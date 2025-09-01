import 'package:get/get.dart';

class HomeController extends GetxController {
  



  
  void navigateToOcr() {
    Get.toNamed('/ocr');
  }
  
  void navigateToCamera() {
    Get.toNamed('/camera');
  }
  
  void navigateToCredentialsList() {
    Get.toNamed('/credentials-list');
  }
  
  void navigateToLocalProcess() {
    Get.toNamed('/local-process');
  }
}