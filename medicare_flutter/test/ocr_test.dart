import 'package:flutter_test/flutter_test.dart';
import 'package:medicare_flutter/services/ocr_service.dart';

void main() {
  test('OCRService parses Everbliss Smg strip correctly with typos', () {
    final ocr = OCRService();
    const rawText =
        'Everolimus Tablets D Everbliss Smg For Oral Use Dosage As dirncted by ie yaician. below 25e Store in the orig Pronect fromn tghtao sold by rtat on the prcrption f wagierod Medical Pracaboner only aring a by pan ofc acured in inda by BDR Pharmaceuticals nttv. LId. RS.NO. 578, Near Emuei Channe Ros, V';

    // Test English
    final enResult = ocr.parseMedicineText(rawText, language: 'en-US');
    expect(enResult['name'], equals('Everbliss'));
    expect(enResult['strength'], equals('5 mg'));
    expect(enResult['form'], equals('Tablet'));
    expect(enResult['composition'], contains('Everolimus'));
    expect(enResult['when_to_take'], isNotEmpty);
    expect(enResult['suggested_times'], contains('08:00'));

    // Test Kannada
    final knResult = ocr.parseMedicineText(rawText, language: 'kn-IN');
    expect(knResult['name'], equals('Everbliss'));
    expect(knResult['strength'], equals('5 mg'));
    expect(knResult['purpose'], contains('ಜೀವಕೋಶಗಳ'));
    expect(knResult['when_to_take'], contains('ಮಾತ್ರೆ'));
    expect(knResult['spoken_summary'], contains('Everbliss'));

    // Test Hindi
    final hiResult = ocr.parseMedicineText(rawText, language: 'hi-IN');
    expect(hiResult['name'], equals('Everbliss'));
    expect(hiResult['strength'], equals('5 mg'));
    expect(hiResult['when_to_take'], contains('गोली'));
  });

  test('OCRService parses handwritten and hospital prescriptions without regex crash', () {
    final ocr = OCRService();

    // 1. Neuro-psychiatrist prescription with OCR typos
    const presc1 =
        'Dr. Y. NAGENDAR RAO MBBS(Dam, M.O (PayL s Consultant Neuro - Psychiatrist Regd. No, 8373 (A.PR) Counsetle) oe Phone Tos M SRoiuAs Conh e SizoboN PLus Qutpia 906ms 3Tab ATivan CloreE pem) Iuis SERTn SOmg nadi Cuna Dr. Nagendar Rao Y. Plot 89, Sardar Patel Colony Hashmathpet Road, imulgherry SECUNDERA';

    final res1 = ocr.parsePrescriptionText(presc1, language: 'en-US');
    expect(res1['doctor_name'], isNotEmpty);
    expect((res1['medicines'] as List).length, greaterThan(0));
    final medNames1 = (res1['medicines'] as List).map((m) => m['name'].toString().toLowerCase()).toList();
    expect(medNames1.any((n) => n.contains('sizodon') || n.contains('ativan') || n.contains('qutipin')), isTrue);

    // 2. Hospital prescription with Rochet
    const presc2 =
        ') TINSRniversity Adichunchanagir Adichunchanagiri Tnstitute of Medical Science Hospitat& Research Centre balagangadhaanatha Nagara-57 A8 Name. UHIDIPNo.. 2]12l24 PR that. 2 Rochet. Signature of Doctor';

    final res2 = ocr.parsePrescriptionText(presc2, language: 'en-US');
    expect(res2['doctor_name'], isNotEmpty);
    expect((res2['medicines'] as List).length, greaterThan(0));
    final medNames2 = (res2['medicines'] as List).map((m) => m['name'].toString().toLowerCase()).toList();
    expect(medNames2.any((n) => n.contains('rochet')), isTrue);
  });
}
