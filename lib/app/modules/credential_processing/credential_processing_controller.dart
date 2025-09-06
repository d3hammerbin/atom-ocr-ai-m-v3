import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/ine_credential_processor_service.dart';
import '../../core/services/mlkit_text_recognition_service.dart';
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
    final arguments = Get.arguments as Map<String, dynamic>?;
    
    if (arguments != null) {
      frontImagePath.value = arguments['frontImagePath'] ?? '';
      backImagePath.value = arguments['backImagePath'] ?? '';
      
      Log.i('CredentialProcessingController', 
        'Imágenes cargadas - Frontal: ${frontImagePath.value}, Trasera: ${backImagePath.value}');
    } else {
      Log.w('CredentialProcessingController', 'No se recibieron argumentos de navegación');
    }
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
      Log.i('CredentialProcessingController', 'Iniciando guardado de credencial');

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

      // Convertir CredencialIneModel a CredentialModel
      final credentialToSave = CredentialModel(
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
        fechaCaptura: DateTime.now(),
        photoPath: credential.photoPath,
        signaturePath: credential.signaturePath,
        qrImagePath: credential.qrImagePath,
        barcodeImagePath: credential.barcodeImagePath,
        mrzImagePath: credential.mrzImagePath,
        signatureHuellaImagePath: credential.signatureHuellaImagePath,
        qrContent: credential.qrContent,
        barcodeContent: credential.barcodeContent,
        mrzContent: credential.mrzContent,
      );

      // Guardar en la base de datos
      final credentialId = await _credentialRepository.insertCredential(credentialToSave);
      
      Log.i('CredentialProcessingController', 'Credencial guardada con ID: $credentialId');
      
      SnackbarUtils.showSuccess(
        title: 'Éxito',
        message: 'Credencial guardada correctamente',
      );

      // Navegar a la lista de credenciales
      Get.offAllNamed('/credentials-list');
      
    } catch (e) {
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudo guardar la credencial: $e',
      );
      Log.e('CredentialProcessingController', 'Error guardando credencial', e);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}