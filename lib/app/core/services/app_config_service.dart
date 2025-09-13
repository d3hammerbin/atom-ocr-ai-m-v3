import 'dart:io';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'logger_service.dart';

/// Servicio para leer configuraciones personalizadas del pubspec.yaml
class AppConfigService {
  static Map<String, dynamic>? _config;
  static bool _initialized = false;

  /// Inicializa el servicio de configuración leyendo el pubspec.yaml
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Intentar leer desde assets primero
      String content;
      try {
        content = await rootBundle.loadString('pubspec.yaml');
        Log.d('AppConfigService', 'Pubspec.yaml cargado desde assets');
      } catch (e) {
        // Fallback: intentar leer desde el sistema de archivos
        Log.d(
          'AppConfigService',
          'No se pudo cargar desde assets, intentando desde filesystem',
        );
        final pubspecFile = File('pubspec.yaml');
        if (await pubspecFile.exists()) {
          content = await pubspecFile.readAsString();
          Log.d('AppConfigService', 'Pubspec.yaml cargado desde filesystem');
        } else {
          throw Exception('Archivo pubspec.yaml no encontrado');
        }
      }

      final yamlDoc = loadYaml(content);

      if (yamlDoc is Map && yamlDoc.containsKey('app_config')) {
        _config = Map<String, dynamic>.from(yamlDoc['app_config']);
        Log.i(
          'AppConfigService',
          'Configuración cargada exitosamente: $_config',
        );
      } else {
        _config = {};
        Log.w(
          'AppConfigService',
          'No se encontró sección app_config en pubspec.yaml',
        );
      }
    } catch (e) {
      _config = {};
      Log.e('AppConfigService', 'Error al cargar configuración: $e');
    }

    _initialized = true;
  }

  /// Obtiene un valor de configuración por clave
  static T? getValue<T>(String key, [T? defaultValue]) {
    if (!_initialized) {
      Log.w(
        'AppConfigService',
        'Servicio no inicializado. Llamar initialize() primero.',
      );
      return defaultValue;
    }

    if (_config == null) return defaultValue;

    final keys = key.split('.');
    dynamic current = _config;

    for (final k in keys) {
      if (current is Map && current.containsKey(k)) {
        current = current[k];
      } else {
        return defaultValue;
      }
    }

    return current is T ? current : defaultValue;
  }

  /// Verifica si el modo demo está habilitado
  static bool? get isDemoEnabled {
    final value = getValue<bool>(
      'demo',
      true,
    ); // Default: true
    Log.d(
      'AppConfigService',
      'isDemoEnabled: $value, initialized: $_initialized, config: $_config',
    );
    return value;
  }

  /// Obtiene el texto de la marca de agua
  static String? get watermarkText {
    return getValue<String>('watermark.text', 'DEMO D'); // Default: 'DEMO'
  }

  /// Obtiene la opacidad de la marca de agua
  static double? get watermarkOpacity {
    final opacity = getValue<dynamic>('watermark.opacity', 0.6); // Default: 0.6
    if (opacity is num) {
      return opacity.toDouble().clamp(0.0, 1.0);
    }
    return 0.6;
  }

  /// Obtiene el color de la marca de agua
  static String? get watermarkColor {
    return getValue<String>('watermark.color', 'white'); // Default: 'white'
  }

  /// Verifica si el procesamiento de EXIF está habilitado
  static bool? get isExifProcessingEnabled {
    return getValue<bool>('enable_exif_processing');
  }

  /// Obtiene toda la configuración como mapa
  static Map<String, dynamic> get allConfig {
    return Map<String, dynamic>.from(_config ?? {});
  }

  /// Reinicia el servicio (útil para testing)
  static void reset() {
    _config = null;
    _initialized = false;
  }

  /// Verifica si el servicio está inicializado
  static bool get isInitialized => _initialized;
}
