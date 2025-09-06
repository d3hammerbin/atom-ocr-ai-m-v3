import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:system_info2/system_info2.dart';
import 'package:flutter/services.dart';
import '../../data/models/device_model.dart';

/// Servicio para obtener información del dispositivo Android
class DeviceInfoService extends GetxService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Battery _battery = Battery();
  AndroidDeviceInfo? _androidInfo;

  @override
  void onInit() {
    super.onInit();
    _initializeDeviceInfo();
  }

  /// Inicializa la información del dispositivo
  Future<void> _initializeDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        _androidInfo = await _deviceInfo.androidInfo;
      }
    } catch (e) {
      Get.log('Error al inicializar información del dispositivo: $e');
    }
  }

  /// Obtiene información completa del dispositivo para un usuario específico
  Future<DeviceModel> getDeviceInfo(int userId) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Este servicio solo funciona en Android');
    }

    // Asegurar que la información del dispositivo esté disponible
    _androidInfo ??= await _deviceInfo.androidInfo;
    final androidInfo = _androidInfo!;

    // Obtener número de serie o ID alternativo
    final serialInfo = await _getSerialNumberOrDeviceId();

    // Obtener información adicional de hardware
    final cpuInfo = await _getCpuInfo();
    final gpuInfo = await _getGpuInfo();
    final screenInfo = await _getScreenInfo();
    final batteryInfo = await _getBatteryInfo();
    final sensorsInfo = await _getAvailableSensors();

    return DeviceModel(
      userId: userId,
      serialNumber: serialInfo['serialNumber'],
      deviceId: serialInfo['deviceId'],
      androidVersion: androidInfo.version.release,
      sdkInt: androidInfo.version.sdkInt,
      model: androidInfo.model,
      brand: androidInfo.brand,
      supported32BitAbis: androidInfo.supported32BitAbis.join(','),
      supported64BitAbis: androidInfo.supported64BitAbis.join(','),
      supportedAbis: androidInfo.supportedAbis.join(','),
      physicalRamSize: null, // totalMemory no está disponible en device_info_plus
      isLowRamDevice: androidInfo.isLowRamDevice,
      // Información de CPU
      cpuType: cpuInfo['type'],
      cpuCores: cpuInfo['cores'],
      cpuArchitecture: cpuInfo['architecture'],
      // Información de GPU
      gpuVendor: gpuInfo['vendor'],
      gpuRenderer: gpuInfo['renderer'],
      // Información de pantalla
      screenWidth: screenInfo['width'],
      screenHeight: screenInfo['height'],
      screenDensity: screenInfo['density'],
      screenRefreshRate: screenInfo['refreshRate'],
      // Información de batería
      batteryLevel: batteryInfo['level'],
      batteryStatus: batteryInfo['status'],
      batteryHealth: batteryInfo['health'],
      batteryTemperature: batteryInfo['temperature'],
      // Sensores disponibles
      availableSensors: sensorsInfo,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Obtiene el número de serie del dispositivo o el ID alternativo
  Future<Map<String, String?>> _getSerialNumberOrDeviceId() async {
    if (!Platform.isAndroid) {
      return {'serialNumber': null, 'deviceId': null};
    }

    final androidInfo = _androidInfo!;
    String? serialNumber;
    String? deviceId = androidInfo.id; // ID alternativo siempre disponible

    try {
      // Verificar la versión de Android para determinar la estrategia
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 29) {
        // Android 10+ (API 29+): Solo apps de sistema pueden acceder
        // Para apps normales, getSerial() devuelve "UNKNOWN"
        Get.log('Android 10+: Número de serie no disponible para apps normales');
        serialNumber = null;
      } else if (sdkInt >= 28) {
        // Android 9 (API 28): Necesita READ_PHONE_STATE
        final hasPermission = await _requestPhoneStatePermission();
        if (hasPermission) {
          serialNumber = await _getSerialNumber();
        }
      } else if (sdkInt >= 26) {
        // Android 8 (API 26-27): Build.getSerial() disponible con permiso
        final hasPermission = await _requestPhoneStatePermission();
        if (hasPermission) {
          serialNumber = await _getSerialNumber();
        }
      } else {
        // Android < 8: Número de serie disponible sin permisos especiales
        serialNumber = await _getSerialNumber();
      }

      // Si no se pudo obtener el número de serie o es "UNKNOWN", usar el ID del dispositivo
      if (serialNumber == null || serialNumber == 'UNKNOWN' || serialNumber.isEmpty) {
        Get.log('Usando androidInfo.id como identificador del dispositivo');
        serialNumber = null; // Mantener null para indicar que no está disponible
      }
    } catch (e) {
      Get.log('Error al obtener número de serie: $e');
      serialNumber = null;
    }

    return {
      'serialNumber': serialNumber,
      'deviceId': deviceId,
    };
  }

  /// Solicita el permiso READ_PHONE_STATE
  Future<bool> _requestPhoneStatePermission() async {
    try {
      final status = await Permission.phone.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        final result = await Permission.phone.request();
        return result.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        Get.log('Permiso READ_phone_state permanentemente denegado');
        return false;
      }
      
      return false;
    } catch (e) {
      Get.log('Error al solicitar permiso READ_phone_state: $e');
      return false;
    }
  }

  /// Intenta obtener el número de serie del dispositivo
  Future<String?> _getSerialNumber() async {
    try {
      // Nota: En device_info_plus, el número de serie se obtiene a través de androidInfo.serialNumber
      // Sin embargo, esto puede devolver "UNKNOWN" en versiones recientes de Android
      final androidInfo = _androidInfo!;
      
      // Intentar obtener el número de serie
      // En versiones recientes de Android, esto puede devolver "UNKNOWN"
      final serial = androidInfo.serialNumber;
      
      if (serial != 'UNKNOWN' && serial.isNotEmpty) {
        return serial;
      }
      
      return null;
    } catch (e) {
      Get.log('Error al obtener número de serie: $e');
      return null;
    }
  }

  /// Obtiene información básica del dispositivo sin permisos especiales
  Future<Map<String, dynamic>> getBasicDeviceInfo() async {
    if (!Platform.isAndroid) {
      return {};
    }

    _androidInfo ??= await _deviceInfo.androidInfo;
    final androidInfo = _androidInfo!;

    return {
      'model': androidInfo.model,
      'brand': androidInfo.brand,
      'androidVersion': androidInfo.version.release,
      'sdkInt': androidInfo.version.sdkInt,
      'deviceId': androidInfo.id,
      'isLowRamDevice': androidInfo.isLowRamDevice,
    };
  }

  /// Verifica si el dispositivo puede proporcionar el número de serie
  Future<bool> canGetSerialNumber() async {
    if (!Platform.isAndroid) {
      return false;
    }

    _androidInfo ??= await _deviceInfo.androidInfo;
    final sdkInt = _androidInfo!.version.sdkInt;

    // Android 10+ (API 29+): Solo apps de sistema
    if (sdkInt >= 29) {
      return false;
    }

    // Android 8-9 (API 26-28): Requiere permiso
    if (sdkInt >= 26) {
      final hasPermission = await Permission.phone.status;
      return hasPermission.isGranted;
    }

    // Android < 8: Disponible sin permisos especiales
    return true;
  }

  /// Obtiene el identificador único del dispositivo (serial o ID)
  Future<String> getUniqueDeviceIdentifier() async {
    final serialInfo = await _getSerialNumberOrDeviceId();
    
    // Preferir número de serie si está disponible
    if (serialInfo['serialNumber'] != null && serialInfo['serialNumber']!.isNotEmpty) {
      return serialInfo['serialNumber']!;
    }
    
    // Usar ID del dispositivo como alternativa
    return serialInfo['deviceId'] ?? 'UNKNOWN_DEVICE';
  }

  /// Obtiene información de la CPU
  Future<Map<String, dynamic>> _getCpuInfo() async {
    try {
      final architecture = SysInfo.kernelArchitecture;
      final cores = SysInfo.cores.length;
      
      return {
        'type': null, // No disponible en system_info2
        'cores': cores > 0 ? cores : null,
        'architecture': architecture.toString().split('.').last,
      };
    } catch (e) {
      Get.log('Error al obtener información de CPU: $e');
      return {
        'type': null,
        'cores': null,
        'architecture': null,
      };
    }
  }

  /// Obtiene información de la GPU
  Future<Map<String, dynamic>> _getGpuInfo() async {
    try {
      // Intentar obtener información de GPU usando platform channels
      const platform = MethodChannel('device_info/gpu');
      final result = await platform.invokeMethod('getGpuInfo');
      
      return {
        'vendor': result['vendor'],
        'renderer': result['renderer'],
      };
    } catch (e) {
      Get.log('Error al obtener información de GPU: $e');
      return {
        'vendor': null,
        'renderer': null,
      };
    }
  }

  /// Obtiene información de la pantalla
  Future<Map<String, dynamic>> _getScreenInfo() async {
    try {
      // Obtener información de pantalla usando MediaQuery o platform channels
      const platform = MethodChannel('device_info/screen');
      final result = await platform.invokeMethod('getScreenInfo');
      
      return {
        'width': result['width']?.toDouble(),
        'height': result['height']?.toDouble(),
        'density': result['density']?.toDouble(),
        'refreshRate': result['refreshRate']?.toDouble(),
      };
    } catch (e) {
      Get.log('Error al obtener información de pantalla: $e');
      return {
        'width': null,
        'height': null,
        'density': null,
        'refreshRate': null,
      };
    }
  }

  /// Obtiene información de la batería
  Future<Map<String, dynamic>> _getBatteryInfo() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      
      // Intentar obtener información adicional de batería
      const platform = MethodChannel('device_info/battery');
      Map<String, dynamic>? additionalInfo;
      
      try {
        additionalInfo = await platform.invokeMethod('getBatteryInfo');
      } catch (e) {
        Get.log('No se pudo obtener información adicional de batería: $e');
      }
      
      return {
        'level': batteryLevel,
        'status': _batteryStateToString(batteryState),
        'health': additionalInfo?['health'],
        'temperature': additionalInfo?['temperature'],
      };
    } catch (e) {
      Get.log('Error al obtener información de batería: $e');
      return {
        'level': null,
        'status': null,
        'health': null,
        'temperature': null,
      };
    }
  }

  /// Convierte el estado de la batería a string
  String _batteryStateToString(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return 'Cargando';
      case BatteryState.discharging:
        return 'Descargando';
      case BatteryState.full:
        return 'Completa';
      case BatteryState.unknown:
      default:
        return 'Desconocido';
    }
  }

  /// Obtiene la lista de sensores disponibles
  Future<String?> _getAvailableSensors() async {
    try {
      final List<String> availableSensors = [];
      
      // Verificar sensores disponibles
      try {
        // Intentar acceder a cada sensor para verificar disponibilidad
        accelerometerEventStream().listen(null).cancel();
        availableSensors.add('Acelerómetro');
      } catch (e) {
        // Sensor no disponible
      }
      
      try {
        gyroscopeEventStream().listen(null).cancel();
        availableSensors.add('Giroscopio');
      } catch (e) {
        // Sensor no disponible
      }
      
      try {
        magnetometerEventStream().listen(null).cancel();
        availableSensors.add('Magnetómetro');
      } catch (e) {
        // Sensor no disponible
      }
      
      try {
        userAccelerometerEventStream().listen(null).cancel();
        availableSensors.add('Acelerómetro de Usuario');
      } catch (e) {
        // Sensor no disponible
      }
      
      // Intentar obtener sensores adicionales usando platform channels
      try {
        const platform = MethodChannel('device_info/sensors');
        final additionalSensors = await platform.invokeMethod('getAvailableSensors');
        if (additionalSensors is List) {
          availableSensors.addAll(additionalSensors.cast<String>());
        }
      } catch (e) {
        Get.log('No se pudieron obtener sensores adicionales: $e');
      }
      
      return availableSensors.isNotEmpty ? jsonEncode(availableSensors) : null;
    } catch (e) {
      Get.log('Error al obtener sensores disponibles: $e');
      return null;
    }
  }
}