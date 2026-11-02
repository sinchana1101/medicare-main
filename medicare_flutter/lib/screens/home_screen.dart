import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';
import '../services/alarm_setup_service.dart';
import '../services/database_service.dart';
import '../services/dose_utils.dart';
import '../services/side_effects_service.dart';
import '../services/voice_intent_service.dart';
import '../services/i18n_service.dart';
import '../services/ai_service.dart';
import '../services/voice_controller.dart';
import 'camera_screen.dart';
import 'scan_screen.dart';
import 'schedule_screen.dart';
import 'assistant_screen.dart';
import 'emergency_screen.dart';
import 'settings_screen.dart';

PageRouteBuilder<T> _fastFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 100),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> implements VoiceScreenDelegate {
  VoiceController? _voiceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _voiceController = Provider.of<VoiceController>(context, listen: false);
    } catch (_) {}
  }

  List<TodayDose> _todayDoses = [];
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  int _currentNavIndex = 0;
  static bool _initialSummarySpoken = false;

  void _resumeHomeVoice() {
    if (!mounted) return;
    try {
      final voice = Provider.of<VoiceController>(context, listen: false);
      voice.setActiveDelegate(this, AppScreen.home);
      // Mic state preserved (toggled only by double-tap)
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final voice = Provider.of<VoiceController>(context, listen: false);
        voice.setActiveDelegate(this, AppScreen.home);
        // Mic state preserved (toggled only by double-tap)
      }
    });
  }

  @override
  void dispose() {
    try {
      _voiceController?.clearActiveDelegate(this);
    } catch (_) {}
    super.dispose();
  }

  @override
  String getScreenAnnouncement() {
    if (!mounted) return "";
    final speech = Provider.of<SpeechService>(context, listen: false);
    final sideEffectWarnings = SideEffectsService.evaluateMedicines(_medicines, language: speech.currentLanguage);
    String warnText = "";
    if (sideEffectWarnings.isNotEmpty) {
      warnText = speech.currentLanguage.startsWith('kn')
          ? " ${sideEffectWarnings.length} ಔಷಧಿಗಳಲ್ಲಿ ಎಚ್ಚರಿಕೆಗಳಿವೆ."
          : speech.currentLanguage.startsWith('hi')
              ? " ${sideEffectWarnings.length} दवाओं में चेतावनियां हैं।"
              : " There are ${sideEffectWarnings.length} medication warnings.";
    }
    final summary = DoseUtils.spokenSummary(_todayDoses, language: speech.currentLanguage) + warnText;
    final hint = speech.currentLanguage.startsWith('kn')
        ? "ಹೇಳಿ: 'ತೆಗೆದುಕೊಂಡೆ', 'ಮುಂದಿನ ಔಷಧಿ', 'ಸ್ಕ್ಯಾನ್', ಅಥವಾ 'ತುರ್ತು'."
        : speech.currentLanguage.startsWith('hi')
            ? "कहें: 'ले ली', 'अगली दवा', 'स्कैन', या 'आपातकाल'।"
            : "Say: 'mark taken', 'next medicine', 'scan', 'emergency', or 'help'.";
    return "$summary. $hint";
  }

  @override
  Future<bool> handleVoiceCommand(VoiceIntent? intent, String transcript) async {
    if (!mounted) return false;
    final setup = Provider.of<AlarmSetupService>(context, listen: false);
    final speech = Provider.of<SpeechService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final lang = speech.currentLanguage;
    final lower = transcript.toLowerCase().trim();
    debugPrint("HomeScreen handleVoiceCommand: '$transcript' (intent: $intent)");

    // Instant robust scan navigation: triggers on VoiceIntent.scan OR any scan/scanner/camera/prescription keyword in transcript!
    if (intent == VoiceIntent.scan ||
        lower == "scan" ||
        lower == "can" ||
        lower == "scam" ||
        lower == "skan" ||
        lower == "scann" ||
        lower == "scanner" ||
        lower == "camera" ||
        lower == "cam" ||
        lower == "open scan" ||
        lower == "open scanner" ||
        lower == "open camera" ||
        lower == "go to scan" ||
        lower == "goto scan" ||
        lower == "to scan" ||
        lower == "scan please" ||
        lower == "from home to scan" ||
        lower == "home to scan" ||
        lower == "scan screen" ||
        lower == "scan medicine" ||
        lower == "scan box" ||
        lower == "prescription" ||
        lower == "scan prescription" ||
        lower.contains("scan") ||
        lower.contains("scanner") ||
        lower.contains("prescription") ||
        transcript.contains("ಸ್ಕ್ಯಾನ್") ||
        transcript.contains("ಸ್ಕಾನರ್") ||
        transcript.contains("ಕ್ಯಾಮೆರಾ") ||
        transcript.contains("ಕ್ಯಾಮರಾ") ||
        transcript.contains("ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್") ||
        transcript.contains("ಸ್ಕ್ರೀನ್") ||
        transcript.contains("स्कैन") ||
        transcript.contains("स्कैनर") ||
        transcript.contains("कैमरा") ||
        transcript.contains("पर्चा")) {
      final scanMsg = lang.startsWith('kn')
          ? 'ಸ್ಕ್ಯಾನ್.'
          : (lang.startsWith('hi') ? 'स्कैन।' : 'Scan.');
      speech.speak(scanMsg);
      setState(() => _currentNavIndex = 1);
      try {
        Navigator.push(
          context,
          _fastFadeRoute(const ScanScreen()),
        ).then((_) {
          if (mounted) {
            setState(() => _currentNavIndex = 0);
            _resumeHomeVoice();
            _loadData();
          }
        });
      } catch (_) {
        VoiceController.navigatorKey.currentState?.push(
          _fastFadeRoute(const ScanScreen()),
        ).then((_) {
          if (mounted) {
            setState(() => _currentNavIndex = 0);
            _resumeHomeVoice();
            _loadData();
          }
        });
      }
      return true;
    }

    if (intent == VoiceIntent.deleteAllMedicines ||

        lower.contains("delete all data") ||

        lower.contains("clear all data") ||

        lower.contains("delete all medicines") ||

        transcript.contains("ಎಲ್ಲಾ ಡೇಟಾ ಅಳಿಸಿ") ||

        transcript.contains("ಎಲ್ಲಾ ಔಷಧಿಗಳನ್ನು ಅಳಿಸಿ") ||

        transcript.contains("सारा डेटा हटाएं")) {

      await db.clearAllData();

      await _loadData();

      final clearMsg = lang.startsWith('kn')

          ? "ಎಲ್ಲಾ ಔಷಧಿ ಮಾಹಿತಿಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ."

          : lang.startsWith('hi')

              ? "सभी दवाओं का डेटा सफलतापूर्वक हटा दिया गया है।"

              : "All medication data has been permanently cleared.";

      speech.speak(clearMsg);

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(clearMsg),

            backgroundColor: const Color(0xFFDC2626),

            behavior: SnackBarBehavior.floating,

          ),

        );

      }

      return true;

    }



    if (intent == VoiceIntent.deleteAllMedicines ||
        lower.contains("delete all data") ||
        lower.contains("clear all data") ||
        lower.contains("delete all medicines") ||
        transcript.contains("ಎಲ್ಲಾ ಡೇಟಾ ಅಳಿಸಿ") ||
        transcript.contains("ಎಲ್ಲಾ ಔಷಧಿಗಳನ್ನು ಅಳಿಸಿ") ||
        transcript.contains("सारा डेटा हटाएं")) {
      await db.clearAllData();
      await _loadData();
      final clearMsg = lang.startsWith('kn')
          ? "ಎಲ್ಲಾ ಔಷಧಿ ಮಾಹಿತಿಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ."
          : lang.startsWith('hi')
              ? "सभी दवाओं का डेटा सफलतापूर्वक हटा दिया गया है।"
              : "All medication data has been permanently cleared.";
      speech.speak(clearMsg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(clearMsg),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    }

    if (intent == VoiceIntent.deleteDuplicate ||
        lower.contains("delete duplicate") ||
        lower.contains("remove duplicate") ||
        transcript.contains("ನಕಲಿ ಔಷಧಿ ಅಳಿಸಿ") ||
        transcript.contains("ನಕಲಿ ತೆಗೆದುಹಾಕಿ") ||
        transcript.contains("डुप्लीकेट दवा हटाएं") ||
        transcript.contains("नकली दवा हटाएं")) {
      final voiceCtrl = Provider.of<VoiceController>(context, listen: false);
      await voiceCtrl.deleteDuplicateMedicineCommand(transcript: transcript);
      await _loadData();
      return true;
    }

    if (intent == VoiceIntent.safetyCheck ||
        lower.contains("safety check") ||
        lower.contains("check safety") ||
        lower.contains("run safety check") ||
        lower.contains("check my medicines") ||
        transcript.contains("ಸುರಕ್ಷತೆ") ||
        transcript.contains("ಪರಿಶೀಲನೆ") ||
        transcript.contains("सुरक्षा") ||
        transcript.contains("जांच")) {
      final voiceCtrl = Provider.of<VoiceController>(context, listen: false);
      await voiceCtrl.runSafetyCheckCommand();
      await _loadData();
      return true;
    }

    switch (intent) {
      case VoiceIntent.markTaken:
        final pending = _todayDoses.where((d) => d.status != 'taken').toList();
        if (pending.isNotEmpty) {
          final target = pending.first;
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
          speech.speak(done);
          await _loadData();
        } else {
          speech.speak(lang.startsWith('kn') ? "ಇಂದಿನ ಎಲ್ಲಾ ಔಷಧಿಗಳನ್ನು ಈಗಾಗಲೇ ತೆಗೆದುಕೊಳ್ಳಲಾಗಿದೆ." : "All medicines for today are already marked as taken.");
        }
        return true;

      case VoiceIntent.skipDose:
        final pending = _todayDoses.where((d) => d.status != 'taken').toList();
        if (pending.isNotEmpty) {
          final target = pending.first;
          final medName = target.medicine['name'] ?? 'Medicine';
          await db.logDose(
            target.medicine['id'],
            'skipped',
            scheduleId: target.schedule['id'],
            scheduledFor: target.scheduledFor,
          );
          speech.speak(lang.startsWith('kn')
              ? "$medName ಬಿಟ್ಟುಬಿಡಲಾಗಿದೆ. ಆರೈಕೆದಾರರಿಗೆ ಎಚ್ಚರಿಕೆ ಕಳುಹಿಸಲಾಗಿದೆ."
              : "Skipped $medName. Caregiver notified.");
          await _loadData();
        } else {
          speech.speak("No pending doses to skip.");
        }
        return true;

      case VoiceIntent.nextMedicine:
        final pending = _todayDoses.where((d) => d.status != 'taken').toList();
        if (pending.isNotEmpty) {
          final next = pending.first;
          final time = DoseUtils.friendlyTime(next.time);
          final name = next.medicine['name'] ?? 'Medicine';
          speech.speak(lang.startsWith('kn')
              ? "ನಿಮ್ಮ ಮುಂದಿನ ಔಷಧಿ $name, ಸಮಯ $time."
              : "Your next medicine is $name at $time.");
        } else {
          speech.speak(lang.startsWith('kn') ? "ಇಂದು ಮುಂದೆ ಯಾವುದೇ ಬಾಕಿ ಔಷಧಿಗಳಿಲ್ಲ." : "No upcoming doses left for today.");
        }
        return true;

      case VoiceIntent.home:
        final homeMsg = lang.startsWith('kn')
            ? 'ಮುಖಪುಟ.'
            : (lang.startsWith('hi') ? 'मुख्य पृष्ठ।' : 'Home.');
        speech.speak(homeMsg);
        return true;

      case VoiceIntent.scan:
        final scanMsg = lang.startsWith('kn')
            ? 'ಸ್ಕ್ಯಾನ್.'
            : (lang.startsWith('hi') ? 'स्कैन।' : 'Scan.');
        speech.speak(scanMsg);
        setState(() => _currentNavIndex = 1);
        try {
          Navigator.push(
            context,
            _fastFadeRoute(const ScanScreen()),
          ).then((_) {
            if (mounted) {
              setState(() => _currentNavIndex = 0);
              _resumeHomeVoice();
              _loadData();
            }
          });
        } catch (_) {
          VoiceController.navigatorKey.currentState?.push(
            _fastFadeRoute(const ScanScreen()),
          ).then((_) {
            if (mounted) {
              setState(() => _currentNavIndex = 0);
              _resumeHomeVoice();
              _loadData();
            }
          });
        }
        return true;

      case VoiceIntent.readPage:
      case VoiceIntent.repeat:
        speech.speak(getScreenAnnouncement());
        return true;

      case VoiceIntent.takePhoto:
        final camMsg = lang.startsWith('kn')
            ? "ಕ್ಯಾಮೆರಾ ತೆರೆಯಲಾಗುತ್ತಿದೆ."
            : (lang.startsWith('hi') ? "कैमरा खोला जा रहा है।" : "Opening camera.");
        speech.speak(camMsg);
        Navigator.push<String>(
          context,
          _fastFadeRoute(const CameraScreen(autoCapture: false)),
        ).then((capturedPath) {
          if (mounted) {
            final voice = Provider.of<VoiceController>(context, listen: false);
            voice.setActiveDelegate(this, AppScreen.home);
            if (capturedPath != null && capturedPath.isNotEmpty) {
              Navigator.push(
                context,
                _fastFadeRoute(ScanScreen(initialImagePath: capturedPath)),
              ).then((_) {
                if (mounted) {
                  final voice = Provider.of<VoiceController>(context, listen: false);
                  voice.setActiveDelegate(this, AppScreen.home);
                  _loadData();
                }
              });
            } else {
              _loadData();
            }
          }
        });
        return true;

      case VoiceIntent.setAlarm:
        setup.start();
        return true;

      case VoiceIntent.refresh:
        await _loadData();
        speech.speak("Dashboard refreshed.");
        return true;

      case VoiceIntent.sendMail:
        final voice = Provider.of<VoiceController>(context, listen: false);
        await voice.sendCaregiverMail();
        return true;

      case VoiceIntent.safetyCheck:
        final voiceCtrl = Provider.of<VoiceController>(context, listen: false);
        await voiceCtrl.runSafetyCheckCommand();
        await _loadData();
        return true;

      case VoiceIntent.checkWarnings:
        final lang = speech.currentLanguage;
        final sideEffectWarnings = SideEffectsService.evaluateMedicines(_medicines, language: lang);
        final summary = SideEffectsService.buildSpokenSummary(sideEffectWarnings, language: lang);
        speech.speak(summary);
        _showSideEffectsWarningSheet(context);
        return true;

      case VoiceIntent.schedule:
        final schedMsg = lang.startsWith('kn')
            ? "ವೇಳಾಪಟ್ಟಿ."
            : (lang.startsWith('hi') ? "समय सारणी।" : "Schedule.");
        speech.speak(schedMsg);
        _onBottomNavTapped(2);
        return true;

      case VoiceIntent.assistant:
        final astMsg = lang.startsWith('kn')
            ? "ಸಹಾಯಕ."
            : (lang.startsWith('hi') ? "सहायक।" : "Assistant.");
        speech.speak(astMsg);
        _onBottomNavTapped(3);
        return true;

      case VoiceIntent.more:
        final setMsg = lang.startsWith('kn')
            ? "ಸೆಟ್ಟಿಂಗ್ಸ್."
            : (lang.startsWith('hi') ? "सेटिंग्स।" : "Settings.");
        speech.speak(setMsg);
        _onBottomNavTapped(4);
        return true;

      case VoiceIntent.emergency:
        final emgMsg = lang.startsWith('kn')
            ? "ತುರ್ತು."
            : (lang.startsWith('hi') ? "आपातकाल।" : "Emergency.");
        speech.speak(emgMsg);
        Navigator.push(context, _fastFadeRoute(const EmergencyScreen()));
        return true;

      case VoiceIntent.deleteWarningMedicine:
        final lang = speech.currentLanguage;
        final sideEffectWarnings = SideEffectsService.evaluateMedicines(_medicines, language: lang);
        if (sideEffectWarnings.isNotEmpty) {
          final target = sideEffectWarnings.first;
          await db.deleteMedicine(target.medicineId);
          final msg = lang.startsWith('kn')
              ? "${target.name} ಔಷಧಿಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ."
              : lang.startsWith('hi')
                  ? "${target.name} दवा को सफलतापूर्वक हटा दिया गया है।"
                  : "${target.name} medicine has been deleted.";
          speech.speak(msg);
          await _loadData();
        } else {
          speech.speak(lang.startsWith('kn') ? "ಅಳಿಸಲು ಯಾವುದೇ ಎಚ್ಚರಿಕೆ ಔಷಧಿಗಳಿಲ್ಲ." : "No warning medicines to delete.");
        }
        return true;

      default:
        return false;
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final db = Provider.of<DatabaseService>(context, listen: false);
    final speech = Provider.of<SpeechService>(context, listen: false);

    // Instant local memory render for 0ms initial load
    final localMeds = db.localMedicines;
    final localScheds = db.localSchedules;
    final localLogs = db.localDoseLogs;
    final localAlerts = db.localAlerts;
    if (localMeds.isNotEmpty || localScheds.isNotEmpty || localAlerts.isNotEmpty) {
      if (mounted) {
        setState(() {
          _medicines = localMeds;
          _todayDoses = DoseUtils.buildTodayDoses(
            medicines: localMeds,
            schedules: localScheds,
            logs: localLogs,
          );
          _alerts = localAlerts.where((a) => a['acknowledged'] == false).toList();
          _isLoading = false;
        });
      }
    }

    try {
      final results = await Future.wait([
        db.getMedicines(),
        db.getSchedules(),
        db.getDoseLogs(),
        db.getAlerts(),
        db.getProfile(),
      ]);
      final medicines = results[0] as List<Map<String, dynamic>>;
      final schedules = results[1] as List<Map<String, dynamic>>;
      final logs = results[2] as List<Map<String, dynamic>>;
      final alertsData = results[3] as List<Map<String, dynamic>>;
      final profileData = results[4] as Map<String, dynamic>?;
      if (!mounted) return;
      if (profileData != null && profileData['gemini_api_key'] != null && profileData['gemini_api_key'].toString().trim().isNotEmpty) {
        final ai = Provider.of<AIService>(context, listen: false);
        ai.setApiKey(profileData['gemini_api_key'].toString().trim());
      }
      if (profileData != null && profileData['preferred_language'] != null && profileData['preferred_language'].toString().isNotEmpty) {
        final prefLang = profileData['preferred_language'].toString();
        if (speech.currentLanguage != prefLang) {
          speech.currentLanguage = prefLang;
          debugPrint("HomeScreen: Synced SpeechService language to profile: $prefLang");
        }
      }

      setState(() {
        _profile = profileData;
        _medicines = medicines;
        _todayDoses = DoseUtils.buildTodayDoses(
          medicines: medicines,
          schedules: schedules,
          logs: logs,
        );
        _alerts = alertsData.where((a) => a['acknowledged'] == false).toList();
        _isLoading = false;
      });

      // Real-time automatic medication safety & duplicate check
      if (medicines.length >= 2 && !_isCheckingSafety) {
        _runRealtimeSafetyCheck();
      }

      // Spoken overview on first load in selected language
      if (!_initialSummarySpoken) {
        _initialSummarySpoken = true;
        final summary = DoseUtils.spokenSummary(_todayDoses, language: speech.currentLanguage);
        speech.speak(summary);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);

    switch (index) {
      case 0:
        // Already home
        break;
      case 1:
        Navigator.push(context, _fastFadeRoute(const ScanScreen())).then((_) {
          setState(() => _currentNavIndex = 0);
          _resumeHomeVoice();
          _loadData();
        });
        break;
      case 2:
        Navigator.push(context, _fastFadeRoute(const ScheduleScreen())).then((_) {
          setState(() => _currentNavIndex = 0);
          _resumeHomeVoice();
          _loadData();
        });
        break;
      case 3:
        Navigator.push(context, _fastFadeRoute(const AssistantScreen())).then((_) {
          setState(() => _currentNavIndex = 0);
          _resumeHomeVoice();
        });
        break;
      case 4:
        Navigator.push(context, _fastFadeRoute(const SettingsScreen())).then((_) {
          setState(() => _currentNavIndex = 0);
          _resumeHomeVoice();
          _loadData();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final speech = Provider.of<SpeechService>(context);
    final setup = Provider.of<AlarmSetupService>(context);
    final db = Provider.of<DatabaseService>(context);
    final t = Provider.of<I18nService>(context);

    final sideEffectWarnings = SideEffectsService.evaluateMedicines(_medicines, language: speech.currentLanguage);
    final summary = DoseUtils.spokenSummary(_todayDoses, language: speech.currentLanguage);
    final userName = _profile?['full_name']?.toString().split(" ").first ?? "there";
    final formattedDate = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('home.hello', speech.currentLanguage, vars: {'name': userName}),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 14, color: Color(0xFFECFDF5), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          // Safety Check Shield with notification inside the shield
          IconButton(
            tooltip: "Safety Alerts & Duplicate Check",
            icon: SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _alerts.isNotEmpty ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _alerts.isNotEmpty ? const Color(0xFFDC2626) : Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                  ),
                  if (_alerts.isNotEmpty)
                    Positioned(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                        ),
                        child: Text(
                          "${_alerts.length}",
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            onPressed: () => _showSafetyShieldSheet(context),
          ),
          // Medicine Warnings & Side Effects Icon near the shield
          IconButton(
            tooltip: "Medicine Warnings & Side Effects",
            icon: SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: sideEffectWarnings.isNotEmpty ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sideEffectWarnings.isNotEmpty ? const Color(0xFFD97706) : Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                  ),
                  if (sideEffectWarnings.isNotEmpty)
                    Positioned(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                        ),
                        child: Text(
                          "${sideEffectWarnings.length}",
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            onPressed: () => _showSideEffectsWarningSheet(context),
          ),
          // Read aloud button
          IconButton(
            tooltip: "Read today's schedule aloud",
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
            ),
            onPressed: () => speech.speak(summary),
          ),
          // Push-to-talk microphone button
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
                    size: 24,
                  ),
                ),
                onPressed: () async {
                  if (!voice.isContinuousMode) {
                    await voice.startContinuousListening(customAnnouncement: "");
                  } else {
                    await voice.startContinuousListening(customAnnouncement: "");
                  }
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
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF059669),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                // Today Summary Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t.translate('home.today', speech.currentLanguage),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colors.white70,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t.translate('home.doses', speech.currentLanguage, vars: {'count': _todayDoses.length.toString()}),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

// Safety alerts are housed inside the Shield icon

                // Today's Doses Header
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.translate('home.todaysSchedule', speech.currentLanguage),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF059669),
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScheduleScreen()),
                      ).then((_) => _loadData()),
                      icon: const Icon(Icons.calendar_month, size: 16, color: Color(0xFF059669)),
                      label: Text(
                        t.translate('home.allSchedules', speech.currentLanguage),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Dose Tiles List - Grouped by medicine so details never appear twice
                if (_todayDoses.isEmpty)
                  _buildEmptyState(t, speech)
                else
                  ...DoseUtils.groupTodayDoses(_todayDoses).map(
                    (g) => _MedicineGroupTile(group: g, onUpdate: _loadData, t: t, speech: speech),
                  ),

// Safety action is housed directly inside the Shield icon

                // Saved Medicines Section
                if (_medicines.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.translate('medicines.title', speech.currentLanguage),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        "${_medicines.length} saved",
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._medicines.map((m) => _buildMedicineCard(m, t, speech, db)),
                ],
              ],
            ),
          ),

          // Floating SOS Button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'sos_btn',
              backgroundColor: const Color(0xFFEF4444),
              elevation: 8,
              onPressed: () {
                speech.speak("Opening emergency help.");
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyScreen()));
              },
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              label: Text(
                t.translate('home.sos', speech.currentLanguage),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white),
              ),
            ),
          ),

          if (setup.isRunning) _AlarmSetupOverlay(setup: setup),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
        ],
      ),

      // Fixed 5-Tab Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: _onBottomNavTapped,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF059669),
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: t.translate('nav.home', speech.currentLanguage),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.document_scanner_rounded),
              label: t.translate('nav.scan', speech.currentLanguage),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month_rounded),
              label: t.translate('nav.schedule', speech.currentLanguage),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_rounded),
              label: t.translate('nav.assistant', speech.currentLanguage),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: t.translate('nav.more', speech.currentLanguage),
            ),
          ],
        ),
      ),
    );
  }

  void _showSideEffectsWarningSheet(BuildContext context) {
    final speech = Provider.of<SpeechService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final lang = speech.currentLanguage;

    final headerTitle = lang.startsWith('kn')
        ? "ಔಷಧಿ ಎಚ್ಚರಿಕೆಗಳು & ಅಡ್ಡಪರಿಣಾಮಗಳು"
        : lang.startsWith('hi')
            ? "दवा चेतावनियां और साइड इफेक्ट्स"
            : "Medicine Warnings & Side Effects";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentWarnings = SideEffectsService.evaluateMedicines(_medicines, language: lang);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: currentWarnings.isNotEmpty ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: currentWarnings.isNotEmpty ? const Color(0xFFD97706) : const Color(0xFF059669),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: currentWarnings.isNotEmpty ? const Color(0xFFD97706) : const Color(0xFF059669),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            currentWarnings.isNotEmpty
                                ? "${currentWarnings.length} medicine(s) with side effects/warnings"
                                : "All medicines verified safe",
                            style: TextStyle(
                              fontSize: 13,
                              color: currentWarnings.isNotEmpty ? const Color(0xFFD97706) : const Color(0xFF059669),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                if (currentWarnings.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "No severe side effects or critical warning alerts detected for your medications.",
                            style: TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: currentWarnings.length,
                      itemBuilder: (context, i) {
                        final warn = currentWarnings[i];
                        return _buildWarningCard(warn, db, modalContext: ctx, onDeleted: () {
                          setModalState(() {});
                        });
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWarningCard(
    MedicineWarningItem item,
    DatabaseService db, {
    BuildContext? modalContext,
    VoidCallback? onDeleted,
  }) {
    final isCrit = item.severity == 'critical';
    final bgColor = isCrit ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final borderColor = isCrit ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
    final titleColor = isCrit ? const Color(0xFF991B1B) : const Color(0xFF92400E);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCrit ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCrit ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                  color: borderColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.strength.isNotEmpty ? "${item.name} (${item.strength})" : item.name,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: titleColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCrit ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCrit ? "CRITICAL RISK" : "PRECAUTION",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          if (item.packagingWarning != null && item.packagingWarning!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.report_problem_rounded, color: borderColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.packagingWarning!,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: titleColor),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (item.sideEffects.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              "Reported Side Effects:",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            ...item.sideEffects.map((se) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(" • ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                  Expanded(
                    child: Text(
                      se,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.3),
                    ),
                  ),
                ],
              ),
            )),
          ],

          if (item.warnings.isNotEmpty || item.precautions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              "Important Precautions & Safe Limits:",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            ...item.warnings.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(" ⚠️ ", style: TextStyle(fontSize: 11)),
                  Expanded(
                    child: Text(
                      w,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
                    ),
                  ),
                ],
              ),
            )),
            ...item.precautions.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(" ℹ️ ", style: TextStyle(fontSize: 11)),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
                    ),
                  ),
                ],
              ),
            )),
          ],

          const SizedBox(height: 14),
          // DELETE OPTION FOR THE MEDICINE WITH WARNING
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _confirmAndDeleteWarningMedicine(item, db, modalContext: modalContext, onDeleted: onDeleted),
              icon: const Icon(Icons.delete_forever_rounded, size: 20, color: Colors.white),
              label: Text(
                "DELETE MEDICINE (${item.name})",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteWarningMedicine(
    MedicineWarningItem item,
    DatabaseService db, {
    BuildContext? modalContext,
    VoidCallback? onDeleted,
  }) async {
    final speech = Provider.of<SpeechService>(context, listen: false);

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
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Delete ${item.name}?",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        content: Text(
          "Do you want to permanently delete ${item.name} from your medicines due to side effects / warnings?\n\nThis will remove all schedules and dose reminders for this medication.",
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text("DELETE MEDICINE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 1. Delete medicine from database & RTDB
    await db.deleteMedicine(item.medicineId);

    // 2. Voice announcement
    final lang = speech.currentLanguage;
    final deletedMsg = lang.startsWith('kn')
        ? "${item.name} ಔಷಧಿಯನ್ನು ಅಳಿಸಲಾಗಿದೆ."
        : lang.startsWith('hi')
            ? "${item.name} दवा को हटा दिया गया है।"
            : "${item.name} medicine has been deleted.";
    await speech.speak(deletedMsg);

    // 3. Reload data
    await _loadData();
    onDeleted?.call();

    // 4. Dismiss modal sheet if open
    if (mounted && modalContext != null && Navigator.canPop(modalContext)) {
      Navigator.pop(modalContext);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🗑️ ${item.name} deleted"),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  bool _isCheckingSafety = false;
  Future<void> _runRealtimeSafetyCheck() async {
    if (_isCheckingSafety || !mounted) return;
    _isCheckingSafety = true;
    try {
      final ai = Provider.of<AIService>(context, listen: false);
      final db = Provider.of<DatabaseService>(context, listen: false);
      final speech = Provider.of<SpeechService>(context, listen: false);

      final results = await ai.runSafetyCheck(
        _medicines,
        language: speech.currentLanguage,
      );

      final returnedAlerts = (results['alerts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (returnedAlerts.isNotEmpty) {
        await db.replaceAlerts(returnedAlerts);
      }
      final latestAlerts = await db.getAlerts();
      if (mounted) {
        setState(() {
          _alerts = latestAlerts.where((a) => a['acknowledged'] == false).toList();
        });
      }
    } catch (e) {
      debugPrint("Realtime safety check note: $e");
    } finally {
      if (mounted) _isCheckingSafety = false;
    }
  }

  void _showSafetyShieldSheet(BuildContext context) {
    final t = Provider.of<I18nService>(context, listen: false);
    final speech = Provider.of<SpeechService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final voiceCtrl = Provider.of<VoiceController>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _alerts.isNotEmpty ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _alerts.isNotEmpty ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      color: _alerts.isNotEmpty ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Safety & Duplicate Check",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          _alerts.isNotEmpty
                              ? "${_alerts.length} safety alert(s) detected"
                              : "All medicines verified safe",
                          style: TextStyle(
                            fontSize: 13,
                            color: _alerts.isNotEmpty ? const Color(0xFFDC2626) : const Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Real-Time Safety & Duplicate Monitoring Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "AI Real-Time Verification Active: Duplicate & safety alerts update automatically.",
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Alerts list inside the Shield
              if (_alerts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "No duplicate medications or dangerous drug interactions found.",
                          style: TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _alerts.length,
                    itemBuilder: (context, i) {
                      final a = _alerts[i];
                      return _buildAlertCard(a, db, modalContext: ctx, onDeleted: () {
                        setModalState(() {});
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(
    Map<String, dynamic> alert,
    DatabaseService db, {
    BuildContext? modalContext,
    VoidCallback? onDeleted,
  }) {
    final alertTitle = (alert['title'] ?? '').toString();
    final alertMsg = (alert['message'] ?? '').toString();
    final lowerTitle = alertTitle.toLowerCase();
    final lowerMsg = alertMsg.toLowerCase();

    final isDuplicate = alert['alert_type'] == 'duplicate' ||
        lowerTitle.contains('duplicate') ||
        alertTitle.contains('ನಕಲಿ') ||
        alertTitle.contains('डुप्लीकेट') ||
        lowerMsg.contains('duplicate') ||
        (alert['duplicate_medicine'] != null && alert['duplicate_medicine'].toString().trim().isNotEmpty);

    final isCrit = alert['severity'] == 'critical' || isDuplicate;

    String dupName = (alert['duplicate_medicine'] ?? '').toString().trim();
    if (dupName.isEmpty) {
      if (alertTitle.contains(':')) {
        dupName = alertTitle.split(':').last.trim();
      } else if (lowerTitle.contains('duplicate')) {
        dupName = alertTitle.replaceAll(RegExp(r'(?i)duplicate\s*:?'), '').trim();
      }
    }
    if (dupName.isEmpty) {
      dupName = "Duplicate Medicine";
    }
    final bgColor = isCrit ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final borderColor = isCrit ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
    final iconColor = isCrit ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
    final titleColor = isCrit ? const Color(0xFF991B1B) : const Color(0xFF92400E);
    final msgColor = isCrit ? const Color(0xFF7F1D1D) : const Color(0xFF78350F);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(isCrit ? Icons.error_outline_rounded : Icons.warning_amber_rounded, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['title'] ?? "Refill / Safety Notice",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert['message'] ?? "",
                      style: TextStyle(fontSize: 13, color: msgColor, height: 1.35),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: "Dismiss alert",
                icon: Icon(Icons.check_circle_outline_rounded, color: iconColor, size: 26),
                onPressed: () async {
                  await db.acknowledgeAlert(alert['id']);
                  await _loadData();
                  onDeleted?.call();
                },
              ),
            ],
          ),
          if (isDuplicate) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _confirmAndDeleteDuplicate(alert, db, modalContext: modalContext, onDeleted: onDeleted),
                icon: const Icon(Icons.delete_forever_rounded, size: 20, color: Colors.white),
                label: Text(
                  dupName.isNotEmpty ? "DELETE DUPLICATE ($dupName)" : "DELETE DUPLICATE MEDICINE",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteDuplicate(
    Map<String, dynamic> alert,
    DatabaseService db, {
    BuildContext? modalContext,
    VoidCallback? onDeleted,
  }) async {
    final speech = Provider.of<SpeechService>(context, listen: false);
    final voiceCtrl = Provider.of<VoiceController>(context, listen: false);
    final dupName = (alert['duplicate_medicine'] ?? 'Duplicate Medicine').toString();
    final origName = (alert['original_medicine'] ?? 'Original Medicine').toString();

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
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Delete Duplicate?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        content: Text(
          "Do you want to permanently delete $dupName from your medications and schedule?\n\n$origName is your original prescribed medicine.",
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text("DELETE MEDICINE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 1. Identify medicine id
    String? targetMedId = alert['duplicate_medicine_id']?.toString();
    if (targetMedId == null || targetMedId.isEmpty) {
      final cleanDup = dupName.trim().toLowerCase();
      for (final m in _medicines) {
        final mName = (m['name'] ?? '').toString().trim().toLowerCase();
        final mStrength = (m['strength'] ?? '').toString().trim().toLowerCase();
        if (cleanDup == mName || cleanDup.contains(mName) || (mStrength.isNotEmpty && cleanDup.contains(mStrength))) {
          targetMedId = m['id']?.toString();
          break;
        }
      }
    }

    // 2. Delete medicine from database & RTDB
    if (targetMedId != null && targetMedId.isNotEmpty) {
      await db.deleteMedicine(targetMedId);
    }

    // 3. Acknowledge alert
    if (alert['id'] != null) {
      await db.acknowledgeAlert(alert['id'].toString());
    }

    // 4. Voice announcement
    final lang = speech.currentLanguage;
    final deletedMsg = lang.startsWith('kn')
        ? "$dupName ನಕಲಿ ಔಷಧಿಯನ್ನು ಅಳಿಸಲಾಗಿದೆ."
        : lang.startsWith('hi')
            ? "$dupName डुप्लीकेट दवा को हटा दिया गया है।"
            : "$dupName duplicate medicine has been deleted.";
    await speech.speak(deletedMsg);

    // 5. Re-run safety check & reload data
    await voiceCtrl.runSafetyCheckCommand();
    await _loadData();
    onDeleted?.call();

    // 6. Dismiss bottom sheet if all alerts resolved
    if (mounted && modalContext != null && Navigator.canPop(modalContext)) {
      Navigator.pop(modalContext);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🗑️ $dupName duplicate medicine deleted"),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmAndDeleteMedicine(Map<String, dynamic> med, DatabaseService db) async {
    final name = med['name'] ?? 'Medicine';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete $name?"),
        content: Text("Are you sure you want to remove $name from your saved medicines?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
    if (confirm == true && med['id'] != null) {
      await db.deleteMedicine(med['id'].toString());
      final voiceCtrl = Provider.of<VoiceController>(context, listen: false);
      await voiceCtrl.runSafetyCheckCommand();
      await _loadData();
    }
  }

  Widget _buildMedicineCard(Map<String, dynamic> med, I18nService t, SpeechService speech, DatabaseService db) {
    final name = med['name']?.toString() ?? 'Medicine';
    final strength = med['strength']?.toString() ?? '';
    final form = med['form']?.toString() ?? 'Tablet';
    final dosage = med['dosage']?.toString() ?? '1 dose';
    final instructions = med['instructions']?.toString() ?? med['purpose']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_rounded, color: Color(0xFF059669), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                      ),
                    ),
                    if (strength.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          strength,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  instructions.isNotEmpty ? instructions : "$form • $dosage",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Delete medicine",
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
            onPressed: () => _confirmAndDeleteMedicine(med, db),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(I18nService t, SpeechService speech) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.medication_liquid_rounded, size: 70, color: Color(0xFF059669)),
          const SizedBox(height: 16),
          Text(
            t.translate('home.empty', speech.currentLanguage),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            t.translate('home.emptySub', speech.currentLanguage),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              _fastFadeRoute(const ScanScreen()),
            ).then((_) => _loadData()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(Icons.add_a_photo_rounded),
            label: Text(
              t.translate('home.scanCta', speech.currentLanguage),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineGroupTile extends StatelessWidget {
  final MedicineDoseGroup group;
  final VoidCallback onUpdate;
  final I18nService t;
  final SpeechService speech;
  const _MedicineGroupTile({
    required this.group,
    required this.onUpdate,
    required this.t,
    required this.speech,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'taken':
        return const Color(0xFF10B981);
      case 'due':
        return const Color(0xFF34D399);
      case 'upcoming':
        return const Color(0xFF64748B);
      case 'missed':
        return const Color(0xFFEF4444);
      case 'skipped':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusText(String status) {
    return t.translate('status.$status', speech.currentLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final isAllTaken = group.allTaken;
    final primaryDose = group.primaryDose;
    final statusColor = _getStatusColor(group.status);
    final isDue = group.status == 'due';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDue ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
          width: isDue ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  isAllTaken ? "COMPLETED" : _getStatusText(group.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: statusColor,
                  ),
                ),
              ),

              // Time chips row showing all dose timings for today
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: group.doses.map((d) {
                    final dColor = _getStatusColor(d.status);
                    final isThisPrimary = d.key == primaryDose.key && !isAllTaken;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isThisPrimary ? dColor.withValues(alpha: 0.22) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isThisPrimary ? dColor : const Color(0xFFE2E8F0),
                          width: isThisPrimary ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            d.status == 'taken' ? Icons.check_circle_rounded : Icons.schedule_rounded,
                            size: 13,
                            color: dColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DoseUtils.friendlyTime(d.time),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isThisPrimary ? FontWeight.w800 : FontWeight.w600,
                              color: isThisPrimary ? const Color(0xFF047857) : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Medicine Name and Strength (displayed ONLY ONCE per medicine)
          Text(
            group.medicine['name'] ?? "Medicine",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          if (group.medicine['composition'] != null && group.medicine['composition'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.science_outlined, size: 15, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    group.medicine['composition'].toString(),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (group.medicine['purpose'] != null && group.medicine['purpose'].toString().isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.healing_outlined, size: 15, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    group.medicine['purpose'].toString(),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (group.medicine['when_to_take'] != null && group.medicine['when_to_take'].toString().isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.alarm_on_rounded, size: 15, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    group.medicine['when_to_take'].toString(),
                    style: const TextStyle(fontSize: 13, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (group.medicine['dosage'] != null || group.medicine['instructions'] != null) ...[
            const SizedBox(height: 6),
            Text(
              [group.medicine['dosage'], group.medicine['instructions']]
                  .where((s) => s != null && s.toString().isNotEmpty)
                  .join(" • "),
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.3),
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          if (isAllTaken)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "All doses completed for today!",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                  ),
                ),
                IconButton(
                  tooltip: "Delete this schedule",
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  ),
                  onPressed: () => _confirmDelete(context, db),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final doneText = speech.currentLanguage.startsWith('kn')
                          ? "ತೆಗೆದುಕೊಂಡಂತೆ ಗುರುತಿಸಲಾಗಿದೆ."
                          : speech.currentLanguage.startsWith('hi')
                              ? "ले ली गई के रूप में चिह्नित किया गया।"
                              : "Marked as taken. Well done.";
                      speech.speak(doneText);
                      await db.logDose(
                        primaryDose.medicine['id'],
                        'taken',
                        scheduleId: primaryDose.schedule['id'],
                        scheduledFor: primaryDose.scheduledFor,
                      );
                      onUpdate();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 22),
                    label: Text(
                      "${t.translate('home.markTaken', speech.currentLanguage)} (${DoseUtils.friendlyTime(primaryDose.time)})",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () async {
                      final skipText = speech.currentLanguage.startsWith('kn')
                          ? "ಡೋಸ್ ಬಿಟ್ಟುಬಿಡಲಾಗಿದೆ. ಆರೈಕೆದಾರರಿಗೆ ಇಮೇಲ್ ಕಳುಹಿಸಲಾಗಿದೆ."
                          : speech.currentLanguage.startsWith('hi')
                              ? "खुराक छोड़ दी गई। देखभालकर्ता को ईमेल भेजा गया।"
                              : "Dose skipped. Caregiver notified via email.";
                      speech.speak(skipText);
                      await db.logDose(
                        primaryDose.medicine['id'],
                        'skipped',
                        scheduleId: primaryDose.schedule['id'],
                        scheduledFor: primaryDose.scheduledFor,
                      );
                      onUpdate();

                      final caregivers = await db.getCaregivers();
                      final caregiverEmail = caregivers.isNotEmpty &&
                              caregivers.first['email'] != null &&
                              caregivers.first['email'].toString().isNotEmpty
                          ? caregivers.first['email'].toString()
                          : "caregiver";

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFFF59E0B),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            content: Row(
                              children: [
                                const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Dose skipped. Alert sent to $caregiverEmail!",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      t.translate('home.skip', speech.currentLanguage),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: "Delete this schedule",
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF64748B), size: 22),
                  onPressed: () => _confirmDelete(context, db),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DatabaseService db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 10),
            Text("Delete Schedule", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Delete \"${group.medicine['name']}\" and its schedule? This cannot be undone.",
          style: const TextStyle(color: Color(0xFF334155), fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              speech.speak("${group.medicine['name']} deleted.");
              await db.deleteMedicine(group.medicine['id']);
              await db.deactivateSchedule(group.schedule['id']);
              onUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AlarmSetupOverlay extends StatelessWidget {
  final AlarmSetupService setup;
  const _AlarmSetupOverlay({required this.setup});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF059669), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.alarm_add_rounded, size: 64, color: Color(0xFF059669)),
              const SizedBox(height: 16),
              const Text(
                "Voice Alarm Setup",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              Text(
                setup.status.isNotEmpty ? setup.status : "Listening for medicine details...",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, color: Color(0xFF334155), height: 1.4),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: setup.cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("CANCEL SETUP", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
