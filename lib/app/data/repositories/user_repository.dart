import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../../core/services/database_service.dart';

/// Repositorio para el manejo de datos de usuarios
class UserRepository {
  final DatabaseService _databaseService = DatabaseService();
  static const String _tableName = 'users';

  /// Inserta un nuevo usuario en la base de datos
  Future<int> insertUser(UserModel user) async {
    final db = await _databaseService.database;
    return await db.insert(
      _tableName,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene un usuario por su ID
  Future<UserModel?> getUserById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene un usuario por su identificador único (solo usuarios activos)
  Future<UserModel?> getUserByIdentifier(String identifier) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'identifier = ? AND enabled = 1',
      whereArgs: [identifier],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene todos los usuarios
  Future<List<UserModel>> getAllUsers() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return UserModel.fromMap(maps[i]);
    });
  }

  /// Obtiene todos los usuarios habilitados
  Future<List<UserModel>> getEnabledUsers() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return UserModel.fromMap(maps[i]);
    });
  }

  /// Actualiza un usuario existente
  Future<int> updateUser(UserModel user) async {
    final db = await _databaseService.database;
    return await db.update(
      _tableName,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Habilita o deshabilita un usuario
  Future<int> toggleUserStatus(int id, bool enabled) async {
    final db = await _databaseService.database;
    return await db.update(
      _tableName,
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un usuario por su ID
  Future<int> deleteUser(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Cuenta el total de usuarios
  Future<int> getUserCount() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Verifica si existe un usuario con el identificador dado
  Future<bool> userExists(String identifier) async {
    final user = await getUserByIdentifier(identifier);
    return user != null;
  }

  /// Crea un nuevo usuario con validación
  Future<UserModel> createUser(String identifier) async {
    // Validar formato del identificador
    if (!UserModel.isValidIdentifier(identifier)) {
      throw ArgumentError('El identificador debe tener exactamente 4 dígitos numéricos');
    }

    // Verificar que no exista ya
    if (await userExists(identifier)) {
      throw StateError('Ya existe un usuario con el identificador $identifier');
    }

    final now = DateTime.now();
    final newUser = UserModel(
      identifier: identifier,
      enabled: true,
      createdAt: now,
      updatedAt: now,
      lastLoginAt: now,
    );

    final id = await insertUser(newUser);
    return newUser.copyWith(id: id);
  }

  /// Actualiza la fecha de último login del usuario
  Future<int> updateLastLogin(String identifier) async {
    final db = await _databaseService.database;
    
    return await db.update(
      _tableName,
      {
        'last_login_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'identifier = ? AND enabled = 1',
      whereArgs: [identifier],
    );
  }
}