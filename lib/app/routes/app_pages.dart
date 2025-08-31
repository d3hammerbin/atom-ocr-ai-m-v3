import 'package:get/get.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/ocr/ocr_binding.dart';
import '../modules/ocr/ocr_view.dart';
import '../modules/camera/camera_binding.dart';
import '../modules/camera/camera_view.dart';
import '../modules/credentials_list/credentials_list_binding.dart';
import '../modules/credentials_list/credentials_list_view.dart';
import '../modules/processing/processing_binding.dart';
import '../modules/processing/processing_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.OCR,
      page: () => const OcrView(),
      binding: OcrBinding(),
    ),
    GetPage(
      name: _Paths.CAMERA,
      page: () => const CameraView(),
      binding: CameraBinding(),
    ),
    GetPage(
      name: _Paths.CREDENTIALS_LIST,
      page: () => const CredentialsListView(),
      binding: CredentialsListBinding(),
    ),
    GetPage(
      name: _Paths.PROCESSING,
      page: () => const ProcessingView(),
      binding: ProcessingBinding(),
    ),
  ];
}