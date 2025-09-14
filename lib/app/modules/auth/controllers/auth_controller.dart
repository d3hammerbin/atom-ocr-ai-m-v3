import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/device_info_service.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/user_session_service.dart';
import '../../../core/services/location_fallback_service.dart';
import '../../../data/models/geo_login_model.dart';
import '../../../data/repositories/geo_login_repository.dart';
import '../../../routes/app_pages.dart';

class AuthController extends GetxController {
  final UserRepository _userRepository = Get.find<UserRepository>();
  final DeviceInfoService _deviceInfoService = Get.find<DeviceInfoService>();
  final DeviceRepository _deviceRepository = Get.find<DeviceRepository>();
  final LocationFallbackService _locationService = LocationFallbackService.instance;
  final GeoLoginRepository _geoLoginRepository = GeoLoginRepository();

  // Estados reactivos
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString identifierInput = ''.obs;
  final RxBool isValidIdentifier = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Escuchar cambios en el input del identificador
    identifierInput.listen((value) {
      isValidIdentifier.value = UserModel.isValidIdentifier(value);
      if (errorMessage.value.isNotEmpty) {
        errorMessage.value = '';
      }
    });
  }

  /// Verifica si hay un usuario activo y maneja el flujo inicial
  Future<void> checkInitialUserStatus() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Verificar si hay usuarios registrados
      final totalUsers = await _userRepository.getUserCount();
      
      if (totalUsers > 0) {
        // Hay usuarios registrados, ir directamente a selección de captura
        await Log.i('AuthController', 'Usuario existente encontrado, redirigiendo a captura');
        Get.offAllNamed(Routes.CAPTURE_SELECTION);
      } else {
        // No hay usuarios, mostrar pantalla inicial
        await Log.i('AuthController', 'No hay usuarios registrados, mostrando pantalla inicial');
        // La pantalla inicial ya está siendo mostrada
      }
    } catch (e) {
      await Log.e('AuthController', 'Error verificando estado inicial del usuario', e);
      errorMessage.value = 'Error al verificar el estado del usuario';
    } finally {
      isLoading.value = false;
    }
  }

  /// Maneja el proceso completo de inicio (verificación/registro + permisos + dispositivo)
  Future<void> handleStartProcess() async {
    if (!isValidIdentifier.value) {
      errorMessage.value = 'Por favor ingresa un identificador válido de 4 dígitos';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final identifier = identifierInput.value;
      await Log.i('AuthController', 'Iniciando proceso para identificador: $identifier');

      // Verificar si ya existe algún usuario registrado
      final totalUsers = await _userRepository.getUserCount();
      
      if (totalUsers > 0) {
        // Ya existe un usuario registrado, verificar que el ID coincida
        final allUsers = await _userRepository.getAllUsers();
        final firstUser = allUsers.first;
        
        if (firstUser.identifier != identifier) {
          // ID diferente al registrado, mostrar error de identificación
          errorMessage.value = 'Error de identificación: Este dispositivo ya está registrado con un ID diferente';
          await Log.w('AuthController', 'Intento de acceso con ID incorrecto. ID registrado: ${firstUser.identifier}, ID ingresado: $identifier');
          return;
        }
        
        // ID correcto, proceder con autenticación
        await _userRepository.updateLastLogin(firstUser.identifier);
        await Log.i('AuthController', 'Usuario existente autenticado: ${firstUser.id}');
        
        // Iniciar sesión de usuario
        final sessionService = UserSessionService.to;
        await sessionService.startSession(firstUser);
        
        await Log.i('AuthController', 'Sesión iniciada para usuario: ${firstUser.identifier}');
        
        // Capturar datos de geolocalización
        await _captureGeoLocation(firstUser.identifier);
        
        // Proceder con verificación de permisos
        await _handlePermissionsAndDeviceFlow(firstUser);
      } else {
        // No hay usuarios registrados, crear el primer usuario
        await Log.i('AuthController', 'Creando primer usuario con identificador: $identifier');
        
        final createdUser = await _userRepository.createUser(identifier);
        if (createdUser.id != null && createdUser.id! > 0) {
          await Log.i('AuthController', 'Primer usuario creado con ID: ${createdUser.id}');
          
          // Iniciar sesión de usuario
          final sessionService = UserSessionService.to;
          await sessionService.startSession(createdUser);
          
          await Log.i('AuthController', 'Sesión iniciada para usuario: ${createdUser.identifier}');
          
          // Capturar datos de geolocalización
          await _captureGeoLocation(createdUser.identifier);
          
          // Proceder con verificación de permisos y dispositivo
          await _handlePermissionsAndDeviceFlow(createdUser);
        } else {
          throw Exception('Error al crear el usuario');
        }
      }
    } catch (e) {
      await Log.e('AuthController', 'Error en proceso de inicio', e);
      errorMessage.value = 'Error al procesar el inicio: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// Maneja el flujo de permisos y información del dispositivo
  Future<void> _handlePermissionsAndDeviceFlow(UserModel user) async {
    try {
      await Log.i('AuthController', 'Iniciando flujo de permisos para usuario: ${user.id}');
      
      // Verificar y solicitar permisos
      bool permissionsGranted = await PermissionService.initialize();
      
      if (!permissionsGranted) {
        errorMessage.value = 'Los permisos son necesarios para continuar';
        return;
      }
      
      await Log.i('AuthController', 'Permisos concedidos, obteniendo información del dispositivo');
      
      // Obtener información del dispositivo
        try {
          final deviceInfo = await _deviceInfoService.getDeviceInfo(user.id!);
          
          // Guardar o actualizar información del dispositivo
          await _deviceRepository.upsertDevice(deviceInfo);
          
          await Log.i('AuthController', 'Información del dispositivo guardada exitosamente');
          
        } catch (deviceError) {
          await Log.w('AuthController', 'Error obteniendo info del dispositivo, continuando sin ella');
        }
        
        // Proceso completado, redirigir a selección de captura
        Get.offAllNamed(Routes.CAPTURE_SELECTION);
      
    } catch (e) {
      await Log.e('AuthController', 'Error en flujo de permisos y dispositivo', e);
      errorMessage.value = 'Error al configurar la aplicación: ${e.toString()}';
    }
  }

  /// Actualiza el valor del identificador
  void updateIdentifier(String value) {
    identifierInput.value = value;
  }

  /// Limpia el estado del controlador
  void clearState() {
    identifierInput.value = '';
    errorMessage.value = '';
    isLoading.value = false;
    isValidIdentifier.value = false;
  }

  /// Valida el formato del identificador en tiempo real
  String? validateIdentifier(String? value) {
    if (value == null || value.isEmpty) {
      return 'El identificador es requerido';
    }
    
    if (!UserModel.isValidIdentifier(value)) {
      return 'Debe ser un número de 4 dígitos';
    }
    
    return null;
  }

  /// Captura y guarda los datos de geolocalización durante el login usando sistema de fallback
  Future<void> _captureGeoLocation(String userIdentifier) async {
    try {
      await Log.i('AuthController', 'Iniciando captura de geolocalización con sistema de fallback para usuario: $userIdentifier');
      
      // Obtener ubicación usando sistema de fallback (GPS → Network → Passive)
      LocationResult? locationResult = await _locationService.getLocationWithFallback(
        timeout: const Duration(seconds: 45), // Timeout más generoso para el fallback
        maxAccuracyMeters: 100.0, // Criterio de precisión más flexible
      );
      
      if (locationResult != null) {
        // Crear registro de geo login con el método de ubicación usado
        final geoLogin = GeoLoginModel(
          usuario: userIdentifier,
          latitud: locationResult.position.latitude,
          longitud: locationResult.position.longitude,
          fechaInsercion: DateTime.now(),
          metodoUbicacion: locationResult.method,
        );
        
        // Guardar en la base de datos
        int geoLoginId = await _geoLoginRepository.insertGeoLogin(geoLogin);
        
        await Log.i('AuthController', 
          'Geolocalización guardada exitosamente - ID: $geoLoginId, '
          'Método: ${locationResult.method.displayName}, '
          'Lat: ${locationResult.position.latitude}, Lng: ${locationResult.position.longitude}, '
          'Precisión: ${locationResult.position.accuracy}m, Confiable: ${locationResult.isReliable}');
        
        // Log información adicional de la ubicación
        Map<String, dynamic> locationInfo = locationResult.toMap();
        await Log.d('AuthController', 'Información detallada de ubicación: $locationInfo');
        
        // Log advertencia si la ubicación no es confiable
        if (!locationResult.isReliable && locationResult.errorMessage != null) {
          await Log.w('AuthController', 'Advertencia de ubicación: ${locationResult.errorMessage}');
        }
        
      } else {
        await Log.w('AuthController', 
          'No se pudo obtener ubicación con ningún método disponible para el usuario: $userIdentifier. '
          'Continuando con el proceso de login sin datos de geolocalización.');
      }
    } catch (e) {
      await Log.e('AuthController', 'Error capturando geolocalización', e);
      // No interrumpir el proceso de login por errores de geolocalización
    }
  }

  @override
  void onClose() {
    clearState();
    super.onClose();
  }
}