import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

import '../../lib/app/core/services/image_quality_analysis_service.dart';
import '../../lib/app/core/services/memory_management_service.dart';

void main() {
  group('Image Quality Analysis - Memory Management Integration', () {
    late Directory tempDir;
    late List<String> testImages;

    setUpAll(() async {
      // Crear directorio temporal para imágenes de prueba
      tempDir = await Directory.systemTemp.createTemp('image_quality_test_');
      testImages = [];
      
      print('📁 Directorio temporal creado: ${tempDir.path}');
    });

    tearDownAll(() async {
      // Limpiar archivos de prueba
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        print('🗑️ Directorio temporal eliminado');
      }
    });

    test('debe procesar múltiples imágenes sin crashes por memoria', () async {
      print('\n🧪 Test: Procesamiento múltiple sin crashes');
      print('=' * 50);
      
      // Crear múltiples imágenes de prueba con diferentes características
      final imageConfigs = [
        {'name': 'bright', 'brightness': 220, 'size': 800},
        {'name': 'dark', 'brightness': 30, 'size': 1200},
        {'name': 'normal', 'brightness': 128, 'size': 1000},
        {'name': 'large', 'brightness': 150, 'size': 2000},
        {'name': 'small', 'brightness': 100, 'size': 400},
      ];
      
      // Crear imágenes de prueba
      for (final config in imageConfigs) {
        final size = config['size'] as int;
        final brightness = config['brightness'] as int;
        final name = config['name'] as String;
        
        final image = img.Image(width: size, height: size);
        img.fill(image, color: img.ColorRgb8(brightness, brightness, brightness));
        
        // Agregar algo de ruido para hacer el análisis más realista
        final random = math.Random();
        for (int i = 0; i < size * size ~/ 10; i++) {
          final x = random.nextInt(size);
          final y = random.nextInt(size);
          final noise = random.nextInt(50) - 25;
          final newBrightness = (brightness + noise).clamp(0, 255);
          image.setPixel(x, y, img.ColorRgb8(newBrightness, newBrightness, newBrightness));
        }
        
        final imagePath = path.join(tempDir.path, 'test_${name}_image.png');
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(img.encodePng(image));
        testImages.add(imagePath);
        
        print('✅ Imagen $name creada: ${size}x$size, brillo: $brightness');
      }
      
      print('\n🔄 Procesando ${testImages.length} imágenes...');
      
      // Procesar cada imagen y verificar gestión de memoria
      for (int i = 0; i < testImages.length; i++) {
        print('\n📊 Procesando imagen ${i + 1}/${testImages.length}: ${path.basename(testImages[i])}');
        
        // Verificar memoria antes del procesamiento
        final memoryBefore = await MemoryManagementService.getMemoryInfo();
        print('   📈 Memoria antes: ${(memoryBefore['used'] ?? 0) ~/ (1024 * 1024)} MB');
        
        // Procesar imagen con análisis de calidad
        final result = await ImageQualityAnalysisService.analyzeImageQuality(testImages[i]);
        
        // Verificar que el análisis se completó
        expect(result, isNotNull);
        expect(result.containsKey('hasProblems'), isTrue);
        expect(result.containsKey('metrics'), isTrue);
        
        // Verificar memoria después del procesamiento
        final memoryAfter = await MemoryManagementService.getMemoryInfo();
        print('   📉 Memoria después: ${(memoryAfter['used'] ?? 0) ~/ (1024 * 1024)} MB');
        
        // Mostrar resultados del análisis
        final hasProblems = result['hasProblems'] as bool;
        final metrics = result['metrics'] as Map<String, dynamic>;
        print('   🔍 Problemas detectados: $hasProblems');
        print('   📊 Brillo: ${metrics['brightness']?.toStringAsFixed(1) ?? "N/A"}');
        print('   📊 Contraste: ${metrics['contrast']?.toStringAsFixed(1) ?? "N/A"}');
        
        // Forzar limpieza de memoria
        await MemoryManagementService.forceGarbageCollection();
        
        // Verificar que no hay crash (el test continúa)
        print('   ✅ Imagen procesada exitosamente');
        
        // Pequeña pausa entre procesamiento
        await Future.delayed(Duration(milliseconds: 200));
      }
      
      print('\n🎉 Todas las imágenes procesadas exitosamente sin crashes');
      
      // Verificar que el servicio sigue funcionando
      expect(true, isTrue); // Si llegamos aquí, no hubo crashes
    });
    
    test('debe manejar correctamente imágenes grandes con gestión de memoria', () async {
      print('\n🧪 Test: Manejo de imágenes grandes');
      print('=' * 50);
      
      // Crear imagen muy grande para estresar la memoria
      const largeSize = 3000;
      final largeImage = img.Image(width: largeSize, height: largeSize);
      
      // Crear patrón complejo para análisis más intensivo
      for (int y = 0; y < largeSize; y++) {
        for (int x = 0; x < largeSize; x++) {
          final brightness = ((math.sin(x / 100.0) + math.cos(y / 100.0)) * 50 + 128).round().clamp(0, 255);
          largeImage.setPixel(x, y, img.ColorRgb8(brightness, brightness, brightness));
        }
      }
      
      final imagePath = path.join(tempDir.path, 'large_stress_test.png');
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(img.encodePng(largeImage));
      
      print('✅ Imagen grande creada: ${largeSize}x$largeSize píxeles');
      
      // Procesar la imagen múltiples veces
      for (int i = 0; i < 3; i++) {
        print('\n🔄 Procesamiento de estrés ${i + 1}/3');
        
        // Verificar memoria antes
        final memoryBefore = await MemoryManagementService.getMemoryInfo();
        print('   📈 Memoria antes: ${(memoryBefore['used'] ?? 0) ~/ (1024 * 1024)} MB');
        
        // Preparar memoria
        await MemoryManagementService.prepareForIntensiveOperation();
        
        // Procesar imagen
        final result = await ImageQualityAnalysisService.analyzeImageQuality(imagePath);
        
        // Verificar resultado
        expect(result, isNotNull);
        expect(result.containsKey('hasProblems'), isTrue);
        
        // Limpiar memoria
        await MemoryManagementService.cleanupAfterIntensiveOperation();
        
        // Verificar memoria después
        final memoryAfter = await MemoryManagementService.getMemoryInfo();
        print('   📉 Memoria después: ${(memoryAfter['used'] ?? 0) ~/ (1024 * 1024)} MB');
        
        print('   ✅ Procesamiento de estrés $i completado');
        
        // Pausa entre procesamiento
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      print('\n🎉 Test de estrés completado sin crashes');
    });
    
    test('debe optimizar automáticamente imágenes grandes', () async {
      print('\n🧪 Test: Optimización automática de imágenes');
      print('=' * 50);
      
      // Crear imagen que debería ser redimensionada automáticamente
      const originalSize = 1500;
      final originalImage = img.Image(width: originalSize, height: originalSize);
      img.fill(originalImage, color: img.ColorRgb8(128, 128, 128));
      
      final imagePath = path.join(tempDir.path, 'auto_resize_test.png');
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(img.encodePng(originalImage));
      
      print('✅ Imagen original creada: ${originalSize}x$originalSize píxeles');
      
      // Procesar imagen (debería ser redimensionada automáticamente)
      final startTime = DateTime.now();
      final result = await ImageQualityAnalysisService.analyzeImageQuality(imagePath);
      final processingTime = DateTime.now().difference(startTime);
      
      // Verificar que el análisis se completó
      expect(result, isNotNull);
      expect(result.containsKey('metrics'), isTrue);
      
      final metrics = result['metrics'] as Map<String, dynamic>;
      print('📊 Métricas obtenidas:');
      print('   - Brillo: ${metrics['brightness']?.toStringAsFixed(1) ?? "N/A"}');
      print('   - Contraste: ${metrics['contrast']?.toStringAsFixed(1) ?? "N/A"}');
      print('   - Tiempo de procesamiento: ${processingTime.inMilliseconds}ms');
      
      // El tiempo de procesamiento debería ser razonable gracias a la optimización
      expect(processingTime.inSeconds, lessThan(10), 
        reason: 'El procesamiento debería completarse en menos de 10 segundos gracias a la optimización');
      
      print('✅ Imagen procesada eficientemente con optimización automática');
    });
  });
}