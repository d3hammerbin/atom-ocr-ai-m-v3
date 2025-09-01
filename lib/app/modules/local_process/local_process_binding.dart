import 'package:get/get.dart';
import 'local_process_controller.dart';

class LocalProcessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocalProcessController>(
      () => LocalProcessController(),
    );
  }
}