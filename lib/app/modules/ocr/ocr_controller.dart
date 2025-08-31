import 'package:get/get.dart';

class OcrController extends GetxController {
  final isProcessing = false.obs;
  final extractedText = ''.obs;
  


  void processImage() {
    // TODO: Implementar lógica de OCR
    isProcessing.value = true;
    
    // Simulación de procesamiento
    Future.delayed(const Duration(seconds: 2), () {
      extractedText.value = 'Texto extraído de la imagen (simulación)';
      isProcessing.value = false;
    });
  }
  
  void clearText() {
    extractedText.value = '';
  }
}