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
  
  // Repositorios
  final CredentialRepository _credentialRepository = CredentialRepository();
  final UserRepository _userRepository = UserRepository();
  
  @override
  void onInit() {
    super.onInit();
    loadCredentials();
  }


  
  /// Cargar credenciales desde la base de datos
  Future<void> loadCredentials() async {
    try {
      isLoading.value = true;
      Log.i('CredentialsListController', 'Cargando credenciales desde base de datos');
      
      // Obtener el usuario actual
      final users = await _userRepository.getAllUsers();
      if (users.isEmpty) {
        Log.w('CredentialsListController', 'No se encontró usuario activo');
        credentialsList.clear();
        return;
      }
      
      final currentUser = users.first;
      
      // Cargar credenciales del usuario actual
      final credentials = await _credentialRepository.getCredentialsByUserId(currentUser.id!);
      credentialsList.value = credentials;
      
      // Siempre actualizar filteredCredentialsList aplicando el filtro actual
      if (searchQuery.value.isEmpty) {
        filteredCredentialsList.assignAll(credentials);
      } else {
        // Reaplicar el filtro con los nuevos datos
        final lowercaseQuery = searchQuery.value.toLowerCase();
        final filtered = credentials.where((credential) {
          final nombre = credential.nombre?.toLowerCase() ?? '';
          final curp = credential.curp?.toLowerCase() ?? '';
          return nombre.contains(lowercaseQuery) || curp.contains(lowercaseQuery);
        }).toList();
        filteredCredentialsList.assignAll(filtered);
      }
      
      Log.i('CredentialsListController', 'Cargadas ${credentials.length} credenciales');
      
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
    searchQuery.value = trimmedQuery;
    
    Log.i('CredentialsListController', 'Filtrando con query: "$trimmedQuery"');
    Log.i('CredentialsListController', 'credentialsList.length: ${credentialsList.length}');
    
    if (trimmedQuery.isEmpty) {
      Log.i('CredentialsListController', 'Antes de assignAll - credentialsList: ${credentialsList.length}');
      filteredCredentialsList.assignAll(credentialsList);
      Log.i('CredentialsListController', 'Después de assignAll - filteredCredentialsList: ${filteredCredentialsList.length}');
      Log.i('CredentialsListController', 'credentialsList contenido: ${credentialsList.map((c) => c.nombre).toList()}');
      Log.i('CredentialsListController', 'Query vacío - mostrando todas las credenciales: ${filteredCredentialsList.length}');
    } else {
      final lowercaseQuery = trimmedQuery.toLowerCase();
      final filtered = credentialsList.where((credential) {
        final nombre = credential.nombre?.toLowerCase() ?? '';
        final curp = credential.curp?.toLowerCase() ?? '';
        return nombre.contains(lowercaseQuery) || curp.contains(lowercaseQuery);
      }).toList();
      filteredCredentialsList.assignAll(filtered);
      Log.i('CredentialsListController', 'Filtrado completado - resultados: ${filteredCredentialsList.length}');
    }
    
    // Forzar actualización de la UI
    filteredCredentialsList.refresh();
  }
  
  /// Limpiar búsqueda
  void clearSearch() {
    Log.i('CredentialsListController', 'Limpiando búsqueda');
    Log.i('CredentialsListController', 'credentialsList.length antes de limpiar: ${credentialsList.length}');
    
    searchQuery.value = '';
    filteredCredentialsList.assignAll(credentialsList);
    
    Log.i('CredentialsListController', 'Búsqueda limpiada - filteredCredentialsList.length: ${filteredCredentialsList.length}');
    Log.i('CredentialsListController', 'searchQuery después de limpiar: "${searchQuery.value}"');
    
    // Forzar actualización de la UI
    filteredCredentialsList.refresh();
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