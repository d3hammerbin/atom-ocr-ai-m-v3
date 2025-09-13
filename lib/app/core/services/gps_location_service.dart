import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'logger_service.dart';

class GpsLocationService {
  static GpsLocationService? _instance;
  static GpsLocationService get instance => _instance ??= GpsLocationService._();
  
  // Platform channel para comunicarse con código nativo Android
  static const MethodChannel _channel = MethodChannel('gps_hardware_detector');
  
  GpsLocationService._();

  /// Verifica si el dispositivo tiene hardware GPS físico
  Future<bool> hasGpsHardware() async {
    try {
      await Log.i('GpsLocationService', 'Verificando si el dispositivo tiene hardware GPS físico...');
      
      // Llamar al método nativo para verificar GPS hardware
      final bool hasGps = await _channel.invokeMethod('hasGpsHardware');
      
      await Log.i('GpsLocationService', 'Hardware GPS disponible: $hasGps');
      return hasGps;
    } catch (e) {
      await Log.e('GpsLocationService', 'Error verificando hardware GPS', e);
      // En caso de error, asumir que sí tiene GPS (comportamiento por defecto)
      return true;
    }
  }

  /// Obtiene información completa sobre las capacidades de ubicación del dispositivo
  Future<Map<String, dynamic>> getLocationCapabilities() async {
    try {
      final bool gpsHardwareAvailable = await hasGpsHardware();
      final bool isServiceEnabled = await isLocationServiceEnabled();
      final LocationPermission permission = await checkLocationPermission();
      
      final capabilities = {
        'hasGpsHardware': gpsHardwareAvailable,
        'isServiceEnabled': isServiceEnabled,
        'permissionStatus': permission.toString(),
        'canGetLocation': gpsHardwareAvailable && isServiceEnabled && 
                        (permission == LocationPermission.always || 
                         permission == LocationPermission.whileInUse),
      };
      
      await Log.i('GpsLocationService', 'Capacidades de ubicación: $capabilities');
      return capabilities;
    } catch (e) {
      await Log.e('GpsLocationService', 'Error obteniendo capacidades de ubicación', e);
      return {
        'hasGpsHardware': false,
        'isServiceEnabled': false,
        'permissionStatus': 'unknown',
        'canGetLocation': false,
        'error': e.toString(),
      };
    }
  }

  /// Verifica si los servicios de ubicación están habilitados
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      await Log.e('GpsLocationService', 'Error verificando servicios de ubicación', e);
      return false;
    }
  }

  /// Verifica los permisos de ubicación
  Future<LocationPermission> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      await Log.i('GpsLocationService', 'Estado de permisos de ubicación: $permission');
      return permission;
    } catch (e) {
      await Log.e('GpsLocationService', 'Error verificando permisos de ubicación', e);
      return LocationPermission.denied;
    }
  }

  /// Solicita permisos de ubicación al usuario
  Future<LocationPermission> requestLocationPermission() async {
    try {
      await Log.i('GpsLocationService', 'Solicitando permisos de ubicación al usuario');
      LocationPermission permission = await Geolocator.requestPermission();
      await Log.i('GpsLocationService', 'Permisos de ubicación otorgados: $permission');
      return permission;
    } catch (e) {
      await Log.e('GpsLocationService', 'Error solicitando permisos de ubicación', e);
      return LocationPermission.denied;
    }
  }

  /// Verifica y solicita permisos si es necesario
  Future<bool> ensureLocationPermissions() async {
    try {
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Log.w('GpsLocationService', 'Servicios de ubicación deshabilitados');
        return false;
      }

      // Verificar permisos actuales
      LocationPermission permission = await checkLocationPermission();
      
      if (permission == LocationPermission.denied) {
        // Solicitar permisos
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          await Log.w('GpsLocationService', 'Permisos de ubicación denegados');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Log.w('GpsLocationService', 'Permisos de ubicación denegados permanentemente');
        return false;
      }

      await Log.i('GpsLocationService', 'Permisos de ubicación concedidos');
      return true;
    } catch (e) {
      await Log.e('GpsLocationService', 'Error verificando/solicitando permisos', e);
      return false;
    }
  }

  /// Obtiene la ubicación actual usando GPS de alta precisión
  Future<Position?> getCurrentPosition() async {
    try {
      // Verificar y solicitar permisos de ubicación si es necesario
      LocationPermission permission = await checkLocationPermission();
      
      if (permission == LocationPermission.denied) {
        await Log.i('GpsLocationService', 'Permisos denegados, solicitando permisos al usuario');
        permission = await requestLocationPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        await Log.e('GpsLocationService', 'Permisos denegados permanentemente. El usuario debe habilitarlos manualmente en configuración.');
        return null;
      }
      
      bool hasPermissions = permission == LocationPermission.always || 
                           permission == LocationPermission.whileInUse;
      
      if (!hasPermissions) {
        await Log.w('GpsLocationService', 'No se pudieron obtener permisos de ubicación: $permission');
        return null;
      }

      await Log.i('GpsLocationService', 'Obteniendo ubicación GPS actual...');
      
      // Configuración para GPS de alta precisión
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high, // Alta precisión GPS
        distanceFilter: 0, // Sin filtro de distancia
        timeLimit: Duration(seconds: 30), // Timeout de 30 segundos
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      await Log.i('GpsLocationService', 
        'Ubicación obtenida - Lat: ${position.latitude}, Lng: ${position.longitude}, Precisión: ${position.accuracy}m');
      
      return position;
    } catch (e) {
      await Log.e('GpsLocationService', 'Error obteniendo ubicación GPS', e);
      return null;
    }
  }

  /// Obtiene la ubicación actual con reintentos para mayor confiabilidad offline
  Future<Position?> getCurrentPositionWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await Log.i('GpsLocationService', 'Intento $attempt de $maxRetries para obtener ubicación GPS');
        
        Position? position = await getCurrentPosition();
        if (position != null) {
          await Log.i('GpsLocationService', 'Ubicación GPS obtenida exitosamente en intento $attempt');
          return position;
        }
        
        if (attempt < maxRetries) {
          await Log.w('GpsLocationService', 'Intento $attempt falló, reintentando en 2 segundos...');
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        await Log.e('GpsLocationService', 'Error en intento $attempt', e);
        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    
    await Log.e('GpsLocationService', 'No se pudo obtener ubicación GPS después de $maxRetries intentos');
    return null;
  }

  /// Verifica si la ubicación obtenida es confiable (precisión aceptable)
  bool isLocationReliable(Position position, {double maxAccuracyMeters = 50.0}) {
    bool reliable = position.accuracy <= maxAccuracyMeters;
    if (!reliable) {
      Log.w('GpsLocationService', 
        'Ubicación no confiable - Precisión: ${position.accuracy}m (máximo aceptable: ${maxAccuracyMeters}m)');
    }
    return reliable;
  }

  /// Obtiene información detallada de la ubicación para logging
  Map<String, dynamic> getLocationInfo(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'heading': position.heading,
      'speed': position.speed,
      'speedAccuracy': position.speedAccuracy,
      'timestamp': position.timestamp?.toIso8601String(),
      'isMocked': position.isMocked,
    };
  }
}