import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import '../../global_widgets/user_settings_widget.dart';
import '../../core/app_version_service.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final versionService = AppVersionService.to;
          return Text(
            versionService.isLoading ? 'Atom OCR AI' : versionService.appTitle,
          );
        }),
        actions: [
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Atom OCR AI (Beta)',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aplicación móvil para reconocimiento óptico de caracteres',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Tips de fotografía
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tips para mejores resultados:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTipItem(
                        context,
                        Icons.wb_sunny,
                        'Tomar fotografías con buena iluminación',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        context,
                        Icons.crop_square,
                        'De preferencia con fondo blanco',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        context,
                        Icons.wifi,
                        'Para compartir requiere conexión a internet',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: controller.navigateToCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capturar Credencial'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: controller.navigateToCredentialsList,
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Credenciales Procesadas'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                ),
                const SizedBox(height: 20),
                Visibility(
                  visible: false,
                  child: ElevatedButton.icon(
                    onPressed: controller.navigateToLocalProcess,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Procesar Local'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
