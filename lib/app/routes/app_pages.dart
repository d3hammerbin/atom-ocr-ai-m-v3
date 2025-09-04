import 'package:get/get.dart';
import '../modules/local_process/local_process_binding.dart';
import '../modules/local_process/local_process_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOCAL_PROCESS;

  static final routes = [
    GetPage(
      name: _Paths.LOCAL_PROCESS,
      page: () => const LocalProcessView(),
      binding: LocalProcessBinding(),
    ),
  ];
}