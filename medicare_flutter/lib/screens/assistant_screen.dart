import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../services/speech_service.dart';

import '../services/ai_service.dart';

import '../services/database_service.dart';

import '../services/i18n_service.dart';

import '../services/voice_controller.dart';

import '../services/voice_intent_service.dart';



class AssistantScreen extends StatefulWidget {

  const AssistantScreen({super.key});



  @override

  State<AssistantScreen> createState() => _AssistantScreenState();

}



class _AssistantScreenState extends State<AssistantScreen> implements VoiceScreenDelegate {

  VoiceController? _voiceController;



  @override

  void didChangeDependencies() {

    super.didChangeDependencies();

    try {

      _voiceController = Provider.of<VoiceController>(context, listen: false);

    } catch (_) {}

  }



  final List<Map<String, String>> _messages = [];

  final _controller = TextEditingController();

  bool _isListening = false;

  bool _busy = false;



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (mounted) {

        final voice = Provider.of<VoiceController>(context, listen: false);

        voice.setActiveDelegate(this, AppScreen.assistant);

        voice.announceScreen();

      }

    });

  }



  @override

  void dispose() {

    _voiceController?.clearActiveDelegate(this);

    _voiceController?.setCurrentScreen(AppScreen.home);

    _controller.dispose();

    super.dispose();

  }



  @override

  String getScreenAnnouncement() {

    if (!mounted) return "";

    final speech = Provider.of<SpeechService>(context, listen: false);

    final lang = speech.currentLanguage;

    if (lang.startsWith('kn')) {

      return "ಎಐ ಸಹಾಯಕ ಪರದೆ. ನಿಮ್ಮ ಯಾವುದೇ ಆರೋಗ್ಯ ಪ್ರಶ್ನೆಯನ್ನು ನೇರವಾಗಿ ಮಾತನಾಡಿ ಕೇಳಬಹುದು.";

    } else if (lang.startsWith('hi')) {

      return "एआई सहायक स्क्रीन। अपनी सेहत या दवा के बारे में सीधे बोलकर सवाल पूछें।";

    }

    return "AI Voice Assistant screen. Ask any medicine or health question directly.";

  }



  @override

  Future<bool> handleVoiceCommand(VoiceIntent? intent, String transcript) async {

    if (!mounted) return false;

    final speech = Provider.of<SpeechService>(context, listen: false);

    if (intent == VoiceIntent.repeat) {

      if (_messages.isNotEmpty) {

        final lastAssistant = _messages.lastWhere((m) => m['role'] == 'assistant', orElse: () => {});

        if (lastAssistant.isNotEmpty) {

          speech.speak(lastAssistant['text']!);

          return true;

        }

      }

    }



    // If it's a global navigation intent like home, scan, back, let VoiceController handle it

    if (intent == VoiceIntent.home ||

        intent == VoiceIntent.scan ||

        intent == VoiceIntent.schedule ||

        intent == VoiceIntent.emergency ||

        intent == VoiceIntent.more ||

        intent == VoiceIntent.back ||

        intent == VoiceIntent.langEn ||

        intent == VoiceIntent.langKn ||

        intent == VoiceIntent.langHi ||

        intent == VoiceIntent.stop) {

      return false;

    }



    // Any other question is directly answered by the AI assistant!

    if (transcript.trim().isNotEmpty) {

      await _ask(transcript);

      return true;

    }

    return false;

  }



  void _addMessage(String text, bool isUser) {

    setState(() {

      _messages.add({'text': text, 'role': isUser ? 'user' : 'assistant'});

    });

  }



  Future<void> _ask(String text) async {

    final trimmed = text.trim();

    if (trimmed.isEmpty || _busy) return;



    final speech = Provider.of<SpeechService>(context, listen: false);

    final ai = Provider.of<AIService>(context, listen: false);

    final db = Provider.of<DatabaseService>(context, listen: false);



    _addMessage(trimmed, true);

    _controller.clear();

    setState(() => _busy = true);



    try {

      final medicines = await db.getMedicines();

      final schedules = await db.getSchedules();

      final medInfo = medicines.map((m) {

        final comp = (m['composition'] != null && m['composition'].toString().isNotEmpty) ? " contains ${m['composition']}" : "";

        final timing = (m['when_to_take'] != null && m['when_to_take'].toString().isNotEmpty) ? ". When to take: ${m['when_to_take']}" : "";

        final inst = (m['instructions'] != null && m['instructions'].toString().isNotEmpty) ? ". Instructions: ${m['instructions']}" : "";

        return "${m['name']}$comp$timing$inst";

      }).join(". ");

      final schedInfo = schedules.isNotEmpty ? "; Schedules: ${schedules.map((s) => s['time']).join(', ')}" : "";

      final contextText = "$medInfo$schedInfo";



      

      final answer = await ai.askAssistant(trimmed, contextText, language: speech.currentLanguage);



      _addMessage(answer, false);

      speech.speak(answer);

    } catch (e) {

      final errorMsg = speech.currentLanguage.startsWith('kn')

          ? "ಕ್ಷಮಿಸಿ, ಸಹಾಯಕನಿಗೆ ಸಂಪರ್ಕ ಸಾಧಿಸಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ."

          : speech.currentLanguage.startsWith('hi')

              ? "क्षमा करें, सहायक से जुड़ने में समस्या आ रही है।"

              : "Sorry, I'm having trouble connecting to the assistant.";

      _addMessage(errorMsg, false);

      speech.speak(errorMsg);

    } finally {

      if (mounted) setState(() => _busy = false);

    }

  }



  Future<void> _handleVoiceCommand() async {

    final speech = Provider.of<SpeechService>(context, listen: false);

    final voice = Provider.of<VoiceController>(context, listen: false);

    setState(() => _isListening = true);

    final heard = await speech.listenOnce();

    setState(() => _isListening = false);

    if (heard.isNotEmpty) {

      final intent = VoiceIntentService.matchIntent(heard);

      if (intent != null && intent != VoiceIntent.help) {

        final handled = await handleVoiceCommand(intent, heard);

        if (!handled) {

          await voice.executeIntent(intent, heard);

          return;

        }

      }

      _ask(heard);

    }

  }



  @override

  Widget build(BuildContext context) {

    final speech = Provider.of<SpeechService>(context);

    final t = Provider.of<I18nService>(context);



    return Scaffold(

      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(

        title: Text(

          t.translate('nav.assistant', speech.currentLanguage),

          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),

        ),

        backgroundColor: const Color(0xFF059669),

        elevation: 0,

        iconTheme: const IconThemeData(color: Colors.white),

      ),

      body: Column(

        children: [

          Expanded(

            child: ListView.builder(

              padding: const EdgeInsets.all(16),

              itemCount: _messages.length,

              itemBuilder: (context, index) {

                final msg = _messages[index];

                final isUser = msg['role'] == 'user';

                return Align(

                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,

                  child: Container(

                    padding: const EdgeInsets.all(16),

                    margin: const EdgeInsets.only(bottom: 12),

                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),

                    decoration: BoxDecoration(

                      color: isUser ? const Color(0xFF059669) : Colors.white,

                      borderRadius: BorderRadius.circular(20),

                      border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),

                      boxShadow: [

                        BoxShadow(

                          color: const Color(0xFF059669).withValues(alpha: isUser ? 0.2 : 0.04),

                          blurRadius: 8,

                          offset: const Offset(0, 2),

                        ),

                      ],

                    ),

                    child: Text(

                      msg['text']!,

                      style: TextStyle(

                        fontSize: 18,

                        color: isUser ? Colors.white : const Color(0xFF0F172A),

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                  ),

                );

              },

            ),

          ),

          if (_busy)

            const Padding(

              padding: EdgeInsets.all(8.0),

              child: CircularProgressIndicator(color: Color(0xFF059669)),

            ),

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

            decoration: const BoxDecoration(

              color: Colors.white,

              border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),

            ),

            child: SafeArea(

              child: Row(

                children: [

                  Expanded(

                    child: Container(

                      padding: const EdgeInsets.symmetric(horizontal: 14),

                      decoration: BoxDecoration(

                        color: const Color(0xFFF1F5F9),

                        borderRadius: BorderRadius.circular(24),

                        border: Border.all(color: const Color(0xFFCBD5E1)),

                      ),

                      child: TextField(

                        controller: _controller,

                        onSubmitted: _ask,

                        decoration: const InputDecoration(

                          hintText: "Ask anything...",

                          border: InputBorder.none,

                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),

                        ),

                        style: const TextStyle(fontSize: 16, color: Color(0xFF0F172A)),

                      ),

                    ),

                  ),

                  const SizedBox(width: 8),

                  Container(

                    decoration: const BoxDecoration(

                      color: Color(0xFF059669),

                      shape: BoxShape.circle,

                    ),

                    child: IconButton(

                      icon: Icon(_isListening ? Icons.graphic_eq : Icons.mic, size: 24, color: Colors.white),

                      onPressed: _handleVoiceCommand,

                    ),

                  ),

                  const SizedBox(width: 6),

                  Container(

                    decoration: const BoxDecoration(

                      color: Color(0xFF059669),

                      shape: BoxShape.circle,

                    ),

                    child: IconButton(

                      icon: const Icon(Icons.send_rounded, size: 20, color: Colors.white),

                      onPressed: () => _ask(_controller.text),

                    ),

                  ),

                ],

              ),

            ),

          ),

        ],

      ),

    );

  }

}