import 'package:get/get.dart';
import 'splash_controller.dart';
import '../../data/repositories/user_repository.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar UserRepository si no está ya registrado
    if (!Get.isRegistered<UserRepository>()) {
      Get.lazyPut<UserRepository>(() => UserRepository());
    }
    
    Get.lazyPut<SplashController>(
      () => SplashController(),
    );
  }
}