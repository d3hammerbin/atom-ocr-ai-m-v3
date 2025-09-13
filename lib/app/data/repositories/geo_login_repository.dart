import '../models/geo_login_model.dart';
import '../../core/services/database_service.dart';

class GeoLoginRepository {
  final DatabaseService _databaseService = DatabaseService();

  /// Inserta un nuevo registro de geo login
  Future<int> insertGeoLogin(GeoLoginModel geoLogin) async {
    final db = await _databaseService.database;
    return await db.insert('geo_login', geoLogin.toMap());
  }

  /// Obtiene un registro de geo login por ID
  Future<GeoLoginModel?> getGeoLoginById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'geo_login',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return GeoLoginModel.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene todos los registros de geo login por usuario
  Future<List<GeoLoginModel>> getGeoLoginsByUsuario(String usuario) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'geo_login',
      where: 'usuario = ?',
      whereArgs: [usuario],
      orderBy: 'fecha_insercion DESC',
    );

    return List.generate(maps.length, (i) {
      return GeoLoginModel.fromMap(maps[i]);
    });
  }

  /// Obtiene todos los registros de geo login
  Future<List<GeoLoginModel>> getAllGeoLogins() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'geo_login',
      orderBy: 'fecha_insercion DESC',
    );

    return List.generate(maps.length, (i) {
      return GeoLoginModel.fromMap(maps[i]);
    });
  }

  /// Obtiene los registros de geo login en un rango de fechas
  Future<List<GeoLoginModel>> getGeoLoginsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'geo_login',
      where: 'fecha_insercion BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'fecha_insercion DESC',
    );

    return List.generate(maps.length, (i) {
      return GeoLoginModel.fromMap(maps[i]);
    });
  }

  /// Obtiene el último registro de geo login de un usuario
  Future<GeoLoginModel?> getLastGeoLoginByUsuario(String usuario) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'geo_login',
      where: 'usuario = ?',
      whereArgs: [usuario],
      orderBy: 'fecha_insercion DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return GeoLoginModel.fromMap(maps.first);
    }
    return null;
  }

  /// Elimina un registro de geo login por ID
  Future<int> deleteGeoLogin(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'geo_login',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina todos los registros de geo login de un usuario
  Future<int> deleteGeoLoginsByUsuario(String usuario) async {
    final db = await _databaseService.database;
    return await db.delete(
      'geo_login',
      where: 'usuario = ?',
      whereArgs: [usuario],
    );
  }

  /// Cuenta el total de registros de geo login
  Future<int> getGeoLoginCount() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM geo_login');
    return result.first['count'] as int;
  }

  /// Cuenta los registros de geo login de un usuario específico
  Future<int> getGeoLoginCountByUsuario(String usuario) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM geo_login WHERE usuario = ?',
      [usuario],
    );
    return result.first['count'] as int;
  }
}