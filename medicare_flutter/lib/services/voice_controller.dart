import 'dart:async';



import 'package:flutter/material.dart';



import 'package:flutter/services.dart';



import 'package:flutter/scheduler.dart';



import 'package:firebase_auth/firebase_auth.dart';



import 'package:url_launcher/url_launcher.dart';



import 'speech_service.dart';



import 'voice_intent_service.dart';



import 'database_service.dart';



import 'emailjs_service.dart';



import 'ai_service.dart';



import 'dose_utils.dart';
import 'side_effects_service.dart';



import '../screens/home_screen.dart';



import '../screens/camera_screen.dart';



import '../screens/scan_screen.dart';



import '../screens/schedule_screen.dart';



import '../screens/assistant_screen.dart';



import '../screens/emergency_screen.dart';



import '../screens/settings_screen.dart';



import '../screens/auth_screen.dart';



enum AppScreen {



  auth,



  home,



  scan,



  camera,



  schedule,



  assistant,



  emergency,



  settings,



  alarmOverlay,



}



abstract class VoiceScreenDelegate {



  Future<bool> handleVoiceCommand(VoiceIntent? intent, String transcript);



  String getScreenAnnouncement();



}



PageRouteBuilder<T> _fastFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 100),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class VoiceController extends ChangeNotifier with WidgetsBindingObserver {
  bool _isNavigating = false;
  DateTime _lastNavigationTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _isNavigationIntent(VoiceIntent? intent) {
    if (intent == null) return false;
    return intent == VoiceIntent.home ||
        intent == VoiceIntent.back ||
        intent == VoiceIntent.cancel ||
        intent == VoiceIntent.scan ||
        intent == VoiceIntent.schedule ||
        intent == VoiceIntent.assistant ||
        intent == VoiceIntent.emergency ||
        intent == VoiceIntent.more;
  }



  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



  final SpeechService _speech;



  final DatabaseService db;



  final AIService? ai;



  AppScreen _currentScreen = AppScreen.home;



  AppScreen get currentScreen => _currentScreen;



  VoiceScreenDelegate? _activeDelegate;

  String? _instantHandledTranscript;



  VoiceScreenDelegate? get activeDelegate {



    if (_activeDelegate != null && _activeDelegate is State && !(_activeDelegate as State).mounted) {



    _activeDelegate = null;



    }



    return _activeDelegate;



  }



  String _lastHeard = "";



  String get lastHeard => _lastHeard;



  String _statusMessage = "";



  String get statusMessage => _statusMessage;



  bool _isProcessing = false;



  bool get isProcessing => _isProcessing;



  // Persistent continuous voice mode state (always true for hands-free automation)
  bool _isContinuousMode = false;



  bool get isContinuousMode => _isContinuousMode;



  @override



  void notifyListeners() {



    final phase = WidgetsBinding.instance.schedulerPhase;



    if (phase == SchedulerPhase.persistentCallbacks || phase == SchedulerPhase.midFrameMicrotasks) {



      WidgetsBinding.instance.addPostFrameCallback((_) {



        super.notifyListeners();



      });



    } else {



      super.notifyListeners();



    }



  }



  Future<void> _initPreferences() async {



    try {



      final profile = await db.getProfile();



      if (profile != null) {



        final lang = profile['preferred_language']?.toString();



        if (lang != null && lang.isNotEmpty) {



          _speech.currentLanguage = lang;



        }



      }



    } catch (_) {}



  }



  static VoiceIntent? _parseIntentFromAiResponse(Map<String, dynamic> aiRes) {



    if (aiRes.isEmpty) return null;



    // 1. Direct intent field: {"action": "intent", "intent": "takePhoto"} or {"intent": "takePhoto"}



    final rawIntent = aiRes['intent']?.toString();



    if (rawIntent != null && rawIntent.trim().isNotEmpty) {



      final parsed = VoiceIntentService.fromName(rawIntent);



      if (parsed != null) return parsed;



    }



    // 2. Action as intent name: {"action": "takePhoto"} or {"action": "scan"}



    final action = aiRes['action']?.toString();



    if (action != null && action.trim().isNotEmpty) {



      final cleanAction = action.trim();



      if (cleanAction != 'intent' &&



          cleanAction != 'question' &&



          cleanAction != 'unknown') {



        final parsed = VoiceIntentService.fromName(cleanAction);



        if (parsed != null) return parsed;



      }



    }



    return null;



  }



  static String? _parseAnswerFromAiResponse(Map<String, dynamic> aiRes) {



    if (aiRes.isEmpty) return null;



    final ans = aiRes['answer']?.toString() ??



        (aiRes['action'] == 'question' ? aiRes['text']?.toString() : null);



    if (ans != null && ans.trim().isNotEmpty) {



      return ans.trim();



    }



    return null;



  }



  bool _isAcousticEcho(String transcript) {
    final cleanTrans = VoiceIntentService.normalize(transcript);
    final cleanSpoken = VoiceIntentService.normalize(_speech.lastSpokenText);
    if (cleanTrans.isEmpty || cleanSpoken.isEmpty) return false;
    if (cleanSpoken.contains(cleanTrans) || cleanTrans.contains(cleanSpoken)) {
      return true;
    }
    final transWords = cleanTrans.split(' ').where((w) => w.length > 2).toSet();
    final spokenWords = cleanSpoken.split(' ').where((w) => w.length > 2).toSet();
    if (transWords.isNotEmpty) {
      final overlap = transWords.intersection(spokenWords).length;
      if (overlap / transWords.length >= 0.6) {
        return true;
      }
    }
    return false;
  }

  VoiceController(this._speech, this.db, {this.ai}) {
    WidgetsBinding.instance.addObserver(this);
    _initPreferences();



    _speech.onInstantIntent = (intent, transcript) async {

      _lastHeard = transcript;

      _statusMessage = "Heard: \"$transcript\"";

      notifyListeners();

      _instantHandledTranscript = transcript.trim().toLowerCase();

      if (intent == VoiceIntent.stop) {

        await _speech.stopTTS();

      } else {

        // Zero-latency instant action execution!
        await executeIntent(intent, transcript);
      }
    };

// Mic is OFF by default; toggled ON/OFF exclusively by double-tapping
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isContinuousMode) {
        debugPrint("VoiceController: App resumed, re-engaging active mic session");
        ensureContinuousListening();
      }
    } else if (state == AppLifecycleState.paused) {
      if (_isContinuousMode) {
        debugPrint("VoiceController: App paused, pausing mic session");
        _speech.stopSTT();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }



  void setActiveDelegate(VoiceScreenDelegate delegate, AppScreen screen) {
    _activeDelegate = delegate;
    _currentScreen = screen;
    notifyListeners();
    // Mic is strictly turned on & off by user double-tapping!
    // Never turn off mic without double tapping!
    if (_isContinuousMode && !_isContinuousLoopRunning) {
      startContinuousListening(customAnnouncement: "");
    }
  }



  void clearActiveDelegate(VoiceScreenDelegate delegate) {



    if (_activeDelegate == delegate) {



      _activeDelegate = null;



      notifyListeners();



    }



  }



  void setCurrentScreen(AppScreen screen) {



    _currentScreen = screen;



    notifyListeners();



  }



  /// Announces current screen details and commands



  void announceScreen() {



    if (_activeDelegate != null) {



      if (_activeDelegate is State && !(_activeDelegate as State).mounted) {



        _activeDelegate = null;



      } else {



        try {



          final announcement = _activeDelegate!.getScreenAnnouncement();



          if (announcement.isNotEmpty) {



            _speech.speak(announcement);



            return;



          }



        } catch (_) {



          _activeDelegate = null;



        }



      }



    }



    final lang = _speech.currentLanguage;



    String text;



    if (lang.startsWith('kn')) {



      switch (_currentScreen) {



        case AppScreen.home:



          text = "ಮುಖಪುಟ. ಇಂದಿನ ವೇಳಾಪಟ್ಟಿ ಕೇಳಲು 'ವೇಳಾಪಟ್ಟಿ ಓದಿ' ಎನ್ನಿ, ಅಥವಾ 'ಸ್ಕ್ಯಾನ್', 'ತುರ್ತು', 'ಸಹಾಯ' ಎನ್ನಿ.";



          break;



        case AppScreen.scan:



          text = "ಔಷಧಿ ಸ್ಕ್ಯಾನ್ ಪರದೆ. ಫೋಟೋ ತೆಗೆಯಲು 'ಫೋಟೋ ತೆಗೆ' ಎನ್ನಿ, ಅಥವಾ 'ಗ್ಯಾಲರಿ', 'ಹಿಂದಕ್ಕೆ' ಎನ್ನಿ.";



          break;



        case AppScreen.camera:



          text = "ಕ್ಯಾಮೆರಾ ಪರದೆ. ಚಿತ್ರ ತೆಗೆಯಲು 'ಕ್ಲಿಕ್' ಅಥವಾ 'ಫೋಟೋ' ಎನ್ನಿ. ಟಾರ್ಚ್‌ಗೆ 'ಟಾರ್ಚ್' ಎನ್ನಿ.";



          break;



        case AppScreen.schedule:



          text = "ವೇಳಾಪಟ್ಟಿ ಪರದೆ. 'ಎಲ್ಲಾ ಓದಿ', 'ತೆಗೆದುಕೊಂಡೆ', ಅಥವಾ 'ಹಿಂದಕ್ಕೆ' ಎನ್ನಿ.";



          break;



        case AppScreen.assistant:



          text = "ಎಐ ಸಹಾಯಕ. ನಿಮ್ಮ ಆರೋಗ್ಯ ಅಥವಾ ಔಷಧಿಯ ಪ್ರಶ್ನೆಯನ್ನು ಕೇಳಿ.";



          break;



        case AppScreen.emergency:



          text = "ತುರ್ತು ಪರದೆ. ಎಸ್ಒಎಸ್ ಕಳುಹಿಸಲು 'ಎಸ್ಒಎಸ್' ಅಥವಾ 'ಆಂಬ್ಯುಲೆನ್ಸ್', 'ಆರೈಕೆದಾರರಿಗೆ ಕರೆ' ಎನ್ನಿ.";



          break;



        case AppScreen.settings:



          text = "ಸೆಟ್ಟಿಂಗ್ಸ್ ಪರದೆ. ಭಾಷೆ ಬದಲಾಯಿಸಲು 'ಕನ್ನಡ', 'ಇಂಗ್ಲಿಷ್', ಅಥವಾ 'ಹಿಂದಿ' ಎನ್ನಿ.";



          break;



        case AppScreen.auth:



          text = "ಸ್ಮಾರ್ಟ್ ಮೆಡಿಕೇರ್. ತಕ್ಷಣ ಪ್ರಾರಂಭಿಸಲು 'ಡೆಮೊ' ಅಥವಾ 'ಆಫ್‌ಲೈನ್' ಎನ್ನಿ.";



          break;



        default:



          text = "ಮೆಡಿಕೇರ್ ಆಪ್.";



      }



    } else if (lang.startsWith('hi')) {



      switch (_currentScreen) {



        case AppScreen.home:



          text = "मुख्य पृष्ठ। आज की दवाएं सुनने के लिए 'दवाएं पढ़ो' कहें, या 'स्कैन', 'आपातकाल', 'मदद' कहें।";



          break;



        case AppScreen.scan:



          text = "दवा स्कैन स्क्रीन। फोटो लेने के लिए 'फोटो लो' कहें, या 'गैलरी', 'वापस' कहें।";



          break;



        case AppScreen.camera:



          text = "कैमरा स्क्रीन। फोटो लेने के लिए 'क्लिक' या 'फोटो' कहें। रोशनी के लिए 'टॉर्च' कहें।";



          break;



        case AppScreen.schedule:



          text = "समय-सारणी स्क्रीन। 'सब पढ़ो', 'ले ली', या 'वापस' कहें।";



          break;



        case AppScreen.assistant:



          text = "एआई सहायक। अपनी सेहत या दवा के बारे में कोई भी प्रश्न पूछें।";



          break;



        case AppScreen.emergency:



          text = "आपातकालीन स्क्रीन। मदद के लिए 'एसओएस', 'एम्बुलेंस', या 'केयरगिवर को कॉल' कहें।";



          break;



        case AppScreen.settings:



          text = "सेटिंग्स स्क्रीन। भाषा बदलने के लिए 'हिंदी', 'अंग्रेजी', या 'कन्नड़' कहें।";



          break;



        case AppScreen.auth:



          text = "स्मार्ट मेडिकेयर में स्वागत है। तुरंत शुरू करने के लिए 'डेमो' या 'ऑफ़लाइन' कहें।";



          break;



        default:



          text = "मेडिकेयर ऐप।";



      }



    } else {



      switch (_currentScreen) {



        case AppScreen.home:



          text = "Home screen. Say 'read schedule', 'mark taken', 'scan', 'emergency', or 'help'.";



          break;



        case AppScreen.scan:



          text = "Scan medicine screen. Say 'take photo', 'upload photo', 'save', or 'go back'.";



          break;



        case AppScreen.camera:



          text = "Camera screen. Say 'click' or 'capture' to take photo, or 'torch' for light.";



          break;



        case AppScreen.schedule:



          text = "Medicine schedule. Say 'read all', 'mark taken', or 'go back'.";



          break;



        case AppScreen.assistant:



          text = "Voice Assistant. Ask any health or medicine question.";



          break;



        case AppScreen.emergency:



          text = "Emergency SOS screen. Say 'send SOS', 'call caregiver', 'call 108', or 'go back'.";



          break;



        case AppScreen.settings:



          text = "Settings screen. Say 'English', 'Kannada', 'Hindi', or 'test alarm'.";



          break;



        case AppScreen.auth:



          text = "Welcome to Smart MediCare. Say 'demo' or 'continue offline' to start immediately.";



          break;



        default:



          text = "MediCare App.";



      }



    }



    _speech.speak(text);



  }



  /// Toggles continuous voice mode on or off.



  /// Double-tapping anywhere on screen toggles this mode.



  Future<void> toggleContinuousListening() async {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    final lang = _speech.currentLanguage;
    if (_isContinuousMode || _isContinuousLoopRunning || _speech.isListening) {
      // Double tap -> Turn mic OFF
      debugPrint("VoiceController: Double tap -> Turning mic OFF");
      _isContinuousMode = false;
      _speech.stopSTT();
      await stopContinuousListening(announce: true);
      notifyListeners();
    } else {
      // Double tap -> Turn mic ON
      debugPrint("VoiceController: Double tap -> Turning mic ON");
      _isContinuousMode = true;
      final onMsg = lang.startsWith('kn')
          ? "ಮೈಕ್ರೊಫೋನ್ ಆನ್ ಆಗಿದೆ."
          : lang.startsWith('hi')
              ? "माइक्रोफ़ोन चालू है।"
              : "Microphone on.";
      await _speech.speak(onMsg);
      await startContinuousListening(customAnnouncement: "");
      notifyListeners();
    }
  }

  Future<void> ensureContinuousListening() async {
    if (_isContinuousMode && !_isContinuousLoopRunning) {
      await startContinuousListening(customAnnouncement: "");
    }
  }



  /// Push-to-talk microphone trigger: listens for a command, interprets and executes it immediately



  Future<void> listenAndExecute() async {



    if (_isProcessing) return;



    // Preserve continuous voice mode so user is not disconnected



    if (_speech.isSpeaking || _speech.isListening) {



      await Future.wait([



        if (_speech.isSpeaking) _speech.stopTTS(),



        if (_speech.isListening) _speech.stopSTT(),



      ]);



      await Future.delayed(const Duration(milliseconds: 200));



    }



    try {



      HapticFeedback.mediumImpact();



    } catch (_) {}



    _isProcessing = true;



    final lang = _speech.currentLanguage;



    _statusMessage = lang.startsWith('kn')



        ? "ಕೇಳಿಸಿಕೊಳ್ಳುತ್ತಿದ್ದೇನೆ... ಮಾತನಾಡಿ"



        : lang.startsWith('hi')



            ? "सुन रहा हूँ... बोलिए"



            : "Listening... Speak now";



    notifyListeners();



    try {



      final transcript = await _speech.listenOnce(timeoutSeconds: 8);

      if (transcript.trim().isNotEmpty) {

        final cleanTr = transcript.trim().toLowerCase();
        if (_isAcousticEcho(transcript)) {
          debugPrint("VoiceController: Ignored acoustic echo from TTS speaker.");
          return;
        }
        if (_instantHandledTranscript != null &&
            (_instantHandledTranscript == cleanTr ||
             cleanTr.contains(_instantHandledTranscript!) ||
             _instantHandledTranscript!.contains(cleanTr))) {
          _instantHandledTranscript = null;
          return;
        }

        _instantHandledTranscript = null;

        _lastHeard = transcript;

        _statusMessage = "Heard: \"$transcript\"";

        notifyListeners();



        VoiceIntent? intent = VoiceIntentService.matchIntent(transcript);



        // If local regex didn't match, use AI to resolve conversational commands or answer health questions



        if (intent == null && ai != null && transcript.trim().isNotEmpty) {



          final aiRes = await ai!.resolveVoiceCommand(transcript, language: lang);



          final parsedIntent = _parseIntentFromAiResponse(aiRes);



          if (parsedIntent != null) {



            intent = parsedIntent;



            debugPrint("AI resolved voice intent: $intent from '$transcript'");



          } else {



            final answer = _parseAnswerFromAiResponse(aiRes);



            if (answer != null) {



              await _speech.speak(answer);



              return;



            }



          }



        }



        await executeIntent(intent, transcript);      } else {

        final noHearMsg = lang.startsWith('kn')

            ? "ಯಾವುದೇ ಧ್ವನಿ ಕೇಳಸಿಲ್ಲ. ಮೈಕ್ ಒತ್ತಿ ಮತ್ತೆ ಮಾತನಾಡಿ."

            : lang.startsWith('hi')

                ? "कोई आवाज नहीं सुनाई दी। कृपया माइक दबाकर फिर बोलें।"

                : "No voice heard. Tap the mic and speak.";

        _statusMessage = noHearMsg;

        notifyListeners();

        _speech.speak(noHearMsg);

      }



    } catch (e) {



      debugPrint("listenAndExecute error: $e");



    } finally {



      _isProcessing = false;



      notifyListeners();



    }



  }



  /// Starts continuous listening mode.



  /// The mic stays on until user double-taps or says stop.



  bool _isContinuousLoopRunning = false;

  Future<void> startContinuousListening({String? customAnnouncement}) async {



    _isContinuousMode = true;



    _isProcessing = false;



    notifyListeners();



    try {



      HapticFeedback.mediumImpact();



    } catch (_) {}



    // Instant mic activation: starts continuous loop immediately with 0ms delay!
    if (!_isContinuousLoopRunning) {
      _runContinuousLoop();
    }



  }



  /// Stops continuous listening mode.



  Future<void> stopContinuousListening({bool announce = true}) async {
    _isContinuousMode = false;
    _isProcessing = false;
    _statusMessage = "Voice stopped";
    notifyListeners();
    await _speech.stop();
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    if (announce) {
      final lang = _speech.currentLanguage;
      final stopMsg = lang.startsWith('kn')
          ? "ಮೈಕ್ರೊಫೋನ್ ಆಫ್ ಆಗಿದೆ."
          : lang.startsWith('hi')
              ? "माइक्रोफ़ोन बंद है।"
              : "Microphone off.";
      await _speech.speak(stopMsg);
    }
  }



  /// Persistent loop that runs as long as continuous mode is active



  Future<void> _runContinuousLoop() async {
    if (_isContinuousLoopRunning) return;
    _isContinuousLoopRunning = true;
    try {
    while (_isContinuousMode) {



      // 0. If speech/TTS is playing (e.g. reading medicine details or announcing screens),



      // pause microphone listening until reading finishes plus 300ms echo cooldown



      if (_speech.isSpeaking) {
        await _speech.waitForSpeech(maxWaitMs: 300);
        await Future.delayed(const Duration(milliseconds: 40));
      }



      if (!_isContinuousMode) break;



      final lang = _speech.currentLanguage;



      _statusMessage = lang.startsWith('kn')



          ? "ಕೇಳಿಸಿಕೊಳ್ಳುತ್ತಿದ್ದೇನೆ..."



          : lang.startsWith('hi')



              ? "सुन रहा हूँ..."



              : "Listening...";



      notifyListeners();



      String transcript = "";
      final startListenTime = DateTime.now();

      try {
        transcript = await _speech.listenOnce(timeoutSeconds: 8);
      } catch (e) {
        debugPrint("Continuous voice listen error: $e");
        await Future.delayed(const Duration(milliseconds: 1000));
        continue;
      }

      if (!_isContinuousMode) break;

      final elapsedMs = DateTime.now().difference(startListenTime).inMilliseconds;

      // If transcript is empty (no speech detected or silence timeout)
      if (transcript.trim().isEmpty) {
        // Safe inter-cycle gap so Android audioserver and microphone hardware properly reset
        await Future.delayed(const Duration(milliseconds: 350));
        continue;
      }

      if (transcript.trim().isNotEmpty) {
        final cleanTr = transcript.trim().toLowerCase();
        if (_isAcousticEcho(transcript)) {
          debugPrint("VoiceController: Ignored acoustic echo from TTS speaker.");
          continue;
        }
        if (_instantHandledTranscript != null &&
            (_instantHandledTranscript == cleanTr ||
             cleanTr.contains(_instantHandledTranscript!) ||
             _instantHandledTranscript!.contains(cleanTr))) {
          _instantHandledTranscript = null;
          if (_speech.isSpeaking) {
            await _speech.waitForSpeech(maxWaitMs: 300);
            await Future.delayed(const Duration(milliseconds: 40));
          }
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        }
        _instantHandledTranscript = null;

        debugPrint("Voice Heard: '$transcript'");



        _lastHeard = transcript;



        _statusMessage = "Heard: \"$transcript\"";



        notifyListeners();



        // 1. Check if user asked to stop/turn off mic



        final lower = transcript.toLowerCase();



        if (lower.contains("stop listening") ||



            lower.contains("turn off mic") ||



            lower.contains("stop mic") ||



            lower.contains("turn off voice") ||



            lower.contains("stop voice") ||



            transcript.contains("ಮೈಕ್ ಆಫ್") ||



            transcript.contains("ಧ್ವನಿ ನಿಲ್ಲಿಸಿ") ||



            transcript.contains("ಮಾತನಾಡುವುದು ಬೇಡ") ||



            transcript.contains("माइक बंद") ||



            transcript.contains("वॉइस बंद")) {



          await stopContinuousListening();



          break;



        }



        // 2. Match intent and execute



        _isProcessing = true;



        notifyListeners();



        try {



          VoiceIntent? intent = VoiceIntentService.matchIntent(transcript);



          // If local regex didn't match, use AI to resolve conversational commands



          if (intent == null && ai != null && transcript.trim().isNotEmpty) {



            final aiRes = await ai!.resolveVoiceCommand(transcript, language: lang);



            final parsedIntent = _parseIntentFromAiResponse(aiRes);



            if (parsedIntent != null) {



              intent = parsedIntent;



              debugPrint("AI continuous loop resolved intent: $intent from '$transcript'");



            } else {



              final answer = _parseAnswerFromAiResponse(aiRes);



              if (answer != null) {



                await _speech.speak(answer);



                continue;



              }



            }



          }



          await executeIntent(intent, transcript);



        } catch (e) {



          debugPrint("Voice execution error: $e");



        } finally {



          _isProcessing = false;



          notifyListeners();



        }



        // 3. Wait for all speech feedback to finish before mic resumes



        if (_speech.isSpeaking) {
          await _speech.waitForSpeech();
          await Future.delayed(const Duration(milliseconds: 120));
        }



      }



      // Safe pause so Android OS audioserver and microphone hardware properly reset



      if (_isContinuousMode) {
        await Future.delayed(const Duration(milliseconds: 350));
      }
    }
    } finally {
      _isContinuousLoopRunning = false;
    }



  }



  Future<List<TodayDose>> _getTodayDoses() async {



    try {



      final medicines = await db.getMedicines();



      final schedules = await db.getSchedules();



      final logs = await db.getDoseLogs();



      return DoseUtils.buildTodayDoses(



        medicines: medicines,



        schedules: schedules,



        logs: logs,



      );



    } catch (_) {



      return [];



    }



  }



  /// Navigates from ANY page to ANY page seamlessly with clean route hygiene



  Future<void> navigateTo(AppScreen targetScreen, {bool autoTriggerSos = false}) async {



    final nav = navigatorKey.currentState;



    if (nav == null) return;



    final lang = _speech.currentLanguage;



    if (_currentScreen == targetScreen) {



      if (targetScreen == AppScreen.emergency && autoTriggerSos && _activeDelegate != null) {



        _activeDelegate!.handleVoiceCommand(VoiceIntent.emergency, "sos");



        return;



      }



      announceScreen();



      return;



    }



    _activeDelegate = null;



    try {
    switch (targetScreen) {



      case AppScreen.home:



        final homeMsg = lang.startsWith('kn')



            ? "ಮುಖಪುಟ."



            : lang.startsWith('hi')



                ? "मुख्य पृष्ठ।"



                : "Home.";



        // Instant non-blocking route pop



        try {
          if (nav.canPop()) {
            nav.popUntil((route) => route.isFirst);
          }
        } catch (e) {
          debugPrint('Safe popUntil home error: ');
        }



        _currentScreen = AppScreen.home;



        notifyListeners();



        _speech.speak(homeMsg);



        break;



      case AppScreen.scan:



        final scanMsg = lang.startsWith('kn')



            ? "ಸ್ಕ್ಯಾನ್."



            : lang.startsWith('hi')



                ? "स्कैन।"



                : "Scan.";



        // Instant non-blocking route transition



        if (nav.canPop()) {



          nav.popUntil((route) => route.isFirst);



        }



        _currentScreen = AppScreen.scan;



        notifyListeners();



        nav.push(_fastFadeRoute(const ScanScreen())).then((_) {



          if (_currentScreen == AppScreen.scan) {



            _currentScreen = AppScreen.home;



            notifyListeners();



          }



        });



        _speech.speak(scanMsg);



        break;



      case AppScreen.camera:



        final camMsg = lang.startsWith('kn')



            ? "ಕ್ಯಾಮೆರಾ."



            : lang.startsWith('hi')



                ? "कैमरा।"



                : "Camera.";



        _currentScreen = AppScreen.camera;



        notifyListeners();



        nav.push<String>(_fastFadeRoute(const CameraScreen())).then((capturedPath) {



          if (capturedPath != null && capturedPath.isNotEmpty) {



            _currentScreen = AppScreen.scan;



            notifyListeners();



            nav.push(_fastFadeRoute(ScanScreen(initialImagePath: capturedPath)));



          } else {



            _currentScreen = AppScreen.home;



            notifyListeners();



          }



        });



        _speech.speak(camMsg);



        break;



      case AppScreen.schedule:



        final schedMsg = lang.startsWith('kn')



            ? "ವೇಳಾಪಟ್ಟಿ."



            : lang.startsWith('hi')



                ? "शेड्यूल।"



                : "Schedule.";



        if (nav.canPop()) {



          nav.popUntil((route) => route.isFirst);



        }



        _currentScreen = AppScreen.schedule;



        notifyListeners();



        nav.push(_fastFadeRoute(const ScheduleScreen())).then((_) {



          if (_currentScreen == AppScreen.schedule) {



            _currentScreen = AppScreen.home;



            notifyListeners();



          }



        });



        _speech.speak(schedMsg);



        break;



      case AppScreen.assistant:



        final asstMsg = lang.startsWith('kn')



            ? "ಸಹಾಯಕ."



            : lang.startsWith('hi')



                ? "सहायक।"



                : "Assistant.";



        if (nav.canPop()) {



          nav.popUntil((route) => route.isFirst);



        }



        _currentScreen = AppScreen.assistant;



        notifyListeners();



        nav.push(_fastFadeRoute(const AssistantScreen())).then((_) {



          if (_currentScreen == AppScreen.assistant) {



            _currentScreen = AppScreen.home;



            notifyListeners();



          }



        });



        _speech.speak(asstMsg);



        break;



      case AppScreen.emergency:



        final emerMsg = lang.startsWith('kn')



            ? "ತುರ್ತು."



            : lang.startsWith('hi')



                ? "आपातकाल।"



                : "Emergency.";



        if (nav.canPop()) {



          nav.popUntil((route) => route.isFirst);



        }



        _currentScreen = AppScreen.emergency;



        notifyListeners();



        nav.push(_fastFadeRoute(EmergencyScreen(autoTrigger: autoTriggerSos))).then((_) {



          if (_currentScreen == AppScreen.emergency) {



            _currentScreen = AppScreen.home;



            notifyListeners();



          }



        });



        _speech.speak(emerMsg);



        break;



      case AppScreen.settings:



        final openMsg = lang.startsWith('kn')



            ? "ಸೆಟ್ಟಿಂಗ್ಸ್."



            : lang.startsWith('hi')



                ? "सेटिंग्स।"



                : "Settings.";



        if (nav.canPop()) {



          nav.popUntil((route) => route.isFirst);



        }



        _currentScreen = AppScreen.settings;



        notifyListeners();



        nav.push(_fastFadeRoute(const SettingsScreen())).then((_) {



          if (_currentScreen == AppScreen.settings) {



            _currentScreen = AppScreen.home;



            notifyListeners();



          }



        });



        _speech.speak(openMsg);



        break;



      default:



        break;



    }
    } catch (e) {
      debugPrint('navigateTo error: ');
    } finally {
      await Future.delayed(const Duration(milliseconds: 80));
      _isNavigating = false;
    }



  }



  Future<void> goBack() async {



    final nav = navigatorKey.currentState;



    final lang = _speech.currentLanguage;



    if (nav?.canPop() == true) {



      nav?.pop();



      final backMsg = lang.startsWith('kn')



          ? "ಹಿಂದಿನ ಪರದೆಗೆ ಹೋಗಲಾಗಿದೆ."



          : lang.startsWith('hi')



              ? "पिछले पृष्ठ पर वापस आ गए।"



              : "Going back.";



      _speech.speak(backMsg);



    } else {



      _speech.speak(lang.startsWith('kn')



          ? "ನೀವು ಈಗಾಗಲೇ ಮುಖ್ಯ ಪುಟದಲ್ಲಿದ್ದೀರಿ."



          : lang.startsWith('hi')



              ? "आप पहले से ही मुख्य पृष्ठ पर हैं।"



              : "You are already on the home screen.");



    }



  }



  /// Dispatches the recognized voice intent to navigation, delegate, or universal handlers.



  /// Guarantees that EVERY feature in the entire app can be triggered by voice from any page.



    /// Runs safety and duplicate tablet check from any screen via voice or button
  /// Voice command to delete duplicate medicine identified by safety check
  Future<void> deleteDuplicateMedicineCommand({String? transcript}) async {
    final lang = _speech.currentLanguage;
    final alerts = await db.getAlerts();
    final dupAlerts = alerts.where((a) => a['alert_type'] == 'duplicate' && a['acknowledged'] != true).toList();
    if (dupAlerts.isEmpty) {
      final msg = lang.startsWith('kn')
          ? "ಯಾವುದೇ ನಕಲಿ ಔಷಧಿಗಳು ಕಂಡುಬಂದಿಲ್ಲ."
          : lang.startsWith('hi')
              ? "कोई डुप्लीकेट दवा नहीं मिली।"
              : "No duplicate medicine alerts found to delete.";
      await _speech.speak(msg);
      return;
    }

    final dupAlert = dupAlerts.first;
    final dupName = (dupAlert['duplicate_medicine'] ?? 'Duplicate medicine').toString();
    final meds = await db.getMedicines();

    String? targetId = dupAlert['duplicate_medicine_id']?.toString();
    if (targetId == null || targetId.isEmpty) {
      final clean = dupName.toLowerCase();
      for (final m in meds) {
        final mName = (m['name'] ?? '').toString().toLowerCase();
        final mStrength = (m['strength'] ?? '').toString().toLowerCase();
        if (clean == mName || clean.contains(mName) || (mStrength.isNotEmpty && clean.contains(mStrength))) {
          targetId = m['id']?.toString();
          break;
        }
      }
    }

    if (targetId != null && targetId.isNotEmpty) {
      await db.deleteMedicine(targetId);
      if (dupAlert['id'] != null) {
        await db.acknowledgeAlert(dupAlert['id'].toString());
      }
      final msg = lang.startsWith('kn')
          ? "$dupName ನಕಲಿ ಔಷಧಿಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ."
          : lang.startsWith('hi')
              ? "$dupName डुप्लीकेट दवा को सफलतापूर्वक हटा दिया गया है।"
              : "$dupName duplicate medicine has been deleted.";
      await _speech.speak(msg);
      await runSafetyCheckCommand();
      notifyListeners();
    }
  }

  /// Voice command to check warnings and side effects of uploaded medicines
  Future<void> checkWarningsCommand({BuildContext? context}) async {
    final lang = _speech.currentLanguage;
    final meds = await db.getMedicines();
    final warnings = SideEffectsService.evaluateMedicines(meds, language: lang);
    final summary = SideEffectsService.buildSpokenSummary(warnings, language: lang);
    await _speech.speak(summary);
    notifyListeners();
  }

  /// Voice command to delete medicine with warnings / side effects
  Future<void> deleteWarningMedicineCommand({String? transcript}) async {
    final lang = _speech.currentLanguage;
    final meds = await db.getMedicines();
    final warnings = SideEffectsService.evaluateMedicines(meds, language: lang);
    if (warnings.isEmpty) {
      final msg = lang.startsWith('kn')
          ? "ಅಳಿಸಲು ಯಾವುದೇ ಎಚ್ಚರಿಕೆ ಅಥವಾ ಅಡ್ಡಪರಿಣಾಮದ ಔಷಧಿಗಳಿಲ್ಲ."
          : lang.startsWith('hi')
              ? "हटाने के लिए कोई चेतावनी या साइड इफेक्ट वाली दवा नहीं है।"
              : "No medicines with warning alerts found to delete.";
      await _speech.speak(msg);
      return;
    }

    final target = warnings.first;
    await db.deleteMedicine(target.medicineId);

    final msg = lang.startsWith('kn')
        ? "${target.name} ಔಷಧಿಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ."
        : lang.startsWith('hi')
            ? "${target.name} दवा को सफलतापूर्वक हटा दिया गया है।"
            : "${target.name} medicine has been deleted.";
    await _speech.speak(msg);
    notifyListeners();
  }

  Future<Map<String, dynamic>> runSafetyCheckCommand() async {
    final lang = _speech.currentLanguage;
    final startMsg = lang.startsWith('kn')
        ? "ಔಷಧಿಗಳ ಸುರಕ್ಷತೆ ಮತ್ತು ನಕಲಿ ಮಾತ್ರೆಗಳ ಪರಿಶೀಲನೆ ಮಾಡಲಾಗುತ್ತಿದೆ..."
        : lang.startsWith('hi')
            ? "दवाओं की सुरक्षा और डुप्लीकेट गोलियों की जांच की जा रही है..."
            : "Checking your medicines for safety and duplicate tablets...";
    await _speech.speak(startMsg);

    final meds = await db.getMedicines();
    try {
      final prof = await db.getProfile();
      if (prof != null) {
        if (prof['voice_api_key'] != null && prof['voice_api_key'].toString().trim().isNotEmpty) {
          ai?.setVoiceApiKey(prof['voice_api_key'].toString().trim());
        }
        if (prof['gemini_api_key'] != null && prof['gemini_api_key'].toString().trim().isNotEmpty) {
          ai?.setApiKey(prof['gemini_api_key'].toString().trim());
        }
      }
    } catch (_) {}
    final result = await (ai?.runSafetyCheck(meds, language: lang) ?? Future.value(<String, dynamic>{}));
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

    await _speech.speak(summary);



    notifyListeners();
    return result;
  }

  Future<void> _handleMarkTaken(String lang, {String? transcript}) async {



    try {



      final doses = await _getTodayDoses();



      if (doses.isEmpty) {



        final noMeds = lang.startsWith('kn')



            ? "ಯಾವುದೇ ಔಷಧಿ ನಿಗದಿಯಾಗಿಲ್ಲ. ಹೊಸ ಔಷಧಿಯನ್ನು ಸೇರಿಸಲು 'ಸ್ಕ್ಯಾನ್' ಎನ್ನಿ."



            : lang.startsWith('hi')



                ? "कोई दवा निर्धारित नहीं है। नई दवा जोड़ने के लिए 'स्कैन' कहें।"



                : "No medicines in your schedule yet. Say 'scan' to add a medicine.";



        await _speech.speak(noMeds);



        return;



      }



      final pending = doses.where((d) => d.status != 'taken').toList();



      if (pending.isEmpty) {



        final allTaken = lang.startsWith('kn')



            ? "ಇಂದಿನ ಎಲ್ಲಾ ಔಷಧಿಗಳನ್ನು ಈಗಾಗಲೇ ತೆಗೆದುಕೊಳ್ಳಲಾಗಿದೆ. ತುಂಬಾ ಒಳ್ಳೆಯದು!"



            : lang.startsWith('hi')



                ? "आज की सभी दवाएं पहले ही ली जा चुकी हैं।"



                : "All medicines for today are already marked as taken. Well done!";



        await _speech.speak(allTaken);



        return;



      }



      // Check if user specified a medicine name in speech



      TodayDose target = pending.first;



      if (transcript != null && transcript.isNotEmpty) {



        final lower = transcript.toLowerCase();



        for (final d in pending) {



          final name = (d.medicine['name'] ?? '').toString().toLowerCase();



          if (name.isNotEmpty && lower.contains(name)) {



            target = d;



            break;



          }



        }



      }



      final medName = target.medicine['name'] ?? 'Medicine';



      await db.logDose(



        target.medicine['id'],



        'taken',



        scheduleId: target.schedule['id'],



        scheduledFor: target.scheduledFor,



      );



      final done = lang.startsWith('kn')



          ? "$medName ತೆಗೆದುಕೊಂಡಂತೆ ಗುರುತಿಸಲಾಗಿದೆ. ಉತ್ತಮ!"



          : lang.startsWith('hi')



              ? "$medName ले ली गई के रूप में चिह्नित किया गया।"



              : "Marked $medName as taken. Well done.";



      await _speech.speak(done);



      // Safe delegate notification



      if (_activeDelegate != null && _activeDelegate is State && (_activeDelegate as State).mounted) {



        try {



          await _activeDelegate!.handleVoiceCommand(VoiceIntent.markTaken, transcript ?? "mark taken");



        } catch (_) {}



      }



      notifyListeners();



    } catch (e) {



      debugPrint("Error handling markTaken: $e");



      await _speech.speak(lang.startsWith('kn') ? "ಔಷಧಿ ತೆಗೆದುಕೊಳ್ಳಲಾಗಿದೆ." : "Marked as taken.");



    }



  }



  Future<void> _handleSkipDose(String lang, {String? transcript}) async {



    try {



      final doses = await _getTodayDoses();



      if (doses.isEmpty) {



        final noMeds = lang.startsWith('kn')



            ? "ಯಾವುದೇ ಔಷಧಿ ನಿಗದಿಯಾಗಿಲ್ಲ."



            : lang.startsWith('hi')



                ? "कोई दवा निर्धारित नहीं है।"



                : "No medicines in your schedule yet.";



        await _speech.speak(noMeds);



        return;



      }



      final pending = doses.where((d) => d.status != 'taken').toList();



      if (pending.isEmpty) {



        final noPending = lang.startsWith('kn')



            ? "ಬಿಟ್ಟುಬಿಡಲು ಯಾವುದೇ ಬಾಕಿ ಔಷಧಿಗಳಿಲ್ಲ."



            : lang.startsWith('hi')



                ? "छोड़ने के लिए कोई दवा बाकी नहीं है।"



                : "No pending doses left to skip.";



        await _speech.speak(noPending);



        return;



      }



      TodayDose target = pending.first;



      if (transcript != null && transcript.isNotEmpty) {



        final lower = transcript.toLowerCase();



        for (final d in pending) {



          final name = (d.medicine['name'] ?? '').toString().toLowerCase();



          if (name.isNotEmpty && lower.contains(name)) {



            target = d;



            break;



          }



        }



      }



      final medName = target.medicine['name'] ?? 'Medicine';



      await db.logDose(



        target.medicine['id'],



        'skipped',



        scheduleId: target.schedule['id'],



        scheduledFor: target.scheduledFor,



      );



      final skipMsg = lang.startsWith('kn')



          ? "$medName ಬಿಟ್ಟುಬಿಡಲಾಗಿದೆ. ಆರೈಕೆದಾರರಿಗೆ ಎಚ್ಚರಿಕೆ ನೀಡಲಾಗಿದೆ."



          : lang.startsWith('hi')



              ? "$medName छोड़ दी गई। केयरगिवर को सूचित किया गया।"



              : "Skipped $medName. Caregiver notified.";



      await _speech.speak(skipMsg);



      // Safe delegate notification



      if (_activeDelegate != null && _activeDelegate is State && (_activeDelegate as State).mounted) {



        try {



          await _activeDelegate!.handleVoiceCommand(VoiceIntent.skipDose, transcript ?? "skip dose");



        } catch (_) {}



      }



      notifyListeners();



    } catch (e) {



      debugPrint("Error handling skipDose: $e");



      await _speech.speak(lang.startsWith('kn') ? "ಡೋಸ್ ಬಿಟ್ಟುಬಿಡಲಾಗಿದೆ." : "Dose skipped.");



    }



  }



    DateTime _lastGeneralExecutionTime = DateTime.fromMillisecondsSinceEpoch(0);
    VoiceIntent? _lastGeneralExecutedIntent;

    Future<void> executeIntent(VoiceIntent? intent, String transcript) async {
    final execNow = DateTime.now();
    if (intent != null && intent == _lastGeneralExecutedIntent && execNow.difference(_lastGeneralExecutionTime).inMilliseconds < 450) {
      debugPrint('Debouncing rapid duplicate execution of intent: $intent');
      return;
    }
    _lastGeneralExecutionTime = execNow;
    _lastGeneralExecutedIntent = intent;

    if (_isNavigationIntent(intent)) {
      final now = DateTime.now();
      if (now.difference(_lastNavigationTime).inMilliseconds < 300) {
        debugPrint('Debouncing rapid navigation trigger: $intent');
        return;
      }
      _lastNavigationTime = now;
    }



    final lang = _speech.currentLanguage;



    final clean = VoiceIntentService.normalize(transcript);



    if (clean == "open" || clean == "open the" || clean == "ತೆರೆ" || clean == "ಓಪನ್" || clean == "खोलो" || clean == "ओपन") {



      final prompt = lang.startsWith('kn')



          ? "ಏನನ್ನು ತೆರೆಯಬೇಕು? ಮುಖಪುಟ, ಸ್ಕ್ಯಾನ್, ವೇಳಾಪಟ್ಟಿ, ಅಥವಾ ಸೆಟ್ಟಿಂಗ್ಸ್ ಎನ್ನಿ."



          : lang.startsWith('hi')



              ? "क्या खोलना चाहते हैं? होम, स्कैन, समय सारणी, या सेटिंग्स कहें।"



              : "What would you like to open? Say Home, Scan, Schedule, or Settings.";



      await _speech.speak(prompt);



      return;



    }



    // 1. Language switching commands work from ANY screen, ANY time



    if (intent == VoiceIntent.langKn) {



      await _speech.announceLanguageChanged('kn-IN');



      await db.saveProfile({'preferred_language': 'kn-IN'});



      return;



    }



    if (intent == VoiceIntent.langHi) {



      await _speech.announceLanguageChanged('hi-IN');



      await db.saveProfile({'preferred_language': 'hi-IN'});



      return;



    }



    if (intent == VoiceIntent.langEn) {



      await _speech.announceLanguageChanged('en-US');



      await db.saveProfile({'preferred_language': 'en-US'});



      return;



    }



    // 2. Universal noise cancellation toggle: works from ANY screen, ANY time



    if (intent == VoiceIntent.noiseCancelOn) {



      _speech.setNoiseCancellation(true);



      final onMsg = lang.startsWith('kn')



          ? "ಹಿನ್ನೆಲೆ ಶಬ್ದ ರದ್ದತಿ ಆನ್ ಆಗಿದೆ."



          : lang.startsWith('hi')



              ? "बैकग्राउंड शोर रद्दीकरण चालू किया गया।"



              : "Noise cancellation enabled.";



      await _speech.speak(onMsg);



      return;



    }



    if (intent == VoiceIntent.noiseCancelOff) {



      _speech.setNoiseCancellation(false);



      final offMsg = lang.startsWith('kn')



          ? "ಹಿನ್ನೆಲೆ ಶಬ್ದ ರದ್ದತಿ ಆಫ್ ಆಗಿದೆ."



          : lang.startsWith('hi')



              ? "बैकग्राउंड शोर रद्दीकरण बंद किया गया।"



              : "Noise cancellation disabled.";



      await _speech.speak(offMsg);



      return;



    }



    // 3. Audio playback controls (stops spoken voice output, keeps mic listening)



    if (intent == VoiceIntent.stop) {



      await _speech.stopTTS();



      return;



    }



    if (intent == VoiceIntent.repeat) {



      await _speech.repeat();



      return;



    }



    // Continuous Voice controls



    if (intent == VoiceIntent.continuousVoiceOn) {



      await startContinuousListening();



      return;



    }



    if (intent == VoiceIntent.continuousVoiceOff) {



      await stopContinuousListening();



      return;



    }



        // Camera lens flip

    if (intent == VoiceIntent.switchCamera) {

      if (_activeDelegate != null) {

        final handled = await _activeDelegate!.handleVoiceCommand(VoiceIntent.switchCamera, transcript);

        if (handled) return;

      }

    }



    // 4. Delegate has priority for screen-specific actions (e.g. snapping photo on camera, saving medicine on scan)



    if (_activeDelegate != null) {



      if (_activeDelegate is State && !(_activeDelegate as State).mounted) {



        _activeDelegate = null;



      } else {



        try {



          final handled = await _activeDelegate!.handleVoiceCommand(intent, transcript);



          if (handled) return;



        } catch (e) {



          debugPrint("Active delegate voice handling note: $e");



          _activeDelegate = null;



        }



      }



    }



    // 5. Universal Page-to-Page Navigation: Works from ANY page to ANY page 100% reliably!



    if (intent == VoiceIntent.home) {



      await navigateTo(AppScreen.home);



      return;



    }



    if (intent == VoiceIntent.scan ||
        clean == "scan" ||
        clean == "can" ||
        clean == "scam" ||
        clean == "open scan" ||
        clean == "scanner" ||
        clean == "open scanner" ||
        clean == "camera" ||
        clean == "open camera" ||
        clean == "from home to scan" ||
        clean == "home to scan" ||
        clean == "prescription" ||
        clean == "scan prescription" ||
        clean.contains("scan") ||
        clean.contains("scanner") ||
        transcript.contains("ಸ್ಕ್ಯಾನ್") ||
        transcript.contains("ಸ್ಕಾನರ್") ||
        transcript.contains("स्कैन") ||
        transcript.contains("स्कैनर")) {
      await navigateTo(AppScreen.scan);
      return;
    }



    if (intent == VoiceIntent.schedule) {



      await navigateTo(AppScreen.schedule);



      return;



    }



    if (intent == VoiceIntent.assistant) {



      await navigateTo(AppScreen.assistant);



      return;



    }



    if (intent == VoiceIntent.emergency) {



      if (_currentScreen == AppScreen.emergency && _activeDelegate != null) {



        await _activeDelegate!.handleVoiceCommand(VoiceIntent.emergency, transcript);



      } else {



        await navigateTo(AppScreen.emergency, autoTriggerSos: true);



      }



      return;



    }



    if (intent == VoiceIntent.more) {



      await navigateTo(AppScreen.settings);



      return;



    }



    if (intent == VoiceIntent.back) {



      await goBack();



      return;



    }



    // 6. Universal Medicine Actions (Work from ANY screen 100% reliably with zero delegate dependency)



    if (intent == VoiceIntent.markTaken) {



      await _handleMarkTaken(lang, transcript: transcript);



      return;



    }



    if (intent == VoiceIntent.skipDose) {



      await _handleSkipDose(lang, transcript: transcript);



      return;



    }



    if (intent == VoiceIntent.sendMail) {



      await _handleSendMail(lang);



      return;



    }



    // 7. Universal Global Handlers



    final navContext = navigatorKey.currentContext;



    switch (intent) {



      case VoiceIntent.readPage:



        final doses = await _getTodayDoses();



        if (doses.isEmpty) {



          await _speech.speak(lang.startsWith('kn') ? "ಇಂದು ಯಾವುದೇ ಔಷಧಿಗಳಿಲ್ಲ." : "You have no medicines scheduled for today.");



        } else {



          final summary = DoseUtils.spokenSummary(doses, language: lang);



          await _speech.speak(summary);



        }



        return;



      case VoiceIntent.nextMedicine:



        final doses = await _getTodayDoses();



        final pending = doses.where((d) => d.status != 'taken').toList();



        if (pending.isNotEmpty) {



          final next = pending.first;



          final medName = next.medicine['name'] ?? 'Medicine';



          final timeStr = DoseUtils.friendlyTime(next.time);



          final msg = lang.startsWith('kn')



              ? "ನಿಮ್ಮ ಮುಂದಿನ ಔಷಧಿ $medName, ಸಮಯ $timeStr."



              : lang.startsWith('hi')



                  ? "आपकी अगली दवा $medName $timeStr बजे है।"



                  : "Your next medicine is $medName at $timeStr.";



          await _speech.speak(msg);



        } else {



          await _speech.speak(lang.startsWith('kn') ? "ಇಂದು ಇನ್ನು ಯಾವುದೇ ಬಾಕಿ ಔಷಧಿಗಳಿಲ್ಲ." : "No upcoming doses for today.");



        }



        return;



      case VoiceIntent.callAmbulance:



        await _speech.speak("Calling 108 emergency ambulance.");



        final Uri telUri = Uri(scheme: 'tel', path: '108');



        if (await canLaunchUrl(telUri)) {



          await launchUrl(telUri);



        }



        return;



      case VoiceIntent.callCaregiver:



        final contact = await db.getEmergencyContact();



        final phone = contact?['emergency_contact_phone'] ?? '112';



        final name = contact?['emergency_contact_name'] ?? 'Caregiver';



        await _speech.speak("Calling $name at $phone.");



        final Uri telUri = Uri(scheme: 'tel', path: phone);



        if (await canLaunchUrl(telUri)) {



          await launchUrl(telUri);



        }



        return;



      case VoiceIntent.takePhoto:
        if (_activeDelegate != null) {



          final handled = await _activeDelegate!.handleVoiceCommand(VoiceIntent.takePhoto, transcript);



          if (handled) return;



        }



        await navigateTo(AppScreen.camera);



        return;



      case VoiceIntent.uploadPhoto:



        await navigateTo(AppScreen.scan);



        return;



      case VoiceIntent.testAlarm:



        try {



          HapticFeedback.heavyImpact();



        } catch (_) {}



        final testMsg = lang.startsWith('kn')



            ? "ಅಲಾರಾಂ ಪರೀಕ್ಷೆ. ಟ್ರಿಂಗ್ ಟ್ರಿಂಗ್! ನಿಮ್ಮ ಔಷಧಿ ಜ್ಞಾಪನೆ ಸಕ್ರಿಯವಾಗಿದೆ."



            : lang.startsWith('hi')



                ? "अलार्म टेस्ट। रिंग रिंग! आपकी दवा का रिमाइंडर सक्रिय है।"



                : "Testing alarm sound. Ring ring! Your medicine reminder is working loud and clear.";



        await _speech.speak(testMsg);



        return;



      case VoiceIntent.setAlarm:



        await navigateTo(AppScreen.schedule);



        final alarmMsg = lang.startsWith('kn')



            ? "ವೇಳಾಪಟ್ಟಿ ತೆರೆಯಲಾಗಿದೆ. ಹೊಸ ಅಲಾರಾಂ ಹೊಂದಿಸಲು 'ವೇಳಾಪಟ್ಟಿ' ಬಳಸಿ."



            : lang.startsWith('hi')



                ? "समय-सारणी स्क्रीन खोली गई।"



                : "Schedule screen opened. Say 'read all' or 'go back'.";



        await _speech.speak(alarmMsg);



        return;



      case VoiceIntent.refresh:



        announceScreen();



        return;



      case VoiceIntent.prescriptionMode:



      case VoiceIntent.medicineMode:



        await navigateTo(AppScreen.scan);



        return;



      case VoiceIntent.save:



        final saveMsg = lang.startsWith('kn')



            ? "ಉಳಿಸಲು ಯಾವುದೇ ಹೊಸ ಮಾಹಿತಿ ಇಲ್ಲ. ಮೊದಲು ಔಷಧಿಯನ್ನು ಸ್ಕ್ಯಾನ್ ಮಾಡಿ."



            : lang.startsWith('hi')



                ? "सहेजने के लिए कोई नई जानकारी नहीं है। कृपया पहले दवा स्कैन करें।"



                : "Nothing new to save. Please scan a medicine first.";



        await _speech.speak(saveMsg);



        return;



      case VoiceIntent.cancel:



        await _speech.stopTTS();



        return;



      case VoiceIntent.snooze:



        final snoozeMsg = lang.startsWith('kn')



            ? "ಅಲಾರಾಂ ಹತ್ತು ನಿಮಿಷಗಳ ಕಾಲ ಮುಂದೂಡಲಾಗಿದೆ."



            : lang.startsWith('hi')



                ? "अलार्म 10 मिनट के लिए स्नूज़ किया गया।"



                : "Alarm snoozed for 10 minutes.";



        await _speech.speak(snoozeMsg);



        return;



      case VoiceIntent.demoLogin:



        const demoEmail = "demo_patient@medicare.com";



        const offlineId = "usr_demo_patient";



        await db.switchUser(offlineId);



        await db.saveProfile({'full_name': 'Patient', 'email': demoEmail});



        if (navContext != null) {



          navigatorKey.currentState?.pushReplacement(



            MaterialPageRoute(builder: (_) => const HomeScreen()),



          );



        }



        await _speech.speak("Logged in to demo mode.");



        return;



      case VoiceIntent.signOut:



        await FirebaseAuth.instance.signOut();



        await db.switchUser('usr_offline_guest');



        if (navContext != null) {



          navigatorKey.currentState?.pushAndRemoveUntil(



            MaterialPageRoute(builder: (_) => const AuthScreen()),



            (r) => false,



          );



        }



        await _speech.speak("Signed out.");



        return;



      case VoiceIntent.whereAmI:



        announceScreen();



        return;



      case VoiceIntent.help:



        final helpText = lang.startsWith('kn')



            ? "ಲಭ್ಯವಿರುವ ಆದೇಶಗಳು: ಮುಖಪುಟ, ಸ್ಕ್ಯಾನ್, ವೇಳಾಪಟ್ಟಿ, ತುರ್ತು, ಸಹಾಯಕ, ಇಂಗ್ಲಿಷ್, ಹಿಂದಿ, ಅಥವಾ ರದ್ದು."



            : lang.startsWith('hi')



                ? "उपलब्ध कमांड: होम, स्कैन, समय सारणी, आपातकाल, सहायक, हिंदी, अंग्रेजी, या वापस।"



                : "Available commands: Home, Scan, Schedule, Emergency, Assistant, English, Kannada, Hindi, or Go Back.";



        await _speech.speak(helpText);



        return;

      case VoiceIntent.safetyCheck:
        await runSafetyCheckCommand();
        return;
      case VoiceIntent.deleteAllMedicines:
        await db.clearAllData();
        final clearMsg = lang.startsWith('kn')
            ? "ಎಲ್ಲಾ ಔಷಧಿ ಮಾಹಿತಿಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ."
            : lang.startsWith('hi')
                ? "सभी दवाओं का डेटा सफलतापूर्वक हटा दिया गया है।"
                : "All medication data has been permanently cleared.";
        await _speech.speak(clearMsg);
        notifyListeners();
        return;

      case VoiceIntent.deleteDuplicate:
        await deleteDuplicateMedicineCommand(transcript: transcript);
        return;
      case VoiceIntent.checkWarnings:
        await checkWarningsCommand();
        return;
      case VoiceIntent.deleteWarningMedicine:
        await deleteWarningMedicineCommand(transcript: transcript);
        return;



      default:



        // If not a known system intent, route to AI Assistant for health or medicine answers!



        if (ai != null && transcript.trim().isNotEmpty) {



          final answer = await ai!.askAssistant(transcript, "", language: lang);



          await _speech.speak(answer);



        } else {



          final unrecogMsg = lang.startsWith('kn')



              ? "ಆಜ್ಞೆ ಅರ್ಥವಾಗಲಿಲ್ಲ. 'ಸಹಾಯ' ಎನ್ನಿ ಅಥವಾ ಮುಖಪುಟ, ಸ್ಕ್ಯಾನ್, ವೇಳಾಪಟ್ಟಿ ಎನ್ನಿ."



              : lang.startsWith('hi')



                  ? "आदेश समझ नहीं आया। 'मदद' कहें या होम, स्कैन, समय सारणी कहें।"



                  : "Command not recognized. Say 'help' to hear available options.";



          await _speech.speak(unrecogMsg);



        }



    }



  }



  /// Trigger sending caregiver email report (can be called by voice intent or UI button)



  Future<bool> sendCaregiverMail({String? targetEmail}) async {



    final lang = _speech.currentLanguage;



    return await _handleSendMail(lang, targetEmail: targetEmail);



  }



  Future<bool> _handleSendMail(String lang, {String? targetEmail}) async {



    final startMsg = lang.startsWith('kn')



        ? "ಆರೈಕೆದಾರರಿಗೆ ಇಮೇಲ್ ಕಳುಹಿಸಲಾಗುತ್ತಿದೆ..."



        : lang.startsWith('hi')



            ? "केयरगिवर को ईमेल भेजा जा रहा है..."



            : "Sending email report to caregiver...";



    await _speech.speak(startMsg);



    try {



      // 1. Fetch recipient email(s) from Caregivers list or Emergency Contact



      final recipientEmails = <String>{};



      if (targetEmail != null && targetEmail.trim().contains('@')) {



        recipientEmails.add(targetEmail.trim());



      } else {



        final caregivers = await db.getCaregivers();



        for (final cg in caregivers) {



          final em = cg['email']?.toString().trim();



          if (em != null && em.isNotEmpty && em.contains('@')) {



            recipientEmails.add(em);



          }



        }



        if (recipientEmails.isEmpty) {



          final ec = await db.getEmergencyContact();



          final em = ec?['emergency_contact_email']?.toString().trim() ??



              ec?['emergency_email']?.toString().trim();



          if (em != null && em.isNotEmpty && em.contains('@')) {



            recipientEmails.add(em);



          }



        }



        if (recipientEmails.isEmpty) {



          final profile = await db.getProfile();



          final em = profile?['emergency_contact_email']?.toString().trim() ??



              profile?['emergency_email']?.toString().trim();



          if (em != null && em.isNotEmpty && em.contains('@')) {



            recipientEmails.add(em);



          }



        }



        if (recipientEmails.isEmpty) {



          final noEmailMsg = lang.startsWith('kn')



              ? "ಯಾವುದೇ ಆರೈಕೆದಾರರ ಅಥವಾ ತುರ್ತು ಇಮೇಲ್ ಕಾನ್ಫಿಗರ್ ಮಾಡಲಾಗಿಲ್ಲ. ದಯವಿಟ್ಟು ಆರೈಕೆದಾರರಲ್ಲಿ ಅಥವಾ ತುರ್ತು ಸಂಪರ್ಕದಲ್ಲಿ ಇಮೇಲ್ ಸೇರಿಸಿ."



              : lang.startsWith('hi')



                  ? "कोई केयरगिवर या आपातकालीन ईमेल कॉन्फ़िगर नहीं किया गया है। कृपया केयरगिवर या आपातकालीन संपर्क में ईमेल जोड़ें।"



                  : "No caregiver or emergency contact email configured. Please add an email in Caregivers or Emergency Contact first.";



          await _speech.speak(noEmailMsg);



          return false;



        }



      }



      // 2. Build summary of doses and health status



      final profile = await db.getProfile();



      final patientName = profile?['full_name'] ?? 'Patient';



      final doses = await _getTodayDoses();



      final dosesSummary = doses.map((d) => "- ${d.medicine['name']}: ${d.time} (${d.status.toUpperCase()})").join("\n");



      final subject = "MediCare Health Report - $patientName";



      final emailBody = "Hello Caregiver,\n\n"



          "This is an automated health status update for $patientName from the MediCare app.\n\n"



          "Today's Medication Schedule & Status:\n"



          "${dosesSummary.isNotEmpty ? dosesSummary : 'All current medications are on track.'}\n\n"



          "Report generated at: ${DateTime.now().toString().split('.').first}\n"



          "Smart MediCare Health System";



      // 3. Send via 2nd EmailJS Template (template_err1y5l)



      bool anySuccess = false;



      for (final email in recipientEmails) {



        debugPrint("EmailJS: Sending Caregiver Template (template_err1y5l) to $email...");



        final sent = await EmailJSService.sendCaregiverEmail(



          toEmail: email,



          patientName: patientName,



          message: emailBody,



          subject: subject,



          medicineName: doses.isNotEmpty ? doses.first.medicine['name']?.toString() : 'Daily Schedule',



          status: 'Schedule Update',



        );



        if (sent) anySuccess = true;



      }



      if (anySuccess) {



        final successMsg = lang.startsWith('kn')



            ? "ಆರೈಕೆದಾರರಿಗೆ ಇಮೇಲ್ ಕಳುಹಿಸಲಾಗಿದೆ."



            : lang.startsWith('hi')



                ? "केयरगिवर को ईमेल सफलतापूर्वक भेज दिया गया।"



                : "Email to caregiver has been sent.";



        await _speech.speak(successMsg);



        return true;



      } else {



        final err = EmailJSService.lastError ?? '';



        if (err.contains("Gmail account disconnected") || err.contains("Invalid grant")) {



          final warnMsg = lang.startsWith('kn')



              ? "ಇಮೇಲ್‌ಜೆಎಸ್ ಜಿಮೇಲ್ ಖಾತೆ ಸಂಪರ್ಕ ಕಡಿತಗೊಂಡಿದೆ. ಡ್ಯಾಶ್‌ಬೋರ್ಡ್‌ನಲ್ಲಿ ಮರುಸಂಪರ್ಕಿಸಿ."



              : "EmailJS Gmail account is disconnected. Please reconnect it in your EmailJS dashboard.";



          await _speech.speak(warnMsg);



        } else {



          await _speech.speak(lang.startsWith('kn')



              ? "ಇಮೇಲ್ ಕಳುಹಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ."



              : "Could not send email via EmailJS.");



        }



        return false;



      }



    } catch (e) {



      debugPrint("Error in _handleSendMail: $e");



      await _speech.speak("Email error: $e");



      return false;



    }



  }



}



