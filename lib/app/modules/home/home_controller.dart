import 'package:get/get.dart';

class HomeController extends GetxController {
  
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }


  
  void navigateToOcr() {
    Get.toNamed('/ocr');
  }
  
  void navigateToCamera() {
    Get.toNamed('/camera');
  }
  
  void navigateToCredentialsList() {
    Get.toNamed('/credentials-list');
  }
}