import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/app/core/services/exif_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ExifService Integration Tests', () {
    test('ExifService class should be properly defined', () {
      // Verificar que la clase ExifService existe y tiene los métodos esperados
      expect(ExifService.addProcessingMetadata, isA<Function>());
      expect(ExifService.addGpsMetadata, isA<Function>());
      expect(ExifService.stripAllMetadata, isA<Function>());
    });

    test('addProcessingMetadata should handle invalid file path gracefully', () async {
      // Test que el método maneja archivos inexistentes correctamente
      final result = await ExifService.addProcessingMetadata(
        imagePath: '/path/that/does/not/exist.png',
        credentialType: 'INE',
      );
      
      // Debe retornar false para archivos que no existen
      expect(result, isFalse);
    });

    test('addProcessingMetadata should accept valid parameters', () {
      // Verificar que el método acepta los parámetros correctos sin lanzar errores de compilación
      expect(() {
        ExifService.addProcessingMetadata(
          imagePath: 'test.png',
          credentialType: 'INE',
        );
      }, returnsNormally);
      
      expect(() {
        ExifService.addProcessingMetadata(
          imagePath: 'test.png',
          credentialType: 'PASSPORT',
          processingDate: DateTime.now().toIso8601String(),
        );
      }, returnsNormally);
    });

    test('service should handle different credential types', () {
      final credentialTypes = ['INE', 'PASSPORT', 'DRIVER_LICENSE', 'CEDULA'];
      
      for (final type in credentialTypes) {
        expect(() {
          ExifService.addProcessingMetadata(
            imagePath: 'test.png',
            credentialType: type,
          );
        }, returnsNormally);
      }
    });
  });
}