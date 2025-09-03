import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/ine_credential_processor_service.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/mlkit_text_recognition_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../data/models/credencial_ine_model.dart';

class LocalProcessController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final MLKitTextRecognitionService _mlKitService = MLKitTextRecognitionService();
  
  // Variables observables
  final RxString selectedImagePath = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString extractedText = ''.obs;
  final RxBool isExtractingText = false.obs;
  final Rxn<CredencialIneModel> processedCredential = Rxn<CredencialIneModel>();
  final RxBool isProcessingCredential = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeMLKit();
  }
  
  /// Inicializa el servicio ML Kit
  Future<void> _initializeMLKit() async {
    try {
      await _mlKitService.initialize();
    } catch (e) {
      errorMessage.value = 'Error al inicializar ML Kit: $e';
    }
  }
  
  @override
  void onClose() {
    _mlKitService.dispose();
    super.onClose();
  }
  
  /// Selecciona una imagen desde la galería
  Future<void> selectImageFromGallery() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Limpiar información anterior antes de seleccionar nueva imagen
      clearExtractedText();
      clearProcessedCredential();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        selectedImagePath.value = image.path;
        SnackbarUtils.showSuccess(
          title: 'Éxito',
          message: 'Imagen seleccionada correctamente',
        );
      }
    } catch (e) {
      errorMessage.value = 'Error al seleccionar imagen: $e';
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudo seleccionar la imagen',
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Limpia la imagen seleccionada
  void clearSelectedImage() {
    selectedImagePath.value = '';
    errorMessage.value = '';
  }
  
  /// Verifica si hay una imagen seleccionada
  bool get hasSelectedImage => selectedImagePath.value.isNotEmpty;
  
  /// Extrae texto de la imagen seleccionada usando ML Kit
  Future<void> extractTextFromSelectedImage() async {
    if (!hasSelectedImage) {
      SnackbarUtils.showWarning(
        title: 'Error',
        message: 'Primero selecciona una imagen',
      );
      return;
    }
    
    try {
      isExtractingText.value = true;
      errorMessage.value = '';
      extractedText.value = '';
      
      final String? text = await _mlKitService.extractTextFromImage(selectedImagePath.value);
      
      if (text != null && text.isNotEmpty) {
        extractedText.value = text;
        SnackbarUtils.showSuccess(
          title: 'Éxito',
          message: 'Texto extraído correctamente',
        );
      } else {
        extractedText.value = 'No se encontró texto en la imagen';
        SnackbarUtils.showInfo(
          title: 'Información',
          message: 'No se detectó texto en la imagen seleccionada',
        );
      }
    } catch (e) {
      errorMessage.value = 'Error al extraer texto: $e';
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudo extraer el texto de la imagen',
      );
    } finally {
      isExtractingText.value = false;
    }
  }
  
  /// Limpia el texto extraído
  void clearExtractedText() {
    extractedText.value = '';
  }
  
  /// Verifica si hay texto extraído
  bool get hasExtractedText => extractedText.value.isNotEmpty;
  
  /// Obtiene información del servicio ML Kit
  Map<String, dynamic> getMLKitServiceInfo() {
    return _mlKitService.getServiceInfo();
  }

  /// Procesa credencial INE desde el texto extraído
  Future<void> processIneCredential() async {
    if (!hasExtractedText) {
      SnackbarUtils.showWarning(
        title: 'Error',
        message: 'Primero extrae texto de una imagen',
      );
      return;
    }

    try {
      isProcessingCredential.value = true;
      errorMessage.value = '';

      // Verificar si es una credencial INE
      if (!IneCredentialProcessorService.isIneCredential(extractedText.value)) {
        SnackbarUtils.showWarning(
          title: 'Información',
          message: 'La imagen no parece ser una credencial INE válida',
        );
        return;
      }

      // Procesar la credencial con detección de lado si hay imagen seleccionada
      final credential = selectedImagePath.value.isNotEmpty
          ? await IneCredentialProcessorService.processCredentialWithSideDetection(
              extractedText.value, selectedImagePath.value)
          : IneCredentialProcessorService.processCredentialText(extractedText.value);

      if (IneCredentialProcessorService.validateExtractedData(credential)) {
        processedCredential.value = credential;
        SnackbarUtils.showSuccess(
          title: 'Éxito',
          message: 'Credencial INE procesada correctamente',
        );
      } else {
        SnackbarUtils.showWarning(
          title: 'Advertencia',
          message: 'Se procesó la credencial pero faltan algunos datos',
        );
        processedCredential.value = credential;
      }
    } catch (e) {
      errorMessage.value = 'Error al procesar credencial: $e';
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudo procesar la credencial INE',
      );
    } finally {
      isProcessingCredential.value = false;
    }
  }

  /// Extrae y procesa credencial INE en un solo paso
  Future<void> extractAndProcessIneCredential() async {
    await extractTextFromSelectedImage();
    if (hasExtractedText) {
      await processIneCredential();
    }
  }

  /// Limpia los datos de credencial procesada
  void clearProcessedCredential() {
    processedCredential.value = null;
  }

  /// Verifica si hay una credencial procesada
  bool get hasProcessedCredential => processedCredential.value != null;

  /// Limpia todos los datos
  void clearAllData() {
    clearSelectedImage();
    clearExtractedText();
    clearProcessedCredential();
  }
}