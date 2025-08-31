import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ocr_controller.dart';
import '../../global_widgets/user_settings_widget.dart';

class OcrView extends GetView<OcrController> {
  const OcrView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procesamiento OCR'),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Procesamiento de Texto OCR',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Área de imagen\n(Por implementar)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => ElevatedButton(
              onPressed: controller.isProcessing.value ? null : controller.processImage,
              child: controller.isProcessing.value
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Procesando...'),
                      ],
                    )
                  : const Text('Procesar Imagen'),
            )),
            const SizedBox(height: 20),
            const Text(
              'Texto Extraído:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(() => SingleChildScrollView(
                  child: Text(
                    controller.extractedText.value.isEmpty
                        ? 'No hay texto extraído'
                        : controller.extractedText.value,
                    style: const TextStyle(fontSize: 16),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: controller.clearText,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Limpiar Texto'),
            ),
          ],
        ),
      ),
    );
  }
}