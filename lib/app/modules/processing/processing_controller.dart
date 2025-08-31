import 'dart:io';
import 'package:get/get.dart';
import '../../core/utils/secure_storage.dart';

class ProcessingController extends GetxController {
  // Observable para el estado de procesamiento
  final RxBool isProcessing = false.obs;
  final RxString processingStatus = 'Procesando credencial...'.obs;
  
  // Imagen capturada
  File? capturedImage;
  
  // Datos dummy de la credencial
  final RxMap<String, String> credentialData = <String, String>{
    'nombre': 'JUAN CARLOS PÉREZ GARCÍA',
    'curp': 'PEGJ850315HDFRRN09',
    'clave_elector': 'PGJCRN85031512H700',
    'seccion': '1234',
    'localidad': 'CIUDAD DE MÉXICO',
    'municipio': 'BENITO JUÁREZ',
    'estado': 'DISTRITO FEDERAL',
    'vigencia': '2024',
    'emision': '2019'
  }.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeProcessing();
  }
  
  Future<void> _initializeProcessing() async {
    try {
      // Verificar que el directorio seguro esté listo
      final bool isSecureReady = await SecureStorage.isSecureDirectoryReady();
      if (!isSecureReady) {
        processingStatus.value = 'Error: Directorio seguro no disponible';
        return;
      }
      
      // Obtener la imagen del argumento de navegación
      final arguments = Get.arguments;
      if (arguments != null && arguments['imagePath'] != null) {
        final String imagePath = arguments['imagePath'] as String;
        final File imageFile = File(imagePath);
        
        // Verificar que la imagen existe en el directorio seguro
        if (await imageFile.exists()) {
          capturedImage = imageFile;
          startProcessing();
        } else {
          processingStatus.value = 'Error: Imagen no encontrada en directorio seguro';
        }
      } else {
        processingStatus.value = 'Error: No se proporcionó ruta de imagen';
      }
    } catch (e) {
      processingStatus.value = 'Error inicializando procesamiento: $e';
    }
  }
  
  void startProcessing() {
    isProcessing.value = true;
    processingStatus.value = 'Analizando imagen...';
    
    // Simular procesamiento con delay
    Future.delayed(const Duration(seconds: 2), () {
      processingStatus.value = 'Extrayendo texto...';
    });
    
    Future.delayed(const Duration(seconds: 4), () {
      processingStatus.value = 'Validando información...';
    });
    
    Future.delayed(const Duration(seconds: 6), () {
      processingStatus.value = 'Procesamiento completado';
      isProcessing.value = false;
    });
  }
  
  void cancelProcessing() {
    // Regresar a la pantalla inicial (home)
    Get.offAllNamed('/home');
  }
  
  void retryProcessing() {
    startProcessing();
  }
  
  void saveCredential() {
    // Aquí se implementaría la lógica para guardar la credencial
    Get.snackbar(
      'Éxito',
      'Credencial guardada correctamente',
      snackPosition: SnackPosition.BOTTOM,
    );
    
    // Regresar a la lista de credenciales
    Get.offAllNamed('/credentials-list');
  }
}