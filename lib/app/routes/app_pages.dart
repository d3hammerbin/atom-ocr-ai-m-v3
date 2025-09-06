import 'package:get/get.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/ocr/ocr_binding.dart';
import '../modules/ocr/ocr_view.dart';
import '../modules/camera/camera_binding.dart';
import '../modules/camera/camera_view.dart';
import '../modules/credentials_list/credentials_list_view.dart';
import '../modules/credentials_list/credentials_list_binding.dart';
import '../presentation/views/credential_details_view.dart';
import '../modules/processing/processing_binding.dart';
import '../modules/processing/processing_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../modules/local_process/local_process_binding.dart';
import '../modules/local_process/local_process_view.dart';
import '../modules/credential_processing/credential_processing_binding.dart';
import '../modules/credential_processing/credential_processing_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/initial_screen.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.INITIAL;

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
      name: _Paths.CREDENTIAL_DETAILS,
      page: () => const CredentialDetailsView(),
    ),
    GetPage(
      name: _Paths.PROCESSING,
      page: () => const ProcessingView(),
      binding: ProcessingBinding(),
    ),
    GetPage(
      name: _Paths.LOCAL_PROCESS,
      page: () => const LocalProcessView(),
      binding: LocalProcessBinding(),
    ),
    GetPage(
      name: _Paths.INITIAL,
      page: () => const InitialScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.CAPTURE_SELECTION,
      page: () => const HomeView(), // Temporal: usar HomeView como selección de captura
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.CREDENTIAL_PROCESSING,
      page: () => const CredentialProcessingView(),
      binding: CredentialProcessingBinding(),
    ),
  ];
}