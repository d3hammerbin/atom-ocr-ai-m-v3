import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'memory_management_service.dart';
import 'exif_service.dart';
import 'watermark_service.dart';
import 'app_config_service.dart';

class FaceDetectionService {
  static FaceDetector? _detectorInstance;
  
  /// Inicializa el detector de rostros con configuración optimizada
  static FaceDetector get _detector {
    _detectorInstance ??= FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: false,
        enableTracking: false,
        minFaceSize: 0.1, // Tamaño mínimo de rostro (10% de la imagen)
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    return _detectorInstance!;
  }
  
  /// Reinicia el detector para liberar memoria acumulada
  static Future<void> _resetDetector() async {
    if (_detectorInstance != null) {
      try {
        await _detectorInstance!.close();
      } catch (e) {
        print('⚠️ Error al cerrar detector: $e');
      }
      _detectorInstance = null;
    }
  }
  
  /// Detecta rostros en una imagen y extrae la fotografía más grande y clara
  /// Retorna la ruta del archivo de la foto extraída o cadena vacía si no se encuentra
  static Future<String> extractFaceFromCredential(String imagePath) async {
    // Generar ID único para la credencial basado en timestamp
    final credentialId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final result = await extractLargestFacePhoto(
      imagePath: imagePath,
      credentialId: credentialId,
    );
    
    return result ?? '';
  }
  
  /// Detecta rostros en una imagen y extrae la fotografía más grande y clara
  /// Retorna la ruta del archivo de la foto extraída o null si no se encuentra
  static Future<String?> extractLargestFacePhoto({
    required String imagePath,
    required String credentialId,
  }) async {
    try {
      // Preparar memoria para operación intensiva
      await MemoryManagementService.prepareForIntensiveOperation();
      
      // Reiniciar detector periódicamente para evitar acumulación de memoria
      await _resetDetector();
      // Validar que el archivo existe
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        print('❌ El archivo de imagen no existe: $imagePath');
        return null;
      }

      // Cargar y validar la imagen antes del procesamiento ML Kit
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        print('❌ Error al decodificar la imagen');
        return null;
      }

      // Validar dimensiones de imagen para evitar errores de tensor dinámico
      if (originalImage.width < 50 || originalImage.height < 50) {
        print('❌ Imagen demasiado pequeña para detección de rostros: ${originalImage.width}x${originalImage.height}');
        return null;
      }

      if (originalImage.width > 4000 || originalImage.height > 4000) {
        print('⚠️ Imagen muy grande, redimensionando para evitar errores de tensor: ${originalImage.width}x${originalImage.height}');
        // Redimensionar imagen manteniendo proporción
        final maxDimension = 2000;
        final scale = maxDimension / (originalImage.width > originalImage.height ? originalImage.width : originalImage.height);
        if (scale < 1.0) {
          final resizedImage = img.copyResize(
            originalImage,
            width: (originalImage.width * scale).round(),
            height: (originalImage.height * scale).round(),
            interpolation: img.Interpolation.linear,
          );
          
          // Guardar imagen redimensionada temporalmente
          final tempDir = await getTemporaryDirectory();
          final tempPath = path.join(tempDir.path, 'temp_face_${DateTime.now().millisecondsSinceEpoch}.png');
          final tempFile = File(tempPath);
          await tempFile.writeAsBytes(img.encodePng(resizedImage));
          
          // Usar imagen redimensionada para ML Kit
          final inputImage = InputImage.fromFilePath(tempPath);
          final faces = await _detector.processImage(inputImage);
          
          // Limpiar archivo temporal
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          
          return await _processFaceDetectionResults(faces, originalImage, credentialId);
        }
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _detector.processImage(inputImage);
      
      final result = await _processFaceDetectionResults(faces, originalImage, credentialId);
      
      // Limpiar memoria después del procesamiento
      await MemoryManagementService.cleanupAfterIntensiveOperation();
      
      return result;
      
    } catch (e) {
      // Manejo específico para errores de tensor dinámico y memoria
      if (e.toString().contains('dynamic-sized tensor') || 
          e.toString().contains('tensor') ||
          e.toString().contains('FaceDetectorV2Jni') ||
          e.toString().contains('OutOfMemoryError') ||
          e.toString().contains('memory')) {
        print('❌ Error de tensor/memoria detectado: $e');
        print('💡 Reiniciando detector y reintentando...');
        
        // Limpiar memoria agresivamente
        await MemoryManagementService.forceGarbageCollection();
        
        // Forzar reinicio del detector para liberar memoria
        await _resetDetector();
        
        try {
          // Intentar con imagen más pequeña
          final imageFile = File(imagePath);
          final imageBytes = await imageFile.readAsBytes();
          final originalImage = img.decodeImage(imageBytes);
          
          if (originalImage != null) {
            // Redimensionar a tamaño fijo más pequeño para reducir uso de memoria
            final resizedImage = img.copyResize(
              originalImage,
              width: 600, // Reducido de 800 a 600 para menor uso de memoria
              height: (600 * originalImage.height / originalImage.width).round(),
              interpolation: img.Interpolation.linear,
            );
            
            final tempDir = await getTemporaryDirectory();
            final tempPath = path.join(tempDir.path, 'temp_face_small_${DateTime.now().millisecondsSinceEpoch}.png');
            final tempFile = File(tempPath);
            await tempFile.writeAsBytes(img.encodePng(resizedImage));
            
            final inputImage = InputImage.fromFilePath(tempPath);
            final faces = await _detector.processImage(inputImage);
            
            // Limpiar archivo temporal inmediatamente
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
            
            final result = await _processFaceDetectionResults(faces, originalImage, credentialId);
            
            // Reiniciar detector después del procesamiento para liberar memoria
            await _resetDetector();
            
            return result;
          }
        } catch (retryError) {
          print('❌ Error en reintento con imagen redimensionada: $retryError');
          // Reiniciar detector en caso de error
          await _resetDetector();
        }
      }
      
      print('❌ Error al extraer foto del rostro: $e');
      // Reiniciar detector en caso de cualquier error para evitar estados corruptos
      await _resetDetector();
      return null;
    }
  }
  
  /// Procesa los resultados de detección de rostros
  static Future<String?> _processFaceDetectionResults(
    List<Face> faces, 
    img.Image originalImage, 
    String credentialId
  ) async {
    if (faces.isEmpty) {
      print('No se detectaron rostros en la imagen');
      return null;
    }
    
    // Encontrar el mejor rostro basado en múltiples criterios
    Face? bestFace;
    double bestScore = 0;
    
    print('🔍 Analizando ${faces.length} rostros detectados:');
    
    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      final area = face.boundingBox.width * face.boundingBox.height;
      final imageArea = originalImage.width * originalImage.height;
      final faceAreaRatio = area / imageArea;
      
      // Calcular posición relativa (0 = izquierda, 1 = derecha)
      final relativeX = face.boundingBox.center.dx / originalImage.width;
      
      // Criterios de evaluación:
      // 1. Área del rostro (más grande es mejor, pero no demasiado)
      double areaScore = 0;
      if (faceAreaRatio >= 0.02 && faceAreaRatio <= 0.3) {
        areaScore = (faceAreaRatio * 100).clamp(0, 30) / 30; // Normalizar a 0-1
      }
      
      // 2. Posición (preferir lado izquierdo de la credencial)
      double positionScore = 1.0 - relativeX; // Más a la izquierda = mejor score
      
      // 3. Calidad del rostro (basado en ángulos de cabeza)
      double qualityScore = 1.0;
      if (face.headEulerAngleY != null) {
        // Penalizar rostros muy rotados
        final rotationPenalty = (face.headEulerAngleY!.abs() / 45.0).clamp(0, 1);
        qualityScore -= rotationPenalty * 0.3;
      }
      
      // Calcular score total (ponderado)
      final totalScore = (areaScore * 0.4) + (positionScore * 0.4) + (qualityScore * 0.2);
      
      print('  Rostro $i: área=${(faceAreaRatio*100).toStringAsFixed(2)}%, posX=${relativeX.toStringAsFixed(2)}, score=${totalScore.toStringAsFixed(3)}');
      
      if (totalScore > bestScore && faceAreaRatio >= 0.02) {
        bestScore = totalScore;
        bestFace = face;
      }
    }
    
    if (bestFace == null) {
      print('❌ No se encontró un rostro adecuado');
      return null;
    }
    
    final bestArea = bestFace.boundingBox.width * bestFace.boundingBox.height;
    final bestAreaRatio = bestArea / (originalImage.width * originalImage.height);
    print('✅ Mejor rostro seleccionado: área=${(bestAreaRatio*100).toStringAsFixed(2)}%, score=${bestScore.toStringAsFixed(3)}');
    
    // Expandir el área de recorte para incluir más contexto alrededor del rostro
    final boundingBox = bestFace.boundingBox;
    
    // Calcular padding dinámico para capturar más área de la fotografía completa
    final paddingX = (boundingBox.width * 0.25).toInt(); // 25% más de área horizontal
    final paddingY = (boundingBox.height * 0.25).toInt(); // 25% más de área vertical
    
    final cropX = (boundingBox.left - paddingX).clamp(0, originalImage.width - 1).toInt();
    final cropY = (boundingBox.top - paddingY).clamp(0, originalImage.height - 1).toInt();
    final cropWidth = (boundingBox.width + (paddingX * 2))
        .clamp(1, originalImage.width - cropX)
        .toInt();
    final cropHeight = (boundingBox.height + (paddingY * 2))
        .clamp(1, originalImage.height - cropY)
        .toInt();
    
    print('📐 Padding aplicado: X=${paddingX}px, Y=${paddingY}px (25% del rostro para más contexto)');
    
    // Recortar la imagen del rostro
    final croppedImage = img.copyCrop(
      originalImage,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );
    
    // Aplicar mejoras de calidad a la imagen del rostro
    final enhancedImage = _enhanceFaceImage(croppedImage);
    
    // Guardar la imagen del rostro extraída
    final savedPath = await _saveFaceImage(enhancedImage, credentialId);
    
    print('Rostro extraído y guardado en: $savedPath');
    print('Área del rostro: ${(bestAreaRatio * 100).toStringAsFixed(2)}% de la imagen total');
    
    return savedPath;
  }
  
  /// Aplica mejoras de calidad a la imagen del rostro extraída
  static img.Image _enhanceFaceImage(img.Image faceImage) {
    // Aplicar ajustes de contraste y brillo
    var enhanced = img.adjustColor(
      faceImage,
      contrast: 1.1, // Aumentar contraste ligeramente
      brightness: 1.05, // Aumentar brillo ligeramente
      saturation: 1.0,
    );
    
    // Aplicar filtro de nitidez suave
    enhanced = img.convolution(
      enhanced,
      filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ],
      div: 1,
    );
    
    return enhanced;
  }
  
  /// Guarda la imagen del rostro en el directorio de la aplicación
  static Future<String> _saveFaceImage(img.Image faceImage, String credentialId) async {
    try {
      // Obtener directorio de documentos de la aplicación
      final appDir = await getApplicationDocumentsDirectory();
      final facesDir = Directory(path.join(appDir.path, 'faces'));
      
      // Crear directorio si no existe
      if (!await facesDir.exists()) {
        await facesDir.create(recursive: true);
      }
      
      // Generar nombre de archivo único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${credentialId}_face_$timestamp.png';
      final filePath = path.join(facesDir.path, fileName);
      
      // Codificar y guardar la imagen
      final pngBytes = img.encodePng(faceImage);
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      
      // Agregar metadatos EXIF a la imagen del rostro extraído solo si está habilitado
      final bool isExifEnabled = AppConfigService.isExifProcessingEnabled ?? false;
      if (isExifEnabled) {
        await ExifService.addProcessingMetadata(
          imagePath: filePath,
          credentialType: 'Face Extraction',
          processingDate: DateTime.now().toIso8601String(),
        );
      }
      
      // Aplicar watermark inmediatamente después de guardar
      await WatermarkService.addWatermarkIfEnabled(imagePath: filePath);
      
      return filePath;
      
    } catch (e) {
      print('Error al guardar imagen del rostro: $e');
      rethrow;
    }
  }
  
  /// Obtiene información detallada de los rostros detectados (para debugging)
  static Future<List<Map<String, dynamic>>> getFaceAnalysis(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _detector.processImage(inputImage);
      
      final analysis = <Map<String, dynamic>>[];
      
      for (int i = 0; i < faces.length; i++) {
        final face = faces[i];
        final area = face.boundingBox.width * face.boundingBox.height;
        
        analysis.add({
          'index': i,
          'boundingBox': {
            'left': face.boundingBox.left,
            'top': face.boundingBox.top,
            'width': face.boundingBox.width,
            'height': face.boundingBox.height,
          },
          'area': area,
          'headEulerAngleY': face.headEulerAngleY,
          'headEulerAngleZ': face.headEulerAngleZ,
          'leftEyeOpenProbability': face.leftEyeOpenProbability,
          'rightEyeOpenProbability': face.rightEyeOpenProbability,
          'smilingProbability': face.smilingProbability,
        });
      }
      
      return analysis;
      
    } catch (e) {
      print('Error en análisis de rostros: $e');
      return [];
    }
  }
  
  /// Libera los recursos del detector
  static Future<void> dispose() async {
    try {
      await _detectorInstance?.close();
    } catch (e) {
      print('⚠️ Error al liberar recursos del detector: $e');
    } finally {
      _detectorInstance = null;
    }
  }
}