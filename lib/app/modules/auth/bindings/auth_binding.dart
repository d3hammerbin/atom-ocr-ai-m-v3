import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/services/device_info_service.dart';
import '../../../data/repositories/device_repository.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar dependencias necesarias si no están ya registradas
    if (!Get.isRegistered<UserRepository>()) {
      Get.lazyPut<UserRepository>(() => UserRepository());
    }
    
    if (!Get.isRegistered<DeviceInfoService>()) {
      Get.lazyPut<DeviceInfoService>(() => DeviceInfoService());
    }
    
    if (!Get.isRegistered<DeviceRepository>()) {
      Get.lazyPut<DeviceRepository>(() => DeviceRepository());
    }
    
    // Registrar el AuthController
    Get.lazyPut<AuthController>(() => AuthController());
  }
}