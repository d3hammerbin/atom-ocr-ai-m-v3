import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void onItemTapped(int index) {
    selectedIndex.value = index;
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
  
  void navigateToLocalProcess() {
    Get.toNamed('/local-process');
  }
}