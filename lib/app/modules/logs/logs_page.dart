import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'logs_controller.dart';

class LogsPage extends GetView<LogsController> {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs y Depuración'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Estadísticas de logs
              _buildStatsSection(),
              const SizedBox(height: 16),
              
              // Acciones principales
              _buildActionsSection(),
              const SizedBox(height: 16),
              
              // Lista de archivos de log
              _buildLogFilesSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Get.theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Estadísticas',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Obx(() {
              final stats = controller.logStats;
              if (stats.isEmpty) {
                return const Text('Cargando estadísticas...');
              }
              
              return Column(
                children: [
                  _buildStatRow('Archivos de log', '${stats['totalFiles'] ?? 0}'),
                  _buildStatRow('Total de líneas', '${stats['totalLines'] ?? 0}'),
                  _buildStatRow('Tamaño total', '${stats['totalSizeMB'] ?? 0} MB'),
                  const SizedBox(height: 8),
                  const Text(
                    'Los logs se mantienen automáticamente por 7 días.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.blue),
            title: const Text('Exportar logs'),
            subtitle: const Text('Compartir logs de errores y depuración'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showExportDialog(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Limpiar logs'),
            subtitle: const Text('Eliminar todos los logs almacenados'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showClearDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogFilesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, color: Get.theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Archivos de Log',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Obx(() {
              if (controller.logFiles.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No hay archivos de log disponibles',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                children: controller.logFiles.map((file) {
                  final fileName = file.path.split('\\').last;
                  final fileSize = _getFileSize(file);
                  final lastModified = _getLastModified(file);

                  return ListTile(
                    leading: const Icon(Icons.description, color: Colors.orange),
                    title: Text(fileName),
                    subtitle: Text('$fileSize • $lastModified'),
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: const Row(
                            children: [
                              Icon(Icons.visibility),
                              SizedBox(width: 8),
                              Text('Ver contenido'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: const Row(
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 8),
                              Text('Compartir'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'view') {
                          _showLogContent(file);
                        } else if (value == 'share') {
                          _shareLogFile(file);
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Desconocido';
    }
  }

  String _getLastModified(File file) {
    try {
      final modified = file.lastModifiedSync();
      final now = DateTime.now();
      final difference = now.difference(modified);
      
      if (difference.inDays > 0) {
        return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'Hace unos segundos';
      }
    } catch (e) {
      return 'Desconocido';
    }
  }

  void _showExportDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Exportar Logs'),
        content: const Text(
          '¿Deseas exportar todos los logs? Se creará un archivo '
          'con todos los logs disponibles que podrás compartir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.exportLogs();
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Limpiar Logs'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los logs? '
          'Esta acción no se puede deshacer y puede dificultar la '
          'resolución de problemas futuros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.clearAllLogs();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showLogContent(File file) {
    Get.dialog(
      Dialog(
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      file.path.split('\\').last,
                      style: Get.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<String>(
                  future: file.readAsString(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    
                    return SingleChildScrollView(
                      child: SelectableText(
                        snapshot.data ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareLogFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Log: ${file.path.split('\\').last}',
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo compartir el archivo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}