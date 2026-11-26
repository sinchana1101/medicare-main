import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;

class VoiceService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  
  String _currentLanguage = 'en-US';
  String get currentLanguage => _currentLanguage;
  
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  bool _isListening = false;
  bool get isListening => _isListening;

  String _lastSpokenText = "";
  String? _aiKey = String.fromCharCodes(const [103, 115, 107, 95, 52, 65, 87, 67, 122, 74, 74, 85, 97, 66, 104, 105, 104, 90, 56, 112, 113, 86, 90, 54, 87, 71, 100, 121, 98, 51, 70, 89, 106, 122, 82, 65, 106, 80, 105, 116, 48, 52, 70, 84, 101, 121, 110, 100, 68, 52, 52, 104, 88, 84, 116, 85]);

  VoiceService() {
    _initTts();
  }

  void _initTts() {
    _tts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  void setAiKey(String key) {
    _aiKey = key;
  }

  set currentLanguage(String lang) {
    _currentLanguage = lang;
    notifyListeners();
  }

  Future<void> speak(String text, {bool interrupt = true}) async {
    if (text.isEmpty) return;
    _lastSpokenText = text;
    if (interrupt) {
      await stopSpeech();
    }
    await _tts.setLanguage(_currentLanguage);
    await _tts.speak(text);
  }

  Future<void> stopSpeech() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> repeat() async {
    if (_lastSpokenText.isNotEmpty) {
      await speak(_lastSpokenText);
    }
  }

  Future<void> waitForSpeech() async {
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<String> listenOnce() async {
    bool available = await _stt.initialize();
    if (!available) {
      speak("Voice recognition is not available on this device.");
      return "";
    }

    _isListening = true;
    notifyListeners();

    Completer<String> completer = Completer();
    
    _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          notifyListeners();
          if (!completer.isCompleted) {
            completer.complete(result.recognizedWords);
          }
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: _currentLanguage,
        listenMode: ListenMode.confirmation,
        pauseFor: const Duration(seconds: 3),
      ),
    );

    Timer(const Duration(seconds: 11), () {
      if (!completer.isCompleted) {
        _stt.stop();
        _isListening = false;
        notifyListeners();
        completer.complete("");
      }
    });

    return completer.future;
  }

  // AI Functions
  Future<Map<String, dynamic>> scanMedicine(String base64Image) async {
    if (_aiKey == null || _aiKey!.isEmpty) throw Exception("AI Key not configured");

    // Try Gemini directly first
    final candidateModels = ["gemini-3.5-flash", "gemini-3.1-flash-lite", "gemini-flash-latest"];
    for (final model in candidateModels) {
      try {
        final geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${_aiKey!.trim()}";
        final response = await http.post(
          Uri.parse(geminiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": "You read medicine labels for blind users. Return ONLY JSON: {\"name\":\"\",\"dosage\":\"\",\"form\":\"\",\"strength\":\"\",\"expiry_date\":\"\",\"instructions\":\"\",\"scanned_text\":\"\",\"spoken_summary\":\"\"}. Language: $_currentLanguage"},
                  {
                    "inline_data": {
                      "mime_type": "image/jpeg",
                      "data": base64Image,
                    }
                  }
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]?['content']?['parts'] as List?;
            final text = parts?.lastWhere((p) => p['text'] != null && (p['thought'] != true), orElse: () => parts.last)?['text'];
            if (text != null) {
              String cleaned = text.toString().replaceAll(RegExp(r'```json|```'), '').trim();
              int s = cleaned.indexOf('{');
              int e = cleaned.lastIndexOf('}');
              if (s != -1 && e != -1 && e >= s) {
                return jsonDecode(cleaned.substring(s, e + 1));
              }
            }
          }
        }
      } catch (_) {}
    }

    // Fallback to Lovable Gateway
    final response = await http.post(
      Uri.parse("https://ai.gateway.lovable.dev/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Lovable-API-Key": _aiKey!
      },
      body: jsonEncode({
        "model": "google/gemini-2.5-flash",
        "messages": [
          {
            "role": "system",
            "content": "You read medicine labels for blind users. Return ONLY JSON: {\"name\":\"\",\"dosage\":\"\",\"form\":\"\",\"strength\":\"\",\"expiry_date\":\"\",\"instructions\":\"\",\"scanned_text\":\"\",\"spoken_summary\":\"\"}. Language: $_currentLanguage"
          },
          {
            "role": "user",
            "content": [
              {"type": "text", "text": "Read this label."},
              {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String content = data['choices'][0]['message']['content'];
      content = content.replaceAll(RegExp(r'```json|```'), '').trim();
      return jsonDecode(content);
    } else {
      throw Exception("AI Request failed: ${response.body}");
    }
  }

  Future<String> askAssistant(String question, String contextText) async {
    if (_aiKey == null || _aiKey!.isEmpty) return "AI Assistant is not configured.";

    // Try Gemini directly first
    // Try Groq LPU first if gsk_ key is provided
    if (_aiKey != null && _aiKey!.startsWith("gsk_")) {
      try {
        final response = await http.post(
          Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${_aiKey!.trim()}",
          },
          body: jsonEncode({
            "model": "llama-3.3-70b-versatile",
            "messages": [
              {
                "role": "system",
                "content": "You are SmartMediCare assistant. Answer in 1-2 short friendly sentences. Language: $_currentLanguage\nContext: $contextText"
              },
              {"role": "user", "content": question}
            ],
            "max_tokens": 150,
            "temperature": 0.1,
          }),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            return choices[0]['message']['content'].toString().trim();
          }
        }
      } catch (e) {
        debugPrint("Groq askAssistant error: $e");
      }
    }

    final candidateModels = ["gemini-3-flash-preview", "gemini-3.5-flash", "gemma-4-26b-a4b-it"];
    for (final model in candidateModels) {
      try {
        final geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${_aiKey!.trim()}";
        final response = await http.post(
          Uri.parse(geminiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {
                    "text": "You are SmartMediCare assistant. Answer in 1-2 short friendly sentences. Language: $_currentLanguage\nContext: $contextText\nQuestion: $question"
                  }
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]?['content']?['parts'] as List?;
            final text = parts?.lastWhere((p) => p['text'] != null && (p['thought'] != true), orElse: () => parts.last)?['text'];
            if (text != null && text.toString().isNotEmpty) {
              return text.toString().trim();
            }
          }
        }
      } catch (_) {}
    }

    final response = await http.post(
      Uri.parse("https://ai.gateway.lovable.dev/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Lovable-API-Key": _aiKey!
      },
      body: jsonEncode({
        "model": "google/gemini-2.5-flash",
        "messages": [
          {
            "role": "system", 
            "content": "You are SmartMediCare assistant. Answer in 1-3 short sentences. Language: $_currentLanguage\nContext: $contextText"
          },
          {"role": "user", "content": question}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    }
    return "I'm sorry, I encountered an error talking to the assistant.";
  }
}
