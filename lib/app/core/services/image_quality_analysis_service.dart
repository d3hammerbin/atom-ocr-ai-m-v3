import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'logger_service.dart';
import 'memory_management_service.dart';

/// Servicio para analizar la calidad de iluminación de imágenes
/// antes del procesamiento OCR
class ImageQualityAnalysisService {
  static final LoggerService _logger = LoggerService.instance;
  
  // Umbrales para análisis de calidad
  static const double MIN_BRIGHTNESS = 50.0;
  static const double MAX_BRIGHTNESS = 200.0;
  static const double MIN_CONTRAST = 30.0;
  static const double MAX_GLARE_PERCENTAGE = 15.0;
  static const double MIN_LAPLACIAN_VARIANCE = 100.0;
  static const double MAX_SHADOW_PERCENTAGE = 25.0;
  
  /// Analiza la calidad de iluminación de una imagen
  /// Retorna un mapa con información sobre problemas detectados
  static Future<Map<String, dynamic>> analyzeImageQuality(String imagePath) async {
    try {
      // Preparar memoria para análisis
      await MemoryManagementService.prepareForIntensiveOperation();
      
      _logger.info('ImageQualityAnalysisService', '🔍 Analizando calidad de imagen: $imagePath');
      
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return {
          'hasProblems': true,
          'error': 'El archivo de imagen no existe',
          'problems': ['Archivo no encontrado'],
          'metrics': {},
          'recommendations': ['Verifique que la imagen esté disponible'],
        };
      }
      
      final imageBytes = await imageFile.readAsBytes();
      var image = img.decodeImage(imageBytes);
      
      if (image == null) {
        return {
          'hasProblems': true,
          'error': 'No se pudo decodificar la imagen',
          'problems': ['Formato de imagen inválido'],
          'metrics': {},
          'recommendations': ['Use un formato de imagen válido (JPG, PNG)'],
        };
      }
      
      // Optimización: redimensionar imagen para análisis si es muy grande
      // Esto reduce significativamente el uso de memoria
      const maxAnalysisSize = 800;
      if (image.width > maxAnalysisSize || image.height > maxAnalysisSize) {
        final scale = maxAnalysisSize / math.max(image.width, image.height);
        final newWidth = (image.width * scale).round();
        final newHeight = (image.height * scale).round();
        
        _logger.info('ImageQualityAnalysisService', 
          '📏 Redimensionando imagen para análisis: ${image.width}x${image.height} → ${newWidth}x${newHeight}');
        
        image = img.copyResize(image, width: newWidth, height: newHeight);
        
        // Limpiar memoria después del redimensionamiento
        await MemoryManagementService.forceGarbageCollection();
      }
      
      // Calcular métricas de calidad
      final brightness = _calculateBrightness(image);
      final contrast = _calculateContrast(image);
      final glarePercentage = _calculateGlarePercentage(image);
      final laplacianVariance = _calculateLaplacianVariance(image);
      final shadowPercentage = _calculateShadowPercentage(image);
      final uniformity = _calculateIlluminationUniformity(image);
      
      _logger.info('ImageQualityAnalysisService', 
        '📊 Métricas calculadas - Brillo: ${brightness.toStringAsFixed(1)}, '
        'Contraste: ${contrast.toStringAsFixed(1)}, '
        'Glare: ${glarePercentage.toStringAsFixed(1)}%, '
        'Nitidez: ${laplacianVariance.toStringAsFixed(1)}');
      
      // Detectar problemas
      final problems = <String>[];
      
      if (brightness < MIN_BRIGHTNESS) {
        problems.add('Imagen muy oscura');
      }
      if (brightness > MAX_BRIGHTNESS) {
        problems.add('Imagen sobreexpuesta');
      }
      if (contrast < MIN_CONTRAST) {
        problems.add('Contraste insuficiente');
      }
      if (glarePercentage > MAX_GLARE_PERCENTAGE) {
        problems.add('Reflejos detectados');
      }
      if (laplacianVariance < MIN_LAPLACIAN_VARIANCE) {
        problems.add('Imagen desenfocada');
      }
      if (shadowPercentage > MAX_SHADOW_PERCENTAGE) {
        problems.add('Sombras excesivas');
      }
      if (uniformity < 0.7) {
        problems.add('Iluminación desigual');
      }
      
      final hasProblems = problems.isNotEmpty;
      
      if (hasProblems) {
        _logger.warning('ImageQualityAnalysisService', 
          '⚠️ Problemas detectados: ${problems.join(", ")}');
      } else {
        _logger.info('ImageQualityAnalysisService', '✅ Calidad de imagen aceptable');
      }
      
      return {
        'hasProblems': hasProblems,
        'problems': problems,
        'metrics': {
          'brightness': brightness,
          'contrast': contrast,
          'glarePercentage': glarePercentage,
          'laplacianVariance': laplacianVariance,
          'shadowPercentage': shadowPercentage,
          'illuminationUniformity': uniformity,
        },
        'recommendations': _getRecommendations(problems),
        'qualityScore': _calculateOverallQualityScore(brightness, contrast, glarePercentage, laplacianVariance, uniformity),
      };
      
    } catch (e) {
      _logger.error('ImageQualityAnalysisService', 'Error analizando calidad de imagen: $e');
      return {
        'hasProblems': true,
        'error': 'Error interno al analizar la imagen: $e',
        'problems': ['Error de procesamiento'],
        'metrics': {},
        'recommendations': ['Intente con otra imagen'],
      };
    } finally {
      // Limpiar memoria después del análisis
      await MemoryManagementService.cleanupAfterIntensiveOperation();
    }
  }
  
  /// Calcula el brillo promedio de la imagen usando muestreo optimizado
  static double _calculateBrightness(img.Image image) {
    int totalLuminance = 0;
    int sampleCount = 0;
    
    // Usar muestreo cada 4 píxeles para reducir carga computacional
    const step = 4;
    
    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        totalLuminance += img.getLuminance(pixel).round();
        sampleCount++;
      }
    }
    
    return sampleCount > 0 ? totalLuminance / sampleCount : 0;
  }
  
  /// Calcula el contraste usando muestreo optimizado
  static double _calculateContrast(img.Image image) {
    final brightnesses = <int>[];
    
    // Usar muestreo cada 8 píxeles para el cálculo de contraste
    const step = 8;
    
    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        brightnesses.add(img.getLuminance(pixel).round());
      }
    }
    
    if (brightnesses.length < 2) return 0;
    
    brightnesses.sort();
    final p95Index = (brightnesses.length * 0.95).round().clamp(0, brightnesses.length - 1);
    final p5Index = (brightnesses.length * 0.05).round().clamp(0, brightnesses.length - 1);
    
    final p95 = brightnesses[p95Index];
    final p5 = brightnesses[p5Index];
    
    return (p95 - p5).toDouble();
  }
  
  /// Calcula el porcentaje de píxeles con glare (reflejos) usando muestreo
  static double _calculateGlarePercentage(img.Image image) {
    int glarePixels = 0;
    int sampleCount = 0;
    
    // Usar muestreo cada 6 píxeles para detectar glare
    const step = 6;
    
    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        
        // Detectar píxeles saturados (muy brillantes)
        if (r > 240 && g > 240 && b > 240) {
          glarePixels++;
        }
        sampleCount++;
      }
    }
    
    return sampleCount > 0 ? (glarePixels / sampleCount) * 100 : 0;
  }
  
  /// Calcula la varianza del Laplaciano para medir nitidez usando muestreo
  static double _calculateLaplacianVariance(img.Image image) {
    // Convertir a escala de grises
    final grayImage = img.grayscale(image);
    
    // Kernel del Laplaciano
    final laplacianKernel = [
      [0, -1, 0],
      [-1, 4, -1],
      [0, -1, 0],
    ];
    
    final laplacianValues = <double>[];
    
    // Usar muestreo cada 8 píxeles para el cálculo de nitidez
    const step = 8;
    
    // Aplicar filtro Laplaciano con muestreo
    for (int y = 1; y < grayImage.height - 1; y += step) {
      for (int x = 1; x < grayImage.width - 1; x += step) {
        double laplacianValue = 0;
        
        for (int ky = 0; ky < 3; ky++) {
          for (int kx = 0; kx < 3; kx++) {
            final pixel = grayImage.getPixel(x + kx - 1, y + ky - 1);
            final intensity = img.getLuminance(pixel);
            laplacianValue += intensity * laplacianKernel[ky][kx];
          }
        }
        
        laplacianValues.add(laplacianValue);
      }
    }
    
    // Calcular varianza
    if (laplacianValues.isEmpty) return 0;
    
    final mean = laplacianValues.reduce((a, b) => a + b) / laplacianValues.length;
    final variance = laplacianValues
        .map((value) => math.pow(value - mean, 2))
        .reduce((a, b) => a + b) / laplacianValues.length;
    
    return variance;
  }
  
  /// Calcula el porcentaje de píxeles en sombra usando muestreo
  static double _calculateShadowPercentage(img.Image image) {
    int shadowPixels = 0;
    int sampleCount = 0;
    const shadowThreshold = 50; // Umbral para considerar un píxel como sombra
    
    // Usar muestreo cada 6 píxeles para detectar sombras
    const step = 6;
    
    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        
        if (luminance < shadowThreshold) {
          shadowPixels++;
        }
        sampleCount++;
      }
    }
    
    return sampleCount > 0 ? (shadowPixels / sampleCount) * 100 : 0;
  }
  
  /// Calcula la uniformidad de la iluminación usando muestreo optimizado
  static double _calculateIlluminationUniformity(img.Image image) {
    // Dividir la imagen en una grilla de 3x3 y calcular el brillo de cada región
    final regionWidth = image.width ~/ 3;
    final regionHeight = image.height ~/ 3;
    final regionBrightnesses = <double>[];
    
    // Usar muestreo dentro de cada región para reducir carga computacional
    const step = 8;
    
    for (int regionY = 0; regionY < 3; regionY++) {
      for (int regionX = 0; regionX < 3; regionX++) {
        final startX = regionX * regionWidth;
        final startY = regionY * regionHeight;
        final endX = math.min(startX + regionWidth, image.width);
        final endY = math.min(startY + regionHeight, image.height);
        
        int totalLuminance = 0;
        int pixelCount = 0;
        
        // Muestrear píxeles dentro de la región
        for (int y = startY; y < endY; y += step) {
          for (int x = startX; x < endX; x += step) {
            final pixel = image.getPixel(x, y);
            totalLuminance += img.getLuminance(pixel).round();
            pixelCount++;
          }
        }
        
        if (pixelCount > 0) {
          regionBrightnesses.add(totalLuminance / pixelCount);
        }
      }
    }
    
    if (regionBrightnesses.isEmpty) return 0;
    
    // Calcular la desviación estándar de los brillos regionales
    final mean = regionBrightnesses.reduce((a, b) => a + b) / regionBrightnesses.length;
    final variance = regionBrightnesses
        .map((brightness) => math.pow(brightness - mean, 2))
        .reduce((a, b) => a + b) / regionBrightnesses.length;
    final standardDeviation = math.sqrt(variance);
    
    // Convertir a un índice de uniformidad (0-1, donde 1 es perfectamente uniforme)
    final uniformityIndex = 1 - (standardDeviation / mean).clamp(0.0, 1.0);
    
    return uniformityIndex;
  }
  
  /// Calcula una puntuación general de calidad (0-100)
  static double _calculateOverallQualityScore(
    double brightness,
    double contrast,
    double glarePercentage,
    double laplacianVariance,
    double uniformity,
  ) {
    double score = 100.0;
    
    // Penalizar por brillo inadecuado
    if (brightness < MIN_BRIGHTNESS) {
      score -= (MIN_BRIGHTNESS - brightness) / MIN_BRIGHTNESS * 30;
    } else if (brightness > MAX_BRIGHTNESS) {
      score -= (brightness - MAX_BRIGHTNESS) / MAX_BRIGHTNESS * 30;
    }
    
    // Penalizar por contraste bajo
    if (contrast < MIN_CONTRAST) {
      score -= (MIN_CONTRAST - contrast) / MIN_CONTRAST * 25;
    }
    
    // Penalizar por glare excesivo
    if (glarePercentage > MAX_GLARE_PERCENTAGE) {
      score -= (glarePercentage - MAX_GLARE_PERCENTAGE) / MAX_GLARE_PERCENTAGE * 20;
    }
    
    // Penalizar por falta de nitidez
    if (laplacianVariance < MIN_LAPLACIAN_VARIANCE) {
      score -= (MIN_LAPLACIAN_VARIANCE - laplacianVariance) / MIN_LAPLACIAN_VARIANCE * 15;
    }
    
    // Penalizar por falta de uniformidad
    score -= (1 - uniformity) * 10;
    
    return math.max(0, score);
  }
  
  /// Genera recomendaciones basadas en los problemas detectados
  static List<String> _getRecommendations(List<String> problems) {
    final recommendations = <String>[];
    
    for (final problem in problems) {
      switch (problem) {
        case 'Imagen muy oscura':
          recommendations.add('Mejore la iluminación o use el flash de la cámara');
          break;
        case 'Imagen sobreexpuesta':
          recommendations.add('Reduzca la iluminación o evite luz directa intensa');
          break;
        case 'Contraste insuficiente':
          recommendations.add('Mejore la iluminación uniforme del documento');
          break;
        case 'Reflejos detectados':
          recommendations.add('Cambie el ángulo de la cámara para evitar reflejos');
          break;
        case 'Imagen desenfocada':
          recommendations.add('Mantenga la cámara estable y enfoque correctamente');
          break;
        case 'Sombras excesivas':
          recommendations.add('Use iluminación más uniforme para reducir sombras');
          break;
        case 'Iluminación desigual':
          recommendations.add('Asegúrese de que el documento esté uniformemente iluminado');
          break;
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('La calidad de la imagen es adecuada para el procesamiento');
    }
    
    return recommendations;
  }
  
  /// Verifica si la imagen tiene calidad suficiente para OCR
  static Future<bool> isImageSuitableForOCR(String imagePath) async {
    final analysis = await analyzeImageQuality(imagePath);
    return !analysis['hasProblems'] as bool;
  }
  
  /// Obtiene un resumen rápido de la calidad de la imagen
  static Future<String> getQualitySummary(String imagePath) async {
    final analysis = await analyzeImageQuality(imagePath);
    
    if (analysis['hasProblems'] as bool) {
      final problems = analysis['problems'] as List<String>;
      return 'Problemas detectados: ${problems.join(", ")}';
    } else {
      final score = analysis['qualityScore'] as double;
      return 'Calidad aceptable (${score.toStringAsFixed(0)}/100)';
    }
  }
}