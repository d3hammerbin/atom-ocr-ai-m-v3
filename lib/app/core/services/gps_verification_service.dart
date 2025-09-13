import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'logger_service.dart';
import 'location_fallback_service.dart';

/// Servicio para verificar disponibilidad de GPS y fuentes de geolocalización
class GpsVerificationService {
  static final LocationFallbackService _locationService = LocationFallbackService.instance;
  
  /// Resultado de la verificación de GPS
  static const String GPS_HARDWARE_AVAILABLE = 'gps_hardware_available';
  static const String GPS_PERMISSION_GRANTED = 'gps_permission_granted';
  static const String GPS_SERVICE_ENABLED = 'gps_service_enabled';
  static const String NETWORK_LOCATION_AVAILABLE = 'network_location_available';
  static const String PASSIVE_LOCATION_AVAILABLE = 'passive_location_available';
  
  /// Verifica completamente la disponibilidad de GPS y fuentes de geolocalización
  static Future<Map<String, bool>> verifyLocationCapabilities() async {
    try {
      await Log.i('GpsVerificationService', 'Iniciando verificación completa de capacidades de ubicación');
      
      Map<String, bool> capabilities = {
        GPS_HARDWARE_AVAILABLE: false,
        GPS_PERMISSION_GRANTED: false,
        GPS_SERVICE_ENABLED: false,
        NETWORK_LOCATION_AVAILABLE: false,
        PASSIVE_LOCATION_AVAILABLE: false,
      };
      
      // Paso 1: Verificar hardware GPS físico
      capabilities[GPS_HARDWARE_AVAILABLE] = await _verifyGpsHardware();
      await Log.i('GpsVerificationService', 'Hardware GPS disponible: ${capabilities[GPS_HARDWARE_AVAILABLE]}');
      
      // Paso 2: Verificar permisos de ubicación
      capabilities[GPS_PERMISSION_GRANTED] = await _verifyLocationPermissions();
      await Log.i('GpsVerificationService', 'Permisos de ubicación concedidos: ${capabilities[GPS_PERMISSION_GRANTED]}');
      
      // Paso 3: Verificar si los servicios de ubicación están habilitados
      if (capabilities[GPS_HARDWARE_AVAILABLE]! || capabilities[GPS_PERMISSION_GRANTED]!) {
        capabilities[GPS_SERVICE_ENABLED] = await _verifyLocationServicesEnabled();
        await Log.i('GpsVerificationService', 'Servicios de ubicación habilitados: ${capabilities[GPS_SERVICE_ENABLED]}');
      }
      
      // Paso 4: Verificar fuentes alternativas de geolocalización
      capabilities[NETWORK_LOCATION_AVAILABLE] = await _verifyNetworkLocation();
      capabilities[PASSIVE_LOCATION_AVAILABLE] = await _verifyPassiveLocation();
      
      await Log.i('GpsVerificationService', 'Verificación completa finalizada: $capabilities');
      return capabilities;
      
    } catch (e) {
      await Log.e('GpsVerificationService', 'Error durante la verificación de capacidades de ubicación', e);
      return {
        GPS_HARDWARE_AVAILABLE: false,
        GPS_PERMISSION_GRANTED: false,
        GPS_SERVICE_ENABLED: false,
        NETWORK_LOCATION_AVAILABLE: false,
        PASSIVE_LOCATION_AVAILABLE: false,
      };
    }
  }
  
  /// Verifica si el hardware GPS está disponible
  static Future<bool> _verifyGpsHardware() async {
    try {
      return await _locationService.hasGpsHardware();
    } catch (e) {
      await Log.e('GpsVerificationService', 'Error verificando hardware GPS', e);
      return false;
    }
  }
  
  /// Verifica y solicita permisos de ubicación
  static Future<bool> _verifyLocationPermissions() async {
    try {
      // Verificar estado actual de permisos
      final locationStatus = await Permission.location.status;
      final locationAlwaysStatus = await Permission.locationAlways.status;
      final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
      
      // Si ya están concedidos, retornar true
      if (locationStatus.isGranted || 
          locationAlwaysStatus.isGranted || 
          locationWhenInUseStatus.isGranted) {
        await Log.i('GpsVerificationService', 'Permisos de ubicación ya concedidos');
        return true;
      }
      
      // Solicitar permisos de ubicación
      await Log.i('GpsVerificationService', 'Solicitando permisos de ubicación');
      
      // Primero intentar ubicación cuando la app está en uso
      final whenInUseResult = await Permission.locationWhenInUse.request();
      if (whenInUseResult.isGranted) {
        return true;
      }
      
      // Si no se concede, intentar ubicación general
      final locationResult = await Permission.location.request();
      return locationResult.isGranted;
      
    } catch (e) {
      await Log.e('GpsVerificationService', 'Error verificando permisos de ubicación', e);
      return false;
    }
  }
  
  /// Verifica si los servicios de ubicación están habilitados en el dispositivo
  static Future<bool> _verifyLocationServicesEnabled() async {
    try {
      final capabilities = await _locationService.getLocationCapabilities();
      return capabilities['serviceEnabled'] ?? false;
    } catch (e) {
      await Log.e('GpsVerificationService', 'Error verificando servicios de ubicación', e);
      return false;
    }
  }
  
  /// Verifica disponibilidad de ubicación por red (WiFi/datos móviles)
  static Future<bool> _verifyNetworkLocation() async {
    try {
      // En Android, verificar si la ubicación por red está disponible
      if (Platform.isAndroid) {
        final capabilities = await _locationService.getLocationCapabilities();
        return capabilities['networkLocationAvailable'] ?? false;
      }
      
      // En iOS, la ubicación por red generalmente está disponible si hay permisos
      final locationStatus = await Permission.location.status;
      return locationStatus.isGranted;
      
    } catch (e) {
      await Log.e('GpsVerificationService', 'Error verificando ubicación por red', e);
      return false;
    }
  }
  
  /// Verifica disponibilidad de ubicación pasiva
  static Future<bool> _verifyPassiveLocation() async {
    try {
      // La ubicación pasiva generalmente está disponible si hay permisos básicos
      final locationStatus = await Permission.location.status;
      final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
      
      return locationStatus.isGranted || locationWhenInUseStatus.isGranted;
      
    } catch (e) {
      await Log.e('GpsVerificationService', 'Error verificando ubicación pasiva', e);
      return false;
    }
  }
  
  /// Determina si hay al menos una fuente de geolocalización disponible
  static bool hasAnyLocationSource(Map<String, bool> capabilities) {
    return capabilities[GPS_HARDWARE_AVAILABLE]! ||
           capabilities[NETWORK_LOCATION_AVAILABLE]! ||
           capabilities[PASSIVE_LOCATION_AVAILABLE]!;
  }
  
  /// Determina si la configuración de ubicación es óptima
  static bool hasOptimalLocationSetup(Map<String, bool> capabilities) {
    return capabilities[GPS_HARDWARE_AVAILABLE]! &&
           capabilities[GPS_PERMISSION_GRANTED]! &&
           capabilities[GPS_SERVICE_ENABLED]!;
  }
  
  /// Obtiene un mensaje descriptivo del estado de las capacidades de ubicación
  static String getLocationStatusMessage(Map<String, bool> capabilities) {
    if (hasOptimalLocationSetup(capabilities)) {
      return 'GPS completamente configurado y disponible';
    }
    
    if (capabilities[GPS_HARDWARE_AVAILABLE]! && !capabilities[GPS_PERMISSION_GRANTED]!) {
      return 'Hardware GPS disponible, pero faltan permisos';
    }
    
    if (capabilities[GPS_HARDWARE_AVAILABLE]! && !capabilities[GPS_SERVICE_ENABLED]!) {
      return 'Hardware GPS disponible, pero servicios deshabilitados';
    }
    
    if (capabilities[NETWORK_LOCATION_AVAILABLE]!) {
      return 'GPS no disponible, usando ubicación por red';
    }
    
    if (capabilities[PASSIVE_LOCATION_AVAILABLE]!) {
      return 'Solo ubicación pasiva disponible';
    }
    
    return 'No hay fuentes de geolocalización disponibles';
  }
  
  /// Solicita al usuario que habilite los servicios de ubicación
  static Future<bool> requestLocationServicesEnable() async {
    try {
      await Log.i('GpsVerificationService', 'Solicitando habilitación de servicios de ubicación');
      
      // En Android, podemos abrir la configuración de ubicación
      if (Platform.isAndroid) {
        await openAppSettings();
        
        // Esperar un momento y verificar nuevamente
        await Future.delayed(const Duration(seconds: 2));
        return await _verifyLocationServicesEnabled();
      }
      
      // En iOS, también abrir configuración
      await openAppSettings();
      await Future.delayed(const Duration(seconds: 2));
      return await _verifyLocationServicesEnabled();
      
    } catch (e) {
      await Log.e('GpsVerificationService', 'Error solicitando habilitación de servicios', e);
      return false;
    }
  }
}