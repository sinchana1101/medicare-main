import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  /// Known common medicines & active pharmaceutical ingredients (brand and generic)
  static final List<String> _knownMedicines = [
    // Pain, Fever & Inflammation
    "Fever-X 650", "Fever-X", "Paracetamol", "Dolo 650", "Dolo", "Crocin 650", "Crocin Advance", "Crocin", 
    "Calpol 650", "Calpol 500", "Calpol", "Ibuprofen", "Combiflam", "Brufen", 
    "Aspirin", "Disprin", "Diclofenac", "Voveran", "Aceclofenac", "Zerodol-SP", 
    "Zerodol-P", "Zerodol", "Tramadol", "Ultracet", "Mefenamic Acid", "Meftal-Spas", 
    "Meftal", "Naproxen", "Piroxicam", "Ketorolac", "Nimesulide", "Morepen",
    
    // Nausea, Pregnancy, Anti-emetic & Vitamins
    "Doxinate", "Doxylamine Succinate & Pyridoxine Hydrochloride", "Doxylamine Succinate", 
    "Pyridoxine Hydrochloride", "Doxylamine", "Pyridoxine", "Pregnidoxin", "Vomikind", 
    "Perinorm", "Metoclopramide",
    
    // Antibiotics & Antivirals & Antifungals
    "Amoxicillin and Potassium Clavulanate", "Amoxicillin", "Amoxyclav", "Augmentin 625 Duo", 
    "Augmentin 625", "Augmentin", "Moxikind-CV", "Azithromycin", "Azithral 500", "Azithral", 
    "Azee 500", "Azee", "Cefixime", "Taxim-O", "Mahacef", "Ciprofloxacin", "Ciplox", 
    "Ofloxacin", "Oflox", "Levofloxacin", "Levomac", "Metronidazole", "Flagyl", 
    "Doxycycline", "Doxt-SL", "Acyclovir", "Cephalexin", "Sporidex", "Clindamycin", 
    "Clavam 625", "Bactrim", "Norfloxacin", "Norflox-TZ",
    
    // Diabetes
    "Metformin Hydrochloride", "Metformin HCl", "Metformin", "Glycomet-GP", "Glycomet 500", 
    "Glycomet", "Glimepiride", "Amaryl", "Gliclazide", "Sitagliptin", "Januvia", 
    "Vildagliptin", "Galvus", "Teneligliptin", "Dapagliflozin", "Forxiga", "Empagliflozin", 
    "Jardiance", "Insulin", "Glipizide", "Voglibose", "Pioglitazone",
    
    // Hypertension & Cardiac
    "Telmisartan", "Telma 40", "Telma-H", "Telma", "Telmikind 40", "Telmikind", 
    "Amlodipine", "Amlong 5", "Amlong", "Atenolol", "Aten 50", "Aten", "Losartan", 
    "Losar 50", "Losar", "Ramipril", "Cardace", "Enalapril", "Atorvastatin", "Atorva 20", 
    "Atorva 10", "Atorva", "Lipitor", "Rosuvastatin", "Rosuvas 10", "Rosuvas", 
    "Clopidogrel", "Clopilet", "Nebivolol", "Concor", "Bisoprolol", "Metoprolol", 
    "Betaloc", "Ecosprin 75", "Ecosprin 150", "Ecosprin",
    
    // Gastrointestinal & Antacids
    "Pantoprazole Sodium", "Pantoprazole Gastro-resistant", "Pantoprazole", "Pan 40", 
    "Pan-D", "Pantocid 40", "Pantocid", "Omeprazole", "Omez 20", "Omez-D", "Omez", 
    "Rabeprazole", "Razo 20", "Rablet 20", "Razo", "Esomeprazole", "Nexpro 40", 
    "Nexpro", "Ranitidine", "Zinetac", "Famotidine", "Domperidone", "Ondansetron", 
    "Emeset 4", "Emeset", "Digene", "Gelusil", "Cremaffin", "Duphalac", "Lactulose", 
    "Sucralfate", "Gerd-M", "Spasmo-Proxyvon",
    
    // Allergy, Respiratory & Cold
    "Cetirizine Hydrochloride", "Cetirizine", "Cetzine", "Alerid", "Levocetirizine", 
    "Levocet", "Montelukast Sodium", "Montelukast", "Montair-LC", "Montek-LC", 
    "Fexofenadine", "Allegra 120", "Allegra", "Chlorpheniramine Maleate", "Chlorpheniramine", 
    "Diphenhydramine", "Benadryl", "Dextromethorphan", "Ambroxol", "Guaifenesin", 
    "Ascoril-D", "Ascoril-LS", "Ascoril", "Grilinctus", "Asthalin", "Salbutamol", 
    "Budecort", "Budesonide", "Foracort", "Deriphyllin", "Cheston Cold", "Sinarest", 
    "Wikoryl", "Maxtra", "Alex", "Chericof",
    
    // Vitamins, Minerals & Supplements
    "Calcium Carbonate", "Calcium and Vitamin D3", "Calcium", "Shelcal 500", "Shelcal", 
    "Calcirol", "Vitamin D3", "Vitamin C", "Limcee 500", "Limcee", "Celin 500", "Celin", 
    "Vitamin B-Complex", "Becosules Z", "Becosules", "Neurobion Forte", "Neurobion", 
    "Methylcobalamin", "Cobadex CZS", "Folic Acid", "Folvite", "Zincovit", "Supradyn", 
    "Iron and Folic Acid", "Autrin", "Orofer-XT", "Livogen", "Evion 400", "Evion",
    
    // Topical & Dermatology
    "Povidone-Iodine", "Betadine", "Neosporin", "Soframycin", "Silverex", "Mupirocin", 
    "T-Bact", "Clotrimazole", "Candid", "Fluconazole", "Diflucan", "Itraconazole", 
    "Candiforce 200", "Ketoconazole", "Permethrin", "Burnol", "Volini", "Moov",
    
    // Neuro, Psychiatric, CNS & Sleep
    "Rochet", "Rocephin", "Monocef", "Ceftriaxone", "Sizodon Plus", "Sizodon", "Qutipin 50", "Qutipin 25", "Qutipin 100", "Qutipin 200", "Qutipin", 
    "Quetiapine 50mg", "Quetiapine 25mg", "Quetiapine", "Ativan 1mg", "Ativan 2mg", "Ativan", 
    "Lorazepam 1mg", "Lorazepam 2mg", "Lorazepam", "Clonazepam 0.5mg", "Clonazepam 0.25mg", "Clonazepam", 
    "Sertraline 50mg", "Sertraline 100mg", "Sertraline 25mg", "Sertraline", "Sertan 50", "Sertan", "Sertafine", 
    "Pacitane", "Trihexyphenidyl", "Risperidone", "Zapiz", "Rivotril", "Alprazolam", 
    "Restyl", "Zolfresh", "Zolpidem", "Nexito", "Escitalopram", "Sertraline", "Fluoxetine", 
    "Olanzapine", "Quetiapine", "Amisulpride", "Lithium", "Valproate", "Divalproex", 
    "Levipil", "Levetiracetam", "Phenytoin", "Gabapentin", "Pregabalin", 
    "Everbliss 5mg", "Everbliss 10mg", "Everbliss", "Everolimus 5mg", "Everolimus 10mg", "Everolimus",
    
    // Thyroid & Endocrine
    "Thyronorm", "Eltroxin", "Thyroxine Sodium", "Thyroxine",

    // Steroids & Anti-inflammatory
    "Prednisolone", "Wysolone", "Dexamethasone", "Dexona", "Methylprednisolone", 
    "Medrol", "Deflazacort", "Defcort", "Hydrocortisone",
  ];

  /// Set of proprietary brand names (prioritized over generic ingredients)
  static final Set<String> _brandMedicines = {
    "Everbliss 5mg", "Everbliss 10mg", "Everbliss",
    "Fever-X 650", "Fever-X", "Doxinate", "Dolo 650", "Dolo", "Crocin 650", "Crocin Advance", 
    "Crocin", "Calpol 650", "Calpol 500", "Calpol", "Pan 40", "Pan-D", "Pantocid 40", 
    "Pantocid", "Augmentin 625 Duo", "Augmentin 625", "Augmentin", "Moxikind-CV", "Omez 20", 
    "Omez-D", "Omez", "Cetzine", "Allegra 120", "Allegra", "Combiflam", "Brufen", "Disprin", 
    "Voveran", "Zerodol-SP", "Zerodol-P", "Zerodol", "Ultracet", "Meftal-Spas", "Meftal", 
    "Azithral 500", "Azithral", "Azee 500", "Azee", "Taxim-O", "Mahacef", "Ciplox", "Oflox", 
    "Levomac", "Flagyl", "Doxt-SL", "Sporidex", "Clavam 625", "Bactrim", "Norflox-TZ", 
    "Glycomet-GP", "Glycomet 500", "Glycomet", "Amaryl", "Januvia", "Galvus", "Forxiga", 
    "Jardiance", "Telma 40", "Telma-H", "Telma", "Telmikind 40", "Telmikind", "Amlong 5", 
    "Amlong", "Aten 50", "Aten", "Losar 50", "Losar", "Cardace", "Atorva 20", "Atorva 10", 
    "Atorva", "Lipitor", "Rosuvas 10", "Rosuvas", "Clopilet", "Concor", "Betaloc", "Ecosprin 75", 
    "Ecosprin 150", "Ecosprin", "Razo 20", "Rablet 20", "Razo", "Nexpro 40", "Nexpro", 
    "Zinetac", "Emeset 4", "Emeset", "Digene", "Gelusil", "Cremaffin", "Duphalac", "Alerid", 
    "Levocet", "Montair-LC", "Montek-LC", "Ascoril-D", "Ascoril-LS", "Ascoril", "Grilinctus", 
    "Asthalin", "Budecort", "Foracort", "Deriphyllin", "Cheston Cold", "Sinarest", "Wikoryl", 
    "Alex", "Chericof", "Shelcal 500", "Shelcal", "Calcirol", "Limcee 500", "Limcee", 
    "Celin 500", "Celin", "Becosules Z", "Becosules", "Neurobion Forte", "Neurobion", 
    "Folvite", "Zincovit", "Supradyn", "Autrin", "Orofer-XT", "Livogen", "Evion 400", "Evion", 
    "Betadine", "Neosporin", "Soframycin", "Silverex", "T-Bact", "Candid", "Diflucan", 
    "Candiforce 200", "Burnol", "Volini", "Moov", "Wysolone", "Dexona", "Medrol", "Defcort",
    "Pregnidoxin", "Vomikind", "Perinorm", "Morepen"
  };

  /// Common pharmaceutical labels and boilerplate to filter out
  static final List<String> _boilerplateLines = [
    "for oral use", "for oral use only", "registered medical practitioner", "regd. medical",
    "wagierod medical", "pracaboner", "yaician", "dirncted", "bdr pharmaceuticals",
    "channel road", "emuei", "mfg. in india", "manufactured in india",
    "mfg. lic.", "mfg lic", "licence no", "license no", "batch no", "b.no", "lot no",
    "m.r.p.", "mrp rs", "incl. of all taxes", "store below", "store in a cool",
    "protect from light", "protect from moisture", "keep out of reach of children",
    "keep medicine out of", "schedule h prescription", "schedule h1", "schedule h", "schedule g", "schedule x",
    "warning: to be sold", "caution: not to be sold", "dosage: as directed", "as directed by the physician",
    "marketed by", "manufactured by", "mfg by", "pkg by", "for external use only",
    "not for injection", "shake well before use", "each uncoated tablet contains",
    "each film coated tablet contains", "each capsule contains", "each 5ml contains",
    "excipients q.s.", "colour:", "color:", "titanium dioxide", "sunset yellow",
    "pharmaceuticals ltd", "laboratories ltd", "pvt. ltd.", "pvt ltd", "india limited",
    "private limited", "strip of 10", "10 tablets", "10 capsules", "net content",
    "customer care", "toll free", "pin code", "industrial area"
  ];

  /// Clinical database mapping medicines to active ingredients (composition) and therapeutic indications (purpose)
  static final Map<String, Map<String, String>> _medicineDatabase = {
    // Pain, Fever & Inflammation
    "dolo650": {
      "composition": "Paracetamol IP (650 mg)",
      "purpose": "Fever, headache, and body pain relief",
      "knPurpose": "ಜ್ವರ, ತಲೆನೋವು ಮತ್ತು ಮೈ-ಕೈ ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "बुखार, सिरदर्द और बदन दर्द से राहत",
    },
    "dolo": {
      "composition": "Paracetamol IP (650 mg)",
      "purpose": "Fever, headache, and body pain relief",
      "knPurpose": "ಜ್ವರ, ತಲೆನೋವು ಮತ್ತು ಮೈ-ಕೈ ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "बुखार, सिरदर्द और बदन दर्द से राहत",
    },
    "calpol650": {
      "composition": "Paracetamol IP (650 mg)",
      "purpose": "Fever and mild-to-moderate pain relief",
      "knPurpose": "ಜ್ವರ ಮತ್ತು ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "बुखार और दर्द से राहत",
    },
    "calpol500": {
      "composition": "Paracetamol IP (500 mg)",
      "purpose": "Fever and mild pain relief",
      "knPurpose": "ಜ್ವರ ಮತ್ತು ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "बुखार और दर्द से राहत",
    },
    "calpol": {
      "composition": "Paracetamol IP",
      "purpose": "Fever and pain relief",
      "knPurpose": "ಜ್ವರ ಮತ್ತು ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "बुखार और दर्द से राहत",
    },
    "feverx650": {
      "composition": "Paracetamol IP (650 mg)",
      "purpose": "Fever and pain relief",
      "knPurpose": "ಜ್ವರ ಮತ್ತು ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "बुखार और दर्द से राहत",
    },
    "feverx": {
      "composition": "Paracetamol IP (650 mg)",
      "purpose": "Fever and pain relief",
      "knPurpose": "ಜ್ವರ ಮತ್ತು ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "बुखार और दर्द से राहत",
    },
    "crocin650": {
      "composition": "Paracetamol IP (650 mg)",
      "purpose": "Fever and headache relief",
      "knPurpose": "ಜ್ವರ ಮತ್ತು ತಲೆನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "बुखार और सिरदर्द से राहत",
    },
    "crocinadvance": {
      "composition": "Paracetamol IP (500 mg) Fast Action",
      "purpose": "Fast relief from fever and body pain",
      "knPurpose": "ಜ್ವರ ಮತ್ತು ಮೈ-ಕೈ ನೋವು ಶೀಘ್ರ ನಿವಾರಣೆ",
      "hiPurpose": "बुखार और दर्द से तेज़ राहत",
    },
    "crocin": {
      "composition": "Paracetamol IP",
      "purpose": "Fever and headache relief",
      "knPurpose": "ಜ್ವರ ಮತ್ತು ತಲೆನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "बुखार और सिरदर्द से राहत",
    },
    "paracetamol": {
      "composition": "Paracetamol IP",
      "purpose": "Fever, headache, and pain relief",
      "knPurpose": "ಜ್ವರ ಮತ್ತು ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "बुखार और दर्द से राहत",
    },
    "combiflam": {
      "composition": "Ibuprofen IP (400 mg) + Paracetamol IP (325 mg)",
      "purpose": "Fever, dental pain, body ache, and joint inflammation",
      "knPurpose": "ಜ್ವರ, ಹಲ್ಲು ನೋವು, ಮೈ-ಕೈ ನೋವು ಮತ್ತು ಊತ ನಿವಾರಣೆ",
      "hiPurpose": "बुखार, दांत दर्द, बदन दर्द और सूजन से राहत",
    },
    "brufen": {
      "composition": "Ibuprofen IP (400 mg)",
      "purpose": "Pain relief, muscle ache, and joint swelling",
      "knPurpose": "ನೋವು ಮತ್ತು ಊತ ನಿವಾರಣೆ",
      "hiPurpose": "दर्द और सूजन से राहत",
    },
    "ibuprofen": {
      "composition": "Ibuprofen IP",
      "purpose": "Pain relief and anti-inflammatory",
      "knPurpose": "ನೋವು ಮತ್ತು ಊತ ನಿವಾರಣೆ",
      "hiPurpose": "दर्द और सूजन से राहत",
    },
    "disprin": {
      "composition": "Aspirin / Acetylsalicylic Acid (350 mg)",
      "purpose": "Headache, fever, and pain relief",
      "knPurpose": "ತಲೆನೋವು ಮತ್ತು ಜ್ವರ ನಿವಾರಣೆ",
      "hiPurpose": "सिरदर्द और बुखार से राहत",
    },
    "aspirin": {
      "composition": "Aspirin / Acetylsalicylic Acid",
      "purpose": "Pain relief and blood clot prevention",
      "knPurpose": "ನೋವು ನಿವಾರಣೆ ಮತ್ತು ರಕ್ತ ತಿಳಿಯಾಗಿಸಲು",
      "hiPurpose": "दर्द से राहत और खून को पतला रखने के लिए",
    },
    "voveran": {
      "composition": "Diclofenac Sodium IP (50 mg)",
      "purpose": "Severe pain, arthritis, and joint inflammation",
      "knPurpose": "ಕೀಲು ನೋವು ಮತ್ತು ಉರಿಯೂತ ನಿವಾರಣೆ",
      "hiPurpose": "जोड़ों के दर्द और सूजन से राहत",
    },
    "diclofenac": {
      "composition": "Diclofenac Sodium IP",
      "purpose": "Pain relief and anti-inflammatory",
      "knPurpose": "ನೋವು ಮತ್ತು ಉರಿಯೂತ ನಿವಾರಣೆ",
      "hiPurpose": "दर्द और सूजन से राहत",
    },
    "zerodolsp": {
      "composition": "Aceclofenac (100 mg) + Paracetamol (325 mg) + Serratiopeptidase (15 mg)",
      "purpose": "Severe pain, swelling, and muscle inflammation relief",
      "knPurpose": "ತೀವ್ರ ನೋವು, ಊತ ಮತ್ತು ಸ್ನಾಯು ಉರಿಯೂತ ನಿವಾರಣೆ",
      "hiPurpose": "दर्द, सूजन और मांसपेशियों की ऐंठन से राहत",
    },
    "zerodolp": {
      "composition": "Aceclofenac (100 mg) + Paracetamol (325 mg)",
      "purpose": "Joint and muscle ache, dental pain, and fever",
      "knPurpose": "ಮೈ-ಕೈ ನೋವು, ಕೀಲು ನೋವು ಮತ್ತು ಜ್ವರ ನಿವಾರಣೆ",
      "hiPurpose": "जोड़ों के दर्द और बुखार से राहत",
    },
    "zerodol": {
      "composition": "Aceclofenac (100 mg)",
      "purpose": "Pain and inflammation relief",
      "knPurpose": "ನೋವು ಮತ್ತು ಉರಿಯೂತ ನಿವಾರಣೆ",
      "hiPurpose": "दर्द और सूजन से राहत",
    },
    "aceclofenac": {
      "composition": "Aceclofenac IP",
      "purpose": "Pain and inflammatory relief",
      "knPurpose": "ನೋವು ಮತ್ತು ಉರಿಯೂತ ನಿವಾರಣೆ",
      "hiPurpose": "दर्द और सूजन से राहत",
    },
    "meftalspas": {
      "composition": "Mefenamic Acid (250 mg) + Dicyclomine Hydrochloride (10 mg)",
      "purpose": "Abdominal cramps, stomach spasms, and menstrual pain relief",
      "knPurpose": "ಹೊಟ್ಟೆ ನೋವು, ಸೆಳೆತ ಮತ್ತು ಮುಟ್ಟಿನ ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "पेट दर्द, ऐंठन और मासिक धर्म के दर्द से राहत",
    },
    "meftal": {
      "composition": "Mefenamic Acid IP (500 mg)",
      "purpose": "Menstrual pain, dental ache, and muscular discomfort",
      "knPurpose": "ಮುಟ್ಟಿನ ನೋವು ಮತ್ತು ಮೈ-ಕೈ ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "मासिक धर्म के दर्द और बदन दर्द से राहत",
    },
    "ultracet": {
      "composition": "Tramadol Hydrochloride (37.5 mg) + Paracetamol (325 mg)",
      "purpose": "Moderate to severe acute pain relief",
      "knPurpose": "ತೀವ್ರ ಸ್ವರೂಪದ ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "गंभीर दर्द से राहत के लिए",
    },
    "tramadol": {
      "composition": "Tramadol Hydrochloride IP",
      "purpose": "Moderate to severe pain relief",
      "knPurpose": "ತೀವ್ರ ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "गंभीर दर्द से राहत",
    },

    // Gastrointestinal & Antacids
    "pan40": {
      "composition": "Pantoprazole Sodium Gastro-resistant (40 mg)",
      "purpose": "Acidity, heartburn, acid reflux (GERD), and stomach ulcers",
      "knPurpose": "ಅಸಿಡಿಟಿ, ಎದೆಯುರಿ, ಗ್ಯಾಸ್ಟ್ರಿಕ್ ಮತ್ತು ಹೊಟ್ಟೆಯ ಹುಣ್ಣು ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी, सीने में जलन, गैस और पेट के अल्सर से राहत",
    },
    "pand": {
      "composition": "Pantoprazole (40 mg) + Domperidone (30 mg)",
      "purpose": "Acidity, nausea, acid reflux, and stomach heaviness",
      "knPurpose": "ಅಸಿಡಿಟಿ, ವಾಕರಿಕೆ ಮತ್ತು ಎದೆಯುರಿ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी, मतली और सीने में जलन से राहत",
    },
    "pantocid40": {
      "composition": "Pantoprazole Sodium IP (40 mg)",
      "purpose": "Acidity, GERD, and stomach acid reduction",
      "knPurpose": "ಅಸಿಡಿಟಿ ಮತ್ತು ಎದೆಯುರಿ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी और सीने में जलन से राहत",
    },
    "pantocid": {
      "composition": "Pantoprazole Sodium IP",
      "purpose": "Acidity and reflux treatment",
      "knPurpose": "ಅಸಿಡಿಟಿ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी से राहत",
    },
    "pantoprazole": {
      "composition": "Pantoprazole Sodium IP",
      "purpose": "Reduces stomach acid and prevents heartburn",
      "knPurpose": "ಅಸಿಡಿಟಿ ಮತ್ತು ಎದೆಯುರಿ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी और सीने में जलन से राहत",
    },
    "omez20": {
      "composition": "Omeprazole Gastro-resistant (20 mg)",
      "purpose": "Stomach acid reducer for indigestion and heartburn",
      "knPurpose": "ಎದೆಯುರಿ, ಅಜೀರ್ಣ ಮತ್ತು ಗ್ಯಾಸ್ಟ್ರಿಕ್ ನಿವಾರಣೆ",
      "hiPurpose": "सीने में जलन, अपच और गैस से राहत",
    },
    "omezd": {
      "composition": "Omeprazole (20 mg) + Domperidone (10 mg)",
      "purpose": "Acid reflux, nausea, and indigestion relief",
      "knPurpose": "ಎದೆಯುರಿ ಮತ್ತು ವಾಂತಿ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी और मतली से राहत",
    },
    "omez": {
      "composition": "Omeprazole IP (20 mg)",
      "purpose": "Gastric acid reducer for heartburn and indigestion",
      "knPurpose": "ಗ್ಯಾಸ್ಟ್ರಿಕ್ ಮತ್ತು ಎದೆಯುರಿ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी और सीने में जलन से राहत",
    },
    "omeprazole": {
      "composition": "Omeprazole IP",
      "purpose": "Stomach acid reducer for reflux and heartburn",
      "knPurpose": "ಅಸಿಡಿಟಿ ಮತ್ತು ಎದೆಯುರಿ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी और सीने में जलन से राहत",
    },
    "razo20": {
      "composition": "Rabeprazole Sodium IP (20 mg)",
      "purpose": "Fast-acting relief from acidity, heartburn, and GERD",
      "knPurpose": "ಅಸಿಡಿಟಿ ಮತ್ತು ಎದೆಯುರಿ ಶೀಘ್ರ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी और सीने में जलन से त्वरित राहत",
    },
    "rablet20": {
      "composition": "Rabeprazole Sodium IP (20 mg)",
      "purpose": "Acidity and acid reflux treatment",
      "knPurpose": "ಅಸಿಡಿಟಿ ಮತ್ತು ಎದೆಯುರಿ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी और सीने में जलन से राहत",
    },
    "rabeprazole": {
      "composition": "Rabeprazole Sodium IP",
      "purpose": "Stomach acid reduction and reflux relief",
      "knPurpose": "ಅಸಿಡಿಟಿ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी से राहत",
    },
    "nexpro40": {
      "composition": "Esomeprazole Magnesium (40 mg)",
      "purpose": "Heals acid reflux, heartburn, and erosive esophagitis",
      "knPurpose": "ಎದೆಯುರಿ ಮತ್ತು ಅಸಿಡಿಟಿ ನಿವಾರಣೆ",
      "hiPurpose": "सीने में जलन और एसिडिटी से राहत",
    },
    "nexpro": {
      "composition": "Esomeprazole Magnesium",
      "purpose": "Gastric acid reducer for GERD",
      "knPurpose": "ಅಸಿಡಿಟಿ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी से राहत",
    },
    "esomeprazole": {
      "composition": "Esomeprazole IP",
      "purpose": "Gastric acid reduction and ulcer healing",
      "knPurpose": "ಅಸಿಡಿಟಿ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी से राहत",
    },
    "doxinate": {
      "composition": "Doxylamine Succinate (10 mg) + Pyridoxine HCl / Vitamin B6 (10 mg)",
      "purpose": "Pregnancy morning sickness, nausea, and vomiting relief",
      "knPurpose": "ಗರ್ಭಾವಸ್ಥೆಯ ವಾಂತಿ, ತಲೆತಿರುಗುವಿಕೆ ಮತ್ತು ವಾಕರಿಕೆ ನಿವಾರಣೆ",
      "hiPurpose": "गर्भावस्था में उल्टी, मतली और चक्कर से राहत",
    },
    "vomikind": {
      "composition": "Ondansetron IP (4 mg)",
      "purpose": "Fast relief from nausea and vomiting",
      "knPurpose": "ವಾಂತಿ ಮತ್ತು ವಾಕರಿಕೆ ನಿವಾರಣೆ",
      "hiPurpose": "उल्टी और मतली की रोकथाम",
    },
    "perinorm": {
      "composition": "Metoclopramide Hydrochloride IP (10 mg)",
      "purpose": "Prevents vomiting and aids gastric emptying",
      "knPurpose": "ವಾಂತಿ ನಿವಾರಣೆ ಮತ್ತು ಜೀರ್ಣಕ್ರಿಯೆ ಸುಧಾರಣೆ",
      "hiPurpose": "उल्टी रोकने और पाचन गति बढ़ाने के लिए",
    },
    "emeset4": {
      "composition": "Ondansetron IP (4 mg)",
      "purpose": "Prevents and stops nausea and vomiting",
      "knPurpose": "ವಾಂತಿ ಮತ್ತು ವಾಕರಿಕೆ ನಿವಾರಣೆ",
      "hiPurpose": "उल्टी और मतली से राहत",
    },
    "emeset": {
      "composition": "Ondansetron IP (4 mg)",
      "purpose": "Stops nausea and vomiting",
      "knPurpose": "ವಾಂತಿ ನಿವಾರಣೆ",
      "hiPurpose": "उल्टी से राहत",
    },
    "ondansetron": {
      "composition": "Ondansetron IP",
      "purpose": "Anti-emetic for nausea and vomiting control",
      "knPurpose": "ವಾಂತಿ ನಿವಾರಣೆ",
      "hiPurpose": "उल्टी की रोकथाम",
    },
    "digene": {
      "composition": "Dried Aluminium Hydroxide + Magnesium Hydroxide + Simethicone",
      "purpose": "Instant relief from acidity, heartburn, and gas bloating",
      "knPurpose": "ಅಸಿಡಿಟಿ, ಎದೆಯುರಿ ಮತ್ತು ಗ್ಯಾಸ್ ನಿಂದ ತಕ್ಷಣದ ಮುಕ್ತಿ",
      "hiPurpose": "एसिडिटी, सीने में जलन और गैस से तुरंत राहत",
    },
    "gelusil": {
      "composition": "Aluminium Hydroxide + Magnesium Silicate + Simethicone",
      "purpose": "Relief from acidity, stomach discomfort, and flatulence",
      "knPurpose": "ಅಸಿಡಿಟಿ ಮತ್ತು ಗ್ಯಾಸ್ ನಿವಾರಣೆ",
      "hiPurpose": "एसिडिटी और गैस से राहत",
    },

    // Antibiotics & Antimicrobials
    "augmentin625duo": {
      "composition": "Amoxicillin Trihydrate (500 mg) + Potassium Clavulanate (125 mg)",
      "purpose": "Broad-spectrum antibiotic for bacterial infections (chest, throat, teeth, skin)",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ ಆಂಟಿಬಯೋಟಿಕ್",
      "hiPurpose": "बैक्टीरियल संक्रमण के इलाज के लिए एंटीबायोटिक",
    },
    "augmentin625": {
      "composition": "Amoxicillin (500 mg) + Clavulanic Acid (125 mg)",
      "purpose": "Antibiotic for bacterial infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ ಆಂಟಿಬಯೋಟಿಕ್",
      "hiPurpose": "बैक्टीरियल इन्फेक्शन के लिए एंटीबायोटिक",
    },
    "augmentin": {
      "composition": "Amoxicillin + Potassium Clavulanate",
      "purpose": "Antibiotic for bacterial infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ ಆಂಟಿಬಯೋಟಿಕ್",
      "hiPurpose": "बैक्टीरियल इन्फेक्शन के लिए एंटीबायोटिक",
    },
    "clavam625": {
      "composition": "Amoxicillin (500 mg) + Potassium Clavulanate (125 mg)",
      "purpose": "Antibiotic for bacterial respiratory and dental infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ ಆಂಟಿಬಯೋಟಿಕ್",
      "hiPurpose": "बैक्टीरियल इन्फेक्शन के लिए एंटीबायोटिक",
    },
    "moxikindcv": {
      "composition": "Amoxicillin (500 mg) + Potassium Clavulanate (125 mg)",
      "purpose": "Antibiotic for bacterial infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "बैक्टीरियल संक्रमण के लिए",
    },
    "amoxicillin": {
      "composition": "Amoxicillin Trihydrate IP",
      "purpose": "Antibiotic for bacterial infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "बैक्टीरियल इन्फेक्शन के लिए एंटीबायोटिक",
    },
    "amoxyclav": {
      "composition": "Amoxicillin + Potassium Clavulanate",
      "purpose": "Antibiotic for resistant bacterial infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "बैक्टीरियल इन्फेक्शन के लिए एंटीबायोटिक",
    },
    "azithral500": {
      "composition": "Azithromycin Dihydrate IP (500 mg)",
      "purpose": "Antibiotic for throat, tonsils, chest, sinus, and respiratory infections",
      "knPurpose": "ಗಂಟಲು, ಶ್ವಾಸಕೋಶ ಮತ್ತು ಕಫ ಸೋಂಕು ನಿವಾರಕ ಆಂಟಿಬಯೋಟಿಕ್",
      "hiPurpose": "गले, फेफड़ों और सांस के इन्फेक्शन के लिए एंटीबायोटिक",
    },
    "azithral": {
      "composition": "Azithromycin Dihydrate IP (500 mg)",
      "purpose": "Antibiotic for throat and respiratory infections",
      "knPurpose": "ಗಂಟಲು ಮತ್ತು ಶ್ವಾಸಕೋಶದ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "गले और सांस के इन्फेक्शन के लिए",
    },
    "azee500": {
      "composition": "Azithromycin IP (500 mg)",
      "purpose": "Antibiotic for respiratory and skin infections",
      "knPurpose": "ಶ್ವಾಸಕೋಶ ಮತ್ತು ಗಂಟಲಿನ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "गले और सांस के इन्फेक्शन के लिए",
    },
    "azee": {
      "composition": "Azithromycin IP",
      "purpose": "Antibiotic for bacterial infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "बैक्टीरियल इन्फेक्शन के लिए",
    },
    "azithromycin": {
      "composition": "Azithromycin IP",
      "purpose": "Broad-spectrum macrolide antibiotic for infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "बैक्टीरियल इन्फेक्शन के लिए एंटीबायोटिक",
    },
    "cefixime": {
      "composition": "Cefixime Trihydrate IP",
      "purpose": "Antibiotic for typhoid, urinary, and respiratory infections",
      "knPurpose": "ಟೈಫಾಯಿಡ್ ಮತ್ತು ಮೂತ್ರನಾಳದ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "टाइफाइड और यूरिन इन्फेक्शन के लिए एंटीबायोटिक",
    },
    "taximo": {
      "composition": "Cefixime IP (200 mg)",
      "purpose": "Antibiotic for bacterial infections and typhoid",
      "knPurpose": "ಟೈಫಾಯಿಡ್ ಮತ್ತು ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "टाइफाइड और बैक्टीरियल संक्रमण के लिए",
    },
    "mahacef": {
      "composition": "Cefixime IP (200 mg)",
      "purpose": "Antibiotic for bacterial infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "बैक्टीरियल संक्रमण के लिए",
    },
    "ciplox": {
      "composition": "Ciprofloxacin Hydrochloride IP (500 mg)",
      "purpose": "Antibiotic for urinary tract, eye/ear, and stomach infections",
      "knPurpose": "ಮೂತ್ರನಾಳ ಮತ್ತು ಕಣ್ಣು/ಕಿವಿ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "यूरिन और आंख/कान के इन्फेक्शन के लिए एंटीबायोटिक",
    },
    "ciprofloxacin": {
      "composition": "Ciprofloxacin Hydrochloride IP",
      "purpose": "Antibiotic for bacterial infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "बैक्टीरियल इन्फेक्शन के लिए एंटीबायोटिक",
    },
    "oflox": {
      "composition": "Ofloxacin IP (200 mg)",
      "purpose": "Antibiotic for bacterial infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "बैक्टीरियल संक्रमण के लिए एंटीबायोटिक",
    },
    "ofloxacin": {
      "composition": "Ofloxacin IP",
      "purpose": "Antibiotic for bacterial infections",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "बैक्टीरियल संक्रमण के लिए",
    },
    "norfloxtz": {
      "composition": "Norfloxacin (400 mg) + Tinidazole (600 mg)",
      "purpose": "Treatment for bacterial diarrhea, amoebiasis, and stomach infections",
      "knPurpose": "ಹೊಟ್ಟೆ ಕೆಡುವುದು ಮತ್ತು ಅತಿಸಾರ ಸೋಂಕು ನಿವಾರಣೆ",
      "hiPurpose": "दस्त और पेट के बैक्टीरियल इन्फेक्शन के लिए",
    },
    "norfloxacin": {
      "composition": "Norfloxacin IP",
      "purpose": "Antibiotic for urinary tract and stomach infections",
      "knPurpose": "ಮೂತ್ರನಾಳ ಮತ್ತು ಹೊಟ್ಟೆಯ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "यूरिन और पेट के इन्फेक्शन के लिए",
    },
    "flagyl": {
      "composition": "Metronidazole IP (400 mg)",
      "purpose": "Treatment for bacterial and amoebic intestinal infections",
      "knPurpose": "ಕರುಳಿನ ಸೋಂಕು ಮತ್ತು ಅತಿಸಾರ ನಿವಾರಣೆ",
      "hiPurpose": "आंतों के इन्फेक्शन और दस्त के लिए",
    },
    "metronidazole": {
      "composition": "Metronidazole IP",
      "purpose": "Antiprotozoal and anaerobic antibiotic",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಮತ್ತು ಪರಾವಲಂಬಿ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "बैक्टीरियल और परजीवी इन्फेक्शन के लिए",
    },
    "doxtsl": {
      "composition": "Doxycycline (100 mg) + Lactic Acid Bacillus",
      "purpose": "Antibiotic for acne, chest, and bacterial infections",
      "knPurpose": "ಮೊಡವೆ ಮತ್ತು ಎದೆಯ ಸೋಂಕು ನಿವಾರಕ ಆಂಟಿಬಯೋಟಿಕ್",
      "hiPurpose": "मुंहासे और छाती के इन्फेक्शन के लिए",
    },
    "doxycycline": {
      "composition": "Doxycycline Hydrochloride IP",
      "purpose": "Antibiotic for bacterial infections and acne",
      "knPurpose": "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ",
      "hiPurpose": "बैक्टीरियल इन्फेक्शन के लिए",
    },

    // Diabetes
    "glycometgp": {
      "composition": "Glimepiride + Metformin Hydrochloride",
      "purpose": "Dual medication for type-2 diabetes blood sugar control",
      "knPurpose": "ಟೈಪ್-2 ಮಧುಮೇಹದಲ್ಲಿ ರಕ್ತದ ಸಕ್ಕರೆ ನಿಯಂತ್ರಣ",
      "hiPurpose": "टाइप-2 डायबिटीज में ब्लड शुगर का नियंत्रण",
    },
    "glycomet500": {
      "composition": "Metformin Hydrochloride IP (500 mg)",
      "purpose": "Lowers high blood sugar in type-2 diabetes",
      "knPurpose": "ಟೈಪ್-2 ಮಧುಮೇಹದಲ್ಲಿ ಸಕ್ಕರೆ ಮಟ್ಟ ನಿಯಂತ್ರಣ",
      "hiPurpose": "डायबिटीज में ब्लड शुगर का नियंत्रण",
    },
    "glycomet": {
      "composition": "Metformin Hydrochloride IP",
      "purpose": "Controls blood sugar in type-2 diabetes",
      "knPurpose": "ಮಧುಮೇಹ ನಿಯಂತ್ರಣ",
      "hiPurpose": "डायबिटीज में शुगर नियंत्रण",
    },
    "metformin": {
      "composition": "Metformin Hydrochloride IP",
      "purpose": "First-line medicine to control high blood sugar in diabetes",
      "knPurpose": "ಮಧುಮೇಹದಲ್ಲಿ ಸಕ್ಕರೆ ನಿಯಂತ್ರಣ",
      "hiPurpose": "डायबिटीज में ब्लड शुगर नियंत्रण",
    },
    "glimepiride": {
      "composition": "Glimepiride IP",
      "purpose": "Stimulates natural insulin production in type-2 diabetes",
      "knPurpose": "ಮಧುಮೇಹದಲ್ಲಿ ಇನ್ಸುಲಿನ್ ಉತ್ಪಾದನೆ ಪ್ರಚೋದನೆ",
      "hiPurpose": "डायबिटीज में इंसुलिन बढ़ाने के लिए",
    },
    "amaryl": {
      "composition": "Glimepiride (1 mg / 2 mg)",
      "purpose": "Lowers blood glucose in type-2 diabetes",
      "knPurpose": "ಮಧುಮೇಹ ನಿಯಂತ್ರಣ",
      "hiPurpose": "डायबिटीज में ब्लड शुगर नियंत्रण",
    },
    "januvia": {
      "composition": "Sitagliptin Phosphate (100 mg)",
      "purpose": "DPP-4 inhibitor to control blood sugar in diabetes",
      "knPurpose": "ಮಧುಮೇಹದಲ್ಲಿ ಸಕ್ಕರೆ ಮಟ್ಟ ನಿಯಂತ್ರಣ",
      "hiPurpose": "डायबिटीज में शुगर नियंत्रण",
    },
    "galvus": {
      "composition": "Vildagliptin (50 mg)",
      "purpose": "DPP-4 inhibitor to maintain steady blood glucose",
      "knPurpose": "ಮಧುಮೇಹ ನಿಯಂತ್ರಣ",
      "hiPurpose": "डायबिटीज में शुगर नियंत्रण",
    },
    "forxiga": {
      "composition": "Dapagliflozin Propanediol (10 mg)",
      "purpose": "SGLT2 inhibitor to lower blood sugar and protect heart & kidneys",
      "knPurpose": "ಮಧುಮೇಹ, ಹೃದಯ ಮತ್ತು ಮೂತ್ರಪಿಂಡಗಳ ರಕ್ಷಣೆ",
      "hiPurpose": "डायबिटीज में शुगर नियंत्रण और किडनी/हार्ट सुरक्षा",
    },
    "jardiance": {
      "composition": "Empagliflozin (10 mg / 25 mg)",
      "purpose": "Lowers blood glucose and reduces cardiovascular risk in diabetes",
      "knPurpose": "ಮಧುಮೇಹ ಮತ್ತು ಹೃದಯದ ಆರೋಗ್ಯ ರಕ್ಷಣೆ",
      "hiPurpose": "डायबिटीज और हृदय सुरक्षा के लिए",
    },

    // Hypertension & Cardiac
    "telma40": {
      "composition": "Telmisartan IP (40 mg)",
      "purpose": "Lowers high blood pressure (hypertension) and protects heart",
      "knPurpose": "ಅಧಿಕ ರಕ್ತದೊತ್ತಡ (BP) ನಿಯಂತ್ರಣ ಮತ್ತು ಹೃದಯ ರಕ್ಷಣೆ",
      "hiPurpose": "हाई ब्लड प्रेशर (बीपी) नियंत्रण और हृदय सुरक्षा",
    },
    "telmah": {
      "composition": "Telmisartan (40 mg) + Hydrochlorothiazide (12.5 mg)",
      "purpose": "Dual therapy for high blood pressure control",
      "knPurpose": "ರಕ್ತದೊತ್ತಡ (BP) ನಿಯಂತ್ರಣ",
      "hiPurpose": "ब्लड प्रेशर नियंत्रण",
    },
    "telma": {
      "composition": "Telmisartan IP (40 mg)",
      "purpose": "Controls high blood pressure and protects heart",
      "knPurpose": "ರಕ್ತದೊತ್ತಡ ನಿಯಂತ್ರಣ",
      "hiPurpose": "ब्लड प्रेशर नियंत्रण",
    },
    "telmikind40": {
      "composition": "Telmisartan IP (40 mg)",
      "purpose": "Controls high blood pressure",
      "knPurpose": "ರಕ್ತದೊತ್ತಡ ನಿಯಂತ್ರಣ",
      "hiPurpose": "ब्लड प्रेशर नियंत्रण",
    },
    "telmisartan": {
      "composition": "Telmisartan IP",
      "purpose": "Lowers high blood pressure and reduces risk of heart attack",
      "knPurpose": "ಅಧಿಕ ರಕ್ತದೊತ್ತಡ ಮತ್ತು ಹೃದಯಾಘಾತ ತಡೆಗಟ್ಟಲು",
      "hiPurpose": "हाई ब्लड प्रेशर नियंत्रण और हार्ट अटैक से बचाव",
    },
    "amlong5": {
      "composition": "Amlodipine Besylate IP (5 mg)",
      "purpose": "Calcium channel blocker for high blood pressure and angina",
      "knPurpose": "ಅಧಿಕ ರಕ್ತದೊತ್ತಡ ಮತ್ತು ಎದೆ ನೋವು ನಿವಾರಣೆ",
      "hiPurpose": "हाई ब्लड प्रेशर और सीने के दर्द से राहत",
    },
    "amlong": {
      "composition": "Amlodipine Besylate IP (5 mg)",
      "purpose": "Lowers high blood pressure",
      "knPurpose": "ರಕ್ತದೊತ್ತಡ ನಿಯಂತ್ರಣ",
      "hiPurpose": "ब्लड प्रेशर नियंत्रण",
    },
    "amlodipine": {
      "composition": "Amlodipine Besylate IP",
      "purpose": "Lowers high blood pressure and improves blood flow",
      "knPurpose": "ರಕ್ತದೊತ್ತಡ ನಿಯಂತ್ರಣ",
      "hiPurpose": "ब्लड प्रेशर नियंत्रण",
    },
    "aten50": {
      "composition": "Atenolol IP (50 mg)",
      "purpose": "Beta-blocker for high blood pressure and irregular heartbeat",
      "knPurpose": "ಅಧಿಕ ರಕ್ತದೊತ್ತಡ ಮತ್ತು ಹೃದಯ ಬಡಿತ ನಿಯಂತ್ರಣ",
      "hiPurpose": "हाई ब्लड प्रेशर और दिल की धड़कन नियंत्रण",
    },
    "aten": {
      "composition": "Atenolol IP",
      "purpose": "Beta-blocker for blood pressure control",
      "knPurpose": "ರಕ್ತದೊತ್ತಡ ನಿಯಂತ್ರಣ",
      "hiPurpose": "ब्लड प्रेशर नियंत्रण",
    },
    "atenolol": {
      "composition": "Atenolol IP",
      "purpose": "Controls high blood pressure and protects heart",
      "knPurpose": "ರಕ್ತದೊತ್ತಡ ನಿಯಂತ್ರಣ",
      "hiPurpose": "ब्लड प्रेशर नियंत्रण",
    },
    "atorva10": {
      "composition": "Atorvastatin Calcium IP (10 mg)",
      "purpose": "Lowers bad cholesterol (LDL) and prevents heart disease",
      "knPurpose": "ಕೆಟ್ಟ ಕೊಲೆಸ್ಟ್ರಾಲ್ ಕಡಿಮೆ ಮಾಡಿ ಹೃದಯ ರಕ್ಷಣೆ",
      "hiPurpose": "खराब कोलेस्ट्रॉल कम करने और हृदय सुरक्षा के लिए",
    },
    "atorva20": {
      "composition": "Atorvastatin Calcium IP (20 mg)",
      "purpose": "Lowers bad cholesterol and triglycerides, protects arteries",
      "knPurpose": "ಕೊಲೆಸ್ಟ್ರಾಲ್ ಕಡಿಮೆ ಮಾಡಿ ಹೃದಯ ರಕ್ಷಣೆ",
      "hiPurpose": "कोलेस्ट्रॉल कम करने और हृदय सुरक्षा के लिए",
    },
    "atorva": {
      "composition": "Atorvastatin Calcium IP",
      "purpose": "Statin to lower bad cholesterol and prevent heart attack",
      "knPurpose": "ಕೊಲೆಸ್ಟ್ರಾಲ್ ನಿಯಂತ್ರಣ",
      "hiPurpose": "कोलेस्ट्रॉल नियंत्रण",
    },
    "atorvastatin": {
      "composition": "Atorvastatin Calcium IP",
      "purpose": "Lowers bad cholesterol and reduces risk of stroke and heart attack",
      "knPurpose": "ಕೊಲೆಸ್ಟ್ರಾಲ್ ಕಡಿಮೆ ಮಾಡಿ ಪಾರ್ಶ್ವವಾಯು ಮತ್ತು ಹೃದಯಾಘಾತ ತಡೆಗಟ್ಟಲು",
      "hiPurpose": "कोलेस्ट्रॉल कम करने और स्ट्रोक/हार्ट अटैक से बचाव के लिए",
    },
    "rosuvas10": {
      "composition": "Rosuvastatin Calcium IP (10 mg)",
      "purpose": "Potent statin to lower bad cholesterol and triglycerides",
      "knPurpose": "ಕೊಲೆಸ್ಟ್ರಾಲ್ ನಿಯಂತ್ರಣ ಮತ್ತು ಹೃದಯ ರಕ್ಷಣೆ",
      "hiPurpose": "कोलेस्ट्रॉल कम करने और हृदय सुरक्षा के लिए",
    },
    "rosuvastatin": {
      "composition": "Rosuvastatin Calcium IP",
      "purpose": "Lowers cholesterol and prevents plaque buildup in arteries",
      "knPurpose": "ಕೊಲೆಸ್ಟ್ರಾಲ್ ನಿಯಂತ್ರಣ",
      "hiPurpose": "कोलेस्ट्रॉल नियंत्रण",
    },
    "ecosprin75": {
      "composition": "Enteric-coated Aspirin IP (75 mg)",
      "purpose": "Low-dose blood thinner to prevent blood clots, heart attack, and stroke",
      "knPurpose": "ರಕ್ತ ಹೆಪ್ಪುಗಟ್ಟುವುದನ್ನು ತಡೆದು ಹೃದಯಾಘಾತ ಮತ್ತು ಪಾರ್ಶ್ವವಾಯು ತಡೆಗಟ್ಟಲು",
      "hiPurpose": "खून के थक्कों, हार्ट अटैक और स्ट्रोक से बचाव के लिए",
    },
    "ecosprin150": {
      "composition": "Enteric-coated Aspirin IP (150 mg)",
      "purpose": "Blood thinner for cardiovascular protection",
      "knPurpose": "ರಕ್ತ ತಿಳಿಯಾಗಿಸಿ ಹೃದಯ ರಕ್ಷಣೆ",
      "hiPurpose": "हार्ट अटैक और स्ट्रोक से बचाव",
    },
    "ecosprin": {
      "composition": "Enteric-coated Aspirin IP",
      "purpose": "Blood thinner to prevent blood clots and protect heart",
      "knPurpose": "ರಕ್ತ ತಿಳಿಯಾಗಿಸಿ ಹೃದಯ ರಕ್ಷಣೆ",
      "hiPurpose": "खून पतला करने और हृदय सुरक्षा के लिए",
    },

    // Allergy & Respiratory
    "cetzine": {
      "composition": "Cetirizine Hydrochloride IP (10 mg)",
      "purpose": "Allergy relief for sneezing, runny nose, watery eyes, and itching",
      "knPurpose": "ಅಲರ್ಜಿ, ಸೀನು, ನೆಗಡಿ, ಕಣ್ಣಿನಲ್ಲಿ ನೀರು ಮತ್ತು ತುರಿಕೆ ನಿವಾರಣೆ",
      "hiPurpose": "एलर्जी, छींक, बहती नाक और खुजली से राहत",
    },
    "alerid": {
      "composition": "Cetirizine Hydrochloride IP (10 mg)",
      "purpose": "Relieves cold, sneezing, runny nose, and allergic hives",
      "knPurpose": "ಅಲರ್ಜಿ, ಸೀನು ಮತ್ತು ನೆಗಡಿ ನಿವಾರಣೆ",
      "hiPurpose": "एलर्जी और जुकाम से राहत",
    },
    "cetirizine": {
      "composition": "Cetirizine Hydrochloride IP",
      "purpose": "Antihistamine for allergies, cold symptoms, and itchy skin",
      "knPurpose": "ಅಲರ್ಜಿ ಮತ್ತು ನೆಗಡಿ ನಿವಾರಣೆ",
      "hiPurpose": "एलर्जी, छींक और खुजली से राहत",
    },
    "levocet": {
      "composition": "Levocetirizine Dihydrochloride IP (5 mg)",
      "purpose": "Effective anti-allergic for sneezing, nasal congestion, and hives",
      "knPurpose": "ಅಲರ್ಜಿ, ಸೀನು ಮತ್ತು ಮೂಗು ಕಟ್ಟುವಿಕೆ ನಿವಾರಣೆ",
      "hiPurpose": "एलर्जी, छींक और बंद नाक से राहत",
    },
    "levocetirizine": {
      "composition": "Levocetirizine Dihydrochloride IP",
      "purpose": "Anti-allergic medication for allergic rhinitis and skin hives",
      "knPurpose": "ಅಲರ್ಜಿ ನಿವಾರಣೆ",
      "hiPurpose": "एलर्जी से राहत",
    },
    "montairlc": {
      "composition": "Montelukast Sodium (10 mg) + Levocetirizine (5 mg)",
      "purpose": "Relief from allergic rhinitis, asthma symptoms, and chronic sneezing",
      "knPurpose": "ಅಲರ್ಜಿ, ಉಬ್ಬಸ, ಸೀನು ಮತ್ತು ಕೆಮ್ಮು ನಿವಾರಣೆ",
      "hiPurpose": "एलर्जी, छींक, दमा के लक्षण और खांसी से राहत",
    },
    "monteklc": {
      "composition": "Montelukast Sodium (10 mg) + Levocetirizine (5 mg)",
      "purpose": "Relief from allergies, sneezing, and breathing discomfort",
      "knPurpose": "ಅಲರ್ಜಿ ಮತ್ತು ಉಸಿರಾಟದ ತೊಂದರೆ ನಿವಾರಣೆ",
      "hiPurpose": "एलर्जी और सांस की तकलीफ से राहत",
    },
    "allegra120": {
      "composition": "Fexofenadine Hydrochloride IP (120 mg)",
      "purpose": "Non-drowsy allergy relief for seasonal hay fever and skin rashes",
      "knPurpose": "ನಿದ್ದೆ ಬಾರದ ಅಲರ್ಜಿ, ಸೀನು ಮತ್ತು ಚರ್ಮದ ತುರಿಕೆ ನಿವಾರಣೆ",
      "hiPurpose": "बिना सुस्ती वाली एलर्जी, छींक और खुजली से राहत",
    },
    "allegra": {
      "composition": "Fexofenadine Hydrochloride IP (120 mg)",
      "purpose": "Non-drowsy relief from allergic rhinitis and itching",
      "knPurpose": "ಅಲರ್ಜಿ ಮತ್ತು ಸೀನು ನಿವಾರಣೆ",
      "hiPurpose": "एलर्जी और छींक से राहत",
    },
    "fexofenadine": {
      "composition": "Fexofenadine Hydrochloride IP",
      "purpose": "Non-drowsy antihistamine for allergy symptoms",
      "knPurpose": "ಅಲರ್ಜಿ ನಿವಾರಣೆ",
      "hiPurpose": "एलर्जी से राहत",
    },
    "ascorills": {
      "composition": "Levosalbutamol + Ambroxol + Guaifenesin",
      "purpose": "Cough syrup to thin mucus, clear chest congestion, and ease breathing",
      "knPurpose": "ಕಫ ಕರಗಿಸಿ ಕೆಮ್ಮು ಮತ್ತು ಎದೆ ಬಿಗಿತ ನಿವಾರಿಸಲು ಕೆಮ್ಮಿನ ಸಿರಪ್",
      "hiPurpose": "कफ को पतला करने, खांसी और सीने की जकड़न से राहत का सिरप",
    },
    "ascoril": {
      "composition": "Levosalbutamol + Ambroxol + Guaifenesin",
      "purpose": "Relieves chest congestion, wet cough, and airway constriction",
      "knPurpose": "ಕಫ ಮತ್ತು ಕೆಮ್ಮು ನಿವಾರಕ ಸಿರಪ್",
      "hiPurpose": "खांसी और कफ से राहत का सिरप",
    },
    "benadryl": {
      "composition": "Diphenhydramine HCl + Ammonium Chloride",
      "purpose": "Cough syrup to suppress dry cough and soothe throat irritation",
      "knPurpose": "ಒಣ ಕೆಮ್ಮು ಮತ್ತು ಗಂಟಲು ಕಿರಿಕಿರಿ ನಿವಾರಕ ಸಿರಪ್",
      "hiPurpose": "सूखी खांसी और गले की खराश से राहत का सिरप",
    },
    "chestoncold": {
      "composition": "Paracetamol (325 mg) + Phenylephrine (5 mg) + Chlorpheniramine (2 mg)",
      "purpose": "Comprehensive relief from severe cold, headache, blocked nose, and fever",
      "knPurpose": "ನೆಗಡಿ, ಮೂಗು ಕಟ್ಟುವಿಕೆ, ತಲೆನೋವು ಮತ್ತು ಜ್ವರ ನಿವಾರಣೆ",
      "hiPurpose": "जुकाम, बंद नाक, सिरदर्द और बुखार से राहत",
    },

    // Vitamins, Minerals & Supplements
    "shelcal500": {
      "composition": "Calcium Carbonate (500 mg elemental Calcium) + Vitamin D3 (250 IU)",
      "purpose": "Strengthens bones and teeth, treats calcium and vitamin D deficiency",
      "knPurpose": "ಮೂಳೆ ಮತ್ತು ಹಲ್ಲುಗಳ ಬಲವರ್ಧನೆ, ಕ್ಯಾಲ್ಸಿಯಂ ಪೂರಕ",
      "hiPurpose": "हड्डियों और दांतों की मजबूती, कैल्शियम की पूर्ति",
    },
    "shelcal": {
      "composition": "Calcium + Vitamin D3",
      "purpose": "Bone health and calcium supplement",
      "knPurpose": "ಕ್ಯಾಲ್ಸಿಯಂ ಮತ್ತು ಮೂಳೆಗಳ ಆರೋಗ್ಯ ಪೂರಕ",
      "hiPurpose": "कैल्शियम और हड्डियों के स्वास्थ्य के लिए",
    },
    "becosulesz": {
      "composition": "Vitamin B-Complex + Vitamin C + Zinc Sulphate",
      "purpose": "Restores energy, heals mouth ulcers, and treats vitamin deficiency",
      "knPurpose": "ಬಾಯಿ ಹುಣ್ಣು ನಿವಾರಣೆ, ಶಕ್ತಿ ವೃದ್ಧಿ ಮತ್ತು ವಿಟಮಿನ್ ಪೂರಕ",
      "hiPurpose": "मुंह के छालों, कमजोरी और विटामिन की कमी को दूर करने के लिए",
    },
    "becosules": {
      "composition": "Vitamin B-Complex + Vitamin C",
      "purpose": "Boosts energy, heals tissue, and treats vitamin B deficiency",
      "knPurpose": "ವಿಟಮಿನ್-ಬಿ ಪೂರಕ ಮತ್ತು ಬಾಯಿ ಹುಣ್ಣು ನಿವಾರಣೆ",
      "hiPurpose": "विटामिन बी सप्लीमेंट और छालों से राहत",
    },
    "neurobionforte": {
      "composition": "Vitamin B1 + B2 + B3 + B5 + B6 + B12 (Cyanocobalamin)",
      "purpose": "Restores nerve health, treats numbness, tingling, and nerve pain",
      "knPurpose": "ನರಗಳ ದೌರ್ಬಲ್ಯ, ಮರಗಟ್ಟುವಿಕೆ ಮತ್ತು ಜುಮುಗುಡುವಿಕೆ ನಿವಾರಣೆ",
      "hiPurpose": "नसों की कमजोरी, सुन्नपन और झनझनाहट से राहत",
    },
    "neurobion": {
      "composition": "Vitamin B-Complex (B1, B6, B12)",
      "purpose": "Nourishes nerve cells and treats diabetic neuropathy",
      "knPurpose": "ನರಗಳ ಆರೋಗ್ಯ ಪೂರಕ",
      "hiPurpose": "नसों के पोषण के लिए",
    },
    "limcee500": {
      "composition": "Vitamin C / Ascorbic Acid (500 mg)",
      "purpose": "Immunity booster, antioxidant, and tissue repair supplement",
      "knPurpose": "ರೋಗನಿರೋಧಕ ಶಕ್ತಿ ವೃದ್ಧಿ ಮತ್ತು ವಿಟಮಿನ್-ಸಿ ಪೂರಕ",
      "hiPurpose": "इम्यूनिटी बढ़ाने और विटामिन सी की पूर्ति के लिए",
    },
    "limcee": {
      "composition": "Vitamin C (500 mg)",
      "purpose": "Boosts immune defense and skin health",
      "knPurpose": "ವಿಟಮಿನ್-ಸಿ ಪೂರಕ",
      "hiPurpose": "विटामिन सी सप्लीमेंट",
    },
    "celin500": {
      "composition": "Vitamin C / Ascorbic Acid (500 mg)",
      "purpose": "Immunity enhancer and antioxidant",
      "knPurpose": "ರೋಗನಿರೋಧಕ ಶಕ್ತಿ ಮತ್ತು ವಿಟಮಿನ್-ಸಿ",
      "hiPurpose": "इम्यूनिटी बूस्टर",
    },
    "evion400": {
      "composition": "Vitamin E / Tocopheryl Acetate (400 mg)",
      "purpose": "Antioxidant for muscle cramps, skin nourishment, and cellular health",
      "knPurpose": "ಸ್ನಾಯು ಸೆಳೆತ ನಿವಾರಣೆ, ಚರ್ಮದ ಕಾಂತಿ ಮತ್ತು ವಿಟಮಿನ್-ಇ",
      "hiPurpose": "मांसपेशियों के दर्द, त्वचा और विटामिन ई के लिए",
    },
    "evion": {
      "composition": "Vitamin E (400 mg)",
      "purpose": "Vitamin E supplement for muscles and skin",
      "knPurpose": "ವಿಟಮಿನ್-ಇ ಪೂರಕ",
      "hiPurpose": "विटामिन ई सप्लीमेंट",
    },

    // Topical & Antiseptics
    "betadine": {
      "composition": "Povidone-Iodine IP (5% w/w)",
      "purpose": "Antiseptic for minor cuts, wounds, burns, and skin infection prevention",
      "knPurpose": "ಗಾಯ, ಸುಟ್ಟ ಗಾಯ ಮತ್ತು ಕಡಿತಗಳಿಗೆ ಆಂಟಿಸೆಪ್ಟಿಕ್ ಮುಲಾಮು",
      "hiPurpose": "घाव, कटने और जलने पर इन्फेक्शन रोकने वाला एंटीसेप्टिक",
    },
    "volini": {
      "composition": "Diclofenac Diethylamine + Methyl Salicylate + Menthol",
      "purpose": "Fast relief from joint pain, backache, neck pain, and muscle sprains",
      "knPurpose": "ಮೈ-ಕೈ ನೋವು, ಬೆನ್ನು ನೋವು ಮತ್ತು ಉಳುಕಿಗೆ ಶೀಘ್ರ ಮುಲಾಮು",
      "hiPurpose": "कमर दर्द, जोड़ों के दर्द और मोच से त्वरित राहत",
    },
    "moov": {
      "composition": "Wintergreen Oil + Mint Extract + Turpentine Oil + Eucalyptus Oil",
      "purpose": "Warmth and quick relief from backache and muscle pain",
      "knPurpose": "ಬೆನ್ನು ನೋವು ಮತ್ತು ಸ್ನಾಯು ನೋವು ನಿವಾರಕ ಮುಲಾಮು",
      "hiPurpose": "कमर दर्द और मांसपेशियों के दर्द से राहत",
    },

    // Targeted & Specialty Medications
    "everbliss": {
      "composition": "Everolimus (5 mg)",
      "purpose": "Targeted cellular growth regulation and immunosuppressive therapy",
      "knPurpose": "ಜೀವಕೋಶಗಳ ಅಸಹಜ ಬೆಳವಣಿಗೆ ನಿಯಂತ್ರಣ ಮತ್ತು ರೋಗನಿರೋಧಕ ಔಷಧ",
      "hiPurpose": "असामान्य कोशिका वृद्धि को नियंत्रित करने और इम्यून सिस्टम की दवा",
      "when_to_take": "Take once daily at the same time each day with water, consistently either with or without food. Swallow whole; do not chew or crush.",
      "knWhenToTake": "ಪ್ರತಿದಿನ ಒಂದೇ ಸಮಯದಲ್ಲಿ 1 ಮಾತ್ರೆ ನೀರಿನೊಂದಿಗೆ ನುಂಗಿ. ಅಗಿಯಬೇಡಿ ಅಥವಾ ಪುಡಿಮಾಡಬೇಡಿ.",
      "hiWhenToTake": "रोजाना एक निश्चित समय पर 1 गोली पानी के साथ निगलें; चबाएं या तोड़ें नहीं।",
      "suggested_times": "08:00",
    },
    "everbliss5mg": {
      "composition": "Everolimus (5 mg)",
      "purpose": "Targeted cellular growth regulation and immunosuppressive therapy",
      "knPurpose": "ಜೀವಕೋಶಗಳ ಅಸಹಜ ಬೆಳವಣಿಗೆ ನಿಯಂತ್ರಣ ಮತ್ತು ರೋಗನಿರೋಧಕ ಔಷಧ",
      "hiPurpose": "असामान्य कोशिका वृद्धि को नियंत्रित करने और इम्यून सिस्टम की दवा",
      "when_to_take": "Take once daily at the same time each day with water, consistently either with or without food. Swallow whole; do not chew or crush.",
      "knWhenToTake": "ಪ್ರತಿದಿನ ಒಂದೇ ಸಮಯದಲ್ಲಿ 1 ಮಾತ್ರೆ ನೀರಿನೊಂದಿಗೆ ನುಂಗಿ. ಅಗಿಯಬೇಡಿ ಅಥವಾ ಪುಡಿಮಾಡಬೇಡಿ.",
      "hiWhenToTake": "रोजाना एक निश्चित समय पर 1 गोली पानी के साथ निगलें; चबाएं ಅಥವಾ ಪುಡಿಮಾಡಬೇಡಿ.",
      "suggested_times": "08:00",
    },
    "everolimus": {
      "composition": "Everolimus IP (5 mg)",
      "purpose": "Targeted cellular growth regulation and immunosuppressive therapy",
      "knPurpose": "ಜೀವಕೋಶಗಳ ಅಸಹಜ ಬೆಳವಣಿಗೆ ನಿಯಂತ್ರಣ ಮತ್ತು ರೋಗನಿರೋಧಕ ಔಷಧ",
      "hiPurpose": "असामान्य कोशिका वृद्धि को नियंत्रित करने और इम्यून सिस्टम की दवा",
      "when_to_take": "Take once daily at the same time each day with water, consistently either with or without food. Swallow whole; do not chew or crush.",
      "knWhenToTake": "ಪ್ರತಿದಿನ ಒಂದೇ ಸಮಯದಲ್ಲಿ 1 ಮಾತ್ರೆ ನೀರಿನೊಂದಿಗೆ ನುಂಗಿ. ಅಗಿಯಬೇಡಿ ಅಥವಾ ಪುಡಿಮಾಡಬೇಡಿ.",
      "hiWhenToTake": "रोजाना एक निश्चित समय पर 1 गोली पानी के साथ निगलें; चबाएं ಅಥವಾ ಪುಡಿಮಾಡಬೇಡಿ.",
      "suggested_times": "08:00",
    },
    "everolimus5mg": {
      "composition": "Everolimus IP (5 mg)",
      "purpose": "Targeted cellular growth regulation and immunosuppressive therapy",
      "knPurpose": "ಜೀವಕೋಶಗಳ ಅಸಹಜ ಬೆಳವಣಿಗೆ ನಿಯಂತ್ರಣ ಮತ್ತು ರೋಗನಿರೋಧಕ ಔಷಧ",
      "hiPurpose": "असामान्य कोशिका वृद्धि को नियंत्रित करने और इम्यून सिस्टम की दवा",
      "when_to_take": "Take once daily at the same time each day with water, consistently either with or without food. Swallow whole; do not chew or crush.",
      "knWhenToTake": "ಪ್ರತಿದಿನ ಒಂದೇ ಸಮಯದಲ್ಲಿ 1 ಮಾತ್ರೆ ನೀರಿನೊಂದಿಗೆ ನುಂಗಿ. ಅಗಿಯಬೇಡಿ ಅಥವಾ ಪುಡಿಮಾಡಬೇಡಿ.",
      "hiWhenToTake": "रोजाना एक निश्चित समय पर 1 गोली पानी के साथ निगलें; चबाएं ಅಥವಾ ಪುಡಿಮಾಡಬೇಡಿ.",
      "suggested_times": "08:00",
    },
  };

  /// Extract raw text from an image file using Google ML Kit on-device OCR with fallback
  Future<String> extractRawText(File imageFile) async {
    if (kIsWeb) {
      debugPrint("ML Kit OCR is not available directly on Web.");
      return "";
    }

    try {
      if (!await imageFile.exists() || await imageFile.length() == 0) {
        debugPrint("ML Kit OCR error: file missing or 0 bytes: ${imageFile.path}");
        return "";
      }
      debugPrint("Starting ML Kit OCR on image: ${imageFile.path} (${await imageFile.length()} bytes)");
      final inputImage = InputImage.fromFilePath(imageFile.path);
      TextRecognizer textRecognizer;
      try {
        textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      } catch (_) {
        textRecognizer = TextRecognizer();
      }

      var recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      String text = _extractOrderedLines(recognizedText);

      // If latin recognizer found nothing or very short text, attempt with generic script recognizer
      if (text.length < 5) {
        try {
          final genericRecognizer = TextRecognizer();
          recognizedText = await genericRecognizer.processImage(inputImage);
          await genericRecognizer.close();
          final genericText = _extractOrderedLines(recognizedText);
          if (genericText.length > text.length) {
            text = genericText;
          }
        } catch (_) {}
      }



      debugPrint("ML Kit OCR extracted ${text.length} characters.");
      if (text.isNotEmpty) {
        debugPrint("Extracted OCR snippet: ${text.substring(0, text.length > 300 ? 300 : text.length).replaceAll('\n', ' ')}");
      }
      return text;
    } catch (e) {
      debugPrint("ML Kit OCR processing error: $e");
      return "";
    }
  }

  String _extractOrderedLines(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) {
      return recognizedText.text.trim();
    }
    final allLines = <TextLine>[];
    for (final block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }
    if (allLines.isEmpty) {
      return recognizedText.text.trim();
    }

    // Sort by Y position (top-to-bottom), then X position (left-to-right) for aligned columns
    allLines.sort((a, b) {
      final yDiff = (a.boundingBox.top - b.boundingBox.top).abs();
      if (yDiff <= 14) {
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return a.boundingBox.top.compareTo(b.boundingBox.top);
    });

    final ordered = allLines
        .map((l) => l.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n');
    return ordered.isNotEmpty ? ordered : recognizedText.text.trim();
  }

  /// Normalizes and cleans OCR text, fixing character misrecognitions on pharmaceutical packages
  String _cleanOcrText(String text) {
    if (text.trim().isEmpty) return "";
    var cleaned = text;

    // 1. Fix common OCR number substitutions before units (mg, mcg, g, ml, tabs, etc.)
    // e.g. "Smg" -> "5 mg", "s mg" -> "5 mg", "65Omg" -> "650 mg", "l0mg" -> "10 mg", "O.5mg" -> "0.5 mg"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\b([0-9SlIOoZzB\.]+)\s*(mg|mcg|µg|g|ml|iu|tabs?|caps?)\b', caseSensitive: false),
      (m) {
        String digits = m.group(1)!;
        final unit = m.group(2)!;
        digits = digits
            .replaceAll('S', '5')
            .replaceAll('s', '5')
            .replaceAll('O', '0')
            .replaceAll('o', '0')
            .replaceAll('l', '1')
            .replaceAll('I', '1')
            .replaceAll('|', '1')
            .replaceAll('Z', '2')
            .replaceAll('z', '2')
            .replaceAll('B', '8');
        return '$digits $unit';
      },
    );

    // 2. Fix OCR numbers attached to popular brand names: e.g. "Dolo 65O" -> "Dolo 650", "Pan 4O" -> "Pan 40"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\b(dolo|pan|calpol|crocin|fever[\- ]?x|augmentin|omez|taxim|azithral|everbliss)\s*([0-9SlIOoZzB]+)\b', caseSensitive: false),
      (m) {
        final brand = m.group(1)!;
        String digits = m.group(2)!;
        digits = digits
            .replaceAll('S', '5')
            .replaceAll('s', '5')
            .replaceAll('O', '0')
            .replaceAll('o', '0')
            .replaceAll('l', '1')
            .replaceAll('I', '1')
            .replaceAll('Z', '2')
            .replaceAll('z', '2')
            .replaceAll('B', '8');
        return '$brand $digits';
      },
    );

    // 3. Fix common OCR misspellings in pharmaceutical words
    cleaned = cleaned
        .replaceAll(RegExp(r'\bTableis\b', caseSensitive: false), 'Tablets')
        .replaceAll(RegExp(r'\bTadlets\b', caseSensitive: false), 'Tablets')
        .replaceAll(RegExp(r'\bTablsts\b', caseSensitive: false), 'Tablets')
        .replaceAll(RegExp(r'\bCaprules\b', caseSensitive: false), 'Capsules')
        .replaceAll(RegExp(r'\byaician\b', caseSensitive: false), 'physician')
        .replaceAll(RegExp(r'\bdirncted\b', caseSensitive: false), 'directed')
        .replaceAll(RegExp(r'\bprcrption\b', caseSensitive: false), 'prescription')
        .replaceAll(RegExp(r'\bwagierod\b', caseSensitive: false), 'registered')
        .replaceAll(RegExp(r'\bPracaboner\b', caseSensitive: false), 'Practitioner');

    return cleaned;
  }

  /// Parses raw OCR text into structured medicine packaging data
  Map<String, dynamic> parseMedicineText(String rawText, {String? language}) {
    if (rawText.trim().isEmpty) {
      return _generateEmptyResult(language);
    }

    // Clean OCR text first to normalize common character substitutions (Smg -> 5 mg, etc.)
    final cleanedText = _cleanOcrText(rawText);

    final lines = cleanedText
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. Extract Strength
    final strength = _extractStrength(cleanedText);

    // 2. Extract Pharmaceutical Form
    final form = _extractForm(cleanedText);

    // 3. Extract Medicine Name
    final name = _extractMedicineName(lines, cleanedText, strength, form);

    // 4. Extract Composition (Active Ingredients / What is available in the medicine)
    final composition = _extractComposition(lines, cleanedText, name, strength);

    // 5. Extract Purpose / Indication
    final purpose = _extractPurpose(name, composition, cleanedText, language: language);

    // 6. Extract Expiry Date
    final expiryDate = _extractExpiryDate(cleanedText);

    // 7. Extract Instructions
    final instructions = _extractInstructions(cleanedText, form);

    // 8. Generate Dosage
    final dosage = _extractDosage(cleanedText, form);

    // 9. Extract When to take (Directions & Timing)
    final whenToTake = _extractWhenToTake(name, composition, cleanedText, instructions, language: language);

    // 10. Extract Suggested Schedule Times
    final suggestedTimes = _extractSuggestedTimes(name, composition, whenToTake, cleanedText);

    // 11. Calculate confidence
    String confidence = "high";
    if (name.isEmpty || name == "Medicine") {
      confidence = "low";
    } else if (expiryDate.isEmpty) {
      confidence = "medium";
    }

    // 12. Generate spoken summary
    final cleanPackagingLines = lines.where((l) => !_isBoilerplate(l) && l.length >= 3 && !l.toLowerCase().contains(name.toLowerCase())).take(3).toList();
    final spokenSummary = _generateMedicineSpokenSummary(
      name: name,
      strength: strength,
      form: form,
      composition: composition,
      purpose: purpose,
      expiryDate: expiryDate,
      instructions: instructions,
      dosage: dosage,
      language: language,
      packagingLines: cleanPackagingLines,
    );

    return {
      "name": name.isNotEmpty ? name : "Medicine",
      "dosage": dosage,
      "form": form.isNotEmpty ? form : "Tablet",
      "strength": strength,
      "composition": composition,
      "purpose": purpose,
      "when_to_take": whenToTake,
      "suggested_times": suggestedTimes,
      "expiry_date": expiryDate,
      "instructions": instructions,
      "scanned_text": rawText,
      "confidence": confidence,
      "spoken_summary": spokenSummary,
    };
  }

  /// Extracts strength (e.g. "650 mg", "500 mg", "40 mg", "5 ml", "0.5% w/w")
  String _extractStrength(String text) {
    // 1. Dual strengths e.g. "500 mg / 125 mg" or "500mg + 125mg"
    final dualMatch = RegExp(
      r'(\d+(?:\.\d+)?\s*(?:mg|g|mcg|µg|ml)\s*[\/\+]\s*\d+(?:\.\d+)?\s*(?:mg|g|mcg|µg|ml))',
      caseSensitive: false,
    ).firstMatch(text);
    if (dualMatch != null) {
      return dualMatch.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    // 2. Percentage strengths e.g. "5% w/w", "0.3% w/v", "2%"
    final percentMatch = RegExp(
      r'(\d+(?:\.\d+)?\s*%\s*(?:w\/w|w\/v|v\/v)?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (percentMatch != null) {
      return percentMatch.group(1)!.trim();
    }

    // 3. Single standard strength e.g. "650 mg", "500mg", "40 mg", "2.5 mg", "100 ml"
    final singleMatch = RegExp(
      r'(\b\d+(?:\.\d+)?\s*(?:mg|g|mcg|µg|ml|iu)\b)',
      caseSensitive: false,
    ).firstMatch(text);
    if (singleMatch != null) {
      return singleMatch.group(1)!.trim();
    }

    // 4. Numbers attached to brand like "Dolo 650", "Pan 40", "Everbliss 5"
    final attachedMatch = RegExp(
      r'(?:dolo|pan|calpol|crocin|azithral|shelcal|augmentin|cetzine|omez|everbliss|amlong|losar|aten)\s*(\d+(?:\.\d+)?)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (attachedMatch != null) {
      return "${attachedMatch.group(1)} mg";
    }

    return "";
  }

  /// Extracts dosage amount
  String _extractDosage(String text, String form) {
    final match = RegExp(
      r'\b(?:(?:take|instill|apply)\s+)?(\d+(?:\s*(?:to|-)\s*\d+)?|\b(?:one|two|half)\b)\s*(tablet|capsule|spoon|drop|puff)s?\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final amount = match.group(1)!.trim();
      final unit = match.group(2)!.trim();
      final isPlural = amount.contains('to') || amount.contains('-') || (amount != '1' && amount != 'one');
      return "$amount $unit${isPlural ? 's' : ''}";
    }
    if (form == "Capsule") return "1 capsule";
    if (form == "Syrup") return "5 to 10 ml";
    if (form == "Drops") return "1 to 2 drops";
    if (form == "Inhaler") return "1 to 2 puffs";
    if (form == "Cream / Ointment") return "Thin layer";
    return "1 tablet";
  }

  /// Extracts pharmaceutical form
  String _extractForm(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("capsule") || lower.contains("cap.")) return "Capsule";
    if (lower.contains("syrup") || lower.contains("suspension") || lower.contains("elixir") || lower.contains("syr.")) return "Syrup";
    if (lower.contains("eye drop") || lower.contains("ear drop") || lower.contains("drops")) return "Drops";
    if (lower.contains("ointment") || lower.contains("gel") || lower.contains("cream") || lower.contains("lotion")) return "Cream / Ointment";
    if (lower.contains("inhaler") || lower.contains("rotacap") || lower.contains("respules") || lower.contains("spray")) return "Inhaler";
    if (lower.contains("injection") || lower.contains("inj.") || lower.contains("vial") || lower.contains("ampoule")) return "Injection";
    if (lower.contains("tablet") || lower.contains("tab.") || lower.contains("tab")) return "Tablet";
    return "Tablet";
  }

  /// Extracts medicine brand name or active drug name
  String _extractMedicineName(List<String> lines, String fullText, String strength, String form) {
    // 1. Check known proprietary brand names first
    for (final brand in _brandMedicines) {
      final reg = RegExp(r'\b' + RegExp.escape(brand) + r'\b', caseSensitive: false);
      if (reg.hasMatch(fullText)) {
        return brand;
      }
    }

    // 2. Check known medicines list (and rank by specificity and position)
    final candidates = <Map<String, dynamic>>[];
    for (final known in _knownMedicines) {
      final reg = RegExp(r'\b' + RegExp.escape(known) + r'\b', caseSensitive: false);
      final match = reg.firstMatch(fullText);
      if (match != null) {
        int lineIndex = 999;
        for (int i = 0; i < lines.length; i++) {
          if (reg.hasMatch(lines[i])) {
            lineIndex = i;
            break;
          }
        }
        candidates.add({
          'name': known,
          'index': match.start,
          'line': lineIndex,
          'length': known.length,
          'hasNumber': RegExp(r'\d').hasMatch(known),
          'isBrand': _brandMedicines.contains(known),
        });
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) {
        final isBrandA = a['isBrand'] == true ? 1 : 0;
        final isBrandB = b['isBrand'] == true ? 1 : 0;
        if (isBrandB != isBrandA) return isBrandB.compareTo(isBrandA);

        final numA = a['hasNumber'] == true ? 1 : 0;
        final numB = b['hasNumber'] == true ? 1 : 0;
        if (numB != numA) return numB.compareTo(numA);

        final lineDiff = (a['line'] as int).compareTo(b['line'] as int);
        if (lineDiff != 0) return lineDiff;

        final lenDiff = (b['length'] as int).compareTo(a['length'] as int);
        if (lenDiff != 0) return lenDiff;

        return (a['index'] as int).compareTo(b['index'] as int);
      });
      return candidates.first['name'] as String;
    }

    // 3. Inspect lines near the top before generic/composition lines:
    // If a non-boilerplate line is followed by "... Tablets IP" or "... Capsules IP" or "Each ... contains",
    // that preceding line is the commercial brand name!
    for (int i = 0; i < lines.length && i < 6; i++) {
      final line = lines[i].trim();
      if (line.length < 3 || line.length > 35) continue;
      if (_isBoilerplate(line)) continue;

      if (i + 1 < lines.length) {
        final nextLine = lines[i + 1].toLowerCase();
        if (nextLine.contains("tablet") || nextLine.contains("capsule") || nextLine.contains("syrup") || nextLine.contains("ip") || nextLine.contains("contains")) {
          final cleanBrand = line.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-\.]'), '').trim();
          if (cleanBrand.length >= 3 && RegExp(r'[a-zA-Z]').hasMatch(cleanBrand) && !_isBoilerplate(cleanBrand)) {
            final prefixMatch = RegExp(r'^(?:tab|cap|syr|inj)\.?\s*(.+)', caseSensitive: false).firstMatch(cleanBrand);
            return prefixMatch != null ? prefixMatch.group(1)!.trim() : cleanBrand;
          }
        }
      }
    }

    // 4. Look for prominent Brand Pattern with Number (e.g. "EVERBLISS 5", "DOLO 650", "PAN 40", "AUGMENTIN 625")
    final brandWithNum = RegExp(
      r'\b([A-Z][A-Za-z0-9\-]{2,20})\s*[\-]?\s*(\d+(?:\.\d+)?)\s*(?:mg|g|mcg|ml)?\b',
    ).firstMatch(fullText);
    if (brandWithNum != null) {
      final brand = brandWithNum.group(1)!.trim();
      final num = brandWithNum.group(2)!.trim();
      if (!_isBoilerplate(brand) && brand.toLowerCase() != "tablets" && brand.toLowerCase() != "capsules") {
        return "$brand $num";
      }
    }

    // 5. Look for Pharmacopoeia Generic Name lines:
    // e.g. "Paracetamol Tablets IP 650 mg", "Amoxycillin and Potassium Clavulanate Tablets IP"
    final ipMatch = RegExp(
      r'([A-Za-z0-9\s\-\+\&\,]+?)\s+(?:Tablets|Capsules|Syrup|Injection|Suspension|Drops|Gel|Ointment)\s*(?:IP|BP|USP)?',
      caseSensitive: false,
    ).firstMatch(fullText);
    if (ipMatch != null) {
      final matchedName = ipMatch.group(1)!.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
      if (matchedName.length >= 3 && matchedName.length <= 45 && !_isBoilerplate(matchedName)) {
        return strength.isNotEmpty ? "$matchedName $strength" : matchedName;
      }
    }

    // 6. Inspect clean lines near top
    for (int i = 0; i < lines.length && i < 8; i++) {
      final line = lines[i].trim();
      if (line.length < 3 || line.length > 40) continue;
      if (_isBoilerplate(line)) continue;

      final clean = line.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-\.]'), '').trim();
      if (clean.length >= 3 && RegExp(r'[a-zA-Z]').hasMatch(clean)) {
        final prefixMatch = RegExp(r'^(?:tab|cap|syr|inj)\.?\s*(.+)', caseSensitive: false).firstMatch(clean);
        return prefixMatch != null ? prefixMatch.group(1)!.trim() : clean;
      }
    }

    // 7. General fallback: return first readable text line
    for (final line in lines) {
      final clean = line.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-\.]'), '').trim();
      if (clean.length >= 3 && RegExp(r'[a-zA-Z]{3,}').hasMatch(clean) && !_isBoilerplate(clean)) {
        return clean;
      }
    }

    if (strength.isNotEmpty) {
      return "Medicine $strength";
    }
    return "Medicine";
  }

  bool _isBoilerplate(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return true;
    for (final bp in _boilerplateLines) {
      if (lower.contains(bp)) return true;
    }
    if (RegExp(r'^\s*\d+\s*(?:tablets?|capsules?|tabs?|caps?|softgels?|pills?|strip|strips|blister|bottle|vials?|sachets?|units?|n|pcs?)\s*$', caseSensitive: false).hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'^(?:strip\s*of|pack\s*of|blister\s*of)\s*\d+', caseSensitive: false).hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'^(?:net\s*(?:qty|vol|weight|content)|m\.?r\.?p|batch\s*no|b\.?\s*no|mfg|mfd|exp|lot\s*no)', caseSensitive: false).hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'^(?:for\s*(?:oral|external)\s*use|schedule\s*[ghx]|caution|warning)', caseSensitive: false).hasMatch(lower)) {
      return true;
    }
    return false;
  }

  /// Normalizes brand or generic name into alphanumeric key for database lookup
  String _normalizeKey(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Cleans and sanitizes raw composition text by stripping excipients and manufacturing boilerplate
  String _cleanComposition(String comp) {
    var cleaned = comp.trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[:\-\s]+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'(?:excipients\s*q\.?s\.?|colour:?|color:?|titanium\s*dioxide|sunset\s*yellow|lake\s*of\s*tartrazine|dosage:?|as\s*directed|storage:?|store\s*below).*', caseSensitive: false), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'[\s,;\.\-]+$'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  /// Extracts active ingredients (composition) available in the medicine
  String _extractComposition(List<String> lines, String rawText, String matchedName, String strength) {
    // 1. Look for explicit packaging patterns in rawText:
    // e.g. "Each uncoated tablet contains: Paracetamol IP 650 mg"
    final containsMatch = RegExp(
      r'(?:each\s+(?:[a-z\-]+\s+)?(?:tablet|capsule|5ml|ml)\s+contains[:\s]+|contains[:\s]+|composition[:\s]+)(.+?)(?=\.|\n|dosage|storage|mfg|exp|keep|warning|caution|batch|lic|mrp|pkg|marketed|manufactured|pvt|ltd|$)',
      caseSensitive: false,
    ).firstMatch(rawText);
    if (containsMatch != null) {
      String comp = containsMatch.group(1)!.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
      comp = _cleanComposition(comp);
      if (comp.length >= 4 && !_isBoilerplate(comp)) {
        return comp;
      }
    }

    // 2. Look for Pharmacopoeia IP/BP/USP line:
    // e.g. "Paracetamol Tablets IP 650 mg", "Amoxycillin and Potassium Clavulanate Tablets IP"
    final ipMatch = RegExp(
      r'([A-Za-z0-9\s\-\+\&\,]+?)\s+(?:Tablets|Capsules|Syrup|Injection|Suspension|Drops|Gel|Ointment)\s*(?:IP|BP|USP)',
      caseSensitive: false,
    ).firstMatch(rawText);
    if (ipMatch != null) {
      String comp = ipMatch.group(1)!.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
      comp = _cleanComposition(comp);
      if (comp.length >= 4 && !_isBoilerplate(comp)) {
        return comp;
      }
    }

    // 3. Fallback to Medical Knowledge Dictionary by matched medicine key
    final key = _normalizeKey(matchedName);
    if (_medicineDatabase.containsKey(key)) {
      return _medicineDatabase[key]!['composition'] ?? "";
    }

    for (final entry in _medicineDatabase.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value['composition'] ?? "";
      }
    }

    // 4. If medicine name has generic drug ingredient (e.g. Paracetamol)
    if (matchedName.isNotEmpty && matchedName != "Medicine") {
      final strSuffix = strength.isNotEmpty ? " ($strength)" : "";
      return "$matchedName$strSuffix";
    }

    return "";
  }

  /// Extracts the therapeutic purpose / medical indication of the medicine
  String _extractPurpose(String matchedName, String composition, String rawText, {String? language}) {
    final key = _normalizeKey(matchedName);
    final lang = language ?? 'en-US';

    // 1. Direct dictionary lookup
    Map<String, String>? info = _medicineDatabase[key];
    if (info == null) {
      for (final entry in _medicineDatabase.entries) {
        if (key.contains(entry.key) || entry.key.contains(key)) {
          info = entry.value;
          break;
        }
      }
    }

    if (info != null) {
      if (lang.startsWith('kn') && info['knPurpose'] != null && info['knPurpose']!.isNotEmpty) {
        return info['knPurpose']!;
      }
      if (lang.startsWith('hi') && info['hiPurpose'] != null && info['hiPurpose']!.isNotEmpty) {
        return info['hiPurpose']!;
      }
      return info['purpose'] ?? "";
    }

    // 2. Clinical class heuristics
    final combined = "$matchedName $composition $rawText".toLowerCase();
    if (combined.contains("paracetamol") || combined.contains("ibuprofen") || combined.contains("aceclofenac") || combined.contains("diclofenac")) {
      return lang.startsWith('kn') ? "ಜ್ವರ ಮತ್ತು ನೋವು ನಿವಾರಣೆ" : lang.startsWith('hi') ? "बुखार और दर्द से राहत" : "Fever and pain relief";
    }
    if (combined.contains("amoxicillin") || combined.contains("azithromycin") || combined.contains("cefixime") || combined.contains("ciprofloxacin") || combined.contains("ofloxacin")) {
      return lang.startsWith('kn') ? "ಬ್ಯಾಕ್ಟೀರಿಯಾ ಸೋಂಕು ನಿವಾರಕ ಆಂಟಿಬಯೋಟಿಕ್" : lang.startsWith('hi') ? "बैक्टीरियल संक्रमण के इलाज के लिए एंटीबायोटिक" : "Antibiotic for bacterial infections";
    }
    if (combined.contains("pantoprazole") || combined.contains("omeprazole") || combined.contains("rabeprazole") || combined.contains("esomeprazole")) {
      return lang.startsWith('kn') ? "ಅಸಿಡಿಟಿ ಮತ್ತು ಎದೆಯುರಿ ನಿವಾರಣೆ" : lang.startsWith('hi') ? "एसिडिटी और सीने में जलन से राहत" : "Acidity and heartburn relief";
    }
    if (combined.contains("metformin") || combined.contains("glimepiride") || combined.contains("vildagliptin") || combined.contains("dapagliflozin")) {
      return lang.startsWith('kn') ? "ಮಧುಮೇಹದಲ್ಲಿ ರಕ್ತದ ಸಕ್ಕರೆ ನಿಯಂತ್ರಣ" : lang.startsWith('hi') ? "डायबिटीज में ब्लड शुगर का नियंत्रण" : "Blood sugar control for diabetes";
    }
    if (combined.contains("telmisartan") || combined.contains("amlodipine") || combined.contains("atenolol") || combined.contains("losartan")) {
      return lang.startsWith('kn') ? "ರಕ್ತದೊತ್ತಡ (BP) ನಿಯಂತ್ರಣ" : lang.startsWith('hi') ? "ब्लड प्रेशर (बीपी) नियंत्रण" : "Blood pressure control";
    }
    if (combined.contains("atorvastatin") || combined.contains("rosuvastatin")) {
      return lang.startsWith('kn') ? "ಕೊಲೆಸ್ಟ್ರಾಲ್ ನಿಯಂತ್ರಣ ಮತ್ತು ಹೃದಯ ರಕ್ಷಣೆ" : lang.startsWith('hi') ? "कोलेस्ट्रॉल का नियंत्रण और हृदय सुरक्षा" : "Cholesterol control and heart protection";
    }
    if (combined.contains("cetirizine") || combined.contains("levocetirizine") || combined.contains("fexofenadine") || combined.contains("montelukast")) {
      return lang.startsWith('kn') ? "ಅಲರ್ಜಿ, ಸೀನು ಮತ್ತು ನೆಗಡಿ ನಿವಾರಣೆ" : lang.startsWith('hi') ? "एलर्जी, छींक और जुकाम से राहत" : "Allergy, cold, and sneezing relief";
    }
    if (combined.contains("everolimus") || combined.contains("everbliss")) {
      return lang.startsWith('kn') ? "ಜೀವಕೋಶಗಳ ಅಸಹಜ ಬೆಳವಣಿಗೆ ನಿಯಂತ್ರಣ ಮತ್ತು ರೋಗನಿರೋಧಕ ಔಷಧ" : lang.startsWith('hi') ? "असामान्य कोशिका वृद्धि को नियंत्रित करने और इम्यून सिस्टम की दवा" : "Targeted cellular regulation and immunosuppressive therapy";
    }

    return "";
  }

  /// Extracts or clinically infers when and how to take the medicine
  String _extractWhenToTake(
    String matchedName,
    String composition,
    String rawText,
    String instructions, {
    String? language,
  }) {
    final lang = language ?? 'en-US';
    final key = _normalizeKey(matchedName);

    // 1. Direct dictionary lookup
    Map<String, String>? info = _medicineDatabase[key];
    if (info == null) {
      for (final entry in _medicineDatabase.entries) {
        if (key.contains(entry.key) || entry.key.contains(key)) {
          info = entry.value;
          break;
        }
      }
    }

    if (info != null) {
      if ((lang.startsWith('kn')) && info['knWhenToTake'] != null && info['knWhenToTake']!.isNotEmpty) {
        return info['knWhenToTake']!;
      }
      if ((lang.startsWith('hi')) && info['hiWhenToTake'] != null && info['hiWhenToTake']!.isNotEmpty) {
        return info['hiWhenToTake']!;
      }
      if (info['when_to_take'] != null && info['when_to_take']!.isNotEmpty) {
        return info['when_to_take']!;
      }
    }

    // 2. Packaging text indicators
    final lower = rawText.toLowerCase();
    if (lower.contains("before food") || lower.contains("before meals") || lower.contains("empty stomach") || lower.contains("a.c")) {
      return lang.startsWith('kn')
          ? "ಊಟಕ್ಕಿಂತ ಮುಂಚೆ ಖಾಲಿ ಹೊಟ್ಟೆಯಲ್ಲಿ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ."
          : lang.startsWith('hi')
              ? "भोजन से पहले खाली पेट पानी के साथ लें।"
              : "Take on an empty stomach with water, 30 minutes before meals.";
    }
    if (lower.contains("after food") || lower.contains("after meals") || lower.contains("p.c")) {
      return lang.startsWith('kn')
          ? "ಊಟದ ನಂತರ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ."
          : lang.startsWith('hi')
              ? "भोजन के बाद पानी के साथ लें।"
              : "Take after meals with a glass of water.";
    }
    if (lower.contains("bedtime") || lower.contains("at night") || lower.contains("h.s")) {
      return lang.startsWith('kn')
          ? "ರಾತ್ರಿ ಮಲಗುವ ಮುನ್ನ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ."
          : lang.startsWith('hi')
              ? "रात को सोने से पहले पानी के साथ लें।"
              : "Take once daily at bedtime with water.";
    }

    // 3. Clinical pharmacological classes
    final combined = "$matchedName $composition $rawText".toLowerCase();
    if (combined.contains("everolimus") || combined.contains("everbliss")) {
      return lang.startsWith('kn')
          ? "ಪ್ರತಿದಿನ ಒಂದೇ ಸಮಯದಲ್ಲಿ 1 ಮಾತ್ರೆ ನೀರಿನೊಂದಿಗೆ ನುಂಗಿ. ಅಗಿಯಬೇಡಿ ಅಥವಾ ಪುಡಿಮಾಡಬೇಡಿ."
          : lang.startsWith('hi')
              ? "रोजाना एक निश्चित समय पर 1 गोली पानी के साथ निगलें; चबाएं या तोड़ें नहीं।"
              : "Take once daily at the same time each day with water. Swallow whole; do not chew or crush.";
    }
    if (combined.contains("prazole") || combined.contains("pantop") || combined.contains("omep") || combined.contains("rabep")) {
      return lang.startsWith('kn')
          ? "ಬೆಳಿಗ್ಗೆ ಉಪಹಾರಕ್ಕಿಂತ 30 ನಿಮಿಷ ಮುಂಚೆ ಖಾಲಿ ಹೊಟ್ಟೆಯಲ್ಲಿ ನೀರಿನೊಂದಿಗೆ ನುಂಗಿ."
          : lang.startsWith('hi')
              ? "सुबह नाश्ते से 30 मिनट पहले खाली पेट पानी के साथ निगलें।"
              : "Take in the morning on an empty stomach, 30 minutes before breakfast with water.";
    }
    if (combined.contains("paracetamol") || combined.contains("ibuprofen") || combined.contains("aceclo") || combined.contains("diclo") || combined.contains("mefenamic")) {
      return lang.startsWith('kn')
          ? "ಊಟ ಅಥವಾ ತಿಂಡಿಯ ನಂತರ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ."
          : lang.startsWith('hi')
              ? "भोजन या नाश्ते के बाद पानी के साथ लें।"
              : "Take after food with water to avoid stomach irritation.";
    }
    if (combined.contains("metformin") || combined.contains("glimepiride") || combined.contains("glycomet")) {
      return lang.startsWith('kn')
          ? "ಊಟದ ಜೊತೆಗೆ ಅಥವಾ ಊಟವಾದ ತಕ್ಷಣ ತೆಗೆದುಕೊಳ್ಳಿ."
          : lang.startsWith('hi')
              ? "भोजन के साथ या तुरंत बाद लें।"
              : "Take with or immediately after meals to maintain sugar levels.";
    }
    if (combined.contains("atorvastatin") || combined.contains("rosuvastatin") || combined.contains("statin")) {
      return lang.startsWith('kn')
          ? "ರಾತ್ರಿ ಊಟದ ನಂತರ ಮಲಗುವ ಮುನ್ನ ತೆಗೆದುಕೊಳ್ಳಿ."
          : lang.startsWith('hi')
              ? "रात के खाने के बाद सोने से पहले लें।"
              : "Take once daily at night / bedtime after dinner.";
    }
    if (combined.contains("cetirizine") || combined.contains("levocet") || combined.contains("allegra") || combined.contains("montair")) {
      return lang.startsWith('kn')
          ? "ರಾತ್ರಿ ಊಟದ ನಂತರ ತೆಗೆದುಕೊಳ್ಳಿ (ನಿದ್ರೆ ತರಿಸಬಹುದು)."
          : lang.startsWith('hi')
              ? "रात के खाने के बाद लें (नींद आ सकती है)।"
              : "Take once daily at night after food (may cause mild drowsiness).";
    }
    if (combined.contains("thyronorm") || combined.contains("eltroxin") || combined.contains("thyroxine")) {
      return lang.startsWith('kn')
          ? "ಮುಂಜಾನೆ ಖಾಲಿ ಹೊಟ್ಟೆಯಲ್ಲಿ ನೀರಿನೊಂದಿಗೆ ತೆಗೆದುಕೊಳ್ಳಿ. ನಂತರ 30 ನಿಮಿಷ ಏನೂ ತಿನ್ನಬೇಡಿ."
          : lang.startsWith('hi')
              ? "सुबह खाली पेट पानी के साथ लें। इसके 30 मिनट बाद तक कुछ न खाएं।"
              : "Take early morning on an empty stomach with plain water. Wait 30 minutes before eating or tea.";
    }

    // Default safe clinical instruction
    return lang.startsWith('kn')
        ? "ಊಟದ ನಂತರ ನೀರಿನೊಂದಿಗೆ 1 ಮಾತ್ರೆ ತೆಗೆದುಕೊಳ್ಳಿ."
        : lang.startsWith('hi')
            ? "भोजन के बाद 1 गोली पानी के साथ लें।"
            : "Take 1 dose after meals with a glass of water.";
  }

  /// Extracts suggested schedule times
  List<String> _extractSuggestedTimes(
    String name,
    String composition,
    String whenToTake,
    String rawText,
  ) {
    final lower = "$name $composition $whenToTake $rawText".toLowerCase();

    final key = _normalizeKey(name);
    final dbEntry = _medicineDatabase[key];
    if (dbEntry != null && dbEntry['suggested_times'] != null && dbEntry['suggested_times']!.isNotEmpty) {
      return dbEntry['suggested_times']!.split(',').map((s) => s.trim()).toList();
    }

    if (lower.contains("empty stomach") || lower.contains("before breakfast") || lower.contains("before food") || lower.contains("thyronorm") || lower.contains("pantop")) {
      return ["08:00"];
    }
    if (lower.contains("bedtime") || lower.contains("at night") || lower.contains("sleeping") || lower.contains("statin")) {
      return ["21:00"];
    }
    if (lower.contains("thrice") || lower.contains("three times") || lower.contains("t.d.s") || lower.contains("1-1-1")) {
      return ["08:00", "14:00", "20:00"];
    }
    if (lower.contains("twice") || lower.contains("1-0-1") || lower.contains("morning and night") || lower.contains("morning and evening") || lower.contains("b.d")) {
      return ["08:00", "20:00"];
    }
    if (lower.contains("once daily") || lower.contains("o.d") || lower.contains("everbliss") || lower.contains("everolimus")) {
      return ["08:00"];
    }

    return ["08:00", "20:00"];
  }

  /// Extracts Expiry Date and standardizes to YYYY-MM-DD
  String _extractExpiryDate(String text) {
    if (text.trim().isEmpty) return "";

    // Normalize OCR confusion: letter 'O'/'o' inside numbers to '0'
    final normalizedText = text.replaceAllMapped(
      RegExp(r'(?<=\d)[Oo](?=\d)|(?<=\b[Ee][Xx][Pp][:\s\.\-]*)[Oo](?=\d)'),
      (m) => '0',
    );

    final monthNames = {
      "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
      "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12,
      "january": 1, "february": 2, "march": 3, "april": 4, "june": 6,
      "july": 7, "august": 8, "september": 9, "october": 10, "november": 11, "december": 12
    };

    final prefix = r'(?:exp(?:\.|\b)|expiry|exp\.?\s*d(?:a)?t(?:e)?|use\s*before|use\s*by|best\s*before|valid\s*till|valid\s*upto|e\.?d\.?)';

    // 1. Day / Month / Year with prefix: e.g. EXP. 15/08/2026 or 15-08-26 or 15.08.2026
    final dmyMatch = RegExp(
      prefix + r'[:\s\.\-]*([0-3]?\d)\s*[\/\-\.]\s*(0?[1-9]|1[0-2])\s*[\/\-\.]\s*(20\d{2}|\d{2})\b',
      caseSensitive: false,
    ).firstMatch(normalizedText);
    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!);
      final month = int.tryParse(dmyMatch.group(2)!);
      int? year = int.tryParse(dmyMatch.group(3)!);
      if (year != null && year < 100) year += 2000;
      if (day != null && month != null && year != null && day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2020 && year <= 2045) {
        final mStr = month < 10 ? "0$month" : "$month";
        final dStr = day < 10 ? "0$day" : "$day";
        return "$year-$mStr-$dStr";
      }
    }

    // 2. Month / Year with prefix: e.g. EXP: 11/2026 or EXP 05 / 2026 or EXP.DT: 08/2027 or EXP. 12-26
    final myMatch = RegExp(
      prefix + r'[:\s\.\-]*([0-1]?\d)\s*[\/\-\.]\s*(20\d{2}|\d{2})\b',
      caseSensitive: false,
    ).firstMatch(normalizedText);
    if (myMatch != null) {
      final month = int.tryParse(myMatch.group(1)!);
      int? year = int.tryParse(myMatch.group(2)!);
      if (year != null && year < 100) year += 2000;
      if (month != null && month >= 1 && month <= 12 && year != null && year >= 2020 && year <= 2045) {
        final lastDay = DateTime(year, month + 1, 0).day;
        final mStr = month < 10 ? "0$month" : "$month";
        final dStr = lastDay < 10 ? "0$lastDay" : "$lastDay";
        return "$year-$mStr-$dStr";
      }
    }

    // 3. Year / Month with prefix: e.g. EXP: 2026/08 or EXP 2026-11
    final ymMatch = RegExp(
      prefix + r'[:\s\.\-]*(20\d{2})\s*[\/\-\.]\s*(0?[1-9]|1[0-2])\b',
      caseSensitive: false,
    ).firstMatch(normalizedText);
    if (ymMatch != null) {
      final year = int.tryParse(ymMatch.group(1)!);
      final month = int.tryParse(ymMatch.group(2)!);
      if (month != null && month >= 1 && month <= 12 && year != null && year >= 2020 && year <= 2045) {
        final lastDay = DateTime(year, month + 1, 0).day;
        final mStr = month < 10 ? "0$month" : "$month";
        final dStr = lastDay < 10 ? "0$lastDay" : "$lastDay";
        return "$year-$mStr-$dStr";
      }
    }

    // 4. Month name with prefix: e.g. EXP. NOV 2026 or EXP: DEC.26 or EXPIRY: AUG 2025
    final nameMatch = RegExp(
      prefix + r"[:\s\.\-]*([a-zA-Z]{3,9})[\s\.\-\/',]+(20\d{2}|\d{2})\b",
      caseSensitive: false,
    ).firstMatch(normalizedText);
    if (nameMatch != null) {
      final mName = nameMatch.group(1)!.toLowerCase();
      final month = monthNames[mName];
      int? year = int.tryParse(nameMatch.group(2)!);
      if (year != null && year < 100) year += 2000;
      if (month != null && year != null && year >= 2020 && year <= 2045) {
        final lastDay = DateTime(year, month + 1, 0).day;
        final mStr = month < 10 ? "0$month" : "$month";
        final dStr = lastDay < 10 ? "0$lastDay" : "$lastDay";
        return "$year-$mStr-$dStr";
      }
    }

    // 5. Date across newlines: e.g. EXP. DATE \n 11/2026
    final multilineMatch = RegExp(
      prefix + r'[\s\S]{1,20}?([0-1]?\d)\s*[\/\-\.]\s*(20\d{2}|\d{2})\b',
      caseSensitive: false,
    ).firstMatch(normalizedText);
    if (multilineMatch != null) {
      final month = int.tryParse(multilineMatch.group(1)!);
      int? year = int.tryParse(multilineMatch.group(2)!);
      if (year != null && year < 100) year += 2000;
      if (month != null && month >= 1 && month <= 12 && year != null && year >= 2020 && year <= 2045) {
        final lastDay = DateTime(year, month + 1, 0).day;
        final mStr = month < 10 ? "0$month" : "$month";
        final dStr = lastDay < 10 ? "0$lastDay" : "$lastDay";
        return "$year-$mStr-$dStr";
      }
    }

    // 6. General date that is NOT preceded by mfg / mfd (e.g. stamped edge on blister strip)
    final generalMatch = RegExp(
      r'(?<!(?:mfg|mfd)[^\n]{0,15})\b(0?[1-9]|1[0-2])\s*[\/\-]\s*(20[2-3]\d|[2-3]\d)\b',
      caseSensitive: false,
    ).firstMatch(normalizedText);
    if (generalMatch != null) {
      final month = int.tryParse(generalMatch.group(1)!);
      int? year = int.tryParse(generalMatch.group(2)!);
      if (year != null && year < 100) year += 2000;
      if (month != null && month >= 1 && month <= 12 && year != null && year >= 2024 && year <= 2045) {
        final lastDay = DateTime(year, month + 1, 0).day;
        final mStr = month < 10 ? "0$month" : "$month";
        final dStr = lastDay < 10 ? "0$lastDay" : "$lastDay";
        return "$year-$mStr-$dStr";
      }
    }

    return "";
  }

  /// Extracts instructions or provides clear safe guidance
  String _extractInstructions(String text, String form) {
    final lower = text.toLowerCase();
    final detected = <String>[];

    if (lower.contains("after food") || lower.contains("after meals") || lower.contains("p.c")) {
      detected.add("Take after meals with water.");
    } else if (lower.contains("before food") || lower.contains("before meals") || lower.contains("empty stomach") || lower.contains("a.c")) {
      detected.add("Take on an empty stomach with water.");
    }

    if (lower.contains("3 to 4 times") || lower.contains("four times") || lower.contains("4 times")) {
      detected.add("Take 3 to 4 times daily (minimum 4 hours interval).");
    } else if (lower.contains("twice daily") || lower.contains("b.d") || lower.contains("bid") || lower.contains("1-0-1")) {
      detected.add("Take twice daily (morning and night).");
    } else if (lower.contains("thrice daily") || lower.contains("three times") || lower.contains("t.d.s") || lower.contains("1-1-1")) {
      detected.add("Take three times daily.");
    } else if (lower.contains("once daily") || lower.contains("o.d") || lower.contains("1-0-0")) {
      detected.add("Take once daily in the morning.");
    } else if (lower.contains("bedtime") || lower.contains("at night") || lower.contains("h.s") || lower.contains("0-0-1")) {
      detected.add("Take once daily at bedtime.");
    }

    if (detected.isNotEmpty) {
      return detected.join(" ");
    }

    // Default safe medical advice tailored to pharmaceutical form
    if (form == "Capsule" || form == "Tablet") {
      return "Take 1 $form with a glass of water after food, as directed by your doctor.";
    } else if (form == "Syrup") {
      return "Shake well before use. Take 5 to 10 ml as directed by your physician.";
    } else if (form == "Drops") {
      return "Instill 1 to 2 drops as advised by your doctor.";
    } else if (form == "Cream / Ointment") {
      return "Apply gently to the affected area. For external use only.";
    } else if (form == "Inhaler") {
      return "Take 1 to 2 puffs using inhaler technique as prescribed.";
    }

    return "Take as directed by your physician or pharmacist.";
  }

  /// Generates spoken summary in the user's selected language announcing all extracted details clearly
  String _generateMedicineSpokenSummary({
    required String name,
    required String strength,
    required String form,
    required String expiryDate,
    required String instructions,
    String composition = "",
    String purpose = "",
    String? dosage,
    String? language,
    List<String>? packagingLines,
  }) {
    final effectiveDose = (dosage != null && dosage.isNotEmpty) ? dosage : "1 $form";
    final strengthText = strength.isNotEmpty ? " $strength" : "";

    final monthNames = [
      "", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    final knMonthNames = [
      "", "ಜನವರಿ", "ಫೆಬ್ರವರಿ", "ಮಾರ್ಚ್", "ಏಪ್ರಿಲ್", "ಮೇ", "ಜೂನ್",
      "ಜುಲೈ", "ಆಗಸ್ಟ್", "ಸೆಪ್ಟೆಂಬರ್", "ಅಕ್ಟೋಬರ್", "ನವೆಂಬರ್", "ಡಿಸೆಂಬರ್"
    ];
    final hiMonthNames = [
      "", "जनवरी", "फरवरी", "मार्च", "अप्रैल", "मई", "जून",
      "जुलाई", "अगस्त", "सितंबर", "अक्टूबर", "नवंबर", "दिसंबर"
    ];

    String expNoticeEn;
    String expNoticeKn;
    String expNoticeHi;

    if (expiryDate.isNotEmpty) {
      try {
        final exp = DateTime.parse(expiryDate);
        final now = DateTime.now();
        final mName = (exp.month >= 1 && exp.month <= 12) ? monthNames[exp.month] : "";
        final knMName = (exp.month >= 1 && exp.month <= 12) ? knMonthNames[exp.month] : "";
        final hiMName = (exp.month >= 1 && exp.month <= 12) ? hiMonthNames[exp.month] : "";

        if (exp.isBefore(now)) {
          expNoticeEn = " Warning: This medicine expired in $mName ${exp.year}.";
          expNoticeKn = " ಎಚ್ಚರಿಕೆ: ಈ ಔಷಧಿಯ ಅವಧಿ $knMName ${exp.year} ನಲ್ಲಿ ಮುಗಿದಿದೆ.";
          expNoticeHi = " चेतावनी: इस दवा की समाप्ति तिथि $hiMName ${exp.year} में समाप्त हो चुकी है।";
        } else {
          expNoticeEn = " Expiry date is $mName ${exp.year}.";
          expNoticeKn = " ಮುಕ್ತಾಯ ದಿನಾಂಕ $knMName ${exp.year}.";
          expNoticeHi = " समाप्ति तिथि $hiMName ${exp.year} है।";
        }
      } catch (_) {
        expNoticeEn = " Expiry date is $expiryDate.";
        expNoticeKn = " ಮುಕ್ತಾಯ ದಿನಾಂಕ $expiryDate.";
        expNoticeHi = " समाप्ति तिथि $expiryDate है।";
      }
    } else {
      expNoticeEn = " Expiry date not visible on this photo. Tap the expiry box to set it.";
      expNoticeKn = " ಈ ಫೋಟೋದಲ್ಲಿ ಮುಕ್ತಾಯ ದಿನಾಂಕ ಕಾಣಿಸುತ್ತಿಲ್ಲ. ದಿನಾಂಕವನ್ನು ಆಯ್ಕೆ ಮಾಡಲು ಬಾಕ್ಸ್ ಟ್ಯಾಪ್ ಮಾಡಿ.";
      expNoticeHi = " इस फोटो पर समाप्ति तिथि दिखाई नहीं दे रही है। तारीख सेट करने के लिए बॉक्स पर टैप करें।";
    }

    String compNoticeEn = composition.isNotEmpty ? " Active ingredients: $composition." : "";
    String purposeNoticeEn = purpose.isNotEmpty ? " Used for $purpose." : "";

    String compNoticeKn = composition.isNotEmpty ? " ಇದರಲ್ಲಿ $composition ಇದೆ." : "";
    String purposeNoticeKn = purpose.isNotEmpty ? " $purpose ಗಾಗಿ ಬಳಸಲಾಗುತ್ತದೆ." : "";

    String compNoticeHi = composition.isNotEmpty ? " इसमें $composition मौजूद है।" : "";
    String purposeNoticeHi = purpose.isNotEmpty ? " $purpose के लिए प्रयोग किया जाता है।" : "";

    String packagingNoticeEn = "";
    String packagingNoticeKn = "";
    String packagingNoticeHi = "";
    if (packagingLines != null && packagingLines.isNotEmpty) {
      final joined = packagingLines.join(', ');
      packagingNoticeEn = " Text on packaging: $joined.";
      packagingNoticeKn = " ಪ್ಯಾಕೇಜ್‌ನಲ್ಲಿರುವ ಪಠ್ಯ: $joined.";
      packagingNoticeHi = " पैकेट पर लिखा पाठ: $joined.";
    }

    if (language == 'kn-IN') {
      return "ನಾನು $name$strengthText $form ಅನ್ನು ಓದಿದೆ.$compNoticeKn$purposeNoticeKn ಪ್ರಮಾಣ: $effectiveDose.$expNoticeKn $instructions$packagingNoticeKn";
    } else if (language == 'hi-IN') {
      return "मैंने $name$strengthText $form पढ़ा है।$compNoticeHi$purposeNoticeHi खुराक: $effectiveDose।$expNoticeHi $instructions$packagingNoticeHi";
    } else {
      return "I read $name$strengthText $form.$compNoticeEn$purposeNoticeEn Dose: $effectiveDose.$expNoticeEn $instructions$packagingNoticeEn";
    }
  }

  /// Parses Doctor's Prescription from raw OCR text
  Map<String, dynamic> parsePrescriptionText(String rawText, {String? language}) {
    if (rawText.trim().isEmpty) {
      return {
        "doctor_name": "",
        "clinic_name": "",
        "extracted_text": "",
        "spoken_summary": language == 'kn-IN'
            ? "ಯಾವುದೇ ಪಠ್ಯ ಕಂಡುಬಂದಿಲ್ಲ. ದಯವಿಟ್ಟು ಉತ್ತಮ ಬೆಳಕಿನಲ್ಲಿ ಮತ್ತೆ ಫೋಟೋ ತೆಗೆದುಕೊಳ್ಳಿ."
            : language == 'hi-IN'
                ? "कोई पाठ नहीं मिला। कृपया अच्छी रोशनी में दोबारा फोटो लें।"
                : "No text found. Please take a clearer photo of the prescription.",
        "medicines": []
      };
    }

    // Preprocess & normalize common OCR corruptions and glued prefixes
    String normalizedText = rawText
        .replaceAll(RegExp(r'\b(\d+)?\s*tab\.?\s*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(\d+)?\s*cap\.?\s*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'SizoboN', caseSensitive: false), 'Sizodon')
        .replaceAll(RegExp(r'Qutpia', caseSensitive: false), 'Qutipin')
        .replaceAll(RegExp(r'CloreE\s*pem\)?', caseSensitive: false), 'Clonazepam')
        .replaceAll(RegExp(r'\bSERTn\b', caseSensitive: false), 'Sertraline')
        .replaceAll(RegExp(r'\bSOmg\b', caseSensitive: false), '50mg');

    final lines = normalizedText
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. Doctor Name / Clinic
    String doctorName = "";
    String clinicName = "";
    for (final line in lines) {
      if (doctorName.isEmpty && RegExp(r'(?:dr\.|doctor|m\.?b\.?b\.?s|m\.?d\.?|m\.?s\.?|consultant|physician|psychiatrist)', caseSensitive: false).hasMatch(line)) {
        doctorName = line;
      }
      if (clinicName.isEmpty && RegExp(r'(?:clinic|hospital|institute|medical\s*science|research\s*centre|health\s*care|nursing\s*home)', caseSensitive: false).hasMatch(line)) {
        clinicName = line;
      }
    }

    // 2. Extract Medicines
    final List<Map<String, dynamic>> medicines = [];

    void addMedicineItem({
      required String name,
      required String line,
      String? form,
      String? strength,
      String? dosage,
      String? frequency,
      List<String>? times,
      String? whenToTake,
      int? durationDays,
      String? instructions,
    }) {
      final cleanName = name.replaceAll(RegExp(r'^(?:\d+[\.\)\-:]\s*|tab\.?\s*|cap\.?\s*|syr\.?\s*|inj\.?\s*|rx:?\s*)', caseSensitive: false), '').trim();
      if (cleanName.length < 2) return;
      final lowerName = cleanName.toLowerCase();

      final existingIndex = medicines.indexWhere((m) {
        final existing = m['name'].toString().toLowerCase();
        return existing == lowerName || (existing.startsWith(lowerName) && existing.length > lowerName.length) || (lowerName.startsWith(existing) && lowerName.length > existing.length);
      });

      final effectiveForm = (form != null && form.isNotEmpty) ? form : _extractForm(line);
      final effectiveStrength = (strength != null && strength.isNotEmpty) ? strength : _extractStrength(line);
      final effectiveDose = (dosage != null && dosage.isNotEmpty) ? dosage : (effectiveStrength.isNotEmpty ? "$effectiveStrength $effectiveForm" : "1 $effectiveForm");
      final effectiveFreq = (frequency != null && frequency.isNotEmpty) ? frequency : _inferFrequencyFromLine(line);
      final effectiveTimes = (times != null && times.isNotEmpty) ? times : _inferTimesFromLine(line);
      final effectiveWhen = (whenToTake != null && whenToTake.isNotEmpty) ? whenToTake : _inferWhenToTakeFromLine(line);
      final effectiveDuration = (durationDays != null && durationDays > 0) ? durationDays : _inferDurationFromLine(line);
      final effectiveInst = (instructions != null && instructions.isNotEmpty) ? instructions : _extractInstructions(line, effectiveForm);

      final medMap = {
        "name": cleanName,
        "form": effectiveForm,
        "strength": effectiveStrength,
        "dosage": effectiveDose,
        "frequency": effectiveFreq,
        "times": effectiveTimes,
        "when_to_take": effectiveWhen,
        "duration_days": effectiveDuration,
        "instructions": effectiveInst,
        "raw_line": line,
      };

      if (existingIndex >= 0) {
        if (cleanName.length > medicines[existingIndex]['name'].toString().length) {
          medicines[existingIndex] = medMap;
        }
      } else {
        medicines.add(medMap);
      }
    }

    // 2A: Full text scan for known medicines (handles multiple meds in single line/block)
    for (final known in _knownMedicines) {
      if (RegExp(r'\b' + RegExp.escape(known) + r'\b', caseSensitive: false).hasMatch(normalizedText)) {
        String contextLine = "";
        for (final l in lines) {
          if (RegExp(r'\b' + RegExp.escape(known.split(' ').first) + r'\b', caseSensitive: false).hasMatch(l)) {
            contextLine = l;
            break;
          }
        }
        final effectiveLine = contextLine.isNotEmpty ? contextLine : normalizedText;
        addMedicineItem(name: known, line: effectiveLine);
      }
    }

    // 2B: Structured prescription line extraction (Numbered or starting with Tab/Cap/Rx)
    for (final line in lines) {
      if (RegExp(r'(?:dr\.|doctor|m\.?b\.?b\.?s|m\.?d\.?|clinic|hospital|regd|consultant|phone|road|plot|street|nagar|colony|date|age|sex|weight)', caseSensitive: false).hasMatch(line)) {
        continue;
      }

      final numberedMatch = RegExp(r'^(?:\d+[\.\)\-:]\s*|rx:?\s*|tab\.?\s*|cap\.?\s*|syr\.?\s*|inj\.?\s*)\s*(.+)', caseSensitive: false).firstMatch(line);
      if (numberedMatch != null) {
        final content = numberedMatch.group(1)!.trim();
        if (content.length >= 3 && !content.toLowerCase().contains("date") && !content.toLowerCase().contains("phone")) {
          final words = content.split(RegExp(r'\s+'));
          String name = words.first;
          if (words.length > 1 && !RegExp(r'^(?:\d|tab|cap|night|bedtime|morning|after|before|sos)', caseSensitive: false).hasMatch(words[1])) {
            name = "$name ${words[1]}";
          }
          addMedicineItem(name: name, line: line);
        }
      }
    }

    // 2C: Pattern matching fallback for lines with medical frequencies or dosages
    for (final line in lines) {
      if (RegExp(r'(?:dr\.|doctor|m\.?b\.?b\.?s|m\.?d\.?|clinic|hospital|regd|consultant|phone|road|plot|street|nagar|colony|date|age|sex|weight)', caseSensitive: false).hasMatch(line)) {
        continue;
      }

      final hasMedicalPattern = RegExp(r'(?:\d+\s*(?:mg|mcg|ml|gm|%|iu|g\b)|(?:tab|cap|syp|inj)\b|1-0-1|1-1-1|0-0-1|1-0-0|b\.?d\.?|b\.?i\.?d\.?|t\.?d\.?s\.?|o\.?d\.?|h\.?s\.?|bedtime|night|morning|after food|before food|sos)', caseSensitive: false).hasMatch(line);
      if (hasMedicalPattern) {
        final cleanLine = line.replaceAll(RegExp(r'^(?:\d+[\.\)\-:]\s*|rx:?\s*|tab\.?\s*|cap\.?\s*)', caseSensitive: false), '').trim();
        final words = cleanLine.split(RegExp(r'\s+'));
        if (words.isNotEmpty && words.first.length >= 3) {
          String name = words.first;
          if (words.length > 1 && !RegExp(r'^(?:\d|tab|cap|night|bedtime|morning|after|before|sos)', caseSensitive: false).hasMatch(words[1])) {
            name = "$name ${words[1]}";
          }
          name = name.replaceAll(RegExp(r'[^a-zA-Z0-9\-\s]'), '').trim();
          if (name.length >= 3) {
            addMedicineItem(name: name, line: line);
          }
        }
      }
    }

    final count = medicines.length;
    String spokenSummary;
    if (count > 0) {
      final docPrefixEn = doctorName.isNotEmpty ? "Prescription from $doctorName. " : (clinicName.isNotEmpty ? "Prescription from $clinicName. " : "");
      final docPrefixKn = doctorName.isNotEmpty ? "$doctorName ಅವರ ಚೀಟಿ. " : "";
      final docPrefixHi = doctorName.isNotEmpty ? "$doctorName का पर्चा। " : "";

      final medListEn = medicines.map((m) {
        final d = m['dosage'] != null && m['dosage'].toString().isNotEmpty ? m['dosage'] : "";
        final inst = m['instructions'] != null && m['instructions'].toString().isNotEmpty ? m['instructions'] : "";
        final dur = m['duration_days'] != null && (m['duration_days'] as int) > 0 ? " for ${m['duration_days']} days" : "";
        return "${m['name']}${d.isNotEmpty ? ' ($d)' : ''}: $inst$dur";
      }).join(". ");

      final medListKn = medicines.map((m) => "${m['name']}: ${m['instructions']}").join(". ");
      final medListHi = medicines.map((m) => "${m['name']}: ${m['instructions']}").join("। ");

      if (language == 'kn-IN') {
        spokenSummary = "$docPrefixKnಈ ಚೀಟಿಯಲ್ಲಿ $count ಔಷಧಿಗಳು ಕಂಡುಬಂದಿವೆ: $medListKn.";
      } else if (language == 'hi-IN') {
        spokenSummary = "$docPrefixHiइस पर्चे में $count दवाएं मिली हैं: $medListHi।";
      } else {
        spokenSummary = "${docPrefixEn}Found $count medicines in this prescription: $medListEn.";
      }
    } else {
      final snippet = lines.take(3).join(', ');
      if (language == 'kn-IN') {
        spokenSummary = "ಚೀಟಿಯ ಪಠ್ಯವನ್ನು ಓದಲಾಗಿದೆ: $snippet.";
      } else if (language == 'hi-IN') {
        spokenSummary = "पर्चे का पाठ पढ़ा गया: $snippet।";
      } else {
        spokenSummary = "Prescription text read: $snippet. Please verify medicines.";
      }
    }

    return {
      "doctor_name": doctorName,
      "clinic_name": clinicName,
      "extracted_text": rawText,
      "spoken_summary": spokenSummary,
      "medicines": medicines,
    };
  }

  String _inferFrequencyFromLine(String line) {
    final lower = line.toLowerCase();
    if (lower.contains("1-0-1") || lower.contains("bid") || lower.contains("b.d") || lower.contains("twice daily") || lower.contains("twice")) {
      return "1-0-1";
    }
    if (lower.contains("1-1-1") || lower.contains("tid") || lower.contains("tds") || lower.contains("three times")) {
      return "1-1-1";
    }
    if (lower.contains("1-0-0") || lower.contains("od morning") || lower.contains("once daily") || lower.contains("o.d")) {
      return "1-0-0";
    }
    if (lower.contains("0-0-1") || lower.contains("h.s") || lower.contains("bedtime") || lower.contains("at night")) {
      return "0-0-1";
    }
    if (lower.contains("0-1-0") || lower.contains("afternoon")) {
      return "0-1-0";
    }
    if (lower.contains("sos") || lower.contains("as needed")) {
      return "SOS";
    }
    return "1-0-1";
  }

  String _inferWhenToTakeFromLine(String line) {
    final lower = line.toLowerCase();
    if (lower.contains("before food") || lower.contains("before meals") || lower.contains("empty stomach") || lower.contains("a.c")) {
      return "Before food";
    }
    if (lower.contains("bedtime") || lower.contains("at night") || lower.contains("h.s")) {
      return "At bedtime";
    }
    return "After food";
  }

  List<String> _inferTimesFromLine(String line) {
    final lower = line.toLowerCase();
    if (lower.contains("1-0-1") || lower.contains("bid") || lower.contains("b.d") || lower.contains("twice")) {
      return ["08:00", "20:00"];
    }
    if (lower.contains("1-1-1") || lower.contains("tid") || lower.contains("tds") || lower.contains("three times")) {
      return ["08:00", "14:00", "20:00"];
    }
    if (lower.contains("1-0-0") || lower.contains("morning") || lower.contains("od morning") || lower.contains("o.d")) {
      return ["08:00"];
    }
    if (lower.contains("0-0-1") || lower.contains("night") || lower.contains("bedtime") || lower.contains("h.s")) {
      return ["21:00"];
    }
    if (lower.contains("0-1-0") || lower.contains("afternoon")) {
      return ["14:00"];
    }
    return ["08:00", "20:00"];
  }

  int _inferDurationFromLine(String line) {
    final match = RegExp(r'(?:x|for)\s*(\d+)\s*(?:days?|d)\b', caseSensitive: false).firstMatch(line);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 7;
    }
    final weekMatch = RegExp(r'(?:x|for)\s*(\d+)\s*(?:weeks?|w)\b', caseSensitive: false).firstMatch(line);
    if (weekMatch != null) {
      return (int.tryParse(weekMatch.group(1)!) ?? 1) * 7;
    }
    return 7;
  }

  Map<String, dynamic> _generateEmptyResult(String? language) {
    final summary = language == 'kn-IN'
        ? "ಚಿತ್ರದಲ್ಲಿ ಯಾವುದೇ ಸ್ಪಷ್ಟ ಪಠ್ಯ ಕಂಡುಬಂದಿಲ್ಲ. ದಯವಿಟ್ಟು ಬೆಳಕಿನಲ್ಲಿ ಮತ್ತೆ ಫೋಟೋ ತೆಗೆಯಿರಿ."
        : language == 'hi-IN'
            ? "फोटो में कोई स्पष्ट पाठ नहीं मिला। कृपया अच्छी रोशनी में दोबारा प्रयास करें।"
            : "Could not read text clearly. Please hold the medicine packaging steady under good light and try again.";

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
      "spoken_summary": summary,
    };
  }
}
