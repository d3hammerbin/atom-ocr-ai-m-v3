import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Servicio para manejar el estado del menú oculto
class HiddenMenuService extends GetxService {
  static HiddenMenuService get to => Get.find<HiddenMenuService>();
  
  final GetStorage _storage = GetStorage();
  static const String _hiddenMenuKey = 'hidden_menu_enabled';
  static const String _clickCountKey = 'author_click_count';
  
  final RxBool _isHiddenMenuEnabled = false.obs;
  final RxInt _clickCount = 0.obs;
  
  /// Estado actual del menú oculto
  bool get isHiddenMenuEnabled => _isHiddenMenuEnabled.value;
  
  /// Contador actual de clics
  int get clickCount => _clickCount.value;
  
  /// Observable del estado del menú oculto
  RxBool get isHiddenMenuEnabledObs => _isHiddenMenuEnabled;
  
  /// Observable para mostrar el indicador del corazón
  RxBool get showHeartIndicator => _isHiddenMenuEnabled;
  
  @override
  void onInit() {
    super.onInit();
    _loadState();
  }
  
  /// Carga el estado desde el almacenamiento local
  void _loadState() {
    _isHiddenMenuEnabled.value = _storage.read(_hiddenMenuKey) ?? false;
    _clickCount.value = _storage.read(_clickCountKey) ?? 0;
  }
  
  /// Registra un clic en la sección del autor
  void registerClick() {
    _clickCount.value++;
    _storage.write(_clickCountKey, _clickCount.value);
    
    // Si alcanza 7 clics, alterna el estado del menú oculto
    if (_clickCount.value >= 7) {
      _toggleHiddenMenu();
      _resetClickCount();
    }
  }
  
  /// Verifica si se debe mostrar el menú oculto
  bool shouldShowMenu() {
    return _isHiddenMenuEnabled.value;
  }
  
  /// Alterna el estado del menú oculto
  void _toggleHiddenMenu() {
    _isHiddenMenuEnabled.value = !_isHiddenMenuEnabled.value;
    _storage.write(_hiddenMenuKey, _isHiddenMenuEnabled.value);
  }
  
  /// Reinicia el contador de clics
  void _resetClickCount() {
    _clickCount.value = 0;
    _storage.write(_clickCountKey, 0);
  }
  
  /// Fuerza el estado del menú oculto (para testing)
  void setHiddenMenuState(bool enabled) {
    _isHiddenMenuEnabled.value = enabled;
    _storage.write(_hiddenMenuKey, enabled);
    _resetClickCount();
  }
  
  /// Obtiene el progreso actual hacia activar/desactivar el menú (0-7)
  int getClickProgress() {
    return _clickCount.value;
  }
  
  /// Limpia todos los datos del servicio
  void clearData() {
    _storage.remove(_hiddenMenuKey);
    _storage.remove(_clickCountKey);
    _isHiddenMenuEnabled.value = false;
    _clickCount.value = 0;
  }
}