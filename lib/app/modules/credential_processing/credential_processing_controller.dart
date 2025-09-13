import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/ine_credential_processor_service.dart';
import '../../core/services/mlkit_text_recognition_service.dart';
import '../../core/services/gps_location_service.dart';
import '../../core/services/watermark_service.dart';
import '../../data/models/credencial_ine_model.dart';
import '../../data/models/credential_model.dart';
import '../../data/repositories/credential_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../camera/camera_controller.dart';

class CredentialProcessingController extends GetxController {
  // Variables observables para las rutas de las imágenes
  final RxString frontImagePath = ''.obs;
  final RxString backImagePath = ''.obs;
  final RxBool isProcessing = false.obs;
  final RxBool isSaving = false.obs;
  
  // Variables para el procesamiento
  final MLKitTextRecognitionService _mlKitService = MLKitTextRecognitionService();
  final Rxn<CredencialIneModel> processedCredential = Rxn<CredencialIneModel>();
  final RxnString extractedFrontText = RxnString();
  final RxnString extractedBackText = RxnString();
  
  // Variable para credencial existente (modo edición)
  final Rxn<CredentialModel> existingCredential = Rxn<CredentialModel>();
  
  // Repositorios
  final CredentialRepository _credentialRepository = CredentialRepository();
  final UserRepository _userRepository = UserRepository();
  
  @override
  void onInit() {
    super.onInit();
    _loadImagesFromArguments();
  }
  
  /// Carga las imágenes desde los argumentos de navegación
  void _loadImagesFromArguments() {
    final arguments = Get.arguments;
    
    if (arguments != null) {
      // Verificar si es una credencial existente (modo edición)
      if (arguments is CredentialModel) {
        existingCredential.value = arguments;
        _loadExistingCredentialData(arguments);
        Log.i('CredentialProcessingController', 
          'Modo edición - Credencial cargada: ${arguments.nombre}');
      }
      // Verificar si son rutas de imágenes nuevas (modo procesamiento)
      else if (arguments is Map<String, dynamic>) {
        frontImagePath.value = arguments['frontImagePath'] ?? '';
        backImagePath.value = arguments['backImagePath'] ?? '';
        
        Log.i('CredentialProcessingController', 
          'Modo procesamiento - Imágenes cargadas - Frontal: ${frontImagePath.value}, Trasera: ${backImagePath.value}');
      }
    } else {
      Log.w('CredentialProcessingController', 'No se recibieron argumentos de navegación');
    }
  }
  
  /// Carga los datos de una credencial existente para edición
  void _loadExistingCredentialData(CredentialModel credential) {
    // Cargar los datos de la credencial existente en el modelo CredencialIneModel
    processedCredential.value = CredencialIneModel(
      nombre: credential.nombre ?? '',
      curp: credential.curp ?? '',
      claveElector: credential.claveElector ?? '',
      fechaNacimiento: credential.fechaNacimiento ?? '',
      sexo: credential.sexo ?? '',
      domicilio: credential.domicilio ?? '',
      estado: credential.estado ?? '',
      municipio: credential.municipio ?? '',
      localidad: credential.localidad ?? '',
      seccion: credential.seccion ?? '',
      anoRegistro: credential.anoRegistro ?? '',
      vigencia: credential.vigencia ?? '',
      tipo: credential.tipo ?? '',
      lado: credential.lado ?? '',
      photoPath: credential.photoPath ?? '',
      signaturePath: credential.signaturePath ?? '',
      qrImagePath: credential.qrImagePath ?? '',
      barcodeImagePath: credential.barcodeImagePath ?? '',
      mrzImagePath: credential.mrzImagePath ?? '',
      signatureHuellaImagePath: credential.signatureHuellaImagePath ?? '',
      qrContent: credential.qrContent ?? '',
      barcodeContent: credential.barcodeContent ?? '',
      mrzContent: credential.mrzContent ?? '',
      mrzDocumentNumber: '',
      mrzNationality: '',
      mrzBirthDate: '',
      mrzExpiryDate: '',
      mrzSex: '',
    );
  }
  
  /// Verifica si ambas imágenes están disponibles
  bool get hasBothImages => frontImagePath.value.isNotEmpty && backImagePath.value.isNotEmpty;
  
  /// Vuelve a la página inicial para comenzar de nuevo
  Future<void> retakePhotos() async {
    try {
      // Navegar primero para evitar problemas con el controlador
      Get.offAllNamed('/');
      
    } catch (e) {
      Log.e('CredentialProcessingController', 'Error en retakePhotos', e);
      // Fallback: intentar navegación directa
      try {
        Get.offAndToNamed('/');
      } catch (fallbackError) {
        Log.e('CredentialProcessingController', 'Error en fallback navigation', fallbackError);
        // Último recurso
        Get.back();
      }
    }
  }
  
  /// Procesa la credencial con ambas imágenes
  Future<void> processCredential() async {
    if (!hasBothImages) {
      SnackbarUtils.showWarning(
        title: 'Advertencia',
        message: 'Se necesitan ambas imágenes (frontal y trasera) para procesar',
      );
      return;
    }
    
    try {
      isProcessing.value = true;
      Log.i('CredentialProcessingController', 'Iniciando procesamiento de credencial con ambas imágenes');
      
      // Validar que las rutas de imágenes no estén vacías
      if (frontImagePath.value.isEmpty || backImagePath.value.isEmpty) {
        SnackbarUtils.showWarning(
          title: 'Error',
          message: 'No se encontraron las rutas de las imágenes',
        );
        return;
      }
      
      // Extraer texto de la imagen frontal
      Log.i('CredentialProcessingController', 'Extrayendo texto de imagen frontal');
      extractedFrontText.value = await _mlKitService.extractTextFromImage(frontImagePath.value);
      
      // Extraer texto de la imagen trasera
      Log.i('CredentialProcessingController', 'Extrayendo texto de imagen trasera');
      extractedBackText.value = await _mlKitService.extractTextFromImage(backImagePath.value);
      
      // Verificar si es una credencial INE válida
      final combinedText = '${extractedFrontText.value}\n${extractedBackText.value}';
      if (!IneCredentialProcessorService.isIneCredential(combinedText)) {
        SnackbarUtils.showWarning(
          title: 'Información',
          message: 'Las imágenes no parecen ser una credencial INE válida',
        );
        return;
      }
      
      // Procesar imagen frontal
      Log.i('CredentialProcessingController', 'Procesando imagen frontal');
      final frontCredential = await IneCredentialProcessorService.processCredentialWithSideDetection(
        extractedFrontText.value ?? '', 
        frontImagePath.value
      );
      
      // Procesar imagen trasera
      Log.i('CredentialProcessingController', 'Procesando imagen trasera');
      final backCredential = await IneCredentialProcessorService.processCredentialWithSideDetection(
        extractedBackText.value ?? '', 
        backImagePath.value
      );
      
      // Combinar los datos de ambas imágenes
      final combinedCredential = _combineCredentialData(frontCredential, backCredential);
      processedCredential.value = combinedCredential;
      
      SnackbarUtils.showSuccess(
        title: 'Éxito',
        message: 'Credencial procesada correctamente',
      );
      
      Log.i('CredentialProcessingController', 'Procesamiento completado exitosamente');
      
      // Los datos procesados se muestran automáticamente en la vista mediante Obx
      
    } catch (e) {
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudo procesar la credencial: $e',
      );
      Log.e('CredentialProcessingController', 'Error procesando credencial', e);
    } finally {
      isProcessing.value = false;
    }
  }
  
  /// Combina los datos de las credenciales frontal y trasera
  CredencialIneModel _combineCredentialData(CredencialIneModel front, CredencialIneModel back) {
    // Tomar los datos principales del frente y complementar con los del reverso
    return front.copyWith(
      // Mantener datos del frente
      qrContent: back.qrContent.isNotEmpty ? back.qrContent : front.qrContent,
      qrImagePath: back.qrImagePath.isNotEmpty ? back.qrImagePath : front.qrImagePath,
      barcodeContent: back.barcodeContent.isNotEmpty ? back.barcodeContent : front.barcodeContent,
      barcodeImagePath: back.barcodeImagePath.isNotEmpty ? back.barcodeImagePath : front.barcodeImagePath,
      mrzContent: back.mrzContent.isNotEmpty ? back.mrzContent : front.mrzContent,
      mrzImagePath: back.mrzImagePath.isNotEmpty ? back.mrzImagePath : front.mrzImagePath,
      mrzDocumentNumber: back.mrzDocumentNumber.isNotEmpty ? back.mrzDocumentNumber : front.mrzDocumentNumber,
      mrzNationality: back.mrzNationality.isNotEmpty ? back.mrzNationality : front.mrzNationality,
      mrzBirthDate: back.mrzBirthDate.isNotEmpty ? back.mrzBirthDate : front.mrzBirthDate,
      mrzExpiryDate: back.mrzExpiryDate.isNotEmpty ? back.mrzExpiryDate : front.mrzExpiryDate,
      mrzSex: back.mrzSex.isNotEmpty ? back.mrzSex : front.mrzSex,
      signatureHuellaImagePath: back.signatureHuellaImagePath.isNotEmpty ? back.signatureHuellaImagePath : front.signatureHuellaImagePath,
      // Indicar que se procesaron ambos lados
      lado: 'ambos',
    );
  }
  
  /// Guarda la credencial procesada en la base de datos
  Future<void> saveCredential() async {
    if (processedCredential.value == null) {
      SnackbarUtils.showWarning(
        title: 'Advertencia',
        message: 'No hay credencial procesada para guardar',
      );
      return;
    }

    try {
      isSaving.value = true;
      
      final isEditMode = existingCredential.value != null;
      Log.i('CredentialProcessingController', 
        isEditMode ? 'Iniciando actualización de credencial' : 'Iniciando guardado de credencial');

      // Obtener el usuario actual (asumimos que hay al menos uno)
      final users = await _userRepository.getAllUsers();
      if (users.isEmpty) {
        SnackbarUtils.showError(
          title: 'Error',
          message: 'No se encontró usuario activo',
        );
        return;
      }

      final currentUser = users.first;
      final credential = processedCredential.value!;

      // Obtener coordenadas GPS del dispositivo
      double? latitude;
      double? longitude;
      
      try {
        Log.i('CredentialProcessingController', 'Obteniendo ubicación GPS para la credencial...');
        final gpsService = GpsLocationService.instance;
        final position = await gpsService.getCurrentPosition();
        
        if (position != null) {
          latitude = position.latitude;
          longitude = position.longitude;
          Log.i('CredentialProcessingController', 
            'Ubicación GPS obtenida - Lat: $latitude, Lng: $longitude, Precisión: ${position.accuracy}m');
        } else {
          Log.w('CredentialProcessingController', 'No se pudo obtener la ubicación GPS');
        }
      } catch (e) {
        Log.e('CredentialProcessingController', 'Error obteniendo ubicación GPS', e);
        // Continuar sin GPS si hay error
      }

      // Aplicar watermark a todas las imágenes de la credencial si está habilitado
      try {
        Log.i('CredentialProcessingController', 'Aplicando watermark a las imágenes de la credencial...');
        
        // Log de todas las rutas antes de filtrar
        Log.d('CredentialProcessingController', 'Rutas de imágenes disponibles:');
        Log.d('CredentialProcessingController', '  - photoPath: "${credential.photoPath}"');
        Log.d('CredentialProcessingController', '  - signaturePath: "${credential.signaturePath}"');
        Log.d('CredentialProcessingController', '  - qrImagePath: "${credential.qrImagePath}"');
        Log.d('CredentialProcessingController', '  - barcodeImagePath: "${credential.barcodeImagePath}"');
        Log.d('CredentialProcessingController', '  - mrzImagePath: "${credential.mrzImagePath}"');
        Log.d('CredentialProcessingController', '  - signatureHuellaImagePath: "${credential.signatureHuellaImagePath}"');
        Log.d('CredentialProcessingController', '  - frontImagePath: "${frontImagePath.value}"');
        Log.d('CredentialProcessingController', '  - backImagePath: "${backImagePath.value}"');
        
        final imagePaths = <String>[
          if (credential.photoPath.isNotEmpty) credential.photoPath,
          if (credential.signaturePath.isNotEmpty) credential.signaturePath,
          if (credential.qrImagePath.isNotEmpty) credential.qrImagePath,
          if (credential.barcodeImagePath.isNotEmpty) credential.barcodeImagePath,
          if (credential.mrzImagePath.isNotEmpty) credential.mrzImagePath,
          if (credential.signatureHuellaImagePath.isNotEmpty) credential.signatureHuellaImagePath,
          if (frontImagePath.value.isNotEmpty) frontImagePath.value,
          if (backImagePath.value.isNotEmpty) backImagePath.value,
        ];
        
        Log.i('CredentialProcessingController', 'Total de imágenes a procesar: ${imagePaths.length}');
        for (int i = 0; i < imagePaths.length; i++) {
          Log.d('CredentialProcessingController', '  ${i + 1}. ${imagePaths[i]}');
        }
        
        final watermarkResults = await WatermarkService.addWatermarkToMultipleImages(
          imagePaths: imagePaths,
        );
        
        final successCount = watermarkResults.values.where((success) => success).length;
        Log.i('CredentialProcessingController', 
          'Watermark aplicado a $successCount de ${imagePaths.length} imágenes');
        
      } catch (e) {
        Log.e('CredentialProcessingController', 'Error aplicando watermark', e);
        // Continuar sin watermark si hay error
      }

      // Convertir CredencialIneModel a CredentialModel
         final credentialToSave = CredentialModel(
           id: isEditMode ? existingCredential.value!.id : null,
           userId: currentUser.id!,
           nombre: credential.nombre,
           curp: credential.curp,
           claveElector: credential.claveElector,
           fechaNacimiento: credential.fechaNacimiento,
           sexo: credential.sexo,
           domicilio: credential.domicilio,
           estado: credential.estado,
           municipio: credential.municipio,
           localidad: credential.localidad,
           seccion: credential.seccion,
           anoRegistro: credential.anoRegistro,
           vigencia: credential.vigencia,
           tipo: credential.tipo,
           lado: credential.lado,
           fechaCaptura: isEditMode ? existingCredential.value!.fechaCaptura : DateTime.now(),
           photoPath: credential.photoPath,
           signaturePath: credential.signaturePath,
           qrImagePath: credential.qrImagePath,
           barcodeImagePath: credential.barcodeImagePath,
           mrzImagePath: credential.mrzImagePath,
           signatureHuellaImagePath: credential.signatureHuellaImagePath,
           frontImagePath: frontImagePath.value.isNotEmpty ? frontImagePath.value : null,
           backImagePath: backImagePath.value.isNotEmpty ? backImagePath.value : null,
           qrContent: credential.qrContent,
           barcodeContent: credential.barcodeContent,
           mrzContent: credential.mrzContent,
           // Campos de geolocalización
           latitude: latitude,
           longitude: longitude,
         );

      if (isEditMode) {
        // Actualizar credencial existente
        await _credentialRepository.updateCredential(credentialToSave);
        Log.i('CredentialProcessingController', 'Credencial actualizada con ID: ${credentialToSave.id}');
        
        SnackbarUtils.showSuccess(
          title: 'Éxito',
          message: 'Credencial actualizada correctamente',
        );
      } else {
        // Crear nueva credencial
        final credentialId = await _credentialRepository.insertCredential(credentialToSave);
        Log.i('CredentialProcessingController', 'Credencial guardada con ID: $credentialId');
        
        SnackbarUtils.showSuccess(
          title: 'Éxito',
          message: 'Credencial guardada correctamente',
        );
      }

      // Navegar a la lista de credenciales
      Get.offAllNamed('/credentials-list');
      
    } catch (e) {
      final isEditMode = existingCredential.value != null;
      SnackbarUtils.showError(
        title: 'Error',
        message: isEditMode ? 'No se pudo actualizar la credencial: $e' : 'No se pudo guardar la credencial: $e',
      );
      Log.e('CredentialProcessingController', 'Error guardando/actualizando credencial', e);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}