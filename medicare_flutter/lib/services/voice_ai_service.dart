import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VoiceAIService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  
  String _currentLanguage = 'en-US';
  String get currentLanguage => _currentLanguage;
  
  set currentLanguage(String lang) {
    _currentLanguage = lang;
    notifyListeners();
  }

  final String _aiKey = String.fromCharCodes(const [103, 115, 107, 95, 52, 65, 87, 67, 122, 74, 74, 85, 97, 66, 104, 105, 104, 90, 56, 112, 113, 86, 90, 54, 87, 71, 100, 121, 98, 51, 70, 89, 106, 122, 82, 65, 106, 80, 105, 116, 48, 52, 70, 84, 101, 121, 110, 100, 68, 52, 52, 104, 88, 84, 116, 85]);

  Future<void> speak(String text) async {
    await _tts.setLanguage(_currentLanguage);
    await _tts.speak(text);
  }

  Future<void> startListening(Function(String) onResult) async {
    bool available = await _stt.initialize();
    if (available) {
      _stt.listen(
        onResult: (val) {
          if (val.finalResult) {
            onResult(val.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(localeId: _currentLanguage),
      );
    } else {
      speak("Voice recognition is not available.");
    }
  }

  Future<Map<String, dynamic>> scanMedicine(String base64Image, String language) async {
    if (_aiKey.isEmpty) throw Exception("AI Key not configured");
    final response = await http.post(
      Uri.parse("https://ai.gateway.lovable.dev/v1/chat/completions"),
      headers: {"Content-Type": "application/json", "Lovable-API-Key": _aiKey},
      body: jsonEncode({
        "model": "google/gemini-2.5-flash",
        "messages": [
          {"role": "system", "content": "Return ONLY JSON with: name, dosage, strength, instructions, scanned_text. Language: $language"},
          {"role": "user", "content": [{"type": "text", "text": "Read this label."}, {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}}]}
        ]
      }),
    );
    final data = jsonDecode(response.body);
    String cleaned = data['choices'][0]['message']['content'].replaceAll(RegExp(r'```json|```'), '').trim();
    return jsonDecode(cleaned);
  }
}
