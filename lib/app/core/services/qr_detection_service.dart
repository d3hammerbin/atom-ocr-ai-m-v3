import 'dart:io';
import 'dart:math' as math;

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'logger_service.dart';

/// Servicio para detectar y extraer códigos QR de credenciales INE T2
/// Implementa detección inteligente usando finder patterns y métodos de respaldo
class QrDetectionService {
  static final LoggerService _logger = LoggerService.instance;
  
  // Constantes para detección de finder patterns
   static const int finderPatternMinSize = 7;
   static const int patternThreshold = 128;
  
  /// Detecta y extrae el código QR usando detección inteligente con múltiples métodos
  /// 
  /// [imagePath] - Ruta de la imagen de la credencial
  /// [credentialId] - ID único de la credencial para nombrar archivos
  /// 
  /// Retorna un Map con:
  /// - 'qrContent': contenido decodificado del QR (String)
  /// - 'qrImagePath': ruta de la imagen recortada del QR (String)
  /// - 'success': si la detección fue exitosa (bool)
  /// - 'error': mensaje de error si falló (String?)
  /// - 'method': método usado para la detección (String)
  static Future<Map<String, dynamic>> detectQrFromT2Credential({
    required String imagePath,
    required String credentialId,
  }) async {
    return await _detectQrWithSmartPositioning(
      imagePath: imagePath,
      credentialId: credentialId,
    );
  }
  
  /// Sistema híbrido de detección con tres niveles de fallback
   static Future<Map<String, dynamic>> _detectQrWithSmartPositioning({
     required String imagePath,
     required String credentialId,
   }) async {
     try {
       _logger.info('QrDetectionService', 'Iniciando detección inteligente de QR para credencial: $credentialId');
       
       // Verificar que el archivo existe
       final imageFile = File(imagePath);
       if (!await imageFile.exists()) {
         throw Exception('El archivo de imagen no existe: $imagePath');
       }
       
       // Cargar y procesar la imagen
       final imageBytes = await imageFile.readAsBytes();
       final originalImage = img.decodeImage(imageBytes);
       
       if (originalImage == null) {
         throw Exception('No se pudo decodificar la imagen');
       }
       
       _logger.info('QrDetectionService', 'Imagen cargada: ${originalImage.width}x${originalImage.height}');
       
       // Método 1: Detección por finder patterns (más preciso)
       _logger.info('QrDetectionService', 'Intentando detección por finder patterns...');
       var result = await _tryFinderPatternDetection(originalImage, credentialId);
       if (result['success']) {
         _logger.info('QrDetectionService', 'QR detectado exitosamente usando finder patterns');
         result['method'] = 'finder_patterns';
         return result;
       }
       
       // Método 2: Detección con Google ML Kit en imagen completa
       _logger.info('QrDetectionService', 'Intentando detección con ML Kit en imagen completa...');
       result = await _tryMLKitFullImageDetection(originalImage, credentialId);
       if (result['success']) {
         _logger.info('QrDetectionService', 'QR detectado exitosamente usando ML Kit completo');
         result['method'] = 'mlkit_full';
         return result;
       }
       
       // Método 3: Región fija optimizada (método actual como respaldo)
       _logger.info('QrDetectionService', 'Usando método de región fija como respaldo...');
       result = await _tryFixedRegionDetection(originalImage, credentialId);
       result['method'] = 'fixed_region';
       return result;
       
     } catch (e) {
       _logger.error('QrDetectionService', 'Error en detección inteligente de QR: $e');
       return {
         'qrContent': '',
         'qrImagePath': '',
         'success': false,
         'error': e.toString(),
         'method': 'error',
       };
     }
   }
   
   /// Método 1: Detección usando finder patterns (1:1:3:1:1)
   static Future<Map<String, dynamic>> _tryFinderPatternDetection(
     img.Image originalImage, 
     String credentialId
   ) async {
     try {
       // Convertir a escala de grises para mejor detección
       final grayImage = img.grayscale(originalImage);
       
       // Buscar finder patterns en la imagen
       final finderPatterns = _findFinderPatterns(grayImage);
       
       if (finderPatterns.length >= 3) {
         _logger.info('QrDetectionService', 'Encontrados ${finderPatterns.length} finder patterns');
         
         // Calcular la región del QR basándose en los finder patterns
         final qrBounds = _calculateQrBoundsFromFinderPatterns(finderPatterns, grayImage);
         
         if (qrBounds != null) {
           // Extraer la región del QR
           final qrRegion = img.copyCrop(
             originalImage,
             x: qrBounds['x']!,
             y: qrBounds['y']!,
             width: qrBounds['width']!,
             height: qrBounds['height']!,
           );
           
           // Guardar la imagen del QR
           final qrImagePath = await _saveQrImage(qrRegion, credentialId);
           
           // Intentar decodificar con ML Kit
           final qrContent = await _decodeQrWithMLKit(qrRegion);
           
           return {
             'qrContent': qrContent,
             'qrImagePath': qrImagePath,
             'success': qrContent.isNotEmpty,
             'error': qrContent.isEmpty ? 'No se pudo decodificar el contenido del QR' : null,
           };
         }
       }
       
       return {
         'qrContent': '',
         'qrImagePath': '',
         'success': false,
         'error': 'No se encontraron suficientes finder patterns',
       };
       
     } catch (e) {
       _logger.error('QrDetectionService', 'Error en detección por finder patterns: $e');
       return {
         'qrContent': '',
         'qrImagePath': '',
         'success': false,
         'error': e.toString(),
       };
     }
    }
    
    /// Buscar finder patterns en la imagen usando la proporción 1:1:3:1:1
    static List<Map<String, int>> _findFinderPatterns(img.Image grayImage) {
      final patterns = <Map<String, int>>[];
      final width = grayImage.width;
      final height = grayImage.height;
      
      // Escanear la imagen buscando patrones 1:1:3:1:1
       for (int y = 0; y < height - finderPatternMinSize; y++) {
         for (int x = 0; x < width - finderPatternMinSize; x++) {
          if (_isFinderPatternAt(grayImage, x, y)) {
            patterns.add({'x': x, 'y': y, 'size': _getFinderPatternSize(grayImage, x, y)});
          }
        }
      }
      
      return _filterValidFinderPatterns(patterns);
    }
    

    
    /// Verificar si hay un finder pattern en la posición dada
    static bool _isFinderPatternAt(img.Image image, int centerX, int centerY) {
      // Verificar patrón horizontal 1:1:3:1:1
      if (!_checkHorizontalPattern(image, centerX, centerY)) return false;
      
      // Verificar patrón vertical 1:1:3:1:1
      if (!_checkVerticalPattern(image, centerX, centerY)) return false;
      
      return true;
    }
    
    /// Verificar patrón horizontal 1:1:3:1:1
    static bool _checkHorizontalPattern(img.Image image, int centerX, int centerY) {
       final width = image.width;
       if (centerX < finderPatternMinSize || centerX >= width - finderPatternMinSize) return false;
      
      final states = <int>[0, 0, 0, 0, 0]; // negro, blanco, negro, blanco, negro
      int stateIndex = 0;
      
      // Escanear desde la izquierda hacia la derecha
       for (int x = centerX - finderPatternMinSize; x < centerX + finderPatternMinSize && x < width; x++) {
         final pixel = image.getPixel(x, centerY);
         final luminance = img.getLuminance(pixel);
         final isBlack = luminance < patternThreshold;
        
        if ((stateIndex % 2 == 0 && isBlack) || (stateIndex % 2 == 1 && !isBlack)) {
          states[stateIndex]++;
        } else {
          if (stateIndex < 4) {
            stateIndex++;
            states[stateIndex] = 1;
          } else {
            return false;
          }
        }
      }
      
      return _checkPatternRatio(states);
    }
    
    /// Verificar patrón vertical 1:1:3:1:1
    static bool _checkVerticalPattern(img.Image image, int centerX, int centerY) {
       final height = image.height;
       if (centerY < finderPatternMinSize || centerY >= height - finderPatternMinSize) return false;
      
      final states = <int>[0, 0, 0, 0, 0]; // negro, blanco, negro, blanco, negro
      int stateIndex = 0;
      
      // Escanear desde arriba hacia abajo
       for (int y = centerY - finderPatternMinSize; y < centerY + finderPatternMinSize && y < height; y++) {
         final pixel = image.getPixel(centerX, y);
         final luminance = img.getLuminance(pixel);
         final isBlack = luminance < patternThreshold;
        
        if ((stateIndex % 2 == 0 && isBlack) || (stateIndex % 2 == 1 && !isBlack)) {
          states[stateIndex]++;
        } else {
          if (stateIndex < 4) {
            stateIndex++;
            states[stateIndex] = 1;
          } else {
            return false;
          }
        }
      }
      
      return _checkPatternRatio(states);
    }
    
    /// Verificar si la proporción coincide con 1:1:3:1:1
    static bool _checkPatternRatio(List<int> states) {
      if (states.any((state) => state == 0)) return false;
      
      final totalSize = states.reduce((a, b) => a + b);
      if (totalSize < 7) return false; // Tamaño mínimo
      
      final moduleSize = totalSize / 7.0;
      final variance = moduleSize / 2.0;
      
      return (states[0] - moduleSize).abs() < variance &&
             (states[1] - moduleSize).abs() < variance &&
             (states[2] - 3 * moduleSize).abs() < variance &&
             (states[3] - moduleSize).abs() < variance &&
             (states[4] - moduleSize).abs() < variance;
    }
    
    /// Obtener el tamaño del finder pattern
    static int _getFinderPatternSize(img.Image image, int centerX, int centerY) {
      int size = 1;
      final width = image.width;
      final height = image.height;
      
      // Expandir hacia afuera hasta encontrar el borde del patrón
      while (centerX - size >= 0 && centerX + size < width && 
             centerY - size >= 0 && centerY + size < height) {
        final topLeft = image.getPixel(centerX - size, centerY - size);
        final topRight = image.getPixel(centerX + size, centerY - size);
        final bottomLeft = image.getPixel(centerX - size, centerY + size);
        final bottomRight = image.getPixel(centerX + size, centerY + size);
        
        if (img.getLuminance(topLeft) > patternThreshold ||
            img.getLuminance(topRight) > patternThreshold ||
            img.getLuminance(bottomLeft) > patternThreshold ||
            img.getLuminance(bottomRight) > patternThreshold) {
          break;
        }
        size++;
      }
      
      return size * 2;
    }
    
    /// Filtrar y validar finder patterns encontrados
    static List<Map<String, int>> _filterValidFinderPatterns(List<Map<String, int>> patterns) {
      if (patterns.length < 3) return patterns;
      
      // Ordenar por tamaño para mantener los más consistentes
      patterns.sort((a, b) => a['size']!.compareTo(b['size']!));
      
      // Filtrar patrones que estén muy cerca entre sí
      final filtered = <Map<String, int>>[];
      for (final pattern in patterns) {
        bool tooClose = false;
        for (final existing in filtered) {
          final dx = pattern['x']! - existing['x']!;
          final dy = pattern['y']! - existing['y']!;
          final distance = math.sqrt(dx * dx + dy * dy);
          
          if (distance < finderPatternMinSize) {
            tooClose = true;
            break;
          }
        }
        
        if (!tooClose) {
          filtered.add(pattern);
        }
      }
      
      return filtered.take(3).toList();
    }
    
    /// Calcular los límites del QR basándose en los finder patterns
    static Map<String, int>? _calculateQrBoundsFromFinderPatterns(
      List<Map<String, int>> patterns, 
      img.Image image
    ) {
      if (patterns.length < 3) return null;
      
      // Encontrar las esquinas del QR
      final topLeft = patterns[0];
      final topRight = patterns[1];
      final bottomLeft = patterns[2];
      
      // Calcular dimensiones aproximadas del QR
      final qrWidth = (topRight['x']! - topLeft['x']!).abs() + topLeft['size']!;
      final qrHeight = (bottomLeft['y']! - topLeft['y']!).abs() + topLeft['size']!;
      
      // Agregar margen para capturar el QR completo
      final margin = (topLeft['size']! * 0.1).round();
      
      final x = math.max(0, topLeft['x']! - margin);
      final y = math.max(0, topLeft['y']! - margin);
      final width = math.min(image.width - x, qrWidth + 2 * margin);
      final height = math.min(image.height - y, qrHeight + 2 * margin);
      
      return {
         'x': x,
         'y': y,
         'width': width,
         'height': height,
       };
     }
     
     /// Método 2: Detección con Google ML Kit en imagen completa
     static Future<Map<String, dynamic>> _tryMLKitFullImageDetection(
       img.Image originalImage, 
       String credentialId
     ) async {
       try {
         _logger.info('QrDetectionService', 'Intentando detección ML Kit en imagen completa');
         
         // Convertir imagen a bytes para ML Kit usando archivo temporal
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_qr_${DateTime.now().millisecondsSinceEpoch}.png');
          final imageBytes = img.encodePng(originalImage);
          await tempFile.writeAsBytes(imageBytes);
          
          final inputImage = InputImage.fromFilePath(tempFile.path);
         
         final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
          final barcodes = await barcodeScanner.processImage(inputImage);
          
          // Limpiar archivo temporal
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          
          if (barcodes.isNotEmpty) {
           final barcode = barcodes.first;
           _logger.info('QrDetectionService', 'QR detectado con ML Kit: ${barcode.displayValue}');
           
           // Extraer región del QR basándose en las coordenadas detectadas
           final boundingBox = barcode.boundingBox;
           final qrRegion = img.copyCrop(
             originalImage,
             x: boundingBox.left.round(),
             y: boundingBox.top.round(),
             width: boundingBox.width.round(),
             height: boundingBox.height.round(),
           );
             
             // Guardar la imagen del QR
             final qrImagePath = await _saveQrImage(qrRegion, credentialId);
             
             await barcodeScanner.close();
              return {
                'qrContent': barcode.displayValue ?? '',
                'qrImagePath': qrImagePath,
                'success': true,
                'error': null,
              };
         }
         
         await barcodeScanner.close();
          return {
            'qrContent': '',
            'qrImagePath': '',
            'success': false,
            'error': 'No se detectaron códigos QR en la imagen completa',
          };
         
       } catch (e) {
           _logger.error('QrDetectionService', 'Error en detección ML Kit completa: $e');
           // Limpiar archivo temporal en caso de error
           try {
             final tempDir = await getTemporaryDirectory();
             final tempFile = File('${tempDir.path}/temp_qr_${DateTime.now().millisecondsSinceEpoch}.png');
             if (await tempFile.exists()) {
               await tempFile.delete();
             }
           } catch (_) {}
           return {
             'qrContent': '',
             'qrImagePath': '',
             'success': false,
             'error': e.toString(),
           };
         }
     }
     
     /// Método 3: Región fija optimizada (método actual como respaldo)
     static Future<Map<String, dynamic>> _tryFixedRegionDetection(
       img.Image originalImage, 
       String credentialId
     ) async {
       try {
         _logger.info('QrDetectionService', 'Usando método de región fija como respaldo');
         
         // Extraer la región superior derecha donde típicamente está el QR en T2
         final qrRegion = _extractQrRegionFromT2(originalImage);
         
         if (qrRegion == null) {
           return {
             'qrContent': '',
             'qrImagePath': '',
             'success': false,
             'error': 'No se pudo extraer la región del QR con método fijo',
           };
         }
         
         // Guardar la imagen del QR
         final qrImagePath = await _saveQrImage(qrRegion, credentialId);
         
         // Intentar decodificar con ML Kit
         final qrContent = await _decodeQrWithMLKit(qrRegion);
         
         return {
           'qrContent': qrContent,
           'qrImagePath': qrImagePath,
           'success': qrContent.isNotEmpty,
           'error': qrContent.isEmpty ? 'No se pudo decodificar el contenido del QR con método fijo' : null,
         };
         
       } catch (e) {
         _logger.error('QrDetectionService', 'Error en método de región fija: $e');
         return {
           'qrContent': '',
           'qrImagePath': '',
           'success': false,
           'error': e.toString(),
         };
       }
     }
     
     /// Guardar imagen del QR extraída
     static Future<String> _saveQrImage(img.Image qrRegion, String credentialId) async {
       try {
         // Crear directorio para imágenes QR si no existe
         final appDir = await getApplicationDocumentsDirectory();
         final qrDir = Directory('${appDir.path}/qr_images');
         if (!await qrDir.exists()) {
           await qrDir.create(recursive: true);
         }
         
         // Generar nombre único para la imagen
         final timestamp = DateTime.now().millisecondsSinceEpoch;
         final qrImagePath = '${qrDir.path}/qr_${credentialId}_$timestamp.png';
         
         // Codificar y guardar la imagen
         final pngBytes = img.encodePng(qrRegion);
         final qrImageFile = File(qrImagePath);
         await qrImageFile.writeAsBytes(pngBytes);
         
         _logger.info('QrDetectionService', 'Imagen QR guardada en: $qrImagePath');
         return qrImagePath;
         
       } catch (e) {
         _logger.error('QrDetectionService', 'Error guardando imagen QR: $e');
         return '';
       }
     }
     
     /// Decodificar QR usando Google ML Kit
      static Future<String> _decodeQrWithMLKit(img.Image qrRegion) async {
        try {
          // Crear archivo temporal para ML Kit
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_qr_decode_${DateTime.now().millisecondsSinceEpoch}.png');
          final pngBytes = img.encodePng(qrRegion);
          await tempFile.writeAsBytes(pngBytes);
          
          try {
            // Crear InputImage desde archivo
            final inputImage = InputImage.fromFilePath(tempFile.path);
            
            // Procesar con ML Kit
            final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
            final barcodes = await barcodeScanner.processImage(inputImage);
            
            // Limpiar recursos
            await barcodeScanner.close();
            
            if (barcodes.isNotEmpty) {
              final qrContent = barcodes.first.displayValue ?? '';
              _logger.info('QrDetectionService', 'Contenido QR decodificado: $qrContent');
              return qrContent;
            } else {
              _logger.warning('QrDetectionService', 'No se detectaron códigos QR en la región extraída');
              return '';
            }
          } finally {
            // Limpiar archivo temporal
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          }
          
        } catch (e) {
          _logger.error('QrDetectionService', 'Error decodificando QR con ML Kit: $e');
          return '';
        }
      }
  
  /// Extrae la región superior derecha de la credencial donde se encuentra el QR
  /// En credenciales T2, el QR típicamente está en el 25% superior derecho
  static img.Image? _extractQrRegionFromT2(img.Image originalImage) {
    try {
      final imageWidth = originalImage.width;
      final imageHeight = originalImage.height;
      
      // Definir la región del QR (esquina superior derecha)
      // QR típicamente ocupa aproximadamente 25% del ancho y 30% del alto
      final qrWidth = (imageWidth * 0.25).round();
      final qrHeight = (imageHeight * 0.30).round();
      
      // Posición: esquina superior derecha ajustada para capturar QR completo
      final qrX = imageWidth - qrWidth - (imageWidth * 0.02).round(); // 2% de margen
      final qrY = (imageHeight * 0.06).round(); // 6% de margen desde arriba para desplazar hacia abajo
      
      _logger.info('QrDetectionService', 'Extrayendo región QR: x=$qrX, y=$qrY, width=$qrWidth, height=$qrHeight');
      
      // Extraer la región
      final qrRegion = img.copyCrop(
        originalImage,
        x: qrX,
        y: qrY,
        width: qrWidth,
        height: qrHeight,
      );
      
      return qrRegion;
      
    } catch (e) {
      _logger.error('QrDetectionService', 'Error extrayendo región QR: $e');
      return null;
    }
  }
  

  

  
  /// Valida si una imagen contiene un QR válido en la región esperada
  static Future<bool> hasValidQrInT2Region(String imagePath) async {
    try {
      final result = await detectQrFromT2Credential(
        imagePath: imagePath,
        credentialId: 'validation_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      return result['success'] == true && result['qrContent'].toString().isNotEmpty;
      
    } catch (e) {
      _logger.error('QrDetectionService', 'Error validando QR: $e');
      return false;
    }
  }
  
  /// Limpia archivos temporales de QR antiguos (más de 24 horas)
  static Future<void> cleanupOldQrFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final qrDir = Directory(path.join(appDir.path, 'qr_codes'));
      
      if (!await qrDir.exists()) return;
      
      final now = DateTime.now();
      final files = await qrDir.list().toList();
      
      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          
          // Eliminar archivos más antiguos de 24 horas
          if (age.inHours > 24) {
            await entity.delete();
            _logger.info('QrDetectionService', 'Archivo QR antiguo eliminado: ${entity.path}');
          }
        }
      }
      
    } catch (e) {
      _logger.error('QrDetectionService', 'Error limpiando archivos QR: $e');
    }
  }
}