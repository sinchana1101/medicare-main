import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/speech_service.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../services/i18n_service.dart';
import '../services/voice_controller.dart';
import '../services/voice_intent_service.dart';
import 'caregiver_screen.dart';
import 'auth_screen.dart';
import 'scan_screen.dart';
import 'schedule_screen.dart';
import 'assistant_screen.dart';
import 'emergency_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> implements VoiceScreenDelegate {
  VoiceController? _voiceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _voiceController = Provider.of<VoiceController>(context, listen: false);
    } catch (_) {}
  }

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSaving = false;
  bool _isCheckingSafety = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final voice = Provider.of<VoiceController>(context, listen: false);
        voice.setActiveDelegate(this, AppScreen.settings);
        // Mic state preserved (toggled only by double-tap)
      }
    });
  }

  Future<void> _loadProfile() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final ai = Provider.of<AIService>(context, listen: false);
    final speech = Provider.of<SpeechService>(context, listen: false);
    final profile = await db.getProfile();
    final emergency = await db.getEmergencyContact();
    if (!mounted) return;
    if (emergency != null || profile != null) {
      setState(() {
        _nameController.text = emergency?['emergency_contact_name'] ?? profile?['emergency_contact_name'] ?? "";
        _phoneController.text = emergency?['emergency_contact_phone'] ?? profile?['emergency_contact_phone'] ?? "";
        _emailController.text = emergency?['emergency_contact_email'] ?? profile?['emergency_contact_email'] ?? profile?['emergency_email'] ?? "";
      });
      if (profile != null) {
        if (profile['preferred_language'] != null && profile['preferred_language'].toString().isNotEmpty) {
          speech.currentLanguage = profile['preferred_language'];
        }
        if (profile['gemini_api_key'] != null && profile['gemini_api_key'].toString().isNotEmpty) {
          ai.setApiKey(profile['gemini_api_key']);
        } else if (ai.apiKey != null && ai.apiKey!.isNotEmpty) {
        }
      } else if (ai.apiKey != null && ai.apiKey!.isNotEmpty) {
      }
    } else if (ai.apiKey != null && ai.apiKey!.isNotEmpty) {
    }
  }

  @override
  void dispose() {
    _voiceController?.clearActiveDelegate(this);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  String getScreenAnnouncement() {
    if (!mounted) return "";
    final speech = Provider.of<SpeechService>(context, listen: false);
    final lang = speech.currentLanguage;
    if (lang.startsWith('kn')) return "ಸೆಟ್ಟಿಂಗ್ಸ್";
    if (lang.startsWith('hi')) return "सेटिंग्स";
    return "Settings";
  }

  @override
  Future<bool> handleVoiceCommand(VoiceIntent? intent, String transcript) async {
    if (!mounted) return false;
    final speech = Provider.of<SpeechService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final lower = transcript.toLowerCase().trim();
    debugPrint("SettingsScreen handleVoiceCommand: '$transcript' (intent: $intent)");

    // 1. Navigation to Home / Back
    if (intent == VoiceIntent.home ||
        intent == VoiceIntent.back ||
        intent == VoiceIntent.cancel ||
        lower == "home" ||
        lower.contains("home") ||
        lower.contains("back") ||
        lower.contains("hinde") ||
        lower.contains("mane") ||
        transcript.contains("ಮುಖಪುಟ") ||
        transcript.contains("ಹೋಮ್") ||
        transcript.contains("ಹೋಂ") ||
        transcript.contains("ಮುಖ್ಯ") ||
        transcript.contains("ವಾಪಸ್") ||
        transcript.contains("ಮನೆ") ||
        transcript.contains("ಹಿಂತಿರುಗಿ") ||
        transcript.contains("ಹಿಂದೆ") ||
        transcript.contains("होम") ||
        transcript.contains("घर") ||
        transcript.contains("वापस")) {
      final lang = speech.currentLanguage;
      final msg = lang.startsWith('kn')
          ? "ಮುಖಪುಟ."
          : (lang.startsWith('hi') ? "मुख्य पृष्ठ।" : "Home.");
      speech.speak(msg);
      if (mounted) {
        try {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            VoiceController.navigatorKey.currentState?.popUntil((r) => r.isFirst);
          }
        } catch (_) {
          VoiceController.navigatorKey.currentState?.popUntil((r) => r.isFirst);
        }
      }
      return true;
    }

    // 2. Navigation to Scan
    if (intent == VoiceIntent.scan ||
        lower.contains("scan") ||
        lower.contains("camera") ||
        lower.contains("photo") ||
        transcript.contains("ಸ್ಕ್ಯಾನ್") ||
        transcript.contains("ಕ್ಯಾಮೆರಾ") ||
        transcript.contains("ಸ್ಕಾನರ್") ||
        transcript.contains("ಫೋಟೋ") ||
        transcript.contains("स्कैन") ||
        transcript.contains("कैमरा")) {
      final lang = speech.currentLanguage;
      final msg = lang.startsWith('kn')
          ? "ಸ್ಕ್ಯಾನ್."
          : (lang.startsWith('hi') ? "स्कैन।" : "Scan.");
      speech.speak(msg);
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ScanScreen(),
            transitionDuration: const Duration(milliseconds: 100),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      }
      return true;
    }

    // 3. Navigation to Schedule
    if (intent == VoiceIntent.schedule ||
        lower.contains("schedule") ||
        lower.contains("alarm") ||
        transcript.contains("ವೇಳಾಪಟ್ಟಿ") ||
        transcript.contains("ಶೆಡ್ಯೂಲ್") ||
        transcript.contains("ಅಲಾರಾಂ") ||
        transcript.contains("ಅಲಾರಂ") ||
        transcript.contains("समय") ||
        transcript.contains("शेड्यूल")) {
      final lang = speech.currentLanguage;
      final msg = lang.startsWith('kn')
          ? "ವೇಳಾಪಟ್ಟಿ."
          : (lang.startsWith('hi') ? "शेड्यूल।" : "Schedule.");
      speech.speak(msg);
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ScheduleScreen(),
            transitionDuration: const Duration(milliseconds: 100),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      }
      return true;
    }

    // 4. Navigation to Assistant
    if (intent == VoiceIntent.assistant ||
        lower.contains("assistant") ||
        transcript.contains("ಸಹಾಯಕ") ||
        transcript.contains("ಅಸಿಸ್ಟೆಂಟ್") ||
        transcript.contains("सहायक")) {
      final lang = speech.currentLanguage;
      final msg = lang.startsWith('kn')
          ? "ಸಹಾಯಕ."
          : (lang.startsWith('hi') ? "सहायक।" : "Assistant.");
      speech.speak(msg);
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AssistantScreen(),
            transitionDuration: const Duration(milliseconds: 100),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      }
      return true;
    }

    // 5. Navigation to Emergency
    if (intent == VoiceIntent.emergency ||
        lower.contains("emergency") ||
        lower.contains("sos") ||
        transcript.contains("ತುರ್ತು") ||
        transcript.contains("ಆಪತ್ಕಾಲ") ||
        transcript.contains("आपातकाल") ||
        transcript.contains("खतरा")) {
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const EmergencyScreen(autoTrigger: true),
            transitionDuration: const Duration(milliseconds: 100),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      }
      return true;
    }

    // 6. Language switching
    if (intent == VoiceIntent.langKn || lower.contains("kannada") || transcript.contains("ಕನ್ನಡ")) {
      speech.announceLanguageChanged('kn-IN');
      await db.saveProfile({'preferred_language': 'kn-IN'});
      return true;
    }
    if (intent == VoiceIntent.langHi || lower.contains("hindi") || transcript.contains("हिंदी") || transcript.contains("ಹಿಂದಿ")) {
      speech.announceLanguageChanged('hi-IN');
      await db.saveProfile({'preferred_language': 'hi-IN'});
      return true;
    }
    if (intent == VoiceIntent.langEn || lower.contains("english") || transcript.contains("ಇಂಗ್ಲಿಷ್") || transcript.contains("इंग्लिश")) {
      speech.announceLanguageChanged('en-US');
      await db.saveProfile({'preferred_language': 'en-US'});
      return true;
    }

    // 7. Sign out
    if (intent == VoiceIntent.signOut || lower.contains("sign out") || lower.contains("log out") || transcript.contains("ಲಾಗ್ ಔಟ್")) {
      speech.speak("Signing out.");
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pop(context);
      return true;
    }

    // 8. Read page info / repeat
    if (intent == VoiceIntent.readPage || intent == VoiceIntent.repeat) {
      final contactName = _nameController.text.trim();
      final langName = speech.currentLanguage.startsWith('kn')
          ? "ಕನ್ನಡ"
          : speech.currentLanguage.startsWith('hi')
              ? "हिंदी"
              : "English";
      speech.speak("Current language is $langName. Emergency contact is ${contactName.isNotEmpty ? contactName : 'not set'}.");
      return true;
    }

    // 9. Safety Check Voice Command
    if (intent == VoiceIntent.safetyCheck ||
        lower.contains("safety check") ||
        lower.contains("check safety") ||
        lower.contains("run safety") ||
        lower.contains("check my medicines") ||
        lower.contains("check medicines") ||
        transcript.contains("ಸುರಕ್ಷತೆ") ||
        transcript.contains("ಪರಿಶೀಲನೆ") ||
        transcript.contains("सुरक्षा") ||
        transcript.contains("जांच")) {
      await _handleSafetyCheck();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final speech = Provider.of<SpeechService>(context);
    final db = Provider.of<DatabaseService>(context);
    final t = Provider.of<I18nService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(t.translate('settings.title', speech.currentLanguage), style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<VoiceController>(
            builder: (context, voice, child) {
              final active = voice.isContinuousMode || speech.isListening;
              return IconButton(
                tooltip: "Voice command",
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    active ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                onPressed: () async {
                  voice.toggleContinuousListening();
                },
                onLongPress: () {
                  voice.toggleContinuousListening();
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        children: [
          // Active Account Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF059669),
                  radius: 22,
                  child: Icon(Icons.person, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Signed In Account",
                        style: TextStyle(color: Color(0xFFECFDF5), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        db.activeEmail ?? "Guest User",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(t.translate('settings.language', speech.currentLanguage)),
          _buildLanguageTile("English", "en-US", speech, db),
          _buildLanguageTile("ಕನ್ನಡ (Kannada)", "kn-IN", speech, db),
          _buildLanguageTile("हिंदी (Hindi)", "hi-IN", speech, db),
          const SizedBox(height: 16),

          _buildSectionHeader(
            speech.currentLanguage.startsWith('kn')
                ? "ಧ್ವನಿ ಮತ್ತು ಶಬ್ದ ರದ್ದತಿ"
                : speech.currentLanguage.startsWith('hi')
                    ? "आवाज और शोर रद्दीकरण"
                    : "Voice & Noise Cancellation",
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: speech.noiseCancellation ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (speech.noiseCancellation ? const Color(0xFF10B981) : const Color(0xFF059669)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    speech.noiseCancellation ? Icons.noise_control_off_rounded : Icons.graphic_eq_rounded,
                    color: speech.noiseCancellation ? const Color(0xFF10B981) : const Color(0xFF059669),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        speech.currentLanguage.startsWith('kn')
                            ? "ಹಿನ್ನೆಲೆ ಶಬ್ದ ರದ್ದತಿ"
                            : speech.currentLanguage.startsWith('hi')
                                ? "बैकग्राउंड शोर रद्दीकरण"
                                : "Background Noise Cancellation",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        speech.currentLanguage.startsWith('kn')
                            ? "ಮಾತನಾಡುವಾಗ ಸುತ್ತಲಿನ ಶಬ್ದ ಮತ್ತು ಇತರರ ಧ್ವನಿಯನ್ನು ತಡೆಯುತ್ತದೆ"
                            : speech.currentLanguage.startsWith('hi')
                                ? "बोलते समय पृष्ठभूमि की आवाज और टीवी शोर को रोकता है"
                                : "Filters out background voices, room murmurs, and TV audio",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: speech.noiseCancellation,
                  activeThumbColor: const Color(0xFF10B981),
                  activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                  onChanged: (val) {
                    speech.setNoiseCancellation(val);
                    final msg = val
                        ? (speech.currentLanguage.startsWith('kn') ? "ಶಬ್ದ ರದ್ದತಿ ಆನ್ ಆಗಿದೆ." : "Noise cancellation enabled.")
                        : (speech.currentLanguage.startsWith('kn') ? "ಶಬ್ದ ರದ್ದತಿ ಆಫ್ ಆಗಿದೆ." : "Noise cancellation disabled.");
                    speech.speak(msg);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),


          const SizedBox(height: 24),

          _buildSectionHeader(t.translate('settings.emergencyContact', speech.currentLanguage)),
          _buildTextField(t.translate('settings.contactName', speech.currentLanguage), _nameController),
          const SizedBox(height: 12),
          _buildTextField(t.translate('settings.phoneNumber', speech.currentLanguage), _phoneController, keyboard: TextInputType.phone),
          const SizedBox(height: 12),
          _buildTextField(t.translate('settings.email', speech.currentLanguage), _emailController, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _SettingsActionButton(
            label: t.translate('settings.saveContact', speech.currentLanguage),
            icon: Icons.save_rounded,
            color: const Color(0xFF059669),
            isLoading: _isSaving,
            onPressed: () async {
              setState(() => _isSaving = true);
              try {
                final email = _emailController.text.trim();
                await db.saveEmergencyContact(
                  name: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                  email: email,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Emergency contact & email saved!"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                speech.speak("Emergency contact saved.");
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Save note: $e")),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
          ),

          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 24),

          _buildSectionHeader(t.translate('settings.caregivers', speech.currentLanguage)),
          _SettingsActionButton(
            label: t.translate('settings.manageCaregivers', speech.currentLanguage),
            icon: Icons.people_rounded,
            color: const Color(0xFF6366F1),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CaregiverScreen())),
          ),

          const SizedBox(height: 32),
          _SettingsActionButton(
            label: "SWITCH ACCOUNT / CREATE NEW",
            icon: Icons.switch_account_rounded,
            color: const Color(0xFF059669),
            onPressed: () async {
              final db = Provider.of<DatabaseService>(context, listen: false);
              final speech = Provider.of<SpeechService>(context, listen: false);
              speech.speak("Signing out. You can now register or sign in with another Gmail.");
              await FirebaseAuth.instance.signOut();
              await db.switchUser(null);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _SettingsActionButton(
            label: "DELETE ALL DATA (CLEAR MEDICATIONS)",
            icon: Icons.delete_forever_rounded,
            color: const Color(0xFFB91C1C),
            onPressed: () => _confirmAndDeleteAllData(context),
          ),
          const SizedBox(height: 12),
          _SettingsActionButton(
            label: t.translate('settings.signOut', speech.currentLanguage),
            icon: Icons.logout_rounded,
            color: const Color(0xFFDC2626),
            onPressed: () async {
              final db = Provider.of<DatabaseService>(context, listen: false);
              final speech = Provider.of<SpeechService>(context, listen: false);
              speech.speak("Signing out.");
              await FirebaseAuth.instance.signOut();
              await db.switchUser(null);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }


  Future<void> _handleSafetyCheck() async {
    if (_isCheckingSafety) return;
    setState(() => _isCheckingSafety = true);
    final speech = Provider.of<SpeechService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final ai = Provider.of<AIService>(context, listen: false);
    final t = Provider.of<I18nService>(context, listen: false);

    final lang = speech.currentLanguage;
    final startingMsg = lang.startsWith('kn')
        ? "ಔಷಧಿಗಳ ಸುರಕ್ಷತೆ ಮತ್ತು ನಕಲಿ ಮಾತ್ರೆಗಳ ಪರಿಶೀಲನೆ ಮಾಡಲಾಗುತ್ತಿದೆ..."
        : lang.startsWith('hi')
            ? "दवाओं की सुरक्षा और डुप्लीकेट गोलियों की जांच की जा रही है..."
            : "Checking your medicines for safety and duplicate tablets...";
    await speech.speak(startingMsg);

    try {
      final meds = await db.getMedicines();
      final result = await ai.runSafetyCheck(meds, language: lang);
      final rawAlerts = result['alerts'];
      final List<Map<String, dynamic>> alerts = (rawAlerts is List)
          ? rawAlerts.map((a) => Map<String, dynamic>.from(a as Map)).toList()
          : <Map<String, dynamic>>[];
      await db.replaceAlerts(alerts);

      final summary = result['spoken_summary']?.toString() ??
          (alerts.isEmpty
              ? (lang.startsWith('kn')
                  ? "ಎಲ್ಲಾ ಔಷಧಿಗಳು ಸುರಕ್ಷಿತವಾಗಿವೆ."
                  : (lang.startsWith('hi') ? "सभी दवाएं सुरक्षित हैं।" : "All medicines are safe."))
              : (lang.startsWith('kn')
                  ? "ಸುರಕ್ಷತಾ ಪರಿಶೀಲನೆ ಪೂರ್ಣಗೊಂಡಿದೆ."
                  : (lang.startsWith('hi') ? "सुरक्षा जांच पूरी हो गई।" : "Safety check complete.")));

      await speech.speak(summary);

      if (mounted) {
        _showSafetyCheckDialog(result, t, speech);
      }
    } catch (e) {
      debugPrint("Error running safety check: $e");
    } finally {
      if (mounted) {
        setState(() => _isCheckingSafety = false);
      }
    }
  }

  void _showSafetyCheckDialog(Map<String, dynamic> result, I18nService t, SpeechService speech) {
    final rawAlerts = result['alerts'];
    final List<Map<String, dynamic>> alerts = (rawAlerts is List)
        ? rawAlerts.map((a) => Map<String, dynamic>.from(a as Map)).toList()
        : <Map<String, dynamic>>[];
    final summary = result['spoken_summary']?.toString() ?? "";
    final lang = speech.currentLanguage;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: alerts.any((a) => a['alert_type'] == 'duplicate')
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  alerts.any((a) => a['alert_type'] == 'duplicate')
                      ? Icons.warning_rounded
                      : Icons.shield_rounded,
                  color: alerts.any((a) => a['alert_type'] == 'duplicate')
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF059669),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  lang.startsWith('kn')
                      ? "ಸುರಕ್ಷತಾ ಫಲಿತಾಂಶಗಳು"
                      : lang.startsWith('hi')
                          ? "सुरक्षा जांच परिणाम"
                          : "Safety Check Results",
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (alerts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lang.startsWith('kn')
                                  ? "ಎಲ್ಲಾ ಔಷಧಿಗಳು ಸುರಕ್ಷಿತವಾಗಿವೆ. ಯಾವುದೇ ನಕಲಿ ಅಥವಾ ಮುಕ್ತಾಯಗೊಂಡ ಔಷಧಿಗಳಿಲ್ಲ."
                                  : lang.startsWith('hi')
                                      ? "आपकी सभी दवाएं सुरक्षित हैं। कोई नकली दवा नहीं मिली।"
                                      : "All medicines are safe. No duplicate or expired tablets detected.",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...alerts.map((a) {
                      final isDuplicate = a['alert_type'] == 'duplicate';
                      final orig = a['original_medicine']?.toString();
                      final dup = a['duplicate_medicine']?.toString();
                      final msg = a['message']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDuplicate ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDuplicate ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isDuplicate ? Icons.error_rounded : Icons.info_rounded,
                                  color: isDuplicate ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    a['title']?.toString() ?? 'Alert',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDuplicate ? const Color(0xFF991B1B) : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isDuplicate && orig != null && dup != null) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF86EFAC)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, size: 14, color: Color(0xFF15803D)),
                                        const SizedBox(width: 5),
                                        Text(
                                          "ORIGINAL: $orig",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.cancel_rounded, size: 14, color: Color(0xFFB91C1C)),
                                        const SizedBox(width: 5),
                                        Text(
                                          "DUPLICATE: $dup",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFB91C1C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              msg,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            if (summary.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF059669), size: 20),
                label: Text(
                  lang.startsWith('kn') ? "ಮತ್ತೆ ಕೇಳಿ" : (lang.startsWith('hi') ? "फिर सुनें" : "Read Aloud"),
                  style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700),
                ),
                onPressed: () => speech.speak(summary),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                lang.startsWith('kn') ? "ಮುಗಿಯಿತು" : (lang.startsWith('hi') ? "बंद करें" : "Done"),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _confirmAndDeleteAllData(BuildContext context) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final speech = Provider.of<SpeechService>(context, listen: false);
    final lang = speech.currentLanguage;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                lang.startsWith('kn') ? "ಎಲ್ಲಾ ಡೇಟಾ ಅಳಿಸಬೇಕೆ?" : lang.startsWith('hi') ? "सारा डेटा हटाएं?" : "Delete All Data?",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          lang.startsWith('kn')
              ? "ಇದು ನಿಮ್ಮ ಎಲ್ಲಾ ಉಳಿಸಲಾದ ಔಷಧಿಗಳು, ವೇಳಾಪಟ್ಟಿಗಳು ಮತ್ತು ಎಚ್ಚರಿಕೆಗಳನ್ನು ಶಾಶ್ವತವಾಗಿ ಅಳಿಸುತ್ತದೆ."
              : lang.startsWith('hi')
                  ? "यह आपकी सभी सहेजी गई दवाओं, समय-सारणी और अलर्ट को स्थायी रूप से हटा देगा।"
                  : "This will permanently delete all your saved medications, dose schedules, duplicate alerts, and dose history in real time.",
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.startsWith('kn') ? "ರದ್ದುಮಾಡಿ" : lang.startsWith('hi') ? "रद्द करें" : "CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.startsWith('kn') ? "ಎಲ್ಲವನ್ನೂ ಅಳಿಸಿ" : lang.startsWith('hi') ? "सब हटाएं" : "DELETE ALL"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.clearAllData();
      final msg = lang.startsWith('kn')
          ? "ಎಲ್ಲಾ ಔಷಧಿ ಮಾಹಿತಿಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ."
          : lang.startsWith('hi')
              ? "सभी दवाओं का डेटा सफलतापूर्वक हटा दिया गया है।"
              : "All medication data has been permanently cleared.";
      speech.speak(msg);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF059669), letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 16, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
      ),
    );
  }

  Widget _buildLanguageTile(String label, String code, SpeechService speech, DatabaseService db) {
    bool isSelected = speech.currentLanguage == code;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: isSelected ? 0.08 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? const Color(0xFF059669) : const Color(0xFF0F172A),
          ),
        ),
        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 24) : null,
        onTap: () async {
          speech.announceLanguageChanged(code);
          await db.saveProfile({'preferred_language': code});
        },
      ),
    );
  }
}

class _SettingsActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onPressed;
  final bool isLoading;

  const _SettingsActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
    this.borderColor,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        side: borderColor != null ? BorderSide(color: borderColor!, width: 1.5) : null,
        minimumSize: const Size(double.infinity, 58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: textColor, strokeWidth: 2.2))
          : Icon(icon, color: textColor, size: 24),
      label: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}
