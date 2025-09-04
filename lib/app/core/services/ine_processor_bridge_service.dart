import 'dart:io';
import 'package:flutter/services.dart';
import 'ine_credential_processor_service.dart';
import 'mlkit_text_recognition_service.dart';
import 'logger_service.dart';
import '../../data/models/credencial_ine_model.dart';

/// Servicio bridge específico para comunicación con IneProcessorBridge nativo
class IneProcessorBridgeService {
  static const MethodChannel _channel = MethodChannel(
    'mx.d3c.dev.atom_ocr_ai_m_v3/ine_processor',
  );
  static final LoggerService _logger = LoggerService.instance;
  static final MLKitTextRecognitionService _mlKitService =
      MLKitTextRecognitionService();

  /// Inicializa el servicio y registra el handler del canal
  static void initialize() {
    _logger.info('IneProcessorBridgeService', 'Inicializando handler del canal ine_processor');
    
    _channel.setMethodCallHandler((MethodCall call) async {
      _logger.info('IneProcessorBridgeService', 'Método recibido: ${call.method}');
      
      switch (call.method) {
        case 'processCredential':
          return await _processCredential(call.arguments);
        case 'validateIneCredential':
          return await _validateIneCredential(call.arguments);
        default:
          _logger.warning('IneProcessorBridgeService', 'Método no implementado: ${call.method}');
          throw PlatformException(
            code: 'UNIMPLEMENTED',
            message: 'Método ${call.method} no implementado',
          );
      }
    });
  }

  /// Procesa una credencial INE desde el bridge nativo
  static Future<Map<String, dynamic>> _processCredential(
    dynamic arguments,
  ) async {
    try {
      final Map<String, dynamic> args = Map<String, dynamic>.from(arguments);
      final String imagePath = args['imagePath'] as String;
      final String side = args['side'] as String;

      _logger.info(
        'IneProcessorBridgeService',
        'Procesando credencial - Path: $imagePath, Side: $side',
      );

      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Archivo de imagen no encontrado: $imagePath');
      }

      // Extraer texto usando MLKit
      final extractedText = await _mlKitService.extractTextFromImage(imagePath);

      if (extractedText?.isEmpty ?? true) {
        throw Exception('No se pudo extraer texto de la imagen');
      }

      // Verificar que se extrajo texto
      if (extractedText == null || extractedText.isEmpty) {
        throw Exception('No se pudo extraer texto de la imagen');
      }

      // Verificar si es una credencial INE válida
      if (!IneCredentialProcessorService.isIneCredential(extractedText)) {
        throw Exception('La imagen no parece ser una credencial INE válida');
      }

      // Procesar la credencial con detección de lado
      final CredencialIneModel credential =
          await IneCredentialProcessorService.processCredentialWithSideDetection(
            extractedText,
            imagePath,
          );

      // Filtrar datos según el tipo de credencial y lado
      final filteredData = _filterCredentialData(credential, side);

      _logger.info(
        'IneProcessorBridgeService',
        'Credencial procesada exitosamente: ${credential.tipo} - ${credential.lado}',
      );

      return {
        'success': true,
        'data': filteredData,
        'credentialType': credential.tipo,
        'side': credential.lado,
      };
    } catch (e) {
      _logger.error('IneProcessorBridgeService', 'Error procesando credencial: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Valida si una imagen es una credencial INE válida
  static Future<bool> _validateIneCredential(dynamic arguments) async {
    try {
      final Map<String, dynamic> args = Map<String, dynamic>.from(arguments);
      final String imagePath = args['imagePath'] as String;

      _logger.info(
        'IneProcessorBridgeService',
        'Validando credencial INE - Path: $imagePath',
      );

      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        return false;
      }

      // Extraer texto usando MLKit
      final extractedText = await _mlKitService.extractTextFromImage(imagePath);

      if (extractedText?.isEmpty ?? true) {
        return false;
      }

      // Verificar si es una credencial INE válida
      return IneCredentialProcessorService.isIneCredential(extractedText!);
    } catch (e) {
      _logger.error('IneProcessorBridgeService', 'Error validando credencial: $e');
      return false;
    }
  }

  /// Filtra los datos de la credencial según el tipo y lado especificado
  static Map<String, dynamic> _filterCredentialData(
    CredencialIneModel credential,
    String requestedSide,
  ) {
    final Map<String, dynamic> baseData = {
      'tipoCredencial': credential.tipo,
      'lado': credential.lado,
    };

    // Verificar que el lado procesado coincida con el solicitado
    if (credential.lado.toLowerCase() != requestedSide.toLowerCase()) {
      _logger.warning(
        'IneProcessorBridgeService',
        'Lado procesado (${credential.lado}) no coincide con el solicitado ($requestedSide)',
      );
    }

    switch (credential.tipo.toLowerCase()) {
      case 't2':
        return _filterT2Data(credential, baseData);
      case 't3':
        return _filterT3Data(credential, baseData);
      default:
        return baseData;
    }
  }

  /// Filtra datos específicos para credenciales T2
  static Map<String, dynamic> _filterT2Data(
    CredencialIneModel credential,
    Map<String, dynamic> baseData,
  ) {
    if (credential.lado.toLowerCase() == 'frontal') {
      return {
        ...baseData,
        'nombre': credential.nombre,
        'domicilio': credential.domicilio,
        'fechaNacimiento': credential.fechaNacimiento,
        'sexo': credential.sexo,
        'curp': credential.curp,
        'claveElector': credential.claveElector,
        'seccion': credential.seccion,
        'localidad': credential.localidad,
        'municipio': credential.municipio,
        'estado': credential.estado,
        'vigencia': credential.vigencia,
        'anoRegistro': credential.anoRegistro,
      };
    } else {
      return {
        ...baseData,
        'mrzContent': credential.mrzContent,
        'barcodeContent': credential.barcodeContent,
      };
    }
  }

  /// Filtra datos específicos para credenciales T3
  static Map<String, dynamic> _filterT3Data(
    CredencialIneModel credential,
    Map<String, dynamic> baseData,
  ) {
    if (credential.lado.toLowerCase() == 'frontal') {
      return {
        ...baseData,
        'nombre': credential.nombre,
        'domicilio': credential.domicilio,
        'fechaNacimiento': credential.fechaNacimiento,
        'sexo': credential.sexo,
        'curp': credential.curp,
        'claveElector': credential.claveElector,
        'seccion': credential.seccion,
        'localidad': credential.localidad,
        'municipio': credential.municipio,
        'estado': credential.estado,
        'vigencia': credential.vigencia,
        'anoRegistro': credential.anoRegistro,
      };
    } else {
      return {
        ...baseData,
        'mrzContent': credential.mrzContent,
      };
    }
  }
}