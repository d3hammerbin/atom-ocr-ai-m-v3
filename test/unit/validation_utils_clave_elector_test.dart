import 'package:flutter_test/flutter_test.dart';
import 'package:atom_ocr_ai_m_v3/app/core/utils/validation_utils.dart';

void main() {
  group('ValidationUtils Clave de Elector Functions', () {
    group('isValidClaveElectorGranular', () {
      test('should validate correct Clave de Elector format', () {
        // Claves válidas de ejemplo
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512H123'), true); // 6 consonantes + 8 dígitos + H + 3 dígitos
        expect(ValidationUtils.isValidClaveElectorGranular('JKLMNP90120215M456'), true); // Mujer
        expect(ValidationUtils.isValidClaveElectorGranular('QRSTVW75061020X789'), true); // No especificado
      });

      test('should reject Clave de Elector with invalid length', () {
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH12345'), false);
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512H1234'), false);
        expect(ValidationUtils.isValidClaveElectorGranular(''), false);
      });

      test('should reject Clave de Elector with vowels in positions 1-6', () {
        expect(ValidationUtils.isValidClaveElectorGranular('ACDFGH85031512H123'), false); // A es vocal
        expect(ValidationUtils.isValidClaveElectorGranular('BCEFGH85031512H123'), false); // E es vocal
        expect(ValidationUtils.isValidClaveElectorGranular('BCDIGH85031512H123'), false); // I es vocal
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFOH85031512H123'), false); // O es vocal
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGU85031512H123'), false); // U es vocal
      });

      test('should accept only consonants in positions 1-6', () {
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512H123'), true);
        expect(ValidationUtils.isValidClaveElectorGranular('JKLMNP85031512H123'), true);
        expect(ValidationUtils.isValidClaveElectorGranular('QRSTVW85031512H123'), true);
        expect(ValidationUtils.isValidClaveElectorGranular('XYZLMN85031512H123'), true);
      });

      test('should reject Clave de Elector with letters in positions 7-14', () {
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGHA5031512H123'), false); // A en posición 7
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH8B031512H123'), false); // B en posición 8
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85C31512H123'), false); // C en posición 9
      });

      test('should validate date ranges in positions 7-14', () {
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85001512H123'), false); // Mes inválido (00)
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85131512H123'), false); // Mes inválido (13)
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85030012H123'), false); // Día inválido (00)
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85033212H123'), false); // Día inválido (32)
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512H123'), true);  // Fecha válida
      });

      test('should validate entity code in positions 13-14', () {
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031500H123'), true);  // 00 es válido
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031515H123'), true);  // 15 es válido
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031532H123'), true);  // 32 es válido
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031599H123'), true);  // 99 es válido
      });

      test('should reject Clave de Elector with invalid gender character', () {
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512F123'), false); // F no es válido
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512A123'), false); // A no es válido
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH851031521123'), false); // 1 no es válido
      });

      test('should accept valid gender characters', () {
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512H123'), true); // H (Hombre)
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512M123'), true); // M (Mujer)
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512X123'), true); // X (No especificado)
      });

      test('should reject Clave de Elector with letters in positions 16-18', () {
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512H12A'), false); // A en posición 18
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512H1B3'), false); // B en posición 17
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512HC23'), false); // C en posición 16
      });

      test('should accept only digits in positions 16-18', () {
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512H000'), true);
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512H123'), true);
        expect(ValidationUtils.isValidClaveElectorGranular('BCDFGH85031512H999'), true);
      });
    });

    group('sanitizeClaveElector', () {
      test('should convert digits to consonants in positions 1-6', () {
        final result = ValidationUtils.sanitizeClaveElector('B1D3GH85031512H123');
        expect(result.substring(0, 6), 'BLDLGH'); // 1->I->L, 3->I->L
      });

      test('should convert vowels to consonants in positions 1-6', () {
        final result = ValidationUtils.sanitizeClaveElector('ACDFGH85031512H123');
        expect(result.substring(0, 6), 'RCDFGH'); // A->R
        
        final result2 = ValidationUtils.sanitizeClaveElector('BCEFGH85031512H123');
        expect(result2.substring(0, 6), 'BCFFGH'); // E->F
        
        final result3 = ValidationUtils.sanitizeClaveElector('BCDIGH85031512H123');
        expect(result3.substring(0, 6), 'BCDLGH'); // I->L
        
        final result4 = ValidationUtils.sanitizeClaveElector('BCDFOH85031512H123');
        expect(result4.substring(0, 6), 'BCDFQH'); // O->Q
        
        final result5 = ValidationUtils.sanitizeClaveElector('BCDFGU85031512H123');
        expect(result5.substring(0, 6), 'BCDFGV'); // U->V
      });

      test('should convert letters to digits in positions 7-14', () {
        final result = ValidationUtils.sanitizeClaveElector('BCDFGHO5L31512H123');
        expect(result.substring(6, 14), '05131512'); // O->0, L->1
        
        final result2 = ValidationUtils.sanitizeClaveElector('BCDFGH8SB31G12H123');
        expect(result2.substring(6, 14), '85831612'); // S->5, B->8, G->6
      });

      test('should normalize gender character in position 15', () {
        expect(ValidationUtils.sanitizeClaveElector('BCDFGH85031512O123')[14], 'H'); // O->H
        expect(ValidationUtils.sanitizeClaveElector('BCDFGH850315121123')[14], 'H'); // 1->H
        expect(ValidationUtils.sanitizeClaveElector('BCDFGH85031512I123')[14], 'H'); // I->H
        expect(ValidationUtils.sanitizeClaveElector('BCDFGH85031512L123')[14], 'H'); // L->H
        expect(ValidationUtils.sanitizeClaveElector('BCDFGH85031512M123')[14], 'M'); // M se mantiene
        expect(ValidationUtils.sanitizeClaveElector('BCDFGH85031512X123')[14], 'X'); // X se mantiene
        expect(ValidationUtils.sanitizeClaveElector('BCDFGH85031512F123')[14], 'H'); // F->H (por defecto)
      });

      test('should convert letters to digits in positions 16-18 (as user specified)', () {
        final result = ValidationUtils.sanitizeClaveElector('BCDFGH85031512HO2L');
        expect(result.substring(15, 18), '021'); // O->0, L->1
        
        final result2 = ValidationUtils.sanitizeClaveElector('BCDFGH85031512HSBA');
        expect(result2.substring(15, 18), '584'); // S->5, B->8, A->4
        
        final result3 = ValidationUtils.sanitizeClaveElector('BCDFGH85031512HGZT');
        expect(result3.substring(15, 18), '627'); // G->6, Z->2, T->7
      });

      test('should handle empty and invalid input', () {
        expect(ValidationUtils.sanitizeClaveElector(''), '');
        expect(ValidationUtils.sanitizeClaveElector('ABC'), 'ABC');
        expect(ValidationUtils.sanitizeClaveElector('ABCDEFGHIJKLMNOP'), 'ABCDEFGHIJKLMNOP'); // 16 caracteres
      });

      test('should remove spaces and special characters', () {
        final result = ValidationUtils.sanitizeClaveElector('BCDFGH-850315 12H123');
        expect(result, 'BCDFGH85031512H123');
      });

      test('should handle mixed case input', () {
        final result = ValidationUtils.sanitizeClaveElector('bcdfgh85031512h123');
        expect(result, 'BCDFGH85031512H123');
      });

      test('should complete sanitization workflow', () {
        // Caso complejo con múltiples errores
        final input = 'B1E3GH-8SO315L2f1O3';
        final result = ValidationUtils.sanitizeClaveElector(input);
        
        // Verificar que se aplicaron todas las reglas
        expect(result.length, 18);
        expect(result.substring(0, 6), matches(r'^[BCDFGHJKLMNPQRSTVWXYZ]{6}$')); // Solo consonantes en 1-6
        expect(result.substring(6, 14), matches(r'^[0-9]{8}$')); // Solo números en 7-14
        expect(result[14], matches(r'^[MHX]$')); // Solo M, H, X en posición 15
        expect(result.substring(15, 18), matches(r'^[0-9]{3}$')); // Solo números en 16-18
      });
    });

    group('Integration tests', () {
      test('sanitized Clave de Elector should pass granular validation when possible', () {
        // Casos donde el saneamiento puede producir Clave válida
        final testCases = [
          'BCDFGH85031512H123', // Ya válida
          'bcdfgh85031512h123', // Solo mayúsculas
          'BCDFGH-850315-12H-123', // Con guiones
          'BCDFGH 85031512 H123', // Con espacios
        ];

        for (final testCase in testCases) {
          final sanitized = ValidationUtils.sanitizeClaveElector(testCase);
          if (sanitized.length == 18) {
            expect(ValidationUtils.isValidClaveElectorGranular(sanitized), true,
                reason: 'Sanitized Clave should be valid: $testCase -> $sanitized');
          }
        }
      });

      test('should handle edge cases gracefully', () {
        final edgeCases = [
          '123456789012345678', // Solo números
          'ABCDEFGHIJKLMNOPQR', // Solo letras
          'B1C2D3F4G5H6789012', // Alternado
          '!@#\$%^&*()_+-=[]{}', // Caracteres especiales
        ];

        for (final testCase in edgeCases) {
          expect(() => ValidationUtils.sanitizeClaveElector(testCase), returnsNormally);
          expect(() => ValidationUtils.isValidClaveElectorGranular(testCase), returnsNormally);
        }
      });
    });

    group('Comparison with basic validation', () {
      test('granular validation should be more strict than basic', () {
        // Casos que pasan validación básica pero fallan granular
        final testCases = [
          'AEIOU185031512H123', // Vocales en posiciones 1-6
          'BCDFGH8A031512H123', // Letra en posiciones 7-14
          'BCDFGH85031512F123', // Género inválido
          'BCDFGH85031512H12A', // Letra en posiciones 16-18
        ];

        for (final testCase in testCases) {
          expect(ValidationUtils.isValidClaveElector(testCase), true,
              reason: 'Basic validation should pass: $testCase');
          expect(ValidationUtils.isValidClaveElectorGranular(testCase), false,
              reason: 'Granular validation should fail: $testCase');
        }
      });

      test('valid cases should pass both validations', () {
        final validCases = [
          'BCDFGH85031512H123',
          'JKLMNP90120215M456',
          'QRSTVW75061020X789',
        ];

        for (final testCase in validCases) {
          expect(ValidationUtils.isValidClaveElector(testCase), true,
              reason: 'Basic validation should pass: $testCase');
          expect(ValidationUtils.isValidClaveElectorGranular(testCase), true,
              reason: 'Granular validation should pass: $testCase');
        }
      });
    });
  });
}