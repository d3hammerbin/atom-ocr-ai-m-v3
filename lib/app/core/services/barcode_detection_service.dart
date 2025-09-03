import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'logger_service.dart';

/// Servicio híbrido de detección de códigos de barras para credenciales T2
/// 
/// Implementa una arquitectura de tres niveles:
/// 1. Detección por patrones específicos de códigos de barras
/// 2. Google ML Kit en imagen completa como respaldo
/// 3. Región fija optimizada como último recurso
class BarcodeDetectionService {
  static final LoggerService _logger = LoggerService.instance;
  
  /// Detecta y extrae código de barras de credenciales T2
  /// 
  /// Parámetros:
  /// - [imagePath]: Ruta de la imagen de la credencial
  /// - [credentialType]: Tipo de credencial ('t2')
  /// 
  /// Retorna un Map con:
  /// - 'success': bool - Si se detectó el código de barras
  /// - 'content': String - Contenido del código de barras
  /// - 'imagePath': String - Ruta de la imagen del código de barras extraído
  /// - 'method': String - Método usado para la detección
  /// - 'confidence': double - Nivel de confianza (0.0 - 1.0)
  static Future<Map<String, dynamic>> detectBarcodeFromCredential(
    String imagePath,
    String credentialType,
  ) async {
    try {
      _logger.info('BarcodeDetectionService', 'Iniciando detección de código de barras para credencial $credentialType');
      
      // Cargar imagen
      final imageBytes = await File(imagePath).readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        _logger.error('BarcodeDetectionService', 'No se pudo decodificar la imagen');
        return _createFailureResult('Error al decodificar imagen');
      }
      
      // Nivel 1: Detección por patrones específicos en región superior izquierda
      _logger.info('BarcodeDetectionService', 'Nivel 1: Detección por patrones en región específica');
      final level1Result = await _detectBarcodeByRegion(originalImage, credentialType);
      if (level1Result['success']) {
        _logger.info('BarcodeDetectionService', 'Código de barras detectado en Nivel 1');
        return level1Result;
      }
      
      // Nivel 2: Google ML Kit en imagen completa
      _logger.info('BarcodeDetectionService', 'Nivel 2: Google ML Kit en imagen completa');
      final level2Result = await _detectBarcodeWithMLKit(originalImage);
      if (level2Result['success']) {
        _logger.info('BarcodeDetectionService', 'Código de barras detectado en Nivel 2');
        return level2Result;
      }
      
      // Nivel 3: Región fija optimizada como último recurso
      _logger.info('BarcodeDetectionService', 'Nivel 3: Región fija optimizada');
      final level3Result = await _detectBarcodeFixedRegion(originalImage, credentialType);
      if (level3Result['success']) {
        _logger.info('BarcodeDetectionService', 'Código de barras detectado en Nivel 3');
        return level3Result;
      }
      
      _logger.warning('BarcodeDetectionService', 'No se pudo detectar código de barras en ningún nivel');
      return _createFailureResult('No se detectó código de barras');
      
    } catch (e) {
      _logger.error('BarcodeDetectionService', 'Error en detección de código de barras: $e');
      return _createFailureResult('Error en detección: $e');
    }
  }
  
  /// Nivel 1: Detección por región específica superior izquierda
  static Future<Map<String, dynamic>> _detectBarcodeByRegion(
    img.Image originalImage,
    String credentialType,
  ) async {
    try {
      // Extraer región del código de barras según el tipo de credencial
      img.Image? barcodeRegion;
      
      if (credentialType == 't2') {
        barcodeRegion = _extractBarcodeRegionFromT2(originalImage);
      }
      
      if (barcodeRegion == null) {
        return _createFailureResult('No se pudo extraer región del código de barras');
      }
      
      // Intentar detectar código de barras con ML Kit en la región específica
      final result = await _processBarcodeWithMLKit(barcodeRegion);
      
      if (result['success']) {
        // Guardar imagen del código de barras
        final savedImagePath = await _saveBarcodeImage(barcodeRegion);
        
        return {
          'success': true,
          'content': result['content'],
          'imagePath': savedImagePath,
          'method': 'region_detection',
          'confidence': 0.95,
          'details': {
            'region': 'superior_izquierda',
            'credential_type': credentialType,
            'format': result['format'],
          },
        };
      }
      
      return _createFailureResult('No se detectó código de barras en región específica');
      
    } catch (e) {
      _logger.error('BarcodeDetectionService', 'Error en detección por región: $e');
      return _createFailureResult('Error en detección por región: $e');
    }
  }
  
  /// Nivel 2: Google ML Kit en imagen completa
  static Future<Map<String, dynamic>> _detectBarcodeWithMLKit(
    img.Image originalImage,
  ) async {
    try {
      final result = await _processBarcodeWithMLKit(originalImage);
      
      if (result['success']) {
        // Si se detectó en imagen completa, extraer región aproximada
        final barcodeRegion = _extractBarcodeRegionFromT2(originalImage);
        final savedImagePath = barcodeRegion != null 
            ? await _saveBarcodeImage(barcodeRegion)
            : '';
        
        return {
          'success': true,
          'content': result['content'],
          'imagePath': savedImagePath,
          'method': 'mlkit_full_image',
          'confidence': 0.85,
          'details': {
            'detection_area': 'imagen_completa',
            'format': result['format'],
          },
        };
      }
      
      return _createFailureResult('No se detectó código de barras con ML Kit');
      
    } catch (e) {
      _logger.error('BarcodeDetectionService', 'Error en ML Kit: $e');
      return _createFailureResult('Error en ML Kit: $e');
    }
  }
  
  /// Nivel 3: Región fija optimizada
  static Future<Map<String, dynamic>> _detectBarcodeFixedRegion(
    img.Image originalImage,
    String credentialType,
  ) async {
    try {
      // Usar región fija más amplia como último recurso
      final barcodeRegion = _extractBarcodeRegionFromT2(originalImage, expanded: true);
      
      if (barcodeRegion == null) {
        return _createFailureResult('No se pudo extraer región fija');
      }
      
      final result = await _processBarcodeWithMLKit(barcodeRegion);
      
      if (result['success']) {
        final savedImagePath = await _saveBarcodeImage(barcodeRegion);
        
        return {
          'success': true,
          'content': result['content'],
          'imagePath': savedImagePath,
          'method': 'fixed_region',
          'confidence': 0.75,
          'details': {
            'region': 'fija_expandida',
            'fallback_level': 3,
            'format': result['format'],
          },
        };
      }
      
      return _createFailureResult('No se detectó código de barras en región fija');
      
    } catch (e) {
      _logger.error('BarcodeDetectionService', 'Error en región fija: $e');
      return _createFailureResult('Error en región fija: $e');
    }
  }
  
  /// Extrae la región superior izquierda donde se encuentra el código de barras
  /// En credenciales T2, el código de barras típicamente está en el 30% superior izquierdo
  static img.Image? _extractBarcodeRegionFromT2(img.Image originalImage, {bool expanded = false}) {
    try {
      final imageWidth = originalImage.width;
      final imageHeight = originalImage.height;
      
      // Definir la región del código de barras (esquina superior izquierda)
      final barcodeWidth = expanded 
          ? (imageWidth * 0.40).round()  // Región expandida para fallback
          : (imageWidth * 0.30).round(); // Región normal
      final barcodeHeight = expanded 
          ? (imageHeight * 0.25).round() // Región expandida para fallback
          : (imageHeight * 0.20).round(); // Región normal
      
      // Posición: esquina superior izquierda con margen
      final barcodeX = (imageWidth * 0.02).round(); // 2% de margen desde la izquierda
      final barcodeY = (imageHeight * 0.05).round(); // 5% de margen desde arriba
      
      _logger.info('BarcodeDetectionService', 
          'Extrayendo región código de barras: x=$barcodeX, y=$barcodeY, width=$barcodeWidth, height=$barcodeHeight');
      
      // Extraer la región
      final barcodeRegion = img.copyCrop(
        originalImage,
        x: barcodeX,
        y: barcodeY,
        width: barcodeWidth,
        height: barcodeHeight,
      );
      
      return barcodeRegion;
      
    } catch (e) {
      _logger.error('BarcodeDetectionService', 'Error extrayendo región código de barras: $e');
      return null;
    }
  }
  
  /// Procesa imagen con Google ML Kit para detectar códigos de barras
  static Future<Map<String, dynamic>> _processBarcodeWithMLKit(img.Image image) async {
    BarcodeScanner? barcodeScanner;
    File? tempFile;
    
    try {
      // Crear scanner con formatos específicos para credenciales mexicanas
      barcodeScanner = BarcodeScanner(
        formats: [
          BarcodeFormat.code128,  // Común en documentos oficiales
          BarcodeFormat.code39,   // También usado en documentos
          BarcodeFormat.ean13,    // Estándar internacional
          BarcodeFormat.ean8,     // Variante más corta
          BarcodeFormat.codabar,  // Usado en algunos documentos
          BarcodeFormat.itf,      // Interleaved 2 of 5
        ],
      );
      
      // Guardar imagen temporalmente como archivo PNG
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      tempFile = File(path.join(tempDir.path, 'barcode_temp_$timestamp.png'));
      
      final pngBytes = img.encodePng(image);
      await tempFile.writeAsBytes(pngBytes);
      
      // Crear InputImage desde archivo
      final inputImage = InputImage.fromFilePath(tempFile.path);
      
      // Procesar con ML Kit
      final barcodes = await barcodeScanner.processImage(inputImage);
      
      if (barcodes.isNotEmpty) {
        final barcode = barcodes.first;
        final content = barcode.displayValue ?? barcode.rawValue ?? '';
        
        if (content.isNotEmpty) {
          _logger.info('BarcodeDetectionService', 
              'Código de barras detectado: ${content.substring(0, content.length.clamp(0, 20))}...');
          
          return {
            'success': true,
            'content': content,
            'format': barcode.format.name,
            'corners': barcode.cornerPoints,
          };
        }
      }
      
      return {'success': false, 'content': ''};
      
    } catch (e) {
      _logger.error('BarcodeDetectionService', 'Error procesando con ML Kit: $e');
      return {'success': false, 'content': '', 'error': e.toString()};
    } finally {
      // Limpiar recursos
      await barcodeScanner?.close();
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          _logger.warning('BarcodeDetectionService', 'No se pudo eliminar archivo temporal: $e');
        }
      }
    }
  }
  
  /// Guarda la imagen del código de barras extraído
  static Future<String> _saveBarcodeImage(img.Image barcodeImage) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final barcodeDir = Directory(path.join(appDir.path, 'barcodes'));
      
      if (!await barcodeDir.exists()) {
        await barcodeDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'barcode_$timestamp.png';
      final filePath = path.join(barcodeDir.path, fileName);
      
      final pngBytes = img.encodePng(barcodeImage);
      await File(filePath).writeAsBytes(pngBytes);
      
      _logger.info('BarcodeDetectionService', 'Imagen de código de barras guardada: $filePath');
      
      // Limpiar archivos antiguos
      await cleanupOldBarcodeFiles();
      
      return filePath;
      
    } catch (e) {
      _logger.error('BarcodeDetectionService', 'Error guardando imagen de código de barras: $e');
      return '';
    }
  }
  
  /// Limpia archivos antiguos de códigos de barras (más de 24 horas)
  static Future<void> cleanupOldBarcodeFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final barcodeDir = Directory(path.join(appDir.path, 'barcodes'));
      
      if (!await barcodeDir.exists()) return;
      
      final now = DateTime.now();
      final files = await barcodeDir.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.contains('barcode_')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          
          if (age.inHours > 24) {
            await file.delete();
            _logger.info('BarcodeDetectionService', 'Archivo antiguo eliminado: ${file.path}');
          }
        }
      }
    } catch (e) {
      _logger.warning('BarcodeDetectionService', 'Error limpiando archivos antiguos: $e');
    }
  }
  
  /// Crea un resultado de fallo estandarizado
  static Map<String, dynamic> _createFailureResult(String reason) {
    return {
      'success': false,
      'content': '',
      'imagePath': '',
      'method': 'none',
      'confidence': 0.0,
      'error': reason,
    };
  }
}