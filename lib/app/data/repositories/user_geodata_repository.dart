import 'package:sqflite/sqflite.dart';
import '../models/user_geodata_model.dart';
import '../../core/services/database_service.dart';

/// Repositorio para el manejo de datos geográficos de usuarios
class UserGeodataRepository {
  final DatabaseService _databaseService = DatabaseService();
  static const String _tableName = 'user_geodata';

  /// Inserta un nuevo registro de geodatos
  Future<int> insertGeodata(UserGeodataModel geodata) async {
    final db = await _databaseService.database;
    return await db.insert(
      _tableName,
      geodata.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene un registro de geodatos por su ID
  Future<UserGeodataModel?> getGeodataById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return UserGeodataModel.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene todos los geodatos de un usuario específico
  Future<List<UserGeodataModel>> getGeodataByUserId(int userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return UserGeodataModel.fromMap(maps[i]);
    });
  }

  /// Obtiene los geodatos más recientes de un usuario
  Future<UserGeodataModel?> getLatestGeodataByUserId(int userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return UserGeodataModel.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene todos los geodatos
  Future<List<UserGeodataModel>> getAllGeodata() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return UserGeodataModel.fromMap(maps[i]);
    });
  }

  /// Obtiene geodatos dentro de un rango de fechas
  Future<List<UserGeodataModel>> getGeodataByDateRange(
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
      return UserGeodataModel.fromMap(maps[i]);
    });
  }

  /// Obtiene geodatos dentro de un radio específico
  Future<List<UserGeodataModel>> getGeodataWithinRadius(
    double centerLatitude,
    double centerLongitude,
    double radiusInKm, {
    int? userId,
  }) async {
    final db = await _databaseService.database;
    
    // Usar la fórmula de Haversine para calcular la distancia
    String query = '''
      SELECT * FROM $_tableName
      WHERE (
        6371 * acos(
          cos(radians(?)) * cos(radians(latitude)) *
          cos(radians(longitude) - radians(?)) +
          sin(radians(?)) * sin(radians(latitude))
        )
      ) <= ?
    ''';
    
    List<dynamic> args = [
      centerLatitude,
      centerLongitude,
      centerLatitude,
      radiusInKm,
    ];

    if (userId != null) {
      query += ' AND user_id = ?';
      args.add(userId);
    }

    query += ' ORDER BY created_at DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

    return List.generate(maps.length, (i) {
      return UserGeodataModel.fromMap(maps[i]);
    });
  }

  /// Actualiza un registro de geodatos
  Future<int> updateGeodata(UserGeodataModel geodata) async {
    final db = await _databaseService.database;
    return await db.update(
      _tableName,
      geodata.toMap(),
      where: 'id = ?',
      whereArgs: [geodata.id],
    );
  }

  /// Elimina un registro de geodatos por su ID
  Future<int> deleteGeodata(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina todos los geodatos de un usuario
  Future<int> deleteGeodataByUserId(int userId) async {
    final db = await _databaseService.database;
    return await db.delete(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Cuenta el total de registros de geodatos
  Future<int> getGeodataCount({int? userId}) async {
    final db = await _databaseService.database;
    
    String query = 'SELECT COUNT(*) as count FROM $_tableName';
    List<dynamic> args = [];
    
    if (userId != null) {
      query += ' WHERE user_id = ?';
      args.add(userId);
    }
    
    final result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}