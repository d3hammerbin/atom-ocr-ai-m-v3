import 'package:get/get.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/services/logger_service.dart';
import '../../data/models/credential_model.dart';
import '../../data/repositories/credential_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../routes/app_pages.dart';

class CredentialsListController extends GetxController {
  // Lista observable de credenciales procesadas
  final RxList<CredentialModel> credentialsList = <CredentialModel>[].obs;
  
  // Lista filtrada para búsqueda
  final RxList<CredentialModel> filteredCredentialsList = <CredentialModel>[].obs;
  
  // Query de búsqueda
  final RxString searchQuery = ''.obs;
  
  // Estado de carga
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreData = true.obs;
  
  // Paginación
  static const int _pageSize = 4;
  int _currentOffset = 0;
  int? _currentUserId;
  int _totalCount = 0;
  
  // Repositorios
  final CredentialRepository _credentialRepository = CredentialRepository();
  final UserRepository _userRepository = UserRepository();
  
  @override
  void onInit() {
    super.onInit();
    loadCredentials();
  }


  
  /// Cargar credenciales desde la base de datos (primera página)
  Future<void> loadCredentials() async {
    try {
      isLoading.value = true;
      _currentOffset = 0;
      hasMoreData.value = true;
      
      Log.i('CredentialsListController', 'Cargando credenciales desde base de datos');
      
      // Obtener el usuario actual
      final users = await _userRepository.getAllUsers();
      if (users.isEmpty) {
        Log.w('CredentialsListController', 'No se encontró usuario activo');
        credentialsList.clear();
        filteredCredentialsList.clear();
        return;
      }
      
      final currentUser = users.first;
      _currentUserId = currentUser.id!;
      
      // Obtener el conteo total
      if (searchQuery.value.isEmpty) {
        _totalCount = await _credentialRepository.getCredentialsCount(_currentUserId!);
      } else {
        _totalCount = await _credentialRepository.getSearchCredentialsCount(_currentUserId!, searchQuery.value.trim());
      }
      
      // Cargar primera página
      await _loadPage(reset: true);
      
      Log.i('CredentialsListController', 'Total de credenciales: $_totalCount');
      Log.i('CredentialsListController', 'Credenciales cargadas: ${credentialsList.length}');
      
    } catch (e) {
      Log.e('CredentialsListController', 'Error cargando credenciales', e);
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudieron cargar las credenciales: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Cargar una página de credenciales
  Future<void> _loadPage({bool reset = false}) async {
    if (_currentUserId == null) return;
    
    try {
      List<CredentialModel> newCredentials;
      
      if (searchQuery.value.isEmpty) {
        // Cargar credenciales sin filtro
        newCredentials = await _credentialRepository.getCredentialsByUserIdPaginated(
          _currentUserId!,
          offset: _currentOffset,
          limit: _pageSize,
        );
      } else {
        // Cargar credenciales con búsqueda
        newCredentials = await _credentialRepository.searchCredentialsPaginated(
          _currentUserId!,
          searchQuery.value.trim(),
          offset: _currentOffset,
          limit: _pageSize,
        );
      }
      
      if (reset) {
        credentialsList.value = newCredentials;
        filteredCredentialsList.assignAll(credentialsList);
      } else {
        credentialsList.addAll(newCredentials);
        filteredCredentialsList.assignAll(credentialsList);
      }
      
      // Actualizar estado de paginación
      _currentOffset += _pageSize;
      hasMoreData.value = newCredentials.length == _pageSize && credentialsList.length < _totalCount;
      
      Log.i('CredentialsListController', 'Página cargada: ${newCredentials.length} elementos');
      Log.i('CredentialsListController', 'Total cargado: ${credentialsList.length}/$_totalCount');
      
    } catch (e) {
      Log.e('CredentialsListController', 'Error al cargar página: $e');
    }
  }
  
  /// Cargar más credenciales (lazy loading)
  Future<void> loadMoreCredentials() async {
    if (isLoadingMore.value || !hasMoreData.value || isLoading.value) {
      return;
    }
    
    try {
      isLoadingMore.value = true;
      Log.i('CredentialsListController', 'Cargando más credenciales...');
      
      await _loadPage();
      
    } catch (e) {
      Log.e('CredentialsListController', 'Error al cargar más credenciales: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }
  
  /// Eliminar una credencial de la lista
  Future<void> deleteCredential(int id) async {
    try {
      Log.i('CredentialsListController', 'Eliminando credencial con ID: $id');
      
      // Eliminar de la base de datos
      await _credentialRepository.deleteCredential(id);
      
      // Eliminar de la lista local
      credentialsList.removeWhere((credential) => credential.id == id);
      filteredCredentialsList.removeWhere((credential) => credential.id == id);
      
      SnackbarUtils.showSuccess(
        title: 'Eliminado',
        message: 'Credencial eliminada exitosamente',
      );
      
      Log.i('CredentialsListController', 'Credencial eliminada correctamente');
      
    } catch (e) {
      Log.e('CredentialsListController', 'Error eliminando credencial', e);
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudo eliminar la credencial: $e',
      );
    }
  }
  
  /// Refrescar la lista de credenciales
  void refreshCredentials() async {
    await loadCredentials();
  }
  
  /// Filtrar credenciales por nombre y CURP
  void filterCredentials(String query) {
    final trimmedQuery = query.trim();
    final previousQuery = searchQuery.value;
    searchQuery.value = trimmedQuery;
    
    Log.i('CredentialsListController', 'Filtrando con query: "$trimmedQuery"');
    
    // Si la query cambió, recargar desde el inicio
    if (previousQuery != trimmedQuery) {
      loadCredentials();
    }
  }
  
  /// Limpiar búsqueda
  void clearSearch() {
    searchQuery.value = '';
    Log.i('CredentialsListController', 'Búsqueda limpiada');
    
    // Recargar credenciales sin filtro
    loadCredentials();
  }
  
  /// Navega a los detalles de una credencial
  void viewCredentialDetails(CredentialModel credential) {
    Get.toNamed('/credential-details', arguments: credential.id);
  }
  
  /// Navegar a la pantalla de edición de credencial
  void editCredential(CredentialModel credential) {
    Get.toNamed(Routes.CREDENTIAL_EDIT, arguments: {
      'credentialId': credential.id,
    });
  }
}