import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

enum AppThemeMode { light, dark, system }
enum AppLanguage { spanish, english }

class UserPreferencesController extends GetxController {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'app_language';
  static const String _firstLaunchKey = 'first_launch';
  static const String _autoSaveKey = 'auto_save_results';
  static const String _notificationsKey = 'notifications_enabled';
  
  final _storage = GetStorage();
  
  // Observables para las preferencias
  final _themeMode = AppThemeMode.system.obs;
  final _language = AppLanguage.spanish.obs;
  final _isFirstLaunch = true.obs;
  final _autoSaveResults = true.obs;
  final _notificationsEnabled = true.obs;
  
  // Getters
  AppThemeMode get themeMode => _themeMode.value;
  AppLanguage get language => _language.value;
  bool get isFirstLaunch => _isFirstLaunch.value;
  bool get autoSaveResults => _autoSaveResults.value;
  bool get notificationsEnabled => _notificationsEnabled.value;
  
  @override
  void onInit() {
    super.onInit();
    _loadPreferencesFromStorage();
  }
  
  void _loadPreferencesFromStorage() {
    // Cargar tema
    final savedTheme = _storage.read(_themeKey);
    if (savedTheme != null) {
      _themeMode.value = AppThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => AppThemeMode.system,
      );
    }
    
    // Cargar idioma
    final savedLanguage = _storage.read(_languageKey);
    if (savedLanguage != null) {
      _language.value = AppLanguage.values.firstWhere(
        (lang) => lang.toString() == savedLanguage,
        orElse: () => AppLanguage.spanish,
      );
    }
    
    // Cargar otras preferencias
    _isFirstLaunch.value = _storage.read(_firstLaunchKey) ?? true;
    _autoSaveResults.value = _storage.read(_autoSaveKey) ?? true;
    _notificationsEnabled.value = _storage.read(_notificationsKey) ?? true;
    
    _updateAppTheme();
  }
  
  // Métodos para cambiar preferencias
  void changeTheme(AppThemeMode mode) {
    _themeMode.value = mode;
    _storage.write(_themeKey, mode.toString());
    _updateAppTheme();
  }
  
  void changeLanguage(AppLanguage language) {
    _language.value = language;
    _storage.write(_languageKey, language.toString());
    // Aquí se podría implementar el cambio de idioma de la app
  }
  
  void setFirstLaunchCompleted() {
    _isFirstLaunch.value = false;
    _storage.write(_firstLaunchKey, false);
  }
  
  void toggleAutoSaveResults() {
    _autoSaveResults.value = !_autoSaveResults.value;
    _storage.write(_autoSaveKey, _autoSaveResults.value);
  }
  
  void toggleNotifications() {
    _notificationsEnabled.value = !_notificationsEnabled.value;
    _storage.write(_notificationsKey, _notificationsEnabled.value);
  }
  
  void _updateAppTheme() {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        Get.changeThemeMode(ThemeMode.light);
        break;
      case AppThemeMode.dark:
        Get.changeThemeMode(ThemeMode.dark);
        break;
      case AppThemeMode.system:
        Get.changeThemeMode(ThemeMode.system);
        break;
    }
  }
  
  // Métodos de utilidad para UI
  String get themeModeText {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return 'Claro';
      case AppThemeMode.dark:
        return 'Oscuro';
      case AppThemeMode.system:
        return 'Sistema';
    }
  }
  
  IconData get themeModeIcon {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }
  
  String get languageText {
    switch (_language.value) {
      case AppLanguage.spanish:
        return 'Español';
      case AppLanguage.english:
        return 'English';
    }
  }
  
  // Método para resetear todas las preferencias
  void resetAllPreferences() {
    _storage.erase();
    _themeMode.value = AppThemeMode.system;
    _language.value = AppLanguage.spanish;
    _isFirstLaunch.value = true;
    _autoSaveResults.value = true;
    _notificationsEnabled.value = true;
    _updateAppTheme();
  }
  
  // Método para exportar preferencias (útil para backup)
  Map<String, dynamic> exportPreferences() {
    return {
      _themeKey: _themeMode.value.toString(),
      _languageKey: _language.value.toString(),
      _firstLaunchKey: _isFirstLaunch.value,
      _autoSaveKey: _autoSaveResults.value,
      _notificationsKey: _notificationsEnabled.value,
    };
  }
  
  // Método para importar preferencias (útil para restore)
  void importPreferences(Map<String, dynamic> preferences) {
    preferences.forEach((key, value) {
      _storage.write(key, value);
    });
    _loadPreferencesFromStorage();
  }
}