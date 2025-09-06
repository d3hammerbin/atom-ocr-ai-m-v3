import 'package:get/get.dart';
import 'database_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/user_geodata_repository.dart';
import '../../data/models/user_model.dart';

/// Servicio para la inicialización y migración de la base de datos
class DatabaseInitializationService extends GetxService {
  static DatabaseInitializationService get to => Get.find();
  
  final DatabaseService _databaseService = DatabaseService();
  final UserRepository _userRepository = UserRepository();
  final UserGeodataRepository _geodataRepository = UserGeodataRepository();
  
  bool _isInitialized = false;
  
  /// Indica si la base de datos ha sido inicializada
  bool get isInitialized => _isInitialized;

  @override
  Future<void> onInit() async {
    super.onInit();
    await initializeDatabase();
  }

  /// Inicializa la base de datos y ejecuta migraciones si es necesario
  Future<void> initializeDatabase() async {
    try {
      // Inicializar la base de datos
      await _databaseService.database;
      
      // Ejecutar configuración inicial si es necesario
      await _runInitialSetup();
      
      _isInitialized = true;
      
      print('Base de datos inicializada correctamente');
    } catch (e) {
      print('Error al inicializar la base de datos: $e');
      rethrow;
    }
  }

  /// Ejecuta la configuración inicial de la base de datos
  Future<void> _runInitialSetup() async {
    try {
      // Verificar si ya existe algún usuario
      final userCount = await _userRepository.getUserCount();
      
      if (userCount == 0) {
        // Crear usuario por defecto si no existe ninguno
        await _createDefaultUser();
      }
      
      print('Configuración inicial completada');
    } catch (e) {
      print('Error en la configuración inicial: $e');
      rethrow;
    }
  }

  /// Crea un usuario por defecto para la aplicación
  Future<void> _createDefaultUser() async {
    try {
      final defaultUser = UserModel(
        identifier: 'default_user_${DateTime.now().millisecondsSinceEpoch}',
        enabled: true,
        createdAt: DateTime.now(),
      );
      
      await _userRepository.insertUser(defaultUser);
      print('Usuario por defecto creado');
    } catch (e) {
      print('Error al crear usuario por defecto: $e');
      rethrow;
    }
  }

  /// Reinicia la base de datos (útil para desarrollo y testing)
  Future<void> resetDatabase() async {
    try {
      await _databaseService.deleteDatabase();
      _isInitialized = false;
      await initializeDatabase();
      print('Base de datos reiniciada');
    } catch (e) {
      print('Error al reiniciar la base de datos: $e');
      rethrow;
    }
  }

  /// Obtiene estadísticas de la base de datos
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final userCount = await _userRepository.getUserCount();
      final geodataCount = await _geodataRepository.getGeodataCount();
      
      return {
        'users': userCount,
        'geodata_records': geodataCount,
      };
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return {
        'users': 0,
        'geodata_records': 0,
      };
    }
  }

  /// Verifica la integridad de la base de datos
  Future<bool> checkDatabaseIntegrity() async {
    try {
      // Verificar que las tablas existan y tengan la estructura correcta
      final db = await _databaseService.database;
      
      // Verificar tabla users
      final usersTableInfo = await db.rawQuery("PRAGMA table_info(users)");
      if (usersTableInfo.isEmpty) {
        print('Tabla users no encontrada');
        return false;
      }
      
      // Verificar tabla user_geodata
      final geodataTableInfo = await db.rawQuery("PRAGMA table_info(user_geodata)");
      if (geodataTableInfo.isEmpty) {
        print('Tabla user_geodata no encontrada');
        return false;
      }
      
      // Verificar tabla device
      final deviceTableInfo = await db.rawQuery("PRAGMA table_info(device)");
      if (deviceTableInfo.isEmpty) {
        print('Tabla device no encontrada');
        return false;
      }
      
      print('Integridad de la base de datos verificada');
      return true;
    } catch (e) {
      print('Error al verificar integridad: $e');
      return false;
    }
  }

  /// Ejecuta una migración manual si es necesario
  Future<void> runMigration(int targetVersion) async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('PRAGMA user_version');
      final currentVersion = result.first['user_version'] as int;
      
      if (currentVersion < targetVersion) {
        // Aquí se pueden agregar migraciones específicas
        print('Ejecutando migración de versión $currentVersion a $targetVersion');
        
        // Ejemplo de migración futura:
        // if (currentVersion < 2) {
        //   await _migrateToVersion2(db);
        // }
        
        await db.rawQuery('PRAGMA user_version = $targetVersion');
        print('Migración completada');
      }
    } catch (e) {
      print('Error durante la migración: $e');
      rethrow;
    }
  }

  /// Cierra la conexión a la base de datos
  Future<void> closeDatabase() async {
    try {
      await _databaseService.close();
      _isInitialized = false;
      print('Conexión a la base de datos cerrada');
    } catch (e) {
      print('Error al cerrar la base de datos: $e');
    }
  }
}