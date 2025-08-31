import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/routes/app_pages.dart';
import 'app/core/user_preferences_controller.dart';
import 'app/core/app_version_service.dart';
import 'app/core/services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  
  // Inicializar servicios
  Get.put(UserPreferencesController());
  await Get.putAsync(() => AppVersionService().onInit().then((_) => AppVersionService()));
  
  runApp(const MyApp());
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
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF424242),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9E9E9E),
            brightness: Brightness.dark,
          ).copyWith(
            primary: const Color(0xFF9E9E9E),
            secondary: const Color(0xFF757575),
            surface: const Color(0xFF121212),
            background: const Color(0xFF121212),
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onBackground: Colors.white,
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
