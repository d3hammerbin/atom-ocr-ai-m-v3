import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import '../../core/utils/secure_storage.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/logger_service.dart';
import '../../core/utils/snackbar_utils.dart';

class CameraCaptureController extends GetxController with WidgetsBindingObserver {
  // Variables observables
  final isInitialized = false.obs;
  final isCapturing = false.obs;
  final capturedImagePath = ''.obs;
  final hasPermission = false.obs;
  final errorMessage = ''.obs;
  final isFrontSide = true.obs; // true = frontal (persona), false = reverso (QR)
  final isFlashOn = false.obs; // Estado del flash
  
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
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCameraController();
    super.onClose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    
    // Si no hay controlador de cámara, no hacer nada
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      // Pausar la cámara cuando la app se vuelve inactiva
      _pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      // Reanudar la cámara cuando la app se reanuda
      _resumeCamera();
    }
  }
  
  /// Pausa la cámara de forma segura
  Future<void> _pauseCamera() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        // No hacer dispose, solo marcar como no inicializada temporalmente
        await Log.i('CameraController', 'Pausando cámara por cambio de estado de aplicación');
      }
    } catch (e) {
      await Log.e('CameraController', 'Error al pausar cámara', e);
    }
  }
  
  /// Reanuda la cámara de forma segura
  Future<void> _resumeCamera() async {
    try {
      if (_cameraController != null && !_cameraController!.value.isInitialized) {
        // Reinicializar la cámara si es necesario
        _initializeCamera();
        await Log.i('CameraController', 'Reanudando cámara por cambio de estado de aplicación');
      }
    } catch (e) {
      await Log.e('CameraController', 'Error al reanudar cámara', e);
    }
  }
  
  /// Limpia los recursos de la cámara de forma segura
  Future<void> _disposeCameraController() async {
    try {
      if (_cameraController != null) {
        // Verificar si el controlador está inicializado antes de hacer dispose
        if (_cameraController!.value.isInitialized) {
          await _cameraController!.dispose();
        }
        _cameraController = null;
      }
    } catch (e) {
      await Log.e('CameraController', 'Error al limpiar recursos de cámara', e);
      // Forzar la limpieza del controlador incluso si hay error
      _cameraController = null;
    }
  }
  
  /// Inicializa la cámara y solicita permisos
  Future<void> _initializeCamera() async {
    try {
      // Limpiar recursos previos si existen
      await _disposeCameraController();
      
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
      await Log.e('CameraController', 'Error inicializando cámara', e);
    }
  }
  
  /// Solicita permisos de cámara
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    hasPermission.value = status == PermissionStatus.granted;
  }
  
  /// Calcula las coordenadas del marco de referencia para recorte
  Map<String, double> _calculateFrameCoordinates(Size screenSize, Orientation orientation) {
    // Aspect ratio de credencial: 790:490 ≈ 1.61:1
    const double credentialAspectRatio = 790 / 490;
    
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    double frameWidth, frameHeight;
    
    if (orientation == Orientation.portrait) {
      // En portrait, usar 80% del ancho disponible
      frameWidth = screenWidth * 0.8;
      frameHeight = frameWidth / credentialAspectRatio;
      
      // Verificar que no exceda la altura disponible (dejando espacio para controles)
      final maxHeight = screenHeight * 0.5;
      if (frameHeight > maxHeight) {
        frameHeight = maxHeight;
        frameWidth = frameHeight * credentialAspectRatio;
      }
    } else {
      // En landscape, maximizar área de captura (85% ancho, dejando solo espacio para barra de botones)
      frameWidth = screenWidth * 0.85;
      frameHeight = frameWidth / credentialAspectRatio;
      
      // Verificar que no exceda la altura disponible (dejando espacio para tip superior)
      final maxHeight = screenHeight * 0.85;
      if (frameHeight > maxHeight) {
        frameHeight = maxHeight;
        frameWidth = frameHeight * credentialAspectRatio;
      }
    }
    
    // Calcular posición del marco (centrado)
    double frameX, frameY;
    
    if (orientation == Orientation.portrait) {
      frameX = (screenWidth - frameWidth) / 2;
      frameY = (screenHeight - frameHeight) / 2;
    } else {
      // En landscape, centrar verticalmente en el espacio disponible
      const double tipHeight = 60;
      final double availableHeight = screenHeight - tipHeight;
      frameX = (screenWidth - frameWidth) / 2;
      frameY = tipHeight + (availableHeight - frameHeight) / 2 - 20;
    }
    
    return {
      'x': frameX,
      'y': frameY,
      'width': frameWidth,
      'height': frameHeight,
    };
  }
  
  /// Recorta la imagen según las coordenadas del marco de referencia
  Future<Uint8List> _cropImageToFrame(Uint8List imageBytes, Size screenSize, Orientation orientation) async {
    try {
      // Decodificar la imagen
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('No se pudo decodificar la imagen');
      }
      
      // Obtener coordenadas del marco
      final frameCoords = _calculateFrameCoordinates(screenSize, orientation);
      
      // Calcular la escala entre la imagen capturada y la pantalla
      final double scaleX = originalImage.width / screenSize.width;
      final double scaleY = originalImage.height / screenSize.height;
      
      // Convertir coordenadas de pantalla a coordenadas de imagen
      final int cropX = (frameCoords['x']! * scaleX).round();
      final int cropY = (frameCoords['y']! * scaleY).round();
      final int cropWidth = (frameCoords['width']! * scaleX).round();
      final int cropHeight = (frameCoords['height']! * scaleY).round();
      
      // Validar que las coordenadas estén dentro de los límites de la imagen
      final int validX = cropX.clamp(0, originalImage.width - 1);
      final int validY = cropY.clamp(0, originalImage.height - 1);
      final int validWidth = cropWidth.clamp(1, originalImage.width - validX);
      final int validHeight = cropHeight.clamp(1, originalImage.height - validY);
      
      // Recortar la imagen
      final img.Image croppedImage = img.copyCrop(
        originalImage,
        x: validX,
        y: validY,
        width: validWidth,
        height: validHeight,
      );
      
      // Codificar la imagen recortada a JPEG
      final Uint8List croppedBytes = Uint8List.fromList(img.encodeJpg(croppedImage, quality: 90));
      
      return croppedBytes;
    } catch (e) {
      await Log.e('CameraController', 'Error recortando imagen', e);
      // En caso de error, devolver la imagen original
      return imageBytes;
    }
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
      final Uint8List originalImageBytes = await image.readAsBytes();
      if (originalImageBytes.isEmpty) {
        throw Exception('La imagen capturada está vacía');
      }
      
      // Obtener tamaño de pantalla y orientación actual
      final Size screenSize = Get.size;
      final Orientation orientation = Get.width > Get.height ? Orientation.landscape : Orientation.portrait;
      
      // Recortar la imagen al área del marco de referencia
      final Uint8List croppedImageBytes = await _cropImageToFrame(
        originalImageBytes,
        screenSize,
        orientation,
      );
      
      // Guardar imagen recortada en la galería
       await Gal.putImageBytes(
         croppedImageBytes,
         name: "atom_ocr_cropped_${DateTime.now().millisecondsSinceEpoch}.jpg",
       );
       
       // Guardar imagen recortada en directorio seguro y oculto
       final String secureFileName = SecureStorage.generateSecureFileName(
         prefix: 'credential',
         extension: 'jpg',
       );
       final File secureFile = await SecureStorage.saveImageBytes(
         croppedImageBytes,
         fileName: secureFileName,
       );
       final String filePath = secureFile.path;
      
      capturedImagePath.value = filePath;
      isCapturing.value = false;
      
      SnackbarUtils.showSuccess(
        title: 'Éxito',
        message: 'Imagen recortada y guardada en la galería',
      );
      
      // Restaurar orientación portrait antes de navegar
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Navegar a la pantalla de procesamiento con la imagen capturada
      Get.toNamed('/processing', arguments: {
        'imagePath': filePath,
        'side': isFrontSide.value ? 'front' : 'back',
      });
      
    } catch (e) {
      isCapturing.value = false;
      errorMessage.value = 'Error al capturar imagen: $e';
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudo capturar la imagen: $e',
      );
      await Log.e('CameraController', 'Error capturando imagen', e);
    }
  }
  
  /// Alterna entre lado frontal y reverso de la credencial
  void switchCredentialSide() {
    isFrontSide.value = !isFrontSide.value;
    
    // Mostrar mensaje informativo sobre el lado seleccionado
    SnackbarUtils.showInfo(
      title: 'Lado de credencial',
      message: isFrontSide.value ? 'Capturando lado frontal' : 'Capturando lado reverso',
      duration: const Duration(seconds: 2),
    );
  }
  
  /// Alterna el estado del flash de la cámara
  Future<void> toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      final FlashMode newFlashMode = isFlashOn.value ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newFlashMode);
      isFlashOn.value = !isFlashOn.value;
      
      // Mostrar mensaje informativo sobre el estado del flash
      SnackbarUtils.showInfo(
        title: 'Flash',
        message: isFlashOn.value ? 'Flash activado' : 'Flash desactivado',
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      await Log.e('CameraController', 'Error al cambiar estado del flash', e);
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