import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/speech_service.dart';
import '../services/dose_utils.dart';
import '../services/i18n_service.dart';
import '../services/voice_controller.dart';
import '../services/voice_intent_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> implements VoiceScreenDelegate {
  VoiceController? _voiceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _voiceController = Provider.of<VoiceController>(context, listen: false);
    } catch (_) {}
  }

  List<TodayDose> _doses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final voice = Provider.of<VoiceController>(context, listen: false);
        voice.setActiveDelegate(this, AppScreen.schedule);
        // Mic state preserved (toggled only by double-tap)
        voice.announceScreen();
      }
    });
  }

  @override
  void dispose() {
    _voiceController?.clearActiveDelegate(this);
    super.dispose();
  }

  @override
  String getScreenAnnouncement() {
    if (!mounted) return "";
    final speech = Provider.of<SpeechService>(context, listen: false);
    final lang = speech.currentLanguage;
    final count = _doses.length;
    if (lang.startsWith('kn')) {
      return "ವೇಳಾಪಟ್ಟಿ ಪರದೆ. ಇಂದು ನಿಮಗೆ $count ಡೋಸ್‌ಗಳಿವೆ. ಕೇಳಲು 'ಎಲ್ಲಾ ಓದಿ' ಎನ್ನಿ, ಅಥವಾ 'ತೆಗೆದುಕೊಂಡೆ' ಎನ್ನಿ.";
    } else if (lang.startsWith('hi')) {
      return "समय-सारणी स्क्रीन। आज आपकी $count खुराकें हैं। सुनने के लिए 'सब पढ़ो' कहें, या 'ले ली' कहें।";
    }
    return "Schedule screen. You have $count doses today. Say 'read all' to listen, or 'mark taken'.";
  }

  @override
  Future<bool> handleVoiceCommand(VoiceIntent? intent, String transcript) async {
    if (!mounted) return false;
    final speech = Provider.of<SpeechService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final lang = speech.currentLanguage;

    switch (intent) {
      case VoiceIntent.readPage:
      case VoiceIntent.repeat:
        if (_doses.isEmpty) {
          speech.speak(lang.startsWith('kn') ? "ಇಂದು ಯಾವುದೇ ಔಷಧಿ ನಿಗದಿಯಾಗಿಲ್ಲ." : "No medicines scheduled for today.");
        } else {
          final buffer = StringBuffer();
          buffer.write(lang.startsWith('kn') ? "ಇಂದಿನ ವೇಳಾಪಟ್ಟಿ: " : "Today's schedule: ");
          for (var d in _doses) {
            final time = DoseUtils.friendlyTime(d.time);
            final name = d.medicine['name'] ?? 'Medicine';
            final status = d.status == 'taken'
                ? (lang.startsWith('kn') ? "ತೆಗೆದುಕೊಳ್ಳಲಾಗಿದೆ" : "already taken")
                : (lang.startsWith('kn') ? "ಬಾಕಿ ಇದೆ" : "pending");
            buffer.write("$time: $name, $status. ");
          }
          speech.speak(buffer.toString());
        }
        return true;

      case VoiceIntent.markTaken:
        final pending = _doses.where((d) => d.status != 'taken').toList();
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
              ? "$medName ತೆಗೆದುಕೊಂಡಂತೆ ಗುರುತಿಸಲಾಗಿದೆ."
              : lang.startsWith('hi')
                  ? "$medName ले ली गई के रूप में चिह्नित किया गया।"
                  : "Marked $medName as taken. Well done.";
          speech.speak(done);
          await _refresh();
        } else {
          speech.speak(lang.startsWith('kn') ? "ಎಲ್ಲಾ ಔಷಧಿಗಳನ್ನು ಈಗಾಗಲೇ ತೆಗೆದುಕೊಳ್ಳಲಾಗಿದೆ." : "All medicines are already marked as taken.");
        }
        return true;

      case VoiceIntent.refresh:
        await _refresh();
        speech.speak("Schedule refreshed.");
        return true;

      default:
        return false;
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    
    try {
      final medicines = await db.getMedicines();
      final schedules = await db.getSchedules();
      final logs = await db.getDoseLogs();

      if (!mounted) return;
      setState(() {
        _doses = DoseUtils.buildTodayDoses(
          medicines: medicines,
          schedules: schedules,
          logs: logs,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final speech = Provider.of<SpeechService>(context);
    final db = Provider.of<DatabaseService>(context);
    final t = Provider.of<I18nService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          t.translate('schedule.title', speech.currentLanguage),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF059669),
        iconTheme: const IconThemeData(color: Colors.white),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : _doses.isEmpty
              ? _buildEmptyState(t, speech)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _doses.length,
                  itemBuilder: (context, index) {
                    final dose = _doses[index];
                    return _DoseCard(
                      dose: dose,
                      onMarkTaken: () async {
                        final markedMsg = speech.currentLanguage.startsWith('kn')
                            ? "${dose.medicine['name']} ತೆಗೆದುಕೊಂಡಂತೆ ಗುರುತಿಸಲಾಗಿದೆ."
                            : speech.currentLanguage.startsWith('hi')
                                ? "${dose.medicine['name']} ले ली गई के रूप में चिह्नित किया गया।"
                                : "Marking ${dose.medicine['name']} as taken.";
                        speech.speak(markedMsg);
                        await db.logDose(
                          dose.medicine['id'], 
                          'taken',
                          scheduleId: dose.schedule['id'],
                          scheduledFor: dose.scheduledFor,
                        );
                        _refresh();
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(I18nService t, SpeechService speech) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_rounded, size: 72, color: Color(0xFF059669)),
          ),
          const SizedBox(height: 20),
          Text(
            t.translate('schedule.empty', speech.currentLanguage),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            "No scheduled doses for today",
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _DoseCard extends StatelessWidget {
  final TodayDose dose;
  final VoidCallback onMarkTaken;

  const _DoseCard({required this.dose, required this.onMarkTaken});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    
    switch (dose.status) {
      case 'taken':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case 'missed':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.error_outline;
        break;
      case 'due':
        statusColor = const Color(0xFF059669);
        statusIcon = Icons.access_time_filled;
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusIcon = Icons.access_time;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dose.status == 'due' ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
          width: dose.status == 'due' ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor, width: 1.2),
                    ),
                    child: Text(
                      DoseUtils.friendlyTime(dose.time),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: statusColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dose.medicine['name'],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
                  ),
                  if (dose.medicine['composition'] != null && dose.medicine['composition'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.science_outlined, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dose.medicine['composition'].toString(),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (dose.medicine['purpose'] != null && dose.medicine['purpose'].toString().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.healing_outlined, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dose.medicine['purpose'].toString(),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (dose.medicine['when_to_take'] != null && dose.medicine['when_to_take'].toString().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.alarm_on_rounded, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dose.medicine['when_to_take'].toString(),
                            style: const TextStyle(fontSize: 13, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (dose.medicine['dosage'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        dose.medicine['dosage'],
                        style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
            if (dose.status != 'taken')
              IconButton(
                icon: Icon(statusIcon, size: 42, color: statusColor),
                onPressed: onMarkTaken,
              )
            else
              Icon(statusIcon, size: 42, color: statusColor),
          ],
        ),
      ),
    );
  }
}
