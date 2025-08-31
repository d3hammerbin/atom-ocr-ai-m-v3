import 'package:get/get.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/logger_service.dart';
import '../../routes/app_pages.dart';

class SplashController extends GetxController {
  final RxString statusMessage = 'Inicializando aplicación...'.obs;
  final RxBool hasError = false.obs;
  final RxBool isInitializing = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  /// Inicializa la aplicación verificando permisos y servicios
  Future<void> _initializeApp() async {
    try {
      isInitializing.value = true;
      hasError.value = false;
      
      // Paso 1: Verificar permisos
      statusMessage.value = 'Verificando permisos...';
      await Future.delayed(const Duration(milliseconds: 500)); // Pequeña pausa para UX
      
      bool permissionsGranted = await PermissionService.initialize();
      
      if (!permissionsGranted) {
        statusMessage.value = 'Permisos requeridos no concedidos';
        hasError.value = true;
        isInitializing.value = false;
        return;
      }
      
      // Paso 2: Inicializar otros servicios si es necesario
      statusMessage.value = 'Configurando servicios...';
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Paso 3: Navegación a la pantalla principal
      statusMessage.value = 'Completando inicialización...';
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Navegar a la pantalla principal
      Get.offAllNamed(Routes.HOME);
      
    } catch (e) {
      await Log.e('SplashController', 'Error durante la inicialización', e);
      statusMessage.value = 'Error durante la inicialización';
      hasError.value = true;
      isInitializing.value = false;
    }
  }

  /// Reintenta la inicialización de la aplicación
  Future<void> retryInitialization() async {
    await _initializeApp();
  }

  /// Verifica si todos los permisos están concedidos
  Future<bool> checkPermissions() async {
    try {
      return await PermissionService.areAllPermissionsGranted();
    } catch (e) {
      await Log.e('SplashController', 'Error verificando permisos', e);
      return false;
    }
  }

  /// Solicita permisos específicos
  Future<bool> requestPermissions() async {
    try {
      statusMessage.value = 'Solicitando permisos necesarios...';
      return await PermissionService.requestAllPermissions();
    } catch (e) {
      await Log.e('SplashController', 'Error solicitando permisos', e);
      return false;
    }
  }

  /// Maneja el caso cuando los permisos son denegados
  void handlePermissionsDenied() {
    statusMessage.value = 'Permisos necesarios para continuar';
    hasError.value = true;
    
    Get.snackbar(
      'Permisos Requeridos',
      'La aplicación necesita permisos para funcionar correctamente. Por favor, concede los permisos en la configuración.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  /// Navega directamente a la pantalla principal (para casos de emergencia)
  void skipToHome() {
    Get.offAllNamed(Routes.HOME);
  }
}