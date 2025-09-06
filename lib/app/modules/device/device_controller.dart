import 'package:get/get.dart';
import '../../core/services/device_info_service.dart';
import '../../data/models/device_model.dart';
import '../../data/repositories/device_repository.dart';

/// Controlador para manejar la información del dispositivo
class DeviceController extends GetxController {
  final DeviceInfoService _deviceInfoService = Get.find<DeviceInfoService>();
  final DeviceRepository _deviceRepository = Get.find<DeviceRepository>();
  
  final Rx<DeviceModel?> currentDevice = Rx<DeviceModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadDeviceInfo();
  }
  
  /// Carga la información del dispositivo actual
  Future<void> loadDeviceInfo() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Obtener información del dispositivo (necesita userId)
      // Por ahora usamos userId = 1 como ejemplo, esto debería venir del sistema de autenticación
      final deviceInfo = await _deviceInfoService.getDeviceInfo(1);
      
      // Guardar o actualizar en la base de datos
      await _deviceRepository.upsertDevice(deviceInfo);
      currentDevice.value = deviceInfo;
    } catch (e) {
      errorMessage.value = 'Error al obtener información del dispositivo: $e';
      print('Error en DeviceController.loadDeviceInfo: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Refresca la información del dispositivo
  Future<void> refreshDeviceInfo() async {
    await loadDeviceInfo();
  }
  
  /// Obtiene el historial de dispositivos para un usuario
  Future<List<DeviceModel>> getDeviceHistory(int userId) async {
    try {
      return await _deviceRepository.getDevicesByUserId(userId);
    } catch (e) {
      print('Error al obtener historial de dispositivos: $e');
      return [];
    }
  }
  
  /// Verifica si el dispositivo actual es de baja RAM
  bool get isLowRamDevice => currentDevice.value?.isLowRamDevice ?? false;
  
  /// Obtiene el identificador único del dispositivo (serial o ID)
  String? get deviceIdentifier {
    final device = currentDevice.value;
    return device?.serialNumber ?? device?.deviceId;
  }
  
  /// Obtiene información resumida del dispositivo
  Map<String, dynamic> get deviceSummary {
    final device = currentDevice.value;
    if (device == null) return {};
    
    return {
      'modelo': device.model,
      'marca': device.brand,
      'version_android': device.androidVersion,
      'api_level': device.sdkInt,
      'identificador': deviceIdentifier,
      'ram_baja': device.isLowRamDevice,
      'fecha_registro': device.createdAt?.toString(),
    };
  }
}