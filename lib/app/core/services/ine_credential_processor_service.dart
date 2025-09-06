import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../../../app/data/models/credencial_ine_model.dart';
import '../utils/validation_utils.dart';
import '../utils/string_similarity_utils.dart';
import '../utils/credential_side_detector.dart';
import 'face_detection_service.dart';
import 'signature_extraction_service.dart';
import 'qr_detection_service.dart';
import 'barcode_detection_service.dart';
import 'mrz_detection_service.dart';

class IneCredentialProcessorService {
  /// Palabras clave que indican que es una credencial INE
  static const List<String> _ineKeywords = [
    'INSTITUTO NACIONAL ELECTORAL',
    'CREDENCIAL PARA VOTAR',
    'INE',
    'CLAVE DE ELECTOR',
    'CURP',
  ];

  /// Textos institucionales que deben ser filtrados completamente
  static const List<String> _unwantedTexts = [
    'INSTITUTO NACIONAL ELECTORAL',
    'MÉXICO',
    'MEXICO',
  ];

  /// Etiquetas de referencia necesarias para localizar datos pero que no deben aparecer en el resultado final
  static const List<String> _referenceLabels = [
    'CREDENCIAL PARA VOTAR',
    'NOMBRE',
    'NOMERE',
    'NOMRE',
    'DOMICILIO',
    'DOMICILIo',
    'DOMICILI',
    'CLAVE DE ELECTOR',
    'COL',
    'COLONIA',
    'ESTADO',
    'MUNICIPIO',
    'LOCALIDAD',
  ];

  // T1 deshabilitado completamente - solo se procesan T2 y T3

  /// Etiquetas específicas para credenciales t2
  static const List<String> _tipo2Labels = ['ESTADO', 'MUNICIPIO', 'LOCALIDAD'];

  /// Configuración de tipos de credenciales y su procesamiento
  /// NOTA: La detección de tipo usa métodos híbridos:
  /// - Lado frontal: Análisis de texto OCR (método _detectCredentialType)
  /// - Lado reverso: Conteo de códigos QR (método _detectCredentialTypeByQrCount)
  static const Map<String, Map<String, dynamic>> _credentialTypeConfig = {
    // T1 completamente deshabilitado - solo se procesan T2 y T3
    'Tipo 2': {
      'code': 't2',
      'process': true,
      'description': 'Credenciales con ESTADO/MUNICIPIO/LOCALIDAD',
      'requiredFields': [
        'NOMBRE',
        'CLAVE DE ELECTOR',
        'CURP',
        'SECCION',
        'VIGENCIA',
      ],
    },
    'Tipo 3': {
      'code': 't3',
      'process': true,
      'description': 'Credenciales más nuevas sin campos específicos',
      'requiredFields': [
        'NOMBRE',
        'CLAVE DE ELECTOR',
        'CURP',
        'SECCION',
        'VIGENCIA',
      ],
    },
  };

  /// Verifica si el texto extraído corresponde a una credencial INE
  static bool isIneCredential(String extractedText) {
    final upperText = extractedText.toUpperCase();
    
    // Verificar palabras clave tradicionales
    if (_ineKeywords.any((keyword) => upperText.contains(keyword))) {
      return true;
    }
    
    // Verificar patrones MRZ para credenciales T3 traseras
    if (_isMrzPattern(upperText)) {
      print('🔍 DIAGNÓSTICO: Credencial INE detectada por patrón MRZ');
      return true;
    }
    
    return false;
  }
  
  /// Verifica si el texto contiene patrones MRZ típicos de credenciales INE T3
  static bool _isMrzPattern(String upperText) {
    // Patrones típicos de MRZ en credenciales INE T3:
    // - Líneas que terminan con <<< o contienen << 
    // - Códigos de país MEX
    // - Patrones de fecha con formato específico
    // - Líneas con números de documento y checksums
    
    final lines = upperText.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    // Verificar patrones MRZ específicos
    bool hasMexCode = upperText.contains('MEX');
    bool hasTripleAngleBrackets = upperText.contains('<<<');
    bool hasDoubleAngleBrackets = upperText.contains('<<');
    bool hasNumericPatterns = RegExp(r'\d{10,}').hasMatch(upperText);
    
    // Si tiene al menos 2 de estos patrones, probablemente es MRZ
    int mrzPatternCount = 0;
    if (hasMexCode) mrzPatternCount++;
    if (hasTripleAngleBrackets) mrzPatternCount++;
    if (hasDoubleAngleBrackets) mrzPatternCount++;
    if (hasNumericPatterns) mrzPatternCount++;
    
    return mrzPatternCount >= 2;
  }

  /// Verifica si un tipo de credencial debe ser procesado
  static bool _shouldProcessCredentialType(String credentialType) {
    // Buscar la configuración por código
    for (final config in _credentialTypeConfig.values) {
      if (config['code'] == credentialType) {
        return config['process'] as bool;
      }
    }
    return false; // Por defecto no procesar tipos desconocidos
  }

  /// Verifica si una credencial cumple con los requisitos mínimos
  static bool isCredentialAcceptable(CredencialIneModel credential) {
    // Buscar la configuración del tipo de credencial
    Map<String, dynamic>? typeConfig;
    for (var config in _credentialTypeConfig.values) {
      if (config['code'] == credential.tipo) {
        typeConfig = config;
        break;
      }
    }

    if (typeConfig == null) return false;

    // Validar consistencia del lado con el tipo de credencial
    if (!ValidationUtils.isSideConsistentWithType(credential.lado, credential.tipo)) {
      return false;
    }

    // Validar que los datos sean consistentes con el lado detectado
    final credentialDataMap = {
      'nombre': credential.nombre,
      'domicilio': credential.domicilio,
      'claveElector': credential.claveElector,
      'curp': credential.curp,
    };
    
    if (!ValidationUtils.hasExpectedDataForSide(credential.lado, credentialDataMap)) {
      return false;
    }

    final requiredFields = typeConfig['requiredFields'] as List<String>;

    // Verificar cada campo requerido con validaciones específicas
    for (String field in requiredFields) {
      switch (field) {
        case 'NOMBRE':
          if (credential.nombre.isEmpty ||
              !ValidationUtils.isValidName(credential.nombre)) {
            return false;
          }
          break;
        case 'CLAVE DE ELECTOR':
          if (credential.claveElector.isEmpty ||
              !ValidationUtils.isValidClaveElector(credential.claveElector)) {
            return false;
          }
          break;
        case 'CURP':
          if (credential.curp.isEmpty ||
              !ValidationUtils.isValidCurpFormat(credential.curp)) {
            return false;
          }
          break;
        case 'SECCION':
          if (credential.seccion.isEmpty ||
              !ValidationUtils.isValidSection(credential.seccion)) {
            return false;
          }
          break;
        case 'VIGENCIA':
          if (credential.vigencia.isEmpty) {
            return false;
          }
          // Para T2, validar formato específico de vigencia
          if (credential.tipo == 't2') {
            // Extraer el año final de vigencia (formato: "YYYY YYYY" o solo "YYYY")
            final vigenciaParts = credential.vigencia.split(' ');
            final lastYear =
                vigenciaParts.isNotEmpty
                    ? vigenciaParts.last
                    : credential.vigencia;
            if (!ValidationUtils.isValidVigencia(lastYear)) {
              return false;
            }
          }
          // Para T3, validar formato específico de vigencia (YYYY-YYYY)
          if (credential.tipo == 't3') {
            if (!ValidationUtils.isValidVigencia(credential.vigencia)) {
              return false;
            }
          }
          break;
      }
    }

    // Validaciones adicionales específicas para credenciales T2
    if (credential.tipo == 't2') {
      // Validar fecha de nacimiento
      if (credential.fechaNacimiento.isNotEmpty &&
          !ValidationUtils.isValidBirthDate(credential.fechaNacimiento)) {
        return false;
      }

      // Validar sexo
      if (credential.sexo.isNotEmpty &&
          !ValidationUtils.isValidSex(credential.sexo)) {
        return false;
      }

      // Validar año de registro
      if (credential.anoRegistro.isNotEmpty &&
          !ValidationUtils.isValidRegistrationYear(
            credential.anoRegistro.replaceAll(' ', ''),
          )) {
        return false;
      }

      // Validar estado (debe ser numérico)
      if (credential.estado.isNotEmpty &&
          !ValidationUtils.isValidState(credential.estado)) {
        return false;
      }

      // Validar municipio (3 dígitos)
      if (credential.municipio.isNotEmpty &&
          !ValidationUtils.isValidMunicipality(credential.municipio)) {
        return false;
      }

      // Validar localidad (4 dígitos)
      if (credential.localidad.isNotEmpty &&
          !ValidationUtils.isValidLocality(credential.localidad)) {
        return false;
      }
    }

    return true; // Todos los campos requeridos están presentes y válidos
  }

  /// Procesa credencial con detección de lado basada en texto
  static Future<CredencialIneModel> processCredentialWithSideDetection(
      String extractedText, String imagePath) async {
    print('🎯 Iniciando procesamiento con detección de lado');
    print('DIAGNÓSTICO T3: Texto extraído para análisis: ${extractedText.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}...');
    print('DIAGNÓSTICO T3: Imagen path: $imagePath');
    
    // Detectar lado PRIMERO para determinar el método de procesamiento
    String detectedSide = 'frontal';
    try {
      final sideResult = CredentialSideDetector.detectSide(extractedText);
      detectedSide = sideResult['lado'] as String;
      print('📍 Lado detectado: $detectedSide');
      print('DIAGNÓSTICO T3: Resultado completo de detección de lado: $sideResult');
    } catch (e) {
      // En caso de error, mantener lado como frontal por defecto
      detectedSide = 'frontal';
      print('⚠️ Error detectando lado, usando frontal por defecto: $e');
      print('DIAGNÓSTICO T3: Error en detección de lado: $e');
    }
    
    // Crear modelo base según el lado detectado
    CredencialIneModel credential;
    if (detectedSide == 'reverso' || detectedSide == 'trasero') {
      // Para lado reverso: usar SOLO conteo de QRs sin análisis OCR previo
      print('🔍 Lado reverso detectado - usando SOLO conteo de QRs para clasificación');
      print('DIAGNÓSTICO T3: Iniciando conteo de QRs en imagen');
      Map<String, dynamic> qrCountResult = await QrDetectionService.countAllQrCodesInImage(imagePath);
      int qrCount = qrCountResult['qrCount'] ?? 0;
      print('📊 Códigos QR detectados: $qrCount');
      print('DIAGNÓSTICO T3: Resultado completo del conteo QR: $qrCountResult');
      
      // Detectar tipo usando SOLO conteo de QRs (sin análisis de texto)
      String credentialType = _detectCredentialTypeByQrCount(qrCount);
      print('🔍 Tipo de credencial detectado por QR: $credentialType');
      print('DIAGNÓSTICO T3: Tipo final asignado: $credentialType');
      
      // Crear modelo básico con solo el tipo detectado por QRs
      credential = CredencialIneModel(
        nombre: '',
        domicilio: '',
        claveElector: '',
        curp: '',
        fechaNacimiento: '',
        sexo: '',
        anoRegistro: '',
        seccion: '',
        vigencia: '',
        tipo: credentialType,
        lado: detectedSide,
        estado: '',
        municipio: '',
        localidad: '',
        photoPath: '',
        signaturePath: '',
        qrContent: '',
        qrImagePath: '',
        barcodeContent: '',
        barcodeImagePath: '',
        mrzContent: '',
        mrzImagePath: '',
        mrzDocumentNumber: '',
        mrzNationality: '',
        mrzBirthDate: '',
        mrzExpiryDate: '',
        mrzSex: '',
        signatureHuellaImagePath: '',
      );
    } else {
      // Para lado frontal: usar lógica original basada en texto
      print('🔍 Lado frontal detectado - usando análisis de texto OCR');
      credential = processCredentialText(extractedText);
      print('🔍 Tipo de credencial detectado por texto: ${credential.tipo}');
    }
    
    // Actualizar el lado detectado
    credential = credential.copyWith(lado: detectedSide);
    
    // Variables para almacenar los resultados de detección
    Map<String, String> frontalData = {};
    Map<String, String> reversoData = {};

    // Procesar según el lado detectado
    if (detectedSide == 'frontal') {
      print('🔍 Procesando lado frontal de la credencial...');
      frontalData = await _processFrontalSide(imagePath, credential);
    } else if (detectedSide == 'reverso' || detectedSide == 'trasero') {
      print('🔍 Procesando lado trasero de la credencial...');
      final reversoResult = await _processReversoSide(imagePath, credential);
      reversoData = reversoResult['reversoData'] as Map<String, String>;
      credential = reversoResult['updatedCredential'] as CredencialIneModel;
      
      // Para credenciales T2 del lado reverso, limpiar campos frontales incorrectos
      if (credential.tipo == 't2') {
        print('🧹 Limpiando campos frontales incorrectos para T2 reverso...');
        credential = credential.copyWith(
          nombre: '',
          claveElector: '',
          domicilio: '',
          curp: '',
          fechaNacimiento: '',
          sexo: '',
          anoRegistro: '',
          seccion: '',
          vigencia: '',
          estado: '',
          municipio: '',
          localidad: '',
        );
      }
    } else {
      print('⚠️ Lado no reconocido: $detectedSide. Procesando como frontal por defecto.');
      frontalData = await _processFrontalSide(imagePath, credential);
    }

    // Formatear cadena MRZ si está presente (eliminar espacios y saltos de línea)
    String formattedMrzContent = '';
    print('🔍 DEBUG: reversoData[mrzContent] = "${reversoData['mrzContent']}"');
    print('🔍 DEBUG: reversoData[mrzContent]?.isNotEmpty = ${reversoData['mrzContent']?.isNotEmpty}');
    
    if (reversoData['mrzContent']?.isNotEmpty == true) {
      print('🔍 MRZ original detectada: "${reversoData['mrzContent']}"');
      print('🔍 MRZ original length: ${reversoData['mrzContent']!.length}');
      formattedMrzContent = _formatMrzContent(reversoData['mrzContent']!);
      print('📝 MRZ formateada: "$formattedMrzContent" (${formattedMrzContent.length} caracteres)');
      print('🔍 DEBUG: formattedMrzContent.isEmpty = ${formattedMrzContent.isEmpty}');
    } else {
      print('⚠️ No se detectó contenido MRZ o está vacío');
      print('🔍 DEBUG: reversoData keys = ${reversoData.keys.toList()}');
    }

    // Actualizar el modelo con todos los datos detectados
    final updatedCredential = credential.copyWith(
      lado: detectedSide,
      // Datos frontales
      photoPath: frontalData['photoPath']?.isNotEmpty == true ? frontalData['photoPath'] : credential.photoPath,
      signaturePath: frontalData['signaturePath']?.isNotEmpty == true ? frontalData['signaturePath'] : credential.signaturePath,
      // Datos del reverso
      qrContent: reversoData['qrContent']?.isNotEmpty == true ? reversoData['qrContent'] : credential.qrContent,
      qrImagePath: reversoData['qrImagePath']?.isNotEmpty == true ? reversoData['qrImagePath'] : credential.qrImagePath,
      barcodeContent: reversoData['barcodeContent']?.isNotEmpty == true ? reversoData['barcodeContent'] : credential.barcodeContent,
      barcodeImagePath: reversoData['barcodeImagePath']?.isNotEmpty == true ? reversoData['barcodeImagePath'] : credential.barcodeImagePath,
      mrzContent: formattedMrzContent.isNotEmpty ? formattedMrzContent : credential.mrzContent,
      mrzImagePath: reversoData['mrzImagePath']?.isNotEmpty == true ? reversoData['mrzImagePath'] : credential.mrzImagePath,
      mrzDocumentNumber: reversoData['mrzDocumentNumber']?.isNotEmpty == true ? reversoData['mrzDocumentNumber'] : credential.mrzDocumentNumber,
      mrzNationality: reversoData['mrzNationality']?.isNotEmpty == true ? reversoData['mrzNationality'] : credential.mrzNationality,
      mrzBirthDate: reversoData['mrzBirthDate']?.isNotEmpty == true ? reversoData['mrzBirthDate'] : credential.mrzBirthDate,
      mrzExpiryDate: reversoData['mrzExpiryDate']?.isNotEmpty == true ? reversoData['mrzExpiryDate'] : credential.mrzExpiryDate,
      mrzSex: reversoData['mrzSex']?.isNotEmpty == true ? reversoData['mrzSex'] : credential.mrzSex,
      // Datos de firma-huella para T2 reverso
      signatureHuellaImagePath: reversoData['signatureHuellaImagePath']?.isNotEmpty == true ? reversoData['signatureHuellaImagePath'] : credential.signatureHuellaImagePath,
    );

    print('✅ Procesamiento completado para credencial ${updatedCredential.tipo} lado ${updatedCredential.lado}');
    print('🏁 Credencial final - photoPath: ${updatedCredential.photoPath}, signaturePath: ${updatedCredential.signaturePath}, qrContent: ${updatedCredential.qrContent.isNotEmpty ? 'Presente' : 'Ausente'}, qrImagePath: ${updatedCredential.qrImagePath}');
    print('🔤 MRZ final en modelo: "${updatedCredential.mrzContent}" (${updatedCredential.mrzContent.length} caracteres)');
    return updatedCredential;
  }

  /// Procesa el lado frontal de una credencial (T2, T3)
  /// Incluye: detección facial y extracción de firma (solo T3)
  static Future<Map<String, String>> _processFrontalSide(
    String imagePath,
    CredencialIneModel credential,
  ) async {
    final Map<String, String> frontalData = {
      'photoPath': '',
      'signaturePath': '',
    };

    // Detectar y extraer fotografía del rostro para credenciales T2 y T3
    print('🎯 Procesando lado frontal - tipo: ${credential.tipo}');
    if (credential.tipo == 't2' || credential.tipo == 't3') {
      print('✅ Iniciando detección facial...');
      try {
        frontalData['photoPath'] = await FaceDetectionService.extractFaceFromCredential(imagePath);
        print('📸 Foto extraída exitosamente: ${frontalData['photoPath']}');
      } catch (e) {
        print('❌ Error en detección facial: $e');
      }
    }

    // Extraer firma solo para credenciales T3 frontales
    if (credential.tipo == 't3' && frontalData['photoPath']!.isNotEmpty) {
      print('🖋️ Iniciando extracción de firma para credencial T3...');
      try {
        final credentialId = DateTime.now().millisecondsSinceEpoch.toString();
        frontalData['signaturePath'] = await SignatureExtractionService.extractSignatureFromT3Credential(
          imagePath: imagePath,
          facePhotoPath: frontalData['photoPath']!,
          credentialId: credentialId,
        );
        print('🖋️ Firma extraída exitosamente: ${frontalData['signaturePath']}');
      } catch (e) {
        print('❌ Error en extracción de firma: $e');
      }
    } else if (credential.tipo == 't3') {
      print('⚠️ No se puede extraer firma: falta la fotografía del rostro');
    }

    return frontalData;
  }

  /// Formatea el contenido MRZ eliminando espacios y saltos de línea
  /// para obtener una cadena de exactamente 90 caracteres
  static String _formatMrzContent(String mrzContent) {
    if (mrzContent.isEmpty) return '';
    
    print('🧹 MRZ original recibida: "$mrzContent"');
    print('🧹 MRZ original longitud: ${mrzContent.length} caracteres');
    
    // Dividir en líneas y limpiar cada una
    final lines = mrzContent.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    print('🧹 Líneas detectadas: ${lines.length}');
    for (int i = 0; i < lines.length; i++) {
      print('🧹 Línea ${i + 1}: "${lines[i]}" (${lines[i].length} chars)');
    }
    
    // Validar que tengamos exactamente 3 líneas
    if (lines.length != 3) {
      print('⚠️ MRZ no tiene 3 líneas (tiene ${lines.length}), intentando formateo directo');
      // Intentar formateo directo eliminando espacios
      String cleanedMrz = mrzContent
          .replaceAll(RegExp(r'\s+'), '') // Eliminar espacios, tabs, saltos de línea
          .replaceAll(RegExp(r'[\r\n\t]'), '') // Eliminar caracteres de control específicos
          .trim();
      
      if (cleanedMrz.length == 90) {
        print('✅ MRZ formateada directamente: 90 caracteres');
        return cleanedMrz;
      } else {
        print('⚠️ MRZ formateo directo falló: ${cleanedMrz.length} caracteres');
        return cleanedMrz.length > 90 ? cleanedMrz.substring(0, 90) : cleanedMrz.padRight(90, '<');
      }
    }
    
    // Concatenar las 3 líneas (cada una debe tener 30 caracteres)
    String formattedMrz = '';
    for (int i = 0; i < 3; i++) {
      String line = lines[i];
      // Limpiar caracteres especiales y espacios invisibles
      line = line.replaceAll(RegExp(r'[^A-Z0-9<]'), '<');
      
      // Normalizar la línea a exactamente 30 caracteres
      if (line.length > 30) {
        line = line.substring(0, 30);
        print('⚠️ Línea ${i + 1} truncada a 30 caracteres');
      } else if (line.length < 30) {
        line = line.padRight(30, '<');
        print('⚠️ Línea ${i + 1} rellenada a 30 caracteres');
      }
      formattedMrz += line;
    }
    
    // Validación final: asegurar que solo contiene caracteres válidos
    formattedMrz = formattedMrz.replaceAll(RegExp(r'[^A-Z0-9<]'), '<');
    
    // Asegurar exactamente 90 caracteres
    if (formattedMrz.length != 90) {
      if (formattedMrz.length > 90) {
        formattedMrz = formattedMrz.substring(0, 90);
      } else {
        formattedMrz = formattedMrz.padRight(90, '<');
      }
    }
    
    print('🧹 MRZ final concatenada: ${formattedMrz.length} caracteres');
    print('✅ MRZ formateada correctamente: "$formattedMrz"');
    
    // Verificación adicional de caracteres
    print('🔍 MRZ bytes: ${formattedMrz.codeUnits}');
    print('🔍 MRZ isEmpty: ${formattedMrz.isEmpty}');
    print('🔍 MRZ isNotEmpty: ${formattedMrz.isNotEmpty}');
    print('🔍 MRZ válida: ${formattedMrz.isNotEmpty && formattedMrz.length == 90}');
    
    return formattedMrz;
  }

  /// Procesa el lado reverso de una credencial (T2, T3)
  /// El tipo de credencial ya fue determinado por conteo de QRs en processCredentialWithSideDetection
  /// Incluye: QR (T2 y T3), código de barras (T2 y T3), MRZ (T2 y T3)
  static Future<Map<String, dynamic>> _processReversoSide(
    String imagePath,
    CredencialIneModel credential,
  ) async {
    final Map<String, String> reversoData = {
      'qrContent': '',
      'qrImagePath': '',
      'barcodeContent': '',
      'barcodeImagePath': '',
      'mrzContent': '',
      'mrzImagePath': '',
      'mrzDocumentNumber': '',
      'mrzNationality': '',
      'mrzBirthDate': '',
      'mrzExpiryDate': '',
      'mrzSex': '',
      'signatureHuellaImagePath': '',
    };

    print('🎯 Procesando lado reverso - tipo: ${credential.tipo}');
    
    // El tipo ya fue determinado correctamente en processCredentialWithSideDetection
    // usando conteo de QRs, no necesitamos re-evaluarlo aquí
    CredencialIneModel updatedCredential = credential;
    String processingType = credential.tipo;

    // Detectar y extraer código QR para credenciales T2 y T3 traseras
    if (processingType == 't2' || processingType == 't3') {
      print('🔍 Iniciando detección de código QR para credencial ${processingType.toUpperCase()} trasera...');
      print('DIAGNÓSTICO: Ejecutando detecciones porque el tipo es ${processingType} (válido para detecciones)');
      try {
        final credentialId = DateTime.now().millisecondsSinceEpoch.toString();
        final qrResult = await QrDetectionService.detectQrFromT2Credential(
          imagePath: imagePath,
          credentialId: credentialId,
        );
        
        reversoData['qrImagePath'] = qrResult['qrImagePath'] ?? '';
        
        if (qrResult['success'] == true) {
          reversoData['qrContent'] = qrResult['qrContent'] ?? '';
          print('📱 QR detectado exitosamente: ${reversoData['qrContent']!.length > 50 ? reversoData['qrContent']!.substring(0, 50) + '...' : reversoData['qrContent']}');
        } else {
          print('⚠️ No se pudo detectar código QR: ${qrResult['error']}');
          print('📷 Imagen QR guardada para revisión: ${reversoData['qrImagePath']}');
        }
      } catch (e) {
        print('❌ Error en detección de QR: $e');
      }

      // Detectar y extraer código de barras para credenciales T2 y T3
      print('🔍 Iniciando detección de código de barras para credencial ${processingType.toUpperCase()}...');
      try {
        final barcodeResult = await BarcodeDetectionService.detectBarcodeFromCredential(
          imagePath,
          processingType,
        );
        
        reversoData['barcodeImagePath'] = barcodeResult['imagePath'] ?? '';
        
        if (barcodeResult['success'] == true) {
          reversoData['barcodeContent'] = barcodeResult['content'] ?? '';
          print('📊 Código de barras detectado exitosamente: ${reversoData['barcodeContent']!.length > 30 ? reversoData['barcodeContent']!.substring(0, 30) + '...' : reversoData['barcodeContent']}');
          print('🎯 Método usado: ${barcodeResult['method']}, Confianza: ${barcodeResult['confidence']}');
        } else {
          print('⚠️ No se pudo detectar código de barras: ${barcodeResult['error']}');
          print('📷 Imagen de código de barras guardada para revisión: ${reversoData['barcodeImagePath']}');
        }
      } catch (e) {
        print('❌ Error en detección de código de barras: $e');
      }

    } else {
      print('DIAGNÓSTICO: Saltando detecciones de QR y códigos de barras - tipo no válido: ${processingType}');
      print('DIAGNÓSTICO: Las detecciones solo se ejecutan para tipos t2 y t3, pero se detectó tipo: ${processingType}');
    }

    // Detectar y extraer código MRZ para credenciales T2 y T3
    if (processingType == 't2' || processingType == 't3') {
      print('🔍 Iniciando detección de código MRZ para credencial ${processingType.toUpperCase()}...');
      try {
        final mrzResult = await MrzDetectionService.detectMrzFromCredential(
          imagePath,
          processingType,
        );
        
        reversoData['mrzImagePath'] = mrzResult['imagePath'] ?? '';
        
        if (mrzResult['success'] == true) {
          reversoData['mrzContent'] = mrzResult['content'] ?? '';
          final parsedData = mrzResult['parsedData'] as Map<String, dynamic>? ?? {};
          
          reversoData['mrzDocumentNumber'] = parsedData['documentNumber'] ?? '';
          reversoData['mrzNationality'] = parsedData['nationality'] ?? '';
          reversoData['mrzBirthDate'] = parsedData['birthDate'] ?? '';
          reversoData['mrzExpiryDate'] = parsedData['expiryDate'] ?? '';
          reversoData['mrzSex'] = parsedData['sex'] ?? '';
          
          print('🆔 Código MRZ detectado exitosamente: ${reversoData['mrzContent']!.length > 50 ? reversoData['mrzContent']!.substring(0, 50).replaceAll('\n', ' ') + '...' : reversoData['mrzContent']!.replaceAll('\n', ' ')}');
          print('🎯 Método usado: ${mrzResult['method']}, Confianza: ${mrzResult['confidence']}');
          print('📋 Datos extraídos - Doc: ${reversoData['mrzDocumentNumber']}, Nacionalidad: ${reversoData['mrzNationality']}, Sexo: ${reversoData['mrzSex']}');
        } else {
          print('⚠️ No se pudo detectar código MRZ: ${mrzResult['error']}');
          print('📷 Imagen MRZ guardada para revisión: ${reversoData['mrzImagePath']}');
        }
      } catch (e) {
        print('❌ Error en detección de código MRZ: $e');
      }
    }

    // Extraer región de firma y huella digital para credenciales T2 del lado reverso
    if (processingType == 't2') {
      print('🔍 Iniciando extracción de firma y huella digital para credencial T2 reverso...');
      try {
        // Cargar la imagen original
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          final originalImage = img.decodeImage(imageBytes);
          
          if (originalImage != null) {
            final signatureHuellaResult = _extractSignatureHuellaT2(originalImage, imagePath);
            
            reversoData['signatureHuellaImagePath'] = signatureHuellaResult['imagePath'] ?? '';
            
            if (reversoData['signatureHuellaImagePath']!.isNotEmpty) {
              print('✅ Región firma-huella extraída exitosamente: ${reversoData['signatureHuellaImagePath']}');
            } else {
              print('⚠️ No se pudo extraer la región firma-huella');
            }
          } else {
            print('❌ No se pudo decodificar la imagen para extracción firma-huella');
          }
        } else {
          print('❌ Archivo de imagen no encontrado: $imagePath');
        }
      } catch (e) {
        print('❌ Error en extracción de firma-huella: $e');
      }
    }

    return {
      'reversoData': reversoData,
      'updatedCredential': updatedCredential,
    };
  }

  /// Procesa el texto extraído y devuelve un modelo estructurado usando conteo de QRs
  static CredencialIneModel processCredentialTextWithQrCount(String extractedText, int qrCount) {
    if (!isIneCredential(extractedText)) {
      return CredencialIneModel.empty();
    }

    // Dividir el texto en líneas y limpiar
    final lines =
        extractedText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

    // Detectar tipo de credencial usando conteo de QRs
    final tipoCredencial = _detectCredentialTypeByQrCount(qrCount);
    print('🔍 Tipo detectado por conteo QR ($qrCount QRs): $tipoCredencial');

    // Verificar si este tipo de credencial debe ser procesado
    if (!_shouldProcessCredentialType(tipoCredencial)) {
      // Retornar modelo con solo el tipo detectado para credenciales no procesadas
      return CredencialIneModel(
        nombre: '',
        domicilio: '',
        claveElector: '',
        curp: '',
        fechaNacimiento: '',
        sexo: '',
        anoRegistro: '',
        seccion: '',
        vigencia: '',
        tipo: tipoCredencial,
        lado: '', // Se detectará posteriormente si es T2 o T3
        estado: '',
        municipio: '',
        localidad: '',
        photoPath: '', // No procesado
        signaturePath: '', // No procesado
        qrContent: '', // No procesado
        qrImagePath: '', // No procesado
        barcodeContent: '', // No procesado
        barcodeImagePath: '', // No procesado
        mrzContent: '', // No procesado
        mrzImagePath: '', // No procesado
        mrzDocumentNumber: '', // No procesado
        mrzNationality: '', // No procesado
        mrzSex: '', // No procesado
        mrzBirthDate: '', // No procesado
        mrzExpiryDate: '', // No procesado
        signatureHuellaImagePath: '', // No procesado
      );
    }

    // Filtrar líneas no deseadas
    final filteredLines = _filterUnwantedText(lines);

    // Extraer información adicional usando similitud de cadenas
    final additionalInfo = extractAdditionalInfoWithSimilarity(lines);

    // Extraer campos específicos solo para tipos procesables (t2 y t3)
    // Para t2, usar métodos específicos que manejan campos en la misma línea
    if (tipoCredencial == 't2') {
      // Extraer datos con validación y limpieza
      final nombre = _extractNombre(filteredLines);
      final claveElector = _extractClaveElector(filteredLines);
      final fechaNacimiento = _extractFechaNacimientoT2(filteredLines);
      final sexo = _extractSexo(filteredLines);
      final anoRegistro = _extractAnoRegistroT2(filteredLines);
      final seccion = _extractSeccionT2(filteredLines);
      final vigencia = _extractVigenciaT2(filteredLines);
      final estado = _extractEstado(filteredLines);
      final municipio = _extractMunicipioT2(filteredLines);
      final localidad = _extractLocalidadT2(filteredLines);

      // Aplicar normalización OCR al nombre antes de validación
      final nombreNormalizado = StringSimilarityUtils.normalizeOcrCharacters(nombre);
      
      return CredencialIneModel(
        nombre:
            ValidationUtils.isValidName(nombreNormalizado)
                ? ValidationUtils.cleanNormalizedName(nombreNormalizado)
                : nombreNormalizado,
        domicilio: _extractDomicilio(filteredLines),
        claveElector:
            ValidationUtils.isValidClaveElector(claveElector)
                ? ValidationUtils.cleanClaveElector(claveElector)
                : claveElector,
        curp: _extractCurpT2(filteredLines),
        fechaNacimiento:
            ValidationUtils.isValidBirthDate(fechaNacimiento)
                ? ValidationUtils.formatBirthDate(fechaNacimiento)
                : fechaNacimiento,
        sexo: ValidationUtils.isValidSex(sexo) ? sexo.toUpperCase() : sexo,
        anoRegistro: anoRegistro,
        seccion:
            ValidationUtils.isValidSection(seccion)
                ? ValidationUtils.cleanNumericCode(seccion)
                : seccion,
        vigencia: vigencia,
        tipo: tipoCredencial,
        lado: '', // Se detectará posteriormente con QR detection
        estado:
            ValidationUtils.isValidState(estado)
                ? ValidationUtils.cleanNumericCode(estado)
                : estado,
        municipio:
            ValidationUtils.isValidMunicipality(municipio)
                ? ValidationUtils.cleanNumericCode(municipio)
                : municipio,
        localidad:
            ValidationUtils.isValidLocality(localidad)
                ? ValidationUtils.cleanNumericCode(localidad)
                : localidad,
        photoPath: '', // Se establecerá en processCredentialWithSideDetection
        signaturePath: '', // Se establecerá para T3 en processCredentialWithSideDetection
        qrContent: '', // Se establecerá para T2 trasero en processCredentialWithSideDetection
        qrImagePath: '', // Se establecerá para T2 trasero en processCredentialWithSideDetection
        barcodeContent: '', // Se establecerá para T2 en processCredentialWithSideDetection
        barcodeImagePath: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzContent: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzImagePath: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzDocumentNumber: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzNationality: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzBirthDate: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzExpiryDate: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzSex: '', // Se establecerá para T2 en processCredentialWithSideDetection
        signatureHuellaImagePath: '', // Se establecerá para T2 reverso en processCredentialWithSideDetection
      );
    }

    // Para t3, usar métodos optimizados específicos
    if (tipoCredencial == 't3') {
      // Extraer datos específicos para T3
      final nombre = _extractNombre(filteredLines);
      // Aplicar normalización OCR al nombre antes de validación
      final nombreNormalizado = StringSimilarityUtils.normalizeOcrCharacters(nombre);
      
      return CredencialIneModel(
        nombre:
            ValidationUtils.isValidName(nombreNormalizado)
                ? ValidationUtils.cleanNormalizedName(nombreNormalizado)
                : nombreNormalizado,
        domicilio: _extractDomicilio(filteredLines),
        claveElector: _extractClaveElector(filteredLines),
        curp: _extractCurpT3(filteredLines),
        fechaNacimiento: _extractFechaNacimientoT3(filteredLines),
        sexo: _extractSexo(filteredLines),
        anoRegistro: _extractAnoRegistroT3(filteredLines),
        seccion: _extractSeccionT3(filteredLines),
        vigencia: _extractVigenciaT3(filteredLines),
        tipo: tipoCredencial,
        lado: '', // Se detectará posteriormente con QR detection
        estado: '',
        municipio: '',
        localidad: '',
        photoPath: '', // Se establecerá en processCredentialWithSideDetection
        signaturePath: '', // Se establecerá en processCredentialWithSideDetection
        qrContent: '', // No aplicable para T3
        qrImagePath: '', // No aplicable para T3
        barcodeContent: '', // No aplicable para T3
        barcodeImagePath: '', // No aplicable para T3
        mrzContent: '', // No aplicable para T3
        mrzImagePath: '', // No aplicable para T3
        mrzDocumentNumber: '', // No aplicable para T3
        mrzNationality: '', // No aplicable para T3
        mrzBirthDate: '', // No aplicable para T3
        mrzExpiryDate: '', // No aplicable para T3
        mrzSex: '', // No aplicable para T3
        signatureHuellaImagePath: '', // No aplicable para T3
      );
    }

    // Para otros tipos, usar métodos estándar
    final nombreStandard = _extractNombre(filteredLines);
    // Aplicar normalización OCR al nombre antes de validación
    final nombreStandardNormalizado = StringSimilarityUtils.normalizeOcrCharacters(nombreStandard);
    
    return CredencialIneModel(
      nombre:
          ValidationUtils.isValidName(nombreStandardNormalizado)
              ? ValidationUtils.cleanNormalizedName(nombreStandardNormalizado)
              : nombreStandardNormalizado,
      domicilio: _extractDomicilio(filteredLines),
      claveElector: _extractClaveElector(filteredLines),
      curp: _extractCurp(filteredLines),
      fechaNacimiento: _extractFechaNacimiento(filteredLines),
      sexo: _extractSexo(filteredLines),
      anoRegistro:
          additionalInfo['año_registro'] ?? _extractAnoRegistro(filteredLines),
      seccion: _extractSeccion(filteredLines),
      vigencia: additionalInfo['vigencia'] ?? _extractVigencia(filteredLines),
      tipo: tipoCredencial,
      lado: '', // Se detectará posteriormente si es necesario
      estado: tipoCredencial == 't2' ? _extractEstado(filteredLines) : '',
      municipio: tipoCredencial == 't2' ? _extractMunicipio(filteredLines) : '',
      localidad: tipoCredencial == 't2' ? _extractLocalidad(filteredLines) : '',
      photoPath: '', // Se establecerá en processCredentialWithSideDetection
      signaturePath: '', // No procesado
      qrContent: '', // Se establecerá para T2 trasero
      qrImagePath: '', // Se establecerá para T2 trasero
      barcodeContent: '', // Se establecerá para T2
      barcodeImagePath: '', // Se establecerá para T2
      mrzContent: '', // Se establecerá para T2
      mrzImagePath: '', // Se establecerá para T2
      mrzDocumentNumber: '', // Se establecerá para T2
      mrzNationality: '', // Se establecerá para T2
      mrzBirthDate: '', // Se establecerá para T2
      mrzExpiryDate: '', // Se establecerá para T2
      mrzSex: '', // Se establecerá para T2
      signatureHuellaImagePath: '', // Se establecerá para T2 reverso
    );
  }

  /// Procesa el texto extraído y devuelve un modelo estructurado (método legacy)
  static CredencialIneModel processCredentialText(String extractedText) {
    if (!isIneCredential(extractedText)) {
      return CredencialIneModel.empty();
    }

    // Dividir el texto en líneas y limpiar
    final lines =
        extractedText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

    // Detectar tipo de credencial primero (método legacy basado en texto)
    final tipoCredencial = _detectCredentialType(lines);

    // Verificar si este tipo de credencial debe ser procesado
    if (!_shouldProcessCredentialType(tipoCredencial)) {
      // Retornar modelo con solo el tipo detectado para credenciales no procesadas
      return CredencialIneModel(
        nombre: '',
        domicilio: '',
        claveElector: '',
        curp: '',
        fechaNacimiento: '',
        sexo: '',
        anoRegistro: '',
        seccion: '',
        vigencia: '',
        tipo: tipoCredencial,
        lado: '', // Se detectará posteriormente si es T2 o T3
        estado: '',
        municipio: '',
        localidad: '',
        photoPath: '', // No procesado
        signaturePath: '', // No procesado
        qrContent: '', // No procesado
        qrImagePath: '', // No procesado
        barcodeContent: '', // No procesado
        barcodeImagePath: '', // No procesado
        mrzContent: '', // No procesado
        mrzImagePath: '', // No procesado
        mrzDocumentNumber: '', // No procesado
        mrzNationality: '', // No procesado
        mrzBirthDate: '', // No procesado
        mrzExpiryDate: '', // No procesado
        mrzSex: '', // No procesado
        signatureHuellaImagePath: '', // No procesado
      );
    }

    // Filtrar líneas no deseadas
    final filteredLines = _filterUnwantedText(lines);

    // Extraer información adicional usando similitud de cadenas
    final additionalInfo = extractAdditionalInfoWithSimilarity(lines);

    // Extraer campos específicos solo para tipos procesables (t2 y t3)
    // Para t2, usar métodos específicos que manejan campos en la misma línea
    if (tipoCredencial == 't2') {
      // Extraer datos con validación y limpieza
      final nombre = _extractNombre(filteredLines);
      final claveElector = _extractClaveElector(filteredLines);
      final fechaNacimiento = _extractFechaNacimientoT2(filteredLines);
      final sexo = _extractSexo(filteredLines);
      final anoRegistro = _extractAnoRegistroT2(filteredLines);
      final seccion = _extractSeccionT2(filteredLines);
      final vigencia = _extractVigenciaT2(filteredLines);
      final estado = _extractEstado(filteredLines);
      final municipio = _extractMunicipioT2(filteredLines);
      final localidad = _extractLocalidadT2(filteredLines);

      // Aplicar normalización OCR al nombre antes de validación
      final nombreNormalizado = StringSimilarityUtils.normalizeOcrCharacters(nombre);
      
      return CredencialIneModel(
        nombre:
            ValidationUtils.isValidName(nombreNormalizado)
                ? ValidationUtils.cleanNormalizedName(nombreNormalizado)
                : nombreNormalizado,
        domicilio: _extractDomicilio(filteredLines),
        claveElector:
            ValidationUtils.isValidClaveElector(claveElector)
                ? ValidationUtils.cleanClaveElector(claveElector)
                : claveElector,
        curp: _extractCurpT2(filteredLines),
        fechaNacimiento:
            ValidationUtils.isValidBirthDate(fechaNacimiento)
                ? ValidationUtils.formatBirthDate(fechaNacimiento)
                : fechaNacimiento,
        sexo: ValidationUtils.isValidSex(sexo) ? sexo.toUpperCase() : sexo,
        anoRegistro: anoRegistro,
        seccion:
            ValidationUtils.isValidSection(seccion)
                ? ValidationUtils.cleanNumericCode(seccion)
                : seccion,
        vigencia: vigencia,
        tipo: tipoCredencial,
        lado: '', // Se detectará posteriormente con QR detection
        estado:
            ValidationUtils.isValidState(estado)
                ? ValidationUtils.cleanNumericCode(estado)
                : estado,
        municipio:
            ValidationUtils.isValidMunicipality(municipio)
                ? ValidationUtils.cleanNumericCode(municipio)
                : municipio,
        localidad:
            ValidationUtils.isValidLocality(localidad)
                ? ValidationUtils.cleanNumericCode(localidad)
                : localidad,
        photoPath: '', // Se establecerá en processCredentialWithSideDetection
        signaturePath: '', // Se establecerá para T3 en processCredentialWithSideDetection
        qrContent: '', // Se establecerá para T2 trasero en processCredentialWithSideDetection
        qrImagePath: '', // Se establecerá para T2 trasero en processCredentialWithSideDetection
        barcodeContent: '', // Se establecerá para T2 en processCredentialWithSideDetection
        barcodeImagePath: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzContent: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzImagePath: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzDocumentNumber: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzNationality: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzBirthDate: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzExpiryDate: '', // Se establecerá para T2 en processCredentialWithSideDetection
        mrzSex: '', // Se establecerá para T2 en processCredentialWithSideDetection
        signatureHuellaImagePath: '', // Se establecerá para T2 reverso en processCredentialWithSideDetection
      );
    }

    // Para t3, usar métodos optimizados específicos
    if (tipoCredencial == 't3') {
      final nombre = _extractNombre(filteredLines);
      // Aplicar normalización OCR al nombre antes de validación
      final nombreNormalizado = StringSimilarityUtils.normalizeOcrCharacters(nombre);
      
      return CredencialIneModel(
        nombre:
            ValidationUtils.isValidName(nombreNormalizado)
                ? ValidationUtils.cleanNormalizedName(nombreNormalizado)
                : nombreNormalizado,
        domicilio: _extractDomicilio(filteredLines),
        claveElector: _extractClaveElector(filteredLines),
        curp: _extractCurpT3(filteredLines),
        fechaNacimiento: _extractFechaNacimientoT3(filteredLines),
        sexo: _extractSexo(filteredLines),
        anoRegistro: _extractAnoRegistroT3(filteredLines),
        seccion: _extractSeccionT3(filteredLines),
        vigencia: _extractVigenciaT3(filteredLines),
        tipo: tipoCredencial,
        lado: '', // Se detectará posteriormente con QR detection
        estado: '',
        municipio: '',
        localidad: '',
        photoPath: '', // Se establecerá en processCredentialWithSideDetection
        signaturePath: '', // Se establecerá en processCredentialWithSideDetection
        qrContent: '', // No aplicable para T3
        qrImagePath: '', // No aplicable para T3
        barcodeContent: '', // No aplicable para T3
        barcodeImagePath: '', // No aplicable para T3
        mrzContent: '', // No aplicable para T3
        mrzImagePath: '', // No aplicable para T3
        mrzDocumentNumber: '', // No aplicable para T3
        mrzNationality: '', // No aplicable para T3
        mrzBirthDate: '', // No aplicable para T3
        mrzExpiryDate: '', // No aplicable para T3
        mrzSex: '', // No aplicable para T3
        signatureHuellaImagePath: '', // No aplicable para T3
      );
    }

    // Para otros tipos, usar métodos estándar
    final nombreStandard = _extractNombre(filteredLines);
    // Aplicar normalización OCR al nombre antes de validación
    final nombreStandardNormalizado = StringSimilarityUtils.normalizeOcrCharacters(nombreStandard);
    
    return CredencialIneModel(
      nombre:
          ValidationUtils.isValidName(nombreStandardNormalizado)
              ? ValidationUtils.cleanNormalizedName(nombreStandardNormalizado)
              : nombreStandardNormalizado,
      domicilio: _extractDomicilio(filteredLines),
      claveElector: _extractClaveElector(filteredLines),
      curp: _extractCurp(filteredLines),
      fechaNacimiento: _extractFechaNacimiento(filteredLines),
      sexo: _extractSexo(filteredLines),
      anoRegistro:
          additionalInfo['año_registro'] ?? _extractAnoRegistro(filteredLines),
      seccion: _extractSeccion(filteredLines),
      vigencia: additionalInfo['vigencia'] ?? _extractVigencia(filteredLines),
      tipo: tipoCredencial,
      lado: '', // Se detectará posteriormente si es necesario
      estado: tipoCredencial == 't2' ? _extractEstado(filteredLines) : '',
      municipio: tipoCredencial == 't2' ? _extractMunicipio(filteredLines) : '',
      localidad: tipoCredencial == 't2' ? _extractLocalidad(filteredLines) : '',
      photoPath: '', // Se establecerá en processCredentialWithSideDetection
      signaturePath: '', // No procesado
      qrContent: '', // Se establecerá para T2 trasero
      qrImagePath: '', // Se establecerá para T2 trasero
      barcodeContent: '', // Se establecerá para T2
      barcodeImagePath: '', // Se establecerá para T2
      mrzContent: '', // Se establecerá para T2
      mrzImagePath: '', // Se establecerá para T2
      mrzDocumentNumber: '', // Se establecerá para T2
      mrzNationality: '', // Se establecerá para T2
      mrzBirthDate: '', // Se establecerá para T2
      mrzExpiryDate: '', // Se establecerá para T2
      mrzSex: '', // Se establecerá para T2
      signatureHuellaImagePath: '', // Se establecerá para T2 reverso
    );
  }

  /// Filtra textos institucionales no deseados de las líneas
  static List<String> _filterUnwantedText(List<String> lines) {
    return lines.where((line) {
      final upperLine = line.toUpperCase();
      return !_unwantedTexts.any((unwanted) {
        // No filtrar líneas que contengan información de sexo
        if (unwanted.toUpperCase() == 'SEXO' &&
            (upperLine.contains('SEXO H') ||
                upperLine.contains('SEXO M') ||
                upperLine.contains('H') ||
                upperLine.contains('M'))) {
          return false;
        }
        return upperLine.contains(unwanted.toUpperCase()) &&
            line.length <= unwanted.length + 5;
      });
    }).toList();
  }

  /// Filtra etiquetas de referencia del resultado final
  static List<String> _filterReferenceLabels(List<String> lines) {
    return lines.where((line) {
      final upperLine = line.toUpperCase();
      return !_referenceLabels.any((label) {
        return upperLine.contains(label.toUpperCase()) &&
            line.length <= label.length + 5;
      });
    }).toList();
  }

  /// Encuentra la mejor coincidencia de una etiqueta usando algoritmos de similitud
  static Map<String, dynamic> _findLabelWithSimilarity(
    List<String> lines,
    List<String> targetLabels, {
    double threshold = 0.7,
  }) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toUpperCase();

      // Buscar coincidencias exactas primero
      for (final label in targetLabels) {
        // Habilitar normalización OCR para etiquetas críticas
        final criticalLabels = [
          'VIGENCIA',
          'NOMBRE',
          'DOMICILIO',
          'SECCION',
          'SECCIÓN',
        ];
        final shouldNormalizeOcr = targetLabels.any(
          (label) => criticalLabels.any(
            (critical) => label.toUpperCase().contains(critical),
          ),
        );

        final normalizedLabel =
            shouldNormalizeOcr
                ? StringSimilarityUtils.normalizeOcrCharacters(label)
                : label.toUpperCase();
        final normalizedLine =
            shouldNormalizeOcr
                ? StringSimilarityUtils.normalizeOcrCharacters(line)
                : line;

        if (normalizedLine.contains(normalizedLabel)) {
          return {
            'found': true,
            'index': i,
            'line': lines[i],
            'label': label,
            'similarity': 1.0,
            'method': 'exact',
          };
        }
      }

      // Buscar usando similitud de cadenas
      final words = line.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length < 3) continue; // Ignorar palabras muy cortas

        // Habilitar normalización OCR para etiquetas críticas
        final criticalLabels = [
          'VIGENCIA',
          'NOMBRE',
          'DOMICILIO',
          'SECCION',
          'SECCIÓN',
        ];
        final shouldNormalizeOcr = targetLabels.any(
          (label) => criticalLabels.any(
            (critical) => label.toUpperCase().contains(critical),
          ),
        );

        // Aplicar normalización OCR al texto de entrada si es necesario
        final processedWord =
            shouldNormalizeOcr
                ? StringSimilarityUtils.normalizeOcrCharacters(word)
                : word;

        final result = StringSimilarityUtils.findBestMatch(
          processedWord,
          targetLabels,
          threshold: threshold,
          useJaroWinkler: true,
          normalizeOcr: shouldNormalizeOcr,
        );

        if (result['found'] == true) {
          return {
            'found': true,
            'index': i,
            'line': lines[i],
            'label': result['match'],
            'similarity': result['score'],
            'method': 'similarity',
            'original_word': word,
          };
        }
      }
    }

    return {
      'found': false,
      'index': -1,
      'line': '',
      'label': '',
      'similarity': 0.0,
      'method': 'none',
    };
  }

  /// Extrae el nombre de la credencial
  static String _extractNombre(List<String> lines) {
    List<String> nombreLines = [];

    // Método 1: Usar "CREDENCIAL PARA VOTAR" como punto de referencia
    nombreLines = _extractNombreByCredentialReference(lines);

    // Método 2: Buscar variantes de la etiqueta NOMBRE/NOMERE
    if (nombreLines.isEmpty) {
      nombreLines = _extractNombreByLabel(lines);
    }

    // Método 3: Fallback con el método anterior
    if (nombreLines.isEmpty) {
      nombreLines = _extractNombreFallback(lines);
    }

    return nombreLines.join(' ').trim();
  }

  /// Extrae el nombre usando "CREDENCIAL PARA VOTAR" como referencia
  static List<String> _extractNombreByCredentialReference(List<String> lines) {
    List<String> nombreLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final upperLine = line.toUpperCase();

      // Buscar "CREDENCIAL" o "VOTAR" como punto de referencia
      if (upperLine.contains('CREDENCIAL') || upperLine.contains('VOTAR')) {
        // La siguiente línea después de "CREDENCIAL PARA VOTAR" contiene la etiqueta del nombre
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].toUpperCase();

          // Verificar si la siguiente línea contiene variantes de NOMBRE
          if (nextLine.contains('NOMBRE') ||
              nextLine.contains('NOMERE') ||
              nextLine.contains('NOMRE')) {
            // Extraer las siguientes 3 líneas después de la etiqueta del nombre
            for (int j = i + 2; j < lines.length && j <= i + 4; j++) {
              final dataLine = lines[j].trim();

              if (dataLine.isNotEmpty) {
                // Filtrar etiquetas de referencia del resultado final
                final filteredData = _filterReferenceLabels([dataLine]);
                if (filteredData.isNotEmpty) {
                  nombreLines.add(filteredData.first.toUpperCase());
                }
              }
            }
            break;
          }
        }
      }
    }

    return nombreLines;
  }

  /// Extrae el nombre buscando directamente las variantes de la etiqueta
  static List<String> _extractNombreByLabel(List<String> lines) {
    List<String> nombreLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Buscar variantes de la etiqueta NOMBRE
      if (line.contains('NOMBRE') ||
          line.contains('NOMERE') ||
          line.contains('NOMRE')) {
        // Extraer exactamente las siguientes 3 líneas después de encontrar la etiqueta
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();

          if (nextLine.isNotEmpty) {
            // Filtrar etiquetas de referencia del resultado final
            final filteredData = _filterReferenceLabels([nextLine]);
            if (filteredData.isNotEmpty) {
              nombreLines.add(filteredData.first.toUpperCase());
            }
          }
        }
        break;
      }
    }

    return nombreLines;
  }

  /// Método fallback para extraer el nombre
  static List<String> _extractNombreFallback(List<String> lines) {
    List<String> nombreLines = [];

    for (int i = 0; i < lines.length && nombreLines.length < 3; i++) {
      final line = lines[i].trim();

      if (RegExp(r'^[A-Za-zÀ-ÿ\s]+$').hasMatch(line) &&
          line.length > 2 &&
          line.length < 50) {
        final upperLine = line.toUpperCase();
        // Excluir textos institucionales y etiquetas de referencia
        if (!_unwantedTexts.any((unwanted) => upperLine.contains(unwanted)) &&
            !_referenceLabels.any((label) => upperLine.contains(label))) {
          nombreLines.add(line.toUpperCase());
        }
      }
    }

    return nombreLines;
  }

  /// Extrae el domicilio
  static String _extractDomicilio(List<String> lines) {
    List<String> domicilioLines = [];

    // Buscar la etiqueta DOMICILIO (con variantes) y extraer exactamente las siguientes 3 líneas
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Buscar variantes de DOMICILIO (incluyendo errores de OCR como 'DOMICILIo')
      if (line.contains('DOMICILIO') ||
          line.contains('DOMICILIo') ||
          line.contains('DOMICILI')) {
        // Extraer exactamente las siguientes 3 líneas después de encontrar DOMICILIO
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();

          if (nextLine.isNotEmpty && !_isMrzLine(nextLine)) {
            // Filtrar etiquetas de referencia del resultado final
            final filteredData = _filterReferenceLabels([nextLine]);
            if (filteredData.isNotEmpty) {
              domicilioLines.add(filteredData.first.toUpperCase());
            }
          }
        }
        break;
      }
    }

    // Si no se encontró la etiqueta DOMICILIO, usar el método anterior como fallback
    if (domicilioLines.isEmpty) {
      for (final line in lines) {
        final upperLine = line.toUpperCase();
        // Buscar líneas que contengan direcciones pero detener en CLAVE DE ELECTOR
        if (upperLine.contains('CLAVE DE ELECTOR') ||
            upperLine.contains('CLAVE ELECTOR')) {
          break;
        }

        if ((upperLine.contains('AV ') ||
                upperLine.contains('CALLE ') ||
                upperLine.contains('COL ') ||
                RegExp(r'\d+').hasMatch(line)) &&
            line.length > 10 &&
            !upperLine.contains('CURP') &&
            !upperLine.contains('SEXO') &&
            !upperLine.contains('NOMBRE') &&
            !_isMrzLine(line)) {
          domicilioLines.add(line.toUpperCase());
        }
      }
    }

    return domicilioLines.join(' ').trim();
  }

  /// Verifica si una línea es parte de un código MRZ
  /// Los códigos MRZ tienen exactamente 30 caracteres y patrones específicos
  static bool _isMrzLine(String line) {
    final cleanLine = line.trim().replaceAll(' ', '');
    
    // Verificar longitud exacta de 30 caracteres (característica del MRZ)
    if (cleanLine.length != 30) return false;
    
    // Verificar patrones típicos del MRZ
    // Línea 1: Comienza con código de documento (I, A, C, P, V) y contiene MEX
    if (RegExp(r'^[IACPV]').hasMatch(cleanLine) && cleanLine.contains('MEX')) {
      return true;
    }
    
    // Línea 2: Contiene fecha de nacimiento (6 dígitos) y sexo (M/F)
    if (RegExp(r'\d{6}').hasMatch(cleanLine) && RegExp(r'[MF]').hasMatch(cleanLine)) {
      return true;
    }
    
    // Línea 3: Contiene principalmente letras y caracteres de relleno '<'
    if (RegExp(r'^[A-Z<]+$').hasMatch(cleanLine) && cleanLine.contains('<')) {
      return true;
    }
    
    // Verificar alta densidad de caracteres de relleno '<' (típico del MRZ)
    final fillCharCount = cleanLine.split('<').length - 1;
    if (fillCharCount >= 5) {
      return true;
    }
    
    return false;
  }

  /// Extrae la clave de elector
  static String _extractClaveElector(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta CLAVE DE ELECTOR, extraer el dato de la misma línea
      if (line.contains('CLAVE DE ELECTOR') || line.contains('CLAVE ELECTOR')) {
        // Buscar el patrón después de la etiqueta en la misma línea
        final match = RegExp(
          r'CLAVE\s+DE\s+ELECTOR\s+([A-Z0-9]{18})',
        ).firstMatch(line);
        if (match != null) {
          return match.group(1) ?? '';
        }

        // Fallback: buscar cualquier secuencia de 18 caracteres alfanuméricos en la línea
        final fallbackMatch = RegExp(r'[A-Z0-9]{18}').firstMatch(line);
        if (fallbackMatch != null) {
          return fallbackMatch.group(0) ?? '';
        }

        // Si no está en la misma línea, buscar en las siguientes líneas como fallback
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim().toUpperCase();
          final nextMatch = RegExp(r'[A-Z0-9]{18}').firstMatch(nextLine);
          if (nextMatch != null) {
            return nextMatch.group(0) ?? '';
          }
        }
      }

      // También buscar directamente en la línea actual
      final match = RegExp(r'[A-Z0-9]{18}').firstMatch(line);
      if (match != null && !line.contains('CURP')) {
        return match.group(0) ?? '';
      }
    }
    return '';
  }

  /// Extrae el CURP
  static String _extractCurp(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta CURP, buscar exactamente en la línea siguiente
      if (line.contains('CURP') && i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim().toUpperCase();

        // Buscar patrón de CURP (18 caracteres) sin guiones ni caracteres especiales
        final match = RegExp(
          r'[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]',
        ).firstMatch(nextLine);
        if (match != null) {
          return match.group(0) ?? '';
        }

        // Buscar CURP con guiones o espacios y limpiarlos
        final matchWithSeparators = RegExp(
          r'[A-Z]{4}[0-9]{6}[-\s]*[HM][A-Z]{5}[0-9A-Z][0-9]',
        ).firstMatch(nextLine);
        if (matchWithSeparators != null) {
          return (matchWithSeparators.group(0) ?? '').replaceAll(
            RegExp(r'[-\s]'),
            '',
          );
        }

        // Si la línea siguiente no está vacía pero no coincide con el patrón, devolverla tal como está
        if (nextLine.isNotEmpty) {
          return nextLine;
        }
      }

      // También buscar directamente en la línea actual como fallback
      final match = RegExp(
        r'[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]',
      ).firstMatch(line);
      if (match != null) {
        return match.group(0) ?? '';
      }
    }
    return '';
  }

  /// Extrae el CURP específicamente para credenciales t3
  /// Optimizado para el formato específico de credenciales T3
  static String _extractCurpT3(List<String> lines) {
    // Patrón CURP: 18 caracteres alfanuméricos específicos
    final curpPattern = RegExp(r'\b[A-Z]{4}\d{6}[HM][A-Z]{5}\d{2}\b');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Patrón 1: Buscar línea que contenga "CURP" seguida del código
      if (line.contains('CURP')) {
        // Buscar CURP en la misma línea
        final match = curpPattern.firstMatch(line);
        if (match != null) {
          return match.group(0) ?? '';
        }

        // Buscar CURP en las siguientes 2 líneas
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].toUpperCase();
          final nextMatch = curpPattern.firstMatch(nextLine);
          if (nextMatch != null) {
            return nextMatch.group(0) ?? '';
          }
        }
      }

      // Patrón 2: Buscar CURP en líneas que contengan solo el código (sin etiqueta)
      // Esto es común en T3 donde el CURP puede aparecer en una línea separada
      final match = curpPattern.firstMatch(line);
      if (match != null) {
        final curp = match.group(0) ?? '';
        // Validación adicional: verificar que la línea no contenga otros datos importantes
        if (!line.contains('VIGENCIA') &&
            !line.contains('EMISIÓN') &&
            !line.contains('EMISION') &&
            !line.contains('SECCIÓN') &&
            !line.contains('SECCION')) {
          return curp;
        }
      }

      // Patrón 3: Buscar patrones de CURP con posibles errores de OCR
      // Común en T3 donde la calidad de impresión puede variar
      final curpWithErrorsPattern = RegExp(
        r'\b[A-Z0-9]{4}\d{6}[HM][A-Z0-9]{5}\d{2}\b',
      );
      final errorMatch = curpWithErrorsPattern.firstMatch(line);
      if (errorMatch != null) {
        final potentialCurp = errorMatch.group(0) ?? '';
        // Aplicar correcciones comunes de OCR
        String correctedCurp = potentialCurp
            .replaceAll('0', 'O')
            .replaceAll('1', 'I')
            .replaceAll('5', 'S')
            .replaceAll('8', 'B');

        // Verificar si después de las correcciones coincide con el patrón CURP
        if (curpPattern.hasMatch(correctedCurp)) {
          return correctedCurp;
        }
      }
    }

    // Fallback: usar método estándar
    return _extractCurp(lines);
  }

  /// Extrae el CURP específicamente para credenciales t2
  static String _extractCurpT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Para t2, CURP está en la misma línea que la etiqueta
      if (line.contains('CURP')) {
        // Buscar patrón de CURP en la misma línea
        final match = RegExp(
          r'CURP\s+([A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9])',
        ).firstMatch(line);
        if (match != null) {
          return match.group(1) ?? '';
        }

        // Buscar cualquier patrón de CURP en la línea
        final fallbackMatch = RegExp(
          r'[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]',
        ).firstMatch(line);
        if (fallbackMatch != null) {
          return fallbackMatch.group(0) ?? '';
        }
      }
    }
    return '';
  }

  /// Extrae la fecha de nacimiento
  static String _extractFechaNacimiento(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta FECHA DE NACIMIENTO, buscar en líneas siguientes
      if (line.contains('FECHA DE NACIMIENTO') || line.contains('NACIMIENTO')) {
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          // Buscar patrón de fecha DD/MM/YYYY
          final match = RegExp(
            r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b',
          ).firstMatch(nextLine);
          if (match != null) {
            final day = match.group(1)?.padLeft(2, '0') ?? '';
            final month = match.group(2)?.padLeft(2, '0') ?? '';
            final year = match.group(3) ?? '';
            return '$day/$month/$year';
          }
        }
      }

      // También buscar directamente en la línea actual
      final match = RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b').firstMatch(line);
      if (match != null) {
        final day = match.group(1)?.padLeft(2, '0') ?? '';
        final month = match.group(2)?.padLeft(2, '0') ?? '';
        final year = match.group(3) ?? '';
        return '$day/$month/$year';
      }
    }
    return '';
  }

  /// Extrae la fecha de nacimiento específicamente para credenciales t3
  /// Optimizado para el formato específico de credenciales T3
  static String _extractFechaNacimientoT3(List<String> lines) {
    // Patrones de fecha comunes en T3
    final datePatterns = [
      RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b'), // DD/MM/YYYY
      RegExp(r'\b(\d{1,2})-(\d{1,2})-(\d{4})\b'), // DD-MM-YYYY
      RegExp(r'\b(\d{4})/(\d{1,2})/(\d{1,2})\b'), // YYYY/MM/DD
      RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b'), // YYYY-MM-DD
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Patrón 1: Buscar líneas que contengan "NACIMIENTO" o "NAC"
      if (line.contains('NACIMIENTO') || line.contains('NAC')) {
        // Buscar fecha en la misma línea
        for (final pattern in datePatterns) {
          final match = pattern.firstMatch(line);
          if (match != null &&
              ValidationUtils.isValidBirthDate(match.group(0) ?? '')) {
            return ValidationUtils.formatBirthDate(match.group(0) ?? '');
          }
        }

        // Buscar fecha en las siguientes 2 líneas
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j];
          for (final pattern in datePatterns) {
            final match = pattern.firstMatch(nextLine);
            if (match != null &&
                ValidationUtils.isValidBirthDate(match.group(0) ?? '')) {
              return ValidationUtils.formatBirthDate(match.group(0) ?? '');
            }
          }
        }
      }

      // Patrón 2: Buscar fechas que no sean de vigencia o emisión
      // Común en T3 donde la fecha puede aparecer sin etiqueta clara
      if (!line.contains('VIGENCIA') &&
          !line.contains('EMISIÓN') &&
          !line.contains('EMISION') &&
          !line.contains('REGISTRO')) {
        for (final pattern in datePatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final dateStr = match.group(0) ?? '';
            if (ValidationUtils.isValidBirthDate(dateStr)) {
              return ValidationUtils.formatBirthDate(dateStr);
            }
          }
        }
      }

      // Patrón 3: Buscar fechas con posibles errores de OCR
      // Común en T3 donde la calidad puede variar
      final ocrErrorPattern = RegExp(
        r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})\b',
      );
      final errorMatch = ocrErrorPattern.firstMatch(line);
      if (errorMatch != null) {
        final day = errorMatch.group(1) ?? '';
        final month = errorMatch.group(2) ?? '';
        final year = errorMatch.group(3) ?? '';
        final dateStr = '$day/$month/$year';

        if (ValidationUtils.isValidBirthDate(dateStr) &&
            !line.contains('VIGENCIA') &&
            !line.contains('EMISIÓN') &&
            !line.contains('EMISION')) {
          return ValidationUtils.formatBirthDate(dateStr);
        }
      }
    }

    // Fallback: usar método estándar
    return _extractFechaNacimiento(lines);
  }

  /// Extrae la fecha de nacimiento específicamente para credenciales t2
  /// Maneja el formato especial donde puede faltar "/" y necesita normalización numérica
  static String _extractFechaNacimientoT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta FECHA DE NACIMIENTO, buscar en líneas siguientes
      if (line.contains('FECHA DE NACIMIENTO') || line.contains('NACIMIENTO')) {
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          final processedDate = _processBirthDateT2(nextLine);
          if (processedDate.isNotEmpty) {
            return processedDate;
          }
        }
      }

      // También buscar directamente en la línea actual
      final processedDate = _processBirthDateT2(line);
      if (processedDate.isNotEmpty) {
        return processedDate;
      }
    }
    return '';
  }

  /// Procesa y normaliza una fecha de nacimiento para credenciales t2
  /// Maneja formatos como "1710/1997", "17101997", etc.
  static String _processBirthDateT2(String text) {
    if (text.isEmpty) return '';

    // Normalizar caracteres numéricos (OCR puede confundir algunos caracteres)
    String normalizedText = text
        .replaceAll(RegExp(r'[Oo]'), '0') // O -> 0
        .replaceAll(RegExp(r'[Il|]'), '1') // I, l, | -> 1
        .replaceAll(RegExp(r'[S]'), '5') // S -> 5 (en algunos casos)
        .replaceAll(RegExp(r'[B]'), '8'); // B -> 8 (en algunos casos)

    // Remover todos los caracteres que no sean dígitos
    String digitsOnly = normalizedText.replaceAll(RegExp(r'[^0-9]'), '');

    // Verificar si tenemos exactamente 8 dígitos (DDMMYYYY)
    if (digitsOnly.length == 8) {
      final day = digitsOnly.substring(0, 2);
      final month = digitsOnly.substring(2, 4);
      final year = digitsOnly.substring(4, 8);

      // Validar rangos básicos
      final dayInt = int.tryParse(day);
      final monthInt = int.tryParse(month);
      final yearInt = int.tryParse(year);

      if (dayInt != null &&
          monthInt != null &&
          yearInt != null &&
          dayInt >= 1 &&
          dayInt <= 31 &&
          monthInt >= 1 &&
          monthInt <= 12 &&
          yearInt >= 1900 &&
          yearInt <= 2100) {
        return '$day/$month/$year';
      }
    }

    // Buscar patrón de fecha con separadores existentes DD/MM/YYYY
    final match = RegExp(
      r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})\b',
    ).firstMatch(normalizedText);
    if (match != null) {
      final day = match.group(1)?.padLeft(2, '0') ?? '';
      final month = match.group(2)?.padLeft(2, '0') ?? '';
      final year = match.group(3) ?? '';

      // Validar rangos básicos
      final dayInt = int.tryParse(day);
      final monthInt = int.tryParse(month);
      final yearInt = int.tryParse(year);

      if (dayInt != null &&
          monthInt != null &&
          yearInt != null &&
          dayInt >= 1 &&
          dayInt <= 31 &&
          monthInt >= 1 &&
          monthInt <= 12 &&
          yearInt >= 1900 &&
          yearInt <= 2100) {
        return '$day/$month/$year';
      }
    }

    return '';
  }

  /// Extrae el sexo
  static String _extractSexo(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upperLine = line.toUpperCase();

      // Buscar patrones de sexo
      if (upperLine.contains('SEXO')) {
        // Verificar si H o M están en la misma línea
        if (upperLine.contains('SEXO H') || upperLine.contains('H')) {
          return 'H';
        } else if (upperLine.contains('SEXO M') || upperLine.contains('M')) {
          return 'M';
        }

        // Buscar en las siguientes 2 líneas
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim().toUpperCase();
          if (nextLine == 'H' || nextLine.contains('H')) {
            return 'H';
          } else if (nextLine == 'M' || nextLine.contains('M')) {
            return 'M';
          }
        }
      }

      // Buscar líneas que solo contengan H o M
      final trimmedLine = line.trim().toUpperCase();
      if (trimmedLine == 'H') {
        return 'H';
      } else if (trimmedLine == 'M') {
        return 'M';
      }
    }
    return '';
  }

  /// Extrae el año de registro
  static String _extractAnoRegistro(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta AÑO DE REGISTRO, buscar en líneas siguientes
      if (line.contains('AÑO DE REGISTRO') ||
          line.contains('ANO DE REGISTRO')) {
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          // Buscar patrón YYYY MM (año y mes)
          final match = RegExp(r'(20\d{2})\s+(\d{2})').firstMatch(nextLine);
          if (match != null) {
            return '${match.group(1)} ${match.group(2)}';
          }
          // Buscar solo año de 4 dígitos
          final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(nextLine);
          if (yearMatch != null) {
            return yearMatch.group(0) ?? '';
          }
        }
      }

      // Buscar patrón YYYY MM en cualquier línea
      final match = RegExp(r'(20\d{2})\s+(\d{2})').firstMatch(line);
      if (match != null && !line.contains('/')) {
        return '${match.group(1)} ${match.group(2)}';
      }
    }
    return '';
  }

  /// Extrae el año de registro específicamente para credenciales t3
  /// Optimizado para el formato específico de credenciales T3
  static String _extractAnoRegistroT3(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Patrón 1: Buscar líneas que contengan "REGISTRO" o "REG"
      if (line.contains('REGISTRO') || line.contains('REG')) {
        // Buscar año completo con código en la misma línea (formato: YYYY XX)
        final fullYearMatch = RegExp(
          r'\b(19|20)\d{2}\s+\d{2}\b',
        ).firstMatch(line);
        if (fullYearMatch != null) {
          final fullYear = fullYearMatch.group(0) ?? '';
          final yearPart = fullYear.split(' ')[0];
          final yearInt = int.tryParse(yearPart);
          if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
            return fullYear;
          }
        }

        // Si no encuentra el formato completo, buscar solo el año
        final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(line);
        if (yearMatch != null) {
          final year = yearMatch.group(0) ?? '';
          final yearInt = int.tryParse(year);
          if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
            return year;
          }
        }

        // Buscar año completo en las siguientes 2 líneas
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j];
          // Primero buscar formato completo YYYY XX
          final nextFullYearMatch = RegExp(
            r'\b(19|20)\d{2}\s+\d{2}\b',
          ).firstMatch(nextLine);
          if (nextFullYearMatch != null) {
            final fullYear = nextFullYearMatch.group(0) ?? '';
            final yearPart = fullYear.split(' ')[0];
            final yearInt = int.tryParse(yearPart);
            if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
              return fullYear;
            }
          }

          // Si no encuentra formato completo, buscar solo año
          final nextYearMatch = RegExp(
            r'\b(19|20)\d{2}\b',
          ).firstMatch(nextLine);
          if (nextYearMatch != null) {
            final year = nextYearMatch.group(0) ?? '';
            final yearInt = int.tryParse(year);
            if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
              return year;
            }
          }
        }
      }

      // Patrón 2: Buscar años que no sean de vigencia o nacimiento
      // Común en T3 donde el año de registro puede aparecer sin etiqueta clara
      if (!line.contains('VIGENCIA') &&
          !line.contains('NACIMIENTO') &&
          !line.contains('EMISIÓN') &&
          !line.contains('EMISION') &&
          !line.contains('/')) {
        // Primero buscar formato completo YYYY XX
        final fullYearMatch = RegExp(
          r'\b(19|20)\d{2}\s+\d{2}\b',
        ).firstMatch(line);
        if (fullYearMatch != null) {
          final fullYear = fullYearMatch.group(0) ?? '';
          final yearPart = fullYear.split(' ')[0];
          final yearInt = int.tryParse(yearPart);
          if (yearInt != null &&
              yearInt >= 1990 &&
              yearInt <= 2050 &&
              yearInt > 1970) {
            // Validación adicional: debe estar en una línea corta
            if (line.trim().length <= 20) {
              return fullYear;
            }
          }
        }

        // Si no encuentra formato completo, buscar solo año
        final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(line);
        if (yearMatch != null) {
          final year = yearMatch.group(0) ?? '';
          final yearInt = int.tryParse(year);
          // Validar rango y que no sea año de nacimiento típico
          if (yearInt != null &&
              yearInt >= 1990 &&
              yearInt <= 2050 &&
              yearInt > 1970) {
            // Evitar años de nacimiento comunes
            // Validación adicional: debe estar en una línea corta
            if (line.trim().length <= 15) {
              return year;
            }
          }
        }
      }

      // Patrón 3: Buscar patrones específicos de T3 como "AÑO YYYY XX" o "YYYY XX REG"
      final specificPatterns = [
        RegExp(r'AÑO\s+(19|20)\d{2}\s+\d{2}\b'), // AÑO YYYY XX
        RegExp(r'\b(19|20)\d{2}\s+\d{2}\s+REG'), // YYYY XX REG
        RegExp(r'REGISTRO\s+(19|20)\d{2}\s+\d{2}\b'), // REGISTRO YYYY XX
      ];

      for (final pattern in specificPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final fullYearMatch = RegExp(
            r'(19|20)\d{2}\s+\d{2}',
          ).firstMatch(match.group(0) ?? '');
          if (fullYearMatch != null) {
            final fullYear = fullYearMatch.group(0) ?? '';
            final yearPart = fullYear.split(' ')[0];
            final yearInt = int.tryParse(yearPart);
            if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
              return fullYear;
            }
          }
        }
      }

      // Patrones de fallback para formato simple
      final fallbackPatterns = [
        RegExp(r'AÑO\s+(19|20)\d{2}\b'),
        RegExp(r'\b(19|20)\d{2}\s+REG'),
        RegExp(r'REGISTRO\s+(19|20)\d{2}\b'),
      ];

      for (final pattern in fallbackPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final yearStr =
              RegExp(
                r'(19|20)\d{2}',
              ).firstMatch(match.group(0) ?? '')?.group(0) ??
              '';
          final yearInt = int.tryParse(yearStr);
          if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
            return yearStr;
          }
        }
      }
    }

    // Fallback: usar método estándar
    return _extractAnoRegistro(lines);
  }

  /// Extrae el año de registro específicamente para credenciales t2 (misma línea)
  static String _extractAnoRegistroT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Para t2, buscar el patrón específico YYYY MM en la misma línea que CURP
      if (line.contains('CURP')) {
        // Buscar patrón YYYY MM (formato específico para t2: 2018 00)
        final match = RegExp(r'(20\d{2})\s+(\d{2})').firstMatch(line);
        if (match != null) {
          return '${match.group(1)} ${match.group(2)}';
        }
      }

      // También buscar en líneas que contengan año de registro
      if (line.contains('AÑO') ||
          line.contains('ANO') ||
          line.contains('REGISTRO')) {
        final match = RegExp(r'(20\d{2})\s+(\d{2})').firstMatch(line);
        if (match != null) {
          return '${match.group(1)} ${match.group(2)}';
        }
      }
    }
    return '';
  }

  /// Extrae la sección
  static String _extractSeccion(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta SECCIÓN, buscar en líneas siguientes
      if (line.contains('SECCIÓN') || line.contains('SECCION')) {
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          // Buscar número de sección (generalmente 4 dígitos)
          final match = RegExp(r'\b\d{4}\b').firstMatch(nextLine);
          if (match != null) {
            final section = match.group(0) ?? '';
            // Verificar que no sea un año
            if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
              return section;
            }
          }
        }
      }

      // Buscar número de sección en cualquier línea (evitando años)
      final match = RegExp(r'\b\d{4}\b').firstMatch(line);
      if (match != null) {
        final section = match.group(0) ?? '';
        // Verificar que no sea un año y no esté en contexto de fecha
        if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section) &&
            !line.contains('/')) {
          return section;
        }
      }
    }
    return '';
  }

  /// Extrae la sección específicamente para credenciales t3
  /// Optimizado para el formato específico de credenciales T3
  static String _extractSeccionT3(List<String> lines) {
    // Búsqueda específica para T3: patrones comunes en credenciales más nuevas
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Patrón 1: Buscar SECCIÓN seguida directamente de un número
      if (line.contains('SECCIÓN') || line.contains('SECCION')) {
        // Buscar número inmediatamente después de SECCIÓN
        final seccionPattern = RegExp(r'SECCI[ÓO]N\s+(\d{4})\b');
        final match = seccionPattern.firstMatch(line);
        if (match != null) {
          final section = match.group(1) ?? '';
          // Verificar que no sea un año
          if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
            return section;
          }
        }

        // Buscar en líneas siguientes si no está en la misma línea
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();
          final sectionMatch = RegExp(r'\b(\d{4})\b').firstMatch(nextLine);
          if (sectionMatch != null) {
            final section = sectionMatch.group(1) ?? '';
            // Verificar que no sea un año
            if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
              return section;
            }
          }
        }
      }

      // Patrón 2: Buscar líneas que contengan "SECCIÓN" y números en la misma línea
      // pero no necesariamente adyacentes (ej: "SECCIÓN ELECTORAL 1234")
      if (line.contains('SECCIÓN') || line.contains('SECCION')) {
        final allNumbers = RegExp(r'\b(\d{4})\b').allMatches(line);
        for (final match in allNumbers) {
          final section = match.group(1) ?? '';
          // Verificar que no sea un año y que esté en contexto de sección
          if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section) &&
              !line.contains('VIGENCIA') &&
              !line.contains('EMISIÓN') &&
              !line.contains('EMISION')) {
            return section;
          }
        }
      }

      // Patrón 3: Buscar números de 4 dígitos en líneas que no contengan fechas
      // Este es un patrón más agresivo para T3 donde la sección puede aparecer sin etiqueta
      if (!line.contains('/') &&
          !line.contains('VIGENCIA') &&
          !line.contains('EMISIÓN') &&
          !line.contains('EMISION') &&
          !line.contains('CURP') &&
          !line.contains('NACIMIENTO') &&
          !line.contains('REGISTRO')) {
        final sectionMatch = RegExp(r'\b(\d{4})\b').firstMatch(line);
        if (sectionMatch != null) {
          final section = sectionMatch.group(1) ?? '';
          // Verificar que no sea un año
          if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
            // Validación adicional: debe estar en una línea corta (probablemente solo la sección)
            if (line.trim().length <= 20) {
              return section;
            }
          }
        }
      }
    }

    // Fallback: usar método estándar
    return _extractSeccion(lines);
  }

  /// Extrae la sección específicamente para credenciales t2 (misma línea que municipio)
  static String _extractSeccionT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Para t2, sección está en la misma línea que municipio
      if ((line.contains('SECCIÓN') || line.contains('SECCION')) &&
          line.contains('MUNICIPIO')) {
        // Buscar número de sección en la misma línea
        final match = RegExp(r'\b(\d{4})\b').firstMatch(line);
        if (match != null) {
          final section = match.group(1) ?? '';
          // Verificar que no sea un año
          if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
            return section;
          }
        }
      }

      // También buscar en líneas que contengan ambas palabras clave
      if (line.contains('MUNICIPIO') &&
          (line.contains('SECCIÓN') || line.contains('SECCION'))) {
        final match = RegExp(r'\b(\d{4})\b').firstMatch(line);
        if (match != null) {
          final section = match.group(1) ?? '';
          if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
            return section;
          }
        }
      }
    }
    return '';
  }

  /// Extrae la vigencia
  static String _extractVigencia(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta VIGENCIA, buscar en líneas siguientes
      if (line.contains('VIGENCIA')) {
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          // Buscar patrón de vigencia (YYYY YYYY)
          final match = RegExp(r'(20\d{2})\s+(20\d{2})').firstMatch(nextLine);
          if (match != null) {
            return '${match.group(1)} ${match.group(2)}';
          }
          // Buscar patrón con guión
          final matchWithDash = RegExp(
            r'(20\d{2})\s*-\s*(20\d{2})',
          ).firstMatch(nextLine);
          if (matchWithDash != null) {
            return '${matchWithDash.group(1)} ${matchWithDash.group(2)}';
          }
        }
      }

      // Buscar patrón de vigencia en cualquier línea
      final match = RegExp(r'(20\d{2})\s+(20\d{2})').firstMatch(line);
      if (match != null && !line.contains('/')) {
        return '${match.group(1)} ${match.group(2)}';
      }
    }
    return '';
  }

  /// Extrae la vigencia específicamente para credenciales t3
  /// Optimizado para el formato específico de credenciales T3
  static String _extractVigenciaT3(List<String> lines) {
    // Primero intentar con el método de similitud mejorado
    final vigenciaWithSimilarity = _extractVigenciaWithSimilarity(lines);
    if (vigenciaWithSimilarity.isNotEmpty) {
      return _cleanVigenciaT3(vigenciaWithSimilarity);
    }

    // Búsqueda específica para T3: patrones comunes en credenciales más nuevas
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Buscar líneas que contengan VIGENCIA y extraer año inmediatamente después
      if (line.contains('VIGENCIA')) {
        // Patrón 1: VIGENCIA seguida de un año (formato común en T3)
        final vigenciaPattern = RegExp(r'VIGENCIA\s+(\d{4})\b');
        final match = vigenciaPattern.firstMatch(line);
        if (match != null) {
          return _cleanVigenciaT3(match.group(1) ?? '');
        }

        // Patrón 2: VIGENCIA con rango de años (YYYY-YYYY)
        final rangePattern = RegExp(r'VIGENCIA\s+(\d{4})\s*-\s*(\d{4})');
        final rangeMatch = rangePattern.firstMatch(line);
        if (rangeMatch != null) {
          return _cleanVigenciaT3(
            '${rangeMatch.group(1)}-${rangeMatch.group(2)}',
          );
        }

        // Patrón 3: Buscar en líneas siguientes si no está en la misma línea
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();

          // Buscar año de 4 dígitos
          final yearPattern = RegExp(r'\b(20\d{2})\b');
          final yearMatch = yearPattern.firstMatch(nextLine);
          if (yearMatch != null) {
            return _cleanVigenciaT3(yearMatch.group(1) ?? '');
          }

          // Buscar rango de años
          final nextRangePattern = RegExp(r'(\d{4})\s*-\s*(\d{4})');
          final nextRangeMatch = nextRangePattern.firstMatch(nextLine);
          if (nextRangeMatch != null) {
            return _cleanVigenciaT3(
              '${nextRangeMatch.group(1)}-${nextRangeMatch.group(2)}',
            );
          }
        }
      }

      // Búsqueda de patrones de vigencia sin etiqueta explícita
      // Común en T3 donde la vigencia puede aparecer sin la palabra "VIGENCIA"
      if (!line.contains('/') &&
          !line.contains('CURP') &&
          !line.contains('NACIMIENTO')) {
        // Buscar patrón de dos años consecutivos (formato YYYY YYYY)
        final doubleYearPattern = RegExp(r'\b(20\d{2})\s+(20\d{2})\b');
        final doubleMatch = doubleYearPattern.firstMatch(line);
        if (doubleMatch != null) {
          final year1 = int.parse(doubleMatch.group(1)!);
          final year2 = int.parse(doubleMatch.group(2)!);
          // Validar que sea un rango lógico de vigencia (diferencia de 5-15 años)
          if (year2 > year1 && (year2 - year1) >= 5 && (year2 - year1) <= 15) {
            return _cleanVigenciaT3(
              '${doubleMatch.group(1)}-${doubleMatch.group(2)}',
            );
          }
        }
      }
    }

    // Fallback: usar método estándar
    final fallbackVigencia = _extractVigencia(lines);
    return fallbackVigencia.isNotEmpty
        ? _cleanVigenciaT3(fallbackVigencia)
        : fallbackVigencia;
  }

  /// Limpia la vigencia T3 eliminando espacios y manteniendo solo números y guión
  static String _cleanVigenciaT3(String vigencia) {
    if (vigencia.isEmpty) return vigencia;

    // Eliminar todos los espacios y caracteres que no sean números o guión
    final cleaned = vigencia.replaceAll(RegExp(r'[^0-9-]'), '');

    // Validar que tenga el formato correcto YYYY-YYYY
    final formatMatch = RegExp(r'^(\d{4})-(\d{4})$').firstMatch(cleaned);
    if (formatMatch != null) {
      return cleaned;
    }

    // Si solo tiene números, intentar formar el formato YYYY-YYYY
    final numbersOnly = cleaned.replaceAll('-', '');
    if (numbersOnly.length == 8) {
      return '${numbersOnly.substring(0, 4)}-${numbersOnly.substring(4, 8)}';
    }

    // Si tiene formato YYYY, devolverlo tal como está
    if (RegExp(r'^\d{4}$').hasMatch(cleaned)) {
      return cleaned;
    }

    return vigencia; // Devolver original si no se puede limpiar
  }

  /// Extrae la vigencia específicamente para credenciales t2 (misma línea que localidad y emisión)
  static String _extractVigenciaT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Para t2, vigencia está en la misma línea que localidad y emisión
      if (line.contains('VIGENCIA') &&
          (line.contains('LOCALIDAD') ||
              line.contains('EMISIÓN') ||
              line.contains('EMISION'))) {
        // Buscar patrón de vigencia (YYYY YYYY) en la misma línea
        final match = RegExp(r'(20\d{2})\s+(20\d{2})').firstMatch(line);
        if (match != null) {
          return '${match.group(1)} ${match.group(2)}';
        }

        // Buscar patrón con guión
        final matchWithDash = RegExp(
          r'(20\d{2})\s*-\s*(20\d{2})',
        ).firstMatch(line);
        if (matchWithDash != null) {
          return '${matchWithDash.group(1)} ${matchWithDash.group(2)}';
        }

        // Buscar un solo año después de VIGENCIA (caso específico para t2)
        final vigenciaIndex = line.indexOf('VIGENCIA');
        if (vigenciaIndex != -1) {
          final afterVigencia = line.substring(
            vigenciaIndex + 8,
          ); // 8 = longitud de "VIGENCIA"
          final singleYearMatch = RegExp(
            r'\b(20\d{2})\b',
          ).firstMatch(afterVigencia);
          if (singleYearMatch != null) {
            return singleYearMatch.group(1) ?? '';
          }
        }
      }

      // También buscar en líneas que contengan las palabras clave
      if ((line.contains('LOCALIDAD') ||
              line.contains('EMISIÓN') ||
              line.contains('EMISION')) &&
          line.contains('VIGENCIA')) {
        final match = RegExp(r'(20\d{2})\s+(20\d{2})').firstMatch(line);
        if (match != null) {
          return '${match.group(1)} ${match.group(2)}';
        }

        // Buscar un solo año después de VIGENCIA como fallback
        final vigenciaIndex = line.indexOf('VIGENCIA');
        if (vigenciaIndex != -1) {
          final afterVigencia = line.substring(vigenciaIndex + 8);
          final singleYearMatch = RegExp(
            r'\b(20\d{2})\b',
          ).firstMatch(afterVigencia);
          if (singleYearMatch != null) {
            return singleYearMatch.group(1) ?? '';
          }
        }
      }
    }
    return '';
  }

  /// Corrige errores comunes de OCR
  static String correctOcrErrors(String text) {
    final corrections = {'0': 'O', '1': 'I', '5': 'S', '8': 'B', '@': 'A'};

    String corrected = text;
    corrections.forEach((wrong, correct) {
      corrected = corrected.replaceAll(wrong, correct);
    });

    return corrected;
  }

  /// Valida si los datos extraídos son suficientes
  static bool validateExtractedData(CredencialIneModel credencial) {
    // Campos mínimos requeridos para considerar válida la extracción
    return credencial.nombre.isNotEmpty ||
        credencial.curp.isNotEmpty ||
        credencial.claveElector.isNotEmpty;
  }

  /// Extrae la vigencia usando algoritmos de similitud para manejar variantes OCR
  static String _extractVigenciaWithSimilarity(List<String> lines) {
    final vigenciaLabels = [
      'VIGENCIA',
      'VIGENC',
      'VIGEN',
      'IGENCIA',
      'GENCIA',
      'VIGENT',
      'VIGENCI',
      'VGENCIA', // Variante donde falta 'I' (vGENCIA -> VGENCIA)
    ];

    // Búsqueda específica para el caso "SECCIÓN IGENCIA" o similar
    for (int i = 0; i < lines.length; i++) {
      final originalLine = lines[i].trim();
      final line = originalLine.toUpperCase();

      // Detectar líneas que contengan tanto SECCIÓN como alguna variante de VIGENCIA
      if (line.contains('SECCIÓN') || line.contains('SECCION')) {
        for (final label in vigenciaLabels) {
          final normalizedLabel = StringSimilarityUtils.normalizeOcrCharacters(
            label,
          );
          final normalizedLine = StringSimilarityUtils.normalizeOcrCharacters(
            line,
          );

          // Comparar etiqueta normalizada con contenido normalizado
          final labelIndex = normalizedLine.indexOf(normalizedLabel);
          if (labelIndex != -1) {
            // Buscar año inmediatamente después de la etiqueta en la misma línea
            final afterLabel =
                normalizedLine
                    .substring(labelIndex + normalizedLabel.length)
                    .trim();
            final yearAfterLabelPattern = RegExp(r'^\s*(\d{4})\b');
            final yearMatch = yearAfterLabelPattern.firstMatch(afterLabel);
            if (yearMatch != null) {
              return yearMatch.group(1) ?? '';
            }

            // Buscar en líneas siguientes el patrón "NÚMERO YYYY-YYYY" (formato tradicional)
            for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
              final nextLine = lines[j].trim();
              final sectionVigenciaPattern = RegExp(r'\b\d+\s+(\d{4}-\d{4})\b');
              final sectionMatch = sectionVigenciaPattern.firstMatch(nextLine);
              if (sectionMatch != null) {
                return sectionMatch.group(1) ?? '';
              }
            }
          }
        }
      }
    }

    // Búsqueda general en todas las líneas para casos como "LOCALIDAD 0001 EMISIÓN 2017 vGENCIA 2027"
    for (int i = 0; i < lines.length; i++) {
      final originalLine = lines[i].trim();
      final line = originalLine.toUpperCase();

      // Buscar variantes de VIGENCIA en la línea
      for (final label in vigenciaLabels) {
        final normalizedLabel = StringSimilarityUtils.normalizeOcrCharacters(
          label,
        );
        final normalizedLine = StringSimilarityUtils.normalizeOcrCharacters(
          line,
        );

        final labelIndex = normalizedLine.indexOf(normalizedLabel);
        if (labelIndex != -1) {
          // Buscar año inmediatamente después de la etiqueta en la misma línea
          final afterLabel =
              normalizedLine
                  .substring(labelIndex + normalizedLabel.length)
                  .trim();
          final yearAfterLabelPattern = RegExp(r'^\s*(\d{4})\b');
          final yearMatch = yearAfterLabelPattern.firstMatch(afterLabel);
          if (yearMatch != null) {
            return yearMatch.group(1) ?? '';
          }
        }
      }

      // También buscar usando el patrón original 'vGENCIA' directamente en la línea original
      if (originalLine.toUpperCase().contains('VGENCIA') ||
          originalLine.contains('vGENCIA')) {
        // Buscar año después de vGENCIA o VGENCIA
        final vgenciaPattern = RegExp(
          r'v?GENCIA\s+(\d{4})',
          caseSensitive: false,
        );
        final match = vgenciaPattern.firstMatch(originalLine);
        if (match != null) {
          return match.group(1) ?? '';
        }
      }
    }

    // Fallback: usar similitud de cadenas para casos no detectados
    final result = _findLabelWithSimilarity(
      lines,
      vigenciaLabels,
      threshold:
          0.5, // Umbral más bajo para vigencia debido a errores comunes de OCR
    );

    if (result['found'] == true) {
      final index = result['index'] as int;
      final line = lines[index].trim();
      final foundLabel = result['label'] as String;

      // Caso específico: buscar año inmediatamente después de la etiqueta VIGENCIA en la misma línea
      // Ejemplo: "LOCALIDAD 0001 EMISIÓN 2017 vGENCIA 2027"
      final normalizedLine = StringSimilarityUtils.normalizeOcrCharacters(line);
      final normalizedLabel = StringSimilarityUtils.normalizeOcrCharacters(
        foundLabel,
      );

      final labelIndex = normalizedLine.toUpperCase().indexOf(
        normalizedLabel.toUpperCase(),
      );
      if (labelIndex != -1) {
        final afterLabel =
            normalizedLine
                .substring(labelIndex + normalizedLabel.length)
                .trim();
        // Buscar un año de 4 dígitos inmediatamente después de la etiqueta
        final yearAfterLabelPattern = RegExp(r'^\s*(\d{4})\b');
        final yearMatch = yearAfterLabelPattern.firstMatch(afterLabel);
        if (yearMatch != null) {
          return yearMatch.group(1) ?? '';
        }
      }

      // Buscar fecha en la misma línea (patrones tradicionales)
      final datePattern = RegExp(
        r'\b(\d{4}-\d{4}|\d{2}[/-]\d{2}[/-]\d{4}|\d{4}[/-]\d{2}[/-]\d{2})\b',
      );
      final match = datePattern.firstMatch(line);
      if (match != null) {
        return match.group(0) ?? '';
      }

      // Buscar en líneas siguientes (hasta 2 líneas)
      for (int i = index + 1; i < lines.length && i <= index + 2; i++) {
        final nextLine = lines[i].trim();

        // Caso especial: línea con formato "NÚMERO YYYY-YYYY" (ej: "2438 2023-2033")
        final sectionVigenciaPattern = RegExp(r'\b\d+\s+(\d{4}-\d{4})\b');
        final sectionMatch = sectionVigenciaPattern.firstMatch(nextLine);
        if (sectionMatch != null) {
          return sectionMatch.group(1) ?? ''; // Retorna solo la parte YYYY-YYYY
        }

        // Búsqueda normal de fechas
        final nextMatch = datePattern.firstMatch(nextLine);
        if (nextMatch != null) {
          return nextMatch.group(0) ?? '';
        }
      }
    }

    return '';
  }

  /// Extrae información adicional usando similitud de cadenas
  static Map<String, String> extractAdditionalInfoWithSimilarity(
    List<String> lines,
  ) {
    final info = <String, String>{};

    // Extraer vigencia con similitud
    final vigencia = _extractVigenciaWithSimilarity(lines);
    if (vigencia.isNotEmpty) {
      info['vigencia'] = vigencia;
    }

    // Extraer año de registro usando similitud
    final registroLabels = ['AÑO', 'ANO', 'REGISTRO', 'REG'];
    final registroResult = _findLabelWithSimilarity(
      lines,
      registroLabels,
      threshold: 0.7,
    );

    if (registroResult['found'] == true) {
      final index = registroResult['index'] as int;
      final line = lines[index].trim();
      final yearPattern = RegExp(r'\b(19|20)\d{2}\b');
      final match = yearPattern.firstMatch(line);
      if (match != null) {
        info['año_registro'] = match.group(0) ?? '';
      }
    }

    // Extraer número de emisión usando similitud
    final emisionLabels = ['EMISIÓN', 'EMISION', 'EMIS', 'NUM'];
    final emisionResult = _findLabelWithSimilarity(
      lines,
      emisionLabels,
      threshold: 0.7,
    );

    if (emisionResult['found'] == true) {
      final index = emisionResult['index'] as int;
      final line = lines[index].trim();
      final numPattern = RegExp(r'\b\d{2,4}\b');
      final match = numPattern.firstMatch(line);
      if (match != null) {
        info['numero_emision'] = match.group(0) ?? '';
      }
    }

    return info;
  }

  /// Detecta el tipo de credencial basado en la presencia de campos específicos
  static String _detectCredentialType(List<String> lines) {
    final upperLines = lines.map((line) => line.toUpperCase()).toList();
    final fullText = upperLines.join(' ');

    print('DEBUG: Método de detección basado en texto para lado frontal');
    print('DEBUG: Para lado reverso se usa _detectCredentialTypeByQrCount con conteo QR');
    print('DEBUG: Texto completo para detección de tipo (${fullText.length} chars): ${fullText.length > 200 ? fullText.substring(0, 200) + '...' : fullText}');
    print('DEBUG: Líneas de texto (${lines.length} líneas): ${lines.take(5).join(' | ')}${lines.length > 5 ? ' | ...' : ''}');

    // T1 deshabilitado completamente - solo se procesan T2 y T3
    // NOTA: Este método es legacy, la nueva lógica usa únicamente conteo de QRs

    // Contar cuántas etiquetas de t2 están presentes
    int tipo2FieldsFound = 0;
    for (final label in _tipo2Labels) {
      if (upperLines.any((line) => line.contains(label))) {
        tipo2FieldsFound++;
        print('DEBUG: Etiqueta T2 encontrada: $label');
      }
    }

    // Patrones adicionales para detectar T2 en el reverso
    bool hasT2ReversePatterns = false;
    
    // Primero verificar si es T3 por número de códigos QR detectados
     bool hasT3MultipleQRPatterns = false;
     
     // Patrón T3: Múltiples códigos QR detectados
     // Las T3 tienen más de 1 código QR, las T2 tienen solo 1 código QR
     // Este es el diferenciador más confiable entre T2 y T3
     int qrReferences = RegExp(r'QR|CODIGO.*QR|QR.*CODE').allMatches(fullText).length;
     if (qrReferences > 1) {
       hasT3MultipleQRPatterns = true;
       print('DEBUG: Patrón T3 detectado - Múltiples códigos QR ($qrReferences > 1)');
     } else {
       print('DEBUG: Patrón T2/T3 - Códigos QR detectados: $qrReferences');
     }
    
    // Si se detectan patrones T3, no evaluar como T2
     if (hasT3MultipleQRPatterns) {
       print('DEBUG: Credencial identificada como T3 por múltiples códigos QR - omitiendo evaluación T2');
     } else {
      // Solo evaluar patrones T2 si no se detectaron patrones T3
      
      // Patrón 1: Códigos específicos de T2 (formato EC seguido de números y letras)
      if (RegExp(r'EC\d{4}[A-Z]').hasMatch(fullText)) {
        hasT2ReversePatterns = true;
        print('DEBUG: Patrón T2 reverso detectado - EC código');
      }
    
    // Patrón 2: Estructura típica del reverso T2 con códigos MRZ
    // NOTA: IDMEX también aparece en T3, necesitamos ser más específicos
    // T2 reverso típicamente tiene IDMEX seguido de patrones específicos de T2
    if (RegExp(r'IDMEX\d+<<\d+').hasMatch(fullText)) {
      // Verificar si también contiene otros indicadores específicos de T2
      bool hasAdditionalT2Indicators = 
          fullText.contains('SECRETARIO EJECUTIVO') ||
          fullText.contains('SECRETARIO EJEC') ||
          RegExp(r'EC\d{4}[A-Z]').hasMatch(fullText) ||
          (fullText.length < 500 && tipo2FieldsFound == 0);
      
      if (hasAdditionalT2Indicators) {
        hasT2ReversePatterns = true;
        print('DEBUG: Patrón T2 reverso detectado - IDMEX MRZ con indicadores T2');
      } else {
        print('DEBUG: IDMEX MRZ detectado pero sin indicadores específicos de T2 - posible T3');
      }
    }
    
    // Patrón 3: Líneas con formato específico de T2 reverso (números y letras específicos)
    if (RegExp(r'\d{7}M\d{7}MEX<\d+<<\d+<\d+').hasMatch(fullText)) {
      hasT2ReversePatterns = true;
      print('DEBUG: Patrón T2 reverso detectado - Formato MRZ completo');
    }
    
    // Patrón 4: Presencia de "SECRETARIO EJECUTIVO" típico del reverso T2
    if (fullText.contains('SECRETARIO EJECUTIVO') || fullText.contains('SECRETARIO EJEC')) {
      hasT2ReversePatterns = true;
      print('DEBUG: Patrón T2 reverso detectado - SECRETARIO EJECUTIVO');
    }
    
    // Patrón 5: Detectar texto muy corto o mal reconocido que podría ser T2 reverso
    // NOTA: Texto corto con MRZ también puede ser T3, necesitamos indicadores más específicos
    if (fullText.length < 300 && tipo2FieldsFound == 0) {
      // Verificar si contiene caracteres típicos de MRZ Y indicadores específicos de T2
      bool hasMrzIndicators = fullText.contains('MEX') || fullText.contains('<<') || 
          RegExp(r'\d{6,}').hasMatch(fullText) || fullText.contains('&');
      
      bool hasSpecificT2Indicators = 
          fullText.contains('SECRETARIO EJECUTIVO') ||
          fullText.contains('SECRETARIO EJEC') ||
          RegExp(r'EC\d{4}[A-Z]').hasMatch(fullText);
      
      if (hasMrzIndicators && hasSpecificT2Indicators) {
        hasT2ReversePatterns = true;
        print('DEBUG: Patrón T2 reverso detectado - Texto corto con MRZ e indicadores T2');
      } else if (hasMrzIndicators) {
         print('DEBUG: Texto corto con MRZ detectado pero sin indicadores específicos de T2 - posible T3');
       }
     }
     
     // Patrón 6: Detectar patrones de texto mal reconocido típicos del reverso T2
     if (RegExp(r'[A-Z]{2,}[&<>]{1,}[A-Z0-9]{2,}').hasMatch(fullText)) {
       hasT2ReversePatterns = true;
       print('DEBUG: Patrón T2 reverso detectado - Patrón de texto mal reconocido');
     }
     
     } // Cerrar el bloque else de evaluación T2

    print('DEBUG [LEGACY]: Resumen detección - T2: $tipo2FieldsFound, T2 Reverso: $hasT2ReversePatterns, T3 Múltiples QR: $hasT3MultipleQRPatterns');
    
    // Logs adicionales para diagnóstico
    print('DEBUG [LEGACY]: Análisis de patrones MRZ (OBSOLETO):');
    print('  - Contiene IDMEX: ${RegExp(r'IDMEX\d+<<\d+').hasMatch(fullText)}');
    print('  - Contiene SECRETARIO EJECUTIVO: ${fullText.contains('SECRETARIO EJECUTIVO') || fullText.contains('SECRETARIO EJEC')}');
    print('  - Contiene patrón EC: ${RegExp(r'EC\d{4}[A-Z]').hasMatch(fullText)}');
    print('  - Longitud de texto: ${fullText.length}');
    print('  - Texto corto sin etiquetas: ${fullText.length < 500 && tipo2FieldsFound == 0}');
    print('DEBUG [LEGACY]: Análisis de patrones T3 (OBSOLETO):');
     print('  - Múltiples QR detectados: $hasT3MultipleQRPatterns');
     print('  - Total referencias QR: ${RegExp(r'QR|CODIGO.*QR|QR.*CODE').allMatches(fullText).length}');
     print('  - Criterio T3: > 1 código QR (T2 tiene solo 1 QR)');

    // Lógica de detección legacy (T1 deshabilitado):
     // NOTA: Este método se usa EXCLUSIVAMENTE para detección frontal
  // El lado reverso usa _detectCredentialTypeByQrCount basado en conteo de QRs
     // t3: tiene múltiples códigos QR (>1) -> retorna 't3'
     // t2: tiene ESTADO, MUNICIPIO o LOCALIDAD (frontal) O patrones de reverso T2 (pero no múltiples QR) -> retorna 't2'
     // t3: no tiene ninguna de las etiquetas anteriores -> retorna 't3'
    String detectedType;
    if (hasT3MultipleQRPatterns) {
      detectedType = _credentialTypeConfig['Tipo 3']!['code'];
      print('DEBUG [LEGACY]: Clasificado como T3 por múltiples códigos QR detectados');
    } else if (tipo2FieldsFound > 0) {
      detectedType = _credentialTypeConfig['Tipo 2']!['code'];
      print('DEBUG [LEGACY]: Clasificado como T2 por etiquetas frontales (ESTADO/MUNICIPIO/LOCALIDAD)');
    } else if (hasT2ReversePatterns) {
      detectedType = _credentialTypeConfig['Tipo 2']!['code'];
      print('DEBUG [LEGACY]: Clasificado como T2 por patrones de reverso');
    } else {
      detectedType = _credentialTypeConfig['Tipo 3']!['code'];
      print('DEBUG [LEGACY]: Clasificado como T3 por exclusión (sin etiquetas específicas)');
    }

    print('DEBUG: Tipo de credencial detectado por análisis de texto: $detectedType');
    print('DEBUG: Detección híbrida: OCR (frontal) + conteo QR (reverso) para mayor precisión');
    return detectedType;
  }

  /// Detecta el tipo de credencial basándose únicamente en el conteo de códigos QR
  /// Este método se utiliza EXCLUSIVAMENTE para el procesamiento del lado reverso
  /// T2: 1 código QR
  /// T3: >= 2 códigos QR (más flexible que exactamente 3)
  static String _detectCredentialTypeByQrCount(int qrCount) {
    print('DEBUG: Detectando tipo de credencial por conteo QR: $qrCount');
    
    String detectedType;
    if (qrCount == 1) {
      detectedType = _credentialTypeConfig['Tipo 2']!['code'];
      print('DEBUG: Clasificado como T2 - 1 código QR detectado');
    } else if (qrCount >= 2) {
      detectedType = _credentialTypeConfig['Tipo 3']!['code'];
      print('DEBUG: Clasificado como T3 - $qrCount códigos QR detectados (>= 2)');
    } else {
      // Fallback: si es 0 QRs, usar T3 por defecto
      detectedType = _credentialTypeConfig['Tipo 3']!['code'];
      print('DEBUG: Clasificado como T3 por defecto - $qrCount códigos QR (esperado: 1 para T2, >= 2 para T3)');
    }
    
    print('DEBUG: Tipo de credencial detectado por QR: $detectedType');
    return detectedType;
  }

  /// Extrae el estado de la credencial (solo para t2)
  static String _extractEstado(List<String> lines) {
    return _extractFieldAfterLabel(lines, ['ESTADO']);
  }

  /// Extrae el municipio de la credencial (solo para t2)
  static String _extractMunicipio(List<String> lines) {
    return _extractFieldAfterLabel(lines, ['MUNICIPIO']);
  }

  /// Extrae el código de municipio específicamente para credenciales t2
  /// Maneja el formato "MUNICIPIO 099 SECCIÓN 2530" extrayendo solo "099"
  static String _extractMunicipioT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Buscar línea que contenga tanto MUNICIPIO como SECCIÓN
      if (line.contains('MUNICIPIO') &&
          (line.contains('SECCIÓN') || line.contains('SECCION'))) {
        // Extraer el código numérico del municipio
        final municipioCode = _extractMunicipioCode(line);
        if (municipioCode.isNotEmpty) {
          return municipioCode;
        }
      }
    }
    return '';
  }

  /// Extrae el código numérico del municipio de una línea
  /// Ejemplo: "MUNICIPIO 099 SECCIÓN 2530" -> "099"
  static String _extractMunicipioCode(String line) {
    // Buscar patrón: MUNICIPIO seguido de espacio y números
    final match = RegExp(r'MUNICIPIO\s+(\d{3})').firstMatch(line);
    if (match != null) {
      return match.group(1) ?? '';
    }

    // Patrón alternativo: buscar números después de MUNICIPIO
    final parts = line.split('MUNICIPIO');
    if (parts.length > 1) {
      final afterMunicipio = parts[1].trim();
      // Extraer los primeros 3 dígitos encontrados
      final digitMatch = RegExp(r'(\d{3})').firstMatch(afterMunicipio);
      if (digitMatch != null) {
        return digitMatch.group(1) ?? '';
      }
    }

    return '';
  }

  /// Extrae la localidad de la credencial (solo para t2)
  static String _extractLocalidad(List<String> lines) {
    return _extractFieldAfterLabel(lines, ['LOCALIDAD']);
  }

  /// Extrae el código de localidad específicamente para credenciales t2
  /// Maneja el formato "LOCALIDAD 0001 EMISIÓN 2016 VIGENCIA 2026" extrayendo solo "0001"
  static String _extractLocalidadT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Buscar línea que contenga LOCALIDAD junto con VIGENCIA o EMISIÓN
      if (line.contains('LOCALIDAD') &&
          (line.contains('VIGENCIA') ||
              line.contains('EMISIÓN') ||
              line.contains('EMISION'))) {
        // Extraer el código numérico de la localidad
        final localidadCode = _extractLocalidadCode(line);
        if (localidadCode.isNotEmpty) {
          return localidadCode;
        }
      }
    }
    return '';
  }

  /// Extrae el código numérico de la localidad de una línea
  /// Ejemplo: "LOCALIDAD 0001 EMISIÓN 2016 VIGENCIA 2026" -> "0001"
  static String _extractLocalidadCode(String line) {
    // Buscar patrón: LOCALIDAD seguido de espacio y números
    final match = RegExp(r'LOCALIDAD\s+(\d{4})').firstMatch(line);
    if (match != null) {
      return match.group(1) ?? '';
    }

    // Patrón alternativo: buscar números después de LOCALIDAD
    final parts = line.split('LOCALIDAD');
    if (parts.length > 1) {
      final afterLocalidad = parts[1].trim();
      // Extraer los primeros 4 dígitos encontrados
      final digitMatch = RegExp(r'(\d{4})').firstMatch(afterLocalidad);
      if (digitMatch != null) {
        return digitMatch.group(1) ?? '';
      }
    }

    return '';
  }

  /// Método auxiliar para extraer un campo después de encontrar su etiqueta
  static String _extractFieldAfterLabel(
    List<String> lines,
    List<String> labels,
  ) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      for (final label in labels) {
        if (line.contains(label)) {
          // Buscar el valor en la misma línea después de la etiqueta
          final parts = line.split(label);
          if (parts.length > 1) {
            final value = parts[1].trim();
            if (value.isNotEmpty) {
              return _filterReferenceLabels([value]).isNotEmpty
                  ? _filterReferenceLabels([value]).first
                  : value;
            }
          }

          // Si no hay valor en la misma línea, buscar en la siguiente
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1].trim();
            if (nextLine.isNotEmpty) {
              final filteredData = _filterReferenceLabels([nextLine]);
              if (filteredData.isNotEmpty) {
                return filteredData.first;
              }
            }
          }
          break;
        }
      }
    }
    return '';
  }

  /// Extrae la región de firma y huella digital para credenciales T2 del lado reverso
  /// Utiliza una región estimada basada en las dimensiones de la credencial
  static Map<String, dynamic> _extractSignatureHuellaT2(img.Image originalImage, String imagePath) {
    try {
      print('🔍 Iniciando extracción de región firma-huella T2...');
      
      // Dimensiones de la imagen
      final int imageWidth = originalImage.width;
      final int imageHeight = originalImage.height;
      
      print('📏 Dimensiones de imagen: ${imageWidth}x$imageHeight');
      
      // Para credenciales T2 reverso, la región de firma-huella está típicamente:
      // - En la parte central-inferior de la credencial
      // - Por encima del MRZ (que está en la parte más inferior)
      // - Por debajo del QR (que está en la parte superior)
      
      // Calcular región estimada basada en proporciones típicas de credencial INE
      final int startX = (imageWidth * 0.175).round(); // 17.5% desde el borde izquierdo
      final int endX = (imageWidth * 0.825).round(); // 82.5% del ancho total
      final int startY = (imageHeight * 0.32).round(); // 32% desde arriba
      final int endY = (imageHeight * 0.62).round(); // 62% desde arriba
      
      // Validar que la región sea válida
      if (startY >= endY || endY > imageHeight || startX >= endX || endX > imageWidth) {
        print('⚠️ Región firma-huella inválida: startX=$startX, endX=$endX, startY=$startY, endY=$endY');
        return {'imagePath': ''};
      }
      
      // Calcular dimensiones de la región
      final int regionWidth = endX - startX;
      final int regionHeight = endY - startY;
      
      print('📍 Región calculada: ($startX, $startY) - ($endX, $endY)');
      print('📏 Dimensiones región: ${regionWidth}x$regionHeight');
      
      // Extraer la región de firma y huella
      final signatureHuellaRegion = img.copyCrop(
        originalImage,
        x: startX,
        y: startY,
        width: regionWidth,
        height: regionHeight,
      );

      // Generar nombre único para la imagen
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'signature_huella_t2_$timestamp.png';
      final directory = path.dirname(imagePath);
      final signatureHuellaPath = path.join(directory, fileName);

      // Guardar la imagen extraída
      final pngBytes = img.encodePng(signatureHuellaRegion);
      File(signatureHuellaPath).writeAsBytesSync(pngBytes);

      print('✅ Región firma-huella T2 extraída: $signatureHuellaPath');
      print('📏 Dimensiones finales: ${regionWidth}x$regionHeight');
      print('📍 Posición final: ($startX, $startY) - ($endX, $endY)');

      return {
        'imagePath': signatureHuellaPath,
      };
    } catch (e) {
      print('❌ Error extrayendo región firma-huella T2: $e');
      return {'imagePath': ''};
    }
  }
}
