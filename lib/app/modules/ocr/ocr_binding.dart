import 'package:get/get.dart';
import 'ocr_controller.dart';

class OcrBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OcrController>(
      () => OcrController(),
    );
  }
}