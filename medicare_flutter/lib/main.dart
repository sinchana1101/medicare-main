import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_auth/firebase_auth.dart';

import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'screens/home_screen.dart';

import 'screens/auth_screen.dart';

import 'services/speech_service.dart';

import 'services/database_service.dart';

import 'services/alarm_service.dart';

import 'services/i18n_service.dart';

import 'services/background_alarm_manager.dart';

import 'services/ai_service.dart';

import 'services/alarm_setup_service.dart';

import 'services/location_service.dart';

import 'services/voice_controller.dart';

import 'services/voice_intent_service.dart';

import 'widgets/accessible_voice_overlay.dart';



void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Prevent any unhandled framework assertions from showing a red screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint("Handled framework error safely: ${details.exception}");
    return const Material(
      color: Color(0xFFF8FAFC),
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFF059669)),
      ),
    );
  };



  // Initialize Firebase with your project medicare-ba41e

  try {

    await Firebase.initializeApp(

      options: DefaultFirebaseOptions.currentPlatform,

    );

    FirebaseFirestore.instance.settings = const Settings(

      persistenceEnabled: true,

      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,

    );

    debugPrint("Firebase initialized successfully for medicare-ba41e with offline persistence");

  } catch (e) {

    debugPrint("Firebase initialization note: $e");

  }



  // Initialize Background Services ONLY if NOT on Web

  if (!kIsWeb) {

    await BackgroundAlarmManager.init();

    await BackgroundAlarmManager.scheduleDailyCheck();

  }



  runApp(

    MultiProvider(

      providers: [

        ChangeNotifierProvider(create: (_) => SpeechService()),

        ChangeNotifierProvider(create: (_) => AlarmService()),

        ChangeNotifierProvider(create: (_) => DatabaseService()),

        ChangeNotifierProvider(create: (_) => AIService()),

        Provider(create: (_) => I18nService()),

        Provider(create: (_) => LocationService()),

        ChangeNotifierProxyProvider3<SpeechService, DatabaseService, AIService, VoiceController>(

          create: (context) => VoiceController(

            Provider.of<SpeechService>(context, listen: false),

            Provider.of<DatabaseService>(context, listen: false),

            ai: Provider.of<AIService>(context, listen: false),

          ),

          update: (context, speech, db, ai, previous) => previous ?? VoiceController(speech, db, ai: ai),

        ),

        ChangeNotifierProxyProvider2<SpeechService, DatabaseService, AlarmSetupService>(

          create: (context) => AlarmSetupService(

            Provider.of<SpeechService>(context, listen: false),

            Provider.of<DatabaseService>(context, listen: false),

          ),

          update: (context, speech, db, previous) => AlarmSetupService(speech, db),

        ),

      ],

      child: const SmartMediCareApp(),

    ),

  );

}



class SmartMediCareApp extends StatelessWidget {

  const SmartMediCareApp({super.key});



  @override

  Widget build(BuildContext context) {

        // Start monitoring alarms as soon as the app starts and sync preferred language from profile
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<AlarmService>(context, listen: false).startMonitoring(context);
      try {
        final db = Provider.of<DatabaseService>(context, listen: false);
        final speech = Provider.of<SpeechService>(context, listen: false);
        final profile = await db.getProfile();
        if (profile != null && profile['preferred_language'] != null && profile['preferred_language'].toString().isNotEmpty) {
          final lang = profile['preferred_language'].toString();
          speech.currentLanguage = lang;
          debugPrint("SmartMediCareApp: Initialized preferred language from profile: $lang");
        }
      } catch (_) {}
    });



    return MaterialApp(

      navigatorKey: VoiceController.navigatorKey,

      title: 'SmartMediCare',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(

        useMaterial3: true,

        brightness: Brightness.light,

        primaryColor: const Color(0xFF059669),

        scaffoldBackgroundColor: const Color(0xFFF8FAFC),

        cardColor: Colors.white,

        colorScheme: const ColorScheme.light(

          primary: Color(0xFF059669),

          secondary: Color(0xFF10B981),

          surface: Colors.white,

          onPrimary: Colors.white,

          onSecondary: Colors.white,

          onSurface: Color(0xFF0F172A),

        ),

        appBarTheme: const AppBarTheme(

          backgroundColor: Color(0xFF059669),

          foregroundColor: Colors.white,

          elevation: 0,

          titleTextStyle: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),

          iconTheme: IconThemeData(color: Colors.white),

        ),

        textTheme: const TextTheme(

          bodyLarge: TextStyle(fontSize: 22, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),

          bodyMedium: TextStyle(fontSize: 18, color: Color(0xFF334155)),

        ),

      ),

      home: const AuthWrapper(),

      builder: (context, child) {

        return Overlay(

          initialEntries: [

            OverlayEntry(

              builder: (context) => Stack(

                children: [

                  AccessibleVoiceOverlay(child: child!),

                  const GlobalAlarmOverlay(),

                ],

              ),

            ),

          ],

        );

      },

    );

  }

}



class AuthWrapper extends StatelessWidget {

  const AuthWrapper({super.key});



  @override

  Widget build(BuildContext context) {

    return Consumer<DatabaseService>(

      builder: (context, db, child) {

        return StreamBuilder<User?>(

          stream: FirebaseAuth.instance.authStateChanges(),

          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {

              return const Scaffold(

                backgroundColor: Color(0xFFF8FAFC),

                body: Center(child: CircularProgressIndicator()),

              );

            }

            final user = snapshot.data;

            if (user != null || db.isAuthenticated) {

              return const HomeScreen();

            } else {

              return const AuthScreen();

            }

          },

        );

      },

    );

  }

}



class GlobalAlarmOverlay extends StatefulWidget {
  const GlobalAlarmOverlay({super.key});

  @override
  State<GlobalAlarmOverlay> createState() => _GlobalAlarmOverlayState();
}

class _GlobalAlarmOverlayState extends State<GlobalAlarmOverlay> {
  String? _lastRingingDoseKey;
  bool _isAlarmLoopRunning = false;

  void _startContinuousAlarmLoop(AlarmService alarm) async {
    if (_isAlarmLoopRunning || alarm.ringingDose == null) return;
    _isAlarmLoopRunning = true;

    final speech = Provider.of<SpeechService>(context, listen: false);

    // Continuous loop: repeats tablet name until user says taken or snooze (or taps either button)
    while (mounted && alarm.ringingDose != null && _isAlarmLoopRunning) {
      final dose = alarm.ringingDose;
      if (dose == null) break;

      final medName = (dose.medicine['name'] ?? 'medicine').toString();
      final lang = speech.currentLanguage;

      final prompt = lang.startsWith('kn')
          ? "ದಯವಿಟ್ಟು ಗಮನಿಸಿ, $medName ತೆಗೆದುಕೊಳ್ಳುವ ಸಮಯವಾಗಿದೆ. 'ತೆಗೆದುಕೊಂಡೆ' ಅಥವಾ 'ಸ್ನೂಜ್' ಎಂದು ಹೇಳಿ."
          : lang.startsWith('hi')
              ? "कृपया ध्यान दें, $medName लेने का समय हो गया है। कृपया 'ले ली' या 'स्नूज़' बोलें।"
              : "Please take your medicine, $medName. Speak 'Taken' or 'Snooze'.";

      await speech.speak(prompt);
      await speech.waitForSpeech();

      if (!mounted || alarm.ringingDose == null || !_isAlarmLoopRunning) break;

      // Listen for voice response
      final heard = await speech.listenOnce(timeoutSeconds: 6);
      if (!mounted || alarm.ringingDose == null || !_isAlarmLoopRunning) break;

      final intent = VoiceIntentService.matchIntent(heard);
      final lower = heard.toLowerCase();

      final isTaken = intent == VoiceIntent.markTaken ||
          intent == VoiceIntent.yes ||
          lower.contains("taken") ||
          lower.contains("took") ||
          lower.contains("done") ||
          lower.contains("finished") ||
          heard.contains("ತೆಗೆದುಕೊಂಡೆ") ||
          heard.contains("ತಗೊಂಡೆ") ||
          heard.contains("ಆಯ್ತು") ||
          heard.contains("ಮಾಡಿದೆ") ||
          heard.contains("ತಗೊಂಡಿದೀನಿ") ||
          heard.contains("ಲೆ ಲಿ") ||
          heard.contains("ले ली") ||
          heard.contains("खा ली") ||
          heard.contains("हो गया") ||
          heard.contains("खा लिया");

      final isSnooze = intent == VoiceIntent.snooze ||
          lower.contains("snooze") ||
          lower.contains("later") ||
          lower.contains("10 min") ||
          heard.contains("ಸ್ನೂಜ್") ||
          heard.contains("ನಂತರ") ||
          heard.contains("ಸ್ನೂಸ್") ||
          heard.contains("ಸ್ನೋಜ್") ||
          heard.contains("स्नूज़") ||
          heard.contains("बाद में") ||
          heard.contains("स्नूज");

      final isSkip = intent == VoiceIntent.skipDose ||
          lower.contains("skip") ||
          heard.contains("ಬಿಟ್ಟುಬಿಡಿ") ||
          heard.contains("ಬೇಡ") ||
          heard.contains("छोड़ें") ||
          heard.contains("नहीं लेना");

      if (isTaken) {
        _isAlarmLoopRunning = false;
        await alarm.acknowledge('taken', context);
        break;
      } else if (isSnooze) {
        _isAlarmLoopRunning = false;
        await alarm.acknowledge('snooze', context);
        break;
      } else if (isSkip) {
        _isAlarmLoopRunning = false;
        await alarm.acknowledge('skip', context);
        break;
      }

      // If user hasn't answered, pause 2 seconds and repeat tablet name!
      await Future.delayed(const Duration(seconds: 2));
    }

    _isAlarmLoopRunning = false;
  }

  @override
  Widget build(BuildContext context) {
    final speech = Provider.of<SpeechService>(context);
    final lang = speech.currentLanguage;

    final headerText = lang.startsWith('kn')
        ? "ಔಷಧಿಯ ಜ್ಞಾಪನೆ"
        : lang.startsWith('hi')
            ? "दवा का रिमाइंडर"
            : "MEDICINE REMINDER";

    final subheaderText = lang.startsWith('kn')
        ? "'ತೆಗೆದುಕೊಂಡೆ' ಅಥವಾ 'ಸ್ನೂಜ್' ಎಂದು ಹೇಳಿ"
        : lang.startsWith('hi')
            ? "'ले ली' या 'स्नूज़' बोलें"
            : "Speak \"TAKEN\" or \"SNOOZE\" hands-free";

    final takenBtnText = lang.startsWith('kn')
        ? "ತೆಗೆದುಕೊಂಡೆ"
        : lang.startsWith('hi')
            ? "मैंने ले ली"
            : "I TOOK IT";

    final snoozeBtnText = lang.startsWith('kn')
        ? "೧೦ ನಿಮಿಷ ಸ್ನೂಜ್ ಮಾಡಿ"
        : lang.startsWith('hi')
            ? "१० मिनट स्नूज़ करें"
            : "SNOOZE 10 MIN";

    return Consumer<AlarmService>(
      builder: (context, alarm, child) {
        if (alarm.ringingDose == null) {
          _lastRingingDoseKey = null;
          _isAlarmLoopRunning = false;
          return const SizedBox.shrink();
        }

        if (_lastRingingDoseKey != alarm.ringingDose!.key) {
          _lastRingingDoseKey = alarm.ringingDose!.key;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startContinuousAlarmLoop(alarm);
          });
        }

        return Material(
          color: Colors.transparent,
          child: Container(
            color: const Color(0xFF0F172A).withValues(alpha: 0.98),
            padding: const EdgeInsets.all(28),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEF4444), width: 3),
                    ),
                    child: const Icon(Icons.alarm_on_rounded, size: 80, color: Color(0xFFEF4444)),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    headerText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    alarm.ringingDose!.medicine['name'] ?? 'Unknown Medicine',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    subheaderText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.cyanAccent.shade200, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 48),

                  ElevatedButton.icon(
                    onPressed: () {
                      _isAlarmLoopRunning = false;
                      speech.stopSTT();
                      alarm.acknowledge('taken', context);
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 36),
                    label: Text(takenBtnText, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 90),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      elevation: 4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: () {
                      _isAlarmLoopRunning = false;
                      speech.stopSTT();
                      alarm.acknowledge('snooze', context);
                    },
                    icon: const Icon(Icons.snooze_rounded, size: 28),
                    label: Text(snoozeBtnText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                      side: const BorderSide(color: Color(0xFF334155), width: 2),
                      minimumSize: const Size(double.infinity, 70),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
