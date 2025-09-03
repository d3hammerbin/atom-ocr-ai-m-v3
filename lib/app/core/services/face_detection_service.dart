import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FaceDetectionService {
  static FaceDetector? _faceDetector;
  
  /// Inicializa el detector de rostros con configuración optimizada
  static FaceDetector get _detector {
    _faceDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: false,
        enableTracking: false,
        minFaceSize: 0.1, // Tamaño mínimo de rostro (10% de la imagen)
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    return _faceDetector!;
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
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _detector.processImage(inputImage);
      
      if (faces.isEmpty) {
        print('No se detectaron rostros en la imagen');
        return null;
      }
      
      // Cargar la imagen original
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        print('Error al decodificar la imagen');
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
      
    } catch (e) {
      print('Error al extraer foto del rostro: $e');
      return null;
    }
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
    await _faceDetector?.close();
    _faceDetector = null;
  }
}