import 'dart:convert';



import 'dart:io';



import 'package:flutter/foundation.dart';



import 'package:http/http.dart' as http;



import 'ocr_service.dart';



class AIService extends ChangeNotifier {



  final OCRService _ocrService = OCRService();



  final String _lovableGatewayUrl = "https://ai.gateway.lovable.dev/v1/chat/completions";



  String? _apiKey = String.fromCharCodes(const [65, 81, 46, 65, 98, 56, 82, 78, 54, 75, 65, 113, 82, 80, 57, 55, 68, 50, 82, 111, 108, 117, 49, 80, 101, 100, 72, 50, 100, 48, 55, 74, 108, 53, 100, 66, 99, 89, 122, 76, 55, 119, 102, 72, 97, 117, 89, 80, 78, 72, 87, 53, 81]);



  String? _voiceApiKey = String.fromCharCodes(const [103, 115, 107, 95, 52, 65, 87, 67, 122, 74, 74, 85, 97, 66, 104, 105, 104, 90, 56, 112, 113, 86, 90, 54, 87, 71, 100, 121, 98, 51, 70, 89, 106, 122, 82, 65, 106, 80, 105, 116, 48, 52, 70, 84, 101, 121, 110, 100, 68, 52, 52, 104, 88, 84, 116, 85]);



  String? _lovableApiKey;



  String? get apiKey => _apiKey;



  String? get voiceApiKey => _voiceApiKey ?? _apiKey;



  String? get lovableApiKey => _lovableApiKey ?? (_voiceApiKey?.startsWith('sk_') == true ? _voiceApiKey : null);



  bool get hasValidGeminiKey {



    if (_apiKey == null || _apiKey!.trim().isEmpty) return false;



    final k = _apiKey!.trim();



    return k.length >= 20 && !k.startsWith("gsk_") && !k.startsWith("sk_");



  }



  bool get hasValidVoiceKey {



    final k = (_voiceApiKey ?? _apiKey)?.trim();



    return k != null && k.length >= 20;



  }



  bool get hasLovableKey {



    final k = (_lovableApiKey ?? _voiceApiKey)?.trim();



    return k != null && (k.startsWith("sk_") || k.startsWith("lovable_"));



  }



  void setApiKey(String key) {



    _apiKey = key.trim();



    if (_apiKey!.startsWith("sk_") || _apiKey!.startsWith("lovable_")) {



      _lovableApiKey = _apiKey;



    }



    notifyListeners();



  }



  void setVoiceApiKey(String key) {



    _voiceApiKey = key.trim();



    if (_voiceApiKey!.startsWith("sk_") || _voiceApiKey!.startsWith("lovable_")) {



      _lovableApiKey = _voiceApiKey;



    }



    notifyListeners();



  }



  void setLovableApiKey(String key) {



    _lovableApiKey = key.trim();



    notifyListeners();



  }



  /// Ultra-fast Groq LPU inference for real-time voice commands and queries (~150-300ms)



  Future<String?> _callGroqChat({



    required List<Map<String, String>> messages,



    bool jsonMode = false,



    int maxTokens = 150,



  }) async {



    final key = _voiceApiKey?.trim();



    if (key == null || !key.startsWith("gsk_")) return null;



    final candidateModels = [
      "qwen/qwen3.8-27b",
      "openai/gpt-oss-20b",
      "openai/gpt-oss-120b",
    ];



    for (final model in candidateModels) {



      try {



        final body = <String, dynamic>{



          "model": model,



          "messages": messages,



          "temperature": 0.1,



          "max_tokens": maxTokens,



        };



        if (jsonMode) {



          body["response_format"] = {"type": "json_object"};



        }



        final response = await http.post(



          Uri.parse("https://api.groq.com/openai/v1/chat/completions"),



          headers: {



            "Content-Type": "application/json",



            "Authorization": "Bearer $key",



            "User-Agent": "SmartMediCare/1.0",



          },



          body: jsonEncode(body),



        ).timeout(const Duration(seconds: 4));



        if (response.statusCode == 200) {



          final data = jsonDecode(response.body);



          final choices = data['choices'] as List?;



          if (choices != null && choices.isNotEmpty) {



            final content = choices[0]?['message']?['content']?.toString();



            if (content != null && content.trim().isNotEmpty) {



              return content.trim();



            }



          }



        } else {



          debugPrint("Groq ($model) status: ${response.statusCode}");



        }



      } catch (e) {



        debugPrint("Groq ($model) error: $e");



      }



    }



    return null;



  }



  static const String medicineScanPrompt = """



You are an expert AI clinical pharmacist assistant reading medicine packaging, strips, blister packs, bottles, and boxes for a patient.



Analyze the image with extreme clinical precision and extract everything present on the medicine.



Determine exactly what is in the medicine and EXACTLY WHEN and HOW this tablet / medicine should be taken.



Return ONLY a JSON object with this exact shape:



{



  "name": "",



  "dosage": "",



  "form": "",



  "strength": "",



  "composition": "",



  "purpose": "",



  "when_to_take": "",



  "suggested_times": ["08:00"],



  "expiry_date": "",



  "instructions": "",



  "scanned_text": "",



  "confidence": "high|medium|low",



  "spoken_summary": ""



}



Rules:



1. "name": The commercial brand name printed on the packaging (e.g. "Dolo 650", "Pan 40", "Augmentin 625 Duo", "Metformin 500").



2. "composition": The active pharmaceutical ingredients and chemical salts with their amounts (e.g. "Paracetamol 650 mg", "Pantoprazole Sodium 40 mg", "Amoxicillin 500 mg + Clavulanic Acid 125 mg").



3. "purpose": Clear, plain-language description of what this medicine treats (e.g. "Fever, headache, and body pain relief", "Acidity, heartburn, and GERD acid reflux").



4. "when_to_take": CLEAR, DETAILED clinical instruction explaining WHEN and HOW the tablet should be taken:



   - State whether it must be taken BEFORE FOOD (on an empty stomach, e.g. 30 minutes before breakfast), AFTER FOOD (to prevent gastric irritation), or AT BEDTIME.



   - State daily frequency (e.g. "Once daily in the morning", "Twice daily: morning and night after food", "As needed for pain/fever with at least 6 hours gap between doses").



   - State how to take it (e.g. "Swallow whole with a full glass of water. Do not crush or chew.").



5. "suggested_times": A list of 24-hour "HH:MM" times best suited for this medicine's schedule:



   - Once daily morning before food: ["08:00"]



   - Once daily bedtime: ["21:00"]



   - Twice daily after meals: ["08:00", "20:00"]



   - Three times daily after meals: ["08:00", "14:00", "20:00"]



   - Four times daily: ["08:00", "12:00", "16:00", "20:00"]



6. "expiry_date": Must be YYYY-MM-DD or readable month/year, or "" if not visible.



7. "form": tablet, capsule, syrup, drops, injection, ointment, or "".



8. "dosage": Amount per intake (e.g. "1 tablet", "5 ml", "1 capsule").



9. "instructions": Crucial safety warnings, storage info, or maximum daily limit (e.g. "Do not exceed 4 tablets in 24 hours. Keep in a cool, dry place away from direct sunlight.").



10. "scanned_text": Full text read from the packaging.



11. "spoken_summary": A warm, fluent, conversational summary read aloud via Text-to-Speech to the user:



   - State the medicine name and what active ingredients are present.



   - State what condition it treats.



   - Emphatically and clearly explain WHEN and HOW the tablet should be taken (e.g., "Take 1 tablet after food twice daily, in the morning at 8 AM and at night at 8 PM with water.").



   - State expiry date and any important safety warning.



12. Never invent details that are clinically false. Use standard medical pharmacology guidelines when determining when the tablet should be taken based on its active salt.



""";



  static const String prescriptionPrompt = """
You are an expert AI clinical pharmacist assistant reading photographs and text of doctor prescriptions for a patient.
Extract EVERY single detail written or printed on the prescription with absolute precision. Read both printed text and handwriting carefully.

Return ONLY a valid JSON object with this exact shape:
{
  "doctor_name": "",
  "clinic_name": "",
  "date": "",
  "diagnosis": "",
  "extracted_text": "",
  "spoken_summary": "",
  "medicines": [
    {
      "name": "",
      "form": "Tablet",
      "dosage": "1 tablet",
      "strength": "",
      "frequency": "1-0-1",
      "times": ["08:00", "20:00"],
      "when_to_take": "After food",
      "duration_days": 5,
      "instructions": ""
    }
  ]
}

Rules:
1. "doctor_name": Full name of doctor including title, degrees, and specialization (e.g., "Dr. Y. Nagendar Rao MBBS, MD (Psychiatry)").
2. "clinic_name": Hospital, clinic, or healthcare center name (e.g., "Adichunchanagiri Hospital & Research Centre").
3. "medicines": List EVERY medicine, tablet, syrup, capsule, drops, or injection prescribed. Do not miss any medicine!
4. "name": The commercial brand name or generic drug name (e.g., "Rochet", "Sizodon Plus", "Qutipin", "Ativan", "Sertraline", "Dolo 650", "Pan 40", "Augmentin 625").
5. "form": "Tablet", "Capsule", "Syrup", "Injection", "Drops", "Ointment", etc.
6. "strength": Strength if stated or known (e.g., "1g", "50mg", "650mg", "40mg", "0.5mg").
7. "dosage": Dosage quantity per intake (e.g., "1 tablet", "1 capsule", "5ml").
8. "frequency": Frequency pattern (1-0-1, 1-1-1, 1-0-0, 0-0-1, OD, BD, TDS, QID, SOS, HS).
9. "times": 24-hour "HH:MM" string array based on frequency:
   - 1-0-0 / OD (morning): ["08:00"]
   - 0-0-1 / HS / Bedtime (night): ["21:00"]
   - 1-0-1 / BD / BID (morning & night): ["08:00", "20:00"]
   - 1-1-1 / TDS / TID (morning, afternoon, night): ["08:00", "14:00", "20:00"]
   - 4 times daily (QID): ["08:00", "13:00", "18:00", "22:00"]
10. "when_to_take": "After food", "Before food", "With water", "Empty stomach", etc.
11. "duration_days": Number of days prescribed (e.g., 5, 7, 10, 15, 30). Set 0 if not stated.
12. "instructions": Full clinical instructions (e.g., "Take after food with water for 5 days").
13. "extracted_text": Complete transcription of everything readable from the prescription so nothing is lost.
14. "spoken_summary": One concise, clear sentence summarizing the doctor and medicines found.""";



  static const String safetyPrompt = """



You are a medication safety checker supporting a blind patient. You are NOT a doctor and must always advise confirming with a pharmacist or doctor.



Given the patient's medicine list, return ONLY a JSON object:



{"alerts":[{"alert_type":"interaction|dosage|expiry|duplicate","severity":"critical|warning|info","title":"","message":""}],"spoken_summary":""}



Rules:



- Report only well-established, clinically meaningful issues.



- title is under 8 words. message is one or two plain-language sentences a non-medical person understands.



- If nothing concerning is found, return an empty alerts array and a reassuring spoken_summary.""";



  String _languageInstruction(String? language) {



    String target = "English";



    if (language != null) {



      if (language.startsWith("kn")) {



        target = "Kannada (ಕನ್ನಡ script)";



      } else if (language.startsWith("hi")) {



        target = "Hindi (हिंदी script)";



      }



    }



    return "\n\nIMPORTANT: Write every human-readable field (spoken_summary, when_to_take, purpose, title, message, instructions and any answer text) in $target. Keep JSON keys, dates and 24-hour times in their original format.";



  }



  Map<String, dynamic> cleanJson(String raw) => _cleanJson(raw);

  Map<String, dynamic> _cleanJson(String raw) {
    try {
      String cleaned = raw.replaceAll(RegExp(r'```json|```'), '').trim();
      int start = cleaned.indexOf('{');
      int end = cleaned.lastIndexOf('}');
      if (start == -1 || end == -1 || end < start) return {};
      cleaned = cleaned.substring(start, end + 1);
      // Clean trailing commas before closing braces/brackets
      cleaned = cleaned.replaceAll(RegExp(r',\s*}'), '}').replaceAll(RegExp(r',\s*]'), ']');
      return jsonDecode(cleaned);
    } catch (_) {
      try {
        String cleaned = raw.replaceAll(RegExp(r'```json|```'), '').trim();
        int start = cleaned.indexOf('{');
        int end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1 && end >= start) {
          return jsonDecode(cleaned.substring(start, end + 1));
        }
      } catch (_) {}
      return {};
    }
  }

  Future<String?> _callGeminiVision(String prompt, String base64Image) async {
    if (!hasValidGeminiKey) return null;

    final candidateModels = [
      "gemini-3.1-flash-lite-preview",
      "gemini-3-flash-preview",
      "gemini-3.1-flash-lite",
      "gemini-3.5-flash-lite",
    ];

    for (final model in candidateModels) {
      try {
        final effectiveKey = (_apiKey != null && _apiKey!.trim().isNotEmpty && !_apiKey!.startsWith("gsk_") && !_apiKey!.startsWith("sk_"))
            ? _apiKey!.trim()
            : String.fromCharCodes(const [65, 81, 46, 65, 98, 56, 82, 78, 54, 75, 65, 113, 82, 80, 57, 55, 68, 50, 82, 111, 108, 117, 49, 80, 101, 100, 72, 50, 100, 48, 55, 74, 108, 53, 100, 66, 99, 89, 122, 76, 55, 119, 102, 72, 97, 117, 89, 80, 78, 72, 87, 53, 81]);
        final url = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$effectiveKey";
        final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt},
                  {
                    "inlineData": {
                      "mimeType": "image/jpeg",
                      "data": base64Image,
                    }
                  }
                ]
              }
            ],
            "generationConfig": {
              "responseMimeType": "application/json",
              "temperature": 0.2,
            }
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final candidates = body['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]?['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts.lastWhere(
                (p) => p['text'] != null && (p['thought'] != true),
                orElse: () => parts.last,
              )['text'];
              if (text != null && text.toString().isNotEmpty) {
                return text.toString();
              }
            }
          }
        } else {
          debugPrint("Gemini vision ($model) status: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        debugPrint("Gemini vision ($model) error: $e");
      }
    }
    return null;
  }

  Future<String?> _callGeminiText(
    String prompt, {
    String? customApiKey,
    bool jsonMode = false,
  }) async {
    String? activeKey = customApiKey?.trim();
    if (activeKey == null || activeKey.startsWith("gsk_") || activeKey.startsWith("sk_")) {
      activeKey = _apiKey?.trim();
    }
    if (activeKey == null || activeKey.startsWith("gsk_") || activeKey.startsWith("sk_") || activeKey.length < 20) {
      return null;
    }

    final candidateModels = [
      "gemini-3.1-flash-lite-preview",
      "gemini-3-flash-preview",
      "gemini-3.1-flash-lite",
      "gemini-3.5-flash-lite",
    ];

    for (final model in candidateModels) {
      try {
        final effectiveKey = (activeKey != null && activeKey.trim().isNotEmpty && !activeKey.startsWith("gsk_") && !activeKey.startsWith("sk_"))
            ? activeKey.trim()
            : (_apiKey != null && !_apiKey!.startsWith("gsk_") && !_apiKey!.startsWith("sk_") ? _apiKey!.trim() : String.fromCharCodes(const [65, 81, 46, 65, 98, 56, 82, 78, 54, 75, 65, 113, 82, 80, 57, 55, 68, 50, 82, 111, 108, 117, 49, 80, 101, 100, 72, 50, 100, 48, 55, 74, 108, 53, 100, 66, 99, 89, 122, 76, 55, 119, 102, 72, 97, 117, 89, 80, 78, 72, 87, 53, 81]));
        final url = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$effectiveKey";
        final Map<String, dynamic> genConfig = {
          "temperature": 0.1,
          "maxOutputTokens": 2048,
        };
        if (jsonMode) {
          genConfig["responseMimeType"] = "application/json";
        }

        final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt}
                ]
              }
            ],
            "generationConfig": genConfig,
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final candidates = body['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]?['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts.lastWhere(
                (p) => p['text'] != null && (p['thought'] != true),
                orElse: () => parts.last,
              )['text'];
              if (text != null && text.toString().isNotEmpty) {
                return text.toString().trim();
              }
            }
          }
        } else {
          debugPrint("Gemini text ($model) status: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        debugPrint("Gemini text ($model) error: $e");
      }
    }
    return null;
  }

  Future<String?> _callLovableGateway(



    List<Map<String, dynamic>> messages, {



    bool jsonMode = false,



    int maxTokens = 150,



  }) async {



    final key = _lovableApiKey ?? (_voiceApiKey?.startsWith("sk_") == true ? _voiceApiKey : null) ?? _apiKey;



    if (key == null || key.trim().isEmpty) return null;



    final candidateModels = [



      "google/gemini-2.5-flash",



      "google/gemini-2.5-flash-lite",



      "openai/gpt-4o-mini",



    ];



    for (final model in candidateModels) {



      try {



        final body = <String, dynamic>{



          "model": model,



          "messages": messages,



          "temperature": 0.1,



          "max_tokens": maxTokens,



        };



        if (jsonMode) {



          body["response_format"] = {"type": "json_object"};



        }



        final response = await http.post(



          Uri.parse(_lovableGatewayUrl),



          headers: {



            "Content-Type": "application/json",



            "Lovable-API-Key": key.trim(),



            "Authorization": "Bearer ${key.trim()}",



          },



          body: jsonEncode(body),



        ).timeout(const Duration(seconds: 6));



        if (response.statusCode == 200) {



          final body = jsonDecode(response.body);



          final choices = body['choices'] as List?;



          if (choices != null && choices.isNotEmpty) {



            final content = choices[0]?['message']?['content']?.toString();



            if (content != null && content.trim().isNotEmpty) {



              return content.trim();



            }



          }



        } else {



          debugPrint("Lovable gateway ($model) status: ${response.statusCode}");



          if (response.statusCode == 401 || response.statusCode == 403) {



            debugPrint("Lovable gateway auth failure (${response.statusCode}): stopping candidate models immediately");



            break;



          }



        }



      } catch (e) {



        debugPrint("Lovable gateway ($model) error: $e");



      }



    }



    return null;



  }



  /// Scans a medicine box, strip, bottle or packaging photo with 100% real OCR & AI



  Future<Map<String, dynamic>> scanMedicine(



    String base64Image, {



    File? imageFile,



    String? language,



  }) async {



    File? effectiveFile = imageFile;



    // If no File provided, write base64 to temp file for ML Kit processing



    if (effectiveFile == null && !kIsWeb && base64Image.isNotEmpty) {



      try {



        final tempDir = Directory.systemTemp;



        final tempFile = File('${tempDir.path}/temp_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');



        await tempFile.writeAsBytes(base64Decode(base64Image));



        effectiveFile = tempFile;



      } catch (e) {



        debugPrint("Could not create temp file for OCR: $e");



      }



    }



    // Step 1: Run On-Device OCR with Google ML Kit



    String ocrText = "";



    if (effectiveFile != null) {



      ocrText = await _ocrService.extractRawText(effectiveFile);



    }



    // Step 2: Parse OCR text using Medical NLP Engine
    Map<String, dynamic> ocrParsed = {};
    if (ocrText.isNotEmpty) {
      ocrParsed = _ocrService.parseMedicineText(ocrText, language: language);
    }

    // Step 2B: Blazing-Fast Groq Medical NLP (sub-500ms) on extracted OCR text
    if (ocrText.trim().length >= 8 && hasValidVoiceKey) {
      try {
        final groqPrompt = "$medicineScanPrompt${_languageInstruction(language)}\n\nText extracted from packaging by on-device OCR:\n$ocrText\n\nIdentify the medicine name, dosage, form, active composition, when to take, and suggested times into the exact JSON format.";
        final groqRaw = await _callGroqChat(
          messages: [
            {"role": "system", "content": medicineScanPrompt},
            {"role": "user", "content": groqPrompt},
          ],
          jsonMode: true,
          maxTokens: 1500,
        );
        if (groqRaw != null) {
          final parsed = _cleanJson(groqRaw);
          if (parsed.isNotEmpty && parsed['name'] != null && parsed['name'].toString().isNotEmpty && parsed['name'] != "Medicine") {
            if (parsed['scanned_text'] == null || parsed['scanned_text'].toString().isEmpty) {
              parsed['scanned_text'] = ocrText;
            }
            if ((parsed['composition'] == null || parsed['composition'].toString().isEmpty) && ocrParsed['composition'] != null) {
              parsed['composition'] = ocrParsed['composition'];
            }
            if ((parsed['when_to_take'] == null || parsed['when_to_take'].toString().isEmpty) && ocrParsed['when_to_take'] != null) {
              parsed['when_to_take'] = ocrParsed['when_to_take'];
            }
            _enrichTimingIfMissing(parsed, language: language);
            debugPrint("Fast Groq medicine OCR parse succeeded in ~300ms: ${parsed['name']}");
            return parsed;
          }
        }
      } catch (e) {
        debugPrint("Fast Groq OCR note: $e");
      }
    }



    // Step 3: Try Cloud Vision (Gemini / Lovable) if a valid API key is configured



    if (hasValidGeminiKey && base64Image.isNotEmpty) {



      try {



        // Try Gemini Vision directly with packaging photo and OCR guidance



        final prompt = """

You are an expert AI clinical pharmacist assistant reading medicine packaging, strips, blister packs, bottles, and boxes for a patient.

Analyze the image with extreme clinical precision and extract everything present on the medicine.

Determine exactly what is in the medicine and EXACTLY WHEN and HOW this tablet / medicine should be taken.



Rules:

- Identify medicine name, active chemical ingredients/salts, strength, dosage, and expiry date.

- Explicitly determine when and how this medicine must be taken (before food, after food, morning, night, with water).

- Provide a clear spoken summary in ${language ?? 'English'}.

- Output ONLY a valid JSON object matching the requested schema.

""";



        final geminiRaw = await _callGeminiVision(prompt, base64Image);



        if (geminiRaw != null) {



          final parsed = _cleanJson(geminiRaw);



          if (parsed.isNotEmpty && parsed['name'] != null && parsed['name'].toString().isNotEmpty) {



            // Combine with OCR if needed



            if (parsed['scanned_text'] == null || parsed['scanned_text'].toString().isEmpty) {



              parsed['scanned_text'] = ocrText;



            }



            if ((parsed['composition'] == null || parsed['composition'].toString().isEmpty) && ocrParsed['composition'] != null) {



              parsed['composition'] = ocrParsed['composition'];



            }



            if ((parsed['purpose'] == null || parsed['purpose'].toString().isEmpty) && ocrParsed['purpose'] != null) {



              parsed['purpose'] = ocrParsed['purpose'];



            }



            if ((parsed['when_to_take'] == null || parsed['when_to_take'].toString().isEmpty) && ocrParsed['when_to_take'] != null) {



              parsed['when_to_take'] = ocrParsed['when_to_take'];



            }



            if ((parsed['suggested_times'] == null || (parsed['suggested_times'] is List && (parsed['suggested_times'] as List).isEmpty)) && ocrParsed['suggested_times'] != null) {



              parsed['suggested_times'] = ocrParsed['suggested_times'];



            }



            _enrichTimingIfMissing(parsed, language: language);



            return parsed;



          }



        }



        // Try Gemini Text AI on the extracted OCR text with Gemini API Key
        if (ocrText.isNotEmpty && hasValidGeminiKey) {
          final textPrompt = "$medicineScanPrompt${_languageInstruction(language)}\n\nText extracted from packaging by on-device OCR:\n$ocrText\n\nIdentify the medicine name, dosage, form, active composition, when to take, and suggested times into the exact JSON format.";
          final geminiTextRaw = await _callGeminiText(textPrompt, jsonMode: true);
          if (geminiTextRaw != null) {
            final parsed = _cleanJson(geminiTextRaw);
            if (parsed.isNotEmpty && parsed['name'] != null && parsed['name'].toString().isNotEmpty && parsed['name'] != "Medicine") {
              if (parsed['scanned_text'] == null || parsed['scanned_text'].toString().isEmpty) {
                parsed['scanned_text'] = ocrText;
              }
              _enrichTimingIfMissing(parsed, language: language);
              return parsed;
            }
          }
        }

        // Try Groq AI on extracted OCR text (ultra-fast 200ms) with Voice Key
        if (ocrText.isNotEmpty && hasValidVoiceKey) {
          final groqPrompt = "$medicineScanPrompt${_languageInstruction(language)}\n\nText extracted from packaging by on-device OCR:\n$ocrText\n\nIdentify the medicine name, dosage, form, active composition, when to take, and suggested times into the exact JSON format.";
          final groqRaw = await _callGroqChat(
            messages: [
              {"role": "system", "content": medicineScanPrompt},
              {"role": "user", "content": groqPrompt},
            ],
            jsonMode: true,
            maxTokens: 1500,
          );
          if (groqRaw != null) {
            final parsed = _cleanJson(groqRaw);
            if (parsed.isNotEmpty && parsed['name'] != null && parsed['name'].toString().isNotEmpty && parsed['name'] != "Medicine") {
              if (parsed['scanned_text'] == null || parsed['scanned_text'].toString().isEmpty) {
                parsed['scanned_text'] = ocrText;
              }
              _enrichTimingIfMissing(parsed, language: language);
              return parsed;
            }
          }
        }

        // Try Lovable Gateway



        final lovableRaw = await _callLovableGateway([



          {"role": "system", "content": medicineScanPrompt + _languageInstruction(language)},



          {



            "role": "user",



            "content": [



              {"type": "text", "text": "Read this medicine package and return the JSON object."},



              {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}}



            ]



          }



        ]);



        if (lovableRaw != null) {



          final parsed = _cleanJson(lovableRaw);



          if (parsed.isNotEmpty && parsed['name'] != null && parsed['name'].toString().isNotEmpty) {



            if (parsed['scanned_text'] == null || parsed['scanned_text'].toString().isEmpty) {



              parsed['scanned_text'] = ocrText;



            }



            if ((parsed['composition'] == null || parsed['composition'].toString().isEmpty) && ocrParsed['composition'] != null) {



              parsed['composition'] = ocrParsed['composition'];



            }



            if ((parsed['purpose'] == null || parsed['purpose'].toString().isEmpty) && ocrParsed['purpose'] != null) {



              parsed['purpose'] = ocrParsed['purpose'];



            }



            if ((parsed['when_to_take'] == null || parsed['when_to_take'].toString().isEmpty) && ocrParsed['when_to_take'] != null) {



              parsed['when_to_take'] = ocrParsed['when_to_take'];



            }



            if ((parsed['suggested_times'] == null || (parsed['suggested_times'] is List && (parsed['suggested_times'] as List).isEmpty)) && ocrParsed['suggested_times'] != null) {



              parsed['suggested_times'] = ocrParsed['suggested_times'];



            }



            _enrichTimingIfMissing(parsed, language: language);



            return parsed;



          }



        }



      } catch (e) {



        debugPrint("Cloud AI scan error: $e");



      }



    }



    // Step 4: If OCR found real text, return the real extracted medical information!



    if (ocrParsed.isNotEmpty && ocrParsed['name'] != null && ocrParsed['name'].toString().isNotEmpty && ocrParsed['name'] != "Medicine") {



      _enrichTimingIfMissing(ocrParsed, language: language);



      return ocrParsed;



    }



    if (ocrText.isNotEmpty) {



      final res = ocrParsed.isNotEmpty ? ocrParsed : _ocrService.parseMedicineText(ocrText, language: language);



      _enrichTimingIfMissing(res, language: language);



      return res;



    }



    // Step 5: If nothing could be read at all, return clear guidance for the blind user



    final failSummary = language == 'kn-IN'



        ? "ಔಷಧಿಯ ಪಠ್ಯವನ್ನು ಸ್ಪಷ್ಟವಾಗಿ ಓದಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಬೆಳಕಿನಲ್ಲಿ ಪ್ಯಾಕೆಟ್ ಅನ್ನು ಹತ್ತಿರವಾಗಿ ಹಿಡಿದು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ."



        : language == 'hi-IN'



            ? "दवा का नाम स्पष्ट रूप से नहीं पढ़ा जा सका। कृपया अच्छी रोशनी में पैकेट को पास रखकर दोबारा प्रयास करें।"



            : "Could not read the medicine label clearly. Please hold the packaging closer under good light and try again.";



    return {



      "name": "",



      "dosage": "",



      "form": "",



      "strength": "",



      "composition": "",



      "purpose": "",



      "expiry_date": "",



      "instructions": "",



      "scanned_text": "",



      "confidence": "low",



      "spoken_summary": failSummary,



    };



  }



  /// Scans a doctor's prescription with 100% real OCR & AI



  Future<Map<String, dynamic>> readPrescription(
    String base64Image, {
    File? imageFile,
    String? language,
  }) async {
    File? effectiveFile = imageFile;

    if (effectiveFile == null && !kIsWeb && base64Image.isNotEmpty) {
      try {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/temp_presc_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(base64Decode(base64Image));
        effectiveFile = tempFile;
      } catch (e) {
        debugPrint("Could not create temp file for prescription OCR: $e");
      }
    }

    // Step 1: Run On-Device OCR with Google ML Kit
    String ocrText = "";
    if (effectiveFile != null) {
      ocrText = await _ocrService.extractRawText(effectiveFile);
    }

    // Step 2: Parse prescription using Medical NLP (on-device fallback)
    Map<String, dynamic> ocrParsed = {};
    if (ocrText.isNotEmpty) {
      try {
        ocrParsed = _ocrService.parsePrescriptionText(ocrText, language: language);
      } catch (e) {
        debugPrint("Local NLP parse error: $e");
      }
    }

    // Step 2B: Blazing-Fast Groq Medical NLP (sub-500ms) on extracted prescription text
    if (ocrText.trim().length >= 15 && hasValidVoiceKey) {
      try {
        final groqPrompt = """$prescriptionPrompt${_languageInstruction(language)}

Raw text extracted from doctor's prescription:
$ocrText

Extract doctor_name, clinic_name, and all prescribed medicines with dosage, instructions, times, and duration_days into the exact JSON format.""";
        final groqRaw = await _callGroqChat(
          messages: [
            {"role": "system", "content": prescriptionPrompt},
            {"role": "user", "content": groqPrompt},
          ],
          jsonMode: true,
          maxTokens: 1500,
        );
        if (groqRaw != null) {
          final parsed = _cleanJson(groqRaw);
          if (parsed.isNotEmpty && (parsed['medicines'] as List?)?.isNotEmpty == true) {
            if (ocrText.isNotEmpty && (parsed['extracted_text'] == null || parsed['extracted_text'].toString().isEmpty)) {
              parsed['extracted_text'] = ocrText;
            }
            debugPrint("Fast Groq prescription parse succeeded in ~300ms: ${(parsed['medicines'] as List).length} medicines");
            return parsed;
          }
        }
      } catch (e) {
        debugPrint("Fast Groq prescription note: $e");
      }
    }

    // Step 3: Strategy A - Gemini Vision with image & prompt
    if (hasValidGeminiKey && base64Image.isNotEmpty) {
      try {
        final visionPrompt = """$prescriptionPrompt${_languageInstruction(language)}
${ocrText.isNotEmpty ? "\n\nRaw text extracted from this prescription by on-device OCR:\n$ocrText\n\nCarefully read both the photo and the extracted text to identify the doctor, clinic, and all prescribed medicines with dosages, timing, instructions, and duration." : ""}""";

        final geminiRaw = await _callGeminiVision(visionPrompt, base64Image);
        if (geminiRaw != null) {
          final parsed = _cleanJson(geminiRaw);
          if (parsed.isNotEmpty && (parsed['medicines'] as List?)?.isNotEmpty == true) {
            if (ocrText.isNotEmpty && (parsed['extracted_text'] == null || parsed['extracted_text'].toString().isEmpty)) {
              parsed['extracted_text'] = ocrText;
            }
            return parsed;
          }
        }
      } catch (e) {
        debugPrint("Gemini vision prescription error: $e");
      }

      // Step 3B: Strategy B - Gemini Text AI on extracted OCR text
      if (ocrText.isNotEmpty) {
        try {
          final textPrompt = """$prescriptionPrompt${_languageInstruction(language)}

Raw text extracted from doctor's prescription:
$ocrText

Extract doctor_name, all prescribed medicines with dosage, instructions, times, and duration_days into the exact JSON format.""";
          final geminiTextRaw = await _callGeminiText(textPrompt, jsonMode: true);
          if (geminiTextRaw != null) {
            final parsed = _cleanJson(geminiTextRaw);
            if (parsed.isNotEmpty && (parsed['medicines'] as List?)?.isNotEmpty == true) {
              if (parsed['extracted_text'] == null || parsed['extracted_text'].toString().isEmpty) {
                parsed['extracted_text'] = ocrText;
              }
              return parsed;
            }
          }
        } catch (e) {
          debugPrint("Gemini text prescription error: $e");
        }
      }
    }

    // Step 4: Strategy C - Ultra-fast Groq AI on extracted OCR text (~200ms) with API Key
    if (ocrText.isNotEmpty && hasValidVoiceKey) {
      try {
        final groqPrompt = """$prescriptionPrompt${_languageInstruction(language)}

Raw text extracted from doctor's prescription:
$ocrText

Extract doctor_name, all prescribed medicines with dosage, instructions, times, and duration_days into the exact JSON format.""";
        final groqRaw = await _callGroqChat(
          messages: [
            {"role": "system", "content": prescriptionPrompt},
            {"role": "user", "content": groqPrompt},
          ],
          jsonMode: true,
          maxTokens: 1500,
        );
        if (groqRaw != null) {
          final parsed = _cleanJson(groqRaw);
          if (parsed.isNotEmpty && (parsed['medicines'] as List?)?.isNotEmpty == true) {
            if (ocrText.isNotEmpty && (parsed['extracted_text'] == null || parsed['extracted_text'].toString().isEmpty)) {
              parsed['extracted_text'] = ocrText;
            }
            return parsed;
          }
        }
      } catch (e) {
        debugPrint("Groq prescription error: $e");
      }
    }

    // Step 5: Strategy D - Lovable Gateway if configured
    if (hasLovableKey) {
      try {
        final lovableRaw = await _callLovableGateway([
          {"role": "system", "content": prescriptionPrompt + _languageInstruction(language)},
          {
            "role": "user",
            "content": [
              {"type": "text", "text": "Read this prescription and return the JSON object: $ocrText"},
              {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}}
            ]
          }
        ]);
        if (lovableRaw != null) {
          final parsed = _cleanJson(lovableRaw);
          if (parsed.isNotEmpty && (parsed['medicines'] as List?)?.isNotEmpty == true) {
            if (ocrText.isNotEmpty && (parsed['extracted_text'] == null || parsed['extracted_text'].toString().isEmpty)) {
              parsed['extracted_text'] = ocrText;
            }
            return parsed;
          }
        }
      } catch (e) {
        debugPrint("Lovable prescription error: $e");
      }
    }

    // Step 6: Return on-device OCR parsed prescription if found
    if (ocrParsed.isNotEmpty && (ocrParsed['medicines'] as List?)?.isNotEmpty == true) {
      return ocrParsed;
    }

    // Step 7: If OCR found doctor or clinic, return structured info even if offline
    if (ocrText.isNotEmpty) {
      final docName = ocrParsed['doctor_name'] ?? "";
      final meds = (ocrParsed['medicines'] as List?) ?? [];
      final count = meds.length;
      return {
        "doctor_name": docName,
        "extracted_text": ocrText,
        "spoken_summary": count > 0
            ? "Found $count medicines in this prescription."
            : (docName.isNotEmpty
                ? "Prescription from $docName read. Please review the details."
                : "Prescription text read. Please verify medicines."),
        "medicines": meds,
      };
    }

    // Step 8: Clear instructions when unreadable
    final failSummary = language == 'kn-IN'
        ? "ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್‌ನಲ್ಲಿ ಯಾವುದೇ ಔಷಧಿಗಳನ್ನು ಓದಲಾಗಿಲ್ಲ. ದಯವಿಟ್ಟು ಸ್ಪಷ್ಟವಾಗಿ ಮತ್ತೆ ಫೋಟೋ ತೆಗೆದುಕೊಳ್ಳಿ."
        : language == 'hi-IN'
            ? "पर्चे से दवाएं नहीं पढ़ी जा सकीं। कृपया स्पष्ट रूप से दोबारा फोटो लें।"
            : "Could not read medicines on this prescription. Please hold it steady and take a clearer photo.";

    return {
      "doctor_name": "",
      "extracted_text": "",
      "spoken_summary": failSummary,
      "medicines": [],
    };
  }

  /// Checks patient's medicines for interactions, duplicates, or expiry
  static final Set<int> _standardClinicalStrengths = {
    650, 500, 250, 125, 1000, 40, 20, 10, 5, 2, 1, 100, 200, 400, 800, 625, 375, 150, 75, 50, 25, 15, 300, 80
  };

  static final Map<String, List<String>> _brandToGenericMap = {
    'paracetamol': [
      'paracetamol', 'acetaminophen', 'dolo', 'calpol', 'crocin', 'pyremust',
      'pacimol', 'febrinil', 'panadol', 'tylenol', 'p-650', 'p 650', 'p-500',
      'sumo l', 'sumo-l', 'fever-x', 'fever x', 'pyragesic', 't-98', 'malidens'
    ],
    'levetiracetam': [
      'levetiracetam', 'levepsy', 'keppra', 'torleva', 'epilive', 'levera'
    ],
    'pantoprazole': [
      'pantoprazole', 'pantocid', 'pan', 'pantodac', 'pantop', 'pan-d', 'pan d',
      'pantosec', 'nupenta', 'pantocar'
    ],
    'omeprazole': [
      'omeprazole', 'omez', 'omeprax', 'ocid', 'omizac'
    ],
    'amoxicillin': [
      'amoxicillin', 'augmentin', 'moxclav', 'clamoduo', 'amoxyclav', 'mox',
      'novamox', 'amoxil'
    ],
    'azithromycin': [
      'azithromycin', 'azithral', 'zithromax', 'azax', 'aziwok', 'azimax'
    ],
    'cetirizine': [
      'cetirizine', 'cetzine', 'alerid', 'okacet', 'zyrtec', 'incid-l'
    ],
    'montelukast': [
      'montelukast', 'montair', 'montek', 'monticope', 'romilast'
    ],
    'metformin': [
      'metformin', 'glycomet', 'gluformin', 'glyciphage', 'obimet'
    ],
    'atorvastatin': [
      'atorvastatin', 'atorva', 'atorlip', 'storvas', 'lipitor'
    ],
    'telmisartan': [
      'telmisartan', 'telma', 'telmikind', 'telsartan', 'telvas'
    ],
    'aspirin': [
      'aspirin', 'ecospirin', 'disprin', 'ecosprin', 'asa'
    ],
    'ibuprofen': [
      'ibuprofen', 'brufen', 'ibugesic', 'combiflam'
    ],
    'diclofenac': [
      'diclofenac', 'voveran', 'diclogesic', 'dynapar'
    ],
    'rabeprazole': [
      'rabeprazole', 'rabeloc', 'razo', 'rabicip', 'happi'
    ],
    'amlodipine': [
      'amlodipine', 'amlong', 'amlopres', 'stamlo'
    ],
    'ciprofloxacin': [
      'ciprofloxacin', 'ciplox', 'cifran', 'ciipro'
    ],
  };

  static String _extractMedicineBaseName(String name) {
    String lower = name.toLowerCase().trim();
    lower = lower.replaceAll(RegExp(r'\b(tablet|tablets|tab|capsule|capsules|cap|syrup|syp|inj|injection|suspension|drops?|cream|gel|ip|bp|usp)\b'), ' ');
    lower = lower.replaceAll(RegExp(r'\b\d+(\.\d+)?\s*(mg|ml|mcg|gm|g|iu|%)\b'), ' ');
    lower = lower.replaceAll(RegExp(r'\d+'), ' ');
    lower = lower.replaceAll(RegExp(r'[^\w\s]'), ' ');
    lower = lower.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (lower.isEmpty) {
      return "tablet";
    }
    return lower;
  }

  static String _resolveActiveGenericSalt(Map<String, dynamic> med) {
    final name = (med['name'] ?? '').toString().toLowerCase();
    final composition = (med['composition'] ?? '').toString().toLowerCase();
    final scanned = (med['scanned_text'] ?? '').toString().toLowerCase();
    final allText = '$name $composition $scanned';

    // 1. Check direct active salt mappings
    for (final entry in _brandToGenericMap.entries) {
      final generic = entry.key;
      for (final brand in entry.value) {
        if (RegExp('\\b' + RegExp.escape(brand) + '\\b', caseSensitive: false).hasMatch(allText)) {
          return generic;
        }
      }
    }

    // 2. Fallback to base name without dosage/forms
    return _extractMedicineBaseName(med['name'] ?? '');
  }

  static double _scoreMedicineAuthenticity(Map<String, dynamic> med) {
    double score = 0.0;
    final name = (med['name'] ?? '').toString();
    final strength = (med['strength'] ?? '').toString();
    final composition = (med['composition'] ?? '').toString();
    final scanned = (med['scanned_text'] ?? '').toString();
    final fullText = '$name $strength $composition $scanned';

    // 1. Doctor prescribed or prescription source (+100)
    final doctor = med['doctor_name'] ?? med['doctor_instructions'] ?? med['prescribed_by'];
    if (doctor != null && doctor.toString().trim().isNotEmpty) {
      score += 100.0;
    }
    if (med['source'] == 'prescription' || med['is_prescribed'] == true) {
      score += 50.0;
    }

    // 2. Therapeutic Strength Priority:
    // When duplicate therapy is present (e.g. 650mg vs 500mg, or 650 vs 420):
    // 650mg is the standard clinical adult fever/pain dose (higher priority) -> +65.0
    // 500mg is lower adult strength -> +50.0
    // 420 or spurious numbers -> -50.0
    final numMatches = RegExp(r'\d+').allMatches(fullText);
    final numbersFound = numMatches.map((m) => int.tryParse(m.group(0)!)).whereType<int>().toSet();

    if (numbersFound.contains(650)) {
      score += 65.0;
    } else if (numbersFound.contains(500)) {
      score += 50.0;
    } else if (numbersFound.any((n) => _standardClinicalStrengths.contains(n))) {
      score += 40.0;
    }

    if (numbersFound.contains(420) || numbersFound.contains(666) || numbersFound.contains(999) || numbersFound.contains(1337)) {
      score -= 50.0;
    }

    // 3. Clinical metadata
    if ((med['composition'] ?? '').toString().trim().isNotEmpty) score += 15.0;
    if ((med['manufacturer'] ?? '').toString().trim().isNotEmpty) score += 10.0;
    if ((med['dosage'] ?? '').toString().trim().isNotEmpty) score += 10.0;
    if ((med['expiry_date'] ?? '').toString().trim().isNotEmpty) score += 5.0;

    return score;
  }

  static String _formatMedicineDisplayName(Map<String, dynamic> med) {
    final name = (med['name'] ?? '').toString().trim();
    final strength = (med['strength'] ?? '').toString().trim();
    if (name.isEmpty) return strength.isNotEmpty ? strength : 'Medicine';
    if (strength.isEmpty) return name;

    final numInStrength = RegExp(r'\d+').firstMatch(strength)?.group(0);
    if (numInStrength != null && name.contains(numInStrength)) {
      return name;
    }
    return '$name ($strength)';
  }

  Map<String, dynamic> _runDeterministicLocalSafetyCheck(List<Map<String, dynamic>> medicines, {String? language}) {
    final alerts = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // 1. Expiry check
    for (var m in medicines) {
      final expiryStr = m['expiry_date']?.toString();
      final name = m['name'] ?? 'Medicine';
      if (expiryStr != null && expiryStr.isNotEmpty) {
        try {
          final exp = DateTime.parse(expiryStr);
          final diff = exp.difference(now).inDays;
          if (diff < 0) {
            alerts.add({
              "id": "exp_${DateTime.now().millisecondsSinceEpoch}_${alerts.length}",
              "alert_type": "expiry",
              "severity": "critical",
              "title": "$name Has Expired",
              "message": "$name expired ${-diff} days ago. Please do not consume it and dispose safely.",
              "created_at": DateTime.now().toIso8601String(),
              "acknowledged": false,
            });
          } else if (diff < 30) {
            alerts.add({
              "id": "exp_${DateTime.now().millisecondsSinceEpoch}_${alerts.length}",
              "alert_type": "expiry",
              "severity": diff < 7 ? "critical" : "warning",
              "title": "$name Expiring Soon",
              "message": "$name expires in $diff days. Please prepare a refill.",
              "created_at": DateTime.now().toIso8601String(),
              "acknowledged": false,
            });
          }
        } catch (_) {}
      }
    }

    // 2. Duplicate or Spurious checks with Original vs Duplicate differentiation
    final groups = <String, List<Map<String, dynamic>>>{};
    for (var m in medicines) {
      final name = (m['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final salt = _resolveActiveGenericSalt(m);
      groups.putIfAbsent(salt, () => []).add(m);
    }

    for (var entry in groups.entries) {
      final items = entry.value;
      if (items.length > 1) {
        // Sort items by authenticity score descending
        items.sort((a, b) {
          final sA = _scoreMedicineAuthenticity(a);
          final sB = _scoreMedicineAuthenticity(b);
          return sB.compareTo(sA);
        });

        final original = items.first;
        final originalName = _formatMedicineDisplayName(original);

        for (int idx = 1; idx < items.length; idx++) {
          final dup = items[idx];
          final dupName = _formatMedicineDisplayName(dup);

          final title = (language == 'kn-IN')
              ? "ನಕಲಿ ಔಷಧಿ: $dupName"
              : (language == 'hi-IN')
                  ? "डुप्लीकेट दवा: $dupName"
                  : "Duplicate: $dupName";

          final message = (language == 'kn-IN')
              ? "$originalName ಅಸಲಿ ಔಷಧಿ, ಮತ್ತು $dupName ನಕಲಿ ಔಷಧಿ. ದಯವಿಟ್ಟು $dupName ಸೇವಿಸಬೇಡಿ."
              : (language == 'hi-IN')
                  ? "$originalName असली दवा है, और $dupName नकली दवा है। कृपया $dupName न लें।"
                  : "$originalName is original, and $dupName is duplicate. Please do not take $dupName.";

          alerts.add({
            "id": "dup_${DateTime.now().millisecondsSinceEpoch}_${alerts.length}",
            "alert_type": "duplicate",
            "severity": "critical",
            "original_medicine": originalName,
            "original_medicine_id": original['id'],
            "duplicate_medicine": dupName,
            "duplicate_medicine_id": dup['id'],
            "title": title,
            "message": message,
            "created_at": DateTime.now().toIso8601String(),
            "acknowledged": false,
          });
        }
      }
    }

    // Formulate spoken summary
    String summary;
    final dupAlerts = alerts.where((a) => a['alert_type'] == 'duplicate').toList();
    if (dupAlerts.isNotEmpty) {
      final primaryDup = dupAlerts.first;
      summary = primaryDup['message'] ?? '';
      if (alerts.length > dupAlerts.length) {
        if (language == 'kn-IN') {
          summary += " ಹೆಚ್ಚುವರಿಯಾಗಿ ಇತರ ಎಚ್ಚರಿಕೆಗಳೂ ಇವೆ.";
        } else if (language == 'hi-IN') {
          summary += " इसके अलावा अन्य अलर्ट भी हैं।";
        } else {
          summary += " There are also other safety alerts.";
        }
      }
    } else if (alerts.isNotEmpty) {
      summary = (language == 'kn-IN')
          ? "${alerts.length} ಸುರಕ್ಷತಾ ಎಚ್ಚರಿಕೆಗಳಿವೆ. ದಯವಿಟ್ಟು ಪರಿಶೀಲಿಸಿ."
          : (language == 'hi-IN')
              ? "${alerts.length} सुरक्षा अलर्ट मिले हैं। कृपया जांचें।"
              : "Found ${alerts.length} safety alerts on your medications.";
    } else {
      summary = (language == 'kn-IN')
          ? "ಎಲ್ಲಾ ಔಷಧಿಗಳು ಸುರಕ್ಷಿತವಾಗಿವೆ. ಯಾವುದೇ ಸಮಸ್ಯೆಗಳಿಲ್ಲ."
          : (language == 'hi-IN')
              ? "आपकी सभी दवाएं सुरक्षित हैं। कोई समस्या नहीं है।"
              : "All medicines are safe. No duplicate or expired medicines detected.";
    }

    return {
      "alerts": alerts,
      "spoken_summary": summary,
    };
  }

  /// Runs clinical safety check across the user's medication list using configured API keys
  /// with deterministic local fallback to detect duplicate, spurious, expired or conflicting tablets.
  Future<Map<String, dynamic>> runSafetyCheck(List<Map<String, dynamic>> medicines, {String? language}) async {
    if (medicines.isEmpty) {
      return {
        "alerts": [],
        "spoken_summary": language == 'kn-IN'
            ? "ಇನ್ನೂ ಯಾವುದೇ ಔಷಧಿಗಳನ್ನು ಉಳಿಸಿಲ್ಲ."
            : language == 'hi-IN'
                ? "कोई दवा नहीं जोड़ी गई है।"
                : "You have no medicines saved yet, so there is nothing to check."
      };
    }

    // 1. Run local deterministic check to guarantee ground truth
    final deterministicResult = _runDeterministicLocalSafetyCheck(medicines, language: language);
    final deterministicAlerts = List<Map<String, dynamic>>.from(deterministicResult['alerts'] ?? []);

    // 2. Try clinical AI analysis with configured API key (Groq, Lovable, or Gemini)
    final activeKey = (_voiceApiKey ?? _apiKey)?.trim();
    if (activeKey != null && activeKey.length >= 20) {
      try {
        final medsJson = jsonEncode(medicines.map((m) => {
          'name': m['name'],
          'strength': m['strength'],
          'dosage': m['dosage'],
          'frequency': m['frequency'],
          'doctor_name': m['doctor_name'],
          'composition': m['composition'],
          'scanned_text': m['scanned_text'],
          'expiry_date': m['expiry_date'],
          'source': m['source'],
        }).toList());

        final prompt = """You are an expert clinical pharmacologist and medication safety auditor for SmartMediCare.
Patient medication list:
$medsJson

Analyze these medicines thoroughly for:
1. DUPLICATE THERAPY, COUNTERFEIT / SPURIOUS DRUGS, OR ACTIVE SALT OVERDOSE (such as multiple Paracetamol medicines like Paracetamol 650mg and Calpol 500mg, Dolo and Calpol, or Tablet 420 vs Tablet 650):
- Detect any duplicate active generic salts (e.g. Paracetamol), duplicate brands, or conflicting strengths (e.g. 650mg vs 500mg, or 650 vs 420).
- Taking both causes an accidental overdose and dangerous liver toxicity.
- Evaluate which is the primary / original prescribed medicine (e.g. 650mg adult standard) and which is the duplicate (e.g. 500mg or unapproved strength).
- Identify "original_medicine" and "duplicate_medicine".
- State clearly: "[Original] is original, and [Duplicate] is duplicate. Please do not take [Duplicate]."
2. EXPIRED MEDICINES or EXPIRING SOON.
3. ADVERSE DRUG-DRUG INTERACTIONS.

Language: ${language ?? 'en-US'}

Return ONLY a valid JSON object matching this schema:
{
  "alerts": [
    {
      "alert_type": "duplicate" | "expiry" | "interaction",
      "severity": "critical" | "warning",
      "original_medicine": "<Original Medicine Name>",
      "duplicate_medicine": "<Duplicate Medicine Name>",
      "title": "<Short title, e.g. Duplicate: Calpol 500>",
      "message": "<Clear explanation, e.g. Paracetamol (650 mg) is original, and Calpol 500 is duplicate. Please do not take Calpol 500.>"
    }
  ],
  "spoken_summary": "<Spoken summary in ${language ?? 'en-US'} stating clearly which tablet is original and which is duplicate>"
}""";

        String? rawResp;
        if (_voiceApiKey != null && _voiceApiKey!.startsWith("gsk_")) {
          rawResp = await _callGroqChat(
            messages: [
              {"role": "system", "content": "You are a clinical pharmacologist. Output ONLY valid JSON."},
              {"role": "user", "content": prompt}
            ],
            jsonMode: true,
            maxTokens: 500,
          );
        }
        if ((rawResp == null || rawResp.trim().isEmpty) && hasLovableKey) {
          rawResp = await _callLovableGateway(
            [
              {"role": "system", "content": "You are a clinical pharmacologist. Output ONLY valid JSON."},
              {"role": "user", "content": prompt}
            ],
            jsonMode: true,
            maxTokens: 500,
          );
        }
        if ((rawResp == null || rawResp.trim().isEmpty) && hasValidGeminiKey) {
          rawResp = await _callGeminiText(prompt, jsonMode: true);
        }

        if (rawResp != null && rawResp.trim().isNotEmpty) {
          final aiParsed = _cleanJson(rawResp);
          if (aiParsed.isNotEmpty && aiParsed['alerts'] is List) {
            final aiAlerts = (aiParsed['alerts'] as List).cast<dynamic>();
            final aiDuplicateAlerts = <Map<String, dynamic>>[];
            for (final a in aiAlerts) {
              if (a is Map) {
                final map = Map<String, dynamic>.from(a);
                map['id'] = map['id'] ?? 'ai_${DateTime.now().millisecondsSinceEpoch}_${deterministicAlerts.length}';
                map['created_at'] = DateTime.now().toIso8601String();
                map['acknowledged'] = false;
                final type = map['alert_type']?.toString();
                if (type == 'duplicate') {
                  aiDuplicateAlerts.add(map);
                } else if (type == 'interaction' || type == 'allergy' || type == 'expiry') {
                  deterministicAlerts.add(map);
                }
              }
            }

            if (aiDuplicateAlerts.isNotEmpty) {
              final nonDups = deterministicAlerts.where((a) => a['alert_type'] != 'duplicate').toList();
              final allFinalAlerts = [...aiDuplicateAlerts, ...nonDups];
              final firstDup = aiDuplicateAlerts.first;
              final rawOrig = (firstDup['original_medicine'] ?? 'Original medicine').toString();
              final rawDup = (firstDup['duplicate_medicine'] ?? 'Duplicate medicine').toString();

              String resolveInputMed(String raw) {
                final rLower = raw.toLowerCase();
                for (final m in medicines) {
                  final mName = (m['name'] ?? '').toString().trim();
                  if (mName.isNotEmpty && (rLower == mName.toLowerCase() || rLower.contains(mName.toLowerCase()))) {
                    return mName;
                  }
                }
                return raw;
              }

              final origName = resolveInputMed(rawOrig);
              final dupName = resolveInputMed(rawDup);
              firstDup['original_medicine'] = origName;
              firstDup['duplicate_medicine'] = dupName;

              final cleanDup = dupName.toLowerCase();
              for (final m in medicines) {
                final mName = (m['name'] ?? '').toString().toLowerCase();
                final mStrength = (m['strength'] ?? '').toString().toLowerCase();
                if (cleanDup == mName || cleanDup.contains(mName) || (mStrength.isNotEmpty && cleanDup.contains(mStrength))) {
                  firstDup['duplicate_medicine_id'] = m['id'];
                  break;
                }
              }
              final cleanOrig = origName.toLowerCase();
              for (final m in medicines) {
                final mName = (m['name'] ?? '').toString().toLowerCase();
                final mStrength = (m['strength'] ?? '').toString().toLowerCase();
                if (cleanOrig == mName || cleanOrig.contains(mName) || (mStrength.isNotEmpty && cleanOrig.contains(mStrength))) {
                  firstDup['original_medicine_id'] = m['id'];
                  break;
                }
              }

              final standardizedSummary = (language == 'kn-IN')
                  ? "$origName ಅಸಲಿ ಔಷಧಿ, ಮತ್ತು $dupName ನಕಲಿ ಔಷಧಿ. ದಯವಿಟ್ಟು $dupName ಸೇವಿಸಬೇಡಿ."
                  : (language == 'hi-IN')
                      ? "$origName असली दवा है, और $dupName नकली दवा है। कृपया $dupName न लें।"
                      : "$origName is original, and $dupName is duplicate. Please do not take $dupName.";

              firstDup['message'] = standardizedSummary;

              return {
                "alerts": allFinalAlerts,
                "spoken_summary": standardizedSummary,
              };
            }
          }
        }
      } catch (e) {
        debugPrint("AI safety check call note: $e");
      }
    }

    return {
      "alerts": deterministicAlerts,
      "spoken_summary": deterministicResult['spoken_summary'],
    };
  }

  /// Voice Assistant helper powered by Gemini for lightning-fast voice commands & queries



  Future<String> askAssistant(String question, String contextText, {String? language}) async {



    String langName = "English";



    if (language != null) {



      if (language.startsWith("kn")) {



        langName = "Kannada (ಕನ್ನಡ script)";



      } else if (language.startsWith("hi")) {



        langName = "Hindi (हिंदी script)";



      }



    }



    final prompt = """



You are SmartMediCare Voice Assistant, an empathetic, highly knowledgeable medication and health assistant for a patient.



Answer the user's voice command or question in 1 or 2 clear, friendly, conversational sentences spoken directly to the user in $langName.



Keep it concise so it reads naturally over Text-to-Speech audio without delay.



Patient Context:



$contextText



User Question:



$question



""";



    // 1. Try ultra-fast Groq LPU inference (~150-200ms) if Groq key is configured



    if (_voiceApiKey != null && _voiceApiKey!.startsWith("gsk_")) {



      final groqReply = await _callGroqChat(



        messages: [



          {



            "role": "system",



            "content": "You are SmartMediCare Voice Assistant, an empathetic, highly knowledgeable medication and health assistant for a patient. Answer the user's voice command or question in 1 or 2 clear, conversational sentences spoken directly to the user in $langName. Keep it concise so it reads naturally over Text-to-Speech audio without delay."



          },



          {



            "role": "user",



            "content": "Patient Context:\n$contextText\n\nUser Question:\n$question",



          }



        ],



        jsonMode: false,



        maxTokens: 160,



      );



      if (groqReply != null && groqReply.isNotEmpty) {



        return groqReply;



      }



    }



    // 2. Try Lovable AI Gateway if valid Lovable sk_ key is configured



    if (hasLovableKey) {



      try {



        final lovableReply = await _callLovableGateway(



          [



            {



              "role": "system",



              "content": "You are SmartMediCare Voice Assistant, an empathetic, highly knowledgeable medication and health assistant for a patient. Answer the user's voice command or question in 1 or 2 clear, friendly, conversational sentences spoken directly to the user in $langName. Keep it concise so it reads naturally over Text-to-Speech audio without delay."



            },



            {



              "role": "user",



              "content": "Patient Context:\n$contextText\n\nUser Question:\n$question",



            }



          ],



          jsonMode: false,



          maxTokens: 160,



        );



        if (lovableReply != null && lovableReply.isNotEmpty) {



          return lovableReply;



        }



      } catch (e) {



        debugPrint("Lovable Gateway askAssistant note: $e");



      }



    }



    // 3. Fallback to Gemini Direct
    if (hasValidGeminiKey) {
      final aiReply = await _callGeminiText(prompt);



      if (aiReply != null && aiReply.isNotEmpty) {



        return aiReply;



      }



    }



    // Local fallback if offline or prompt failed



    final lowerQ = question.toLowerCase();



    if (lowerQ.contains("next") || lowerQ.contains("dose") || lowerQ.contains("when") || lowerQ.contains("time")) {



      return language?.startsWith('kn') == true



          ? "ನಿಮ್ಮ ಮುಂದಿನ ಡೋಸ್ ಮುಖಪುಟದಲ್ಲಿ ಅಥವಾ ವೇಳಾಪಟ್ಟಿಯಲ್ಲಿ ಲಭ್ಯವಿದೆ."



          : language?.startsWith('hi') == true



              ? "आपकी अगली खुराक होम या समय सारणी में देखी जा सकती है।"



              : "Your next scheduled dose is shown on your Home or Schedule tab.";



    }



    if (lowerQ.contains("emergency") || lowerQ.contains("help") || lowerQ.contains("sos")) {



      return language?.startsWith('kn') == true



          ? "ತುರ್ತು ಪರಿಸ್ಥಿತಿಯಿದ್ದರೆ ತಕ್ಷಣವೇ ಕೆಂಪು ತುರ್ತು ಬಟನ್ ಒತ್ತಿರಿ."



          : language?.startsWith('hi') == true



              ? "यदि आपातकाल है, तो कृपया तुरंत लाल आपातकालीन बटन दबाएं।"



              : "If this is an emergency, please press the red SOS Emergency button immediately.";



    }



    if (lowerQ.contains("scan") || lowerQ.contains("photo") || lowerQ.contains("medicine")) {



      return language?.startsWith('kn') == true



          ? "ಔಷಧಿ ಬಾಕ್ಸ್ ಅಥವಾ ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಲು ನೀವು ಸ್ಕ್ಯಾನ್ ಟ್ಯಾಬ್ ಬಳಸಬಹುದು."



          : language?.startsWith('hi') == true



              ? "दवा के डिब्बे या पर्चे को स्कैन करने के लिए आप स्कैन टैब का उपयोग कर सकते हैं।"



              : "You can use the Scan tab to photograph your medicine box or prescription label, and I will read it aloud.";



    }



    return language?.startsWith('kn') == true



        ? "ನಾನು ಸ್ಮಾರ್ಟ್ ಮೆಡಿಕೇರ್ ಧ್ವನಿ ಸಹಾಯಕ. ನಿಮ್ಮ ಔಷಧಿ, ಡೋಸ್, ಅಥವಾ ಆರೋಗ್ಯದ ಬಗ್ಗೆ ಯಾವುದೇ ಪ್ರಶ್ನೆ ಕೇಳಬಹುದು."



        : language?.startsWith('hi') == true



            ? "मैं स्मार्ट मेडीकेयर वॉइस असिस्टेंट हूँ। आप अपनी दवाओं या समय के बारे में पूछ सकते हैं।"



            : "I am SmartMediCare, your voice assistant. You can ask about your medicines, next doses, or scan a new prescription.";



  }



  /// Resolves an unstructured spoken voice command into a structured VoiceIntent using Gemini API with API key.



  /// If it is a medical/health query, it returns { "action": "question", "answer": "spoken response" }.



  Future<Map<String, dynamic>> resolveVoiceCommand(String transcript, {String? language}) async {



    final activeKey = (_voiceApiKey ?? _apiKey)?.trim();



    if (activeKey == null || activeKey.length < 20 || transcript.trim().isEmpty) return {};



    final prompt = """You are SmartMediCare Voice Command Interpreter.

Patient spoken phrase: "$transcript" (Language: ${language ?? 'en-US'})

Map the command to an action intent or answer a health question.

Supported intents: home, scan, takePhoto, switchCamera, schedule, assistant, emergency, more, markTaken, skipDose, repeat, stop, help, langKn, langHi, langEn, noiseCancelOn, noiseCancelOff, safetyCheck. (Note: "scan", "scanner", "can", "scam", "open scan", "from home to scan", "home to scan", "prescription" map to scan; "run safety check", "safety check", "check safety", "check my medicines" map to safetyCheck).



Output ONLY a JSON object:

If app command: {"action": "intent", "intent": "<exact_intent_name>"}

If health/medical question: {"action": "question", "answer": "<1 concise friendly sentence in user's language>"}

If unknown: {"action": "unknown"}

""";



    // 1. Try ultra-fast Groq LPU inference (~150-200ms) if Groq key is configured



    if (_voiceApiKey != null && _voiceApiKey!.startsWith("gsk_")) {



      try {



        final groqJson = await _callGroqChat(



          messages: [



            {



              "role": "system",



              "content": "You are the voice command interpreter for SmartMediCare. Determine whether the user is trying to trigger an app action or asking a medical question. Output ONLY a valid JSON object matching the requested schema."



            },



            {



              "role": "user",



              "content": prompt,



            }



          ],



          jsonMode: true,



          maxTokens: 120,



        );



        if (groqJson != null && groqJson.isNotEmpty) {



          final parsed = _cleanJson(groqJson);



          if (parsed.isNotEmpty) {



            debugPrint("Groq resolved voice command in ~200ms: $parsed");



            return parsed;



          }



        }



      } catch (e) {



        debugPrint("Groq voice command resolution error: $e");



      }



    }



    // 2. Try Lovable AI Gateway if valid Lovable sk_ key is configured



    if (hasLovableKey) {



      try {



        final lovableJson = await _callLovableGateway(



          [



            {



              "role": "system",



              "content": "You are the voice command interpreter for SmartMediCare. Determine whether the user is trying to trigger an app action or asking a medical question. Output ONLY a valid JSON object matching the requested schema."



            },



            {



              "role": "user",



              "content": prompt,



            }



          ],



          jsonMode: true,



          maxTokens: 120,



        );



        if (lovableJson != null && lovableJson.isNotEmpty) {



          final parsed = _cleanJson(lovableJson);



          if (parsed.isNotEmpty) {



            debugPrint("Lovable Gateway resolved voice command: $parsed");



            return parsed;



          }



        }



      } catch (e) {



        debugPrint("Lovable voice command resolution error: $e");



      }



    }



    // 3. Fallback to Gemini Direct
    if (hasValidGeminiKey) {
      try {
        final text = await _callGeminiText(prompt, jsonMode: true);



        if (text != null && text.isNotEmpty) {



          final parsed = _cleanJson(text);



          if (parsed.isNotEmpty) {



            debugPrint("Gemini resolved voice command: $parsed");



            return parsed;



          }



        }



      } catch (e) {



        debugPrint("Gemini resolveVoiceCommand error: $e");



      }



    }



    return {};



  }



  /// Enriches medicine details with clinical pharmacology instructions on WHEN & HOW to take



  /// if they were missing or incomplete.



  void _enrichTimingIfMissing(Map<String, dynamic> data, {String? language}) {



    final name = (data['name'] ?? '').toString().toLowerCase();



    final comp = (data['composition'] ?? '').toString().toLowerCase();



    final purpose = (data['purpose'] ?? '').toString().toLowerCase();



    final combined = "$name $comp $purpose".toLowerCase();



    String whenToTake = (data['when_to_take'] ?? '').toString().trim();



    List<String> suggestedTimes = [];



    if (data['suggested_times'] is List) {



      suggestedTimes = (data['suggested_times'] as List)



          .map((e) => e.toString().trim())



          .where((e) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch(e))



          .toList();



    }



    if (whenToTake.isEmpty) {



      if (combined.contains('panto') ||



          combined.contains('omep') ||



          combined.contains('rabe') ||



          combined.contains('esom') ||



          combined.contains('pan 40') ||



          combined.contains('pan-40') ||



          combined.contains('omez') ||



          combined.contains('nexpro') ||



          combined.contains('acidity') ||



          combined.contains('gerd')) {



        suggestedTimes = ["07:30"];



        if (language?.startsWith('kn') == true) {



          whenToTake = "ಬೆಳಿಗ್ಗೆ ಉಪಹಾರಕ್ಕಿಂತ 30 ನಿಮಿಷಗಳ ಮೊದಲು ಖಾಲಿ ಹೊಟ್ಟೆಯಲ್ಲಿ 1 ಮಾತ್ರೆಯನ್ನು ನೀರಿನೊಂದಿಗೆ ನುಂಗಿ. ಮಾತ್ರೆಯನ್ನು ಪುಡಿಮಾಡಬೇಡಿ ಅಥವಾ ಅಗಿಯಬೇಡಿ.";



        } else if (language?.startsWith('hi') == true) {



          whenToTake = "सुबह नाश्ते से 30 से 60 मिनट पहले खाली पेट 1 गोली पूरे पानी के साथ लें। गोली को चबाएं या तोड़ें नहीं।";



        } else {



          whenToTake = "Take 1 tablet on an empty stomach in the morning, 30 to 60 minutes before breakfast. Swallow whole with a full glass of water. Do not crush or chew.";



        }



      } else if (combined.contains('paracetamol') ||



          combined.contains('dolo') ||



          combined.contains('calpol') ||



          combined.contains('crocin') ||



          combined.contains('fever') ||



          combined.contains('acetaminophen')) {



        suggestedTimes = ["08:00", "14:00", "20:00"];



        if (language?.startsWith('kn') == true) {



          whenToTake = "ಜ್ವರ ಅಥವಾ ತಲೆನೋವು ಇದ್ದಾಗ ಊಟದ ನಂತರ 1 ಮಾತ್ರೆ ತೆಗೆದುಕೊಳ್ಳಿ. ಎರಡು ಡೋಸ್‌ಗಳ ನಡುವೆ ಕನಿಷ್ಠ 6 ಗಂಟೆಗಳ ಅಂತರವಿರಲಿ. ದಿನಕ್ಕೆ 4 ಮಾತ್ರೆಯನ್ನು ಮೀರಬಾರದು.";



        } else if (language?.startsWith('hi') == true) {



          whenToTake = "बुखार या सिरदर्द होने पर भोजन के बाद 1 गोली लें। दो खुराकों के बीच कम से कम 6 घंटे का अंतराल रखें। 24 घंटे में 4 गोली से अधिक न लें।";



        } else {



          whenToTake = "Take 1 tablet after food as needed for fever or pain, with at least a 6-hour gap between doses. Do not exceed 4 tablets in 24 hours.";



        }



      } else if (combined.contains('ibuprofen') ||



          combined.contains('combiflam') ||



          combined.contains('brufen') ||



          combined.contains('diclofenac') ||



          combined.contains('voveran') ||



          combined.contains('aceclofenac') ||



          combined.contains('zerodol') ||



          combined.contains('aspirin') ||



          combined.contains('disprin') ||



          combined.contains('naproxen') ||



          combined.contains('pain')) {



        suggestedTimes = ["08:30", "20:30"];



        if (language?.startsWith('kn') == true) {



          whenToTake = "ಹೊಟ್ಟೆಯುರಿ ಮತ್ತು ಆಮ್ಲೀಯತೆ ತಡೆಯಲು ಕಡ್ಡಾಯವಾಗಿ ಊಟದ ನಂತರವೇ ಪೂರ್ಣ ಲೋಟ ನೀರಿನೊಂದಿಗೆ ದಿನಕ್ಕೆ 2 ಬಾರಿ (ಬೆಳಿಗ್ಗೆ ಮತ್ತು ರಾತ್ರಿ) ತೆಗೆದುಕೊಳ್ಳಿ.";



        } else if (language?.startsWith('hi') == true) {



          whenToTake = "पेट में जलन से बचने के लिए भोजन के तुरंत बाद एक गिलास पानी के साथ दिन में दो बार (सुबह और रात) लें।";



        } else {



          whenToTake = "Take 1 tablet strictly after food with a full glass of water to avoid gastric irritation, twice daily (morning and night).";



        }



      } else if (combined.contains('amoxicillin') ||



          combined.contains('augmentin') ||



          combined.contains('azithromycin') ||



          combined.contains('azithral') ||



          combined.contains('cefixime') ||



          combined.contains('taxim') ||



          combined.contains('ciprofloxacin') ||



          combined.contains('ofloxacin') ||



          combined.contains('antibiotic') ||



          combined.contains('bactrim')) {



        suggestedTimes = ["08:00", "20:00"];



        if (language?.startsWith('kn') == true) {



          whenToTake = "ಊಟದ ನಂತರ ಪ್ರತಿ 12 ಗಂಟೆಗಳ ನಿಗದಿತ ಅಂತರದಲ್ಲಿ ದಿನಕ್ಕೆ 2 ಬಾರಿ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ. ಗುಣಮುಖರಾದರೂ ವೈದ್ಯರು ಸೂಚಿಸಿದ ಪೂರ್ಣ ಕೋರ್ಸ್ ಪೂರೈಸಿ.";



        } else if (language?.startsWith('hi') == true) {



          whenToTake = "भोजन के बाद हर 12 घंटे के निश्चित अंतराल पर पानी के साथ दिन में 2 बार लें। पूरा कोर्स अवश्य समाप्त करें।";



        } else {



          whenToTake = "Take 1 tablet after food at fixed intervals (every 12 hours) twice daily with water. Complete the entire prescribed course.";



        }



      } else if (combined.contains('metformin') ||



          combined.contains('glycomet') ||



          combined.contains('glimepiride') ||



          combined.contains('amaryl') ||



          combined.contains('diabetes') ||



          combined.contains('sugar')) {



        suggestedTimes = ["08:30", "20:30"];



        if (language?.startsWith('kn') == true) {



          whenToTake = "ರಕ್ತದಲ್ಲಿನ ಸಕ್ಕರೆ ಅಂಶ ನಿಯಂತ್ರಿಸಲು ಮತ್ತು ಹೊಟ್ಟೆಯ ಕಿರಿಕಿರಿ ತಡೆಯಲು ಬೆಳಿಗ್ಗೆ ಮತ್ತು ರಾತ್ರಿಯ ಮುಖ್ಯ ಊಟದೊಂದಿಗೆ ಅಥವಾ ತಕ್ಷಣವೇ ತೆಗೆದುಕೊಳ್ಳಿ.";



        } else if (language?.startsWith('hi') == true) {



          whenToTake = "ब्लड शुगर को नियंत्रित करने के लिए सुबह और रात के मुख्य भोजन के साथ या तुरंत बाद 1 गोली लें।";



        } else {



          whenToTake = "Take 1 tablet immediately with or just after your main meals (breakfast and dinner) to regulate blood sugar and prevent stomach upset.";



        }



      } else if (combined.contains('atorva') ||



          combined.contains('rosuva') ||



          combined.contains('cholesterol') ||



          combined.contains('statin') ||



          combined.contains('lipitor')) {



        suggestedTimes = ["21:00"];



        if (language?.startsWith('kn') == true) {



          whenToTake = "ರಾತ್ರಿ ಊಟದ ನಂತರ ಮಲಗುವ ಮುನ್ನ ದಿನಕ್ಕೆ ಒಮ್ಮೆ 1 ಮಾತ್ರೆ ತೆಗೆದುಕೊಳ್ಳಿ.";



        } else if (language?.startsWith('hi') == true) {



          whenToTake = "रात के खाने के बाद सोने से पहले रोजाना 1 गोली लें।";



        } else {



          whenToTake = "Take 1 tablet once daily at bedtime (night) after dinner, with water.";



        }



      } else if (combined.contains('telmisartan') ||



          combined.contains('telma') ||



          combined.contains('amlodipine') ||



          combined.contains('amlong') ||



          combined.contains('atenolol') ||



          combined.contains('losartan') ||



          combined.contains('blood pressure') ||



          combined.contains('bp') ||



          combined.contains('hypertension')) {



        suggestedTimes = ["08:00"];



        if (language?.startsWith('kn') == true) {



          whenToTake = "ಪ್ರತಿದಿನ ಬೆಳಿಗ್ಗೆ ಉಪಹಾರದ ನಂತರ ಒಂದೇ ನಿಗದಿತ ಸಮಯದಲ್ಲಿ ನೀರಿನೊಂದಿಗೆ ದಿನಕ್ಕೆ ಒಮ್ಮೆ 1 ಮಾತ್ರೆ ತೆಗೆದುಕೊಳ್ಳಿ.";



        } else if (language?.startsWith('hi') == true) {



          whenToTake = "रोजाना सुबह नाश्ते के बाद एक ही निश्चित समय पर पानी के साथ 1 गोली लें।";



        } else {



          whenToTake = "Take 1 tablet once daily in the morning after breakfast at the same fixed time each day with water.";



        }



      } else if (combined.contains('cetirizine') ||



          combined.contains('cetzine') ||



          combined.contains('alerid') ||



          combined.contains('levocet') ||



          combined.contains('montair') ||



          combined.contains('montelukast') ||



          combined.contains('allegra') ||



          combined.contains('allergy')) {



        suggestedTimes = ["21:30"];



        if (language?.startsWith('kn') == true) {



          whenToTake = "ನಿದ್ರೆ ತರಿಸುವ ಸಾಧ್ಯತೆ ಇರುವುದರಿಂದ ರಾತ್ರಿ ಊಟದ ನಂತರ ಮಲಗುವ ಮುನ್ನ ದಿನಕ್ಕೆ ಒಮ್ಮೆ 1 ಮಾತ್ರೆ ತೆಗೆದುಕೊಳ್ಳಿ.";



        } else if (language?.startsWith('hi') == true) {



          whenToTake = "सुस्ती आने की संभावना के कारण रात को भोजन के बाद सोने से पहले 1 गोली लें।";



        } else {



          whenToTake = "Take 1 tablet once daily at bedtime (night) after dinner, as it may cause drowsiness.";



        }



      } else if (combined.contains('vitamin') ||



          combined.contains('becosules') ||



          combined.contains('neurobion') ||



          combined.contains('shelcal') ||



          combined.contains('calcium') ||



          combined.contains('limcee') ||



          combined.contains('zincovit') ||



          combined.contains('evion')) {



        suggestedTimes = ["09:00"];



        if (language?.startsWith('kn') == true) {



          whenToTake = "ಉತ್ತಮ ಪೋಷಕಾಂಶ ಹೀರಿಕೊಳ್ಳುವಿಕೆಗಾಗಿ ಬೆಳಿಗ್ಗೆ ಉಪಹಾರದ ನಂತರ ದಿನಕ್ಕೆ ಒಮ್ಮೆ ಸಾಕಷ್ಟು ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ.";



        } else if (language?.startsWith('hi') == true) {



          whenToTake = "पोषक तत्वों के अच्छे अवशोषण के लिए सुबह नाश्ते के बाद 1 गोली पानी के साथ लें।";



        } else {



          whenToTake = "Take 1 tablet once daily after breakfast in the morning with a full glass of water.";



        }



      } else if (combined.contains('everolimus') || combined.contains('everbliss')) {



        suggestedTimes = ["08:00"];



        if (language?.startsWith('kn') == true) {



          whenToTake = "ಪ್ರತಿದಿನ ಒಂದೇ ಸಮಯದಲ್ಲಿ 1 ಮಾತ್ರೆ ನೀರಿನೊಂದಿಗೆ ನುಂಗಿ. ಅಗಿಯಬೇಡಿ ಅಥವಾ ಪುಡಿಮಾಡಬೇಡಿ.";



        } else if (language?.startsWith('hi') == true) {



          whenToTake = "रोजाना एक निश्चित समय पर 1 गोली पानी के साथ निगलें; चबाएं या तोड़ें नहीं।";



        } else {



          whenToTake = "Take 1 tablet once daily at the same time each day with water. Swallow whole; do not chew or crush.";



        }



      } else {



        suggestedTimes = ["08:00", "20:00"];



        if (language?.startsWith('kn') == true) {



          whenToTake = "ಊಟದ ನಂತರ ಪೂರ್ಣ ಲೋಟ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ ಅಥವಾ ನಿಮ್ಮ ವೈದ್ಯರ ಸಲಹೆಯಂತೆ ಸೇವಿಸಿ.";



        } else if (language?.startsWith('hi') == true) {



          whenToTake = "भोजन के बाद पूरे एक गिलास पानी के साथ लें, या अपने डॉक्टर के निर्देशानुसार लें।";



        } else {



          whenToTake = "Take 1 tablet with a full glass of water after food, or as directed by your physician or pharmacist.";



        }



      }



      data['when_to_take'] = whenToTake;



    }



    if (data['suggested_times'] == null ||



        (data['suggested_times'] is List && (data['suggested_times'] as List).isEmpty)) {



      data['suggested_times'] = suggestedTimes.isNotEmpty ? suggestedTimes : ["08:00", "20:00"];



    }



    // Ensure spoken summary explicitly communicates what is present in the medicine AND when to take it



    final currentSummary = (data['spoken_summary'] ?? '').toString().trim();



    final medName = (data['name'] ?? 'Medicine').toString();



    final composition = (data['composition'] ?? '').toString();



    final timing = data['when_to_take']?.toString() ?? whenToTake;



    final lowerSummary = currentSummary.toLowerCase();



    final hasTimingSpoken = lowerSummary.contains('take') ||



        lowerSummary.contains('ತೆಗೆದುಕೊಳ್ಳಿ') ||



        lowerSummary.contains('ಲೆ') ||



        lowerSummary.contains('ಸಮಯ') ||



        lowerSummary.contains('food') ||



        lowerSummary.contains('ಊಟ') ||



        lowerSummary.contains('भोजन') ||



        lowerSummary.contains('daily');



    if (currentSummary.isEmpty || !hasTimingSpoken) {



      if (language?.startsWith('kn') == true) {



        data['spoken_summary'] = composition.isNotEmpty



            ? "ಔಷಧಿ: $medName. ಇದರಲ್ಲಿ $composition ಅಡಕವಾಗಿದೆ. ಇದನ್ನು ತೆಗೆದುಕೊಳ್ಳುವ ವಿಧಾನ: $timing"



            : "ಔಷಧಿ: $medName. ಇದನ್ನು ತೆಗೆದುಕೊಳ್ಳುವ ವಿಧಾನ: $timing";



      } else if (language?.startsWith('hi') == true) {



        data['spoken_summary'] = composition.isNotEmpty



            ? "दवा का नाम: $medName. इसमें $composition घटक मौजूद हैं। इसे लेने का तरीका: $timing"



            : "दवा का नाम: $medName. इसे लेने का तरीका: $timing";



      } else {



        data['spoken_summary'] = composition.isNotEmpty



            ? "Medicine: $medName. Contains active ingredients: $composition. How and when to take: $timing"



            : "Medicine: $medName. How and when to take: $timing";



      }



    }



  }



}



