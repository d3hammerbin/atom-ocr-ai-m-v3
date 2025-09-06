import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../core/user_preferences_controller.dart';
import '../core/app_version_service.dart';
import '../core/services/logger_service.dart';
import '../core/services/hidden_menu_service.dart';
import '../modules/device/device_info_page.dart';
import '../modules/device/device_controller.dart';
import '../data/repositories/device_repository.dart';

class UserSettingsWidget extends StatefulWidget {
  const UserSettingsWidget({super.key});

  @override
  State<UserSettingsWidget> createState() => _UserSettingsWidgetState();
}

class _UserSettingsWidgetState extends State<UserSettingsWidget> {
  final HiddenMenuService _hiddenMenuService = Get.put(HiddenMenuService());

  @override
  Widget build(BuildContext context) {
    final UserPreferencesController preferencesController = Get.find<UserPreferencesController>();
    final AppVersionService versionService = AppVersionService.to;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones'),
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sección de Apariencia
          _buildSectionHeader('Apariencia'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Obx(() => Icon(preferencesController.themeModeIcon)),
                  title: const Text('Tema'),
                  subtitle: Obx(() => Text(preferencesController.themeModeText)),
                  trailing: PopupMenuButton<AppThemeMode>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (AppThemeMode mode) {
                      preferencesController.changeTheme(mode);
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<AppThemeMode>(
                        value: AppThemeMode.light,
                        child: Row(
                          children: [
                            const Icon(Icons.light_mode),
                            const SizedBox(width: 12),
                            const Text('Claro'),
                            const Spacer(),
                            Obx(() => preferencesController.themeMode == AppThemeMode.light
                                ? const Icon(Icons.check, color: Colors.blue)
                                : const SizedBox.shrink()),
                          ],
                        ),
                      ),
                      PopupMenuItem<AppThemeMode>(
                        value: AppThemeMode.dark,
                        child: Row(
                          children: [
                            const Icon(Icons.dark_mode),
                            const SizedBox(width: 12),
                            const Text('Oscuro'),
                            const Spacer(),
                            Obx(() => preferencesController.themeMode == AppThemeMode.dark
                                ? const Icon(Icons.check, color: Colors.blue)
                                : const SizedBox.shrink()),
                          ],
                        ),
                      ),
                      PopupMenuItem<AppThemeMode>(
                        value: AppThemeMode.system,
                        child: Row(
                          children: [
                            const Icon(Icons.brightness_auto),
                            const SizedBox(width: 12),
                            const Text('Sistema'),
                            const Spacer(),
                            Obx(() => preferencesController.themeMode == AppThemeMode.system
                                ? const Icon(Icons.check, color: Colors.blue)
                                : const SizedBox.shrink()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sección de Funcionalidad
          _buildSectionHeader('Funcionalidad'),
          Card(
            child: Column(
              children: [
                Obx(() => SwitchListTile(
                  secondary: const Icon(Icons.save_alt),
                  title: const Text('Guardar resultados automáticamente'),
                  subtitle: const Text('Los resultados de OCR se guardan automáticamente'),
                  value: preferencesController.autoSaveResults,
                  onChanged: (bool value) {
                    preferencesController.toggleAutoSaveResults();
                  },
                )),
                Obx(() => SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Notificaciones'),
                  subtitle: const Text('Recibir notificaciones de la aplicación'),
                  value: preferencesController.notificationsEnabled,
                  onChanged: (bool value) {
                    preferencesController.toggleNotifications();
                  },
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sección de Datos
          _buildSectionHeader('Datos'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Exportar configuraciones'),
                  subtitle: const Text('Guardar una copia de tus preferencias'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showExportDialog(context, preferencesController);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Importar configuraciones'),
                  subtitle: const Text('Restaurar preferencias desde un archivo'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showImportDialog(context, preferencesController);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.orange),
                  title: const Text('Restablecer configuraciones'),
                  subtitle: const Text('Volver a los valores predeterminados'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showResetDialog(context, preferencesController);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sección de Logs
          _buildSectionHeader('Logs y Depuración'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Exportar logs'),
                  subtitle: const Text('Compartir logs de errores y depuración'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showExportLogsDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Ver estadísticas de logs'),
                  subtitle: const Text('Información sobre los logs almacenados'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showLogStatsDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Limpiar logs'),
                  subtitle: const Text('Eliminar todos los logs almacenados'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showClearLogsDialog(context);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sección Sobre nosotros
          _buildSectionHeader('Sobre nosotros'),
          Card(
            child: Column(
              children: [
                Obx(() => ListTile(
                   leading: const Icon(Icons.info_outline),
                   title: const Text('Versión'),
                   subtitle: Text(versionService.isLoading ? 'Cargando...' : versionService.fullVersion),
                 )),
                Obx(() => ListTile(
                   leading: Icon(
                     Icons.person,
                     color: _hiddenMenuService.showHeartIndicator.value ? Colors.red : null,
                   ),
                   title: Row(
                     children: [
                       const Text('Autor'),
                       if (_hiddenMenuService.showHeartIndicator.value) ...[
                         const SizedBox(width: 8),
                         const Text('❤️', style: TextStyle(fontSize: 16)),
                       ],
                     ],
                   ),
                   subtitle: const Text('Ricardo Madrigal Rodriguez'),
                   onTap: () {
                     _hiddenMenuService.registerClick();
                   },
                 )),
                 // Opción del menú oculto
                 Obx(() => _hiddenMenuService.isHiddenMenuEnabled
                   ? ListTile(
                       leading: const Icon(Icons.developer_mode, color: Colors.orange),
                       title: const Text('Información del Sistema'),
                       subtitle: const Text('Datos detallados del usuario y dispositivo'),
                       trailing: const Icon(Icons.arrow_forward_ios),
                       onTap: () {
                         // Asegurar que las dependencias estén disponibles
                         Get.put(DeviceRepository());
                         Get.put(DeviceController());
                         Get.to(() => const DeviceInfoPage());
                       },
                     )
                   : const SizedBox.shrink(),
                 ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  void _showExportDialog(BuildContext context, UserPreferencesController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exportar Configuraciones'),
          content: const Text(
            'Se exportarán todas tus preferencias actuales. '
            'Podrás usar este archivo para restaurar tus configuraciones más tarde.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Aquí se implementaría la lógica para guardar el archivo
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuraciones exportadas exitosamente'),
                    backgroundColor: Colors.grey,
                  ),
                );
              },
              child: const Text('Exportar'),
            ),
          ],
        );
      },
    );
  }
  
  void _showImportDialog(BuildContext context, UserPreferencesController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Importar Configuraciones'),
          content: const Text(
            'Selecciona un archivo de configuraciones previamente exportado. '
            'Esto sobrescribirá tus configuraciones actuales.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Aquí se implementaría la lógica para seleccionar y cargar el archivo
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuraciones importadas exitosamente'),
                    backgroundColor: Colors.grey,
                  ),
                );
              },
              child: const Text('Importar'),
            ),
          ],
        );
      },
    );
  }
  
  void _showResetDialog(BuildContext context, UserPreferencesController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restablecer Configuraciones'),
          content: const Text(
            '¿Estás seguro de que quieres restablecer todas las configuraciones '
            'a sus valores predeterminados? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.resetAllPreferences();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuraciones restablecidas exitosamente'),
                    backgroundColor: Colors.grey,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restablecer'),
            ),
          ],
        );
      },
    );
  }
  
  void _showExportLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exportar Logs'),
          content: const Text(
            'Se exportarán todos los logs de errores y depuración. '
            'Esto puede ser útil para reportar problemas o para soporte técnico.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                navigator.pop();
                
                try {
                  // Mostrar indicador de carga
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  
                  final exportedFile = await LoggerService.instance.exportLogs();
                  
                  // Cerrar indicador de carga
                  navigator.pop();
                  
                  if (exportedFile != null) {
                    // Compartir el archivo
                    await Share.shareXFiles(
                      [XFile(exportedFile.path)],
                      text: 'Logs de Atom OCR AI - ${DateTime.now().toString().split(' ')[0]}',
                    );
                    
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Logs exportados exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Error al exportar logs'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  // Cerrar indicador de carga si está abierto
                  navigator.pop();
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error al exportar logs: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Exportar'),
            ),
          ],
        );
      },
    );
  }
  
  void _showLogStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Estadísticas de Logs'),
          content: FutureBuilder<Map<String, dynamic>>(
            future: LoggerService.instance.getLogStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              
              final stats = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Archivos de log: ${stats['totalFiles']}'),
                  const SizedBox(height: 8),
                  Text('Total de líneas: ${stats['totalLines']}'),
                  const SizedBox(height: 8),
                  Text('Tamaño total: ${stats['totalSizeMB']} MB'),
                  const SizedBox(height: 16),
                  const Text(
                    'Los logs se mantienen automáticamente por 7 días.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
  
  void _showClearLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpiar Logs'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar todos los logs? '
            'Esta acción no se puede deshacer y puede dificultar la '
            'resolución de problemas futuros.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                navigator.pop();
                
                try {
                  await LoggerService.instance.clearAllLogs();
                  
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Logs eliminados exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar logs: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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