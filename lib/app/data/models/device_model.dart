/// Modelo de datos para la tabla device
class DeviceModel {
  final int? id;
  final int userId;
  final String? serialNumber;
  final String? deviceId;
  final String? androidVersion;
  final int? sdkInt;
  final String? model;
  final String? brand;
  final String? supported32BitAbis;
  final String? supported64BitAbis;
  final String? supportedAbis;
  final int? physicalRamSize;
  final int? availableRamSize;
  final int? freeDiskSize;
  final int? totalDiskSize;
  final bool isLowRamDevice;
  
  // Información de CPU
  final String? cpuType;
  final int? cpuCores;
  final String? cpuArchitecture;
  
  // Información de GPU
  final String? gpuVendor;
  final String? gpuRenderer;
  
  // Información de pantalla
  final double? screenWidth;
  final double? screenHeight;
  final double? screenDensity;
  final double? screenRefreshRate;
  
  // Información de batería
  final int? batteryLevel;
  final String? batteryStatus;
  final String? batteryHealth;
  final int? batteryTemperature;
  
  // Información de sensores (JSON string con lista de sensores disponibles)
  final String? availableSensors;
  
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DeviceModel({
    this.id,
    required this.userId,
    this.serialNumber,
    this.deviceId,
    this.androidVersion,
    this.sdkInt,
    this.model,
    this.brand,
    this.supported32BitAbis,
    this.supported64BitAbis,
    this.supportedAbis,
    this.physicalRamSize,
    this.availableRamSize,
    this.freeDiskSize,
    this.totalDiskSize,
    this.isLowRamDevice = false,
    this.cpuType,
    this.cpuCores,
    this.cpuArchitecture,
    this.gpuVendor,
    this.gpuRenderer,
    this.screenWidth,
    this.screenHeight,
    this.screenDensity,
    this.screenRefreshRate,
    this.batteryLevel,
    this.batteryStatus,
    this.batteryHealth,
    this.batteryTemperature,
    this.availableSensors,
    this.createdAt,
    this.updatedAt,
  });

  /// Crea una instancia desde un Map (resultado de consulta SQL)
  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      serialNumber: map['serial_number'] as String?,
      deviceId: map['device_id'] as String?,
      androidVersion: map['android_version'] as String?,
      sdkInt: map['sdk_int'] as int?,
      model: map['model'] as String?,
      brand: map['brand'] as String?,
      supported32BitAbis: map['supported_32bit_abis'] as String?,
      supported64BitAbis: map['supported_64bit_abis'] as String?,
      supportedAbis: map['supported_abis'] as String?,
      physicalRamSize: map['physical_ram_size'] as int?,
      availableRamSize: map['available_ram_size'] as int?,
      freeDiskSize: map['free_disk_size'] as int?,
      totalDiskSize: map['total_disk_size'] as int?,
      isLowRamDevice: (map['is_low_ram_device'] as int?) == 1,
      cpuType: map['cpu_type'] as String?,
      cpuCores: map['cpu_cores'] as int?,
      cpuArchitecture: map['cpu_architecture'] as String?,
      gpuVendor: map['gpu_vendor'] as String?,
      gpuRenderer: map['gpu_renderer'] as String?,
      screenWidth: map['screen_width'] as double?,
      screenHeight: map['screen_height'] as double?,
      screenDensity: map['screen_density'] as double?,
      screenRefreshRate: map['screen_refresh_rate'] as double?,
      batteryLevel: map['battery_level'] as int?,
      batteryStatus: map['battery_status'] as String?,
      batteryHealth: map['battery_health'] as String?,
      batteryTemperature: map['battery_temperature'] as int?,
      availableSensors: map['available_sensors'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convierte la instancia a Map para inserción/actualización SQL
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (deviceId != null) 'device_id': deviceId,
      if (androidVersion != null) 'android_version': androidVersion,
      if (sdkInt != null) 'sdk_int': sdkInt,
      if (model != null) 'model': model,
      if (brand != null) 'brand': brand,
      if (supported32BitAbis != null) 'supported_32bit_abis': supported32BitAbis,
      if (supported64BitAbis != null) 'supported_64bit_abis': supported64BitAbis,
      if (supportedAbis != null) 'supported_abis': supportedAbis,
      if (physicalRamSize != null) 'physical_ram_size': physicalRamSize,
      if (availableRamSize != null) 'available_ram_size': availableRamSize,
      if (freeDiskSize != null) 'free_disk_size': freeDiskSize,
      if (totalDiskSize != null) 'total_disk_size': totalDiskSize,
      'is_low_ram_device': isLowRamDevice ? 1 : 0,
      if (cpuType != null) 'cpu_type': cpuType,
      if (cpuCores != null) 'cpu_cores': cpuCores,
      if (cpuArchitecture != null) 'cpu_architecture': cpuArchitecture,
      if (gpuVendor != null) 'gpu_vendor': gpuVendor,
      if (gpuRenderer != null) 'gpu_renderer': gpuRenderer,
      if (screenWidth != null) 'screen_width': screenWidth,
      if (screenHeight != null) 'screen_height': screenHeight,
      if (screenDensity != null) 'screen_density': screenDensity,
      if (screenRefreshRate != null) 'screen_refresh_rate': screenRefreshRate,
      if (batteryLevel != null) 'battery_level': batteryLevel,
      if (batteryStatus != null) 'battery_status': batteryStatus,
      if (batteryHealth != null) 'battery_health': batteryHealth,
      if (batteryTemperature != null) 'battery_temperature': batteryTemperature,
      if (availableSensors != null) 'available_sensors': availableSensors,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Crea una copia del modelo con valores actualizados
  DeviceModel copyWith({
    int? id,
    int? userId,
    String? serialNumber,
    String? deviceId,
    String? androidVersion,
    int? sdkInt,
    String? model,
    String? brand,
    String? supported32BitAbis,
    String? supported64BitAbis,
    String? supportedAbis,
    int? physicalRamSize,
    int? availableRamSize,
    int? freeDiskSize,
    int? totalDiskSize,
    bool? isLowRamDevice,
    String? cpuType,
    int? cpuCores,
    String? cpuArchitecture,
    String? gpuVendor,
    String? gpuRenderer,
    double? screenWidth,
    double? screenHeight,
    double? screenDensity,
    double? screenRefreshRate,
    int? batteryLevel,
    String? batteryStatus,
    String? batteryHealth,
    int? batteryTemperature,
    String? availableSensors,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serialNumber: serialNumber ?? this.serialNumber,
      deviceId: deviceId ?? this.deviceId,
      androidVersion: androidVersion ?? this.androidVersion,
      sdkInt: sdkInt ?? this.sdkInt,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      supported32BitAbis: supported32BitAbis ?? this.supported32BitAbis,
      supported64BitAbis: supported64BitAbis ?? this.supported64BitAbis,
      supportedAbis: supportedAbis ?? this.supportedAbis,
      physicalRamSize: physicalRamSize ?? this.physicalRamSize,
      availableRamSize: availableRamSize ?? this.availableRamSize,
      freeDiskSize: freeDiskSize ?? this.freeDiskSize,
      totalDiskSize: totalDiskSize ?? this.totalDiskSize,
      isLowRamDevice: isLowRamDevice ?? this.isLowRamDevice,
      cpuType: cpuType ?? this.cpuType,
      cpuCores: cpuCores ?? this.cpuCores,
      cpuArchitecture: cpuArchitecture ?? this.cpuArchitecture,
      gpuVendor: gpuVendor ?? this.gpuVendor,
      gpuRenderer: gpuRenderer ?? this.gpuRenderer,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
      screenDensity: screenDensity ?? this.screenDensity,
      screenRefreshRate: screenRefreshRate ?? this.screenRefreshRate,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryStatus: batteryStatus ?? this.batteryStatus,
      batteryHealth: batteryHealth ?? this.batteryHealth,
      batteryTemperature: batteryTemperature ?? this.batteryTemperature,
      availableSensors: availableSensors ?? this.availableSensors,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DeviceModel(id: $id, userId: $userId, serialNumber: $serialNumber, deviceId: $deviceId, androidVersion: $androidVersion, sdkInt: $sdkInt, model: $model, brand: $brand, isLowRamDevice: $isLowRamDevice, cpuType: $cpuType, cpuCores: $cpuCores, batteryLevel: $batteryLevel, screenWidth: $screenWidth, screenHeight: $screenHeight, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceModel &&
        other.id == id &&
        other.userId == userId &&
        other.serialNumber == serialNumber &&
        other.deviceId == deviceId &&
        other.androidVersion == androidVersion &&
        other.sdkInt == sdkInt &&
        other.model == model &&
        other.brand == brand &&
        other.supported32BitAbis == supported32BitAbis &&
        other.supported64BitAbis == supported64BitAbis &&
        other.supportedAbis == supportedAbis &&
        other.physicalRamSize == physicalRamSize &&
        other.availableRamSize == availableRamSize &&
        other.freeDiskSize == freeDiskSize &&
        other.totalDiskSize == totalDiskSize &&
        other.isLowRamDevice == isLowRamDevice &&
        other.cpuType == cpuType &&
        other.cpuCores == cpuCores &&
        other.cpuArchitecture == cpuArchitecture &&
        other.gpuVendor == gpuVendor &&
        other.gpuRenderer == gpuRenderer &&
        other.screenWidth == screenWidth &&
        other.screenHeight == screenHeight &&
        other.screenDensity == screenDensity &&
        other.screenRefreshRate == screenRefreshRate &&
        other.batteryLevel == batteryLevel &&
        other.batteryStatus == batteryStatus &&
        other.batteryHealth == batteryHealth &&
        other.batteryTemperature == batteryTemperature &&
        other.availableSensors == availableSensors &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        serialNumber.hashCode ^
        deviceId.hashCode ^
        androidVersion.hashCode ^
        sdkInt.hashCode ^
        model.hashCode ^
        brand.hashCode ^
        supported32BitAbis.hashCode ^
        supported64BitAbis.hashCode ^
        supportedAbis.hashCode ^
        physicalRamSize.hashCode ^
        availableRamSize.hashCode ^
        freeDiskSize.hashCode ^
        totalDiskSize.hashCode ^
        isLowRamDevice.hashCode ^
        cpuType.hashCode ^
        cpuCores.hashCode ^
        cpuArchitecture.hashCode ^
        gpuVendor.hashCode ^
        gpuRenderer.hashCode ^
        screenWidth.hashCode ^
        screenHeight.hashCode ^
        screenDensity.hashCode ^
        screenRefreshRate.hashCode ^
        batteryLevel.hashCode ^
        batteryStatus.hashCode ^
        batteryHealth.hashCode ^
        batteryTemperature.hashCode ^
        availableSensors.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}