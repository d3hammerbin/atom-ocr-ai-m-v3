import 'package:get/get.dart';
import 'processing_controller.dart';

class ProcessingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProcessingController>(
      () => ProcessingController(),
    );
  }
}