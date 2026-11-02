import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'speech_service.dart';
import 'database_service.dart';
import 'dose_utils.dart';

class AlarmService extends ChangeNotifier {
  TodayDose? _ringingDose;
  TodayDose? get ringingDose => _ringingDose;

  Timer? _timer;
  final Set<String> _firedKeys = {};
  final Set<String> _missedAlertedKeys = {};
  final Map<String, DateTime> _snoozedDoses = {};
  String? _monitoredUserId;

  void reset() {
    _ringingDose = null;
    _firedKeys.clear();
    _missedAlertedKeys.clear();
    _snoozedDoses.clear();
    notifyListeners();
  }

  void startMonitoring(BuildContext context) {
    _timer?.cancel();
    // Check every 20 seconds, same as React
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final speech = Provider.of<SpeechService>(context, listen: false);
      
      final currentUid = db.userId;
      if (_monitoredUserId != null && _monitoredUserId != currentUid) {
        reset();
      }
      _monitoredUserId = currentUid;
      
      try {
        final medicines = await db.getMedicines();
        final schedules = await db.getSchedules();
        final logs = await db.getDoseLogs();
        
        final doses = DoseUtils.buildTodayDoses(
          medicines: medicines,
          schedules: schedules,
          logs: logs,
        );

        final now = DateTime.now();

        // 1. Detect and alert for missed doses (> 60 minutes past scheduled time)
        for (var dose in doses) {
          if (dose.status == 'missed' && !_missedAlertedKeys.contains(dose.key)) {
            _missedAlertedKeys.add(dose.key);
            debugPrint("AlarmService: Missed dose detected for ${dose.medicine['name']} at ${dose.time}. Auto-logging & emailing caregivers.");
            await db.logDose(
              dose.medicine['id'],
              'missed',
              scheduleId: dose.schedule['id'],
              scheduledFor: dose.scheduledFor,
            );
          }
        }
        
        // 2. Find a dose that is due right now (exact on-time or active snooze)
        for (var dose in doses) {
          if (dose.status == 'taken' || dose.status == 'skipped') continue;

          final isSnoozeExpired = _snoozedDoses.containsKey(dose.key) && now.isAfter(_snoozedDoses[dose.key]!);
          final diffMins = now.difference(dose.scheduledFor).inMinutes;
          final isOnTime = (now.isAfter(dose.scheduledFor) || now.isAtSameMomentAs(dose.scheduledFor)) && diffMins >= 0 && diffMins <= 10;

          if ((isOnTime && !_firedKeys.contains(dose.key)) || isSnoozeExpired) {
            _snoozedDoses.remove(dose.key);
            _ringingDose = dose;
            _firedKeys.add(dose.key);
            notifyListeners();
            debugPrint("AlarmService: Triggering exact on-time alarm for ${dose.medicine['name']} at ${dose.time}");
            break; 
          }
        }
      } catch (e) {
        debugPrint("Alarm monitor error: $e");
      }
    });
  }

  Future<void> acknowledge(String action, BuildContext context) async {
    if (_ringingDose == null) return;
    
    final speech = Provider.of<SpeechService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);

    final lang = speech.currentLanguage;
    if (action == 'taken') {
      await db.logDose(
        _ringingDose!.medicine['id'], 
        'taken',
        scheduleId: _ringingDose!.schedule['id'],
        scheduledFor: _ringingDose!.scheduledFor,
      );
      final takenMsg = lang.startsWith('kn')
          ? "ಔಷಧಿ ತೆಗೆದುಕೊಂಡಿದ್ದಕ್ಕಾಗಿ ಧನ್ಯವಾದಗಳು. ಚೆನ್ನಾಗಿ ಮಾಡಿದ್ದೀರಿ."
          : lang.startsWith('hi')
              ? "दवा ले ली गई। बहुत बढ़िया।"
              : "Marked as taken. Well done.";
      await speech.speak(takenMsg);
    } else if (action == 'skip' || action == 'skipped') {
      await db.logDose(
        _ringingDose!.medicine['id'], 
        'skipped',
        scheduleId: _ringingDose!.schedule['id'],
        scheduledFor: _ringingDose!.scheduledFor,
      );
      final skipMsg = lang.startsWith('kn')
          ? "ಡೋಸ್ ಬಿಟ್ಟುಬಿಡಲಾಗಿದೆ. ಆರೈಕೆದಾರರಿಗೆ ಮಾಹಿತಿ ನೀಡಲಾಗಿದೆ."
          : lang.startsWith('hi')
              ? "खुराक छोड़ दी गई। देखभालकर्ता को सूचित कर दिया गया है।"
              : "Dose skipped. Caregiver notified.";
      await speech.speak(skipMsg);
    } else {
      final snoozeMsg = lang.startsWith('kn')
          ? "೧೦ ನಿಮಿಷಗಳ ಕಾಲ ಸ್ನೂಜ್ ಮಾಡಲಾಗಿದೆ."
          : lang.startsWith('hi')
              ? "१० मिनट के लिए स्नूज़ किया गया।"
              : "Snoozed for 10 minutes.";
      await speech.speak(snoozeMsg);

      final key = _ringingDose!.key;
      _snoozedDoses[key] = DateTime.now().add(const Duration(minutes: 10));
      debugPrint("AlarmService: Snoozed $key for exactly 10 minutes (until ${_snoozedDoses[key]})");
    }
    
    _ringingDose = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
