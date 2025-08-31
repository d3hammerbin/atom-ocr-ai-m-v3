import 'dart:io';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraCaptureController extends GetxController {
  // Variables observables
  final isInitialized = false.obs;
  final isCapturing = false.obs;
  final capturedImagePath = ''.obs;
  final hasPermission = false.obs;
  final errorMessage = ''.obs;
  
  // Controlador de cámara
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  
  // Getters
  CameraController? get cameraController => _cameraController;
  List<CameraDescription> get cameras => _cameras;
  
  @override
  void onInit() {
    super.onInit();
    _initializeCamera();
  }

  @override
  void onClose() {
    _cameraController?.dispose();
    super.onClose();
  }
  
  /// Inicializa la cámara y solicita permisos
  Future<void> _initializeCamera() async {
    try {
      // Solicitar permisos de cámara
      await _requestCameraPermission();
      
      if (!hasPermission.value) {
        errorMessage.value = 'Permisos de cámara denegados';
        return;
      }
      
      // Obtener cámaras disponibles
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        errorMessage.value = 'No se encontraron cámaras disponibles';
        return;
      }
      
      // Inicializar controlador con la primera cámara (trasera)
      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      isInitialized.value = true;
      errorMessage.value = '';
      
    } catch (e) {
      errorMessage.value = 'Error al inicializar cámara: $e';
      print('Error inicializando cámara: $e');
    }
  }
  
  /// Solicita permisos de cámara
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    hasPermission.value = status == PermissionStatus.granted;
  }
  
  /// Captura una imagen
  Future<void> captureImage() async {
    if (!isInitialized.value || _cameraController == null) {
      Get.snackbar(
        'Error',
        'La cámara no está inicializada',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    try {
      isCapturing.value = true;
      
      // Capturar imagen
      final XFile image = await _cameraController!.takePicture();
      
      // Obtener directorio de documentos
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'credential_$timestamp.jpg';
      final String filePath = '${appDir.path}/$fileName';
      
      // Copiar imagen al directorio de la aplicación
      await File(image.path).copy(filePath);
      
      capturedImagePath.value = filePath;
      isCapturing.value = false;
      
      Get.snackbar(
        'Éxito',
        'Credencial capturada correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Navegar de regreso con la imagen capturada
      Get.back(result: filePath);
      
    } catch (e) {
      isCapturing.value = false;
      errorMessage.value = 'Error al capturar imagen: $e';
      Get.snackbar(
        'Error',
        'No se pudo capturar la imagen: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      print('Error capturando imagen: $e');
    }
  }
  
  /// Cambia entre cámara frontal y trasera
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    
    try {
      final currentCamera = _cameraController!.description;
      final newCamera = _cameras.firstWhere(
        (camera) => camera != currentCamera,
        orElse: () => _cameras.first,
      );
      
      await _cameraController!.dispose();
      
      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
    } catch (e) {
      errorMessage.value = 'Error al cambiar cámara: $e';
      print('Error cambiando cámara: $e');
    }
  }
  
  /// Reinicia la cámara
  Future<void> retryInitialization() async {
    isInitialized.value = false;
    errorMessage.value = '';
    await _initializeCamera();
  }
  
  /// Limpia la imagen capturada
  void clearImage() {
    capturedImagePath.value = '';
  }
}