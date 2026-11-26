import 'package:flutter_test/flutter_test.dart';
import 'package:medicare_flutter/services/side_effects_service.dart';

void main() {
  group('SideEffectsService Tests', () {
    test('Correctly identifies Paracetamol side effects and critical liver warnings', () {
      final medicines = [
        {
          'id': 'med_1',
          'name': 'Calpol 500',
          'strength': '500 mg',
          'form': 'Tablet',
          'scanned_text': 'WARNING: Taking more than daily dose may cause serious liver damage or allergic reactions',
          'instructions': 'Do not exceed 8 tablets in 24 hours. Paracetamol overdose may be injurious to liver.',
        },
        {
          'id': 'med_2',
          'name': 'Pyremust-650',
          'strength': '650 mg',
          'form': 'Tablet',
          'composition': 'Paracetamol IP 650mg',
        }
      ];

      final warnings = SideEffectsService.evaluateMedicines(medicines, language: 'en-US');
      expect(warnings.length, 2);

      final calpol = warnings.firstWhere((w) => w.name == 'Calpol 500');
      expect(calpol.severity, 'critical');
      expect(calpol.genericSalt, 'paracetamol');
      expect(calpol.sideEffects.any((s) => s.contains('liver damage')), isTrue);
      expect(calpol.packagingWarning != null, isTrue);

      final summary = SideEffectsService.buildSpokenSummary(warnings, language: 'en-US');
      expect(summary.contains('Calpol 500'), isTrue);
      expect(summary.contains('liver damage'), isTrue);
    });

    test('Translates warnings and side effects into Kannada and Hindi', () {
      final medicines = [
        {
          'id': 'med_1',
          'name': 'Calpol 500',
          'strength': '500 mg',
        }
      ];

      final knWarnings = SideEffectsService.evaluateMedicines(medicines, language: 'kn-IN');
      expect(knWarnings.first.sideEffects.first.contains('ಲಿವರ್'), isTrue);

      final hiWarnings = SideEffectsService.evaluateMedicines(medicines, language: 'hi-IN');
      expect(hiWarnings.first.sideEffects.first.contains('लिवर'), isTrue);
    });
  });
}

