import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart';
import 'schedule_screen.dart';
import 'assistant_screen.dart';
import 'settings_screen.dart';
import '../services/speech_service.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/i18n_service.dart';
import '../services/voice_controller.dart';
import '../services/voice_intent_service.dart';

class ScanScreen extends StatefulWidget {
  final bool autoOpenCamera;
  final String? initialImagePath;
  const ScanScreen({super.key, this.autoOpenCamera = false, this.initialImagePath});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> implements VoiceScreenDelegate {
  bool _isDisposed = false;
  VoiceController? _voiceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _voiceController = Provider.of<VoiceController>(context, listen: false);
    } catch (_) {}
  }

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _timesController = TextEditingController(text: "08:00");
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _strengthController = TextEditingController();
  final TextEditingController _formController = TextEditingController();
  final TextEditingController _compositionController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _whenToTakeController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  String _mode = "medicine"; // "medicine" | "prescription"
  bool _busy = false;
  String? _status;
  File? _selectedImageFile;

  Map<String, dynamic>? _medicineResult;
  Map<String, dynamic>? _prescriptionResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final voice = Provider.of<VoiceController>(context, listen: false);
        voice.setActiveDelegate(this, AppScreen.scan);
        // Mic state preserved (toggled only by double-tap)
        if (widget.initialImagePath != null && widget.initialImagePath!.isNotEmpty) {
          final file = File(widget.initialImagePath!);
          setState(() {
            _selectedImageFile = file;
          });
          _processImage(file);
        } else if (widget.autoOpenCamera) {
          _pickImage(ImageSource.camera);
        } else {
          setState(() {
            _status = "Ready when you are. Say 'take photo' to begin.";
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _voiceController?.clearActiveDelegate(this);
    _timesController.dispose();
    _nameController.dispose();
    _strengthController.dispose();
    _formController.dispose();
    _compositionController.dispose();
    _purposeController.dispose();
    _whenToTakeController.dispose();
    _doseController.dispose();
    _expiryController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  String getScreenAnnouncement() {
    if (!mounted) return "";
    final speech = Provider.of<SpeechService>(context, listen: false);
    final lang = speech.currentLanguage;
    if (lang.startsWith('kn')) return "ಸ್ಕ್ಯಾನ್";
    if (lang.startsWith('hi')) return "स्कैन";
    return "Scan";
  }

  @override
  Future<bool> handleVoiceCommand(VoiceIntent? intent, String transcript) async {
    if (!mounted) return false;
    final speech = Provider.of<SpeechService>(context, listen: false);
    final lower = transcript.toLowerCase().trim();
    debugPrint("ScanScreen handleVoiceCommand: '$transcript' (intent: $intent)");

    // Immediate navigation back to home or other pages
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

    if (intent == VoiceIntent.schedule ||
        lower.contains("schedule") ||
        lower.contains("alarm") ||
        transcript.contains("ವೇಳಾಪಟ್ಟಿ") ||
        transcript.contains("ಶೆಡ್ಯೂಲ್") ||
        transcript.contains("समय") ||
        transcript.contains("शेड्यूल")) {
      final lang = speech.currentLanguage;
      final msg = lang.startsWith('kn') ? "ವೇಳಾಪಟ್ಟಿ." : (lang.startsWith('hi') ? "शेड्यूल।" : "Schedule.");
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

    if (intent == VoiceIntent.assistant ||
        lower.contains("assistant") ||
        transcript.contains("ಸಹಾಯಕ") ||
        transcript.contains("सहायक")) {
      final lang = speech.currentLanguage;
      final msg = lang.startsWith('kn') ? "ಸಹಾಯಕ." : (lang.startsWith('hi') ? "सहायक।" : "Assistant.");
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

    if (intent == VoiceIntent.more ||
        lower.contains("setting") ||
        transcript.contains("ಸೆಟ್ಟಿಂಗ್ಸ್") ||
        transcript.contains("सेटिंग्स")) {
      final lang = speech.currentLanguage;
      final msg = lang.startsWith('kn') ? "ಸೆಟ್ಟಿಂಗ್ಸ್." : (lang.startsWith('hi') ? "सेटिंग्स।" : "Settings.");
      speech.speak(msg);
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const SettingsScreen(),
            transitionDuration: const Duration(milliseconds: 100),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      }
      return true;
    }

    if (intent == VoiceIntent.scan ||
        lower == "scan" ||
        lower == "open scan" ||
        lower == "start scan" ||
        transcript.contains("ಸ್ಕ್ಯಾನ್") ||
        transcript.contains("स्कैन") ||
        intent == VoiceIntent.takePhoto ||
        lower.contains("capture") ||
        lower.contains("click") ||
        lower.contains("snap") ||
        lower.contains("shoot") ||
        lower.contains("photo") ||
        lower.contains("camera") ||
        lower.contains("picture") ||
        lower.contains("tege") ||
        lower.contains("thege") ||
        lower.contains("thago") ||
        lower.contains("tegi") ||
        lower.contains("khicho") ||
        lower.contains("kheencho") ||
        lower.contains("chitra") ||
        transcript.contains("ಕ್ಲಿಕ್") ||
        transcript.contains("ಫೋಟೋ") ||
        transcript.contains("ಕ್ಯಾಪ್ಚರ್") ||
        transcript.contains("ಚಿತ್ರ") ||
        transcript.contains("ತೆಗೆ") ||
        transcript.contains("फोटो") ||
        transcript.contains("खींचो") ||
        transcript.contains("तस्वीर") ||
        transcript.contains("क्लिक")) {
      final camMsg = speech.currentLanguage.startsWith('kn')
          ? "ಕ್ಯಾಮೆರಾ ತೆರೆಯಲಾಗುತ್ತಿದೆ."
          : (speech.currentLanguage.startsWith('hi') ? "कैमरा खोला जा रहा है।" : "Opening camera.");
      speech.speak(camMsg);
      await _pickImage(ImageSource.camera, autoCapture: false);
      return true;
    }

    switch (intent) {
      case VoiceIntent.uploadPhoto:
        await _pickImage(ImageSource.gallery);
        return true;
      case VoiceIntent.save:
        if (_medicineResult != null) {
          await _saveMedicine();
        } else if (_prescriptionResult != null) {
          await _savePrescription();
        } else {
          speech.speak(speech.currentLanguage.startsWith('kn')
              ? "ಇನ್ನೂ ಯಾವುದೇ ಔಷಧಿಯನ್ನು ಸ್ಕ್ಯಾನ್ ಮಾಡಿಲ್ಲ. ದಯವಿಟ್ಟು ಮೊದಲು ಫೋಟೋ ತೆಗೆಯಿರಿ."
              : "No scanned medicine to save yet. Please say 'take photo' first.");
        }
        return true;
      case VoiceIntent.prescriptionMode:
        setState(() => _mode = "prescription");
        speech.speak("Switched to prescription mode.");
        return true;
      case VoiceIntent.medicineMode:
        setState(() => _mode = "medicine");
        speech.speak("Switched to medicine mode.");
        return true;
      case VoiceIntent.readPage:
      case VoiceIntent.repeat:
        if (_status != null && _status!.isNotEmpty) {
          speech.speak(_status!);
        } else {
          speech.speak(getScreenAnnouncement());
        }
        return true;
      default:
        return false;
    }
  }

  Future<void> _pickImage(ImageSource source, {bool autoCapture = false}) async {
    final speech = Provider.of<SpeechService>(context, listen: false);
    final t = Provider.of<I18nService>(context, listen: false);

    try {
      if (source == ImageSource.camera) {
        Navigator.push<String>(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => CameraScreen(autoCapture: autoCapture),
            transitionDuration: const Duration(milliseconds: 100),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        ).then((capturedPath) async {
          if (mounted && !_isDisposed) {
            final voice = Provider.of<VoiceController>(context, listen: false);
            voice.setActiveDelegate(this, AppScreen.scan);
            if (capturedPath != null && capturedPath.isNotEmpty) {
              final imageFile = File(capturedPath);
              setState(() {
                _selectedImageFile = imageFile;
              });
              await _processImage(imageFile);
            }
          }
        });
        return;
      }

      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file == null) return;

      final imageFile = File(file.path);
      setState(() {
        _selectedImageFile = imageFile;
      });

      speech.speak(t.translate('scan.photoChosen', speech.currentLanguage));
      await _processImage(imageFile);
    } catch (e) {
      debugPrint("Image picker error: $e");
      final errorMsg = t.translate('scan.failed', speech.currentLanguage);
      setState(() => _status = errorMsg);
      speech.speak(errorMsg);
    }
  }

  Future<void> _processImage(File imageFile) async {
    final speech = Provider.of<SpeechService>(context, listen: false);
    final ai = Provider.of<AIService>(context, listen: false);
    final t = Provider.of<I18nService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);

    // Sync latest saved Gemini API key from profile
    try {
      final profile = await db.getProfile();
      if (profile != null && profile['gemini_api_key'] != null && profile['gemini_api_key'].toString().trim().isNotEmpty) {
        ai.setApiKey(profile['gemini_api_key'].toString().trim());
      }
    } catch (_) {}

    final workingMsg = _mode == "medicine"
        ? t.translate('scan.readingMedicine', speech.currentLanguage)
        : t.translate('scan.readingPrescription', speech.currentLanguage);

    if (!mounted || _isDisposed) return;
    setState(() {
      _busy = true;
      _status = workingMsg;
      _medicineResult = null;
      _prescriptionResult = null;
    });
    speech.speak(workingMsg);

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (_mode == "medicine") {
        final result = await ai.scanMedicine(
          base64Image,
          imageFile: imageFile,
          language: speech.currentLanguage,
        );

        // Smart Auto-Detection: Check if uploaded photo is actually a doctor's prescription
        final scannedText = (result['scanned_text'] ?? '').toString();
        final hasPrescriptionKeywords = RegExp(
          r'(?:dr\.|doctor|m\.?b\.?b\.?s|m\.?d\.?|rx\b|clinic|hospital|psychiatrist|consultant|prescript|regd\.?\s*no)',
          caseSensitive: false,
        ).hasMatch(scannedText);

        if (hasPrescriptionKeywords && (result['name'] == null || result['name'].toString().isEmpty || result['name'] == "Medicine" || (result['confidence'] == 'low'))) {
          // Switch to prescription mode and process
          final prescResult = await ai.readPrescription(
            base64Image,
            imageFile: imageFile,
            language: speech.currentLanguage,
          );
          if ((prescResult['medicines'] as List?)?.isNotEmpty == true || (prescResult['doctor_name'] as String?)?.isNotEmpty == true) {
            if (!mounted) return;
            setState(() {
              _mode = "prescription";
              _prescriptionResult = prescResult;
              final count = (prescResult['medicines'] as List?)?.length ?? 0;
              _status = prescResult['spoken_summary'] ?? "Found $count medicines in this prescription.";
            });
            speech.speak(_status!);
            return;
          }
        }

        if (!mounted || _isDisposed) return;
        setState(() {
          _medicineResult = result;
          _status = result['spoken_summary'] ?? result['name'] ?? "Read successfully.";

          _nameController.text = (result['name'] ?? '').toString();
          _strengthController.text = (result['strength'] ?? '').toString();
          _formController.text = (result['form'] ?? 'Tablet').toString();
          _compositionController.text = (result['composition'] ?? '').toString();
          _purposeController.text = (result['purpose'] ?? '').toString();
          _whenToTakeController.text = (result['when_to_take'] ?? '').toString();
          _doseController.text = (result['dosage'] ?? '1 tablet').toString();
          _expiryController.text = (result['expiry_date'] ?? '').toString();
          _instructionsController.text = (result['instructions'] ?? '').toString();

          // Set schedule times from suggested_times or intelligent clinical parsing
          bool timesSet = false;
          if (result['suggested_times'] is List && (result['suggested_times'] as List).isNotEmpty) {
            final validTimes = (result['suggested_times'] as List)
                .map((e) => e.toString().trim())
                .where((e) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch(e))
                .toList();
            if (validTimes.isNotEmpty) {
              _timesController.text = validTimes.join(", ");
              timesSet = true;
            }
          }

          if (!timesSet) {
            final inst = "${_instructionsController.text} ${_whenToTakeController.text}".toLowerCase();
            if (inst.contains("3 to 4") || inst.contains("four times") || inst.contains("4 times")) {
              _timesController.text = "08:00, 13:00, 18:00, 22:00";
            } else if (inst.contains("thrice") || inst.contains("three times") || inst.contains("t.d.s")) {
              _timesController.text = "08:00, 14:00, 20:00";
            } else if (inst.contains("bedtime") || inst.contains("night") || inst.contains("h.s")) {
              _timesController.text = "21:00";
            } else if (inst.contains("twice") || inst.contains("b.d") || inst.contains("b.i.d") || inst.contains("two times") || inst.contains("morning and night")) {
              _timesController.text = "08:00, 20:00";
            } else {
              _timesController.text = "08:00";
            }
          }
        });
        speech.speak(_status!);
      } else {
        final result = await ai.readPrescription(
          base64Image,
          imageFile: imageFile,
          language: speech.currentLanguage,
        );

        if (!mounted || _isDisposed) return;
        setState(() {
          _prescriptionResult = result;
          final count = (result['medicines'] as List?)?.length ?? 0;
          _status = result['spoken_summary'] ?? "Found $count medicines in this prescription.";
        });
        speech.speak(_status!);
      }
    } catch (e) {
      debugPrint("Scan process error: $e");
      if (mounted && !_isDisposed) {
        final failMsg = t.translate('scan.failed', speech.currentLanguage);
        setState(() => _status = failMsg);
        speech.speak(failMsg);
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveMedicine() async {
    if (_medicineResult == null || _busy) return;
    setState(() => _busy = true);

    final db = Provider.of<DatabaseService>(context, listen: false);
    final speech = Provider.of<SpeechService>(context, listen: false);
    final t = Provider.of<I18nService>(context, listen: false);

    try {
      final medName = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : (_medicineResult!['name']?.toString().isNotEmpty == true
              ? _medicineResult!['name']
              : "Medicine");

      final medStrength = _strengthController.text.trim().isNotEmpty
          ? _strengthController.text.trim()
          : (_medicineResult!['strength']?.toString() ?? '');

      final medForm = _formController.text.trim().isNotEmpty
          ? _formController.text.trim()
          : (_medicineResult!['form']?.toString() ?? 'Tablet');

      final medDosage = _doseController.text.trim().isNotEmpty
          ? _doseController.text.trim()
          : (_medicineResult!['dosage']?.toString() ?? '1 tablet');

      final medExpiry = _expiryController.text.trim().isNotEmpty
          ? _expiryController.text.trim()
          : (_medicineResult!['expiry_date']?.toString() ?? '');

      final medInstructions = _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : (_medicineResult!['instructions']?.toString() ?? '');

      final medComposition = _compositionController.text.trim().isNotEmpty
          ? _compositionController.text.trim()
          : (_medicineResult!['composition']?.toString() ?? '');

      final medPurpose = _purposeController.text.trim().isNotEmpty
          ? _purposeController.text.trim()
          : (_medicineResult!['purpose']?.toString() ?? '');

      final medWhenToTake = _whenToTakeController.text.trim().isNotEmpty
          ? _whenToTakeController.text.trim()
          : (_medicineResult!['when_to_take']?.toString() ?? '');

      // Find existing medicine by name AND strength to prevent duplicate creation while allowing different strengths
      final existingMeds = await db.getMedicines();
      final clean = medName.toLowerCase();
      final cleanStr = medStrength.toLowerCase();
      final match = existingMeds.firstWhere(
        (m) => m['name']?.toString().trim().toLowerCase() == clean &&
               (cleanStr.isEmpty || m['strength']?.toString().trim().toLowerCase() == cleanStr),
        orElse: () => {},
      );
      final String medId = (match['id'] != null && match['id'].toString().isNotEmpty)
          ? match['id'].toString()
          : 'med_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Add/Update Medicine in database (Local + Cloud)
      await db.addMedicine({
        'id': medId,
        'name': medName,
        'dosage': medDosage,
        'strength': medStrength,
        'form': medForm,
        'composition': medComposition,
        'purpose': medPurpose,
        'when_to_take': medWhenToTake,
        'instructions': medInstructions,
        'scanned_text': _medicineResult!['scanned_text'] ?? '',
        'expiry_date': medExpiry,
      });

      // 2. Parse times & insert/update schedule
      final List<String> times = _timesController.text
          .split(",")
          .map((item) => item.trim())
          .where((item) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch(item))
          .map((item) => item.length == 4 ? "0$item" : item)
          .toSet()
          .toList();

      if (times.isNotEmpty) {
        await db.insertSchedule({
          'medicine_id': medId,
          'medicine_name': medName,
          'dosage': medDosage,
          'times': times,
          'days_of_week': [0, 1, 2, 3, 4, 5, 6],
          'start_date': DateTime.now().toIso8601String().substring(0, 10),
          'active': true,
        });
      }

      final savedMsg = speech.currentLanguage.startsWith('kn')
          ? "$medName ನಿಮ್ಮ ವೇಳಾಪಟ್ಟಿಗೆ ಯಶಸ್ವಿಯಾಗಿ ಉಳಿಸಲಾಗಿದೆ."
          : speech.currentLanguage.startsWith('hi')
              ? "$medName आपकी समय-सारणी में सफलतापूर्वक सहेज लिया गया है।"
              : "$medName saved successfully to your schedule.";
      speech.speak(savedMsg);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$medName saved!", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Reminders: ${times.join(', ')}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Save medicine error: $e");
      final fail = t.translate('scan.saveFailed', speech.currentLanguage);
      speech.speak(fail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text("Failed to save: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePrescription() async {
    if (_prescriptionResult == null || _busy) return;
    setState(() => _busy = true);

    final db = Provider.of<DatabaseService>(context, listen: false);
    final speech = Provider.of<SpeechService>(context, listen: false);
    final t = Provider.of<I18nService>(context, listen: false);

    try {
      final List medicines = _prescriptionResult!['medicines'] ?? [];

      await db.insertPrescription({
        'doctor_name': _prescriptionResult!['doctor_name'],
        'extracted_text': _prescriptionResult!['extracted_text'],
      });

      for (var item in medicines) {
        final medName = item['name'] ?? "Unnamed medicine";
        await db.addMedicine({
          'name': medName,
          'dosage': item['dosage'] ?? '1 tablet',
          'strength': item['strength'] ?? '',
          'form': item['form'] ?? 'Tablet',
          'when_to_take': item['when_to_take'] ?? '',
          'instructions': item['instructions'] ?? '',
          'scanned_text': _prescriptionResult!['extracted_text'] ?? '',
        });

        final allMeds = await db.getMedicines();
        final saved = allMeds.firstWhere(
          (m) => m['name'] == medName,
          orElse: () => allMeds.first,
        );

        final List<dynamic>? times = item['times'];
        if (times != null && times.isNotEmpty) {
          final int? duration = item['duration_days'];
          String? endDate;
          if (duration != null && duration > 0) {
            endDate = DateTime.now().add(Duration(days: duration)).toIso8601String().substring(0, 10);
          }

          await db.insertSchedule({
            'medicine_id': saved['id'],
            'times': times,
            'days_of_week': [0, 1, 2, 3, 4, 5, 6],
            'start_date': DateTime.now().toIso8601String().substring(0, 10),
            'end_date': endDate,
            'active': true,
          });
        }
      }

      final presMsg = speech.currentLanguage.startsWith('kn')
          ? "ಚೀಟಿ ಉಳಿಸಲಾಗಿದೆ. ${medicines.length} ಔಷಧಿಗಳನ್ನು ನಿಮ್ಮ ವೇಳಾಪಟ್ಟಿಗೆ ಸೇರಿಸಲಾಗಿದೆ."
          : speech.currentLanguage.startsWith('hi')
              ? "पर्चा सहेज लिया गया। ${medicines.length} दवाएं आपकी समय-सारणी में जोड़ दी गईं।"
              : "Prescription saved. ${medicines.length} medicines added to your schedule.";
      speech.speak(presMsg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text("${medicines.length} medicines saved from prescription!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Save prescription error: $e");
      final fail = t.translate('scan.saveFailed', speech.currentLanguage);
      speech.speak(fail);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final speech = Provider.of<SpeechService>(context);
    final t = Provider.of<I18nService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('scan.title', speech.currentLanguage),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white),
            ),
            Text(
              t.translate('scan.subtitle', speech.currentLanguage),
              style: const TextStyle(fontSize: 12, color: Color(0xFFECFDF5), fontWeight: FontWeight.w500),
            ),
          ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Tabs (Medicine box vs Prescription)
            _buildModeTabs(t, speech),
            const SizedBox(height: 20),

            // Captured Image Preview (if present)
            if (_selectedImageFile != null) ...[
              _buildImagePreview(),
              const SizedBox(height: 16),
            ],

            // Action: Take Photo (Primary Big Button)
            _buildTakePhotoButton(t),
            const SizedBox(height: 12),

            // Action: Upload Photo (Secondary Button)
            _buildUploadPhotoButton(t),
            const SizedBox(height: 20),

            // Status Announcement Card
            _buildStatusCard(),

            // "Repeat that" Button
            if (_status != null && _status!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildRepeatButton(speech, t),
            ],

            // Results Section: Medicine
            if (_medicineResult != null) ...[
              const SizedBox(height: 28),
              _buildMedicineResultCard(t, speech),
            ],

            // Results Section: Prescription
            if (_prescriptionResult != null) ...[
              const SizedBox(height: 28),
              _buildPrescriptionResultCard(t),
            ],

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTabs(I18nService t, SpeechService speech) {
    final tabs = [
      {'key': 'medicine', 'label': t.translate('scan.medicine', speech.currentLanguage)},
      {'key': 'prescription', 'label': t.translate('scan.prescription', speech.currentLanguage)},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _mode == tab['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mode = tab['key']!;
                  _medicineResult = null;
                  _prescriptionResult = null;
                });
                speech.speak(tab['label']!);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF059669) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(0xFF059669).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  tab['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF34D399).withValues(alpha: 0.4), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedImageFile!, fit: BoxFit.cover),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 16),
                  SizedBox(width: 4),
                  Text("Photo Ready", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakePhotoButton(I18nService t) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      onPressed: _busy ? null : () => _pickImage(ImageSource.camera),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_busy) ...[
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.5),
            ),
            const SizedBox(height: 12),
            Text(
              t.translate('scan.reading', Provider.of<SpeechService>(context, listen: false).currentLanguage),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ] else ...[
            const Icon(Icons.camera_alt_rounded, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              t.translate('scan.takePhoto', Provider.of<SpeechService>(context, listen: false).currentLanguage),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadPhotoButton(I18nService t) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF059669),
        side: const BorderSide(color: Color(0xFF059669), width: 1.8),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: _busy ? null : () => _pickImage(ImageSource.gallery),
      icon: const Icon(Icons.upload_file_rounded, size: 24, color: Color(0xFF059669)),
      label: Text(
        t.translate('scan.uploadPhoto', Provider.of<SpeechService>(context, listen: false).currentLanguage),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF059669).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF059669), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _status ?? "Ready when you are. Hold the pack steady in good light.",
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatButton(SpeechService speech, I18nService t) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF059669),
        side: const BorderSide(color: Color(0xFF059669), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () {
        if (_status != null) speech.speak(_status!);
      },
      icon: const Icon(Icons.volume_up_rounded, size: 22),
      label: Text(
        t.translate('common.repeat', speech.currentLanguage),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMedicineResultCard(I18nService t, SpeechService speech) {
    final lang = speech.currentLanguage;
    final isConfidenceHigh = _medicineResult!['confidence'] == 'high';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0xFF059669).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFF059669), width: 1.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.translate('scan.whatIRead', lang),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF059669), size: 24),
                tooltip: "Listen",
                onPressed: () {
                  final textToSpeak = _status ?? (_medicineResult!['spoken_summary'] ?? '');
                  if (textToSpeak.isNotEmpty) speech.speak(textToSpeak);
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfidenceHigh ? const Color(0xFF065F46) : const Color(0xFF854D0E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isConfidenceHigh ? "100% OCR Match" : "OCR Read",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Editable Medicine Name Field
          _buildFieldInput(
            label: t.translate('scan.field.name', lang),
            controller: _nameController,
            icon: Icons.medication_rounded,
          ),
          const SizedBox(height: 12),

          // Active Ingredients / Composition (What is available in the medicine)
          _buildFieldInput(
            label: lang.startsWith('kn')
                ? "ಔಷಧಿಯ ಘಟಕಗಳು (Composition)"
                : lang.startsWith('hi')
                    ? "सक्रिय घटक (Composition)"
                    : "Active Ingredients / Composition",
            controller: _compositionController,
            icon: Icons.science_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          // Purpose / What it is used for
          _buildFieldInput(
            label: lang.startsWith('kn')
                ? "ಬಳಕೆ / ಉದ್ದೇಶ (Purpose)"
                : lang.startsWith('hi')
                    ? "उपयोग / संकेत (Purpose)"
                    : "Purpose / Used For",
            controller: _purposeController,
            icon: Icons.healing_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          // When & How To Take This Tablet (Clinical Guidance from Gemini AI)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF059669), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.alarm_on_rounded, color: Color(0xFF059669), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang.startsWith('kn')
                            ? "ಮಾತ್ರೆ ತೆಗೆದುಕೊಳ್ಳುವ ಸಮಯ ಮತ್ತು ವಿಧಾನ (When & How to Take)"
                            : lang.startsWith('hi')
                                ? "दवा लेने का समय और तरीका (When & How to Take)"
                                : "When & How To Take This Tablet",
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _whenToTakeController,
                  maxLines: 3,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
                  decoration: InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: lang.startsWith('kn')
                        ? "ಯಾವಾಗ ಮತ್ತು ಹೇಗೆ ತೆಗೆದುಕೊಳ್ಳಬೇಕು (ಉದಾ: ಊಟದ ನಂತರ...)"
                        : lang.startsWith('hi')
                            ? "कब और कैसे लेना है (उदा: भोजन के बाद...)"
                            : "When & how to take (e.g. after food, twice daily...)",
                    hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Strength & Form in a Row
          Row(
            children: [
              Expanded(
                child: _buildFieldInput(
                  label: t.translate('scan.field.strength', lang),
                  controller: _strengthController,
                  icon: Icons.fitness_center_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFieldInput(
                  label: t.translate('scan.field.form', lang),
                  controller: _formController,
                  icon: Icons.category_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dosage & Expiry Date in a Row
          Row(
            children: [
              Expanded(
                child: _buildFieldInput(
                  label: t.translate('scan.field.dose', lang),
                  controller: _doseController,
                  icon: Icons.pin_invoke_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFieldInput(
                  label: t.translate('scan.field.expiry', lang),
                  controller: _expiryController,
                  icon: Icons.calendar_today_rounded,
                  isExpiry: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Instructions
          _buildFieldInput(
            label: t.translate('scan.field.instructions', lang),
            controller: _instructionsController,
            icon: Icons.info_outline_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
          const SizedBox(height: 14),

          // Schedule Times
          Text(
            t.translate('scan.times', lang),
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _timesController,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              hintText: "e.g. 08:00, 20:00",
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
            ),
          ),
          const SizedBox(height: 20),

          // Exact Scanned Packaging Text
          if (_medicineResult!['scanned_text'] != null && _medicineResult!['scanned_text'].toString().trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.text_snippet_rounded, size: 16, color: Color(0xFF059669)),
                          SizedBox(width: 6),
                          Text(
                            "Exact Text from Packaging",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.volume_up_rounded, size: 20, color: Color(0xFF059669)),
                        tooltip: "Read packaging text aloud",
                        onPressed: () {
                          speech.speak(_medicineResult!['scanned_text'].toString());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _medicineResult!['scanned_text'].toString(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Save Medicine Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _busy ? null : _saveMedicine,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 24),
            label: Text(
              t.translate('scan.saveMedicine', lang),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    bool isExpiry = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700, fontSize: 13),
            ),
            if (isExpiry)
              GestureDetector(
                onTap: () => _pickExpiryDate(controller),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Color(0xFF059669)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, color: Color(0xFF059669), size: 12),
                      SizedBox(width: 4),
                      Text("Tap to set date", style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isExpiry,
          onTap: isExpiry ? () => _pickExpiryDate(controller) : null,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            prefixIcon: Icon(icon, color: Color(0xFF059669), size: 18),
            suffixIcon: isExpiry
                ? IconButton(
                    icon: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF059669), size: 20),
                    onPressed: () => _pickExpiryDate(controller),
                  )
                : null,
            hintText: isExpiry ? "Tap to pick expiry date" : null,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickExpiryDate(TextEditingController controller) async {
    final now = DateTime.now();
    DateTime initial = now.add(const Duration(days: 365));
    if (controller.text.isNotEmpty) {
      final parsed = DateTime.tryParse(controller.text);
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2045),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final mStr = picked.month < 10 ? "0${picked.month}" : "${picked.month}";
      final dStr = picked.day < 10 ? "0${picked.day}" : "${picked.day}";
      setState(() {
        controller.text = "${picked.year}-$mStr-$dStr";
        if (_medicineResult != null) {
          _medicineResult!['expiry_date'] = controller.text;
        }
      });
      final speech = Provider.of<SpeechService>(context, listen: false);
      speech.speak("Expiry date set to ${picked.year} $mStr $dStr.");
    }
  }

  Widget _buildPrescriptionResultCard(I18nService t) {
    final speech = Provider.of<SpeechService>(context, listen: false);
    final lang = speech.currentLanguage;
    final List medicines = _prescriptionResult!['medicines'] ?? [];
    final doctor = _prescriptionResult!['doctor_name'];
    final clinic = _prescriptionResult!['clinic_name'];
    final date = _prescriptionResult!['date'];
    final diagnosis = _prescriptionResult!['diagnosis'];
    final rawText = _prescriptionResult!['extracted_text']?.toString() ?? "";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFF059669), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF059669).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.description_rounded, color: Color(0xFF059669), size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.translate('scan.medicinesFound', lang),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF059669), size: 24),
                tooltip: "Listen",
                onPressed: () {
                  final textToSpeak = _status ?? (_prescriptionResult!['spoken_summary'] ?? '');
                  if (textToSpeak.isNotEmpty) speech.speak(textToSpeak);
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFA7F3D0)),
                ),
                child: Text(
                  "${medicines.length} Found",
                  style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Doctor & Clinic Information
          if ((doctor != null && doctor.toString().isNotEmpty) || (clinic != null && clinic.toString().isNotEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xFFA7F3D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (doctor != null && doctor.toString().isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            doctor.toString(),
                            style: const TextStyle(
                              color: Color(0xFF065F46),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (clinic != null && clinic.toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_rounded, color: Color(0xFF059669), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            clinic.toString(),
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((date != null && date.toString().isNotEmpty) || (diagnosis != null && diagnosis.toString().isNotEmpty)) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (date != null && date.toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              "Date: $date",
                              style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            ),
                          ),
                        if (diagnosis != null && diagnosis.toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              "Diagnosis: $diagnosis",
                              style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Medicines List
          ...medicines.map((m) {
            final name = m['name'] ?? "Medicine";
            final form = m['form']?.toString() ?? "";
            final strength = m['strength']?.toString() ?? "";
            final dose = m['dosage']?.toString() ?? "";
            final freq = m['frequency']?.toString() ?? "";
            final times = (m['times'] as List?)?.map((e) => e.toString()).join(", ") ?? "";
            final when = m['when_to_take']?.toString() ?? "";
            final duration = m['duration_days'] != null && (m['duration_days'] as num) > 0
                ? "${m['duration_days']} days"
                : "";
            final inst = m['instructions']?.toString() ?? "";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                      if (form.isNotEmpty || strength.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            [form, strength].where((s) => s.isNotEmpty).join(" "),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (dose.isNotEmpty || times.isNotEmpty || freq.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (dose.isNotEmpty) dose,
                              if (times.isNotEmpty) "Times: $times",
                              if (freq.isNotEmpty) "($freq)",
                            ].join(" · "),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (when.isNotEmpty || duration.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.restaurant_rounded, size: 15, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (when.isNotEmpty) when,
                              if (duration.isNotEmpty) "Duration: $duration",
                            ].join(" · "),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (inst.isNotEmpty && inst != when) ...[
                    Text(
                      inst,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            );
          }),

          // Full Scanned Text Preview
          if (rawText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.text_snippet_rounded, size: 16, color: Color(0xFF059669)),
                          SizedBox(width: 6),
                          Text(
                            "Exact Text from Prescription",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.volume_up_rounded, size: 20, color: Color(0xFF059669)),
                        tooltip: "Read prescription text aloud",
                        onPressed: () {
                          speech.speak(rawText);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rawText,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _busy ? null : _savePrescription,
            icon: const Icon(Icons.done_all_rounded, size: 24),
            label: Text(
              t.translate('scan.saveAll', lang),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
