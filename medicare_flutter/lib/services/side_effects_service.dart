
class MedicineWarningItem {
  final String medicineId;
  final String name;
  final String strength;
  final String form;
  final String genericSalt;
  final List<String> sideEffects;
  final List<String> warnings;
  final List<String> precautions;
  final String severity; // 'critical' | 'warning'
  final String? packagingWarning;

  MedicineWarningItem({
    required this.medicineId,
    required this.name,
    required this.strength,
    required this.form,
    required this.genericSalt,
    required this.sideEffects,
    required this.warnings,
    required this.precautions,
    required this.severity,
    this.packagingWarning,
  });
}

class SideEffectsService {
  static const Map<String, List<String>> _brandAliases = {
    'paracetamol': [
      'paracetamol', 'acetaminophen', 'dolo', 'calpol', 'crocin', 'pyremust',
      'pacimol', 'febrinil', 'panadol', 'tylenol', 'p-650', 'p 650', 'p-500',
      'sumo l', 'sumo-l', 'fever-x', 'pyragesic', 't-98', 'malidens'
    ],
    'nsaid': [
      'ibuprofen', 'diclofenac', 'aceclofenac', 'aspirin', 'naproxen', 'mefenamic',
      'combiflam', 'voveran', 'zerodol', 'brufen', 'hifenac', 'disprin'
    ],
    'antibiotic': [
      'amoxicillin', 'augmentin', 'azithromycin', 'ciprofloxacin', 'cefixime',
      'moxclav', 'novamox', 'azithral', 'zithromax', 'ciro', 'taxim-o'
    ],
    'antihistamine': [
      'cetirizine', 'levocetirizine', 'cetzine', 'alerid', 'okacet', 'zyrtec',
      'montelukast', 'montair', 'montek', 'allegra', 'fexofenadine'
    ],
    'diabetes': [
      'metformin', 'glycomet', 'gluformin', 'glimepiride', 'gliclazide', 'insulin',
      'januvia', 'galvus', 'dapagliflozin'
    ],
    'bp': [
      'amlodipine', 'telmisartan', 'losartan', 'atenolol', 'metoprolol', 'enalapril',
      'stamlo', 'telma', 'cilacar', 'betaloc'
    ],
    'antacid': [
      'pantoprazole', 'pantocid', 'pan', 'pan-d', 'omeprazole', 'omez', 'rabeprazole',
      'rabeprazole', 'rabekind', 'esomeprazole', 'nexpro'
    ],
  };

  static String resolveGenericSalt(Map<String, dynamic> med) {
    final name = (med['name'] ?? '').toString().toLowerCase();
    final comp = (med['composition'] ?? '').toString().toLowerCase();
    final scanned = (med['scanned_text'] ?? '').toString().toLowerCase();
    final all = '$name $comp $scanned';

    for (final entry in _brandAliases.entries) {
      for (final brand in entry.value) {
        if (all.contains(brand)) {
          return entry.key;
        }
      }
    }
    return '';
  }

  /// Extracts packaging warnings from scanned_text or instructions
  static String? extractPackagingWarning(Map<String, dynamic> med) {
    final scanned = (med['scanned_text'] ?? '').toString();
    final inst = (med['instructions'] ?? '').toString();
    final text = '$scanned\n$inst';

    final regExp = RegExp(
      r'(?:warning|caution|overdose|adverse|alert)[:\s]+([^.\n\r]+(?:\.[^.\n\r]+){0,2})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(text);
    if (match != null) {
      final raw = match.group(0)?.trim();
      if (raw != null && raw.length > 10) {
        return raw;
      }
    }

    if (text.toLowerCase().contains("liver damage") ||
        text.toLowerCase().contains("allergic reaction") ||
        text.toLowerCase().contains("do not exceed")) {
      final lines = text.split(RegExp(r'[\r\n]+'));
      for (final line in lines) {
        final l = line.trim();
        if (l.toLowerCase().contains("liver") ||
            l.toLowerCase().contains("damage") ||
            l.toLowerCase().contains("allergic") ||
            l.toLowerCase().contains("exceed")) {
          return l;
        }
      }
    }
    return null;
  }

  /// Evaluates all medicines in the user's list for side effects and warnings
  static List<MedicineWarningItem> evaluateMedicines(
    List<Map<String, dynamic>> medicines, {
    String? language,
  }) {
    final lang = language ?? 'en-US';
    final isKn = lang.startsWith('kn');
    final isHi = lang.startsWith('hi');

    final items = <MedicineWarningItem>[];

    for (final m in medicines) {
      final id = (m['id'] ?? '').toString();
      final name = (m['name'] ?? 'Medicine').toString().trim();
      if (name.isEmpty) continue;

      final strength = (m['strength'] ?? '').toString().trim();
      final form = (m['form'] ?? 'Tablet').toString().trim();
      final salt = resolveGenericSalt(m);
      final packWarn = extractPackagingWarning(m);

      List<String> sideEffects = [];
      List<String> warnings = [];
      List<String> precautions = [];
      String severity = 'warning';

      if (salt == 'paracetamol') {
        severity = 'critical'; // Due to liver injury risk on overdose
        if (isKn) {
          sideEffects = [
            "ಅತಿಯಾದ ಸೇವನೆ ಅಥವಾ ಇತರ ಪ್ಯಾರಾಸಿಟಮಾಲ್ ಜೊತೆ ಸೇವಿಸಿದರೆ ತೀವ್ರ ಯಕೃತ್ತು (ಲಿವರ್) ಹಾನಿ.",
            "ಅಲರ್ಜಿ ಲಕ್ಷಣಗಳು: ಮುಖ, ತುಟಿ, ಬಾಯಿ ಮತ್ತು ಗಂಟಲು ಊತ, ಉಸಿರಾಟದ ತೊಂದರೆ ಮತ್ತು ತುರಿಕೆ.",
            "ವಾಕರಿಕೆ, ವಾಂತಿ ಮತ್ತು ಹೊಟ್ಟೆ ನೋವು.",
          ];
          warnings = [
            "ದಿನಕ್ಕೆ ಗರಿಷ್ಠ ೪೦೦೦ ಮಿಗ್ರಾಂ ಗಿಂತ ಹೆಚ್ಚು ಸೇವಿಸಬಾರದು.",
            "ಇತರ ಪ್ಯಾರಾಸಿಟಮಾಲ್ ಮಾತ್ರೆಗಳೊಂದಿಗೆ ಒಟ್ಟಿಗೆ ಸೇವಿಸಬೇಡಿ.",
            "ಈ ಔಷಧಿ ತೆಗೆದುಕೊಳ್ಳುವಾಗ ಮದ್ಯಪಾನ ಮಾಡಬೇಡಿ.",
          ];
          precautions = [
            "ಎರಡು ಡೋಸ್‌ಗಳ ನಡುವೆ ಕನಿಷ್ಠ ೪ ರಿಂದ ೬ ಗಂಟೆಗಳ ಅಂತರವಿರಲಿ.",
            "೩೦°C ಗಿಂತ ಕಡಿಮೆ ತಾಪಮಾನದಲ್ಲಿ, ತೇವಾಂಶದಿಂದ ದೂರವಿಡಿ.",
          ];
        } else if (isHi) {
          sideEffects = [
            "अधिक मात्रा या ओवरडोज़ से गंभीर लिवर क्षति (लीवर डैमेज) का खतरा।",
            "एलर्जी रिएक्शन: चेहरे, मुंह, होंठ और गले में सूजन, सांस लेने में तकलीफ व खुजली।",
            "जी मिचलाना, उल्टी और पेट के ऊपरी हिस्से में दर्द।",
          ];
          warnings = [
            "२४ घंटे में ४००० मिलीग्राम से अधिक मात्रा कभी न लें।",
            "अन्य पैरासिटामोल युक्त दवाओं के साथ मिलाकर न लें।",
            "इस दवा के सेवन के दौरान शराब का सेवन बिल्कुल न करें।",
          ];
          precautions = [
            "प्रत्येक खुराक के बीच कम से कम ४ से ६ घंटे का अंतर रखें।",
            "३० डिग्री से कम तापमान पर नमी व धूप से बचाकर रखें।",
          ];
        } else {
          sideEffects = [
            "Severe liver damage (hepatotoxicity) in case of overdose or prolonged use.",
            "Allergic reactions: swelling of face, mouth, lips, tongue, throat, breathing difficulty, and itchy rash.",
            "Nausea, vomiting, and epigastric abdominal pain.",
          ];
          warnings = [
            "Do not exceed maximum safe limit of 4000 mg in 24 hours.",
            "Do not combine with other Paracetamol containing medicines to avoid liver toxicity.",
            "Avoid alcohol consumption while taking this medication.",
          ];
          precautions = [
            "Maintain a minimum 4 to 6 hour interval between doses.",
            "Store below 30°C. Protect from direct light and moisture.",
          ];
        }
      } else if (salt == 'nsaid') {
        severity = 'critical';
        if (isKn) {
          sideEffects = [
            "ಹೊಟ್ಟೆಯ ಹುಣ್ಣು (ಅಲ್ಸರ್) ಮತ್ತು ಜಠರದ ರಕ್ತಸ್ರಾವದ ಅಪಾಯ.",
            "ತೀವ್ರ ಆಮ್ಲೀಯತೆ (ಅಸಿಡಿಟಿ) ಮತ್ತು ಎದೆಯುರಿ.",
            "ಮೂತ್ರಪಿಂಡದ (ಕಿಡ್ನಿ) ಮೇಲೆ ಒತ್ತಡ ಮತ್ತು ಊತ.",
          ];
          warnings = [
            "ಖಾಲಿ ಹೊಟ್ಟೆಯಲ್ಲಿ ಎಂದಿಗೂ ತೆಗೆದುಕೊಳ್ಳಬೇಡಿ; ಯಾವಾಗಲೂ ಊಟದ ನಂತರ ಮಾತ್ರ ಸೇವಿಸಿ.",
            "ಅಲ್ಸರ್ ಅಥವಾ ಕಿಡ್ನಿ ಸಮಸ್ಯೆ ಇದ್ದರೆ ವೈದ್ಯರ ಸಲಹೆ ಪಡೆಯಿರಿ.",
          ];
          precautions = ["ಸಾಕಷ್ಟು ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ."];
        } else if (isHi) {
          sideEffects = [
            "पेट में अल्सर और आंतरिक रक्तस्राव का जोखिम।",
            "गंभीर एसिडिटी, सीने में जलन और पेट दर्द।",
            "किडनी पर दबाव और पैरों में सूजन।",
          ];
          warnings = [
            "खाली पेट कभी न लें; हमेशा भोजन या दूध के बाद ही लें।",
            "अल्सर या गुर्दे की बीमारी में सावधानी बरतें।",
          ];
          precautions = ["भरपूर पानी के साथ गोली निगलें।"];
        } else {
          sideEffects = [
            "Stomach ulcers and risk of gastrointestinal bleeding.",
            "Severe acid reflux, heartburn, and stomach upset.",
            "Kidney strain and fluid retention.",
          ];
          warnings = [
            "Always take AFTER meals or with milk; never on an empty stomach.",
            "Avoid combining multiple painkiller NSAIDs simultaneously.",
          ];
          precautions = ["Take with a full glass of water."];
        }
      } else if (salt == 'antibiotic') {
        severity = 'warning';
        if (isKn) {
          sideEffects = [
            "ಅತಿಸಾರ (ಬೇಧಿ) ಮತ್ತು ಹೊಟ್ಟೆಯ ಸೆಳೆತ.",
            "ವಾಕರಿಕೆ ಮತ್ತು ಬಾಯಿಯ ರುಚಿ ಬದಲಾವಣೆ.",
            "ಚರ್ಮದ ಅಲರ್ಜಿ ಮತ್ತು ದದ್ದು.",
          ];
          warnings = [
            "ವೈದ್ಯರು ಸೂಚಿಸಿದ ಪೂರ್ಣ ಕೋರ್ಸ್ ಪೂರ್ಣಗೊಳಿಸಿ, ನಡುವೆ ನಿಲ್ಲಿಸಬೇಡಿ.",
            "ಉಸಿರಾಟದಲ್ಲಿ ತೊಂದರೆ ಅಥವಾ ಚರ್ಮದ ದದ್ದು ಕಂಡುಬಂದರೆ ತಕ್ಷಣ ನಿಲ್ಲಿಸಿ.",
          ];
          precautions = ["ಪ್ರತಿದಿನ ನಿಯಮಿತ ಸಮಯದಲ್ಲಿ ಸೇವಿಸಿ."];
        } else if (isHi) {
          sideEffects = [
            "दस्त (डायरिया) और पेट में मरोड़।",
            "जी मिचलाना और स्वाद बदलना।",
            "त्वचा पर लाल चकत्ते और खुजली।",
          ];
          warnings = [
            "डॉक्टर द्वारा निर्धारित पूरा एंटीबायोटिक कोर्स अवश्य पूरा करें।",
            "एलर्जी या दाने दिखने पर तुरंत डॉक्टर को बताएं।",
          ];
          precautions = ["हर दिन तय समय पर ही दवा लें।"];
        } else {
          sideEffects = [
            "Diarrhea, loose motions, and abdominal cramps.",
            "Nausea and altered taste.",
            "Mild skin rash or allergic reactions.",
          ];
          warnings = [
            "Complete the entire prescribed antibiotic course to prevent bacterial resistance.",
            "Report severe diarrhea or persistent rash immediately.",
          ];
          precautions = ["Take doses at evenly spaced intervals."];
        }
      } else if (salt == 'antihistamine') {
        severity = 'warning';
        if (isKn) {
          sideEffects = [
            "ತೂಕಡಿಕೆ, ಅತಿಯಾದ ನಿದ್ರಾವಸ್ಥೆ ಮತ್ತು ಆಲಸ್ಯ.",
            "ಬಾಯಿ ಒಣಗುವುದು ಮತ್ತು ತಲೆತಿರುಗುವಿಕೆ.",
          ];
          warnings = [
            "ವಾಹನ ಚಲಾಯಿಸುವಾಗ ಅಥವಾ ಯಂತ್ರಗಳನ್ನು ಬಳಸುವಾಗ ತೆಗೆದುಕೊಳ್ಳಬೇಡಿ.",
            "ಮದ್ಯಪಾನದೊಂದಿಗೆ ಸೇವಿಸಬೇಡಿ.",
          ];
          precautions = ["ರಾತ್ರಿ ಮಲಗುವ ಮುನ್ನ ತೆಗೆದುಕೊಳ್ಳುವುದು ಉತ್ತಮ."];
        } else if (isHi) {
          sideEffects = [
            "सुस्ती, उनींदापन और थकान।",
            "मुंह सूखना और हल्का सिरदर्द।",
          ];
          warnings = [
            "गाड़ी चलाते समय या भारी मशीनरी का काम करते समय न लें।",
            "शराब के साथ दवा का सेवन न करें।",
          ];
          precautions = ["सोने से पहले लेना अधिक सुरक्षित है।"];
        } else {
          sideEffects = [
            "Drowsiness, daytime sedation, and reduced alertness.",
            "Dry mouth, mild dizziness, and fatigue.",
          ];
          warnings = [
            "Do not drive or operate machinery while taking this medication.",
            "Avoid alcohol, which increases sedative effects.",
          ];
          precautions = ["Best taken at bedtime."];
        }
      } else if (salt == 'diabetes') {
        severity = 'warning';
        if (isKn) {
          sideEffects = [
            "ರಕ್ತದ ಸಕ್ಕರೆ ಕಡಿಮೆಯಾಗುವುದು (ಹೈಪೊಗ್ಲಿಸಿಮಿಯಾ): ನಡುಕ, ಬೆವರುವುದು, ತಲೆತಿರುಗುವಿಕೆ.",
            "ಹೊಟ್ಟೆ ಉಬ್ಬರ, ವಾಕರಿಕೆ ಮತ್ತು ಅತಿಸಾರ.",
          ];
          warnings = [
            "ಯಾವಾಗಲೂ ಆಹಾರದೊಂದಿಗೆ ಸೇವಿಸಿ.",
            "ತಲೆತಿರುಗಿದರೆ ತಕ್ಷಣ ಗ್ಲೂಕೋಸ್ ಅಥವಾ ಸಿಹಿತಿಂಡಿ ಸೇವಿಸಿ.",
          ];
          precautions = ["ನಿಯಮಿತವಾಗಿ ರಕ್ತದ ಸಕ್ಕರೆ ಮಟ್ಟವನ್ನು ಪರೀಕ್ಷಿಸಿ."];
        } else if (isHi) {
          sideEffects = [
            "लो ब्लड शुगर (हाइपोग्लाइसीमिया): पसीना आना, कंपकंपी, चक्कर आना।",
            "पेट में गैस, जी मिचलाना और दस्त।",
          ];
          warnings = [
            "हमेशा भोजन के साथ ही दवा लें।",
            "चक्कर आने पर पास में मीठा या ग्लूकोज रखें।",
          ];
          precautions = ["नियमित रूप से ब्लड शुगर की जांच करें।"];
        } else {
          sideEffects = [
            "Hypoglycemia (low blood sugar): shaking, sweating, dizziness, confusion.",
            "Nausea, diarrhea, and stomach upset.",
          ];
          warnings = [
            "Take with meals to minimize stomach upset.",
            "Carry fast-acting sugar (sweets or fruit juice) in case of sudden dizziness.",
          ];
          precautions = ["Monitor blood sugar levels regularly."];
        }
      } else if (salt == 'bp') {
        severity = 'warning';
        if (isKn) {
          sideEffects = [
            "ಎದ್ದು ನಿಂತಾಗ ತಲೆತಿರುಗುವಿಕೆ (ರಕ್ತದೊತ್ತಡ ಇಳಿಯುವುದು).",
            "ಪಾದ ಅಥವಾ ಹಿಮ್ಮಡಿ ಊತ (ಎಡಿಮಾ).",
          ];
          warnings = [
            "ಔಷಧಿಯನ್ನು ಇದ್ದಕ್ಕಿದ್ದಂತೆ ನಿಲ್ಲಿಸಬೇಡಿ.",
            "ಕುಳಿತಲ್ಲಿಂದ ನಿಧಾನವಾಗಿ ಎದ್ದು ನಿಲ್ಲಿರಿ.",
          ];
          precautions = ["ಪ್ರತಿದಿನ ಒಂದೇ ಸಮಯದಲ್ಲಿ ತೆಗೆದುಕೊಳ್ಳಿ."];
        } else if (isHi) {
          sideEffects = [
            "खड़े होने पर अचानक चक्कर आना (रक्तचाप में गिरावट)।",
            "पैरों या टखनों में सूजन।",
          ];
          warnings = [
            "दवा को अचानक बंद न करें, इससे बीपी तेजी से बढ़ सकता है।",
            "बैठने या लेटने से धीरे-धीरे खड़े हों।",
          ];
          precautions = ["प्रतिदिन एक ही समय पर लें।"];
        } else {
          sideEffects = [
            "Dizziness upon standing up (postural hypotension).",
            "Ankle swelling, edema, and mild headache.",
          ];
          warnings = [
            "Do not stop abruptly without medical supervision.",
            "Rise slowly from sitting or lying down positions.",
          ];
          precautions = ["Take consistently at the same time each day."];
        }
      } else if (salt == 'antacid') {
        severity = 'warning';
        if (isKn) {
          sideEffects = [
            "ತಲೆನೋವು, ಮಲಬದ್ಧತೆ ಅಥವಾ ಭೇದಿ.",
            "ದೀರ್ಘಕಾಲ ಬಳಸಿದರೆ ಬಿ೧೨ ಮತ್ತು ಕ್ಯಾಲ್ಸಿಯಂ ಕೊರತೆ.",
          ];
          warnings = [
            "ಬೆಳಗಿನ ಉಪಹಾರಕ್ಕೆ ೩೦ ನಿಮಿಷ ಮೊದಲು ಖಾಲಿ ಹೊಟ್ಟೆಯಲ್ಲಿ ಸೇವಿಸಿ.",
            "ಮಾತ್ರೆಯನ್ನು ಪುಡಿಮಾಡದೆ ಅಥವಾ ಅಗಿಯದೆ ನುಂಗಿ.",
          ];
          precautions = ["ನೀರಿನೊಂದಿಗೆ ಪೂರ್ಣ ಮಾತ್ರೆಯನ್ನು ನುಂಗಿ."];
        } else if (isHi) {
          sideEffects = [
            "सिरदर्द, कब्ज या हल्का दस्त।",
            "लंबे समय तक लेने पर विटामिन बी12 की कमी।",
          ];
          warnings = [
            "सुबह नाश्ते से ३० मिनट पहले खाली पेट लें।",
            "गोली को चबाएं या तोड़ें नहीं, पूरी निगलें।",
          ];
          precautions = ["पर्याप्त पानी के साथ लें।"];
        } else {
          sideEffects = [
            "Headache, mild diarrhea or constipation.",
            "Prolonged usage may reduce vitamin B12 absorption.",
          ];
          warnings = [
            "Take 30 minutes before breakfast on an empty stomach.",
            "Do not chew or crush delayed-release tablets.",
          ];
          precautions = ["Swallow whole with a glass of water."];
        }
      } else {
        // Fallback or packaging-detected warnings
        final inst = (m['instructions'] ?? '').toString();
        if (inst.isNotEmpty || packWarn != null) {
          severity = 'warning';
          sideEffects = [
            isKn
                ? "ಸೂಚಿಸಿದ ಪ್ರಮಾಣಕ್ಕಿಂತ ಹೆಚ್ಚು ಸೇವಿಸಿದರೆ ಪ್ರತಿಕೂಲ ಅಡ್ಡಪರಿಣಾಮಗಳಾಗಬಹುದು."
                : (isHi ? "अधिक मात्रा लेने पर प्रतिकूल प्रभाव हो सकते हैं।" : "Potential adverse effects if dose instructions are not followed.")
          ];
          warnings = [
            if (packWarn != null) packWarn else inst,
          ];
          precautions = [
            isKn
                ? "ವೈದ್ಯರು ಸೂಚಿಸಿದ ಪ್ರಮಾಣದಲ್ಲಿ ಮಾತ್ರ ಸೇವಿಸಿ."
                : (isHi ? "डॉक्टर द्वारा बताए गए अनुसार ही सेवन करें।" : "Take strictly as prescribed by your physician.")
          ];
        }
      }

      // If we have any side effects, warnings, or packaging warning, add to list!
      if (sideEffects.isNotEmpty || warnings.isNotEmpty || packWarn != null) {
        items.add(MedicineWarningItem(
          medicineId: id,
          name: name,
          strength: strength,
          form: form,
          genericSalt: salt,
          sideEffects: sideEffects,
          warnings: warnings,
          precautions: precautions,
          severity: severity,
          packagingWarning: packWarn,
        ));
      }
    }

    return items;
  }

  /// Builds a spoken summary of side effects and warnings for voice output
  static String buildSpokenSummary(List<MedicineWarningItem> items, {String? language}) {
    final lang = language ?? 'en-US';
    final isKn = lang.startsWith('kn');
    final isHi = lang.startsWith('hi');

    if (items.isEmpty) {
      if (isKn) {
        return "ಯಾವುದೇ ಔಷಧಿಗಳಿಗೆ ಗಂಭೀರ ಅಡ್ಡಪರಿಣಾಮಗಳು ಅಥವಾ ಎಚ್ಚರಿಕೆಗಳು ಕಂಡುಬಂದಿಲ್ಲ. ನಿಮ್ಮ ಔಷಧಿಗಳು ಸುರಕ್ಷಿತವಾಗಿವೆ.";
      } else if (isHi) {
        return "किसी भी दवा के लिए कोई गंभीर साइड इफेक्ट या चेतावनी नहीं मिली। आपकी दवाएं सुरक्षित हैं।";
      } else {
        return "No severe side effects or warning alerts found for your medicines. Everything looks safe.";
      }
    }

    final first = items.first;
    final medName = first.strength.isNotEmpty ? "${first.name} ${first.strength}" : first.name;

    if (isKn) {
      String text = "$medName ಔಷಧಿಗೆ ಮುಖ್ಯ ಎಚ್ಚರಿಕೆಗಳಿವೆ: ";
      if (first.sideEffects.isNotEmpty) {
        text += "${first.sideEffects.first} ";
      }
      if (first.warnings.isNotEmpty) {
        text += first.warnings.first;
      }
      if (items.length > 1) {
        text += " ಜೊತೆಗೆ ಇನ್ನೂ ${items.length - 1} ಔಷಧಿಗಳಿಗೂ ಎಚ್ಚರಿಕೆಗಳಿವೆ.";
      }
      return text;
    } else if (isHi) {
      String text = "$medName दवा के लिए महत्वपूर्ण चेतावनियां हैं: ";
      if (first.sideEffects.isNotEmpty) {
        text += "${first.sideEffects.first} ";
      }
      if (first.warnings.isNotEmpty) {
        text += first.warnings.first;
      }
      if (items.length > 1) {
        text += " साथ ही ${items.length - 1} अन्य दवाओं के लिए भी चेतावनियां हैं।";
      }
      return text;
    } else {
      String text = "Warning for $medName: ";
      if (first.sideEffects.isNotEmpty) {
        text += "${first.sideEffects.first} ";
      }
      if (first.warnings.isNotEmpty) {
        text += first.warnings.first;
      }
      if (items.length > 1) {
        text += " There are also warnings for ${items.length - 1} other medicine(s).";
      }
      return text;
    }
  }
}

