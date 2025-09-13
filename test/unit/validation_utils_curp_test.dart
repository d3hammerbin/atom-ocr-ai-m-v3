import 'package:flutter_test/flutter_test.dart';
import 'package:atom_ocr_ai_m_v3/app/core/utils/validation_utils.dart';

void main() {
  group('ValidationUtils CURP Functions', () {
    group('isValidCurpGranular', () {
      test('should validate correct CURP format', () {
        // CURP válida de ejemplo con fechas válidas
        expect(ValidationUtils.isValidCurpGranular('ABCD901201HDFGHI01'), true); // 01/12/1990
        expect(ValidationUtils.isValidCurpGranular('XYZW850315MPLQRS09'), true); // 15/03/1985
      });

      test('should reject CURP with invalid length', () {
        expect(ValidationUtils.isValidCurpGranular('ABCD12345'), false);
        expect(ValidationUtils.isValidCurpGranular('ABCD123456HDFGHI012'), false);
        expect(ValidationUtils.isValidCurpGranular(''), false);
      });

      test('should reject CURP with numbers in positions 1-4', () {
        expect(ValidationUtils.isValidCurpGranular('A1CD901201HDFGHI01'), false);
        expect(ValidationUtils.isValidCurpGranular('12CD901201HDFGHI01'), false);
      });

      test('should reject CURP with letters in positions 5-10', () {
        expect(ValidationUtils.isValidCurpGranular('ABCDA01201HDFGHI01'), false);
        expect(ValidationUtils.isValidCurpGranular('ABCD9B1201HDFGHI01'), false);
      });

      test('should reject CURP with invalid sex character', () {
        expect(ValidationUtils.isValidCurpGranular('ABCD901201XDFGHI01'), false);
        expect(ValidationUtils.isValidCurpGranular('ABCD901201FDFGHI01'), false);
      });

      test('should reject CURP with invalid state codes', () {
        expect(ValidationUtils.isValidCurpGranular('ABCD901201HXXGHI01'), false);
        expect(ValidationUtils.isValidCurpGranular('ABCD901201H99GHI01'), false);
      });

      test('should accept valid state codes', () {
        expect(ValidationUtils.isValidCurpGranular('ABCD901201HDFGHI01'), true);
        expect(ValidationUtils.isValidCurpGranular('ABCD901201HBCGHI01'), true);
        expect(ValidationUtils.isValidCurpGranular('ABCD901201HASGHI01'), true);
        expect(ValidationUtils.isValidCurpGranular('ABCD901201HNEGHI01'), true); // NE es válido
      });

      test('should reject CURP with numbers in positions 14-16', () {
        expect(ValidationUtils.isValidCurpGranular('ABCD901201HDF1HI01'), false);
        expect(ValidationUtils.isValidCurpGranular('ABCD901201HDFG2I01'), false);
      });

      test('should reject CURP with invalid verification digit', () {
        expect(ValidationUtils.isValidCurpGranular('ABCD901201HDFGHI0A'), false); // A en posición 18
        expect(ValidationUtils.isValidCurpGranular('ABCD901201HDFGHI1X'), false); // X en posición 18
      });

      test('should validate date ranges', () {
        expect(ValidationUtils.isValidCurpGranular('ABCD901301HDFGHI01'), false); // Mes inválido (13)
        expect(ValidationUtils.isValidCurpGranular('ABCD901232HDFGHI01'), false); // Día inválido (32)
        expect(ValidationUtils.isValidCurpGranular('ABCD901201HDFGHI01'), true);  // Fecha válida (01/12/1990)
      });
    });

    group('sanitizeCurp', () {
      test('should convert numbers to letters in positions 1-4', () {
        final result = ValidationUtils.sanitizeCurp('A1C3901201HDFGHI01');
        expect(result.substring(0, 4), 'AICE'); // 1->I, 3->E
      });

      test('should remove non-numeric characters from positions 5-10', () {
        final result = ValidationUtils.sanitizeCurp('ABCD90A201HDFGHI01');
        expect(result.substring(4, 10), '902010'); // A removida, números reordenados según algoritmo
      });

      test('should normalize sex character', () {
        expect(ValidationUtils.sanitizeCurp('ABCD901201FDFGHI01')[10], 'M'); // F->M
        expect(ValidationUtils.sanitizeCurp('ABCD901201hDFGHI01')[10], 'H'); // h->H
        expect(ValidationUtils.sanitizeCurp('ABCD901201XDFGHI01')[10], 'H'); // X->H (default)
      });

      test('should convert numbers to letters in positions 14-16', () {
        final result = ValidationUtils.sanitizeCurp('ABCD901201HDF1H201');
        expect(result.substring(13, 16), 'IHZ'); // 1->I, 2->Z
      });

      test('should preserve valid alphanumeric in position 17', () {
        expect(ValidationUtils.sanitizeCurp('ABCD901201HDFGHIA1')[16], 'A');
        expect(ValidationUtils.sanitizeCurp('ABCD901201HDFGHI51')[16], '5');
      });

      test('should remove non-numeric from position 18', () {
        final result = ValidationUtils.sanitizeCurp('ABCD901201HDFGHI0A');
        expect(result.length, 17); // A removida de la posición 18
      });

      test('should correct common state code errors', () {
        expect(ValidationUtils.sanitizeCurp('ABCD901201HMXGHI01').substring(11, 13), 'DF'); // MX->DF
        expect(ValidationUtils.sanitizeCurp('ABCD901201HCDGHI01').substring(11, 13), 'DF'); // CD->DF
        expect(ValidationUtils.sanitizeCurp('ABCD901201HNEGHI01').substring(11, 13), 'NE'); // NE es válido, no se corrige
        expect(ValidationUtils.sanitizeCurp('ABCD901201HXXGHI01').substring(11, 13), 'DF'); // XX->DF (código inválido)
      });

      test('should handle empty and invalid input', () {
        expect(ValidationUtils.sanitizeCurp(''), '');
        expect(ValidationUtils.sanitizeCurp('ABC'), 'ABC');
      });

      test('should remove spaces and special characters', () {
        final result = ValidationUtils.sanitizeCurp('ABCD-901201 HDFGHI01');
        expect(result, contains('ABCD901201'));
      });

      test('should handle mixed case input', () {
        final result = ValidationUtils.sanitizeCurp('abcd901201hdfghi01');
        expect(result, 'ABCD901201HDFGHI01');
      });

      test('should complete sanitization workflow', () {
        // Caso complejo con múltiples errores
        final input = 'A1C3-12A456 f99GH201';
        final result = ValidationUtils.sanitizeCurp(input);
        
        // Verificar que se aplicaron todas las reglas
        expect(result.length, lessThanOrEqualTo(18));
        if (result.length >= 4) {
          expect(result.substring(0, 4), matches(r'^[A-Z]{4}$')); // Solo letras en 1-4
        }
        if (result.length >= 10) {
          expect(result.substring(4, 10), matches(r'^[0-9]{6}$')); // Solo números en 5-10
        }
        if (result.length >= 11) {
          expect(result[10], matches(r'^[HM]$')); // Solo H o M en posición 11
        }
      });
    });

    group('Integration tests', () {
      test('sanitized CURP should pass granular validation when possible', () {
        // Casos donde el saneamiento puede producir CURP válida
        final testCases = [
          'ABCD901201HDFGHI01', // Ya válida
          'abcd901201hdfghi01', // Solo mayúsculas
          'ABCD-901201-HDFGHI-01', // Con guiones
        ];

        for (final testCase in testCases) {
          final sanitized = ValidationUtils.sanitizeCurp(testCase);
          if (sanitized.length == 18) {
            expect(ValidationUtils.isValidCurpGranular(sanitized), true,
                reason: 'Sanitized CURP should be valid: $testCase -> $sanitized');
          }
        }
      });

      test('should handle edge cases gracefully', () {
        final edgeCases = [
          '123456789012345678', // Solo números
          'ABCDEFGHIJKLMNOPQR', // Solo letras
          'A1B2C3D4E5F6G7H8I9', // Alternado
          '!@#\$%^&*()_+-=[]{}', // Caracteres especiales
        ];

        for (final testCase in edgeCases) {
          expect(() => ValidationUtils.sanitizeCurp(testCase), returnsNormally);
          expect(() => ValidationUtils.isValidCurpGranular(testCase), returnsNormally);
        }
      });
    });
  });
}