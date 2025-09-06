import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'credentials_list_controller.dart';
import '../../global_widgets/user_settings_widget.dart';

class CredentialsListView extends GetView<CredentialsListController> {
  const CredentialsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credenciales Procesadas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Ir al inicio',
            onPressed: () {
              Get.offAllNamed('/home');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuraciones',
            onPressed: () {
              Get.to(() => const UserSettingsWidget());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (controller.credentialsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.credit_card_off,
                  size: 80,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 20),
                Text(
                  'No hay credenciales procesadas',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Las credenciales que captures aparecerán aquí',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            controller.refreshCredentials();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: controller.credentialsList.length,
            itemBuilder: (context, index) {
              final credential = controller.credentialsList[index];
              return _buildCredentialCard(context, credential);
            },
          ),
        );      }),
    );
  }
  
  Widget _buildCredentialCard(BuildContext context, Map<String, dynamic> credential) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.credit_card,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          credential['nombre'] ?? 'Sin nombre',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'CURP: ${credential['curp'] ?? 'N/A'}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Capturada: ${credential['fechaCaptura'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                controller.viewCredentialDetails(credential);
                break;
              case 'delete':
                _showDeleteDialog(context, credential);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Ver detalles'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          controller.viewCredentialDetails(credential);
        },
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context, Map<String, dynamic> credential) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Credencial'),
          content: Text(
            '¿Estás seguro de que quieres eliminar la credencial de ${credential['nombre']}?\n\nEsta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.deleteCredential(credential['id']);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}