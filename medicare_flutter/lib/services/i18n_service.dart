class I18nService {
  static const Map<String, Map<String, String>> _translations = {
    'en-US': {
      'app.name': 'SmartMediCare',
      'nav.home': 'Home',
      'nav.scan': 'Scan',
      'nav.schedule': 'Schedule',
      'nav.assistant': 'Assistant',
      'nav.more': 'Settings',
      'nav.emergency': 'Emergency',
      'common.repeat': 'Repeat that',
      'common.save': 'Save',
      'common.delete': 'Delete',
      'common.cancel': 'Cancel',

      'home.hello': 'Hello {name}',
      'home.welcome': 'Welcome to SmartMediCare',
      'home.empty': 'No medicines scheduled for today.',
      'home.emptySub': "Tap Scan below or say 'Scan' to add a medicine label.",
      'home.scanCta': 'Scan Medicine',
      'home.today': 'TODAY',
      'home.alerts': 'SAFETY ALERTS',
      'home.doses': '{count} Doses',
      'home.todaysSchedule': "TODAY'S SCHEDULE",
      'home.allSchedules': 'All Schedules',
      'home.markTaken': 'MARK TAKEN',
      'home.skip': 'SKIP',
      'home.completedFor': 'Completed for {time}',
      'home.sos': 'SOS',
      'home.listening': 'Listening...',
      'home.iAmListening': 'I am listening.',
      'medicines.title': 'SAVED MEDICINES',

      'scan.title': 'Scan',
      'scan.subtitle': 'Point camera at label or upload photo',
      'scan.instruction': 'Point camera at label or upload photo',
      'scan.medicine': 'Medicine box',
      'scan.prescription': 'Prescription',
      'scan.takePhoto': 'Take photo',
      'scan.uploadPhoto': 'Upload photo',
      'scan.reading': 'Reading…',
      'scan.intro': 'Scan screen. Tap the camera button to take a photo, or the upload button to choose a photo from your phone. I will read the details back to you.',
      'scan.ready': 'Ready when you are. Hold the pack steady in good light.',
      'scan.readingMedicine': 'Reading your medicine label. Please hold on.',
      'scan.readingPrescription': 'Reading your prescription. Please hold on.',
      'scan.notAnImage': 'That file is not a photo. Please choose an image.',
      'scan.photoChosen': 'Photo chosen. Reading it now.',
      'scan.failed': 'I could not read that photo. Please try again.',
      'scan.whatIRead': 'What I read',
      'scan.notReadable': 'Not readable',
      'scan.times': 'Reminder times (24-hour, comma separated)',
      'scan.saveMedicine': 'Save medicine and reminders',
      'scan.medicinesFound': 'Medicines found',
      'scan.noMedicines': 'No medicines could be read. Try another photo.',
      'scan.saveAll': 'Save all and create schedules',
      'scan.saveFailed': 'Saving failed. Please try again.',
      'scan.field.name': 'Name',
      'scan.field.strength': 'Strength',
      'scan.field.form': 'Form',
      'scan.field.dose': 'Dose',
      'scan.field.expiry': 'Expiry',
      'scan.field.instructions': 'Instructions',

      'status.taken': 'TAKEN',
      'status.missed': 'MISSED',
      'status.skipped': 'SKIPPED',
      'status.due': 'DUE NOW',
      'status.upcoming': 'UPCOMING',

      'voice.listening': 'Listening...',
      'voice.thinking': 'Thinking...',
      'voice.notSupported': 'Voice input not supported',
      'voice.noKey': 'AI is not configured. Please add your API Key in Settings.',
      'voice.unrecognized': "I didn't catch that command. You can say Home, Scan, Schedule, or Emergency.",
      'voice.alarmSetup': 'Voice Alarm Setup',
      'voice.alarmListening': 'Listening for medicine details...',
      'voice.cancelSetup': 'CANCEL SETUP',

      'emergency.title': 'EMERGENCY SOS',
      'emergency.help': 'EMERGENCY HELP',
      'emergency.desc': 'Tapping the button below will send your GPS location to your contact and start a call.',
      'emergency.sendSos': 'SEND SOS NOW',
      'emergency.goBack': 'Go Back',
      'emergency.call': 'Call {name}',
      'emergency.calling': 'Calling for help now.',

      'settings.title': 'Settings & Profile',
      'settings.language': 'APP LANGUAGE',
      'settings.ai': 'AI VISION & SCANNING',
      'settings.smartVision': 'Smart Vision Recognition',
      'settings.aiDesc': 'AI medicine scanner is active with smart recognition fallback. Optionally enter your Gemini or Lovable API Key below for live cloud vision.',
      'settings.apiKeyLabel': 'Gemini / Lovable API Key (Optional)',
      'settings.saveKey': 'SAVE KEY',
      'settings.safety': 'SAFETY',
      'settings.runSafety': 'RUN SAFETY CHECK',
      'settings.emergencyContact': 'EMERGENCY CONTACT',
      'settings.contactName': 'Contact Name',
      'settings.phoneNumber': 'Phone Number',
      'settings.email': 'Email / Gmail',
      'settings.saveContact': 'SAVE CONTACT',
      'settings.caregivers': 'CAREGIVERS',
      'settings.manageCaregivers': 'MANAGE CAREGIVERS',
      'settings.signOut': 'SIGN OUT',

      'schedule.title': 'Daily Schedule',
      'schedule.empty': 'No doses scheduled for today.',
    },
    'kn-IN': {
      'app.name': 'ಸ್ಮಾರ್ಟ್‌ಮೆಡಿಕೇರ್',
      'nav.home': 'ಮುಖಪುಟ',
      'nav.scan': 'ಸ್ಕ್ಯಾನ್',
      'nav.schedule': 'ವೇಳಾಪಟ್ಟಿ',
      'nav.assistant': 'ಸಹಾಯಕ',
      'nav.more': 'ಸೆಟ್ಟಿಂಗ್ಸ್',
      'nav.emergency': 'ತುರ್ತು',
      'common.repeat': 'ಮತ್ತೆ ಹೇಳಿ',
      'common.save': 'ಉಳಿಸಿ',
      'common.delete': 'ಅಳಿಸಿ',
      'common.cancel': 'ರದ್ದುಮಾಡಿ',

      'home.hello': 'ನಮಸ್ಕಾರ {name}',
      'home.welcome': 'ಸ್ಮಾರ್ಟ್ ಮೆಡಿಕೇರ್ ಗೆ ಸ್ವಾಗತ',
      'home.empty': 'ಇಂದು ಯಾವುದೇ ಔಷಧಿ ನಿಗದಿಯಾಗಿಲ್ಲ.',
      'home.emptySub': "ಔಷಧಿ ಲೇಬಲ್ ಸೇರಿಸಲು ಕೆಳಗಿನ ಸ್ಕ್ಯಾನ್ ಒತ್ತಿ ಅಥವಾ 'ಸ್ಕ್ಯಾನ್' ಎಂದು ಹೇಳಿ.",
      'home.scanCta': 'ಔಷಧಿ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
      'home.today': 'ಇಂದು',
      'home.alerts': 'ಸುರಕ್ಷತಾ ಎಚ್ಚರಿಕೆಗಳು',
      'home.doses': '{count} ಡೋಸ್‌ಗಳು',
      'home.todaysSchedule': 'ಇಂದಿನ ವೇಳಾಪಟ್ಟಿ',
      'home.allSchedules': 'ಎಲ್ಲಾ ವೇಳಾಪಟ್ಟಿಗಳು',
      'home.markTaken': 'ತೆಗೆದುಕೊಂಡೆ',
      'home.skip': 'ಬಿಟ್ಟುಬಿಡಿ',
      'home.completedFor': '{time} ಕ್ಕೆ ಪೂರ್ಣಗೊಂಡಿದೆ',
      'home.sos': 'ತುರ್ತು',
      'home.listening': 'ಕೇಳಿಸಿಕೊಳ್ಳುತ್ತಿದ್ದೇನೆ...',
      'home.iAmListening': 'ನಾನು ಕೇಳಿಸಿಕೊಳ್ಳುತ್ತಿದ್ದೇನೆ.',
      'medicines.title': 'ಉಳಿಸಿದ ಔಷಧಿಗಳು',

      'scan.title': 'ಸ್ಕ್ಯಾನ್',
      'scan.subtitle': 'ಕ್ಯಾಮರಾವನ್ನು ಲೇಬಲ್‌ಗೆ ತೋರಿಸಿ ಅಥವಾ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
      'scan.instruction': 'ಕ್ಯಾಮರಾವನ್ನು ಲೇಬಲ್‌ಗೆ ತೋರಿಸಿ',
      'scan.medicine': 'ಔಷಧಿ ಪೆಟ್ಟಿಗೆ',
      'scan.prescription': 'ಚೀಟಿ',
      'scan.takePhoto': 'ಫೋಟೋ ತೆಗೆಯಿರಿ',
      'scan.uploadPhoto': 'ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
      'scan.reading': 'ಓದುತ್ತಿದ್ದೇನೆ…',
      'scan.intro': 'ಸ್ಕ್ಯಾನ್ ಸ್ಕ್ರೀನ್. ಫೋಟೋ ತೆಗೆಯಲು ಕ್ಯಾಮೆರಾ ಬಟನ್ ಒತ್ತಿ, ಅಥವಾ ಫೋನ್‌ನಿಂದ ಆಯ್ಕೆ ಮಾಡಲು ಅಪ್‌ಲೋಡ್ ಬಟನ್ ಒತ್ತಿ.',
      'scan.ready': 'ಸಿದ್ಧವಾಗಿದೆ. ಉತ್ತಮ ಬೆಳಕಿನಲ್ಲಿ ಪ್ಯಾಕ್ ಹಿಡಿದುಕೊಳ್ಳಿ.',
      'scan.readingMedicine': 'ನಿಮ್ಮ ಔಷಧಿ ಲೇಬಲ್ ಓದುತ್ತಿದ್ದೇನೆ. ದಯವಿಟ್ಟು ಕಾಯಿರಿ.',
      'scan.readingPrescription': 'ನಿಮ್ಮ ಚೀಟಿ ಓದುತ್ತಿದ್ದೇನೆ. ದಯವಿಟ್ಟು ಕಾಯಿರಿ.',
      'scan.notAnImage': 'ಆ ಫೈಲ್ ಫೋಟೋ ಅಲ್ಲ.',
      'scan.photoChosen': 'ಫೋಟೋ ಆಯ್ಕೆಯಾಗಿದೆ. ಈಗ ಓದುತ್ತಿದ್ದೇನೆ.',
      'scan.failed': 'ಫೋಟೋ ಓದಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'scan.whatIRead': 'ನಾನು ಓದಿದ್ದು',
      'scan.notReadable': 'ಓದಲು ಸಾಧ್ಯವಿಲ್ಲ',
      'scan.times': 'ಜ್ಞಾಪನೆ ಸಮಯಗಳು (24-ಗಂಟೆ)',
      'scan.saveMedicine': 'ಔಷಧಿ ಮತ್ತು ಜ್ಞಾಪನೆಗಳನ್ನು ಉಳಿಸಿ',
      'scan.medicinesFound': 'ಕಂಡುಬಂದ ಔಷಧಿಗಳು',
      'scan.noMedicines': 'ಯಾವುದೇ ಔಷಧಿ ಕಂಡುಬಂದಿಲ್ಲ.',
      'scan.saveAll': 'ಎಲ್ಲವನ್ನೂ ಉಳಿಸಿ',
      'scan.saveFailed': 'ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ.',
      'scan.field.name': 'ಹೆಸರು',
      'scan.field.strength': 'ಸಾಮರ್ಥ್ಯ',
      'scan.field.form': 'ರೂಪ',
      'scan.field.dose': 'ಡೋಸ್',
      'scan.field.expiry': 'ಮುಕ್ತಾಯ',
      'scan.field.instructions': 'ಸೂಚನೆಗಳು',

      'status.taken': 'ತೆಗೆದುಕೊಂಡಿದೆ',
      'status.missed': 'ತಪ್ಪಿದೆ',
      'status.skipped': 'ಬಿಡಲಾಗಿದೆ',
      'status.due': 'ಈಗ ಸಮಯ',
      'status.upcoming': 'ಮುಂದಿನದು',

      'voice.listening': 'ಕೇಳಿಸಿಕೊಳ್ಳುತ್ತಿದ್ದೇನೆ...',
      'voice.thinking': 'ಆಲೋಚಿಸುತ್ತಿದ್ದೇನೆ...',
      'voice.notSupported': 'ಧ್ವನಿ ಇನ್ಪುಟ್ ಬೆಂಬಲಿತವಾಗಿಲ್ಲ',
      'voice.noKey': 'AI ಕಾನ್ಫಿಗರ್ ಮಾಡಲಾಗಿಲ್ಲ.',
      'voice.unrecognized': 'ಆಜ್ಞೆ ಅರ್ಥವಾಗಲಿಲ್ಲ. ನೀವು ಮುಖಪುಟ, ಸ್ಕ್ಯಾನ್, ವೇಳಾಪಟ್ಟಿ ಅಥವಾ ತುರ್ತು ಎಂದು ಹೇಳಬಹುದು.',
      'voice.alarmSetup': 'ಧ್ವನಿ ಅಲಾರಂ ಸೆಟಪ್',
      'voice.alarmListening': 'ಔಷಧಿ ವಿವರಗಳಿಗಾಗಿ ಕೇಳಿಸಿಕೊಳ್ಳುತ್ತಿದ್ದೇನೆ...',
      'voice.cancelSetup': 'ರದ್ದುಮಾಡಿ',

      'emergency.title': 'ತುರ್ತು SOS',
      'emergency.help': 'ತುರ್ತು ಸಹಾಯ',
      'emergency.desc': 'ಕೆಳಗಿನ ಬಟನ್ ಒತ್ತಿದರೆ ನಿಮ್ಮ GPS ಸ್ಥಳವನ್ನು ನಿಮ್ಮ ಸಂಪರ್ಕಕ್ಕೆ ಕಳುಹಿಸಲಾಗುತ್ತದೆ ಮತ್ತು ಕರೆ ಮಾಡಲಾಗುತ್ತದೆ.',
      'emergency.sendSos': 'ಈಗಲೇ SOS ಕಳುಹಿಸಿ',
      'emergency.goBack': 'ಹಿಂದಕ್ಕೆ ಹೋಗಿ',
      'emergency.call': '{name} ಅವರಿಗೆ ಕರೆ ಮಾಡಿ',
      'emergency.calling': 'ಸಹಾಯಕ್ಕಾಗಿ ಕರೆ ಮಾಡುತ್ತಿದ್ದೇನೆ.',

      'settings.title': 'ಸೆಟ್ಟಿಂಗ್ಸ್ ಮತ್ತು ಪ್ರೊಫೈಲ್',
      'settings.language': 'ಅಪ್ಲಿಕೇಶನ್ ಭಾಷೆ',
      'settings.ai': 'AI ದೃಷ್ಟಿ ಮತ್ತು ಸ್ಕ್ಯಾನಿಂಗ್',
      'settings.smartVision': 'ಸ್ಮಾರ್ಟ್ ವಿಷನ್ ಗುರುತಿಸುವಿಕೆ',
      'settings.aiDesc': 'AI ಔಷಧಿ ಸ್ಕ್ಯಾನರ್ ಸಕ್ರಿಯವಾಗಿದೆ.',
      'settings.apiKeyLabel': 'ಜೆಮಿನಿ API ಕೀ (ಐಚ್ಛಿಕ)',
      'settings.saveKey': 'ಕೀಲಿ ಉಳಿಸಿ',
      'settings.safety': 'ಸುರಕ್ಷತೆ',
      'settings.runSafety': 'ಸುರಕ್ಷತಾ ತಪಾಸಣೆ ನಡೆಸಿ',
      'settings.emergencyContact': 'ತುರ್ತು ಸಂಪರ್ಕ',
      'settings.contactName': 'ಸಂಪರ್ಕ ಹೆಸರು',
      'settings.phoneNumber': 'ದೂರವಾಣಿ ಸಂಖ್ಯೆ',
      'settings.email': 'ಇಮೇಲ್ / ಜಿಮೇಲ್',
      'settings.saveContact': 'ಸಂಪರ್ಕ ಉಳಿಸಿ',
      'settings.caregivers': 'ಆರೈಕೆದಾರರು',
      'settings.manageCaregivers': 'ಆರೈಕೆದಾರರನ್ನು ನಿರ್ವಹಿಸಿ',
      'settings.signOut': 'ಸೈನ್ ಔಟ್',

      'schedule.title': 'ದೈನಂದಿನ ವೇಳಾಪಟ್ಟಿ',
      'schedule.empty': 'ಇಂದು ಯಾವುದೇ ಡೋಸ್‌ಗಳು ನಿಗದಿಯಾಗಿಲ್ಲ.',
    },
    'hi-IN': {
      'app.name': 'स्मार्टमेडिकेयर',
      'nav.home': 'होम',
      'nav.scan': 'स्कैन',
      'nav.schedule': 'अनुसूची',
      'nav.assistant': 'सहायक',
      'nav.more': 'सेटिंग्स',
      'nav.emergency': 'आपातकाल',
      'common.repeat': 'फिर से बोलें',
      'common.save': 'सहेजें',
      'common.delete': 'हटाएं',
      'common.cancel': 'रद्द करें',

      'home.hello': 'नमस्ते {name}',
      'home.welcome': 'स्मार्ट मेडिकेयर में आपका स्वागत है',
      'home.empty': 'आज कोई दवा निर्धारित नहीं है।',
      'home.emptySub': 'दवा का लेबल जोड़ने के लिए नीचे स्कैन दबाएं या "स्कैन" बोलें।',
      'home.scanCta': 'दवा स्कैन करें',
      'home.today': 'आज',
      'home.alerts': 'सुरक्षा चेतावनियाँ',
      'home.doses': '{count} खुराकें',
      'home.todaysSchedule': 'आज की समय-सारणी',
      'home.allSchedules': 'सभी समय-सारणी',
      'home.markTaken': 'ले ली',
      'home.skip': 'छोड़ें',
      'home.completedFor': '{time} पर पूरी हुई',
      'home.sos': 'आपातकाल',
      'home.listening': 'सुन रहा हूँ...',
      'home.iAmListening': 'मैं सुन रहा हूँ।',
      'medicines.title': 'सहेजी गई दवाएं',

      'scan.title': 'स्कैन',
      'scan.subtitle': 'कैमरा लेबल की ओर रखें या फोटो अपलोड करें',
      'scan.instruction': 'कैमरा लेबल की ओर रखें',
      'scan.medicine': 'दवा का डिब्बा',
      'scan.prescription': 'पर्चा',
      'scan.takePhoto': 'फोटो लें',
      'scan.uploadPhoto': 'फोटो अपलोड करें',
      'scan.reading': 'पढ़ रहा हूँ…',
      'scan.intro': 'स्कैन स्क्रीन। फोटो लेने के लिए कैमरा बटन दबाएं, या अपने फोन से चुनने के लिए अपलोड बटन दबाएं।',
      'scan.ready': 'तैयार है। अच्छी रोशनी में दवा रखें।',
      'scan.readingMedicine': 'दवा का लेबल पढ़ रहा हूँ। कृपया प्रतीक्षा करें।',
      'scan.readingPrescription': 'पर्चा पढ़ रहा हूँ। कृपया प्रतीक्षा करें।',
      'scan.notAnImage': 'यह फोटो नहीं है।',
      'scan.photoChosen': 'फोटो चुन ली गई है। अब पढ़ रहा हूँ।',
      'scan.failed': 'फोटो नहीं पढ़ी जा सकी। कृपया पुनः प्रयास करें।',
      'scan.whatIRead': 'जो मैंने पढ़ा',
      'scan.notReadable': 'पठनीय नहीं',
      'scan.times': 'रिमाइंडर का समय (24 घंटे)',
      'scan.saveMedicine': 'दवा और रिमाइंडर सहेजें',
      'scan.medicinesFound': 'मिली हुई दवाएं',
      'scan.noMedicines': 'कोई दवा नहीं मिली।',
      'scan.saveAll': 'सभी दवाएं सहेजें',
      'scan.saveFailed': 'सहेजना विफल रहा।',
      'scan.field.name': 'नाम',
      'scan.field.strength': 'मात्रा',
      'scan.field.form': 'प्रकार',
      'scan.field.dose': 'खुराक',
      'scan.field.expiry': 'समाप्ति तिथि',
      'scan.field.instructions': 'निर्देश',

      'status.taken': 'ले ली',
      'status.missed': 'छूटी',
      'status.skipped': 'छोड़ी गई',
      'status.due': 'अभी लेनी है',
      'status.upcoming': 'आने वाली',

      'voice.listening': 'सुन रहा हूँ...',
      'voice.thinking': 'सोच रहा हूँ...',
      'voice.notSupported': 'वॉयस इनपुट समर्थित नहीं है',
      'voice.noKey': 'एआई कॉन्फ़िगर नहीं है।',
      'voice.unrecognized': 'आदेश समझ नहीं आया। आप होम, स्कैन, शेड्यूल या आपातकाल बोल सकते हैं।',
      'voice.alarmSetup': 'वॉयस अलार्म सेटअप',
      'voice.alarmListening': 'दवा के विवरण के लिए सुन रहा हूँ...',
      'voice.cancelSetup': 'रद्द करें',

      'emergency.title': 'आपातकालीन SOS',
      'emergency.help': 'आपातकालीन मदद',
      'emergency.desc': 'नीचे दिया गया बटन दबाने पर आपका जीपीएस स्थान संपर्क को भेजा जाएगा और कॉल की जाएगी।',
      'emergency.sendSos': 'अभी SOS भेजें',
      'emergency.goBack': 'वापस जाएं',
      'emergency.call': '{name} को कॉल करें',
      'emergency.calling': 'मदद के लिए कॉल कर रहा हूँ।',

      'settings.title': 'सेटिंग्स और प्रोफ़ाइल',
      'settings.language': 'ऐप की भाषा',
      'settings.ai': 'एआई विज़न और स्कैनिंग',
      'settings.smartVision': 'स्मार्ट विज़न पहचान',
      'settings.aiDesc': 'एआई दवा स्कैनर सक्रिय है।',
      'settings.apiKeyLabel': 'जेमिनी एपीआई कुंजी (वैकल्पिक)',
      'settings.saveKey': 'कुंजी सहेजें',
      'settings.safety': 'सुरक्षा',
      'settings.runSafety': 'सुरक्षा जाँच चलाएं',
      'settings.emergencyContact': 'आपातकालीन संपर्क',
      'settings.contactName': 'संपर्क नाम',
      'settings.phoneNumber': 'फ़ोन नंबर',
      'settings.email': 'ईमेल / जीमेल',
      'settings.saveContact': 'संपर्क सहेजें',
      'settings.caregivers': 'देखभालकर्ता',
      'settings.manageCaregivers': 'देखभालकर्ताओं को प्रबंधित करें',
      'settings.signOut': 'साइन आउट',

      'schedule.title': 'दैनिक समय-सारणी',
      'schedule.empty': 'आज कोई खुराक निर्धारित नहीं है।',
    }
  };

  String translate(String key, String lang, {Map<String, String>? vars}) {
    String text = _translations[lang]?[key] ?? _translations['en-US']?[key] ?? key;
    if (vars != null) {
      vars.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }

  String normalizeLocale(String? lang) {
    if (lang == null || lang.isEmpty) return 'en-US';
    if (lang.startsWith('kn')) return 'kn-IN';
    if (lang.startsWith('hi')) return 'hi-IN';
    return 'en-US';
  }

  String localizeDigits(String text, String? lang) {
    if (lang == null) return text;
    if (lang.startsWith('kn')) {
      const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const knDigits = ['೦', '೧', '೨', '೩', '೪', '೫', '೬', '೭', '೮', '೯'];
      var res = text;
      for (int i = 0; i < 10; i++) {
        res = res.replaceAll(enDigits[i], knDigits[i]);
      }
      return res;
    }
    return text;
  }

  String localizePurpose(String purpose, String? lang) {
    if (purpose.trim().isEmpty) return "";
    final l = normalizeLocale(lang);
    if (l == 'en-US') return purpose;

    final lower = purpose.toLowerCase();
    if (l == 'kn-IN') {
      if (lower.contains('fever') || lower.contains('pain') || lower.contains('headache')) {
        return "ಜ್ವರ, ತಲೆನೋವು ಮತ್ತು ಮೈ-ಕೈ ನೋವು ನಿವಾರಣೆ";
      }
      if (lower.contains('acid') || lower.contains('heartburn') || lower.contains('gerd') || lower.contains('gas')) {
        return "ಅಸಿಡಿಟಿ, ಎದೆಯುರಿ ಮತ್ತು ಗ್ಯಾಸ್ ನಿವಾರಣೆ";
      }
      if (lower.contains('diabet') || lower.contains('sugar') || lower.contains('glucose')) {
        return "ಮಧುಮೇಹದಲ್ಲಿ ರಕ್ತದ ಸಕ್ಕರೆ ಮಟ್ಟ ನಿಯಂತ್ರಣ";
      }
      if (lower.contains('blood pressure') || lower.contains('hypertension') || lower.contains(' bp')) {
        return "ರಕ್ತದೊತ್ತಡ (BP) ನಿಯಂತ್ರಣ";
      }
      if (lower.contains('cholesterol') || lower.contains('heart')) {
        return "ಕೊಲೆಸ್ಟ್ರಾಲ್ ನಿಯಂತ್ರಣ ಮತ್ತು ಹೃದಯ ರಕ್ಷಣೆ";
      }
      if (lower.contains('allerg') || lower.contains('cold') || lower.contains('cough') || lower.contains('sneeze')) {
        return "ಅಲರ್ಜಿ, ಶೀತ, ಕೆಮ್ಮು ಮತ್ತು ಸೀನುವಿಕೆ ನಿವಾರಣೆ";
      }
      if (lower.contains('infect') || lower.contains('antibiotic')) {
        return "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಣೆ";
      }
      if (lower.contains('bone') || lower.contains('calcium') || lower.contains('vitamin')) {
        return "ಮೂಳೆ ಬಲವರ್ಧನೆ ಮತ್ತು ವಿಟಮಿನ್ ಪೋಷಕಾಂಶ ಪೂರಕ";
      }
      if (lower.contains('cellular') || lower.contains('immunosuppressive') || lower.contains('growth')) {
        return "ಜೀವಕೋಶಗಳ ಅಸಹಜ ಬೆಳವಣಿಗೆ ನಿಯಂತ್ರಣ ಮತ್ತು ರೋಗನಿರೋಧಕ ಔಷಧ";
      }
    } else if (l == 'hi-IN') {
      if (lower.contains('fever') || lower.contains('pain') || lower.contains('headache')) {
        return "बुखार, सिरदर्द और बदन दर्द से राहत";
      }
      if (lower.contains('acid') || lower.contains('heartburn') || lower.contains('gerd') || lower.contains('gas')) {
        return "एसिडिटी, सीने में जलन और गैस से राहत";
      }
      if (lower.contains('diabet') || lower.contains('sugar') || lower.contains('glucose')) {
        return "डायबिटीज में ब्लड शुगर का नियंत्रण";
      }
      if (lower.contains('blood pressure') || lower.contains('hypertension') || lower.contains(' bp')) {
        return "ब्लड प्रेशर (बीपी) नियंत्रण";
      }
      if (lower.contains('cholesterol') || lower.contains('heart')) {
        return "कोलेस्ट्रॉल का नियंत्रण और हृदय सुरक्षा";
      }
      if (lower.contains('allerg') || lower.contains('cold') || lower.contains('cough') || lower.contains('sneeze')) {
        return "एलर्जी, जुकाम, खांसी और छींक से राहत";
      }
      if (lower.contains('infect') || lower.contains('antibiotic')) {
        return "बैक्टीरियल संक्रमण के इलाज के लिए";
      }
      if (lower.contains('bone') || lower.contains('calcium') || lower.contains('vitamin')) {
        return "हड्डियों की मजबूती और विटामिन पूरक";
      }
      if (lower.contains('cellular') || lower.contains('immunosuppressive') || lower.contains('growth')) {
        return "असामान्य कोशिका वृद्धि को रोकने और इम्यून सिस्टम की दवा";
      }
    }
    return purpose;
  }

  String localizeWhenToTake(String whenToTake, String? lang) {
    if (whenToTake.trim().isEmpty) return "";
    final l = normalizeLocale(lang);
    if (l == 'en-US') return whenToTake;

    final lower = whenToTake.toLowerCase();
    if (l == 'kn-IN') {
      if (lower.contains('empty stomach') || lower.contains('before breakfast') || lower.contains('before food') || lower.contains('before meals')) {
        return "ಬೆಳಿಗ್ಗೆ ಉಪಹಾರಕ್ಕಿಂತ 30 ನಿಮಿಷ ಮುಂಚೆ ಖಾಲಿ ಹೊಟ್ಟೆಯಲ್ಲಿ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ.";
      }
      if (lower.contains('bedtime') || lower.contains('night') || lower.contains('sleeping')) {
        return "ರಾತ್ರಿ ಮಲಗುವ ಮುನ್ನ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ.";
      }
      if (lower.contains('twice') || lower.contains('1-0-1') || lower.contains('morning and night') || lower.contains('morning and evening')) {
        return "ಊಟದ ನಂತರ ದಿನಕ್ಕೆ ಎರಡು ಬಾರಿ (ಬೆಳಿಗ್ಗೆ ಮತ್ತು ರಾತ್ರಿ) ತೆಗೆದುಕೊಳ್ಳಿ.";
      }
      if (lower.contains('thrice') || lower.contains('three times') || lower.contains('1-1-1')) {
        return "ಊಟದ ನಂತರ ದಿನಕ್ಕೆ ಮೂರು ಬಾರಿ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ.";
      }
      if (lower.contains('once daily') || lower.contains('same time') || lower.contains('swallow whole')) {
        return "ಪ್ರತಿದಿನ ಒಂದೇ ಸಮಯದಲ್ಲಿ 1 ಮಾತ್ರೆ ನೀರಿನೊಂದಿಗೆ ನುಂಗಿ. ಅಗಿಯಬೇಡಿ.";
      }
      if (lower.contains('after food') || lower.contains('after meals')) {
        return "ಊಟದ ನಂತರ ಒಂದು ಲೋಟ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ.";
      }
      return "ಊಟದ ನಂತರ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ.";
    } else if (l == 'hi-IN') {
      if (lower.contains('empty stomach') || lower.contains('before breakfast') || lower.contains('before food') || lower.contains('before meals')) {
        return "सुबह नाश्ते से 30 मिनट पहले खाली पेट पानी के साथ लें।";
      }
      if (lower.contains('bedtime') || lower.contains('night') || lower.contains('sleeping')) {
        return "रात को सोने से पहले पानी के साथ लें।";
      }
      if (lower.contains('twice') || lower.contains('1-0-1') || lower.contains('morning and night') || lower.contains('morning and evening')) {
        return "भोजन के बाद दिन में दो बार (सुबह और रात) लें।";
      }
      if (lower.contains('thrice') || lower.contains('three times') || lower.contains('1-1-1')) {
        return "भोजन के बाद दिन में तीन बार पानी के साथ लें।";
      }
      if (lower.contains('once daily') || lower.contains('same time') || lower.contains('swallow whole')) {
        return "रोजाना एक निश्चित समय पर 1 गोली पानी के साथ निगलें। चबाएं नहीं।";
      }
      if (lower.contains('after food') || lower.contains('after meals')) {
        return "भोजन के बाद एक गिलास पानी के साथ लें।";
      }
      return "भोजन के बाद पानी के साथ लें।";
    }
    return whenToTake;
  }

  String localizeDosage(String dosage, String? unit, String? lang) {
    if (dosage.trim().isEmpty) return "";
    final l = normalizeLocale(lang);
    if (l == 'en-US') return dosage;

    final lower = dosage.toLowerCase();
    final amountMatch = RegExp(r'(\d+(?:\.\d+)?|\b(?:one|two|three)\b)').firstMatch(lower);
    String numStr = amountMatch != null ? amountMatch.group(1)! : "1";
    if (numStr == "one") numStr = "1";
    if (numStr == "two") numStr = "2";
    if (numStr == "three") numStr = "3";

    if (l == 'kn-IN') {
      if (lower.contains('cap')) return "$numStr ಕ್ಯಾಪ್ಸುಲ್";
      if (lower.contains('syr') || lower.contains('ml')) return "$numStr ಮಿ.ಲೀ ಸಿರಪ್";
      if (lower.contains('drop')) return "$numStr ಹನಿಗಳು";
      if (lower.contains('puff')) return "$numStr ಪಫ್";
      return "$numStr ಮಾತ್ರೆ";
    } else if (l == 'hi-IN') {
      if (lower.contains('cap')) return "$numStr कैप्सूल";
      if (lower.contains('syr') || lower.contains('ml')) return "$numStr मिली सिरप";
      if (lower.contains('drop')) return "$numStr बूँदें";
      if (lower.contains('puff')) return "$numStr पफ";
      return "$numStr गोली";
    }
    return dosage;
  }

  String localizeInstructions(String instructions, String? lang) {
    if (instructions.trim().isEmpty) return "";
    final l = normalizeLocale(lang);
    if (l == 'en-US') return instructions;

    final lower = instructions.toLowerCase();
    if (l == 'kn-IN') {
      if (lower.contains('crush') || lower.contains('chew') || lower.contains('whole')) {
        return "ಮಾತ್ರೆಯನ್ನು ಪೂರ್ಣವಾಗಿ ನೀರಿನೊಂದಿಗೆ ನುಂಗಿ. ಪುಡಿಮಾಡಬೇಡಿ ಅಥವಾ ಅಗಿಯಬೇಡಿ.";
      }
      if (lower.contains('shake well')) {
        return "ಬಳಸುವ ಮುನ್ನ ಚೆನ್ನಾಗಿ ಅಲ್ಲಾಡಿಸಿ.";
      }
      if (lower.contains('external use')) {
        return "ಹೊರಗಿನ ಬಳಕೆಗೆ ಮಾತ್ರ.";
      }
      if (lower.contains('cool') || lower.contains('25') || lower.contains('light')) {
        return "ತಂಪಾದ, ಒಣ ಸ್ಥಳದಲ್ಲಿ ನೇರ ಸೂರ್ಯನ ಬೆಳಕಿನಿಂದ ದೂರವಿಡಿ.";
      }
      return "ವೈದ್ಯರ ಸಲಹೆಯಂತೆ ನೀರಿನೊಂದಿಗೆ ಸೇವಿಸಿ.";
    } else if (l == 'hi-IN') {
      if (lower.contains('crush') || lower.contains('chew') || lower.contains('whole')) {
        return "गोली को पानी के साथ पूरी तरह निगलें। इसे चबाएं या तोड़ें नहीं।";
      }
      if (lower.contains('shake well')) {
        return "उपयोग से पहले अच्छी तरह हिलाएं।";
      }
      if (lower.contains('external use')) {
        return "केवल बाहरी उपयोग के लिए।";
      }
      if (lower.contains('cool') || lower.contains('25') || lower.contains('light')) {
        return "सीधे धूप से दूर ठंडी और सूखी जगह पर रखें।";
      }
      return "डॉक्टर के निर्देशानुसार पानी के साथ लें।";
    }
    return instructions;
  }
}
