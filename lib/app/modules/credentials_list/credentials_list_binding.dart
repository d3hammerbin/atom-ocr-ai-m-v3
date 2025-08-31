import 'package:get/get.dart';
import 'credentials_list_controller.dart';

class CredentialsListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CredentialsListController>(
      () => CredentialsListController(),
    );
  }
}