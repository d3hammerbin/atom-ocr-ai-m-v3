import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/mlkit_text_recognition_service.dart';
import '../../core/services/ine_credential_processor_service.dart';
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
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        selectedImagePath.value = image.path;
        Get.snackbar(
          'Éxito',
          'Imagen seleccionada correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error al seleccionar imagen: $e';
      Get.snackbar(
        'Error',
        'No se pudo seleccionar la imagen',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
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
      Get.snackbar(
        'Error',
        'Primero selecciona una imagen',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
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
        Get.snackbar(
          'Éxito',
          'Texto extraído correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        extractedText.value = 'No se encontró texto en la imagen';
        Get.snackbar(
          'Información',
          'No se detectó texto en la imagen seleccionada',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error al extraer texto: $e';
      Get.snackbar(
        'Error',
        'No se pudo extraer el texto de la imagen',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
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
      Get.snackbar(
        'Error',
        'Primero extrae texto de una imagen',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isProcessingCredential.value = true;
      errorMessage.value = '';

      // Verificar si es una credencial INE
      if (!IneCredentialProcessorService.isIneCredential(extractedText.value)) {
        Get.snackbar(
          'Información',
          'La imagen no parece ser una credencial INE válida',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Procesar la credencial
      final credential = IneCredentialProcessorService.processCredentialText(extractedText.value);

      if (IneCredentialProcessorService.validateExtractedData(credential)) {
        processedCredential.value = credential;
        Get.snackbar(
          'Éxito',
          'Credencial INE procesada correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Advertencia',
          'Se procesó la credencial pero faltan algunos datos',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        processedCredential.value = credential;
      }
    } catch (e) {
      errorMessage.value = 'Error al procesar credencial: $e';
      Get.snackbar(
        'Error',
        'No se pudo procesar la credencial INE',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
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