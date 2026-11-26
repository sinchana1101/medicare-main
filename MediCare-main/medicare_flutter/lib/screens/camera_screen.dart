import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';
import '../services/voice_controller.dart';
import '../services/voice_intent_service.dart';

class CameraScreen extends StatefulWidget {
  final bool autoCapture;
  const CameraScreen({super.key, this.autoCapture = false});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> implements VoiceScreenDelegate {
  VoiceController? _voiceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _voiceController = Provider.of<VoiceController>(context, listen: false);
    } catch (_) {}
  }

  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  Offset? _focusPoint;

  @override
  void initState() {
    super.initState();
    _initCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final voice = Provider.of<VoiceController>(context, listen: false);
        voice.setActiveDelegate(this, AppScreen.camera);
        // Mic state preserved (toggled only by double-tap)
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("No cameras available on this device");
        return;
      }
      _cameras = cameras;

      // Prioritize rear/back camera so medicine packaging is scanned instead of selfie camera
      int preferredIndex = 0;
      for (int i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == CameraLensDirection.back) {
          preferredIndex = i;
          break;
        }
      }
      _selectedCameraIndex = preferredIndex;

      // Use veryHigh (1080p) so small text on medicine strips is captured with razor-sharp clarity
      _controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _controller!.initialize().then((_) async {
        try {
          await _controller!.setFocusMode(FocusMode.auto);
        } catch (e) {
          debugPrint("Camera setFocusMode note: $e");
        }
        try {
          await _controller!.setExposureMode(ExposureMode.auto);
        } catch (_) {}
        try {
          await _controller!.setFlashMode(FlashMode.off);
        } catch (_) {}
        if (mounted) setState(() {});
        // Camera ready - waits for user to aim packaging and tap button or speak 'capture'
      });
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _selectedCameraIndex = nextIndex;
    _controller?.dispose();
    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _controller!.initialize().then((_) async {
      try {
        await _controller!.setFocusMode(FocusMode.auto);
      } catch (_) {}
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  Future<void> _toggleTorch() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final nextMode = _isTorchOn ? FlashMode.off : FlashMode.torch;
      await _controller!.setFlashMode(nextMode);
      setState(() => _isTorchOn = !_isTorchOn);
      HapticFeedback.lightImpact();
      if (!mounted) return;
      final speech = Provider.of<SpeechService>(context, listen: false);
      final lang = speech.currentLanguage;
      if (_isTorchOn) {
        speech.speak(lang.startsWith('kn') ? "ಟಾರ್ಚ್ ಆನ್ ಮಾಡಲಾಗಿದೆ." : lang.startsWith('hi') ? "टॉर्च चालू किया गया।" : "Torch on.");
      } else {
        speech.speak(lang.startsWith('kn') ? "ಟಾರ್ಚ್ ಆಫ್ ಮಾಡಲಾಗಿದೆ." : lang.startsWith('hi') ? "टॉर्च बंद किया गया।" : "Torch off.");
      }
    } catch (e) {
      debugPrint("Torch toggle error: $e");
    }
  }

  @override
  void dispose() {
    _voiceController?.clearActiveDelegate(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  String getScreenAnnouncement() {
    if (!mounted) return "";
    final speech = Provider.of<SpeechService>(context, listen: false);
    final lang = speech.currentLanguage;
    if (lang.startsWith('kn')) {
      return "ಕ್ಯಾಮೆರಾ ಸಿದ್ಧ";
    } else if (lang.startsWith('hi')) {
      return "कैमरा तैयार";
    }
    return "Camera ready";
  }

  @override
  Future<bool> handleVoiceCommand(VoiceIntent? intent, String transcript) async {
    if (!mounted) return false;
    final lower = transcript.toLowerCase().trim();
    debugPrint("CameraScreen handleVoiceCommand: '$transcript' (intent: $intent)");

    if (intent == VoiceIntent.home ||
        intent == VoiceIntent.back ||
        intent == VoiceIntent.cancel ||
        lower.contains("home") ||
        lower.contains("back") ||
        lower.contains("cancel") ||
        lower.contains("exit") ||
        transcript.contains("ಮುಖಪುಟ") ||
        transcript.contains("ಹೋಮ್") ||
        transcript.contains("ಮನೆ") ||
        transcript.contains("ಹಿಂದಕ್ಕೆ") ||
        transcript.contains("ವಾಪಸ್") ||
        transcript.contains("ಹಿಂತಿರುಗಿ") ||
        transcript.contains("ಹಿಂದೆ") ||
        transcript.contains("होम") ||
        transcript.contains("घर") ||
        transcript.contains("वापस")) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return true;
    }

    // Toggle Torch on voice command
    if (lower.contains("torch") ||
        lower.contains("light") ||
        lower.contains("flash") ||
        transcript.contains("ಟಾರ್ಚ್") ||
        transcript.contains("ಬೆಳಕು") ||
        transcript.contains("ಫ್ಲ್ಯಾಶ್") ||
        transcript.contains("टॉर्च") ||
        transcript.contains("लाइट")) {
      await _toggleTorch();
      return true;
    }

    // Photo capture commands specifically - triggers shutter immediately!
    if (intent == VoiceIntent.takePhoto ||
        lower.contains("capture") ||
        lower.contains("click") ||
        lower.contains("snap") ||
        lower.contains("shoot") ||
        lower.contains("photo") ||
        lower.contains("picture") ||
        lower.contains("take") ||
        lower.contains("camera") ||
        lower.contains("cheese") ||
        lower.contains("tege") ||
        lower.contains("thege") ||
        lower.contains("thago") ||
        lower.contains("tegi") ||
        lower.contains("khicho") ||
        lower.contains("kheencho") ||
        lower.contains("chitra") ||
        lower.contains("now") ||
        transcript.contains("ಕ್ಲಿಕ್") ||
        transcript.contains("ಫೋಟೋ") ||
        transcript.contains("ಕ್ಯಾಪ್ಚರ್") ||
        transcript.contains("ಚಿತ್ರ") ||
        transcript.contains("ತೆಗೆ") ||
        transcript.contains("ಕ್ಯಾಮರಾ") ||
        transcript.contains("फोटो") ||
        transcript.contains("क्लिक") ||
        transcript.contains("खींचो") ||
        transcript.contains("तस्वीर") ||
        transcript.contains("कैमरा")) {
      await _captureAndScan();
      return true;
    }

    // Any other command is NOT handled by CameraScreen, allowing VoiceController to execute global navigation/actions!
    return false;
  }

  Future<void> _captureAndScan() async {
    if (_isProcessing) return;
    if (_controller == null || !_controller!.value.isInitialized) {
      if (_initializeControllerFuture != null) {
        try {
          await _initializeControllerFuture;
        } catch (_) {}
      }
    }
    if (!mounted) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    setState(() => _isProcessing = true);
    debugPrint("CameraScreen: executing _captureAndScan now!");

    final speech = Provider.of<SpeechService>(context, listen: false);
    final lang = speech.currentLanguage;

    try {
      // Lock focus right before capturing to ensure pin-sharp medicine text
      try {
        await _controller!.setFocusMode(FocusMode.locked);
      } catch (_) {}

      final image = await _controller!.takePicture();

      try {
        await _controller!.setFocusMode(FocusMode.auto);
      } catch (_) {}

      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}

      final capturedMsg = lang.startsWith('kn')
          ? "ಫೋಟೋ ತೆಗೆಯಲಾಗಿದೆ. ಔಷಧಿಯನ್ನು ಓದಲಾಗುತ್ತಿದೆ..."
          : lang.startsWith('hi')
              ? "फोटो खींच ली गई। दवा पढ़ी जा रही है..."
              : "Photo captured. Reading medicine...";
      await speech.speak(capturedMsg);

      if (mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      debugPrint("Camera capture error: $e");
      final retryMsg = lang.startsWith('kn')
          ? "ದಯವಿಟ್ಟು ಸ್ಥಿರವಾಗಿ ಹಿಡಿದು ಮತ್ತೆ ಫೋಟೋ ತೆಗೆಯಿರಿ."
          : lang.startsWith('hi')
              ? "कृपया दवा को स्थिर रखें और दोबारा फोटो लें।"
              : "Please hold steady and tap Capture again.";
      speech.speak(retryMsg);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _onTapToFocus(TapDownDetails details) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final size = MediaQuery.of(context).size;
      final x = (details.globalPosition.dx / size.width).clamp(0.0, 1.0);
      final y = (details.globalPosition.dy / size.height).clamp(0.0, 1.0);
      await _controller!.setFocusPoint(Offset(x, y));
      await _controller!.setExposurePoint(Offset(x, y));
      setState(() {
        _focusPoint = details.globalPosition;
      });
      HapticFeedback.selectionClick();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _focusPoint = null);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Medicine Label", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF059669),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? const Color(0xFFFACC15) : Colors.white,
              size: 26,
            ),
            tooltip: _isTorchOn ? "Turn Torch Off" : "Turn Torch On for Clear OCR",
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 24),
            tooltip: "Switch Camera",
            onPressed: _switchCamera,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null &&
              _controller!.value.isInitialized) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _onTapToFocus,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_controller!),
                  // Tap to focus reticle indicator
                  if (_focusPoint != null)
                    Positioned(
                      left: _focusPoint!.dx - 32,
                      top: _focusPoint!.dy - kToolbarHeight - 32,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF34D399), width: 2.5),
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                  // High contrast guide box for packaging alignment
                  Center(
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF34D399), width: 3.5),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Hold medicine packaging inside green box",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Say \"CAPTURE\" or tap button below. Tap screen to focus.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.85),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF34D399), strokeWidth: 5),
                            SizedBox(height: 24),
                            Text(
                              "READING MEDICINE...",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF34D399)));
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: _captureAndScan,
        icon: const Icon(Icons.camera_alt_rounded, size: 28),
        label: const Text("Capture Photo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
