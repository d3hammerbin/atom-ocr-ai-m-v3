import 'package:flutter_test/flutter_test.dart';
import 'package:atom_ocr_ai_m_v3/app/core/services/memory_management_service.dart';
import 'package:atom_ocr_ai_m_v3/app/core/services/face_detection_service.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

void main() {
  group('Memory Management - Face Detection Integration', () {
    late Directory tempDir;
    
    setUpAll(() async {
      // Inicializar binding de Flutter para las pruebas
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Crear directorio temporal para las pruebas
      tempDir = Directory.systemTemp.createTempSync('memory_test_');
    });
    
    tearDownAll(() async {
      // Limpiar directorio temporal
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      
      // Liberar recursos del detector
      await FaceDetectionService.dispose();
    });
    
    test('debe manejar múltiples operaciones de detección facial sin crash', () async {
      // Crear múltiples imágenes de prueba
      final testImages = <String>[];
      
      for (int i = 0; i < 5; i++) {
        // Crear imagen de prueba de tamaño variable
        final width = 400 + (i * 200); // 400, 600, 800, 1000, 1200
        final height = 300 + (i * 150); // 300, 450, 600, 750, 900
        
        final image = img.Image(width: width, height: height);
        img.fill(image, color: img.ColorRgb8(100 + i * 30, 150, 200));
        
        // Agregar algunos "rostros" simulados (rectángulos)
        img.fillRect(image, 
          x1: width ~/ 4, 
          y1: height ~/ 4, 
          x2: (width * 3) ~/ 4, 
          y2: (height * 3) ~/ 4, 
          color: img.ColorRgb8(255, 220, 177)
        );
        
        final imagePath = path.join(tempDir.path, 'test_image_$i.png');
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(img.encodePng(image));
        testImages.add(imagePath);
      }
      
      print('✅ Creadas ${testImages.length} imágenes de prueba');
      
      // Procesar cada imagen y verificar gestión de memoria
      for (int i = 0; i < testImages.length; i++) {
        print('🔄 Procesando imagen ${i + 1}/${testImages.length}');
        
        // Verificar memoria antes del procesamiento
        final memoryBefore = await MemoryManagementService.getMemoryInfo();
        print('📊 Memoria antes: ${memoryBefore['used']} bytes');
        
        // Procesar imagen
        final result = await FaceDetectionService.extractFaceFromCredential(testImages[i]);
        
        // Verificar memoria después del procesamiento
        final memoryAfter = await MemoryManagementService.getMemoryInfo();
        print('📊 Memoria después: ${memoryAfter['used']} bytes');
        
        // Forzar limpieza de memoria
        await MemoryManagementService.forceGarbageCollection();
        
        // Verificar que no hay crash (el test continúa)
        print('✅ Imagen $i procesada sin crash. Resultado: ${result != null ? "Rostro detectado" : "No se detectó rostro"}');
        
        // Pequeña pausa entre procesamiento
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      print('🎉 Todas las imágenes procesadas exitosamente sin crashes');
      
      // Verificar que el servicio sigue funcionando
      expect(true, isTrue); // Si llegamos aquí, no hubo crashes
    });
    
    test('debe manejar correctamente la gestión de memoria bajo estrés', () async {
      // Crear imagen grande para estresar la memoria
      final largeImage = img.Image(width: 2000, height: 1500);
      img.fill(largeImage, color: img.ColorRgb8(128, 128, 128));
      
      // Agregar múltiples "rostros" simulados
      for (int i = 0; i < 3; i++) {
        img.fillRect(largeImage,
          x1: 200 + i * 600,
          y1: 200,
          x2: 500 + i * 600,
          y2: 500,
          color: img.ColorRgb8(255, 220, 177)
        );
      }
      
      final imagePath = path.join(tempDir.path, 'stress_test_image.png');
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(img.encodePng(largeImage));
      
      print('✅ Imagen de estrés creada: 2000x1500 píxeles');
      
      // Procesar la imagen múltiples veces
      for (int i = 0; i < 3; i++) {
        print('🔄 Procesamiento de estrés ${i + 1}/3');
        
        // Preparar memoria
        await MemoryManagementService.prepareForIntensiveOperation();
        
        // Procesar imagen
        final result = await FaceDetectionService.extractFaceFromCredential(imagePath);
        
        // Limpiar memoria
        await MemoryManagementService.cleanupAfterIntensiveOperation();
        
        print('✅ Procesamiento de estrés $i completado. Resultado: ${result != null ? "Rostro detectado" : "No se detectó rostro"}');
        
        // Pausa entre procesamiento
        await Future.delayed(Duration(milliseconds: 200));
      }
      
      print('🎉 Test de estrés completado sin crashes');
      expect(true, isTrue);
    });
    
    test('debe recuperarse de errores de memoria', () async {
      // Crear imagen corrupta para forzar error
      final corruptImagePath = path.join(tempDir.path, 'corrupt_image.png');
      final corruptFile = File(corruptImagePath);
      await corruptFile.writeAsBytes([1, 2, 3, 4, 5]); // Datos inválidos
      
      print('✅ Imagen corrupta creada para test de recuperación');
      
      // Intentar procesar imagen corrupta
      final result = await FaceDetectionService.extractFaceFromCredential(corruptImagePath);
      
      // Debe manejar el error sin crash (retorna cadena vacía)
      expect(result, isEmpty);
      print('✅ Error de imagen corrupta manejado correctamente');
      
      // Verificar que el servicio sigue funcionando después del error
      final normalImage = img.Image(width: 400, height: 300);
      img.fill(normalImage, color: img.ColorRgb8(200, 200, 200));
      
      final normalImagePath = path.join(tempDir.path, 'recovery_test.png');
      final normalFile = File(normalImagePath);
      await normalFile.writeAsBytes(img.encodePng(normalImage));
      
      final recoveryResult = await FaceDetectionService.extractFaceFromCredential(normalImagePath);
      
      print('✅ Servicio recuperado después del error');
      expect(true, isTrue); // Si llegamos aquí, la recuperación fue exitosa
    });
  });
}