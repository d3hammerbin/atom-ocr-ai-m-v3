import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Servicio para manejar configuraciones especiales de la aplicación
class SpecialSettingsService extends GetxController {
  static SpecialSettingsService get instance => Get.find<SpecialSettingsService>();
  
  final GetStorage _storage = GetStorage();
  
  // Keys para el almacenamiento
  static const String _showLocalProcessKey = 'show_local_process';
  static const String _enableImageQualityAnalysisKey = 'enable_image_quality_analysis';
  
  // Observable para mostrar/ocultar la opción "Procesar Local"
  final RxBool _showLocalProcess = false.obs;
  
  // Observable para habilitar/deshabilitar el análisis de calidad de imagen
  final RxBool _enableImageQualityAnalysis = true.obs;
  
  // Getters
  bool get showLocalProcess => _showLocalProcess.value;
  RxBool get showLocalProcessRx => _showLocalProcess;
  
  bool get enableImageQualityAnalysis => _enableImageQualityAnalysis.value;
  RxBool get enableImageQualityAnalysisRx => _enableImageQualityAnalysis;
  
  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }
  
  /// Carga las configuraciones desde el almacenamiento local
  void _loadSettings() {
    _showLocalProcess.value = _storage.read(_showLocalProcessKey) ?? false;
    _enableImageQualityAnalysis.value = _storage.read(_enableImageQualityAnalysisKey) ?? true;
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
  
  /// Reinicia todas las configuraciones especiales
  void resetSettings() {
    _showLocalProcess.value = false;
    _enableImageQualityAnalysis.value = true;
    _storage.remove(_showLocalProcessKey);
    _storage.remove(_enableImageQualityAnalysisKey);
  }
}