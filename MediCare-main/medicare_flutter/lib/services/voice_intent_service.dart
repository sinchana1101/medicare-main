enum VoiceIntent {



  home,



  scan,



  schedule,



  assistant,



  more,



  emergency,



  takePhoto,



  uploadPhoto,



  save,



  markTaken,



  skipDose,



  nextMedicine,



  readPage,



  repeat,



  stop,



  help,



  setAlarm,



  back,



  whereAmI,



  yes,



  no,



  cancel,



  snooze,



  callCaregiver,



  callAmbulance,



  demoLogin,



  testAlarm,



  signOut,



  prescriptionMode,



  medicineMode,



  refresh,



  langEn,



  langKn,



  langHi,



  noiseCancelOn,



  noiseCancelOff,



  continuousVoiceOn,



  continuousVoiceOff,



  sendMail,

  switchCamera,

  safetyCheck,

  deleteDuplicate,

  checkWarnings,

  deleteWarningMedicine,
  deleteAllMedicines
}



class _IntentCandidate {



  final VoiceIntent intent;



  final int startIndex;



  final int length;



  _IntentCandidate(this.intent, this.startIndex, this.length);



}



class VoiceIntentService {



  static const Map<VoiceIntent, List<String>> _phrases = {



    // Navigation Intents



    VoiceIntent.home: [



      "home", "open home", "open the home", "go to home", "show home", "main page", "dashboard", "today's schedule", "main screen", "home screen", "take me home", "back to home", "main",



      "ಮುಖಪುಟ", "ಮನೆ", "ಮುಖ್ಯ ಪುಟ", "ಇಂದಿನ ವೇಳಾಪಟ್ಟಿ", "ಹೋಮ್", "ಹೋಂ", "ಹೋಮ್ ತೆರೆ", "ಹೋಮ್ ಓಪನ್", "ಓಪನ್ ಹೋಮ್", "ಮುಖಪುಟ ತೆರೆ", "ಮನೆಗೆ ಹೋಗು", "ಹೋಮ್ ಸ್ಕ್ರೀನ್",



      "home ge hogi", "home ge hogu", "home hogu", "manege hogu", "manege hogi", "mukhyaputa", "mukhya puta", "mukhya screen", "home open madi",



      "होम", "मुख्य पृष्ठ", "घर", "आज की खुराक", "डैशबोर्ड", "मुख्य स्क्रीन", "होम स्क्रीन", "होम खोलो", "ओपन होम", "होम जाओ", "घर जाओ",



      "home jao", "ghar jao", "home kholo", "mukhya prishth", "dashboard dikhao"



    ],



    VoiceIntent.scan: [
      "scan", "open scan", "open the scan", "go to scan", "camera", "read label", "scan medicine", "open camera", "open the camera", "scan box", "scan screen", "start scan", "take me to scan", "scanner", "open scanner", "skan", "scann", "can", "scam", "from home to scan", "home to scan", "to scan", "scan please", "prescription", "scan prescription", "prescription scan", "open prescription", "doctor prescription", "medicine scan", "scan bottle", "scan strip", "scan tablet",
      "ಸ್ಕ್ಯಾನ್", "ಕ್ಯಾಮೆರಾ", "ಕ್ಯಾಮರಾ", "ಲೇಬಲ್ ಓದಿ", "ಔಷಧಿ ಸ್ಕ್ಯಾನ್", "ಸ್ಕ್ಯಾನ್ ತೆರೆ", "ಸ್ಕ್ಯಾನ್ ಓಪನ್", "ಓಪನ್ ಸ್ಕ್ಯಾನ್", "ಕ್ಯಾಮೆರಾ ತೆರೆ", "ಕ್ಯಾಮರಾ ಓಪನ್", "ಸ್ಕ್ಯಾನರ್", "ಸ್ಕಾನರ್", "ಸ್ಕ್ಯಾನ್ ಸ್ಕ್ರೀನ್", "ಮುಖಪುಟದಿಂದ ಸ್ಕ್ಯಾನ್", "ಹೋಮ್ ಇಂದ ಸ್ಕ್ಯಾನ್", "ಹೋಮ್ ಟು ಸ್ಕ್ಯಾನ್", "ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್",
      "scan madi", "scan maadi", "scan madu", "scan madiri", "scan open madi", "camera open madi", "camera thegi", "camera thagoli", "scanner open madi", "aushadhi scan madi", "tablet scan madi", "prescription scan madi",
      "स्कैन", "कैमरा", "दवा स्कैन", "लेबल पढ़ो", "स्कैनर", "स्कैन खोलो", "स्कैन ओपन", "ओपन स्कैन", "कैमरा खोलो", "स्कैन पर जाओ", "स्कैन स्क्रीन", "स्कैनर खोलो", "दवाई स्कैन", "होम से स्कैन", "होम टू स्कैन", "पर्चा", "पर्चा स्कैन",
      "scan karo", "scan kardo", "scan kholo", "camera kholo", "dawa scan karo", "dawai scan karo", "scanner kholo", "label padho", "scan pe jao"




    ],



    VoiceIntent.schedule: [



      "schedule", "open schedule", "open the schedule", "go to schedule", "my medicines", "reminders", "all medicines", "pill list", "timeline", "calendar", "show schedule", "schedule screen", "alarms", "alarm", "open alarms", "open alarm", "pills", "doses", "skedule", "shedule",



      "ವೇಳಾಪಟ್ಟಿ", "ಔಷಧಿಗಳು", "ನನ್ನ ಔಷಧಿಗಳು", "ಎಲ್ಲಾ ಔಷಧಿಗಳು", "ಶೆಡ್ಯೂಲ್", "ವೇಳಾಪಟ್ಟಿ ತೆರೆ", "ಶೆಡ್ಯೂಲ್ ತೆರೆ", "ಶೆಡ್ಯೂಲ್ ಓಪನ್", "ಓಪನ್ ಶೆಡ್ಯೂಲ್", "ಅಲಾರಾಂ", "ಅಲಾರಂ", "ಅಲಾರಾಂ ತೆರೆ", "ಅಲಾರಂ ತೆರೆ",



      "velapatti", "velapatti thegi", "velapatti thagoli", "schedulege hogi", "schedule open madi", "nanna aushadhi", "yella aushadhigalu", "alarm thegi", "alarm open madi",



      "समय सारणी", "समय-सारणी", "दवाएं", "दवाएँ", "रिमाइंडर", "मेरी दवाएं", "दवाइयों की सूची", "शेड्यूल", "शेड्यूल खोलो", "शेड्यूल ओपन", "ओपन शेड्यूल", "अलार्म", "अलार्म खोलो", "ओपन अलार्म", "दवाई की सूची",



      "schedule kholo", "schedule dikhao", "time table", "timetable", "dawai ki list", "meri dawai", "meri dawaiyan", "dawai ka time", "dawai kab leni hai", "alarm kholo"



    ],



    VoiceIntent.assistant: [



      "assistant", "open assistant", "open the assistant", "voice assistant", "ask", "question", "talk to ai", "ask doctor", "ai assistant", "talk to assistant", "go to assistant", "ai", "doctor", "bot",



      "ಸಹಾಯಕ", "ಪ್ರಶ್ನೆ", "ಎಐ ಸಹಾಯಕ", "ಕೇಳು", "ಅಸಿಸ್ಟೆಂಟ್", "ಸಹಾಯಕ ತೆರೆ", "ಅಸಿಸ್ಟೆಂಟ್ ಓಪನ್", "ಓಪನ್ ಅಸಿಸ್ಟೆಂಟ್", "ಡಾಕ್ಟರ್",



      "sahayaka", "sahayakaru", "doctor ge keli", "assistant open madi", "prashne keli",



      "सहायक", "प्रश्न", "पूछ", "डॉक्टर", "मददगार", "आवाज सहायक", "असिस्टेंट", "सहायक खोलो", "असिस्टेंट ओपन", "ओपन असिस्टेंट",



      "sahayak", "doctor se poocho", "assistant kholo", "madadgar"



    ],



    VoiceIntent.more: [



      "settings", "setting", "the setting", "the settings", "open settings", "open the settings", "open setting", "go to settings", "go to setting", "app settings", "show settings", "more", "options", "preferences", "profile", "account",



      "ಸೆಟ್ಟಿಂಗ್", "ಸೆಟ್ಟಿಂಗ್ಸ್", "ಸೆಟ್ಟಿಂಗ್ ತೆರೆ", "ಸೆಟ್ಟಿಂಗ್ಸ್ ತೆರೆ", "ಸೆಟ್ಟಿಂಗ್ಸ್ ಓಪನ್", "ಓಪನ್ ಸೆಟ್ಟಿಂಗ್ಸ್", "ಇನ್ನಷ್ಟು", "ಖಾತೆ",



      "settings open madi", "setting open madi", "innashtu",



      "सेटिंग", "सेटिंग्स", "सेटिंग खोलो", "सेटिंग्स खोलो", "सेटिंग्स ओपन", "ओपन सेटिंग्स", "और", "प्रोफाइल", "खाता", "विकल्प",



      "settings kholo", "setting kholo", "vikalp dikhao"



    ],



    VoiceIntent.emergency: [



      "emergency", "open emergency", "open the emergency", "help me", "sos", "call for help", "danger", "urgent", "save me", "send sos",



      "send", "send now", "send sms", "send alert", "send message", "trigger sos", "sos alert", "alert",



      "ತುರ್ತು", "ಸಹಾಯ ಬೇಕು", "ಅಪಾಯ", "ರಕ್ಷಿಸಿ", "ಎಮರ್ಜೆನ್ಸಿ", "ಎಸ್ಒಎಸ್", "ತುರ್ತು ತೆರೆ", "ಎಮರ್ಜೆನ್ಸಿ ಓಪನ್", "ಕಳುಹಿಸು", "ಎಸ್ಒಎಸ್ ಕಳುಹಿಸು", "ಕಾಪಾಡಿ",



      "turtu", "aapatu", "sahaya beku", "help madi", "kapadi", "emergency open madi", "sos kalsi", "sos kalisi",



      "आपातकाल", "मदद करो", "बचाओ", "खतरा", "इमरजेंसी", "एसओएस", "इमरजेंसी खोलो", "आपातकाल खोलो", "भेजो", "एसओएस भेजो", "सहायता करो",



      "aapatkaal", "aapatkal", "bachao", "madad karo", "emergency kholo", "sos bhejo", "khatra hai"



    ],



    // Action Intents



    VoiceIntent.deleteDuplicate: [
      "delete duplicate", "delete duplicate medicine", "delete duplicate tablet", "delete duplicate med",
      "remove duplicate", "remove duplicate medicine", "remove duplicate tablet", "remove the duplicate",
      "delete the duplicate", "delete duplicate pills", "remove duplicate pills",
      "ನಕಲಿ ಔಷಧಿ ಅಳಿಸಿ", "ನಕಲಿ ಮಾತ್ರೆ ಅಳಿಸಿ", "ನಕಲಿ ತೆಗೆದುಹಾಕಿ",
      "डुप्लीकेट दवा हटाएं", "नकली दवा हटाएं", "डुप्लीकेट हटाएं", "नकली दवा डिलीट करें",
    ],
    VoiceIntent.checkWarnings: [
      "check warnings", "show warnings", "warnings", "warning", "check side effects", "show side effects", "side effects", "side effect", "tablet side effects", "medicine side effects", "any side effects", "open warnings", "open side effects", "show me side effects", "what are the side effects", "medicine warning", "warnings and side effects", "adverse effects", "check warning", "see warnings", "view warnings",
      "ಎಚ್ಚರಿಕೆಗಳನ್ನು ತೋರಿಸಿ", "ಎಚ್ಚರಿಕೆಗಳು", "ಅಡ್ಡಪರಿಣಾಮಗಳು", "ಸೈಡ್ ಎಫೆಕ್ಟ್ಸ್", "ಮಾತ್ರೆಗಳ ಅಡ್ಡಪರಿಣಾಮಗಳು", "ಅಡ್ಡ ಪರಿಣಾಮಗಳು", "ಎಚ್ಚರಿಕೆ ಪರಿಶೀಲಿಸಿ", "ಎಚ್ಚರಿಕೆ", "ಸೈಡ್ ಎಫೆಕ್ಟ್", "ಎಚ್ಚರಿಕೆ ತೋರಿಸು", "ಅಡ್ಡ ಪರಿಣಾಮ",
      "warnings thegi", "side effects thegi", "warnings thogoli", "side effects nodi",
      "चेतावनियां दिखाएं", "चेतावनियां", "साइड इफेक्ट्स", "दुष्प्रभाव", "दवा के साइड इफेक्ट्स", "साइड इफेक्ट दिखाओ", "चेतावनियां चेक करो", "दुष्प्रभाव बताओ", "चेतावनी", "साइड इफेक्ट", "दुष्परिणाम",
      "warnings dikhao", "side effects batao", "side effect kya hai"
    ],
    VoiceIntent.deleteAllMedicines: [
      "delete all data", "clear all data", "delete all medicines", "delete all tablets", "clear all medicines",
      "delete all meds", "wipe all data", "reset all data", "delete everything", "clear everything",
      "ಎಲ್ಲಾ ಡೇಟಾ ಅಳಿಸಿ", "ಎಲ್ಲಾ ಔಷಧಿಗಳನ್ನು ಅಳಿಸಿ", "ಎಲ್ಲವನ್ನು ಅಳಿಸಿ",
      "सारा डेटा हटाएं", "सभी दवाएं हटाएं", "सब कुछ हटाएं", "डेटा साफ करें",
    ],
    VoiceIntent.deleteWarningMedicine: [
      "delete warning medicine", "delete side effect medicine", "delete warned medicine", "remove warning medicine", "delete medicine with side effects", "remove side effect medicine", "delete side effects medicine",
      "ಎಚ್ಚರಿಕೆ ಔಷಧಿ ಅಳಿಸಿ", "ಅಡ್ಡಪರಿಣಾಮದ ಔಷಧಿ ಅಳಿಸಿ", "ಎಚ್ಚರಿಕೆ ಮಾತ್ರೆ ಅಳಿಸಿ", "ಅಡ್ಡಪರಿಣಾಮ ಮಾತ್ರೆ ಅಳಿಸಿ",
      "चेतावनी वाली दवा हटाएं", "साइड इफेक्ट वाली दवा हटाएं", "साइड इफेक्ट वाली दवा डिलीट करें", "चेतावनी वाली दवा डिलीट करें"
    ],
        VoiceIntent.safetyCheck: [
      "run safety check", "safety check", "check safety", "run safety", "check my medicines", "check medicines", "check medicine safety", "medicine safety check", "medicine safety", "run the safety check", "start safety check", "safety", "run a safety check",
      "ಸುರಕ್ಷತಾ ತಪಾಸಣೆ", "ಸುರಕ್ಷತೆ ಪರಿಶೀಲಿಸಿ", "ಸುರಕ್ಷತೆ ಚೆಕ್", "ಔಷಧಿ ಸುರಕ್ಷತೆ", "ಸುರಕ್ಷತೆ",
      "safety check madi", "safety check maadi", "safety check madu", "safety check open madi", "safety check thegi",
      "सुरक्षा जाँच", "सुरक्षा चेक", "सुरक्षा चेक करो", "दवा सुरक्षा", "दवाइयों की सुरक्षा", "सुरक्षा", "सुरक्षा जांच",
      "safety check karo", "safety check kardo", "dawa check karo"
    ],

    VoiceIntent.switchCamera: [

      "switch camera", "flip camera", "change camera", "switch", "flip",

      "front camera", "back camera", "toggle camera", "turn camera",

      "ಕ್ಯಾಮರಾ ಬದಲಿಸಿ", "ಕ್ಯಾಮೆರಾ ಬದಲಿಸಿ", "ಕ್ಯಾಮರಾ ಸ್ವಿಚ್", "ಕ್ಯಾಮೆರಾ ಸ್ವಿಚ್",

      "ಕ್ಯಾಮರಾ ಚೇಂಜ್", "ಕ್ಯಾಮೆರಾ ಚೇಂಜ್", "ಕ್ಯಾಮರಾ ಫ್ಲಿಪ್", "ಕ್ಯಾಮೆರಾ ತಿರುಗಿಸಿ",

      "ಮುಂಭಾಗದ ಕ್ಯಾಮರಾ", "ಹಿಂಭಾಗದ ಕ್ಯಾಮರಾ", "ಕ್ಯಾಮರಾ ಬದಲಾಯಿಸಿ",

      "कैमरा बदलो", "कैमरा बदलें", "कैमरा स्विच करो", "कैमरा फ्लिप",

      "कैमरा चेंज", "आगे का कैमरा", "पीछे का कैमरा", "कैमरा बदलिए"

    ],

VoiceIntent.takePhoto: [



      "take photo", "take a photo", "take the photo", "take picture", "take a picture", "take the picture",



      "click photo", "click the photo", "click a photo", "capture", "capture image", "capture photo", "capture the photo", "capture a photo", "capture this photo",



      "snap", "click picture", "click the picture", "click", "shoot", "snap photo", "photo", "camera", "picture", "pic", "cheese", "shutter", "clik", "klick",



      "click it", "capture it", "take it", "snap it", "shoot it",



      "ಫೋಟೋ ತೆಗೆ", "ಚಿತ್ರ ತೆಗೆ", "ಕ್ಲಿಕ್ ಮಾಡಿ", "ಕ್ಲಿಕ್", "ಕ್ಯಾಪ್ಚರ್", "ಫೋಟೋ", "ಕ್ಯಾಮರಾ", "ಚಿತ್ರ", "ಕ್ಲಿಕ್ ಮಾಡು",



      "photo thegi", "photo thegiri", "photo thogoli", "photo togoli", "photo madi", "click madi", "click madu", "capture madi", "chitra thegi", "photo snap madi", "photo tege", "photo thege", "photo thago", "photo tago", "photo tegi", "click madu", "capture madu", "camera open", "photo thago", "chitra tege",



      "फोटो लो", "फोटो लें", "तस्वीर लो", "फोटो खींचो", "क्लिक करो", "क्लिक", "चित्र लो", "फोटो", "कैमरा", "तस्वीर", "खींचो",



      "photo kheencho", "photo khincho", "photo khicho", "photo kheecho", "photo lo", "photo le lo", "tasveer lo", "click karo", "capture karo", "snap lo", "photo khinch", "kheecho", "khicho"



    ],



    VoiceIntent.uploadPhoto: [



      "upload photo", "upload", "choose photo", "gallery", "pick image", "select photo",



      "ಅಪ್‌ಲೋಡ್", "ಗ್ಯಾಲರಿ", "ಫೋಟೋ ಆರಿಸಿ", "ಚಿತ್ರ ಆರಿಸಿ",



      "अपलोड", "गैलरी", "फोटो चुनो", "गैलरी से लो"



    ],



    VoiceIntent.save: [



      "save", "save medicine", "confirm save", "add to schedule", "save this", "store",



      "ಉಳಿಸಿ", "ಸೇವ್", "ಸೇರಿಸಿ", "ಖಚಿತಪಡಿಸಿ",



      "सहेज", "सेव", "सुरक्षित करें", "जोड़ो", "रख लो"



    ],



    VoiceIntent.markTaken: [



      "mark taken", "marked taken", "marc taken", "marck taken", "mark take", "mark as taken",



      "mark", "mark it", "mark this", "mark dose", "mark medicine", "mark pill", "mark dolo",



      "taken", "i took", "took my medicine", "i have taken", "pill taken", "medicine taken", "dose taken",



      "done", "consumed", "already taken", "took", "had my medicine", "had medicine", "ate medicine",



      "took pill", "took my pill", "take pill", "pill was taken", "i took it", "took it", "swallowed", "finished",



      "ತೆಗೆದುಕೊಂಡೆ", "ತೆಗೆದುಕೊಂಡಿದ್ದೀನಿ", "ತೆಗೆದುಕೊಂಡಿದ್ದೇನೆ", "ತೆಗೆದುಕೊಂಡೆನು",



      "ತಗೊಂಡೆ", "ತಗೊಂಡಿದ್ದೀನಿ", "ತಗೊಂಡಿದ್ದೇನೆ", "ತಗೊಂಡೆನು", "ತಗೊಂಡಿನಿ", "ತಗೊಂಡಾಯ್ತು",



      "ಸೇವಿಸಿದೆ", "ಕುಡಿದೆ", "ಮುಗಿಯಿತು", "ಆಗಿದೆ", "ಔಷಧಿ ಸೇವಿಸಿದೆ", "ಔಷಧಿ ತೆಗೆದುಕೊಂಡೆ", "ಔಷಧಿ ತಗೊಂಡೆ", "ಔಷಧ ತಗೊಂಡೆ",



      "ಡೋಸ್ ತೆಗೆದುಕೊಂಡೆ", "ಡೋಸ್ ತಗೊಂಡೆ", "ಮಾತ್ರೆ ತೆಗೆದುಕೊಂಡೆ", "ಮಾತ್ರೆ ತಗೊಂಡೆ", "ಮಾರ್ಕ್ ಮಾಡು", "ಮಾರ್ಕ್ ಟೇಕನ್", "ಮಾರ್ಕ್",



      "ಎತ್ತು", "ಎತ್ತಿದೆ", "ಹಾಕಿದೆ", "ಹಾಕ್ಕೊಂಡೆ",



      "thogonde", "thogondini", "thagondini", "thagonde", "thogondaytu", "tagondaytu", "aushadhi thogonde", "tablet thogonde", "matre thogonde", "dose thogonde", "mark madi", "mark madu", "mark taken madi", "tegedukonde", "aushadhi thagondini", "tablet thagondini",



      "ले लिया", "ले ली", "खा लिया", "खा ली", "दवा खा ली", "दवा ले ली", "गोली ले ली", "गोली खा ली",



      "खुराक ले ली", "हो गया", "पी लिया", "मार्क टेकन", "मार्क करो", "मार्क", "दवाई खा ली", "दवाई ले ली",



      "le liya", "le li", "kha liya", "kha li", "dawai le li", "dawai khali", "dawa le li", "dawa khali", "goli le li", "goli khali", "maine le li", "maine kha li", "khorak le li", "mark kardo", "mark karo"



    ],



    VoiceIntent.skipDose: [



      "skip", "skip dose", "skip medicine", "skip pill", "skipped", "skip it", "skip this", "skip the dose",



      "did not take", "didn't take", "missed", "missed dose", "missed it", "not taking", "don't take", "leave it", "cancel dose",



      "ಬಿಟ್ಟುಬಿಡಿ", "ಬಿಟ್ಟು ಬಿಡಿ", "ಬಿಡು", "ಬಿಡ್ರಿ", "ಬೇಡ", "ಡೋಸ್ ಬಿಡಿ", "ಡೋಸ್ ಬೇಡ", "ಔಷಧಿ ಬಿಡಿ", "ಔಷಧಿ ಬೇಡ", "ಮಾತ್ರೆ ಬೇಡ",



      "ತೆಗೆದುಕೊಳ್ಳಬೇಡ", "ತೆಗೆದುಕೊಂಡಿಲ್ಲ", "ತಗೊಂಡಿಲ್ಲ", "ಸ್ಕಿಪ್", "ಸ್ಕಿಪ್ ಮಾಡು", "ಸ್ಕಿಪ್ ಡೋಸ್",



      "bittubidi", "bittu bidi", "bidu", "bidri", "beda", "tablet beda", "matre beda", "thogondilla", "tagondilla", "skip madi", "skip madu",



      "छोड़ो", "छोड़ दिया", "छोड़ दें", "छोड़ दीजिए", "दवा छोड़ दो", "नहीं ली", "नहीं लिया", "नहीं खाना", "नहीं खाया", "स्किप", "स्किप करो", "दवाई छोड़ दो",



      "chhod do", "chhod diya", "nahi li", "nahi liya", "nahi khana", "nahi khaya", "skip kardo", "skip karo", "dawai nahi li"



    ],



    VoiceIntent.nextMedicine: [



      "next medicine", "what next", "next dose", "upcoming medicine", "when is next", "next pill",



      "ಮುಂದಿನ ಔಷಧಿ", "ಮುಂದಿನದು ಯಾವುದು", "ಮುಂದೆ ಏನು",



      "mundina aushadhi", "munde yenu", "mundinadu yavudu",



      "अगली दवा", "आगे क्या है", "अगली खुराक", "अगली दवाई",



      "agli dawai", "agli dawa", "aage kya hai", "agli khorak"



    ],



    VoiceIntent.readPage: [



      "read page", "read this", "read aloud", "what is on screen", "describe screen", "read schedule", "read medicines", "tell me my medicines", "read all",



      "ಪುಟ ಓದಿ", "ಓದಿ", "ಸ್ಕ್ರೀನ್ ಓದಿ", "ಔಷಧಿಗಳನ್ನು ಓದಿ", "ವಿವರಿಸಿ", "ಎಲ್ಲಾ ಓದಿ",



      "puta odi", "yella odi", "screen odi", "aushadhigalannu odi",



      "पृष्ठ पढ़", "पढ़ो", "पढ़ें", "स्क्रीन पढ़ो", "दवाएं बताओ", "सुनाओ", "सब पढ़ो",



      "padho", "screen padho", "dawaiyan batao", "sab padho"



    ],



    VoiceIntent.repeat: [



      "repeat", "say again", "what did you say", "pardon", "one more time", "again",



      "ಮತ್ತೆ ಹೇಳಿ", "ಪುನಃ", "ಇನ್ನೊಮ್ಮೆ ಹೇಳಿ", "ಮತ್ತೆ",



      "mathe heli", "innomme heli", "punah heli",



      "फिर से", "दोहरा", "दोहराओ", "एक बार फिर", "फिर बोलो",



      "phir se bolo", "dobara bolo", "ek bar phir"



    ],



    VoiceIntent.stop: [



      "stop", "quiet", "silence", "shut up", "pause", "hush", "mute",



      "ನಿಲ್ಲಿಸಿ", "ಸುಮ್ಮನಿರಿ", "ಸಾಕು", "ಚುಪ್", "ಸ್ಟಾಪ್",



      "nillisi", "summaniri", "saku", "chup",



      "रुको", "बंद करो", "चुप", "शांत", "स्टॉप",



      "ruko", "band karo", "chup raho", "shant"



    ],



    VoiceIntent.help: [



      "help", "what can i say", "commands", "how to use", "options", "instructions",



      "ಸಹಾಯ", "ಏನು ಹೇಳಬಹುದು", "ಆದೇಶಗಳು",



      "sahaya", "sahaya madi", "yenu helabahudu",



      "मदद", "क्या कह सकता", "निर्देश", "कमांड",



      "madad", "sahayata", "kya bolu"



    ],



    VoiceIntent.setAlarm: [



      "set alarm", "set an alarm", "set a reminder", "add reminder", "new alarm", "remind me",



      "ಅಲಾರಂ ಇಡಿ", "ಅಲಾರಂ", "ನೆನಪಿಸು", "ಜ್ಞಾಪನೆ ಇಡಿ",



      "अलार्म लगाओ", "अलार्म", "याद दिलाओ", "रिमाइंडर लगाओ"



    ],



    VoiceIntent.snooze: [



      "snooze", "later", "remind in 10 minutes", "after 10 minutes",



      "ಸ್ನೂಜ್", "ನಂತರ", "ಹತ್ತು ನಿಮಿಷ ಬಿಟ್ಟು",



      "स्नूज़", "स्नूज", "बाद में", "१० मिनट बाद"



    ],



    VoiceIntent.back: [



      "go back", "back", "previous", "return", "exit screen",



      "ಹಿಂದಕ್ಕೆ", "ಹಿಂದಿನದು", "ಹಿಂದೆ ಹೋಗು", "ವಾಪಸ್",



      "hindakke", "hinde hogu", "wapas", "back hogu",



      "वापस", "पीछे", "वापस जाओ", "पिछला",



      "wapas", "wapas jao", "peeche jao", "back jao"



    ],



    VoiceIntent.whereAmI: [



      "where am i", "which screen", "current screen", "what page",



      "ನಾನು ಎಲ್ಲಿದ್ದೇನೆ", "ಯಾವ ಪರದೆ", "ಯಾವ ಪುಟ",



      "मैं कहाँ हूँ", "कौन सी स्क्रीन", "यह क्या है"



    ],



    VoiceIntent.yes: [



      "yes", "yeah", "correct", "okay", "ok", "confirm", "sure", "yep",



      "ಹೌದು", "ಸರಿ", "ಖಂಡಿತ",



      "हाँ", "हां", "ठीक", "सही", "अवश्य"



    ],



    VoiceIntent.no: [



      "no", "wrong", "nope", "never", "incorrect",



      "ಇಲ್ಲ", "ತಪ್ಪು", "ಬೇಡ",



      "नहीं", "गलत", "मत करो"



    ],



    VoiceIntent.cancel: [



      "cancel", "abort", "discard", "dismiss",



      "ರದ್ದು", "ರದ್ದುಮಾಡಿ", "ಬೇಡ",



      "रद्द", "बंद", "हटाओ"



    ],



    VoiceIntent.callCaregiver: [



      "call caregiver", "call emergency contact", "call family", "call doctor", "call my helper",



      "ಆರೈಕೆದಾರರಿಗೆ ಕರೆ", "ಸಹಾಯಕರಿಗೆ ಕರೆ", "ತುರ್ತು ಕರೆ",



      "केयरगिवर को कॉल", "सहायक को कॉल", "संपर्क को फोन करो", "परिवार को फोन"



    ],



    VoiceIntent.callAmbulance: [



      "call ambulance", "ambulance", "call 108", "dial 108", "108", "hospital call",



      "ಆಂಬ್ಯುಲೆನ್ಸ್", "೧೦೮", "೧೦೮ ಗೆ ಕರೆ", "ಆಸ್ಪತ್ರೆಗೆ ಕರೆ",



      "एम्बुलेंस", "१०८", "१०८ पर कॉल", "अस्पताल को फोन"



    ],



    VoiceIntent.demoLogin: [



      "demo", "demo login", "continue offline", "offline mode", "guest login", "guest",



      "ಡೆಮೊ", "ಆಫ್‌ಲೈನ್", "ಡೆಮೊ ಲಾಗಿನ್",



      "डेमो", "ऑफ़लाइन", "डेमो लॉगिन", "अतिथि"



    ],



    VoiceIntent.testAlarm: [



      "test alarm", "alarm test", "check alarm",



      "ಅಲಾರಂ ಪರೀಕ್ಷೆ", "ಅಲಾರಂ ಚೆಕ್",



      "अलार्म टेस्ट", "अलार्म जांचें"



    ],



    VoiceIntent.signOut: [



      "sign out", "log out", "logout",



      "ನಿರ್ಗಮಿಸಿ", "ಲಾಗ್ ಔಟ್",



      "लॉग आउट", "साइन आउट"



    ],



    VoiceIntent.prescriptionMode: [



      "prescription mode", "prescription", "doctor note", "switch to prescription",



      "ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್", "ವೈದ್ಯರ ಚೀಟಿ", "ಚೀಟಿ ಮೋಡ್",



      "पर्चा", "डॉक्टर का पर्चा", "पर्चा मोड"



    ],



    VoiceIntent.medicineMode: [



      "medicine mode", "box mode", "switch to medicine", "medicine label",



      "ಔಷಧಿ ಮೋಡ್", "ಬಾಕ್ಸ್ ಮೋಡ್",



      "दवा मोड", "बॉक्स मोड"



    ],



    VoiceIntent.refresh: [



      "refresh", "reload", "update",



      "ನವೀಕರಿಸಿ", "ರಿಫ್ರೆಶ್",



      "रिफ्रेश", "ताज़ा करें"



    ],



    VoiceIntent.langEn: [



      "speak english", "english", "switch to english", "change to english",



      "english me bolo", "english nalli mathadi",



      "ಇಂಗ್ಲಿಷ್", "ಇಂಗ್ಲಿಷ್ ಭಾಷೆ",



      "अंग्रेज़ी", "अंग्रेजी", "इंग्लिश"



    ],



    VoiceIntent.langKn: [



      "speak kannada", "kannada", "switch to kannada", "change to kannada",



      "kannada mathadi", "kannadadalli mathadi", "kannada maathadi", "kannad", "kannada bhasha",



      "ಕನ್ನಡ", "ಕನ್ನಡ್", "ಕನ್ನಡದಲ್ಲಿ ಮಾತನಾಡಿ", "ಕನ್ನಡ ಭಾಷೆ"



    ],



    VoiceIntent.langHi: [



      "speak hindi", "hindi", "switch to hindi", "change to hindi",



      "hindi me bolo", "hindi bolo", "hindi bhasha",



      "ಹಿಂದಿ",



      "हिंदी", "हिन्दी", "हिंदी में बोलो", "हिंदी भाषा"



    ],



    VoiceIntent.noiseCancelOn: [



      "turn on noise cancellation", "noise cancellation on", "enable noise cancellation",



      "ಶಬ್ದ ರದ್ದತಿ ಆನ್",



      "शोर रद्दीकरण चालू"



    ],



    VoiceIntent.noiseCancelOff: [



      "turn off noise cancellation", "noise cancellation off", "disable noise cancellation",



      "ಶಬ್ದ ರದ್ದತಿ ಆಫ್",



      "शोर रद्दीकरण बंद"



    ],



    VoiceIntent.continuousVoiceOn: [



      "turn on continuous voice", "continuous voice on", "start continuous listening", "voice mode on", "hands free on", "hands free mode", "keep listening",



      "ಧ್ವನಿ ಮೋಡ್ ಆನ್", "ವಾಯ್ಸ್ ಮೋಡ್ ಆನ್",



      "वॉइस मोड चालू", "कंटीन्यूअस वॉइस ऑन"



    ],



    VoiceIntent.continuousVoiceOff: [



      "turn off continuous voice", "continuous voice off", "stop continuous listening", "voice mode off", "hands free off", "stop listening",



      "ಧ್ವನಿ ಮೋಡ್ ಆಫ್", "ವಾಯ್ಸ್ ಮೋಡ್ ಆಫ್",



      "वॉइस मोड बंद", "कंटीन्यूअस वॉइस बंद"



    ],



    VoiceIntent.sendMail: [



      "send mail", "send email", "mail", "email", "mail caregiver", "email caregiver",



      "send mail to caregiver", "send email to caregiver", "email report", "mail report",



      "send emergency mail", "email alert", "mail alert", "send a mail", "send an email",



      "caregiver email", "caregiver mail", "compose mail", "compose email",



      "ಇಮೇಲ್ ಕಳುಹಿಸು", "ಮೇಲ್ ಕಳುಹಿಸು", "ಇಮೇಲ್", "ಮೇಲ್", "ಆರೈಕೆದಾರರಿಗೆ ಇಮೇಲ್", "ಆರೈಕೆದಾರರಿಗೆ ಮೇಲ್", "ಡಾಕ್ಟರ್‌ಗೆ ಇಮೇಲ್", "ಜಿಮೇಲ್",



      "email kalsi", "mail kalsi", "email kalisi", "mail kalisi", "caregiver ge email kalsi", "doctor ge email kalsi",



      "ईमेल भेजो", "मेल भेजो", "ईमेल", "मेल", "केयरगिवर को ईमेल", "केयरगिवर को मेल", "डॉक्टर को ईमेल", "ईमेल भेजें", "मेल भेजें", "जीमेल",



      "email bhejo", "mail bhejo", "caregiver ko email bhejo", "email bhej do", "mail bhej do"



    ],



  };



  // High-performance precompiled regular expressions for sentence and keyword matching



  static final RegExp _sendMailRegex = RegExp(



    r'\b(?:(?:send\s+(?:an?\s+)?|trigger\s+|compose\s+)?(?:mail|email|e-mail|gmail)|'



    r'(?:mail|email|e-mail)\s+(?:caregiver|doctor|family|contact|report|alert|now|to\s+caregiver)|'



    r'caregiver\s+mail|caregiver\s+email)\b|'



    r'(?:(?:ಇಮೇಲ್|ಮೇಲ್|ಜಿಮೇಲ್)(?:\s*(?:ಕಳುಹಿಸು|ಮಾಡು|ಬರೆ|ಓಪನ್))?|'



    r'(?:ಆರೈಕೆದಾರರಿಗೆ|ಡಾಕ್ಟರ್‌ಗೆ|ಕುಟುಂಬಕ್ಕೆ)\s*(?:ಇಮೇಲ್|ಮೇಲ್))|'



    r'(?:(?:ईमेल|मेल|जीमेल)(?:\s*(?:भेजो|भेजें|करो|लिखो|खोलो))?|'



    r'(?:केयरगिवर|डॉक्टर|परिवार)\s*(?:को\s*)?(?:ईमेल|मेल))',



    caseSensitive: false,



  );



  static final RegExp _homeRegex = RegExp(



    r'(?:(?:open|go\s*to|goto|show|navigate\s*to|back\s*to|take\s*me\s*to|view|visit)\s+(?:the\s+)?)?(?:home|hom|whom|dashboard|main\s*(?:page|screen)?|today(?:\x27?s)?\s*schedule)\b|'



    r'\b(?:home\s*(?:ge\s*hogu|ge\s*hogi|hogu|hogi|screen|jao|kholo)|manege\s*hogu|mukhyaputa|mukhya\s*puta|ghar\s*jao)\b|'



    r'(?:(?:ಓಪನ್\s+)?(?:ಹೋಮ್|ಹೋಂ|ಮುಖಪುಟ|ಮನೆ|ಮುಖ್ಯ\s*ಪುಟ|ಇಂದಿನ\s*ವೇಳಾಪಟ್ಟಿ)(?:\s*(?:ತೆರೆ|ಓಪನ್|ಗೆ\s*ಹೋಗು|ತೋರಿಸು|ಸ್ಕ್ರೀನ್))?)|'



    r'(?:(?:ओपन\s+)?(?:होम|मुख्य|मुखपृष्ठ|घर|डैशबोर्ड|आज\s*(?:का\s*)?(?:शेड्यूल|समय\s*सारणी))(?:\s*(?:खोलो|ओपन|पर\s*जाओ|दिखाओ|स्क्रीन))?)',



    caseSensitive: false,



  );



  static final RegExp _scanRegex = RegExp(
    r'(?:(?:open|go\s*to|goto|show|navigate\s*to|start|launch|take\s*me\s*to|from\s+home\s+to|home\s+to)\s+(?:the\s+)?)?'
    r'(?:scan|camera|scanner|skan|scann|scam|cam|camra|camara|scan\s*medicine|scan\s*box|scan\s*screen|read\s*label|prescription|scan\s*prescription)\b|'
    r'^(?:can|to\s*can|open\s*can|go\s*to\s*can)\b|'
    r'\b(?:scan\s*(?:madi|maadi|madu|madiri|karo|kardo|kholo|open|screen)|camera\s*(?:thegi|thagoli|kholo|open\s*madi)|aushadhi\s*scan|dawa\s*scan|dawai\s*scan|prescription\s*scan)\b|'
    r'(?:(?:ಓಪನ್\s+)?(?:ಸ್ಕ್ಯಾನ್|ಸ್ಕಾನರ್|ಕ್ಯಾಮೆರಾ|ಕ್ಯಾಮರಾ|ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್)(?:\s*(?:ತೆರೆ|ಓಪನ್|ಮಾಡು|ತೋರಿಸು|ಸ್ಕ್ರೀನ್|ಔಷಧಿ|ಓದಿ))?)|'
    r'(?:(?:ओपन\s+)?(?:स्कैन|स्कैनर|कैमरा|कैमरे|पर्चा)(?:\s*(?:खोलो|ओपन|करो|दिखाओ|जाओ|स्क्रीन|दवा|पढ़ो))?)',
    caseSensitive: false,




  );



  static final RegExp _scheduleRegex = RegExp(



    r'(?:(?:open|go\s*to|goto|show|navigate\s*to|view|list|tell\s*me)\s+(?:the\s+)?)?'



    r'(?:schedule|skedule|shedule|schedul|shedul|reminders?|my\s*medicines?|all\s*medicines?|medicines?|pill\s*list|medicine\s*list|dose\s*list|timeline|calendar|alarms?|my\s*doses?|my\s*pills?)\b|'



    r'\b(?:velapatti|schedulege\s*hogi|schedule\s*(?:kholo|dikhao|open\s*madi)|dawai\s*ki\s*list|meri\s*dawai|dawai\s*ka\s*time|nanna\s*aushadhi)\b|'



    r'(?:(?:ಓಪನ್\s+)?(?:ವೇಳಾಪಟ್ಟಿ|ಶೆಡ್ಯೂಲ್|ಶೆಡ್ಯೂಲ|ಔಷಧಿಗಳು|ನನ್ನ\s*ಔಷಧಿಗಳು|ಎಲ್ಲಾ\s*ಔಷಧಿಗಳು|ಅಲಾರಾಂ|ಅಲಾರಂ)(?:\s*(?:ತೆರೆ|ಓಪನ್|ತೋರಿಸು|ಪಟ್ಟಿ))?)|'



    r'(?:(?:ओपन\s+)?(?:शेड्यूल|समय\s*सारणी|समय-सारणी|दवाएं|दवाएँ|मेरी\s*दवाएं|दवाइयों\s*की\s*सूची|रिमाइंडर|अलार्म)(?:\s*(?:खोलो|ओपन|दिखाओ|जाओ))?)',



    caseSensitive: false,



  );



  static final RegExp _assistantRegex = RegExp(



    r'(?:(?:open|go\s*to|talk\s*to|ask|chat\s*with)\s+(?:the\s+)?)?'



    r'(?:assistant|asistant|assistance|voice\s*assistant|ai|ai\s*assistant|doctor|doc|bot|virtual\s*doctor)\b|'



    r'\b(?:sahayaka|sahayakaru|sahayak|doctor\s*(?:se\s*poocho|ge\s*keli)|assistant\s*(?:kholo|open\s*madi))\b|'



    r'(?:(?:ಓಪನ್\s+)?(?:ಸಹಾಯಕ|ಅಸಿಸ್ಟೆಂಟ್|ಎಐ|ಡಾಕ್ಟರ್)(?:\s*(?:ತೆರೆ|ಓಪನ್|ಕೇಳು|ಮಾತನಾಡು|ಜೊತೆ\s*ಮಾತನಾಡು))?)|'



    r'(?:(?:ओपन\s+)?(?:सहायक|असिस्टेंट|मददगार|डॉक्टर|एआई)(?:\s*(?:खोलो|ओपन|पूछो|बात\s*करो))?)',



    caseSensitive: false,



  );



  static final RegExp _settingsRegex = RegExp(



    r'(?:(?:open|go\s*to|goto|show|navigate\s*to)\s+(?:the\s+)?)?'



    r'(?:settings?|setings?|preferences|profile|options?|account|more)\b|'



    r'(?:(?:ಓಪನ್\s+)?(?:ಸೆಟ್ಟಿಂಗ್|ಸೆಟ್ಟಿಂಗ್ಸ್|ಇನ್ನಷ್ಟು|ಖಾತೆ)(?:\s*(?:ತೆರೆ|ಓಪನ್|ತೋರಿಸು))?)|'



    r'(?:(?:ओपन\s+)?(?:सेटिंग|सेटिंग्स|और|विकल्प|प्रोफाइल|खाता)(?:\s*(?:खोलो|ओपन|दिखाओ))?)',



    caseSensitive: false,



  );



  static final RegExp _emergencyRegex = RegExp(



    r'(?:(?:open|trigger)\s+(?:the\s+)?)?'



    r'(?:emergency|emergenci|sos|s\s*o\s*s|help\s*me|save\s*me|danger|urgent|send\s*sms|send\s*sos|send\s*alert|send\s*message|trigger\s*sos|send\s*now)\b|'



    r'^(?:send|send\s+sms|send\s+now)$|'



    r'\b(?:turtu|aapatu|aapatkal|aapatkaal|bachao|madad\s*karo|kapadi|sahaya\s*beku|emergency\s*(?:kholo|open\s*madi)|sos\s*(?:kalsi|kalisi|bhejo))\b|'



    r'(?:(?:ಓಪನ್\s+)?(?:ತುರ್ತು|ಆಪತ್ತು|ಎಮರ್ಜೆನ್ಸಿ|ಎಸ್ಒಎಸ್|ಕಾಪಾಡಿ|ಸಹಾಯ\s*ಬೇಕು)(?:\s*(?:ತೆರೆ|ಓಪನ್|ಮಾಡು))?)|'



    r'^(?:ಕಳುಹಿಸು|ಎಸ್ಒಎಸ್\s*ಕಳುಹಿಸು)$|'



    r'(?:(?:ओपन\s+)?(?:आपातकाल|इमरजेंसी|एसओएस|खतरा|बचाओ|मदद\s*करो)(?:\s*(?:खोलो|ओपन))?)|'



    r'^(?:भेजो|एसओएस\s*भेजो)$',



    caseSensitive: false,



  );



  static final RegExp _takePhotoRegex = RegExp(



    r'\b(?:(?:take|click|capture|snap|shoot)\s+(?:the\s+|a\s+|this\s+)?(?:photo|picture|image|pic)|'



    r'click\s+it|capture\s+it|take\s+it|snap\s+it|shoot\s+it|'



    r'click|clik|klick|capture|captur|snap|shoot|photo|picture|pic|cheese|shutter)\b|'



    r'\b(?:photo\s*(?:thegi|thegiri|thogoli|togoli|tege|thege|thago|tago|tegi|kheencho|khincho|khicho|kheecho|khecho|lo|le\s*lo|madi|madu|karo|capture)|chitra\s*(?:thegi|tege)|tasveer\s*lo|click\s*(?:madi|madu|karo)|capture\s*(?:madi|madu|karo))\b|'



    r'(?:(?:ಫೋಟೋ|ಚಿತ್ರ)\s*(?:ತೆಗೆ|ಕ್ಲಿಕ್\s*ಮಾಡಿ|ಕ್ಯಾಪ್ಚರ್|ಮಾಡು|ಲೋ)?|ಕ್ಲಿಕ್|ಕ್ಯಾಪ್ಚರ್|ಫೋಟೋ|ಚಿತ್ರ)|'



    r'(?:(?:फोटो|तस्वीर|चित्र)\s*(?:लो|खींचो|क्लिक\s*करो|लें|कैप्चर)?|क्लिक|कैप्चर|खींचो|फोटो|तस्वीर)',



    caseSensitive: false,



  );



  static final RegExp _ambulanceRegex = RegExp(



    r'\b(?:(?:call|dial|open)\s+)?(?:108|ambulance|hospital)\b|'



    r'(?:(?:ಕರೆ\s*ಮಾಡಿ\s+)?(?:ಆಂಬ್ಯುಲೆನ್ಸ್|೧೦೮))|'



    r'(?:(?:कॉल\s*करो\s+)?(?:एम्बुलेंस|१०८))',



    caseSensitive: false,



  );



  static final RegExp _caregiverRegex = RegExp(



    r'\b(?:(?:call|contact)\s+(?:my\s+)?)?(?:caregiver|family|helper)\b|'



    r'(?:(?:ಕರೆ\s*ಮಾಡಿ\s+)?(?:ಆರೈಕೆದಾರ|ಕುಟುಂಬ|ಸಹಾಯಕ))|'



    r'(?:(?:कॉल\s*करो\s+)?(?:केयरगिवर|परिवार|सहायक))',



    caseSensitive: false,



  );



  static final RegExp _stopRegex = RegExp(



    r'\b(?:stop|silence|quiet|shut\s*up|pause|hush|mute|stop\s*talking)\b|\b(?:nillisi|summaniri|saku|chup|ruko|band\s*karo|chup\s*raho)\b|(?:ನಿಲ್ಲಿಸಿ|ಸುಮ್ಮನಿರಿ|ಸಾಕು|ಚುಪ್|ಸ್ಟಾಪ್)|(?:रुको|बंद\s*करो|चुप|शांत|स्टॉप)',



    caseSensitive: false,



  );



  static final RegExp _markTakenRegex = RegExp(



    r'\b(?:mark\s*(?:as\s+)?taken|marked\s*taken|marc\s*taken|marck\s*taken|mark\s*take|mark\s*it|mark\s*this|'



    r'mark\s*(?:my\s+)?(?:dose|medicine|pill)?|'



    r'i\s*(?:have\s+)?taken\s*(?:my\s+)?(?:pill|pills|medicine|medicines|dose|it)?|'



    r'i\s*took\s*(?:my\s+)?(?:pill|pills|medicine|medicines|dose|it)?|'



    r'took\s*(?:my\s+)?(?:pill|pills|medicine|medicines|dose|it)?|'



    r'had\s*(?:my\s+)?(?:medicine|pill|dose)|ate\s*(?:my\s+)?(?:medicine|pill)|'



    r'already\s*taken|pill\s*taken|medicine\s*taken|dose\s*taken|take\s*pill|took\s*pill|'



    r'taken|took|done|consumed|finished|swallowed)\b|'



    r'\b(?:(?:tablet|dawa|dawai|aushadhi|matre|dose)\s*(?:thogonde|thogondini|thagondini|thagonde|le\s*li|le\s*liya|khali|kha\s*li|kha\s*liya)|'



    r'(?:nanna\s*)?(?:tablet|matre)\s*(?:thogonde|thagondini)|'



    r'maine\s*(?:dawai|dawa|goli)\s*(?:le\s*li|khali|kha\s*li|kha\s*liya)|'



    r'thogonde|thogondini|thagondini|thagonde|thogondaytu|tagondaytu|tegedukonde|'



    r'le\s*liya|le\s*li|kha\s*liya|kha\s*li|dawai\s*le\s*li|dawai\s*khali|goli\s*le\s*li|goli\s*khali|'



    r'mark\s*(?:madi|madu|karo|kardo|taken\s*madi))\b|'



    r'(?:ತೆಗೆದುಕೊಂಡೆ(?:ನು|ವು)?|ತೆಗೆದುಕೊಂಡಿದ್ದೀನಿ|ತೆಗೆದುಕೊಂಡಿದ್ದೇನೆ|ತಗೊಂಡೆ(?:ನು|ವು)?|ತಗೊಂಡಿದ್ದೀನಿ|ತಗೊಂಡಿದ್ದೇನೆ|ತಗೊಂಡಿನಿ|ತಗೊಂಡಾಯ್ತು|'



    r'ಔಷಧಿ\s*(?:ಸೇವಿಸಿದೆ|ತೆಗೆದುಕೊಂಡೆ|ತಗೊಂಡೆ)|ಔಷಧ\s*(?:ತೆಗೆದುಕೊಂಡೆ|ತಗೊಂಡೆ)|ಮಾತ್ರೆ\s*(?:ತೆಗೆದುಕೊಂಡೆ|ತಗೊಂಡೆ)|ಡೋಸ್\s*(?:ತೆಗೆದುಕೊಂಡೆ|ತಗೊಂಡೆ)|'



    r'ಮಾರ್ಕ್\s*(?:ಮಾಡು|ಟೇಕನ್)?|ಎತ್ತಿದೆ|ಎತ್ತು|ಹಾಕಿದೆ|ಹಾಕ್ಕೊಂಡೆ|ಕುಡಿದೆ|ಸೇವಿಸಿದೆ|ಮುಗಿಯಿತು|ಆಗಿದೆ)|'



    r'(?:ले\s*लिया|ले\s*ली|खा\s*लिया|खा\s*ली|दवा\s*खा\s*ली|दवा\s*ले\s*ली|गोली\s*ले\s*ली|गोली\s*खा\s*ली|खुराक\s*ले\s*ली|'



    r'हो\s*गया|पी\s*लिया|मार्क\s*(?:करो|टेकन)?)',



    caseSensitive: false,



  );



  static final RegExp _skipDoseRegex = RegExp(



    r'\b(?:skip\s*(?:dose|medicine|pill|it|this|the\s+dose)?|skipped|did\s*not\s*take|didn\x27?t\s*take|missed\s*(?:dose|medicine|it)?|missed|not\s*taking|don\x27?t\s*take|leave\s*it|cancel\s*dose)\b|'



    r'\b(?:bittubidi|bittu\s*bidi|bidu|bidri|beda|tablet\s*beda|matre\s*beda|thogondilla|tagondilla|skip\s*(?:madi|madu|karo|kardo)|chhod\s*do|chhod\s*diya|nahi\s*li|nahi\s*liya|nahi\s*khana|nahi\s*khaya)\b|'



    r'(?:ಬಿಟ್ಟುಬಿಡಿ|ಬಿಟ್ಟು\s*ಬಿಡಿ|ಬಿಡು|ಬಿಡ್ರಿ|ಬೇಡ|ಡೋಸ್\s*ಬಿಡಿ|ಡೋಸ್\s*ಬೇಡ|ಔಷಧಿ\s*ಬಿಡಿ|ಔಷಧಿ\s*ಬೇಡ|ಮಾತ್ರೆ\s*ಬೇಡ|'



    r'ತೆಗೆದುಕೊಳ್ಳಬೇಡ|ತೆಗೆದುಕೊಂಡಿಲ್ಲ|ತಗೊಂಡಿಲ್ಲ|ಸ್ಕಿಪ್\s*(?:ಮಾಡು|ಡೋಸ್)?)|'



    r'(?:छोड़ो|छोड़\s*दिया|छोड़\s*दें|छोड़\s*दीजिए|दवा\s*छोड़\s*दो|नहीं\s*ली|नहीं\s*लिया|नहीं\s*खाना|नहीं\s*खाया|स्किप\s*(?:करो)?)',



    caseSensitive: false,



  );



  static final RegExp _backRegex = RegExp(



    r'\b(?:go\s+back|back|previous|return|exit\s*screen|exit|close)\b|\b(?:hindakke|hinde\s*hogu|wapas|wapas\s*jao|peeche\s*jao|back\s*jao)\b|(?:ಹಿಂದಕ್ಕೆ|ಹಿಂದಿನದು|ಹಿಂದೆ\s*ಹೋಗು|ವಾಪಸ್|ಹಿಂದೆ)|(?:वापस|पीछे|वापस\s*जाओ|पिछला)',



    caseSensitive: false,



  );



  static final RegExp _saveRegex = RegExp(



    r'\b(?:save|save\s*medicine|confirm\s*save|add\s*to\s*schedule|save\s*this|store)\b|(?:ಉಳಿಸಿ|ಸೇವ್|ಸೇರಿಸಿ|ಖಚಿತಪಡಿಸಿ)|(?:सहेज|सेव|सुरक्षित\s*करें|जोड़ो|रख\s*ಲೋ)',



    caseSensitive: false,



  );



  static final RegExp _nextMedicineRegex = RegExp(



    r'\b(?:next|upcoming|what\s*next)\b.*\b(?:medicine|dose|pill)?\b|\b(?:mundina\s*aushadhi|munde\s*yenu|agli\s*dawai|agli\s*dawa|aage\s*kya\s*hai)\b|(?:ಮುಂದಿನ\s*ಔಷಧಿ|ಮುಂದಿನದು|ಮುಂದೆ\s*ಏನು)|(?:अगली\s*दवा|आगे\s*क्या\s*है|अगली\s*खुराक)',



    caseSensitive: false,



  );



  static final RegExp _readPageRegex = RegExp(



    r'\b(?:read\s+(?:page|this|aloud|schedule|medicines?|all|screen)|read\s*page|read\s*all|what\s+is\s+on\s+screen|describe\s+screen|tell\s+me\s+my\s+medicines|speak\s+schedule)\b|'



    r'\b(?:puta\s*odi|yella\s*odi|screen\s*odi|padho|screen\s*padho|dawaiyan\s*batao|sab\s*padho)\b|'



    r'(?:ಪುಟ\s*ಓದಿ|ಓದಿ|ಸ್ಕ್ರೀನ್\s*ಓದಿ|ವಿವರಿಸಿ|ಎಲ್ಲಾ\s*ಓದಿ)|'



    r'(?:पृष्ठ\s*पढ़|पढ़ो|पढ़ें|स्क्रीन\s*पढ़ो|दवाएं\s*बताओ|सुनाओ|सब\s*पढ़ो)',



    caseSensitive: false,



  );



  static final RegExp _repeatRegex = RegExp(



    r'\b(?:repeat|say\s*again|what\s+did\s+you\s+say|pardon|one\s+more\s+time|once\s+more|again)\b|\b(?:mathe\s*heli|innomme\s*heli|punah\s*heli|phir\s*se\s*bolo|dobara\s*bolo)\b|(?:ಮತ್ತೆ\s*ಹೇಳಿ|ಪುನಃ|ಇನ್ನೊಮ್ಮೆ\s*ಹೇಳಿ|ಮತ್ತೆ)|(?:फिर\s*से|दोहरा|दोहराओ|एक\s*बार\s*फिर|फिर\s*बोलो)',



    caseSensitive: false,



  );



  static final RegExp _langKnRegex = RegExp(



    r'\b(?:speak\s+kannada|switch\s+to\s+kannada|change\s+to\s+kannada|kannada\s*(?:mathadi|maathadi|bhasha)?|kannad|kannadadalli\s*mathadi)\b|(?:ಕನ್ನಡ|ಕನ್ನಡದಲ್ಲಿ\s*ಮಾತನಾಡಿ|ಕನ್ನಡ\s*ಭಾಷೆ)|(?:कन्नड़|कन्नड)',



    caseSensitive: false,



  );



  static final RegExp _langHiRegex = RegExp(



    r'\b(?:speak\s+hindi|switch\s+to\s+hindi|change\s+to\s+hindi|hindi\s*(?:me\s*bolo|bolo|bhasha)?)\b|(?:ಹಿಂದಿ|ಹಿಂದಿಯಲ್ಲಿ\s*ಮಾತನಾಡಿ)|(?:हिंदी|हिन्दी|हिंदी\s*में\s*बोलो|हिंदी\s*भाषा)',



    caseSensitive: false,



  );



  static final RegExp _langEnRegex = RegExp(



    r'\b(?:speak\s+english|switch\s+to\s+english|change\s+to\s+english|english)\b|(?:ಇಂಗ್ಲಿಷ್|ಇಂಗ್ಲಿಷ್\s*ಭಾಷೆ)|(?:अंग्रेज़ी|अंग्रेजी|इंग्लिश)',



    caseSensitive: false,



  );



  static final RegExp _demoRegex = RegExp(



    r'\b(?:demo|offline|guest)\b|(?:ಡೆಮೊ|ಆಫ್‌ಲೈನ್)|(?:डेमो|ऑफ़लाइन)',



    caseSensitive: false,



  );



  static final RegExp _noiseCancelOnRegex = RegExp(



    r'\b(?:(?:turn\s*on|enable|start|activate)\s+noise\s*cancellation|noise\s*cancellation\s*on|cancel\s*noise)\b|(?:ಶಬ್ದ\s*ರದ್ದತಿ\s*ಆನ್)|(?:शोर\s*रद्दीकरण\s*चालू|शोर\s*हटाना\s*चालू|नॉइज़\s*कैंसलेशन\s*ऑन)',



    caseSensitive: false,



  );



  static final RegExp _noiseCancelOffRegex = RegExp(



    r'\b(?:(?:turn\s*off|disable|stop|deactivate)\s+noise\s*cancellation|noise\s*cancellation\s*off)\b|(?:ಶಬ್ದ\s*ರದ್ದತಿ\s*ಆಫ್)|(?:शोर\s*रद्दीकरण\s*बंद|शोर\s*हटाना\s*बंद|नॉइज़\s*कैंसलेशन\s*ऑफ़)',



    caseSensitive: false,



  );



  static final RegExp _continuousVoiceOnRegex = RegExp(



    r'\b(?:(?:turn\s*on|start|enable|activate)\s+continuous\s*(?:voice|listening)?|continuous\s*voice\s*on|voice\s*mode\s*on|hands\s*free\s*on|hands\s*free\s*mode|keep\s*listening)\b|'



    r'(?:ಧ್ವನಿ\s*ಮೋಡ್\s*ಆನ್|ವಾಯ್ಸ್\s*ಮೋಡ್\s*ಆನ್)|'



    r'(?:वॉइस\s*मोड\s*चालू|कंटीन्यूअस\s*वॉइस\s*ऑन)',



    caseSensitive: false,



  );



  static final RegExp _continuousVoiceOffRegex = RegExp(



    r'\b(?:(?:turn\s*off|stop|disable|deactivate)\s+continuous\s*(?:voice|listening)?|continuous\s*voice\s*off|voice\s*mode\s*off|hands\s*free\s*off|stop\s*continuous\s*listening)\b|'



    r'(?:ಧ್ವನಿ\s*ಮೋಡ್\s*ಆಫ್|ವಾಯ್ಸ್\s*ಮೋಡ್\s*ಆಫ್)|'



    r'(?:वॉइस\s*मोड\s*बंद|कंटीन्यूअस\s*वॉइस\s*बंद)',



    caseSensitive: false,



  );



  static final RegExp _helpRegex = RegExp(



    r'\b(?:help(?:\s*me)?|what\s+can\s+(?:i|you)\s+(?:say|do)|can\s+you(?:\s+help)?|what\s+to\s+do|commands?|how\s+to\s+use|instructions?|options?)\b|'



    r'(?:ಸಹಾಯ|ಏನು\s*ಹೇಳಬಹುದು|ಆದೇಶಗಳು|ಹೇಗೆ\s*ಬಳಸುವುದು)|'



    r'(?:मदद|क्या\s*कह\s*सकता|निर्देश|कमांड|सहायता)',



    caseSensitive: false,



  );



  static final RegExp _uploadPhotoRegex = RegExp(



    r'\b(?:upload\s+(?:a\s+)?photo|upload\s+image|upload|choose\s+photo|gallery|pick\s+(?:image|photo)|select\s+photo)\b|'



    r'(?:ಅಪ್‌ಲೋಡ್|ಗ್ಯಾಲರಿ|ಫೋಟೋ\s*ಆರಿಸಿ|ಚಿತ್ರ\s*ಆರಿಸಿ)|'



    r'(?:अपलोड|गैलरी|फोटो\s*चुनो|गैलरी\s*से\s*लो)',



    caseSensitive: false,



  );



  static final RegExp _setAlarmRegex = RegExp(



    r'\b(?:set\s+(?:an?\s+)?alarm|set\s+(?:a\s+)?reminder|add\s+reminder|new\s+alarm|remind\s+me)\b|'



    r'(?:ಅಲಾರಂ\s*ಇಡಿ|ಅಲಾರಾಂ\s*ಇಡಿ|ನೆನಪಿಸು|ಜ್ಞಾಪನೆ\s*ಇಡಿ)|'



    r'(?:अलार्म\s*लगाओ|अलार्म\s*सेट|याद\s*दिलाओ|रिमाइंडर\s*लगाओ)',



    caseSensitive: false,



  );



  static final RegExp _testAlarmRegex = RegExp(



    r'\b(?:test\s+alarm|alarm\s+test|check\s+alarm)\b|'



    r'(?:ಅಲಾರಂ\s*ಪರೀಕ್ಷೆ|ಅಲಾರಾಂ\s*ಪರೀಕ್ಷೆ|ಅಲಾರಂ\s*ಚೆಕ್)|'



    r'(?:अलार्म\s*टेस्ट|अलार्म\s*जांचें)',



    caseSensitive: false,



  );



  static final RegExp _signOutRegex = RegExp(



    r'\b(?:sign\s*out|log\s*out|logout)\b|'



    r'(?:ನಿರ್ಗಮಿಸಿ|ಲಾಗ್\s*ಔಟ್)|'



    r'(?:लॉग\s*आउट|साइन\s*आउट)',



    caseSensitive: false,



  );



  static final RegExp _refreshRegex = RegExp(



    r'\b(?:refresh|reload|update)\b|'



    r'(?:ನವೀಕರಿಸಿ|ರಿಫ್ರೆಶ್)|'



    r'(?:रिफ्रेश|ताज़ा\s*करें)',



    caseSensitive: false,



  );



  static final RegExp _whereAmIRegex = RegExp(



    r'\b(?:where\s+am\s+i|which\s+screen|current\s+screen|what\s+page)\b|'



    r'(?:ನಾನು\s*ಎಲ್ಲಿದ್ದೇನೆ|ಯಾವ\s*ಪರದೆ|ಯಾವ\s*ಪುಟ)|'



    r'(?:मैं\s*कहाँ\s*हूँ|कौन\s*सी\s*स्क्रीन|यह\s*क्या\s*है)',



    caseSensitive: false,



  );



  static final RegExp _prescriptionModeRegex = RegExp(



    r'\b(?:prescription\s+mode|prescription|doctor\s*note|switch\s+to\s+prescription)\b|'



    r'(?:ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್|ವೈದ್ಯರ\s*ಚೀಟಿ|ಚೀಟಿ\s*ಮೋಡ್)|'



    r'(?:पर्चा|डॉक्टर\s*का\s*पर्चा|पर्चा\s*मोड)',



    caseSensitive: false,



  );



  static final RegExp _medicineModeRegex = RegExp(



    r'\b(?:medicine\s+mode|box\s+mode|switch\s+to\s+medicine|medicine\s+label)\b|'



    r'(?:ಔಷಧಿ\s*ಮೋಡ್|ಬಾಕ್ಸ್\s*ಮೋಡ್)|'



    r'(?:दवा\s*मोड|बॉक्स\s*मोड)',



    caseSensitive: false,



  );



  static final RegExp _yesRegex = RegExp(



    r'\b(?:yes|yeah|correct|okay|ok|confirm|sure|yep)\b|'



    r'(?:ಹೌದು|ಸರಿ|ಖಂಡಿತ)|'



    r'(?:हाँ|हां|ठीक|सही|अवश्य)',



    caseSensitive: false,



  );



  static final RegExp _noRegex = RegExp(



    r'\b(?:no|wrong|nope|never|incorrect)\b|'



    r'(?:ಇಲ್ಲ|ತಪ್ಪು|ಬೇಡ)|'



    r'(?:नहीं|गलत|मत\s*करो)',



    caseSensitive: false,



  );



  static final RegExp _cancelRegex = RegExp(



    r'\b(?:cancel|abort|discard|dismiss)\b|'



    r'(?:ರದ್ದು|ರದ್ದುಮಾಡಿ)|'



    r'(?:रद्द|हटाओ)',



    caseSensitive: false,



  );



  static final RegExp _deleteDuplicateRegex = RegExp(
    r'\b(?:delete|remove|clear)\s+(?:the\s+)?duplicate(?:\s+(?:medicine|tablet|med|pill)s?)?\b|'
    r'\b(?:ನಕಲಿ\s*(?:ಔಷಧಿ|ಮಾತ್ರೆ)?\s*(?:ಅಳಿಸಿ|ತೆಗೆದುಹಾಕಿ))\b|'
    r'\b(?:(?:डुप्लीकेट|नकली)\s*(?:दवा)?\s*(?:हटाएं|हटाओ|डिलीट))\b',
    caseSensitive: false,
  );

  static final RegExp _checkWarningsRegex = RegExp(
    r'\b(?:(?:check|show|view|see|read|open|tell)\s+(?:the\s+|me\s+)?(?:warnings?|side\s*effects?|adverse\s*effects?)|(?:warnings?|side\s*effects?))\b|'
    r'(?:(?:ಎಚ್ಚರಿಕೆಗಳನ್ನು?\s*(?:ತೋರಿಸಿ|ತೋರಿಸು|ಪರಿಶೀಲಿಸಿ|ಚೆಕ್)?|ಅಡ್ಡಪರಿಣಾಮಗಳು?|ಸೈಡ್\s*ಎಫೆಕ್ಟ್ಸ್?|ಮಾತ್ರೆಗಳ\s*ಅಡ್ಡಪರಿಣಾಮಗಳು?))|'
    r'(?:(?:चेतावनियां?\s*(?:दिखाएं|दिखाओ|बताएं|जांचें|चेक)?|साइड\s*इफेक्ट्स?|दुष्प्रभाव|दवा\s*के\s*साइड\s*इफेक्ट्स?))',
    caseSensitive: false,
  );

  static final RegExp _deleteAllMedicinesRegex = RegExp(
    r'\b(?:delete|clear|wipe|reset|remove)\s+(?:all\s+)?(?:data|medicines?|tablets?|meds?|everything)\b|'
    r'\b(?:ಎಲ್ಲಾ\s*(?:ಡೇಟಾ|ಔಷಧಿಗಳನ್ನು|ಮಾಹಿತಿಯನ್ನು)?\s*ಅಳಿಸಿ|ಎಲ್ಲವನ್ನು\s*ಅಳಿಸಿ)\b|'
    r'\b(?:(?:सारा|सभी)\s*(?:डेटा|दवाएं|दवाओं)\s*(?:हटाएं|हटाओ|साफ\s*करें)|सब\s*कुछ\s*हटाएं)\b',
    caseSensitive: false,
  );
  static final RegExp _deleteWarningMedicineRegex = RegExp(
    r'\b(?:delete|remove|clear)\s+(?:the\s+)?(?:warning|warned|side\s*effects?)\s+(?:medicine|tablet|med|pill)s?\b|'
    r'\b(?:(?:ಎಚ್ಚರಿಕೆ|ಅಡ್ಡಪರಿಣಾಮದ?)\s*(?:ಔಷಧಿ|ಮಾತ್ರೆ)?\s*(?:ಅಳಿಸಿ|ತೆಗೆದುಹಾಕಿ))\b|'
    r'\b(?:(?:चेतावनी|साइड\s*इफेक्ट)\s*(?:वाली)?\s*(?:दवा)?\s*(?:हटाएं|हटाओ|डिलीट))\b',
    caseSensitive: false,
  );

  static final RegExp _safetyCheckRegex = RegExp(
    r'(?:(?:run|start|do|perform|launch)\s+)?(?:the\s+)?(?:safety\s*check|medicine\s*safety|check\s*safety|safety\s*test)\b|'
    r'\b(?:safety\s*check|check\s*(?:my\s*)?medicines?|medicine\s*safety)\b|'
    r'(?:(?:ಸುರಕ್ಷತಾ\s*ತಪಾಸಣೆ|ಸುರಕ್ಷತೆ(?:\s*ಪರಿಶೀಲಿಸಿ|\s*ಚೆಕ್)?))|'
    r'(?:(?:सुरक्षा\s*(?:जाँच|जांच|चेक)))',
    caseSensitive: false,
  );

  static final RegExp _snoozeRegex = RegExp(



    r'\b(?:snooze|later|remind\s+(?:me\s+)?later|remind\s+in\s+10\s+minutes?)\b|'



    r'(?:ಸ್ನೂಜ್|ನಂತರ|ಹತ್ತು\s*ನಿಮಿಷ\s*ಬಿಟ್ಟು)|'



    r'(?:स्नूज़|स्नूज|बाद\s*में|१०\s*मिनट\s*बाद)',



    caseSensitive: false,



  );



  /// Smart normalization: removes punctuation, excess spaces, and lowercases



  static String normalize(String text) {



    return text



        .toLowerCase()



        .replaceAll(RegExp(r'''[!?,.:;"'()\[\]{}<>/\\|@#$%^&*~`_+=—–\-]'''), ' ')



        .replaceAll(RegExp(r'\s+'), ' ')



        .trim();



  }



  // Pre-compiled fast O(1) lookup tables initialized once for zero matching latency



  static final Map<String, VoiceIntent> _exactLookup = _buildExactLookup();



  static final List<MapEntry<String, VoiceIntent>> _sortedPhrases = _buildSortedPhrases();



  static Map<String, VoiceIntent> _buildExactLookup() {



    final map = <String, VoiceIntent>{};



    for (final entry in _phrases.entries) {



      for (final phrase in entry.value) {



        final norm = normalize(phrase);



        if (norm.isNotEmpty) {



          map.putIfAbsent(norm, () => entry.key);



        }



      }



    }



    return map;



  }



  static List<MapEntry<String, VoiceIntent>> _buildSortedPhrases() {



    final list = <MapEntry<String, VoiceIntent>>[];



    for (final entry in _phrases.entries) {



      for (final phrase in entry.value) {



        final norm = normalize(phrase);



        if (norm.isNotEmpty) {



          list.add(MapEntry(norm, entry.key));



        }



      }



    }



    // Sort descending by length so longest specific phrases match first



    list.sort((a, b) => b.key.length.compareTo(a.key.length));



    return list;



  }



  // Debounce & deduplication tracker to prevent duplicate executions from streaming partials



  static VoiceIntent? _lastExecutedIntent;



  static int _lastExecutionTimestamp = 0;



  static bool shouldDebounce(VoiceIntent intent, {int debounceMs = 1200}) {



    final now = DateTime.now().millisecondsSinceEpoch;



    if (_lastExecutedIntent == intent && (now - _lastExecutionTimestamp) < debounceMs) {



      return true;



    }



    return false;



  }



  static void recordExecution(VoiceIntent intent) {



    _lastExecutedIntent = intent;



    _lastExecutionTimestamp = DateTime.now().millisecondsSinceEpoch;



  }



  static void resetDebounce() {



    _lastExecutedIntent = null;



    _lastExecutionTimestamp = 0;



  }



  /// High-accuracy matching engine with zero latency, sentence scanning,



  /// multi-language support (English, Kannada, Hindi), and compound phrase resolution.



  static VoiceIntent? matchIntent(String transcript) {



    final clean = normalize(transcript);



    if (clean.isEmpty) return null;



    // 1. Direct O(1) hash map lookup for exact phrase matches (<50 microseconds)



    final exact = _exactLookup[clean];



    if (exact != null) {



      return exact;



    }



    // 2. Scan all regex matches across the string to support natural sentences,



    // single words, and compound commands (e.g. "open home open the scan" -> scan).



    final List<_IntentCandidate> candidates = [];



    void check(VoiceIntent intent, RegExp regex) {



      for (final match in regex.allMatches(clean)) {



        candidates.add(_IntentCandidate(intent, match.start, match.end - match.start));



      }



    }



    check(VoiceIntent.langKn, _langKnRegex);



    check(VoiceIntent.langHi, _langHiRegex);



    check(VoiceIntent.langEn, _langEnRegex);



    check(VoiceIntent.sendMail, _sendMailRegex);



    check(VoiceIntent.emergency, _emergencyRegex);



    check(VoiceIntent.callAmbulance, _ambulanceRegex);



    check(VoiceIntent.callCaregiver, _caregiverRegex);



    check(VoiceIntent.stop, _stopRegex);



    check(VoiceIntent.takePhoto, _takePhotoRegex);



    check(VoiceIntent.uploadPhoto, _uploadPhotoRegex);



    check(VoiceIntent.markTaken, _markTakenRegex);



    check(VoiceIntent.skipDose, _skipDoseRegex);



    check(VoiceIntent.back, _backRegex);



    check(VoiceIntent.readPage, _readPageRegex);



    check(VoiceIntent.repeat, _repeatRegex);



    check(VoiceIntent.save, _saveRegex);



    check(VoiceIntent.nextMedicine, _nextMedicineRegex);



    check(VoiceIntent.demoLogin, _demoRegex);



    check(VoiceIntent.testAlarm, _testAlarmRegex);



    check(VoiceIntent.setAlarm, _setAlarmRegex);



    check(VoiceIntent.signOut, _signOutRegex);



    check(VoiceIntent.refresh, _refreshRegex);



    check(VoiceIntent.whereAmI, _whereAmIRegex);



    check(VoiceIntent.help, _helpRegex);



    check(VoiceIntent.prescriptionMode, _prescriptionModeRegex);



    check(VoiceIntent.medicineMode, _medicineModeRegex);



    check(VoiceIntent.yes, _yesRegex);



    check(VoiceIntent.no, _noRegex);



    check(VoiceIntent.cancel, _cancelRegex);



    check(VoiceIntent.snooze, _snoozeRegex);



    check(VoiceIntent.noiseCancelOn, _noiseCancelOnRegex);



    check(VoiceIntent.noiseCancelOff, _noiseCancelOffRegex);



    check(VoiceIntent.continuousVoiceOn, _continuousVoiceOnRegex);



    check(VoiceIntent.continuousVoiceOff, _continuousVoiceOffRegex);



    // Primary navigation intents



    check(VoiceIntent.deleteDuplicate, _deleteDuplicateRegex);
    check(VoiceIntent.safetyCheck, _safetyCheckRegex);
    check(VoiceIntent.deleteAllMedicines, _deleteAllMedicinesRegex);
    check(VoiceIntent.deleteWarningMedicine, _deleteWarningMedicineRegex);
    check(VoiceIntent.checkWarnings, _checkWarningsRegex);

    check(VoiceIntent.home, _homeRegex);



    check(VoiceIntent.scan, _scanRegex);



    check(VoiceIntent.schedule, _scheduleRegex);



    check(VoiceIntent.assistant, _assistantRegex);



    check(VoiceIntent.more, _settingsRegex);



    if (candidates.isNotEmpty) {



      // 1. Discard sub-matches that are completely enclosed within a longer match span



      // (e.g. prevent internal keywords like 'pill' from overriding 'i took my pill')



      candidates.removeWhere((c) {



        return candidates.any((other) =>



            other != c &&



            other.length > c.length &&



            c.startIndex >= other.startIndex &&



            (c.startIndex + c.length) <= (other.startIndex + other.length));



      });



      // 2. Sort primarily by highest startIndex (the latest independent command takes precedence)



      // Ties broken by match length (more specific pattern wins)



      candidates.sort((a, b) {



        final cmp = b.startIndex.compareTo(a.startIndex);



        if (cmp != 0) return cmp;



        return b.length.compareTo(a.length);



      });



      return candidates.first.intent;



    }



    // 3. Fallback: Pre-sorted phrase matching with word-boundary protection



    for (final entry in _sortedPhrases) {



      final phrase = entry.key;



      if (phrase.contains(' ') || phrase.length > 5) {



        if (RegExp(r'(?:^|\s)' + RegExp.escape(phrase) + r'(?:$|\s)').hasMatch(clean)) {



          return entry.value;



        }



      } else {



        if (clean == phrase ||



            clean == "open $phrase" ||



            clean == "go to $phrase" ||



            clean == "show $phrase") {



          return entry.value;



        }



      }



    }



    return null;



  }



  /// Converts an intent name string into a VoiceIntent enum value (case-insensitive)



  static VoiceIntent? fromName(String? name) {



    if (name == null || name.trim().isEmpty) return null;



    final clean = name.trim().toLowerCase();



    for (final v in VoiceIntent.values) {



      if (v.name.toLowerCase() == clean) return v;



    }



    return null;



  }



  /// Measures exact match execution time in microseconds for diagnostic benchmarking



  static MatchResult matchIntentWithMetrics(String transcript) {



    final sw = Stopwatch()..start();



    final intent = matchIntent(transcript);



    sw.stop();



    return MatchResult(



      intent: intent,



      executionMicroseconds: sw.elapsedMicroseconds,



      transcript: transcript,



    );



  }



}



class MatchResult {



  final VoiceIntent? intent;



  final int executionMicroseconds;



  final String transcript;



  MatchResult({



    required this.intent,



    required this.executionMicroseconds,



    required this.transcript,



  });



}



