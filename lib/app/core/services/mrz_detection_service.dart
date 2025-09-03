import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'logger_service.dart';

/// Servicio híbrido de detección de códigos MRZ para credenciales T2
/// 
/// Implementa una arquitectura de tres niveles:
/// 1. Detección por patrones específicos de MRZ en región inferior
/// 2. Google ML Kit Text Recognition en imagen completa como respaldo
/// 3. Región fija optimizada como último recurso
class MrzDetectionService {
  static final LoggerService _logger = LoggerService.instance;

  /// Detecta y extrae código MRZ de credenciales T2
  /// 
  /// Parámetros:
  /// - [imagePath]: Ruta de la imagen de la credencial
  /// - [credentialType]: Tipo de credencial ('t2')
  /// 
  /// Retorna un Map con:
  /// - 'success': bool - Si se detectó el código MRZ
  /// - 'content': String - Contenido completo del MRZ (3 líneas)
  /// - 'imagePath': String - Ruta de la imagen del MRZ extraído
  /// - 'method': String - Método usado para la detección
  /// - 'confidence': double - Nivel de confianza (0.0 - 1.0)
  /// - 'parsedData': Map - Datos parseados del MRZ
  static Future<Map<String, dynamic>> detectMrzFromCredential(
    String imagePath,
    String credentialType,
  ) async {
    try {
      _logger.info('MrzDetectionService', 'Iniciando detección de código MRZ para credencial $credentialType');
      
      // Cargar imagen
      final imageBytes = await File(imagePath).readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        _logger.error('MrzDetectionService', 'No se pudo decodificar la imagen');
        return _createFailureResult('Error al decodificar imagen');
      }
      
      // Nivel 1: Detección por patrones específicos en región inferior
      _logger.info('MrzDetectionService', 'Nivel 1: Detección por patrones en región inferior');
      final level1Result = await _detectMrzByRegion(originalImage, credentialType);
      if (level1Result['success']) {
        _logger.info('MrzDetectionService', 'MRZ detectado exitosamente en Nivel 1');
        return level1Result;
      }
      
      // Nivel 2: Google ML Kit Text Recognition en imagen completa
      _logger.info('MrzDetectionService', 'Nivel 2: Detección con ML Kit en imagen completa');
      final level2Result = await _detectMrzWithMLKit(originalImage);
      if (level2Result['success']) {
        _logger.info('MrzDetectionService', 'MRZ detectado exitosamente en Nivel 2');
        return level2Result;
      }
      
      // Nivel 3: Región fija optimizada como último recurso
      _logger.info('MrzDetectionService', 'Nivel 3: Detección en región fija optimizada');
      final level3Result = await _detectMrzFixedRegion(originalImage);
      if (level3Result['success']) {
        _logger.info('MrzDetectionService', 'MRZ detectado exitosamente en Nivel 3');
        return level3Result;
      }
      
      _logger.warning('MrzDetectionService', 'No se pudo detectar MRZ en ningún nivel');
      return _createFailureResult('No se detectó código MRZ');
      
    } catch (e) {
      _logger.error('MrzDetectionService', 'Error durante detección de MRZ: $e');
      return _createFailureResult('Error durante detección: $e');
    }
  }

  /// Nivel 1: Detección por patrones específicos en región inferior
  static Future<Map<String, dynamic>> _detectMrzByRegion(
    img.Image originalImage, 
    String credentialType
  ) async {
    try {
      // Definir región inferior para MRZ (aproximadamente 20% inferior de la imagen)
      final regionHeight = (originalImage.height * 0.2).round();
      final regionY = originalImage.height - regionHeight;
      
      // Extraer región inferior
      final mrzRegion = img.copyCrop(
        originalImage,
        x: 0,
        y: regionY,
        width: originalImage.width,
        height: regionHeight,
      );
      
      // Mejorar contraste y nitidez para OCR
      final enhancedRegion = _enhanceImageForMrz(mrzRegion);
      
      // Procesar con ML Kit Text Recognition
      final textResult = await _processImageWithMLKitText(enhancedRegion);
      
      if (textResult['success']) {
        final extractedText = textResult['text'] as String;
        final mrzData = _extractMrzFromText(extractedText);
        
        if (mrzData['isValid']) {
          // Guardar imagen del MRZ extraído
          final mrzImagePath = await _saveMrzImage(enhancedRegion);
          
          return {
            'success': true,
            'content': mrzData['content'],
            'imagePath': mrzImagePath,
            'method': 'region_pattern',
            'confidence': 0.9,
            'parsedData': mrzData['parsedData'],
          };
        }
      }
      
      return _createFailureResult('No se encontró MRZ válido en región específica');
      
    } catch (e) {
      _logger.error('MrzDetectionService', 'Error en detección por región: $e');
      return _createFailureResult('Error en detección por región: $e');
    }
  }

  /// Nivel 2: Detección con Google ML Kit Text Recognition en imagen completa
  static Future<Map<String, dynamic>> _detectMrzWithMLKit(img.Image image) async {
    try {
      // Procesar imagen completa con ML Kit Text Recognition
      final textResult = await _processImageWithMLKitText(image);
      
      if (textResult['success']) {
        final extractedText = textResult['text'] as String;
        final mrzData = _extractMrzFromText(extractedText);
        
        if (mrzData['isValid']) {
          // Intentar localizar región MRZ en imagen completa
          final mrzRegion = await _locateMrzRegionInFullImage(image, extractedText);
          final mrzImagePath = await _saveMrzImage(mrzRegion ?? image);
          
          return {
            'success': true,
            'content': mrzData['content'],
            'imagePath': mrzImagePath,
            'method': 'mlkit_full',
            'confidence': 0.8,
            'parsedData': mrzData['parsedData'],
          };
        }
      }
      
      return _createFailureResult('No se encontró MRZ válido con ML Kit');
      
    } catch (e) {
      _logger.error('MrzDetectionService', 'Error en detección ML Kit: $e');
      return _createFailureResult('Error en detección ML Kit: $e');
    }
  }

  /// Nivel 3: Región fija optimizada como último recurso
  static Future<Map<String, dynamic>> _detectMrzFixedRegion(img.Image image) async {
    try {
      // Región fija en la parte inferior (últimos 15% de la imagen)
      final regionHeight = (image.height * 0.15).round();
      final regionY = image.height - regionHeight;
      
      final fixedRegion = img.copyCrop(
        image,
        x: 0,
        y: regionY,
        width: image.width,
        height: regionHeight,
      );
      
      // Aplicar múltiples mejoras de imagen
      final enhancedRegion = _enhanceImageForMrz(fixedRegion);
      
      // Procesar con ML Kit
      final textResult = await _processImageWithMLKitText(enhancedRegion);
      
      if (textResult['success']) {
        final extractedText = textResult['text'] as String;
        final mrzData = _extractMrzFromText(extractedText);
        
        if (mrzData['isValid']) {
          final mrzImagePath = await _saveMrzImage(enhancedRegion);
          
          return {
            'success': true,
            'content': mrzData['content'],
            'imagePath': mrzImagePath,
            'method': 'fixed_region',
            'confidence': 0.7,
            'parsedData': mrzData['parsedData'],
          };
        }
      }
      
      return _createFailureResult('No se encontró MRZ en región fija');
      
    } catch (e) {
      _logger.error('MrzDetectionService', 'Error en región fija: $e');
      return _createFailureResult('Error en región fija: $e');
    }
  }

  /// Procesa imagen con Google ML Kit Text Recognition
  static Future<Map<String, dynamic>> _processImageWithMLKitText(img.Image image) async {
    TextRecognizer? textRecognizer;
    File? tempFile;
    
    try {
      // Crear reconocedor de texto con script latino
      textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      // Guardar imagen temporalmente como archivo PNG
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      tempFile = File(path.join(tempDir.path, 'mrz_temp_$timestamp.png'));
      
      final pngBytes = img.encodePng(image);
      await tempFile.writeAsBytes(pngBytes);
      
      // Crear InputImage desde archivo
      final inputImage = InputImage.fromFilePath(tempFile.path);
      
      // Procesar con ML Kit
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isNotEmpty) {
        return {
          'success': true,
          'text': recognizedText.text,
          'blocks': recognizedText.blocks,
        };
      }
      
      return {'success': false, 'text': '', 'blocks': []};
      
    } catch (e) {
      _logger.error('MrzDetectionService', 'Error en ML Kit Text Recognition: $e');
      return {'success': false, 'text': '', 'blocks': []};
    } finally {
      // Limpiar recursos
      if (textRecognizer != null) {
        await textRecognizer.close();
      }
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Extrae y valida datos MRZ del texto reconocido
  static Map<String, dynamic> _extractMrzFromText(String text) {
    try {
      final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      
      // Buscar secuencia de 3 líneas consecutivas que cumplan el patrón MRZ
      for (int i = 0; i <= lines.length - 3; i++) {
        final line1 = _normalizeMrzLine(lines[i]);
        final line2 = _normalizeMrzLine(lines[i + 1]);
        final line3 = _normalizeMrzLine(lines[i + 2]);
        
        // Validar que cada línea tenga exactamente 30 caracteres
        if (line1.length == 30 && line2.length == 30 && line3.length == 30) {
          // Validar patrones específicos del MRZ Tipo 1 (tarjetas ID)
          if (_isValidMrzPattern(line1, line2, line3)) {
            final mrzContent = '$line1\n$line2\n$line3';
            final parsedData = _parseMrzData(line1, line2, line3);
            
            return {
              'isValid': true,
              'content': mrzContent,
              'parsedData': parsedData,
              'lines': [line1, line2, line3],
            };
          }
        }
      }
      
      return {'isValid': false, 'content': '', 'parsedData': {}, 'lines': []};
      
    } catch (e) {
      _logger.error('MrzDetectionService', 'Error al extraer MRZ del texto: $e');
      return {'isValid': false, 'content': '', 'parsedData': {}, 'lines': []};
    }
  }

  /// Normaliza una línea MRZ preservando números, letras y '<'
  static String _normalizeMrzLine(String line) {
    // Remover espacios y caracteres no válidos, preservar solo números, letras y '<'
    String normalized = line.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9<]'), '');
    
    // Aplicar normalización específica para OCR común en MRZ
    // IMPORTANTE: Ser cuidadoso con la normalización ya que pueden coexistir O/0 e I/1
    normalized = normalized
        .replaceAll('|', 'I')  // Barra vertical -> I
        .replaceAll('l', 'I')  // L minúscula -> I
        .replaceAll('§', 'S')  // Símbolo de sección -> S
        .replaceAll('€', 'E')  // Euro -> E
        .replaceAll('¢', 'C'); // Centavo -> C
    
    return normalized;
  }

  /// Valida que las líneas cumplan con el patrón MRZ Tipo 1
  static bool _isValidMrzPattern(String line1, String line2, String line3) {
    try {
      // Línea 1: Debe comenzar con código de documento (I, A, C, etc.)
      if (!RegExp(r'^[IACPV]').hasMatch(line1)) return false;
      
      // Línea 1: Debe contener 'MEX' (nacionalidad mexicana)
      if (!line1.contains('MEX')) return false;
      
      // Línea 2: Debe contener fecha de nacimiento (formato YYMMDD)
      if (!RegExp(r'\d{6}').hasMatch(line2)) return false;
      
      // Línea 2: Debe contener 'M' o 'F' para sexo
      if (!RegExp(r'[MF]').hasMatch(line2)) return false;
      
      // Línea 3: Debe contener patrones típicos de nombres
      if (!RegExp(r'[A-Z<]+').hasMatch(line3)) return false;
      
      // Validar que contenga caracteres de relleno '<' típicos del MRZ
      final totalFillChars = (line1.split('<').length - 1) + 
                            (line2.split('<').length - 1) + 
                            (line3.split('<').length - 1);
      
      return totalFillChars >= 3; // Debe tener al menos algunos caracteres de relleno
      
    } catch (e) {
      return false;
    }
  }

  /// Parsea los datos del MRZ según estándares OACI
  static Map<String, dynamic> _parseMrzData(String line1, String line2, String line3) {
    try {
      final parsedData = <String, dynamic>{};
      
      // Línea 1: Tipo de documento, código de país emisor, número de documento
      parsedData['documentType'] = line1.substring(0, 1);
      parsedData['issuingCountry'] = line1.substring(2, 5);
      parsedData['documentNumber'] = line1.substring(5, 14).replaceAll('<', '');
      parsedData['documentCheckDigit'] = line1.substring(14, 15);
      
      // Línea 2: Fecha de nacimiento, sexo, fecha de expiración
      parsedData['birthDate'] = _formatMrzDate(line2.substring(0, 6));
      parsedData['birthDateCheckDigit'] = line2.substring(6, 7);
      parsedData['sex'] = line2.substring(7, 8);
      parsedData['expiryDate'] = _formatMrzDate(line2.substring(8, 14));
      parsedData['expiryDateCheckDigit'] = line2.substring(14, 15);
      parsedData['nationality'] = line2.substring(15, 18);
      
      // Línea 3: Nombres y apellidos
      final namesLine = line3.replaceAll('<', ' ').trim();
      final nameParts = namesLine.split(RegExp(r'\s+'));
      
      if (nameParts.isNotEmpty) {
        parsedData['surname'] = nameParts[0];
        if (nameParts.length > 1) {
          parsedData['givenNames'] = nameParts.sublist(1).join(' ');
        }
      }
      
      return parsedData;
      
    } catch (e) {
      _logger.error('MrzDetectionService', 'Error al parsear datos MRZ: $e');
      return {};
    }
  }

  /// Formatea fecha MRZ (YYMMDD) a formato legible
  static String _formatMrzDate(String mrzDate) {
    if (mrzDate.length != 6) return mrzDate;
    
    try {
      final year = int.parse(mrzDate.substring(0, 2));
      final month = mrzDate.substring(2, 4);
      final day = mrzDate.substring(4, 6);
      
      // Determinar siglo (asumiendo que años 00-30 son 2000-2030, 31-99 son 1931-1999)
      final fullYear = year <= 30 ? 2000 + year : 1900 + year;
      
      return '$day/$month/$fullYear';
    } catch (e) {
      return mrzDate;
    }
  }

  /// Mejora la imagen para optimizar el reconocimiento MRZ
  static img.Image _enhanceImageForMrz(img.Image image) {
    // Convertir a escala de grises
    img.Image enhanced = img.grayscale(image);
    
    // Aumentar contraste para mejorar legibilidad del texto MRZ
    enhanced = img.contrast(enhanced, contrast: 1.3);
    
    // Normalizar la imagen para mejorar uniformidad
    enhanced = img.normalize(enhanced, min: 0, max: 255);
    
    return enhanced;
  }

  /// Intenta localizar la región MRZ en la imagen completa
  static Future<img.Image?> _locateMrzRegionInFullImage(img.Image image, String text) async {
    try {
      // Por ahora, retornar la región inferior como aproximación
      final regionHeight = (image.height * 0.2).round();
      final regionY = image.height - regionHeight;
      
      return img.copyCrop(
        image,
        x: 0,
        y: regionY,
        width: image.width,
        height: regionHeight,
      );
    } catch (e) {
      return null;
    }
  }

  /// Guarda la imagen del MRZ extraído
  static Future<String> _saveMrzImage(img.Image mrzImage) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'mrz_extracted_$timestamp.png';
      final filePath = path.join(documentsDir.path, fileName);
      
      final pngBytes = img.encodePng(mrzImage);
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      
      _logger.info('MrzDetectionService', 'Imagen MRZ guardada en: $filePath');
      return filePath;
      
    } catch (e) {
      _logger.error('MrzDetectionService', 'Error al guardar imagen MRZ: $e');
      return '';
    }
  }

  /// Crea un resultado de fallo
  static Map<String, dynamic> _createFailureResult(String message) {
    return {
      'success': false,
      'content': '',
      'imagePath': '',
      'method': 'none',
      'confidence': 0.0,
      'parsedData': {},
      'error': message,
    };
  }
}