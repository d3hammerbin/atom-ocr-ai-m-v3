import 'package:geolocator/geolocator.dart';
import 'logger_service.dart';
import '../enums/location_method.dart';

/// Resultado de la obtención de ubicación con información del método usado
class LocationResult {
  final Position position;
  final LocationMethod method;
  final bool isReliable;
  final String? errorMessage;

  const LocationResult({
    required this.position,
    required this.method,
    required this.isReliable,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'method': method.toDbString(),
      'isReliable': isReliable,
      'timestamp': position.timestamp.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }
}

class LocationFallbackService {
  static LocationFallbackService? _instance;
  static LocationFallbackService get instance => _instance ??= LocationFallbackService._();
  
  // Removido el canal nativo para evitar MissingPluginException
  
  LocationFallbackService._();

  /// Obtiene la ubicación usando el sistema de fallback con prioridades
  /// Prioridad: GPS → Network → Passive
  Future<LocationResult?> getLocationWithFallback({
    Duration timeout = const Duration(seconds: 30),
    double maxAccuracyMeters = 50.0,
  }) async {
    await Log.i('LocationFallbackService', 'Iniciando obtención de ubicación con sistema de fallback');
    
    // Verificar permisos primero
    if (!await _ensureLocationPermissions()) {
      await Log.e('LocationFallbackService', 'No se pudieron obtener permisos de ubicación');
      return null;
    }

    // Intentar GPS físico primero (máxima prioridad)
    LocationResult? result = await _tryGpsLocation(timeout, maxAccuracyMeters);
    if (result != null && result.isReliable) {
      await Log.i('LocationFallbackService', 'Ubicación obtenida exitosamente con GPS físico');
      return result;
    }

    // Fallback a Network Location
    result = await _tryNetworkLocation(timeout, maxAccuracyMeters);
    if (result != null && result.isReliable) {
      await Log.i('LocationFallbackService', 'Ubicación obtenida exitosamente con Network Location');
      return result;
    }

    // Fallback final a Passive Location
    result = await _tryPassiveLocation(timeout, maxAccuracyMeters);
    if (result != null) {
      await Log.i('LocationFallbackService', 'Ubicación obtenida con Passive Location (última opción)');
      return result;
    }

    await Log.e('LocationFallbackService', 'No se pudo obtener ubicación con ningún método');
    return null;
  }

  /// Intenta obtener ubicación usando GPS físico de alta precisión
  Future<LocationResult?> _tryGpsLocation(Duration timeout, double maxAccuracyMeters) async {
    try {
      await Log.i('LocationFallbackService', 'Intentando obtener ubicación con GPS físico...');
      
      // Verificar si tiene hardware GPS
      bool hasGpsHardware = await _hasGpsHardware();
      if (!hasGpsHardware) {
        await Log.w('LocationFallbackService', 'Hardware GPS no disponible, saltando a siguiente método');
        return null;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high, // GPS de alta precisión
        distanceFilter: 0,
        timeLimit: Duration(seconds: 15), // Timeout más corto para GPS
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(timeout);

      bool isReliable = position.accuracy <= maxAccuracyMeters;
      
      await Log.i('LocationFallbackService', 
        'GPS - Lat: ${position.latitude}, Lng: ${position.longitude}, Precisión: ${position.accuracy}m, Confiable: $isReliable');

      return LocationResult(
        position: position,
        method: LocationMethod.gps,
        isReliable: isReliable,
      );
    } catch (e) {
      await Log.w('LocationFallbackService', 'Error obteniendo ubicación GPS: $e');
      return null;
    }
  }

  /// Intenta obtener ubicación usando Network Location (torres celulares/WiFi)
  Future<LocationResult?> _tryNetworkLocation(Duration timeout, double maxAccuracyMeters) async {
    try {
      await Log.i('LocationFallbackService', 'Intentando obtener ubicación con Network Location...');
      
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium, // Precisión media para network
        distanceFilter: 0,
        timeLimit: Duration(seconds: 10),
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(timeout);

      // Network location es menos preciso, usar criterio más flexible
      bool isReliable = position.accuracy <= (maxAccuracyMeters * 2);
      
      await Log.i('LocationFallbackService', 
        'Network - Lat: ${position.latitude}, Lng: ${position.longitude}, Precisión: ${position.accuracy}m, Confiable: $isReliable');

      return LocationResult(
        position: position,
        method: LocationMethod.network,
        isReliable: isReliable,
      );
    } catch (e) {
      await Log.w('LocationFallbackService', 'Error obteniendo ubicación Network: $e');
      return null;
    }
  }

  /// Intenta obtener ubicación usando Passive Location (última ubicación conocida)
  Future<LocationResult?> _tryPassiveLocation(Duration timeout, double maxAccuracyMeters) async {
    try {
      await Log.i('LocationFallbackService', 'Intentando obtener ubicación con Passive Location...');
      
      // Intentar obtener la última ubicación conocida
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      
      if (lastPosition != null) {
        // Verificar que la ubicación no sea muy antigua (máximo 1 hora)
        DateTime now = DateTime.now();
        DateTime? positionTime = lastPosition.timestamp;
        
        if (now.difference(positionTime).inHours <= 1) {
          bool isReliable = lastPosition.accuracy <= (maxAccuracyMeters * 3); // Criterio más flexible
          
          await Log.i('LocationFallbackService', 
            'Passive - Lat: ${lastPosition.latitude}, Lng: ${lastPosition.longitude}, Precisión: ${lastPosition.accuracy}m, Edad: ${now.difference(positionTime).inMinutes}min');

          return LocationResult(
            position: lastPosition,
            method: LocationMethod.passive,
            isReliable: isReliable,
            errorMessage: isReliable ? null : 'Ubicación pasiva con baja precisión',
          );
        } else {
          await Log.w('LocationFallbackService', 'Última ubicación conocida es muy antigua');
        }
      }

      // Si no hay última ubicación, intentar con configuración de baja precisión
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 0,
        timeLimit: Duration(seconds: 5),
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 10));

      await Log.i('LocationFallbackService', 
        'Passive (nueva) - Lat: ${position.latitude}, Lng: ${position.longitude}, Precisión: ${position.accuracy}m');

      return LocationResult(
        position: position,
        method: LocationMethod.passive,
        isReliable: false, // Passive siempre se considera menos confiable
        errorMessage: 'Ubicación obtenida con método pasivo (baja confiabilidad)',
      );
    } catch (e) {
      await Log.w('LocationFallbackService', 'Error obteniendo ubicación Passive: $e');
      return null;
    }
  }

  /// Verifica si el dispositivo tiene hardware GPS físico
  /// Usa detección indirecta sin canal nativo para evitar MissingPluginException
  Future<bool> _hasGpsHardware() async {
    try {
      // Intentar obtener ubicación GPS de alta precisión como prueba
      const LocationSettings gpsSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        timeLimit: Duration(seconds: 3),
      );
      
      Position? position = await Geolocator.getCurrentPosition(
        locationSettings: gpsSettings,
      ).timeout(const Duration(seconds: 5));
      
      // Si obtenemos una posición con alta precisión, probablemente hay GPS
      bool hasGps = position.accuracy <= 20.0;
      await Log.i('LocationFallbackService', 'Hardware GPS detectado indirectamente: $hasGps (precisión: ${position.accuracy}m)');
      return hasGps;
    } catch (e) {
      await Log.i('LocationFallbackService', 'No se pudo detectar GPS específico, asumiendo disponible para compatibilidad');
      return true; // Asumir disponible para mantener funcionalidad
    }
  }

  /// Verifica y solicita permisos de ubicación
  Future<bool> _ensureLocationPermissions() async {
    try {
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Log.w('LocationFallbackService', 'Servicios de ubicación deshabilitados');
        return false;
      }

      // Verificar permisos actuales
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await Log.w('LocationFallbackService', 'Permisos de ubicación denegados');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Log.w('LocationFallbackService', 'Permisos de ubicación denegados permanentemente');
        return false;
      }

      return true;
    } catch (e) {
      await Log.e('LocationFallbackService', 'Error verificando permisos', e);
      return false;
    }
  }

  /// Verifica si el dispositivo tiene hardware GPS físico (método público)
  Future<bool> hasGpsHardware() async {
    return await _hasGpsHardware();
  }

  /// Solicita permisos de ubicación al usuario (método público)
  Future<bool> requestLocationPermission() async {
    return await _ensureLocationPermissions();
  }

  /// Verifica si los servicios de ubicación están habilitados
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Obtiene información detallada sobre las capacidades de ubicación
  Future<Map<String, dynamic>> getLocationCapabilities() async {
    try {
      final bool gpsHardwareAvailable = await _hasGpsHardware();
      final bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      final LocationPermission permission = await Geolocator.checkPermission();
      
      return {
        'hasGpsHardware': gpsHardwareAvailable,
        'serviceEnabled': isServiceEnabled,
        'isServiceEnabled': isServiceEnabled, // Mantener compatibilidad
        'permissionStatus': permission.toString(),
        'canGetLocation': isServiceEnabled && 
                        (permission == LocationPermission.always || 
                         permission == LocationPermission.whileInUse),
        'networkLocationAvailable': true, // Network location generalmente disponible
        'availableMethods': [
          if (gpsHardwareAvailable) 'gps',
          'network',
          'passive',
        ],
      };
    } catch (e) {
      await Log.e('LocationFallbackService', 'Error obteniendo capacidades de ubicación', e);
      return {
        'hasGpsHardware': false,
        'isServiceEnabled': false,
        'permissionStatus': 'unknown',
        'canGetLocation': false,
        'availableMethods': [],
        'error': e.toString(),
      };
    }
  }
}