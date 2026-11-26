import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'voice_intent_service.dart';

import 'speech_engine_interface.dart';

export 'speech_engine_interface.dart';

class SpeechService extends ChangeNotifier {

  final FlutterTts _tts = FlutterTts();

  final NativeSpeechEngine _nativeEngine = NativeSpeechEngine();

  final WhisperModelManager _whisperManager = WhisperModelManager();

  WhisperSpeechEngine? _whisperEngine;

  late ISpeechEngine _currentEngine;

  String _currentLanguage = 'en-US';

  String get currentLanguage => _currentLanguage;

  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  bool _isListening = false;

  bool get isListening => _isListening;

  bool _isSttInitialized = false;

  bool get isSttInitialized => _isSttInitialized;

  String _lastSpokenText = "";

  String get lastSpokenText => _lastSpokenText;

  String _lastRecognizedText = "";

  String get lastRecognizedText => _lastRecognizedText;

  bool _noiseCancellation = true;

  bool get noiseCancellation => _noiseCancellation;

  SpeechEngineType get activeEngineType => _currentEngine.engineType;

  WhisperModelManager get whisperModelManager => _whisperManager;

  ISpeechEngine get activeEngine => _currentEngine;

  void setNoiseCancellation(bool enabled) {

    if (_noiseCancellation != enabled) {

      _noiseCancellation = enabled;

      notifyListeners();

    }

  }

  void Function(String status)? _onStatusChange;

  void Function(dynamic error)? _onErrorCallback;

  void Function(VoiceIntent intent, String transcript)? onInstantIntent;

  Timer? _speechTimeoutTimer;

  SpeechService() {

    _currentEngine = _nativeEngine;

    _initTts();

    _initStt();

  }

  /// Switches active speech recognition engine safely.

  /// Falls back to native engine if Whisper model is not downloaded or failed.

  Future<bool> switchSpeechEngine(SpeechEngineType type) async {

    if (_currentEngine.engineType == type) return true;

    if (_isListening) {

      await stopSTT();

    }

    if (type == SpeechEngineType.native) {

      _currentEngine = _nativeEngine;

      _isSttInitialized = _nativeEngine.isInitialized;

      notifyListeners();

      return true;

    } else {

      _whisperEngine ??= WhisperSpeechEngine(modelManager: _whisperManager);

      final isReady = await _whisperManager.checkModelReady();

      if (!isReady) {

        debugPrint("Whisper model not ready on device. Please download first.");

        return false;

      }

      final success = await _whisperEngine!.initialize(

        onStatus: (status) => debugPrint("Whisper status: $status"),

        onError: (err) => debugPrint("Whisper error: $err"),

      );

      if (success) {

        _currentEngine = _whisperEngine!;

        _isSttInitialized = true;

        notifyListeners();

        return true;

      } else {

        debugPrint("Failed to initialize Whisper engine. Retaining native engine.");

        _currentEngine = _nativeEngine;

        notifyListeners();

        return false;

      }

    }

  }

  bool _isGoogleEngineSelected = false;

  String _lastAppliedLanguage = "";

  void _initTts() {

    _tts.setStartHandler(() {

      _isSpeaking = true;

      notifyListeners();

    });

    _tts.setCompletionHandler(() {

      _isSpeaking = false;

      _speechTimeoutTimer?.cancel();

      notifyListeners();

    });

    _tts.setErrorHandler((msg) {

      debugPrint("TTS error: $msg");

      _isSpeaking = false;

      _speechTimeoutTimer?.cancel();

      notifyListeners();

    });

    _tts.setCancelHandler(() {

      debugPrint("TTS cancel handler fired");

      _isSpeaking = false;

      _speechTimeoutTimer?.cancel();

      notifyListeners();

    });

    // Natural, crisp rate and pitch for clear, responsive feedback
    _tts.setSpeechRate(1.0);
    _tts.setPitch(1.0);
    _tts.setVolume(1.0);
    _initTtsEngineAndLanguage();

  }

  Future<void> _initTtsEngineAndLanguage() async {

    if (!_isGoogleEngineSelected) {

      try {

        final engines = await _tts.getEngines;

        if (engines is List && engines.contains("com.google.android.tts")) {

          await _tts.setEngine("com.google.android.tts");

          _isGoogleEngineSelected = true;

          debugPrint("Google TTS engine initialized once for Indic languages");

        }

      } catch (e) {

        debugPrint("Initial TTS engine note: $e");

      }

    }

    await _tts.setVolume(1.0);
    await _applyTtsLanguage(_currentLanguage);

  }

  Future<void> _initStt() async {

    try {

      _isSttInitialized = await _currentEngine.initialize(

        onError: (val) {

          debugPrint("STT init error: $val");

          _onErrorCallback?.call(val);

          _isListening = false;

          notifyListeners();

        },

        onStatus: (status) {

          debugPrint("STT status: $status");

          _onStatusChange?.call(status);

          if (status == 'notListening' || status == 'done') {

            if (_isListening) {

              _isListening = false;

              notifyListeners();

            }

          }

        },

      );

      debugPrint("STT initialized: $_isSttInitialized");

      notifyListeners();

    } catch (e) {

      debugPrint("STT initialization exception: $e");

    }

  }

  Future<void> _applyTtsLanguage(String lang) async {

    if (_lastAppliedLanguage == lang) return;

    final List<String> candidates = [];

    if (lang.startsWith('kn')) {

      candidates.addAll(['kn-IN', 'kn_IN', 'kn', 'kan-IND', 'kan_IND', 'kan']);

    } else if (lang.startsWith('hi')) {

      candidates.addAll(['hi-IN', 'hi_IN', 'hi', 'hin-IND', 'hin_IND', 'hin']);

    } else {

      candidates.addAll(['en-US', 'en_US', 'en-IN', 'en_IN', 'en']);

    }

    if (lang.contains('-')) {

      candidates.add(lang);

      candidates.add(lang.replaceAll('-', '_'));

      candidates.add(lang.split('-').first);

      candidates.add(lang.toLowerCase());

      candidates.add(lang.toLowerCase().replaceAll('-', '_'));

    } else if (lang.contains('_')) {

      candidates.add(lang);

      candidates.add(lang.replaceAll('_', '-'));

      candidates.add(lang.split('_').first);

    } else {

      candidates.add(lang);

    }

    for (final candidate in candidates) {

      try {

        final dynamic res = await _tts.setLanguage(candidate);

        // On Android, 0 = LANG_AVAILABLE, 1 = LANG_COUNTRY_AVAILABLE, 2 = LANG_COUNTRY_VAR_AVAILABLE

        // Any return code >= 0 indicates success!

        if (res != null && (res == 1 || res == 0 || res == 2 || (res is num && res >= 0))) {

          _lastAppliedLanguage = lang;

          debugPrint("TTS accepted language: $candidate (code: $res)");

          return;

        }

      } catch (e) {

        debugPrint("TTS candidate $candidate failed: $e");

      }

    }

    // Fallback: inspect available voices

    try {

      final voices = await _tts.getVoices;

      if (voices is List) {

        for (final v in voices) {

          if (v is Map) {

            final loc = (v['locale'] ?? '').toString().toLowerCase();

            final name = (v['name'] ?? '').toString().toLowerCase();

            if (lang.startsWith('kn') && (loc.contains('kn') || name.contains('kn') || loc.contains('kan'))) {

              await _tts.setVoice({"name": v['name'].toString(), "locale": v['locale'].toString()});

              _lastAppliedLanguage = lang;

              return;

            } else if (lang.startsWith('hi') && (loc.contains('hi') || name.contains('hi') || loc.contains('hin'))) {

              await _tts.setVoice({"name": v['name'].toString(), "locale": v['locale'].toString()});

              _lastAppliedLanguage = lang;

              return;

            }

          }

        }

      }

    } catch (_) {}

  }

  set currentLanguage(String lang) {

    if (_currentLanguage != lang) {

      _currentLanguage = lang;

      _applyTtsLanguage(lang);

      notifyListeners();

    }

  }

  Future<void> announceLanguageChanged(String langCode) async {

    _currentLanguage = langCode;

    await _applyTtsLanguage(langCode);

    notifyListeners();

    if (langCode.startsWith('kn')) {

      await speak("ಭಾಷೆಯನ್ನು ಕನ್ನಡಕ್ಕೆ ಬದಲಾಯಿಸಲಾಗಿದೆ. ನೀವು ಈಗ ಕನ್ನಡದಲ್ಲಿ ಮಾತನಾಡಬಹುದು.");

    } else if (langCode.startsWith('hi')) {

      await speak("भाषा बदलकर हिंदी कर दी गई है। अब आप हिंदी में बोल सकते हैं।");

    } else {

      await speak("Language changed to English. You can now speak in English.");

    }

  }

  Future<void> speak(String text, {bool interrupt = true}) async {

    if (text.trim().isEmpty) return;

    _lastSpokenText = text;

    if (interrupt) {

      await stopTTS();

    }

    _isSpeaking = true;

    notifyListeners();

    _speechTimeoutTimer?.cancel();

    final safetyMs = (text.length * 80 + 900).clamp(900, 8000);

    _speechTimeoutTimer = Timer(Duration(milliseconds: safetyMs), () {

      if (_isSpeaking) {

        debugPrint("Safety TTS timer triggered: resetting _isSpeaking to false");

        _isSpeaking = false;

        notifyListeners();

      }

    });

    // Auto-detect Indic scripts to prevent speaking Kannada/Hindi with English voice

    String targetLang = _currentLanguage;

    if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(text)) {

      targetLang = 'kn-IN';

    } else if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {

      targetLang = 'hi-IN';

    }

    await _applyTtsLanguage(targetLang);

    await _tts.speak(text);

  }

  Future<void> stopTTS() async {

    _speechTimeoutTimer?.cancel();

    try {

      await _tts.stop();

    } catch (e) {

      debugPrint("TTS stop error: $e");

    }

    _isSpeaking = false;

    notifyListeners();

  }

  Future<void> stopSTT() async {

    try {

      await _currentEngine.stopListening();

    } catch (e) {

      debugPrint("STT stop error: $e");

    }

    _isListening = false;

    notifyListeners();

  }

  Future<void> stop() async {

    await stopTTS();

    await stopSTT();

  }

  Future<void> stopSpeech() async {

    await stopTTS();

  }

  Future<void> repeat() async {

    if (_lastSpokenText.isNotEmpty) {

      await speak(_lastSpokenText);

    }

  }

  Future<void> waitForSpeech({int maxWaitMs = 500}) async {
    if (!_isSpeaking) return;
    final start = DateTime.now();
    while (_isSpeaking) {
      if (DateTime.now().difference(start).inMilliseconds > maxWaitMs) {
        _isSpeaking = false;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 15));
    }
  }

  Future<String> listenOnce({int timeoutSeconds = 8}) async {
    if (_isSpeaking) {
      await stopTTS();
    }
    if (_isListening) {
      await stopSTT();
      
    }

    if (!_isSttInitialized) {

      await _initStt();

    }

    _isListening = true;

    _lastRecognizedText = "";

    notifyListeners();

    try {

      final transcript = await _currentEngine.listenOnce(

        language: _currentLanguage,

        timeoutSeconds: timeoutSeconds,

        noiseCancellation: _noiseCancellation,

        onPartialResult: (text) {
          _lastRecognizedText = text;
          notifyListeners();
        },

        onInstantIntent: (intent, text) {

          // Conversational Barge-in

          if (_isSpeaking && text.trim().isNotEmpty) {

            stopTTS();

          }

          _lastRecognizedText = text;

          notifyListeners();

          onInstantIntent?.call(intent, text);

        },

      );

      _lastRecognizedText = transcript;

      return transcript;

    } finally {

      _isListening = false;

      notifyListeners();

    }

  }

}

