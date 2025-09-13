import 'package:get/get.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/gps_verification_service.dart';
import '../../core/services/user_session_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../routes/app_pages.dart';
import '../../data/repositories/user_repository.dart';

class SplashController extends GetxController {
  final RxString statusMessage = 'Inicializando aplicación...'.obs;
  final RxBool hasError = false.obs;
  final RxBool isInitializing = true.obs;
  final RxMap<String, bool> locationCapabilities = <String, bool>{}.obs;
  
  late final UserRepository _userRepository;

  @override
  void onInit() {
    super.onInit();
    _userRepository = Get.find<UserRepository>();
    _initializeApp();
  }

  /// Inicializa la aplicación verificando permisos y servicios
  Future<void> _initializeApp() async {
    try {
      isInitializing.value = true;
      hasError.value = false;
      
      // Paso 1: Verificar hardware GPS y capacidades de ubicación
      statusMessage.value = 'Verificando hardware GPS...';
      await Future.delayed(const Duration(milliseconds: 500)); // Pequeña pausa para UX
      
      final gpsCapabilities = await GpsVerificationService.verifyLocationCapabilities();
      locationCapabilities.value = gpsCapabilities;
      
      await Log.i('SplashController', 'Capacidades de ubicación: $gpsCapabilities');
      
      // Informar al usuario sobre el estado del GPS
      final gpsStatusMessage = GpsVerificationService.getLocationStatusMessage(gpsCapabilities);
      await Log.i('SplashController', 'Estado GPS: $gpsStatusMessage');
      
      // Paso 2: Verificar permisos generales
      statusMessage.value = 'Verificando permisos...';
      await Future.delayed(const Duration(milliseconds: 500));
      
      bool permissionsGranted = await PermissionService.requestAllPermissions();
      
      if (!permissionsGranted) {
        statusMessage.value = 'Permisos requeridos no concedidos';
        hasError.value = true;
        isInitializing.value = false;
        return;
      }
      
      // Paso 3: Verificar que tengamos al menos una fuente de geolocalización
      if (!GpsVerificationService.hasAnyLocationSource(gpsCapabilities)) {
        statusMessage.value = 'Advertencia: Sin fuentes de geolocalización';
        await Log.w('SplashController', 'No hay fuentes de geolocalización disponibles');
        
        // Mostrar advertencia pero continuar
        SnackbarUtils.showWarning(
          title: 'GPS No Disponible',
          message: 'No se detectaron fuentes de geolocalización. Algunas funciones pueden estar limitadas.',
          duration: const Duration(seconds: 4),
        );
      }
      
      // Paso 4: Inicializar otros servicios si es necesario
      statusMessage.value = 'Configurando servicios...';
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Paso 5: Verificar estado de usuarios
      statusMessage.value = 'Verificando usuarios...';
      await Future.delayed(const Duration(milliseconds: 300));
      
      await _checkUserStatusAndNavigate();
      
    } catch (e) {
      await Log.e('SplashController', 'Error durante la inicialización', e);
      statusMessage.value = 'Error durante la inicialización';
      hasError.value = true;
      isInitializing.value = false;
    }
  }

  /// Verifica el estado de usuarios y navega apropiadamente
  Future<void> _checkUserStatusAndNavigate() async {
    try {
      final sessionService = UserSessionService.to;
      
      // Verificar si hay una sesión activa válida
      final hasValidSession = await sessionService.hasValidSession();
      
      if (hasValidSession) {
        // Hay sesión activa, ir directamente a selección de captura
        await Log.i('SplashController', 'Sesión activa encontrada para usuario: ${sessionService.currentUserIdentifier}');
        Get.offAllNamed(Routes.CAPTURE_SELECTION);
        return;
      }
      
      // No hay sesión activa, verificar si hay usuarios registrados
      final totalUsers = await _userRepository.getUserCount();
      
      if (totalUsers > 0) {
        // Hay usuarios registrados pero no hay sesión activa, solicitar autenticación
        await Log.i('SplashController', 'Usuarios registrados encontrados, solicitando autenticación');
        Get.offAllNamed(Routes.INITIAL);
      } else {
        // No hay usuarios, mostrar pantalla inicial de registro
        await Log.i('SplashController', 'No hay usuarios registrados, mostrando pantalla inicial');
        Get.offAllNamed(Routes.INITIAL);
      }
    } catch (e) {
      await Log.e('SplashController', 'Error verificando estado de usuarios', e);
      // En caso de error, ir a pantalla inicial como fallback
      Get.offAllNamed(Routes.INITIAL);
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
    
    SnackbarUtils.showWarning(
      title: 'Permisos Requeridos',
      message: 'La aplicación necesita permisos para funcionar correctamente. Por favor, concede los permisos en la configuración.',
      duration: const Duration(seconds: 5),
    );
  }

  /// Navega directamente a la pantalla principal (para casos de emergencia)
  void skipToHome() {
    Get.offAllNamed(Routes.HOME);
  }
  
  /// Obtiene el estado actual de las capacidades de ubicación
  Map<String, bool> getLocationCapabilities() {
    return Map<String, bool>.from(locationCapabilities);
  }
  
  /// Verifica si hay GPS óptimo disponible
  bool hasOptimalGps() {
    return GpsVerificationService.hasOptimalLocationSetup(locationCapabilities);
  }
  
  /// Verifica si hay al menos una fuente de ubicación
  bool hasAnyLocationSource() {
    return GpsVerificationService.hasAnyLocationSource(locationCapabilities);
  }
  
  /// Obtiene un mensaje descriptivo del estado del GPS
  String getGpsStatusMessage() {
    return GpsVerificationService.getLocationStatusMessage(locationCapabilities);
  }
  
  /// Solicita al usuario habilitar servicios de ubicación
  Future<void> requestLocationServices() async {
    try {
      statusMessage.value = 'Solicitando servicios de ubicación...';
      
      bool enabled = await GpsVerificationService.requestLocationServicesEnable();
      
      if (enabled) {
        // Volver a verificar capacidades después de habilitar servicios
        final updatedCapabilities = await GpsVerificationService.verifyLocationCapabilities();
        locationCapabilities.value = updatedCapabilities;
        
        statusMessage.value = 'Servicios de ubicación habilitados';
        SnackbarUtils.showSuccess(
          title: 'GPS Habilitado',
          message: 'Los servicios de ubicación han sido habilitados correctamente.',
        );
      } else {
        statusMessage.value = 'No se pudieron habilitar los servicios';
        SnackbarUtils.showError(
          title: 'Error GPS',
          message: 'No se pudieron habilitar los servicios de ubicación.',
        );
      }
    } catch (e) {
      await Log.e('SplashController', 'Error solicitando servicios de ubicación', e);
      statusMessage.value = 'Error configurando GPS';
    }
  }
  
  /// Reintenta la verificación completa de GPS
  Future<void> retryGpsVerification() async {
    try {
      statusMessage.value = 'Verificando GPS nuevamente...';
      
      final updatedCapabilities = await GpsVerificationService.verifyLocationCapabilities();
      locationCapabilities.value = updatedCapabilities;
      
      final statusMsg = GpsVerificationService.getLocationStatusMessage(updatedCapabilities);
      statusMessage.value = statusMsg;
      
      await Log.i('SplashController', 'Verificación GPS actualizada: $updatedCapabilities');
      
    } catch (e) {
      await Log.e('SplashController', 'Error en verificación GPS', e);
      statusMessage.value = 'Error verificando GPS';
    }
  }
}