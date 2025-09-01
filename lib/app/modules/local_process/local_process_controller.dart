import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class LocalProcessController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  
  // Variables observables
  final RxString selectedImagePath = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
  }
  
  @override
  void onClose() {
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
}