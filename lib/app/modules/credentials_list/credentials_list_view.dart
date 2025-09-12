import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/credential_model.dart';
import 'credentials_list_controller.dart';
import '../../global_widgets/user_settings_widget.dart';

class CredentialsListView extends GetView<CredentialsListController> {
  const CredentialsListView({super.key});

  static final TextEditingController _searchController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Más opciones',
            onSelected: (String value) {
              switch (value) {
                case 'settings':
                  Get.to(() => const UserSettingsWidget());
                  break;
                case 'export':
                  // TODO: Implementar funcionalidad de exportar
                  Get.snackbar(
                    'Exportar',
                    'Funcionalidad de exportar en desarrollo',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Configuraciones'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Exportar'),
                      ],
                    ),
                  ),
                ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                print('TextField onChanged: "$value"');
                controller.filterCredentials(value);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por Nombre o CURP...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        controller.clearSearch();
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          // Lista de credenciales
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (controller.filteredCredentialsList.isEmpty &&
                  controller.searchQuery.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No se encontraron resultados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Intenta con otro término de búsqueda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
                  itemCount: controller.filteredCredentialsList.length,
                  itemBuilder: (context, index) {
                    final credential =
                        controller.filteredCredentialsList[index];
                    return _buildCredentialCard(context, credential);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialCard(
    BuildContext context,
    CredentialModel credential,
  ) {
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
          credential.nombre ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'CURP: ${credential.curp ?? 'N/A'}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Capturada: ${credential.fechaCaptura != null ? _formatDateTime(credential.fechaCaptura!) : 'N/A'}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                controller.editCredential(credential);
                break;
            }
          },
          itemBuilder:
              (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Editar'),
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

  /// Formatea la fecha y hora de captura
  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
