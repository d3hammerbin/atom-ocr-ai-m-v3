import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Servicio para manejar configuraciones especiales de la aplicación
class SpecialSettingsService extends GetxController {
  static SpecialSettingsService get instance => Get.find<SpecialSettingsService>();
  
  final GetStorage _storage = GetStorage();
  
  // Keys para el almacenamiento
  static const String _showLocalProcessKey = 'show_local_process';
  static const String _enableImageQualityAnalysisKey = 'enable_image_quality_analysis';
  static const String _enableFlashKey = 'enable_flash';
  
  // Observable para mostrar/ocultar la opción "Procesar Local"
  final RxBool _showLocalProcess = false.obs;
  
  // Observable para habilitar/deshabilitar el análisis de calidad de imagen
  final RxBool _enableImageQualityAnalysis = true.obs;
  
  // Observable para habilitar/deshabilitar el flash
  final RxBool _enableFlash = false.obs;
  
  // Getters
  bool get showLocalProcess => _showLocalProcess.value;
  RxBool get showLocalProcessRx => _showLocalProcess;
  
  bool get enableImageQualityAnalysis => _enableImageQualityAnalysis.value;
  RxBool get enableImageQualityAnalysisRx => _enableImageQualityAnalysis;
  
  bool get enableFlash => _enableFlash.value;
  RxBool get enableFlashRx => _enableFlash;
  
  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }
  
  /// Carga las configuraciones desde el almacenamiento local
  void _loadSettings() {
    _showLocalProcess.value = _storage.read(_showLocalProcessKey) ?? false;
    _enableImageQualityAnalysis.value = _storage.read(_enableImageQualityAnalysisKey) ?? true;
    _enableFlash.value = _storage.read(_enableFlashKey) ?? false;
  }
  
  /// Alterna la visibilidad de la opción "Procesar Local"
  void toggleShowLocalProcess() {
    _showLocalProcess.value = !_showLocalProcess.value;
    _storage.write(_showLocalProcessKey, _showLocalProcess.value);
  }
  
  /// Establece el estado de la opción "Procesar Local"
  void setShowLocalProcess(bool value) {
    _showLocalProcess.value = value;
    _storage.write(_showLocalProcessKey, value);
  }
  
  /// Alterna el análisis de calidad de imagen
  void toggleImageQualityAnalysis() {
    _enableImageQualityAnalysis.value = !_enableImageQualityAnalysis.value;
    _storage.write(_enableImageQualityAnalysisKey, _enableImageQualityAnalysis.value);
  }
  
  /// Establece el estado del análisis de calidad de imagen
  void setImageQualityAnalysis(bool value) {
    _enableImageQualityAnalysis.value = value;
    _storage.write(_enableImageQualityAnalysisKey, value);
  }
  
  /// Alterna el uso del flash
  void toggleFlash() {
    _enableFlash.value = !_enableFlash.value;
    _storage.write(_enableFlashKey, _enableFlash.value);
  }
  
  /// Establece el estado del flash
  void setFlash(bool value) {
    _enableFlash.value = value;
    _storage.write(_enableFlashKey, value);
  }
  
  /// Reinicia todas las configuraciones especiales
  void resetSettings() {
    _showLocalProcess.value = false;
    _enableImageQualityAnalysis.value = true;
    _enableFlash.value = false;
    _storage.remove(_showLocalProcessKey);
    _storage.remove(_enableImageQualityAnalysisKey);
    _storage.remove(_enableFlashKey);
  }
}