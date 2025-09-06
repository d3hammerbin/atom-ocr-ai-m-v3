import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import 'logger_service.dart';

/// Servicio para manejar la sesión del usuario actual
class UserSessionService extends GetxController {
  static const String _currentUserIdKey = 'current_user_id';
  static const String _sessionActiveKey = 'session_active';
  
  final _storage = GetStorage();
  final UserRepository _userRepository = Get.find<UserRepository>();
  
  // Usuario actual observable
  final Rxn<UserModel> _currentUser = Rxn<UserModel>();
  final RxBool _isSessionActive = false.obs;
  
  // Getters
  UserModel? get currentUser => _currentUser.value;
  bool get isSessionActive => _isSessionActive.value;
  int? get currentUserId => _currentUser.value?.id;
  String? get currentUserIdentifier => _currentUser.value?.identifier;
  
  // Singleton
  static UserSessionService get to => Get.find<UserSessionService>();
  
  @override
  void onInit() {
    super.onInit();
    _loadSessionFromStorage();
  }
  
  /// Carga la sesión desde el almacenamiento local
  Future<void> _loadSessionFromStorage() async {
    try {
      final userId = _storage.read(_currentUserIdKey);
      final isActive = _storage.read(_sessionActiveKey) ?? false;
      
      if (userId != null && isActive) {
        final user = await _userRepository.getUserById(userId);
        if (user != null && user.enabled) {
          _currentUser.value = user;
          _isSessionActive.value = true;
          await Log.i('UserSessionService', 'Sesión restaurada para usuario: ${user.identifier}');
        } else {
          // Usuario no válido, limpiar sesión
          await clearSession();
        }
      }
    } catch (e) {
      await Log.e('UserSessionService', 'Error cargando sesión', e);
      await clearSession();
    }
  }
  
  /// Inicia una nueva sesión para el usuario
  Future<void> startSession(UserModel user) async {
    try {
      _currentUser.value = user;
      _isSessionActive.value = true;
      
      // Guardar en almacenamiento local
      await _storage.write(_currentUserIdKey, user.id);
      await _storage.write(_sessionActiveKey, true);
      
      // Actualizar último login
      await _userRepository.updateLastLogin(user.identifier);
      
      await Log.i('UserSessionService', 'Sesión iniciada para usuario: ${user.identifier}');
    } catch (e) {
      await Log.e('UserSessionService', 'Error loading session', e);
      rethrow;
    }
  }
  
  /// Termina la sesión actual
  Future<void> endSession() async {
    try {
      await Log.i('UserSessionService', 'Terminando sesión para usuario: ${currentUserIdentifier ?? "desconocido"}');
      
      _currentUser.value = null;
      _isSessionActive.value = false;
      
      // Limpiar almacenamiento local
      await _storage.remove(_currentUserIdKey);
      await _storage.remove(_sessionActiveKey);
      
    } catch (e) {
      await Log.e('UserSessionService', 'Error terminando sesión', e);
    }
  }
  
  /// Limpia completamente la sesión
  Future<void> clearSession() async {
    await endSession();
  }
  
  /// Verifica si hay una sesión activa válida
  Future<bool> hasValidSession() async {
    if (!_isSessionActive.value || _currentUser.value == null) {
      return false;
    }
    
    try {
      // Verificar que el usuario sigue siendo válido en la base de datos
      final user = await _userRepository.getUserById(_currentUser.value!.id!);
      if (user == null || !user.enabled) {
        await clearSession();
        return false;
      }
      
      return true;
    } catch (e) {
      await Log.e('UserSessionService', 'Error verificando sesión válida', e);
      await clearSession();
      return false;
    }
  }
  
  /// Refresca los datos del usuario actual
  Future<void> refreshCurrentUser() async {
    if (_currentUser.value?.id == null) return;
    
    try {
      final user = await _userRepository.getUserById(_currentUser.value!.id!);
      if (user != null && user.enabled) {
        _currentUser.value = user;
      } else {
        await clearSession();
      }
    } catch (e) {
      await Log.e('UserSessionService', 'Error refrescando usuario actual', e);
    }
  }
  
  /// Cambia a otro usuario (termina sesión actual e inicia nueva)
  Future<void> switchUser(UserModel newUser) async {
    await endSession();
    await startSession(newUser);
  }
  
  /// Verifica si un usuario específico tiene sesión activa
  bool isUserActive(String identifier) {
    return _isSessionActive.value && 
           _currentUser.value?.identifier == identifier;
  }
  
  /// Obtiene información de la sesión para debugging
  Map<String, dynamic> getSessionInfo() {
    return {
      'isActive': _isSessionActive.value,
      'userId': _currentUser.value?.id,
      'userIdentifier': _currentUser.value?.identifier,
      'lastLogin': _currentUser.value?.lastLoginAt?.toIso8601String(),
      'storageUserId': _storage.read(_currentUserIdKey),
      'storageSessionActive': _storage.read(_sessionActiveKey),
    };
  }
}