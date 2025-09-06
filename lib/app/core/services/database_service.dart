import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Servicio de base de datos SQLite para la aplicación
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const String _databaseName = 'atom_ocr_ai.db';
  static const int _databaseVersion = 5;

  /// Obtiene la instancia de la base de datos
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea las tablas iniciales de la base de datos
  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createUserGeodataTable(db);
    await _createDeviceTable(db);
    await _createCredentialsTable(db);
  }

  /// Maneja las actualizaciones de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar columnas updated_at y last_login_at a la tabla users
      await db.execute('ALTER TABLE users ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP');
      await db.execute('ALTER TABLE users ADD COLUMN last_login_at DATETIME');
    }
    
    if (oldVersion < 3) {
      // Agregar columnas de información de hardware a la tabla device
      await db.execute('ALTER TABLE device ADD COLUMN cpu_type TEXT');
      await db.execute('ALTER TABLE device ADD COLUMN cpu_cores INTEGER');
      await db.execute('ALTER TABLE device ADD COLUMN cpu_architecture TEXT');
      await db.execute('ALTER TABLE device ADD COLUMN gpu_vendor TEXT');
      await db.execute('ALTER TABLE device ADD COLUMN gpu_renderer TEXT');
      await db.execute('ALTER TABLE device ADD COLUMN screen_width REAL');
      await db.execute('ALTER TABLE device ADD COLUMN screen_height REAL');
      await db.execute('ALTER TABLE device ADD COLUMN screen_density REAL');
      await db.execute('ALTER TABLE device ADD COLUMN screen_refresh_rate REAL');
      await db.execute('ALTER TABLE device ADD COLUMN battery_level INTEGER');
      await db.execute('ALTER TABLE device ADD COLUMN battery_status TEXT');
      await db.execute('ALTER TABLE device ADD COLUMN battery_health TEXT');
      await db.execute('ALTER TABLE device ADD COLUMN battery_temperature INTEGER');
      await db.execute('ALTER TABLE device ADD COLUMN available_sensors TEXT');
    }
    
    if (oldVersion < 4) {
      // Agregar tabla de credenciales
      await _createCredentialsTable(db);
    }
    
    if (oldVersion < 5) {
      // Agregar restricción UNIQUE al campo CURP
      await db.execute('CREATE UNIQUE INDEX idx_credentials_curp_unique ON credentials (curp)');
    }
  }

  /// Crea la tabla de usuarios
  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identifier TEXT NOT NULL UNIQUE,
        enabled INTEGER DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_login_at DATETIME
      )
    ''');
  }

  /// Crea la tabla de geodatos de usuario
  Future<void> _createUserGeodataTable(Database db) async {
    await db.execute('''
      CREATE TABLE user_geodata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Crea la tabla de dispositivos
  Future<void> _createDeviceTable(Database db) async {
    await db.execute('''
      CREATE TABLE device (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        serial_number TEXT,
        device_id TEXT,
        android_version TEXT,
        sdk_int INTEGER,
        model TEXT,
        brand TEXT,
        supported_32bit_abis TEXT,
        supported_64bit_abis TEXT,
        supported_abis TEXT,
        physical_ram_size INTEGER,
        available_ram_size INTEGER,
        free_disk_size INTEGER,
        total_disk_size INTEGER,
        is_low_ram_device INTEGER DEFAULT 0,
        cpu_type TEXT,
        cpu_cores INTEGER,
        cpu_architecture TEXT,
        gpu_vendor TEXT,
        gpu_renderer TEXT,
        screen_width REAL,
        screen_height REAL,
        screen_density REAL,
        screen_refresh_rate REAL,
        battery_level INTEGER,
        battery_status TEXT,
        battery_health TEXT,
        battery_temperature INTEGER,
        available_sensors TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Cierra la conexión a la base de datos
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Crea la tabla de credenciales
  Future<void> _createCredentialsTable(Database db) async {
    await db.execute('''
      CREATE TABLE credentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        
        -- Campos principales
        nombre TEXT,
        curp TEXT UNIQUE,
        clave_elector TEXT,
        fecha_nacimiento TEXT,
        sexo TEXT,
        domicilio TEXT,
        
        -- Datos electorales
        estado TEXT,
        municipio TEXT,
        localidad TEXT,
        seccion TEXT,
        ano_registro TEXT,
        vigencia TEXT,
        
        -- Metadatos
        tipo TEXT, -- T2 o T3
        lado TEXT, -- frontal o trasera
        fecha_captura DATETIME DEFAULT CURRENT_TIMESTAMP,
        
        -- Rutas de imágenes
        photo_path TEXT,
        signature_path TEXT,
        qr_image_path TEXT,
        barcode_image_path TEXT,
        mrz_image_path TEXT,
        signature_huella_image_path TEXT,
        
        -- Contenidos extraídos
        qr_content TEXT,
        barcode_content TEXT,
        mrz_content TEXT,
        
        -- Auditoría
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // Crear índices para mejorar el rendimiento
    await db.execute('CREATE INDEX idx_credentials_user_id ON credentials (user_id)');
    await db.execute('CREATE INDEX idx_credentials_curp ON credentials (curp)');
    await db.execute('CREATE INDEX idx_credentials_clave_elector ON credentials (clave_elector)');
    await db.execute('CREATE INDEX idx_credentials_tipo ON credentials (tipo)');
    await db.execute('CREATE INDEX idx_credentials_fecha_captura ON credentials (fecha_captura)');
  }

  /// Elimina la base de datos (útil para desarrollo y testing)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}