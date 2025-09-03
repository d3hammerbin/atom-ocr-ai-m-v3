import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/credencial_ine_model.dart';
import '../models/processing_result.dart';

/// Servicio principal para procesamiento de credenciales INE
/// Implementa la lógica de extracción de datos, OCR, detección de códigos y validaciones
class IneProcessorService {
  static const MethodChannel _channel = MethodChannel('ine_processor_module');
  
  // Configuración de reconocimiento de texto
  static final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  
  // Configuración de detección de códigos de barras
  static final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
  );
  
  // Configuración de detección facial
  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  
  /// Palabras clave que indican que es una credencial INE
  static const List<String> _ineKeywords = [
    'INSTITUTO NACIONAL ELECTORAL',
    'CREDENCIAL PARA VOTAR',
    'INE',
    'CLAVE DE ELECTOR',
    'CURP',
  ];
  
  /// Etiquetas específicas para credenciales T2
  static const List<String> _tipo2Labels = ['ESTADO', 'MUNICIPIO', 'LOCALIDAD'];
  
  /// Configuración de tipos de credenciales
  static const Map<String, Map<String, dynamic>> _credentialTypeConfig = {
    'Tipo 2': {
      'code': 't2',
      'process': true,
      'description': 'Credenciales con ESTADO/MUNICIPIO/LOCALIDAD',
      'requiredFields': ['NOMBRE', 'CLAVE DE ELECTOR', 'CURP', 'SECCION', 'VIGENCIA'],
    },
    'Tipo 3': {
      'code': 't3',
      'process': true,
      'description': 'Credenciales más nuevas sin campos específicos',
      'requiredFields': ['NOMBRE', 'CLAVE DE ELECTOR', 'CURP', 'SECCION', 'VIGENCIA'],
    },
  };
  
  /// Inicializa el servicio
  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
    } catch (e) {
      throw Exception('Error inicializando servicio INE: $e');
    }
  }
  
  /// Procesa una imagen de credencial INE
  static Future<ProcessingResult> processCredentialImage(
    String imagePath, {
    ProcessingOptions? options,
  }) async {
    try {
      final processingOptions = options ?? const ProcessingOptions();
      
      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        return ProcessingResult.error(
          message: 'El archivo de imagen no existe: $imagePath',
          errorCode: 'FILE_NOT_FOUND',
        );
      }
      
      // Extraer texto usando OCR
      final extractedText = await _extractTextFromImage(imagePath);
      if (extractedText.isEmpty) {
        return ProcessingResult.error(
          message: 'No se pudo extraer texto de la imagen',
          errorCode: 'OCR_FAILED',
        );
      }
      
      // Verificar si es una credencial INE
      if (!_isIneCredential(extractedText)) {
        return ProcessingResult.error(
          message: 'La imagen no parece ser una credencial INE válida',
          errorCode: 'NOT_INE_CREDENTIAL',
        );
      }
      
      // Detectar lado de la credencial
      final sideInfo = _detectCredentialSide(extractedText);
      final detectedSide = sideInfo['lado'] as String;
      
      // Procesar según el lado detectado
      CredencialIneModel credential;
      if (detectedSide == 'reverso' || detectedSide == 'trasero') {
        credential = await _processBackSide(imagePath, processingOptions);
      } else {
        credential = await _processFrontSide(imagePath, extractedText, processingOptions);
      }
      
      // Actualizar lado detectado
      credential = credential.copyWith(ladoCredencial: detectedSide);
      
      // Validar datos extraídos
      final isValid = _validateExtractedData(credential);
      
      return ProcessingResult.success(
        data: credential,
        message: isValid ? 'Credencial procesada exitosamente' : 'Credencial procesada con advertencias',
        metadata: {
          'lado_detectado': detectedSide,
          'es_valida': isValid,
          'tipo_credencial': credential.tipoCredencial,
          'confianza_lado': sideInfo['confianza'],
        },
      );
      
    } catch (e) {
      return ProcessingResult.error(
        message: 'Error procesando credencial: $e',
        errorCode: 'PROCESSING_ERROR',
      );
    }
  }
  
  /// Extrae texto de una imagen usando OCR
  static Future<String> _extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw Exception('Error en OCR: $e');
    }
  }
  
  /// Verifica si el texto corresponde a una credencial INE
  static bool _isIneCredential(String extractedText) {
    final upperText = extractedText.toUpperCase();
    return _ineKeywords.any((keyword) => upperText.contains(keyword));
  }
  
  /// Detecta el lado de la credencial basado en el texto
  static Map<String, dynamic> _detectCredentialSide(String extractedText) {
    final upperText = extractedText.toUpperCase();
    
    // Etiquetas que indican lado frontal
    final frontalLabels = [
      'NOMBRE', 'DOMICILIO', 'CLAVE DE ELECTOR', 'CURP',
      'FECHA DE NACIMIENTO', 'SEXO', 'VIGENCIA'
    ];
    
    int frontalCount = 0;
    for (final label in frontalLabels) {
      if (upperText.contains(label)) {
        frontalCount++;
      }
    }
    
    // Si tiene 1 o más etiquetas frontales, es lado frontal
    final isFrontal = frontalCount >= 1;
    final confidence = frontalCount / frontalLabels.length;
    
    return {
      'lado': isFrontal ? 'frontal' : 'reverso',
      'confianza': confidence,
      'etiquetas_encontradas': frontalCount,
    };
  }
  
  /// Procesa el lado frontal de la credencial
  static Future<CredencialIneModel> _processFrontSide(
    String imagePath,
    String extractedText,
    ProcessingOptions options,
  ) async {
    // Detectar tipo de credencial
    final credentialType = _detectCredentialType(extractedText);
    
    // Extraer datos del texto
    final extractedData = _extractDataFromText(extractedText, credentialType);
    
    // Extraer foto si está habilitado
    String? photoPath;
    if (options.extractPhoto) {
      photoPath = await _extractPhoto(imagePath);
    }
    
    // Extraer firma si está habilitado
    String? signaturePath;
    if (options.extractSignature) {
      signaturePath = await _extractSignature(imagePath, credentialType);
    }
    
    return CredencialIneModel(
      nombre: extractedData['nombre'] ?? '',
      apellidoPaterno: extractedData['apellidoPaterno'] ?? '',
      apellidoMaterno: extractedData['apellidoMaterno'] ?? '',
      domicilio: extractedData['domicilio'] ?? '',
      claveElector: extractedData['claveElector'] ?? '',
      curp: extractedData['curp'] ?? '',
      fechaNacimiento: extractedData['fechaNacimiento'] ?? '',
      sexo: extractedData['sexo'] ?? '',
      anioRegistro: extractedData['anioRegistro'] ?? '',
      seccion: extractedData['seccion'] ?? '',
      vigencia: extractedData['vigencia'] ?? '',
      estado: extractedData['estado'] ?? '',
      municipio: extractedData['municipio'] ?? '',
      localidad: extractedData['localidad'] ?? '',
      tipoCredencial: credentialType,
      ladoCredencial: 'frontal',
      fotoPath: photoPath,
      signatureHuellaPath: signaturePath,
      credentialPath: imagePath,
      fechaProcesamiento: DateTime.now(),
    );
  }
  
  /// Procesa el lado reverso de la credencial
  static Future<CredencialIneModel> _processBackSide(
    String imagePath,
    ProcessingOptions options,
  ) async {
    // Detectar códigos QR
    String? qrContent;
    if (options.detectQRCodes) {
      qrContent = await _detectQRCode(imagePath);
    }
    
    // Detectar códigos de barras
    String? barcodeContent;
    if (options.detectBarcodes) {
      barcodeContent = await _detectBarcode(imagePath);
    }
    
    // Detectar tipo por conteo de QRs
    final qrCount = await _countQRCodes(imagePath);
    final credentialType = _detectCredentialTypeByQrCount(qrCount);
    
    return CredencialIneModel(
      tipoCredencial: credentialType,
      ladoCredencial: 'reverso',
      codigoQr: qrContent,
      codigoBarras: barcodeContent,
      credentialPath: imagePath,
      fechaProcesamiento: DateTime.now(),
    );
  }
  
  /// Detecta el tipo de credencial basado en el texto
  static String _detectCredentialType(String extractedText) {
    final upperText = extractedText.toUpperCase();
    
    // Buscar etiquetas específicas de T2
    bool hasT2Labels = _tipo2Labels.any((label) => upperText.contains(label));
    
    return hasT2Labels ? 't2' : 't3';
  }
  
  /// Detecta el tipo de credencial basado en el conteo de códigos QR
  static String _detectCredentialTypeByQrCount(int qrCount) {
    // T2: 1 código QR, T3: 2 códigos QR
    return qrCount == 1 ? 't2' : 't3';
  }
  
  /// Extrae datos específicos del texto OCR
  static Map<String, String> _extractDataFromText(String text, String credentialType) {
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    final extractedData = <String, String>{};
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      
      // Extraer nombre
      if (line.contains('NOMBRE') && i + 1 < lines.length) {
        extractedData['nombre'] = _cleanExtractedText(lines[i + 1]);
      }
      
      // Extraer domicilio
      if (line.contains('DOMICILIO') && i + 1 < lines.length) {
        extractedData['domicilio'] = _cleanExtractedText(lines[i + 1]);
      }
      
      // Extraer clave de elector
      if (line.contains('CLAVE DE ELECTOR') && i + 1 < lines.length) {
        extractedData['claveElector'] = _cleanExtractedText(lines[i + 1]);
      }
      
      // Extraer CURP
      if (line.contains('CURP') && i + 1 < lines.length) {
        extractedData['curp'] = _cleanExtractedText(lines[i + 1]);
      }
      
      // Extraer vigencia
      if (line.contains('VIGENCIA') && i + 1 < lines.length) {
        extractedData['vigencia'] = _cleanExtractedText(lines[i + 1]);
      }
      
      // Extraer sección
      if (line.contains('SECCION') || line.contains('SECCIÓN')) {
        final sectionMatch = RegExp(r'\b\d{4}\b').firstMatch(line);
        if (sectionMatch != null) {
          extractedData['seccion'] = sectionMatch.group(0)!;
        }
      }
      
      // Campos específicos para T2
      if (credentialType == 't2') {
        if (line.contains('ESTADO') && i + 1 < lines.length) {
          extractedData['estado'] = _cleanExtractedText(lines[i + 1]);
        }
        if (line.contains('MUNICIPIO') && i + 1 < lines.length) {
          extractedData['municipio'] = _cleanExtractedText(lines[i + 1]);
        }
        if (line.contains('LOCALIDAD') && i + 1 < lines.length) {
          extractedData['localidad'] = _cleanExtractedText(lines[i + 1]);
        }
      }
    }
    
    return extractedData;
  }
  
  /// Limpia el texto extraído removiendo caracteres no deseados
  static String _cleanExtractedText(String text) {
    return text.trim().replaceAll(RegExp(r'[^\w\s\-\/]'), '');
  }
  
  /// Extrae la foto de la credencial
  static Future<String?> _extractPhoto(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) return null;
      
      // Usar la primera cara detectada
      final face = faces.first;
      final boundingBox = face.boundingBox;
      
      // Cargar imagen original
      final imageBytes = await File(imagePath).readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;
      
      // Extraer región de la cara con margen
      final margin = 20;
      final x = (boundingBox.left - margin).clamp(0, originalImage.width);
      final y = (boundingBox.top - margin).clamp(0, originalImage.height);
      final width = (boundingBox.width + 2 * margin).clamp(0, originalImage.width - x);
      final height = (boundingBox.height + 2 * margin).clamp(0, originalImage.height - y);
      
      final croppedImage = img.copyCrop(originalImage, x: x.toInt(), y: y.toInt(), width: width.toInt(), height: height.toInt());
      
      // Guardar imagen extraída
      final directory = await getApplicationDocumentsDirectory();
      final photoPath = path.join(directory.path, 'extracted_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(photoPath).writeAsBytes(img.encodeJpg(croppedImage));
      
      return photoPath;
    } catch (e) {
      return null;
    }
  }
  
  /// Extrae la firma de la credencial
  static Future<String?> _extractSignature(String imagePath, String credentialType) async {
    try {
      // Cargar imagen
      final imageBytes = await File(imagePath).readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;
      
      // Coordenadas específicas para T2 (ajustadas según el análisis previo)
      double startX = 0.175; // 17.5%
      double endX = 0.825;   // 82.5%
      double startY = 0.32;  // 32%
      double endY = 0.62;    // 62%
      
      // Calcular coordenadas absolutas
      final x = (originalImage.width * startX).toInt();
      final y = (originalImage.height * startY).toInt();
      final width = (originalImage.width * (endX - startX)).toInt();
      final height = (originalImage.height * (endY - startY)).toInt();
      
      // Extraer región de firma
      final signatureImage = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: width,
        height: height,
      );
      
      // Guardar imagen de firma
      final directory = await getApplicationDocumentsDirectory();
      final signaturePath = path.join(directory.path, 'extracted_signature_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(signaturePath).writeAsBytes(img.encodeJpg(signatureImage));
      
      return signaturePath;
    } catch (e) {
      return null;
    }
  }
  
  /// Detecta códigos QR en la imagen
  static Future<String?> _detectQRCode(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final barcodes = await _barcodeScanner.processImage(inputImage);
      
      for (final barcode in barcodes) {
        if (barcode.format == BarcodeFormat.qrCode) {
          return barcode.rawValue;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Detecta códigos de barras en la imagen
  static Future<String?> _detectBarcode(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final barcodes = await _barcodeScanner.processImage(inputImage);
      
      for (final barcode in barcodes) {
        if (barcode.format == BarcodeFormat.code128) {
          return barcode.rawValue;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Cuenta el número de códigos QR en la imagen
  static Future<int> _countQRCodes(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final barcodes = await _barcodeScanner.processImage(inputImage);
      
      return barcodes.where((barcode) => barcode.format == BarcodeFormat.qrCode).length;
    } catch (e) {
      return 0;
    }
  }
  
  /// Valida los datos extraídos de la credencial
  static bool _validateExtractedData(CredencialIneModel credential) {
    // Validaciones básicas
    if (credential.tipoCredencial?.isEmpty ?? true) return false;
    
    // Para lado frontal, validar campos principales
    if (credential.ladoCredencial == 'frontal') {
      if (credential.nombre?.isEmpty ?? true) return false;
      if (credential.claveElector?.isEmpty ?? true) return false;
      if (credential.curp?.isEmpty ?? true) return false;
    }
    
    // Para lado reverso, validar que tenga al menos un código
    if (credential.ladoCredencial == 'reverso') {
      final hasQR = credential.codigoQr?.isNotEmpty ?? false;
      final hasBarcode = credential.codigoBarras?.isNotEmpty ?? false;
      if (!hasQR && !hasBarcode) return false;
    }
    
    return true;
  }
  
  /// Libera recursos del servicio
  static Future<void> dispose() async {
    await _textRecognizer.close();
    await _barcodeScanner.close();
    await _faceDetector.close();
  }
}