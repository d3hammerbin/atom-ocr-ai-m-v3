import 'package:sqflite/sqflite.dart';
import '../models/device_model.dart';
import '../../core/services/database_service.dart';

/// Repositorio para el manejo de datos de dispositivos
class DeviceRepository {
  final DatabaseService _databaseService = DatabaseService();
  static const String _tableName = 'device';

  /// Inserta un nuevo dispositivo en la base de datos
  Future<int> insertDevice(DeviceModel device) async {
    final db = await _databaseService.database;
    return await db.insert(
      _tableName,
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene un dispositivo por su ID
  Future<DeviceModel?> getDeviceById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return DeviceModel.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene todos los dispositivos de un usuario específico
  Future<List<DeviceModel>> getDevicesByUserId(int userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return DeviceModel.fromMap(maps[i]);
    });
  }

  /// Obtiene el dispositivo más reciente de un usuario
  Future<DeviceModel?> getLatestDeviceByUserId(int userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return DeviceModel.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene un dispositivo por número de serie
  Future<DeviceModel?> getDeviceBySerialNumber(String serialNumber) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'serial_number = ?',
      whereArgs: [serialNumber],
    );

    if (maps.isNotEmpty) {
      return DeviceModel.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene un dispositivo por ID del dispositivo
  Future<DeviceModel?> getDeviceByDeviceId(String deviceId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );

    if (maps.isNotEmpty) {
      return DeviceModel.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene todos los dispositivos
  Future<List<DeviceModel>> getAllDevices() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return DeviceModel.fromMap(maps[i]);
    });
  }

  /// Actualiza un dispositivo existente
  Future<int> updateDevice(DeviceModel device) async {
    final db = await _databaseService.database;
    
    // Actualizar el campo updated_at
    final updatedDevice = device.copyWith(updatedAt: DateTime.now());
    
    return await db.update(
      _tableName,
      updatedDevice.toMap(),
      where: 'id = ?',
      whereArgs: [device.id],
    );
  }

  /// Actualiza o inserta un dispositivo basado en el identificador único
  Future<int> upsertDevice(DeviceModel device) async {
    // Buscar dispositivo existente por número de serie o ID del dispositivo
    DeviceModel? existingDevice;
    
    if (device.serialNumber != null && device.serialNumber!.isNotEmpty) {
      existingDevice = await getDeviceBySerialNumber(device.serialNumber!);
    }
    
    if (existingDevice == null && device.deviceId != null && device.deviceId!.isNotEmpty) {
      existingDevice = await getDeviceByDeviceId(device.deviceId!);
    }
    
    if (existingDevice != null) {
      // Actualizar dispositivo existente
      final updatedDevice = device.copyWith(
        id: existingDevice.id,
        createdAt: existingDevice.createdAt,
        updatedAt: DateTime.now(),
      );
      await updateDevice(updatedDevice);
      return existingDevice.id!;
    } else {
      // Insertar nuevo dispositivo
      return await insertDevice(device);
    }
  }

  /// Elimina un dispositivo por su ID
  Future<int> deleteDevice(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina todos los dispositivos de un usuario
  Future<int> deleteDevicesByUserId(int userId) async {
    final db = await _databaseService.database;
    return await db.delete(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Cuenta el total de dispositivos
  Future<int> getDeviceCount() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Cuenta los dispositivos de un usuario específico
  Future<int> getDeviceCountByUserId(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Verifica si existe un dispositivo con el número de serie dado
  Future<bool> deviceExistsBySerialNumber(String serialNumber) async {
    final device = await getDeviceBySerialNumber(serialNumber);
    return device != null;
  }

  /// Verifica si existe un dispositivo con el ID del dispositivo dado
  Future<bool> deviceExistsByDeviceId(String deviceId) async {
    final device = await getDeviceByDeviceId(deviceId);
    return device != null;
  }

  /// Obtiene dispositivos por rango de fechas
  Future<List<DeviceModel>> getDevicesByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? userId,
  }) async {
    final db = await _databaseService.database;
    
    String whereClause = 'created_at BETWEEN ? AND ?';
    List<dynamic> whereArgs = [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ];

    if (userId != null) {
      whereClause += ' AND user_id = ?';
      whereArgs.add(userId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return DeviceModel.fromMap(maps[i]);
    });
  }

  /// Obtiene dispositivos de baja RAM
  Future<List<DeviceModel>> getLowRamDevices() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'is_low_ram_device = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return DeviceModel.fromMap(maps[i]);
    });
  }

  /// Obtiene dispositivos por marca
  Future<List<DeviceModel>> getDevicesByBrand(String brand) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'brand = ?',
      whereArgs: [brand],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return DeviceModel.fromMap(maps[i]);
    });
  }

  /// Obtiene dispositivos por versión de Android
  Future<List<DeviceModel>> getDevicesByAndroidVersion(String androidVersion) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'android_version = ?',
      whereArgs: [androidVersion],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return DeviceModel.fromMap(maps[i]);
    });
  }
}