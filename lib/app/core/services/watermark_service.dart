import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'logger_service.dart';
import 'app_config_service.dart';

/// Servicio para agregar marcas de agua a imágenes procesadas
class WatermarkService {
  /// Agrega una marca de agua transparente a una imagen si está habilitada en la configuración
  /// 
  /// [imagePath] - Ruta de la imagen a la que se agregará la marca de agua
  /// [overrideOpacity] - Opacidad personalizada (opcional, usa la configuración por defecto)
  /// [overrideText] - Texto personalizado (opcional, usa la configuración por defecto)
  /// 
  /// Retorna true si la marca de agua se agregó exitosamente o si está deshabilitada
  static Future<bool> addWatermarkIfEnabled({
    required String imagePath,
    double? overrideOpacity,
    String? overrideText,
  }) async {
    try {
      Log.d('WatermarkService', 'Iniciando proceso de watermark para: $imagePath');
      
      // Verificar si las marcas de agua están habilitadas
      final isEnabled = AppConfigService.isDemoEnabled ?? false;
      Log.d('WatermarkService', 'Watermark habilitado: $isEnabled');
      
      if (!isEnabled) {
        Log.d('WatermarkService', 'Marcas de agua deshabilitadas en configuración');
        return true; // No es un error, simplemente está deshabilitado
      }

      // Verificar que el archivo existe
      final file = File(imagePath);
      final fileExists = await file.exists();
      Log.d('WatermarkService', 'Archivo existe: $fileExists para $imagePath');
      
      if (!fileExists) {
        Log.w('WatermarkService', 'Archivo de imagen no encontrado: $imagePath');
        return false;
      }

      // Verificar tamaño del archivo
      final fileSize = await file.length();
      Log.d('WatermarkService', 'Tamaño del archivo: $fileSize bytes');

      // Cargar la imagen
      Log.d('WatermarkService', 'Cargando imagen desde: $imagePath');
      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        Log.w('WatermarkService', 'No se pudo decodificar la imagen: $imagePath');
        return false;
      }
      
      Log.d('WatermarkService', 'Imagen decodificada: ${image.width}x${image.height}');

      // Obtener configuración
      final text = overrideText ?? AppConfigService.watermarkText ?? 'DEMO';
      final opacity = overrideOpacity ?? AppConfigService.watermarkOpacity ?? 0.3;
      final color = AppConfigService.watermarkColor ?? '#FF0000';
      
      Log.d('WatermarkService', 'Configuración: texto="$text", opacidad=$opacity, color=$color');
      
      // Calcular tamaño de fuente automáticamente
      final fontSize = _calculateFontSize(image.width, image.height);
      Log.d('WatermarkService', 'Tamaño de fuente calculado: $fontSize');
      
      // Crear la marca de agua
      Log.d('WatermarkService', 'Creando watermark...');
      final watermarkedImage = _createWatermark(
        image, 
        text, 
        opacity, 
        fontSize,
        color,
      );

      // Guardar la imagen con marca de agua
      Log.d('WatermarkService', 'Guardando imagen con watermark...');
      final outputBytes = _encodeImage(watermarkedImage, imagePath);
      await file.writeAsBytes(outputBytes);
      
      Log.i('WatermarkService', 'Marca de agua "$text" agregada exitosamente: $imagePath');
      return true;
      
    } catch (e, stackTrace) {
      Log.e('WatermarkService', 'Error al agregar marca de agua a $imagePath: $e');
      Log.e('WatermarkService', 'Stack trace: $stackTrace');
      return false;
    }
  }

  /// Agrega marcas de agua a múltiples imágenes
  static Future<Map<String, bool>> addWatermarkToMultipleImages({
    required List<String> imagePaths,
    double? overrideOpacity,
    String? overrideText,
  }) async {
    final results = <String, bool>{};
    
    Log.i('WatermarkService', 'Iniciando aplicación de watermark a ${imagePaths.length} imágenes');
    Log.d('WatermarkService', 'Rutas de imágenes: ${imagePaths.join(", ")}');
    
    // Si las marcas de agua están deshabilitadas, retornar éxito para todas
    if (!(AppConfigService.isDemoEnabled ?? false)) {
      for (final imagePath in imagePaths) {
        if (imagePath.isNotEmpty) {
          results[imagePath] = true;
        }
      }
      Log.d('WatermarkService', 'Marcas de agua deshabilitadas - omitiendo ${imagePaths.length} imágenes');
      return results;
    }
    
    int processedCount = 0;
    int successCount = 0;
    
    for (final imagePath in imagePaths) {
      if (imagePath.isNotEmpty) {
        processedCount++;
        Log.d('WatermarkService', 'Procesando imagen $processedCount/${imagePaths.length}: $imagePath');
        
        final success = await addWatermarkIfEnabled(
          imagePath: imagePath,
          overrideOpacity: overrideOpacity,
          overrideText: overrideText,
        );
        
        results[imagePath] = success;
        if (success) {
          successCount++;
          Log.i('WatermarkService', 'Watermark aplicado exitosamente a: $imagePath');
        } else {
          Log.w('WatermarkService', 'Falló aplicar watermark a: $imagePath');
        }
      } else {
        Log.w('WatermarkService', 'Ruta de imagen vacía encontrada en la lista');
      }
    }
    
    Log.i('WatermarkService', 'Proceso completado: $successCount/$processedCount imágenes procesadas exitosamente');
    return results;
  }

  /// Calcula el tamaño de fuente apropiado basado en las dimensiones de la imagen
  /// El watermark debe cubrir aproximadamente el 60% del tamaño de la imagen
  static int _calculateFontSize(int width, int height) {
    // Calcular el tamaño para que el watermark cubra el 60% de la imagen
    // Usar la dimensión menor para mantener proporciones
    final minDimension = width < height ? width : height;
    final targetSize = (minDimension * 0.6).round();
    
    // El tamaño de fuente debe ser proporcional al área objetivo
    final fontSize = (targetSize * 0.15).round();
    
    // Limitar entre valores mínimos y máximos razonables
    return fontSize.clamp(30, 200);
  }

  /// Crea la marca de agua sobre la imagen
  /// El watermark cubrirá aproximadamente el 60% del área de la imagen
  static img.Image _createWatermark(
    img.Image image, 
    String text, 
    double opacity, 
    int fontSize,
    String colorName,
  ) {
    // Crear una copia de la imagen original
    final watermarkedImage = img.Image.from(image);
    
    // Crear color con transparencia
    final alpha = (255 * opacity).round();
    final textColor = _getColorFromName(colorName, alpha);
    final shadowColor = img.ColorRgba8(0, 0, 0, (alpha * 0.3).round()); // Sombra más sutil
    
    // Calcular área objetivo (60% de la imagen)
    final targetWidth = (image.width * 0.6).round();
    final targetHeight = (image.height * 0.6).round();
    
    // Calcular cuántas repeticiones del texto necesitamos
    final charWidth = fontSize * 0.6; // Aproximación del ancho por carácter
    final charsPerLine = (targetWidth / charWidth).floor();
    final linesNeeded = (targetHeight / (fontSize * 1.2)).floor();
    
    // Crear patrón de texto repetido
    final repeatedText = _createRepeatedText(text, charsPerLine);
    
    // Calcular posición inicial para centrar el patrón
    final startX = (image.width - targetWidth) ~/ 2;
    final startY = (image.height - targetHeight) ~/ 2;
    
    // Dibujar múltiples líneas de texto para cubrir el área objetivo
    for (int line = 0; line < linesNeeded; line++) {
      final y = startY + (line * (fontSize * 1.2)).round();
      
      // Agregar sombra
      img.drawString(
        watermarkedImage,
        repeatedText,
        font: img.arial48,
        x: startX + 2,
        y: y + 2,
        color: shadowColor,
      );
      
      // Agregar texto principal
      img.drawString(
        watermarkedImage,
        repeatedText,
        font: img.arial48,
        x: startX,
        y: y,
        color: textColor,
      );
    }
    
    return watermarkedImage;
  }
  
  /// Crea un texto repetido para llenar una línea
  static String _createRepeatedText(String text, int targetChars) {
    if (text.isEmpty) return '';
    
    final buffer = StringBuffer();
    while (buffer.length < targetChars) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(text);
    }
    
    final result = buffer.toString();
    return result.length > targetChars ? result.substring(0, targetChars) : result;
  }

  /// Convierte un nombre de color a un objeto Color
  static img.Color _getColorFromName(String colorName, int alpha) {
    switch (colorName.toLowerCase()) {
      case 'white':
        return img.ColorRgba8(255, 255, 255, alpha);
      case 'black':
        return img.ColorRgba8(0, 0, 0, alpha);
      case 'red':
        return img.ColorRgba8(255, 0, 0, alpha);
      case 'green':
        return img.ColorRgba8(0, 255, 0, alpha);
      case 'blue':
        return img.ColorRgba8(0, 0, 255, alpha);
      case 'yellow':
        return img.ColorRgba8(255, 255, 0, alpha);
      case 'cyan':
        return img.ColorRgba8(0, 255, 255, alpha);
      case 'magenta':
        return img.ColorRgba8(255, 0, 255, alpha);
      case 'gray':
      case 'grey':
        return img.ColorRgba8(128, 128, 128, alpha);
      default:
        return img.ColorRgba8(255, 255, 255, alpha); // Blanco por defecto
    }
  }

  /// Codifica la imagen en el formato apropiado basado en la extensión del archivo
  static Uint8List _encodeImage(img.Image image, String originalPath) {
    final extension = originalPath.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'png':
        return Uint8List.fromList(img.encodePng(image));
      case 'jpg':
      case 'jpeg':
        return Uint8List.fromList(img.encodeJpg(image, quality: 95));
      default:
        // Por defecto usar PNG para preservar transparencia
        return Uint8List.fromList(img.encodePng(image));
    }
  }

  /// Verifica si las marcas de agua están habilitadas
  static bool get isEnabled => AppConfigService.isDemoEnabled ?? false;

  /// Obtiene la configuración actual de marcas de agua
  static Map<String, dynamic> get currentConfig => {
    'enabled': AppConfigService.isDemoEnabled ?? false,
    'text': AppConfigService.watermarkText ?? 'DEMO',
    'opacity': AppConfigService.watermarkOpacity ?? 0.3,
    'color': AppConfigService.watermarkColor ?? '#FF0000',
  };
}