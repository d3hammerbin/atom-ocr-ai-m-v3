import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/routes/app_pages.dart';
import 'app/core/user_preferences_controller.dart';
import 'app/core/app_version_service.dart';
import 'app/core/services/logger_service.dart';
import 'app/core/services/hidden_menu_service.dart';
import 'app/core/services/special_settings_service.dart';
import 'app/core/services/user_session_service.dart';
import 'app/core/services/location_fallback_service.dart';
import 'app/core/services/app_config_service.dart';
import 'app/data/repositories/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  
  // Inicializar servicios
  await LoggerService.instance.initialize();
  await AppConfigService.initialize();
  
  // Solicitar permisos de ubicación al inicio de la aplicación
  await _requestLocationPermissions();
  
  Get.put(UserPreferencesController());
  Get.put(UserRepository());
  Get.put(HiddenMenuService());
  Get.put(SpecialSettingsService());
  Get.put(UserSessionService());
  await Get.putAsync(() => AppVersionService().onInit().then((_) => AppVersionService()));
  
  runApp(const MyApp());
}

/// Solicita permisos de ubicación al inicio de la aplicación
Future<void> _requestLocationPermissions() async {
  try {
    final locationService = LocationFallbackService.instance;
    await LoggerService.instance.info('Main', 'Solicitando permisos de ubicación al inicio de la aplicación');
    
    // Verificar capacidades de ubicación
    final capabilities = await locationService.getLocationCapabilities();
    if (!capabilities['serviceEnabled']) {
      await LoggerService.instance.warning('Main', 'Servicios de ubicación deshabilitados');
      return;
    }
    
    // Solicitar permisos de ubicación
    await locationService.requestLocationPermission();
    await LoggerService.instance.info('Main', 'Permisos de ubicación procesados correctamente');
  } catch (e) {
    await LoggerService.instance.error('Main', 'Error al solicitar permisos de ubicación al inicio', e);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final versionService = AppVersionService.to;
      return GetMaterialApp(
        title: versionService.isLoading ? 'Atom OCR AI' : versionService.appTitle,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF616161),
            brightness: Brightness.light,
          ).copyWith(
            // Inicio de ajuste de esquema de color para botones light
            primary: const Color(0xFF18DAA3),
            onPrimary: const Color(0xFF191E33),
            // Fin de ajuste de esquema de color para botones light
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF424242),
            // Inicio ajuste color de texto del AppBar (light)
            foregroundColor: Color(0xFF191E33),
            // Fin ajuste color de texto del AppBar (light)
            elevation: 2,
          ),
          // Inicio de configuración de temas de botones (light)
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18DAA3),
              // Inicio ajuste color de texto del botón (light)
              foregroundColor: const Color(0xFF191E33),
              // Fin ajuste color de texto del botón (light)
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF18DAA3),
              foregroundColor: const Color(0xFF191E33),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF191E33),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF18DAA3),
              foregroundColor: const Color(0xFF191E33),
              side: const BorderSide(
                color: Color(0xFF18DAA3),
                width: 1.5,
              ),
            ),
          ),
          // Fin de configuración de temas de botones (light)
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9E9E9E),
            brightness: Brightness.dark,
          ).copyWith(
            primary: const Color(0xFF9E9E9E),
            secondary: const Color(0xFF757575),
            surface: const Color(0xFF121212),
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            onSurface: Colors.white,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        themeMode: ThemeMode.system,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        debugShowCheckedModeBanner: false,
      );
    });
  }
}
