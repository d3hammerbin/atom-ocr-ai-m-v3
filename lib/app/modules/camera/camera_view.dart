import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'camera_controller.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late CameraCaptureController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CameraCaptureController>();
    // Forzar orientación horizontal al entrar a la cámara
    _setLandscapeOrientation();
  }

  Future<void> _setLandscapeOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Pequeño delay para asegurar que la orientación se aplique
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    // Restaurar orientación vertical al salir
    _restorePortraitOrientation();
    super.dispose();
  }

  void _restorePortraitOrientation() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> _exitToHome() async {
    // Restaurar orientación vertical antes de navegar
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Delay para asegurar que la orientación se aplique antes de navegar
    await Future.delayed(const Duration(milliseconds: 200));
    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Obx(() {
            if (!controller.isInitialized.value &&
                controller.errorMessage.value.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Inicializando cámara...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _exitToHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Regresar al inicio'),
                    ),
                  ],
                ),
              );
            }

            if (!controller.isInitialized.value) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            return OrientationBuilder(
              builder: (context, orientation) {
                final size = MediaQuery.of(context).size;
                return Stack(
                  children: [
                    // Vista previa de la cámara con AspectRatio correcto
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: size.width,
                          height:
                              size.width /
                              controller.cameraController!.value.aspectRatio,
                          child: CameraPreview(controller.cameraController!),
                        ),
                      ),
                    ),

                    // Marco de guía para la credencial
                    _buildCredentialFrame(orientation),

                    // Controles de la cámara
                    _buildCameraControls(orientation),

                    // Texto de instrucción
                    _buildInstructionText(orientation),

                    // Indicador del lado de escaneo (solo en landscape)
                    if (orientation == Orientation.landscape)
                      _buildSideIndicator(),
                  ],
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCredentialFrame(Orientation orientation) {
    // Aspect ratio de credencial: 790:490 ≈ 1.61:1
    const double credentialAspectRatio = 790 / 490;

    // Obtener dimensiones de pantalla
    final screenSize = MediaQuery.of(context).size;
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

    if (orientation == Orientation.portrait) {
      return Center(
        child: Container(
          width: frameWidth,
          height: frameHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Esquinas del marco
              Positioned(
                top: -1,
                left: -1,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.blue, width: 4),
                      left: BorderSide(color: Colors.blue, width: 4),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.blue, width: 4),
                      right: BorderSide(color: Colors.blue, width: 4),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -1,
                left: -1,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.blue, width: 4),
                      left: BorderSide(color: Colors.blue, width: 4),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.blue, width: 4),
                      right: BorderSide(color: Colors.blue, width: 4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // En landscape, centrar verticalmente en el espacio disponible
      // Calcular altura del tip (aproximadamente 60px incluyendo padding)
      const double tipHeight = 60;
      final double availableHeight = screenHeight - tipHeight;
      final double topPosition =
          tipHeight +
          (availableHeight - frameHeight) / 2 -
          20; // Subir 20px para evitar fusión con parte inferior

      return Positioned(
        top: topPosition, // Centrar en el espacio disponible
        left: (screenWidth - frameWidth) / 2, // Centrar horizontalmente
        child: Container(
          width: frameWidth,
          height: frameHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Esquinas del marco
              Positioned(
                top: -1,
                left: -1,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.blue, width: 4),
                      left: BorderSide(color: Colors.blue, width: 4),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.blue, width: 4),
                      right: BorderSide(color: Colors.blue, width: 4),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -1,
                left: -1,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.blue, width: 4),
                      left: BorderSide(color: Colors.blue, width: 4),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.blue, width: 4),
                      right: BorderSide(color: Colors.blue, width: 4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCameraControls(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return Positioned(
        bottom: 50,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botón cancelar
            _buildControlButton(
              icon: Icons.close,
              onPressed: _exitToHome,
              backgroundColor: Colors.red.withValues(alpha: 0.8),
            ),
            // Botón flash
            Obx(
              () => _buildControlButton(
                icon: controller.isFlashOn.value ? Icons.flash_on : Icons.flash_off,
                onPressed: controller.toggleFlash,
                backgroundColor: controller.isFlashOn.value 
                    ? Colors.yellow.withValues(alpha: 0.8)
                    : Colors.grey.withValues(alpha: 0.8),
              ),
            ),
            // Botón capturar
            _buildCaptureButton(),
            // Botón lado de credencial
            Obx(
              () => _buildControlButton(
                icon:
                    controller.isFrontSide.value ? Icons.person : Icons.qr_code,
                onPressed: controller.switchCredentialSide,
                backgroundColor: Colors.blue.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    } else {
      return Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        width: 60,
        child: Container(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón cancelar
              _buildControlButton(
                icon: Icons.close,
                onPressed: _exitToHome,
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                size: 45,
              ),
              // Botón flash
              Obx(
                () => _buildControlButton(
                  icon: controller.isFlashOn.value ? Icons.flash_on : Icons.flash_off,
                  onPressed: controller.toggleFlash,
                  backgroundColor: controller.isFlashOn.value 
                      ? Colors.yellow.withValues(alpha: 0.8)
                      : Colors.black.withValues(alpha: 0.6),
                  size: 45,
                ),
              ),
              // Botón capturar
              _buildCaptureButton(),
              // Botón lado de credencial
              Obx(
                () => _buildControlButton(
                  icon:
                      controller.isFrontSide.value
                          ? Icons.person
                          : Icons.qr_code,
                  onPressed: controller.switchCredentialSide,
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  size: 45,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    double? size,
  }) {
    final buttonSize = size ?? 60.0;
    final iconSize =
        (size ?? 60.0) * 0.47; // Proporción del icono respecto al botón

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Obx(() {
      // Determinar si estamos en landscape para ajustar el tamaño
      final orientation = MediaQuery.of(context).orientation;
      final isLandscape = orientation == Orientation.landscape;
      final buttonSize = isLandscape ? 55.0 : 80.0;
      final iconSize = isLandscape ? 24.0 : 32.0;

      return GestureDetector(
        onTap:
            controller.isCapturing.value
                ? null
                : () async {
                  await controller.captureImage();
                  // La navegación a processing se maneja en el controlador
                },
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color:
                controller.isCapturing.value
                    ? Colors.grey.withValues(alpha: 0.6)
                    : (isLandscape
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.9)),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: isLandscape ? 0.5 : 1.0),
              width: isLandscape ? 2 : 4,
            ),
          ),
          child:
              controller.isCapturing.value
                  ? Center(
                    child: CircularProgressIndicator(
                      color: isLandscape ? Colors.white : Colors.blue,
                      strokeWidth: 2,
                    ),
                  )
                  : Icon(
                    Icons.camera_alt,
                    color: isLandscape ? Colors.black87 : Colors.black,
                    size: iconSize,
                  ),
        ),
      );
    });
  }

  Widget _buildInstructionText(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return Positioned(
        top: 80,
        left: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Coloca la credencial dentro del marco y presiona el botón para capturar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      // En landscape: tip extendido en la parte superior con más transparencia
      return Positioned(
        top: 0,
        left: 0,
        right: 60, // Terminar donde comienza el menú lateral
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4)),
          child: const Text(
            'Coloca la credencial dentro del marco y presiona el botón para capturar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Widget _buildSideIndicator() {
    return Positioned(
      left: 20,
      top: MediaQuery.of(context).size.height * 0.4, // Centrar verticalmente
      child: Obx(
        () => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(
            controller.isFrontSide.value ? Icons.person : Icons.qr_code,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
