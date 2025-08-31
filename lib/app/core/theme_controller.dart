import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart' as flutter;

enum AppThemeMode { light, dark, system }

class ThemeController extends GetxController {
  static const String _themeKey = 'theme_mode';
  final _storage = GetStorage();
  
  final _themeMode = AppThemeMode.system.obs;
  AppThemeMode get themeMode => _themeMode.value;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
  }
  
  void _loadThemeFromStorage() {
    final savedTheme = _storage.read(_themeKey);
    if (savedTheme != null) {
      _themeMode.value = AppThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => AppThemeMode.system,
      );
    }
    _updateAppTheme();
  }
  
  void changeTheme(AppThemeMode mode) {
    _themeMode.value = mode;
    _storage.write(_themeKey, mode.toString());
    _updateAppTheme();
  }
  
  void _updateAppTheme() {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        Get.changeThemeMode(flutter.ThemeMode.light);
        break;
      case AppThemeMode.dark:
        Get.changeThemeMode(flutter.ThemeMode.dark);
        break;
      case AppThemeMode.system:
        Get.changeThemeMode(flutter.ThemeMode.system);
        break;
    }
  }
  
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
}