import 'dart:io';
import 'package:path/path.dart' as path;
import '../../app/core/services/mlkit_text_recognition_service.dart';
import '../../app/core/services/face_detection_service.dart';
import '../../app/core/services/signature_extraction_service.dart';
import '../../app/data/models/credencial_ine_model.dart';

/// Servicio de correcciones para el procesamiento de credenciales
/// Soluciona problemas con CURP incompleto y captura de imágenes
/// 
/// CORRECCIONES IMPLEMENTADAS:
/// - Convertidos métodos privados a públicos para facilitar testing
/// - Corregida integración con MLKitTextRecognitionService
/// - Ajustados patrones de CURP para formato estándar de 18 caracteres
/// - Corregida llamada a SignatureExtractionService con parámetros nombrados
/// - Añadido manejo de valores nullable en extracción de texto OCR
class CredentialProcessingFixes {
  static const String _tag = 'CredentialProcessingFixes';

  /// Mejora la extracción del CURP aplicando múltiples estrategias
  static Future<String> improvedCurpExtraction(String imagePath) async {
    try {
      print('[$_tag] Iniciando extracción mejorada de CURP desde: $imagePath');
      
      // Estrategia 1: OCR estándar
      String curp = await _extractCurpStandard(imagePath);
      if (isValidCurp(curp)) {
        print('[$_tag] CURP extraído con estrategia estándar: $curp');
        return curp;
      }
      
      // Estrategia 2: OCR con preprocesamiento de imagen
      curp = await _extractCurpWithPreprocessing(imagePath);
      if (isValidCurp(curp)) {
        print('[$_tag] CURP extraído con preprocesamiento: $curp');
        return curp;
      }
      
      // Estrategia 3: Búsqueda por patrones específicos
      curp = await _extractCurpByPattern(imagePath);
      if (isValidCurp(curp)) {
        print('[$_tag] CURP extraído por patrones: $curp');
        return curp;
      }
      
      print('[$_tag] No se pudo extraer un CURP válido');
      return '';
    } catch (e) {
      print('[$_tag] Error en extracción mejorada de CURP: $e');
      return '';
    }
  }

  /// Extracción estándar de CURP
  static Future<String> _extractCurpStandard(String imagePath) async {
    try {
      // Usar OCR para extraer texto de la imagen
      final ocrService = MLKitTextRecognitionService();
      final ocrResult = await ocrService.extractTextFromImage(imagePath);
      return findCurpInText(ocrResult ?? '');
    } catch (e) {
      print('[$_tag] Error en extracción estándar: $e');
      return '';
    }
  }

  /// Extracción de CURP con preprocesamiento de imagen
  static Future<String> _extractCurpWithPreprocessing(String imagePath) async {
    try {
      // Aquí se podría implementar preprocesamiento de imagen
      // Por ahora, usamos la misma lógica pero con diferentes parámetros de OCR
      final ocrService = MLKitTextRecognitionService();
        final ocrResult = await ocrService.extractTextFromImage(imagePath);
      return findCurpInText(ocrResult ?? '', useAlternativePattern: true);
    } catch (e) {
      print('[$_tag] Error en extracción con preprocesamiento: $e');
      return '';
    }
  }

  /// Extracción de CURP por patrones específicos
  static Future<String> _extractCurpByPattern(String imagePath) async {
    try {
      final ocrService = MLKitTextRecognitionService();
        final ocrResult = await ocrService.extractTextFromImage(imagePath);
      return findCurpWithFlexiblePattern(ocrResult ?? '');
    } catch (e) {
      print('[$_tag] Error en extracción por patrones: $e');
      return '';
    }
  }

  /// Busca CURP en el texto usando patrones estrictos
  static String findCurpInText(String text, {bool useAlternativePattern = false}) {
    if (text.isEmpty) return '';
    
    // Patrón estricto de CURP: 4 letras + 6 dígitos + 8 caracteres alfanuméricos
    final RegExp curpPattern = useAlternativePattern 
        ? RegExp(r'[A-Z]{4}[0-9]{6}[A-Z0-9]{8}', caseSensitive: false)
        : RegExp(r'\b[A-Z]{4}[0-9]{6}[A-Z0-9]{8}\b', caseSensitive: false);
    
    final match = curpPattern.firstMatch(text.toUpperCase());
    return match?.group(0) ?? '';
  }

  /// Busca CURP con patrones más flexibles
  static String findCurpWithFlexiblePattern(String text) {
    if (text.isEmpty) return '';
    
    // Buscar después de la palabra "CURP"
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      if (line.contains('CURP')) {
        // Buscar en la misma línea
        String curp = extractCurpFromLine(line);
        if (isValidCurp(curp)) return curp;
        
        // Buscar en la siguiente línea
        if (i + 1 < lines.length) {
          curp = extractCurpFromLine(lines[i + 1]);
          if (isValidCurp(curp)) return curp;
        }
      }
    }
    
    return '';
  }

  /// Extrae CURP de una línea específica
  static String extractCurpFromLine(String line) {
    // Remover espacios y caracteres especiales
    final cleanLine = line.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    // Buscar secuencia de 18 caracteres que coincida con patrón CURP
    for (int i = 0; i <= cleanLine.length - 18; i++) {
      final candidate = cleanLine.substring(i, i + 18);
      if (isValidCurpFormat(candidate)) {
        return candidate;
      }
    }
    
    return '';
  }

  /// Valida si un CURP tiene el formato correcto
  static bool isValidCurpFormat(String curp) {
    if (curp.length != 18) return false;
    
    // Verificar patrón: 4 letras + 6 dígitos + 8 alfanuméricos
    final pattern = RegExp(r'^[A-Z]{4}[0-9]{6}[A-Z0-9]{8}$');
    return pattern.hasMatch(curp);
  }

  /// Valida si un CURP es válido y completo
  static bool isValidCurp(String curp) {
    return curp.isNotEmpty && curp.length == 18 && isValidCurpFormat(curp);
  }

  /// Mejora la captura de fotografías con validaciones adicionales
  static Future<String?> improvedPhotoExtraction(String imagePath) async {
    try {
      print('[$_tag] Iniciando extracción mejorada de fotografía desde: $imagePath');
      
      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        print('[$_tag] El archivo de imagen no existe: $imagePath');
        return null;
      }
      
      // Intentar extracción de cara
      final photoPath = await FaceDetectionService.extractFaceFromCredential(imagePath);
      
      if (photoPath != null && photoPath.isNotEmpty) {
        // Verificar que el archivo de foto extraída existe
        final photoFile = File(photoPath);
        if (await photoFile.exists()) {
          print('[$_tag] Fotografía extraída exitosamente: $photoPath');
          return photoPath;
        } else {
          print('[$_tag] El archivo de fotografía extraída no existe: $photoPath');
        }
      }
      
      print('[$_tag] No se pudo extraer la fotografía');
      return null;
    } catch (e) {
      print('[$_tag] Error en extracción mejorada de fotografía: $e');
      return null;
    }
  }

  /// Mejora la captura de firmas con validaciones adicionales
  static Future<String?> improvedSignatureExtraction(String imagePath, String credentialType) async {
    try {
      print('[$_tag] Iniciando extracción mejorada de firma desde: $imagePath');
      
      // Solo procesar firmas para credenciales T3
      if (credentialType != 'T3') {
        print('[$_tag] Extracción de firma solo disponible para credenciales T3');
        return null;
      }
      
      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        print('[$_tag] El archivo de imagen no existe: $imagePath');
        return null;
      }
      
      // Intentar extracción de firma
      final credentialId = DateTime.now().millisecondsSinceEpoch.toString();
      final signaturePath = await SignatureExtractionService.extractSignatureFromT3Credential(
        imagePath: imagePath,
        facePhotoPath: '', // No necesario para esta función
        credentialId: credentialId,
      );
      
      if (signaturePath != null && signaturePath.isNotEmpty) {
        // Verificar que el archivo de firma extraída existe
        final signatureFile = File(signaturePath);
        if (await signatureFile.exists()) {
          print('[$_tag] Firma extraída exitosamente: $signaturePath');
          return signaturePath;
        } else {
          print('[$_tag] El archivo de firma extraída no existe: $signaturePath');
        }
      }
      
      print('[$_tag] No se pudo extraer la firma');
      return null;
    } catch (e) {
      print('[$_tag] Error en extracción mejorada de firma: $e');
      return null;
    }
  }

  /// Sanitiza y valida el CURP extraído
  static String sanitizeCurp(String curp) {
    if (curp.isEmpty) return '';
    
    // Convertir a mayúsculas y remover espacios
    String sanitized = curp.toUpperCase().trim();
    
    // Remover caracteres no válidos
    sanitized = sanitized.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    // Verificar longitud
    if (sanitized.length == 18 && isValidCurpFormat(sanitized)) {
      return sanitized;
    }
    
    return '';
  }

  /// Actualiza el modelo de credencial con las mejoras implementadas
  static Future<CredencialIneModel> updateCredentialWithFixes(
    CredencialIneModel credential,
    String imagePath,
  ) async {
    try {
      print('[$_tag] Aplicando correcciones al modelo de credencial');
      
      // Mejorar extracción de CURP si está incompleto
      String improvedCurp = credential.curp ?? '';
      if (!isValidCurp(improvedCurp)) {
        improvedCurp = await improvedCurpExtraction(imagePath);
        improvedCurp = sanitizeCurp(improvedCurp);
      }
      
      // Mejorar extracción de fotografía si no existe
      String? improvedPhotoPath = credential.photoPath;
      if (improvedPhotoPath == null || improvedPhotoPath.isEmpty) {
        improvedPhotoPath = await improvedPhotoExtraction(imagePath);
      }
      
      // Mejorar extracción de firma si no existe (solo T3)
      String? improvedSignaturePath = credential.signaturePath;
      if (improvedSignaturePath == null || improvedSignaturePath.isEmpty) {
        improvedSignaturePath = await improvedSignatureExtraction(imagePath, credential.tipo ?? '');
      }
      
      // Actualizar modelo con las mejoras
      final updatedCredential = credential.copyWith(
        curp: improvedCurp.isNotEmpty ? improvedCurp : credential.curp,
        photoPath: improvedPhotoPath ?? credential.photoPath,
        signaturePath: improvedSignaturePath ?? credential.signaturePath,
      );
      
      print('[$_tag] Modelo de credencial actualizado con correcciones');
      return updatedCredential;
    } catch (e) {
      print('[$_tag] Error al aplicar correcciones: $e');
      return credential;
    }
  }
}