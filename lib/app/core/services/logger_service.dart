import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Niveles de logging disponibles
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Servicio de logging para la aplicación
class LoggerService {
  static LoggerService? _instance;
  static LoggerService get instance => _instance ??= LoggerService._();
  
  LoggerService._();
  
  late Directory _logDirectory;
  late File _currentLogFile;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  final DateFormat _fileNameFormat = DateFormat('yyyy-MM-dd');
  
  /// Inicializa el servicio de logging
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _logDirectory = Directory('${appDir.path}/logs');
      
      if (!await _logDirectory.exists()) {
        await _logDirectory.create(recursive: true);
      }
      
      // Crear archivo de log para el día actual
      final today = _fileNameFormat.format(DateTime.now());
      _currentLogFile = File('${_logDirectory.path}/app_log_$today.txt');
      
      // Limpiar logs antiguos (mantener solo los últimos 7 días)
      await _cleanOldLogs();
      
      // Log de inicialización
      await _writeToFile(LogLevel.info, 'LoggerService', 'Servicio de logging inicializado');
    } catch (e) {
      // Fallback a debugPrint si no se puede inicializar el logger
      debugPrint('Error inicializando LoggerService: $e');
    }
  }
  
  /// Registra un mensaje de debug
  Future<void> debug(String tag, String message) async {
    await _log(LogLevel.debug, tag, message);
  }
  
  /// Registra un mensaje informativo
  Future<void> info(String tag, String message) async {
    await _log(LogLevel.info, tag, message);
  }
  
  /// Registra un mensaje de advertencia
  Future<void> warning(String tag, String message) async {
    await _log(LogLevel.warning, tag, message);
  }
  
  /// Registra un mensaje de error
  Future<void> error(String tag, String message, [Object? error, StackTrace? stackTrace]) async {
    String fullMessage = message;
    if (error != null) {
      fullMessage += ' - Error: $error';
    }
    if (stackTrace != null) {
      fullMessage += '\nStackTrace: $stackTrace';
    }
    await _log(LogLevel.error, tag, fullMessage);
  }
  
  /// Método interno para logging
  Future<void> _log(LogLevel level, String tag, String message) async {
    try {
      final timestamp = _dateFormat.format(DateTime.now());
      final levelStr = level.name.toUpperCase().padRight(7);
      final logEntry = '[$timestamp] [$levelStr] [$tag] $message';
      
      // Escribir a archivo
      await _writeToFile(level, tag, message);
      
      // También mostrar en consola durante desarrollo
      debugPrint(logEntry);
    } catch (e) {
      // Fallback a debugPrint si hay error en el logging
      debugPrint('Error en logging: $e - Mensaje original: [$tag] $message');
    }
  }
  
  /// Escribe el log al archivo
  Future<void> _writeToFile(LogLevel level, String tag, String message) async {
    try {
      final timestamp = _dateFormat.format(DateTime.now());
      final levelStr = level.name.toUpperCase().padRight(7);
      final logEntry = '[$timestamp] [$levelStr] [$tag] $message\n';
      
      // Verificar si necesitamos cambiar de archivo (nuevo día)
      final today = _fileNameFormat.format(DateTime.now());
      final expectedFileName = 'app_log_$today.txt';
      
      if (!_currentLogFile.path.endsWith(expectedFileName)) {
        _currentLogFile = File('${_logDirectory.path}/$expectedFileName');
      }
      
      await _currentLogFile.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      debugPrint('Error escribiendo log a archivo: $e');
    }
  }
  
  /// Limpia logs antiguos (mantiene solo los últimos 7 días)
  Future<void> _cleanOldLogs() async {
    try {
      final files = await _logDirectory.list().toList();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      
      for (final file in files) {
        if (file is File && file.path.contains('app_log_')) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error limpiando logs antiguos: $e');
    }
  }
  
  /// Obtiene todos los archivos de log disponibles
  Future<List<File>> getLogFiles() async {
    try {
      final files = await _logDirectory.list().toList();
      final logFiles = files
          .whereType<File>()
          .where((file) => file.path.contains('app_log_'))
          .toList();
      
      // Ordenar por fecha de modificación (más reciente primero)
      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return logFiles;
    } catch (e) {
      await error('LoggerService', 'Error obteniendo archivos de log', e);
      return [];
    }
  }
  
  /// Obtiene el contenido de todos los logs
  Future<String> getAllLogsContent() async {
    try {
      final logFiles = await getLogFiles();
      final buffer = StringBuffer();
      
      for (final file in logFiles) {
        final fileName = file.path.split('/').last;
        buffer.writeln('=== $fileName ===');
        final content = await file.readAsString();
        buffer.writeln(content);
        buffer.writeln();
      }
      
      return buffer.toString();
    } catch (e) {
      await error('LoggerService', 'Error obteniendo contenido de logs', e);
      return 'Error al obtener logs: $e';
    }
  }
  
  /// Exporta los logs a un archivo específico
  Future<File?> exportLogs() async {
    try {
      final content = await getAllLogsContent();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final exportFile = File('${_logDirectory.path}/exported_logs_$timestamp.txt');
      
      await exportFile.writeAsString(content);
      await info('LoggerService', 'Logs exportados a: ${exportFile.path}');
      
      return exportFile;
    } catch (e) {
      await error('LoggerService', 'Error exportando logs', e);
      return null;
    }
  }
  
  /// Limpia todos los logs
  Future<void> clearAllLogs() async {
    try {
      final files = await _logDirectory.list().toList();
      
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
      
      // Recrear el archivo de log actual
      final today = _fileNameFormat.format(DateTime.now());
      _currentLogFile = File('${_logDirectory.path}/app_log_$today.txt');
      
      await info('LoggerService', 'Todos los logs han sido eliminados');
    } catch (e) {
      await error('LoggerService', 'Error limpiando logs', e);
    }
  }
  
  /// Obtiene estadísticas de los logs
  Future<Map<String, dynamic>> getLogStats() async {
    try {
      final logFiles = await getLogFiles();
      int totalLines = 0;
      int totalSize = 0;
      
      for (final file in logFiles) {
        final stat = await file.stat();
        totalSize += stat.size;
        
        final content = await file.readAsString();
        totalLines += content.split('\n').length;
      }
      
      return {
        'totalFiles': logFiles.length,
        'totalLines': totalLines,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      await error('LoggerService', 'Error obteniendo estadísticas de logs', e);
      return {
        'totalFiles': 0,
        'totalLines': 0,
        'totalSizeBytes': 0,
        'totalSizeMB': '0.00',
      };
    }
  }
}

/// Clase de utilidad para acceso rápido al logger
class Log {
  static Future<void> d(String tag, String message) async {
    await LoggerService.instance.debug(tag, message);
  }
  
  static Future<void> i(String tag, String message) async {
    await LoggerService.instance.info(tag, message);
  }
  
  static Future<void> w(String tag, String message) async {
    await LoggerService.instance.warning(tag, message);
  }
  
  static Future<void> e(String tag, String message, [Object? error, StackTrace? stackTrace]) async {
    await LoggerService.instance.error(tag, message, error, stackTrace);
  }
}