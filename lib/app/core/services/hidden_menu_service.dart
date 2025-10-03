import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pinput/pinput.dart';

/// Servicio para manejar el estado del menú oculto
class HiddenMenuService extends GetxService {
  static HiddenMenuService get to => Get.find<HiddenMenuService>();
  
  final GetStorage _storage = GetStorage();
  static const String _hiddenMenuKey = 'hidden_menu_enabled';
  static const String _clickCountKey = 'author_click_count';
  
  final RxBool _isHiddenMenuEnabled = false.obs;
  final RxInt _clickCount = 0.obs;
  Timer? _autoHideTimer;
  
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
    
    // Si el menú está habilitado al cargar, iniciar el temporizador
    if (_isHiddenMenuEnabled.value) {
      _startAutoHideTimer();
    }
  }
  
  /// Registra un clic en la sección del autor
  void registerClick() {
    _clickCount.value++;
    _storage.write(_clickCountKey, _clickCount.value);
    
    // Si alcanza 7 clics, verificar el estado actual del menú
    if (_clickCount.value >= 7) {
      if (_isHiddenMenuEnabled.value) {
        // Si el menú ya está activado, desactivarlo directamente sin PIN
        _toggleHiddenMenu();
        _resetClickCount();
        Get.snackbar(
          'Menú Desactivado',
          'El menú especial ha sido ocultado',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        // Si el menú está desactivado, solicitar PIN para activarlo
        _showPinDialog();
      }
    }
  }
  
  /// Muestra el diálogo para ingresar el PIN
  void _showPinDialog() {
    final TextEditingController pinController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('PIN Requerido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el PIN de 5 dígitos para acceder al menú especial:'),
            const SizedBox(height: 16),
            // Inicio del objeto Pinput para PIN del menú oculto
             Pinput(
               length: 5,
               keyboardType: TextInputType.number,
               controller: pinController,
               defaultPinTheme: PinTheme(
                 width: 48,
                 height: 56,
                 textStyle: const TextStyle(
                   fontSize: 20,
                   fontWeight: FontWeight.w600,
                 ),
                 decoration: BoxDecoration(
                   border: Border.all(color: Colors.grey.shade300),
                   borderRadius: BorderRadius.circular(12),
                 ),
               ),
               focusedPinTheme: PinTheme(
                 width: 48,
                 height: 56,
                 textStyle: const TextStyle(
                   fontSize: 20,
                   fontWeight: FontWeight.w700,
                 ),
                 decoration: BoxDecoration(
                   border: Border.all(color: Get.theme.primaryColor),
                   borderRadius: BorderRadius.circular(12),
                 ),
               ),
               onCompleted: (value) => pinController.text = value,
             ),
             // Fin del objeto Pinput para PIN del menú oculto
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _resetClickCount();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _validatePin(pinController.text);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
  
  /// Valida el PIN ingresado
  void _validatePin(String pin) {
    const String correctPin = '73195';
    
    if (pin == correctPin) {
      // PIN correcto, activar menú oculto
      Get.back();
      _toggleHiddenMenu();
      _resetClickCount();
      Get.snackbar(
        'Acceso Concedido',
        'Menú especial activado',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      // PIN incorrecto, cancelar acción
      Get.back();
      _resetClickCount();
      Get.snackbar(
        'PIN Incorrecto',
        'Acceso denegado. La acción ha sido cancelada.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
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
    
    if (_isHiddenMenuEnabled.value) {
      // Iniciar temporizador de 3 minutos para ocultar automáticamente
      _startAutoHideTimer();
    } else {
      // Cancelar temporizador si el menú se oculta manualmente
      _cancelAutoHideTimer();
    }
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
    
    if (enabled) {
      _startAutoHideTimer();
    } else {
      _cancelAutoHideTimer();
    }
  }
  
  /// Obtiene el progreso actual hacia activar/desactivar el menú (0-7)
  int getClickProgress() {
    return _clickCount.value;
  }
  
  /// Inicia el temporizador para ocultar automáticamente el menú después de 3 minutos
  void _startAutoHideTimer() {
    _cancelAutoHideTimer(); // Cancelar cualquier temporizador existente
    _autoHideTimer = Timer(const Duration(minutes: 3), () {
      if (_isHiddenMenuEnabled.value) {
        _isHiddenMenuEnabled.value = false;
        _storage.write(_hiddenMenuKey, false);
      }
    });
  }
  
  /// Cancela el temporizador de ocultación automática
  void _cancelAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }
  
  @override
  void onClose() {
    _cancelAutoHideTimer();
    super.onClose();
  }

  /// Limpia todos los datos del servicio
  void clearData() {
    _cancelAutoHideTimer();
    _storage.remove(_hiddenMenuKey);
    _storage.remove(_clickCountKey);
    _isHiddenMenuEnabled.value = false;
    _clickCount.value = 0;
  }
}