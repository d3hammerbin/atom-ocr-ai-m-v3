import 'package:sqflite/sqflite.dart';
import '../models/credential_model.dart';
import '../../core/services/database_service.dart';

/// Repositorio para el manejo de datos de credenciales
class CredentialRepository {
  final DatabaseService _databaseService = DatabaseService();
  static const String _tableName = 'credentials';

  /// Inserta una nueva credencial en la base de datos
  Future<int> insertCredential(CredentialModel credential) async {
    final db = await _databaseService.database;
    final credentialWithTimestamp = credential.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await db.insert(
      _tableName,
      credentialWithTimestamp.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todas las credenciales de un usuario
  Future<List<CredentialModel>> getCredentialsByUserId(int userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'fecha_captura DESC',
    );

    return List.generate(maps.length, (i) {
      return CredentialModel.fromMap(maps[i]);
    });
  }

  /// Obtiene una credencial por su ID
  Future<CredentialModel?> getCredentialById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CredentialModel.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene credenciales por CURP
  Future<List<CredentialModel>> getCredentialsByCurp(String curp) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'curp = ?',
      whereArgs: [curp],
      orderBy: 'fecha_captura DESC',
    );

    return List.generate(maps.length, (i) {
      return CredentialModel.fromMap(maps[i]);
    });
  }

  /// Obtiene credenciales por clave de elector
  Future<List<CredentialModel>> getCredentialsByClaveElector(String claveElector) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'clave_elector = ?',
      whereArgs: [claveElector],
      orderBy: 'fecha_captura DESC',
    );

    return List.generate(maps.length, (i) {
      return CredentialModel.fromMap(maps[i]);
    });
  }

  /// Obtiene credenciales por tipo (T2 o T3)
  Future<List<CredentialModel>> getCredentialsByType(int userId, String tipo) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND tipo = ?',
      whereArgs: [userId, tipo],
      orderBy: 'fecha_captura DESC',
    );

    return List.generate(maps.length, (i) {
      return CredentialModel.fromMap(maps[i]);
    });
  }

  /// Actualiza una credencial existente
  Future<int> updateCredential(CredentialModel credential) async {
    final db = await _databaseService.database;
    final credentialWithTimestamp = credential.copyWith(
      updatedAt: DateTime.now(),
    );
    return await db.update(
      _tableName,
      credentialWithTimestamp.toMap(),
      where: 'id = ?',
      whereArgs: [credential.id],
    );
  }

  /// Elimina una credencial por su ID
  Future<int> deleteCredential(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina todas las credenciales de un usuario
  Future<int> deleteCredentialsByUserId(int userId) async {
    final db = await _databaseService.database;
    return await db.delete(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Obtiene el conteo total de credenciales de un usuario
  Future<int> getCredentialsCount(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Obtiene el conteo de credenciales por tipo
  Future<Map<String, int>> getCredentialsCountByType(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT tipo, COUNT(*) as count FROM $_tableName WHERE user_id = ? GROUP BY tipo',
      [userId],
    );
    
    Map<String, int> counts = {};
    for (var row in result) {
      final tipo = row['tipo'] as String?;
      final count = row['count'] as int;
      if (tipo != null) {
        counts[tipo] = count;
      }
    }
    return counts;
  }

  /// Busca credenciales por nombre (búsqueda parcial)
  Future<List<CredentialModel>> searchCredentialsByName(int userId, String searchTerm) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND nombre LIKE ?',
      whereArgs: [userId, '%$searchTerm%'],
      orderBy: 'fecha_captura DESC',
    );

    return List.generate(maps.length, (i) {
      return CredentialModel.fromMap(maps[i]);
    });
  }

  /// Obtiene las credenciales más recientes de un usuario
  Future<List<CredentialModel>> getRecentCredentials(int userId, {int limit = 10}) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'fecha_captura DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return CredentialModel.fromMap(maps[i]);
    });
  }

  /// Verifica si existe una credencial con la misma CURP y clave de elector
  Future<bool> credentialExists(String curp, String claveElector) async {
    final db = await _databaseService.database;
    final result = await db.query(
      _tableName,
      where: 'curp = ? AND clave_elector = ?',
      whereArgs: [curp, claveElector],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Obtiene estadísticas de credenciales por fecha
  Future<Map<String, dynamic>> getCredentialsStatistics(int userId) async {
    final db = await _databaseService.database;
    
    // Total de credenciales
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM $_tableName WHERE user_id = ?',
      [userId],
    );
    final total = Sqflite.firstIntValue(totalResult) ?? 0;
    
    // Credenciales por tipo
    final typeResult = await db.rawQuery(
      'SELECT tipo, COUNT(*) as count FROM $_tableName WHERE user_id = ? GROUP BY tipo',
      [userId],
    );
    
    // Credenciales del último mes
    final lastMonthResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE user_id = ? AND fecha_captura >= datetime("now", "-1 month")',
      [userId],
    );
    final lastMonth = Sqflite.firstIntValue(lastMonthResult) ?? 0;
    
    return {
      'total': total,
      'lastMonth': lastMonth,
      'byType': Map.fromIterable(
        typeResult,
        key: (item) => item['tipo'],
        value: (item) => item['count'],
      ),
    };
  }
}