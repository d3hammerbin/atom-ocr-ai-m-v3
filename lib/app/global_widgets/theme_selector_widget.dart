import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/user_preferences_controller.dart';

class ThemeSelectorWidget extends StatelessWidget {
  const ThemeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final UserPreferencesController preferencesController = Get.find<UserPreferencesController>();
    
    return PopupMenuButton<AppThemeMode>(
      icon: Obx(() => Icon(preferencesController.themeModeIcon)),
      tooltip: 'Seleccionar tema',
      onSelected: (AppThemeMode mode) {
        preferencesController.changeTheme(mode);
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<AppThemeMode>(
          value: AppThemeMode.light,
          child: Row(
            children: [
              const Icon(Icons.light_mode),
              const SizedBox(width: 12),
              const Text('Claro'),
              const Spacer(),
              Obx(() => preferencesController.themeMode == AppThemeMode.light
                  ? const Icon(Icons.check, color: Colors.blue)
                  : const SizedBox.shrink()),
            ],
          ),
        ),
        PopupMenuItem<AppThemeMode>(
          value: AppThemeMode.dark,
          child: Row(
            children: [
              const Icon(Icons.dark_mode),
              const SizedBox(width: 12),
              const Text('Oscuro'),
              const Spacer(),
              Obx(() => preferencesController.themeMode == AppThemeMode.dark
                  ? const Icon(Icons.check, color: Colors.blue)
                  : const SizedBox.shrink()),
            ],
          ),
        ),
        PopupMenuItem<AppThemeMode>(
          value: AppThemeMode.system,
          child: Row(
            children: [
              const Icon(Icons.brightness_auto),
              const SizedBox(width: 12),
              const Text('Sistema'),
              const Spacer(),
              Obx(() => preferencesController.themeMode == AppThemeMode.system
                  ? const Icon(Icons.check, color: Colors.blue)
                  : const SizedBox.shrink()),
            ],
          ),
        ),
      ],
    );
  }
}