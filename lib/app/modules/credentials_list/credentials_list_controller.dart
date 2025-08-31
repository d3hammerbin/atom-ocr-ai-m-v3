import 'package:get/get.dart';

class CredentialsListController extends GetxController {
  // Lista observable de credenciales procesadas
  final RxList<Map<String, dynamic>> credentialsList = <Map<String, dynamic>>[].obs;
  
  // Estado de carga
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadCredentials();
  }


  
  /// Cargar credenciales desde almacenamiento local
  void loadCredentials() {
    isLoading.value = true;
    
    // TODO: Implementar carga desde almacenamiento local
    // Por ahora, datos de ejemplo
    Future.delayed(const Duration(milliseconds: 500), () {
      credentialsList.value = [
        {
          'id': '1',
          'nombre': 'Juan Pérez García',
          'curp': 'PEGJ850315HDFRZN09',
          'fechaCaptura': '2024-01-15',
          'tipoCredencial': 'Cédula de Identidad',
        },
        {
          'id': '2',
          'nombre': 'María González López',
          'curp': 'GOLM920728MDFNPR04',
          'fechaCaptura': '2024-01-14',
          'tipoCredencial': 'Cédula de Identidad',
        },
      ];
      isLoading.value = false;
    });
  }
  
  /// Eliminar una credencial de la lista
  void deleteCredential(String id) {
    credentialsList.removeWhere((credential) => credential['id'] == id);
    Get.snackbar(
      'Eliminado',
      'Credencial eliminada exitosamente',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  /// Refrescar la lista de credenciales
  void refreshCredentials() {
    loadCredentials();
  }
  
  /// Navegar a los detalles de una credencial
  void viewCredentialDetails(Map<String, dynamic> credential) {
    // TODO: Implementar navegación a detalles
    Get.snackbar(
      'Detalles',
      'Mostrando detalles de ${credential['nombre']}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}