import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/special_settings_service.dart';

class SpecialSettingsPage extends StatelessWidget {
  const SpecialSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SpecialSettingsService settingsService = Get.find<SpecialSettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones Especiales'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Descripción
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Información',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Estas son configuraciones avanzadas que pueden afectar el comportamiento de la aplicación. Úsalas con precaución.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sección de Procesamiento Local
              Text(
                'Procesamiento Local',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              // Switch para mostrar "Procesar Local"
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Obx(() => SwitchListTile(
                        title: const Text(
                          'Mostrar "Procesar Local"',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Habilita la opción de procesamiento local en la pantalla principal',
                        ),
                        value: settingsService.showLocalProcess,
                        onChanged: (bool value) {
                          settingsService.setShowLocalProcess(value);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      )),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sección de Análisis de Calidad
              Text(
                'Análisis de Imagen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              // Switch para análisis de calidad de imagen
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Obx(() => SwitchListTile(
                        title: const Text(
                          'Análisis de Calidad de Imagen',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Habilita el análisis automático de calidad de imagen y muestra recomendaciones',
                        ),
                        value: settingsService.enableImageQualityAnalysis,
                        onChanged: (bool value) {
                          settingsService.setImageQualityAnalysis(value);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      )),
                      
                      // Información adicional cuando está deshabilitado
                      Obx(() => !settingsService.enableImageQualityAnalysis
                          ? Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange.shade700,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'El análisis de calidad está deshabilitado. No se mostrarán recomendaciones de mejora.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sección de Cámara
              Text(
                'Configuración de Cámara',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              // Switch para habilitar/deshabilitar flash
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Obx(() => SwitchListTile(
                        title: const Text(
                          'Habilitar Flash',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Permite el uso del flash de la cámara durante la captura',
                        ),
                        value: settingsService.enableFlash,
                        onChanged: (bool value) {
                          settingsService.setFlash(value);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      )),
                      
                      // Información adicional cuando está deshabilitado
                      Obx(() => !settingsService.enableFlash
                          ? Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'El botón de flash estará oculto en la interfaz de cámara',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Sección de Administración de Datos
              Text(
                'Administración de Datos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              // Botón para limpiar base de datos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text(
                          'Limpiar Base de Datos',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Elimina permanentemente todos los datos almacenados en la aplicación',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            _showClearDatabaseDialog(context, settingsService);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Limpiar'),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      
                      // Advertencia
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.red.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Esta acción es irreversible. Se eliminarán todas las credenciales, usuarios y datos del dispositivo.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botón para exportar/compartir base de datos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.share, color: Colors.blue),
                        title: const Text(
                          'Exportar/Compartir Base de Datos',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Comparte el archivo completo de la base de datos con todas las credenciales y datos',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            _showExportDatabaseDialog(context, settingsService);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Exportar'),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      
                      // Información
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'El archivo se compartirá usando las opciones nativas del sistema (WhatsApp, email, etc.).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botón para reiniciar configuraciones
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showResetDialog(context, settingsService);
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Reiniciar Configuraciones'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Muestra el diálogo de confirmación para reiniciar configuraciones
  void _showResetDialog(BuildContext context, SpecialSettingsService settingsService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reiniciar Configuraciones'),
          content: const Text(
            '¿Estás seguro de que quieres reiniciar todas las configuraciones especiales a sus valores por defecto?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                settingsService.resetSettings();
                Navigator.of(context).pop();
                Get.snackbar(
                  'Configuraciones Reiniciadas',
                  'Todas las configuraciones especiales han sido reiniciadas',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reiniciar'),
            ),
          ],
        );
      },
    );
  }
  
  /// Muestra el diálogo de confirmación para limpiar la base de datos
  void _showClearDatabaseDialog(BuildContext context, SpecialSettingsService settingsService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
             children: [
               Icon(Icons.warning, color: Colors.red),
               SizedBox(width: 8),
               Expanded(
                 child: Text(
                   'Limpiar Base de Datos',
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
             ],
           ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que quieres eliminar TODOS los datos de la aplicación?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text('Esta acción eliminará:'),
              SizedBox(height: 8),
              Text('• Todas las credenciales procesadas'),
              Text('• Todos los usuarios registrados'),
              Text('• Todos los datos del dispositivo'),
              Text('• Todos los geodatos'),
              SizedBox(height: 12),
              Text(
                'Esta acción NO se puede deshacer.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await settingsService.clearDatabase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar Todo'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra el diálogo de confirmación para exportar la base de datos
  void _showExportDatabaseDialog(BuildContext context, SpecialSettingsService settingsService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.share, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Exportar Base de Datos',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Deseas exportar y compartir la base de datos completa?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text('El archivo incluirá:'),
              SizedBox(height: 8),
              Text('• Todas las credenciales procesadas'),
              Text('• Todos los usuarios registrados'),
              Text('• Todos los datos del dispositivo'),
              Text('• Todos los geodatos'),
              SizedBox(height: 12),
              Text(
                'El archivo se compartirá usando las opciones de compartir del sistema.',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await settingsService.exportDatabase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Exportar'),
            ),
          ],
        );
      },
    );
  }
}