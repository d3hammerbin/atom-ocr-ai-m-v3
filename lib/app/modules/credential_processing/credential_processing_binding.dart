import 'package:get/get.dart';
import 'credential_processing_controller.dart';

class CredentialProcessingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CredentialProcessingController>(
      () => CredentialProcessingController(),
    );
  }
}