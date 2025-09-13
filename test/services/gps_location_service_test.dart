import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../lib/app/core/services/gps_location_service.dart';

void main() {
  // Inicializar Flutter binding para las pruebas
  TestWidgetsFlutterBinding.ensureInitialized();
  group('GpsLocationService Tests', () {
    late GpsLocationService gpsService;

    setUp(() {
      gpsService = GpsLocationService.instance;
    });

    test('should be a singleton', () {
      final instance1 = GpsLocationService.instance;
      final instance2 = GpsLocationService.instance;
      expect(instance1, same(instance2));
    });

    test('should validate location reliability correctly', () {
      // Crear posiciones de prueba con diferentes niveles de precisión
      final highAccuracyPosition = Position(
        latitude: 19.4326,
        longitude: -99.1332,
        timestamp: DateTime.now(),
        accuracy: 5.0, // Alta precisión
        altitude: 2240.0,
        altitudeAccuracy: 3.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      final lowAccuracyPosition = Position(
        latitude: 19.4326,
        longitude: -99.1332,
        timestamp: DateTime.now(),
        accuracy: 150.0, // Baja precisión
        altitude: 2240.0,
        altitudeAccuracy: 3.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      // Verificar que la validación funciona correctamente
      expect(gpsService.isLocationReliable(highAccuracyPosition), isTrue);
      expect(gpsService.isLocationReliable(lowAccuracyPosition), isFalse);
    });

    test('should provide detailed location info', () {
      final testPosition = Position(
        latitude: 19.4326,
        longitude: -99.1332,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 2240.0,
        altitudeAccuracy: 3.0,
        heading: 45.0,
        headingAccuracy: 5.0,
        speed: 2.5,
        speedAccuracy: 1.0,
      );

      final locationInfo = gpsService.getLocationInfo(testPosition);

      expect(locationInfo, isA<Map<String, dynamic>>());
      expect(locationInfo['latitude'], equals(19.4326));
      expect(locationInfo['longitude'], equals(-99.1332));
      expect(locationInfo['accuracy'], equals(10.0));
      expect(locationInfo['altitude'], equals(2240.0));
      expect(locationInfo['heading'], equals(45.0));
      expect(locationInfo['speed'], equals(2.5));
      expect(locationInfo.containsKey('timestamp'), isTrue);
      expect(locationInfo.containsKey('isMocked'), isTrue);
    });

    test('should handle service instantiation correctly', () {
      // Verificar que el servicio se puede instanciar correctamente
      expect(gpsService, isNotNull);
      expect(gpsService, isA<GpsLocationService>());
    });
  });

  group('GpsLocationService Logic Tests', () {
    test('should validate GPS functionality exists', () {
      final gpsService = GpsLocationService.instance;
      
      // Verificar que los métodos principales existen
      expect(gpsService.isLocationReliable, isA<Function>());
      expect(gpsService.getLocationInfo, isA<Function>());
      expect(gpsService.getCurrentPositionWithRetry, isA<Function>());
      expect(gpsService.isLocationServiceEnabled, isA<Function>());
      expect(gpsService.checkLocationPermission, isA<Function>());
    });
  });
}