import 'package:get/get.dart';
import '../../data/models/credential_model.dart';
import '../../data/repositories/credential_repository.dart';
import '../../data/repositories/user_repository.dart';

class CredentialDetailsController extends GetxController {
  final CredentialRepository _credentialRepository = CredentialRepository();
  final UserRepository _userRepository = UserRepository();
  
  final Rx<CredentialModel?> credential = Rx<CredentialModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    final credentialId = Get.arguments as int?;
    if (credentialId != null) {
      loadCredentialDetails(credentialId);
    }
  }
  
  /// Carga los detalles de una credencial específica
  Future<void> loadCredentialDetails(int credentialId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final loadedCredential = await _credentialRepository.getCredentialById(credentialId);
      credential.value = loadedCredential;
      
    } catch (e) {
      errorMessage.value = 'Error al cargar los detalles de la credencial: $e';
      print('Error loading credential details: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Elimina la credencial actual
  Future<void> deleteCredential() async {
    if (credential.value?.id == null) return;
    
    try {
      isLoading.value = true;
      await _credentialRepository.deleteCredential(credential.value!.id!);
      
      Get.back(); // Regresar a la lista
      Get.snackbar(
        'Éxito',
        'Credencial eliminada correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      errorMessage.value = 'Error al eliminar la credencial: $e';
      Get.snackbar(
        'Error',
        'No se pudo eliminar la credencial',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Navega a la pantalla de edición
  void editCredential() {
    if (credential.value?.id != null) {
      Get.toNamed('/credential-processing', arguments: credential.value);
    }
  }
  
  /// Refresca los datos de la credencial
  Future<void> refreshCredential() async {
    if (credential.value?.id != null) {
      await loadCredentialDetails(credential.value!.id!);
    }
  }
}