import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'database_service.dart';
import 'dose_utils.dart';

@pragma('vm:entry-point')
Future<void> backgroundAlarmCallback() async {
  try {
    // Re-initialize Firebase for the background isolate
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final db = DatabaseService();
    final medicines = await db.getMedicines();
    if (medicines.isEmpty) {
      debugPrint("BackgroundAlarmManager: No medicines saved, suppressing notification.");
      return;
    }

    final schedules = await db.getSchedules();
    final logs = await db.getDoseLogs();
    final profile = await db.getProfile();
    final lang = (profile?['preferred_language'] ?? 'en-US').toString();

    final now = DateTime.now();
    final todayDoses = DoseUtils.buildTodayDoses(
      medicines: medicines,
      schedules: schedules,
      logs: logs,
      now: now,
    );

    // ONLY find doses that are genuinely DUE right now!
    // Must have reached scheduled time, be within 60 minutes window, and not already taken/skipped
    final dueDoses = todayDoses.where((d) {
      if (d.status != 'due') return false;
      final diffMins = now.difference(d.scheduledFor).inMinutes;
      final hasReachedTime = now.isAfter(d.scheduledFor) || now.isAtSameMomentAs(d.scheduledFor);
      return hasReachedTime && diffMins >= 0 && diffMins <= 60;
    }).toList();

    // If no dose is due right now, DO NOT show any notification!
    if (dueDoses.isEmpty) {
      debugPrint("BackgroundAlarmManager: No doses due at this exact moment. Notification suppressed.");
      return;
    }

    final targetDose = dueDoses.first;
    final medName = (targetDose.medicine['name'] ?? 'Medicine').toString();
    final doseTime = DoseUtils.friendlyTime(targetDose.time);

    final title = lang.startsWith('kn')
        ? "ಔಷಧಿ ತೆಗೆದುಕೊಳ್ಳುವ ಸಮಯ"
        : lang.startsWith('hi')
            ? "दवा लेने का समय"
            : "Medicine Reminder";

    final body = lang.startsWith('kn')
        ? "$medName ತೆಗೆದುಕೊಳ್ಳುವ ಸಮಯ ($doseTime). ದಯವಿಟ್ಟು ಔಷಧಿಯನ್ನು ಸೇವಿಸಿ."
        : lang.startsWith('hi')
            ? "$medName लेने का समय हो गया है ($doseTime)। कृपया दवा लें।"
            : "Time to take $medName ($doseTime). Please take your medicine.";

    final notifications = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await notifications.initialize(initSettings);

    const androidDetails = AndroidNotificationDetails(
      'med_reminders',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine intake schedules',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const details = NotificationDetails(android: androidDetails);

    // Unique ID based on medicine hash so it doesn't spawn duplicate notifications
    final notificationId = targetDose.key.hashCode.abs() % 100000;
    await notifications.show(
      notificationId,
      title,
      body,
      details,
    );
    debugPrint("BackgroundAlarmManager: Notification shown ONLY for due dose: $medName at $doseTime");
  } catch (e) {
    debugPrint("BackgroundAlarmManager exception: $e");
  }
}

@pragma('vm:entry-point')
class BackgroundAlarmManager {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      await AndroidAlarmManager.initialize();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _notifications.initialize(initSettings);
    } catch (_) {}
  }

  static Future<void> scheduleDailyCheck() async {
    try {
      await AndroidAlarmManager.periodic(
        const Duration(minutes: 15),
        0,
        backgroundAlarmCallback,
        exact: true,
        wakeup: true,
      );
    } catch (_) {}
  }

  static Future<void> cancelDailyCheck() async {
    try {
      await AndroidAlarmManager.cancel(0);
    } catch (_) {}
  }
}
