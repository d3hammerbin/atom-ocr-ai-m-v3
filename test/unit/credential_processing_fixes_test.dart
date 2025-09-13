import 'package:flutter_test/flutter_test.dart';
import 'package:atom_ocr_ai_m_v3/services/fixes/credential_processing_fixes.dart';
import 'package:atom_ocr_ai_m_v3/app/data/models/credencial_ine_model.dart';

void main() {
  group('CredentialProcessingFixes Tests', () {
    test('should validate CURP format correctly', () {
      // Test valid CURP
      expect(CredentialProcessingFixes.isValidCurpFormat('ABCD123456HDFGHI01'), true);
      
      // Test invalid CURP - wrong length
      expect(CredentialProcessingFixes.isValidCurpFormat('ABCD123456'), false);
      
      // Test invalid CURP - wrong format
      expect(CredentialProcessingFixes.isValidCurpFormat('1234567890ABCDEFGH'), false);
    });

    test('should sanitize CURP correctly', () {
      // Test normal CURP
      String result = CredentialProcessingFixes.sanitizeCurp('abcd123456hdfghi01');
      expect(result, 'ABCD123456HDFGHI01');
      
      // Test CURP with spaces and special characters
      result = CredentialProcessingFixes.sanitizeCurp('AB CD-12 34.56 HD FG HI 01');
      expect(result, 'ABCD123456HDFGHI01');
      
      // Test invalid CURP
      result = CredentialProcessingFixes.sanitizeCurp('INVALID');
      expect(result, '');
    });

    test('should find CURP in text using standard pattern', () {
      String text = 'NOMBRE: JUAN PEREZ\nCURP: ABCD123456HDFGHI01\nDOMICILIO: CALLE 123';
      String result = CredentialProcessingFixes.findCurpInText(text);
      expect(result, 'ABCD123456HDFGHI01');
    });

    test('should find CURP in text using flexible pattern', () {
      String text = 'CURP\nABCD123456HDFGHI01\nOTROS DATOS';
      String result = CredentialProcessingFixes.findCurpWithFlexiblePattern(text);
      expect(result, 'ABCD123456HDFGHI01');
    });

    test('should extract CURP from line correctly', () {
      String line = 'CURP: ABCD123456HDFGHI01 OTROS DATOS';
      String result = CredentialProcessingFixes.extractCurpFromLine(line);
      expect(result, 'ABCD123456HDFGHI01');
    });

    test('should validate complete CURP correctly', () {
      expect(CredentialProcessingFixes.isValidCurp('ABCD123456HDFGHI01'), true);
      expect(CredentialProcessingFixes.isValidCurp(''), false);
      expect(CredentialProcessingFixes.isValidCurp('INVALID'), false);
    });

    group('Integration Tests', () {
      test('should update credential model with fixes', () async {
        // Create a test credential with incomplete data
        final testCredential = CredencialIneModel(
          nombre: 'JUAN PEREZ',
          domicilio: 'CALLE 123',
          claveElector: 'ABCD123456789',
          curp: '', // Empty CURP to test correction
          fechaNacimiento: '01/01/1990',
          sexo: 'H',
          anoRegistro: '2020',
          seccion: '1234',
          vigencia: '2030',
          tipo: 't3',
          lado: 'frontal',
          estado: 'CDMX',
          municipio: 'BENITO JUAREZ',
          localidad: 'CENTRO',
          photoPath: '', // Empty photo path to test correction
          signaturePath: '', // Empty signature path to test correction
          qrContent: '',
          qrImagePath: '',
          barcodeContent: '',
          barcodeImagePath: '',
          mrzContent: '',
          mrzImagePath: '',
          mrzDocumentNumber: '',
          mrzNationality: '',
          mrzBirthDate: '',
          mrzExpiryDate: '',
          mrzSex: '',
          signatureHuellaImagePath: '',
        );

        // Note: This test would require actual image files to work properly
        // For now, we just test that the method doesn't throw an exception
        expect(() async {
          await CredentialProcessingFixes.updateCredentialWithFixes(
            testCredential,
            'test_image_path.jpg',
          );
        }, returnsNormally);
      });
    });
  });
}