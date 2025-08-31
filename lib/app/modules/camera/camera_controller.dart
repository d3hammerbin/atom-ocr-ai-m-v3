import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import '../../core/utils/secure_storage.dart';
import '../../core/services/permission_service.dart';

class CameraCaptureController extends GetxController {
  // Variables observables
  final isInitialized = false.obs;
  final isCapturing = false.obs;
  final capturedImagePath = ''.obs;
  final hasPermission = false.obs;
  final errorMessage = ''.obs;
  final isFrontSide = true.obs; // true = frontal (persona), false = reverso (QR)
  
  // Controlador de cámara
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  CameraDescription? _backCamera; // Siempre usar cámara trasera
  
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
      
      // Buscar específicamente la cámara trasera
      _backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first, // Fallback a la primera disponible
      );
      
      // Inicializar controlador siempre con la cámara trasera
      _cameraController = CameraController(
        _backCamera!,
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
    if (isCapturing.value) return;
    
    try {
      isCapturing.value = true;
      
      // Verificar que el directorio seguro esté listo
      final bool isSecureReady = await SecureStorage.isSecureDirectoryReady();
      if (!isSecureReady) {
        throw Exception('Directorio seguro no disponible');
      }
      
      // Verificar permisos de almacenamiento usando el servicio de permisos
      final bool storageGranted = await PermissionService.checkStoragePermission();
      if (!storageGranted) {
        // Intentar solicitar permisos de almacenamiento
        final bool storageRequested = await PermissionService.requestStoragePermissions();
        if (!storageRequested) {
          throw Exception('Permisos de almacenamiento requeridos');
        }
      }
      
      // Verificar permisos de galería para guardar la imagen
      final bool galleryGranted = await PermissionService.checkGalleryPermission();
      if (!galleryGranted) {
        // Intentar solicitar permisos de galería
        final bool galleryRequested = await PermissionService.requestGalleryPermissions();
        if (!galleryRequested) {
          throw Exception('Permisos de galería requeridos para guardar la imagen');
        }
      }
      
      // Verificar que el controlador esté inicializado
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        throw Exception('Controlador de cámara no inicializado');
      }
      
      // Capturar la imagen
      final XFile? image = await _cameraController?.takePicture();
      if (image == null) {
        throw Exception('No se pudo capturar la imagen');
      }
      
      // Leer los bytes de la imagen
      final Uint8List imageBytes = await image.readAsBytes();
      if (imageBytes.isEmpty) {
        throw Exception('La imagen capturada está vacía');
      }
      
      // Guardar imagen en la galería
       await Gal.putImageBytes(
         imageBytes,
         name: "atom_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg",
       );
       
       // Guardar imagen en directorio seguro y oculto
       final String secureFileName = SecureStorage.generateSecureFileName(
         prefix: 'credential',
         extension: 'jpg',
       );
       final File secureFile = await SecureStorage.saveImageBytes(
         imageBytes,
         fileName: secureFileName,
       );
       final String filePath = secureFile.path;
      
      capturedImagePath.value = filePath;
      isCapturing.value = false;
      
      Get.snackbar(
        'Éxito',
        'Imagen guardada en la galería',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // Navegar a la pantalla de procesamiento con la imagen capturada
      Get.toNamed('/processing', arguments: {
        'imagePath': filePath,
        'side': isFrontSide.value ? 'front' : 'back',
      });
      
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
  
  /// Alterna entre lado frontal y reverso de la credencial
  void switchCredentialSide() {
    isFrontSide.value = !isFrontSide.value;
    
    // Mostrar mensaje informativo sobre el lado seleccionado
    Get.snackbar(
      'Lado de credencial',
      isFrontSide.value ? 'Capturando lado frontal' : 'Capturando lado reverso',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
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