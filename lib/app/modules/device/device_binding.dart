import 'package:get/get.dart';
import '../../core/services/device_info_service.dart';
import '../../data/repositories/device_repository.dart';
import 'device_controller.dart';

/// Binding para el módulo de información del dispositivo
class DeviceBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar el repositorio de dispositivos
    Get.lazyPut<DeviceRepository>(
      () => DeviceRepository(),
    );
    
    // Registrar el servicio de información del dispositivo
    Get.lazyPut<DeviceInfoService>(
      () => DeviceInfoService(),
    );
    
    // Registrar el controlador del dispositivo
    Get.lazyPut<DeviceController>(
      () => DeviceController(),
    );
  }
}