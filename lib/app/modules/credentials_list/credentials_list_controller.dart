import 'package:get/get.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/services/logger_service.dart';
import '../../data/models/credential_model.dart';
import '../../data/repositories/credential_repository.dart';
import '../../data/repositories/user_repository.dart';

class CredentialsListController extends GetxController {
  // Lista observable de credenciales procesadas
  final RxList<CredentialModel> credentialsList = <CredentialModel>[].obs;
  
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
  void refreshCredentials() {
    loadCredentials();
  }
  
  /// Navega a los detalles de una credencial
  void viewCredentialDetails(CredentialModel credential) {
    Get.toNamed('/credential-details', arguments: credential.id);
  }
}