import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'local_process_controller.dart';

class LocalProcessView extends GetView<LocalProcessController> {
  const LocalProcessView({super.key});

  Widget _buildCredentialField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value?.isNotEmpty == true ? value! : 'No disponible',
              style: TextStyle(
                fontSize: 14,
                color: value?.isNotEmpty == true 
                    ? null 
                    : Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                fontStyle: value?.isNotEmpty == true 
                    ? FontStyle.normal 
                    : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procesar Local'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botón para seleccionar imagen
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Selecciona una imagen para procesar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Obx(() => ElevatedButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.selectImageFromGallery,
                        icon: controller.isLoading.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.photo_library),
                        label: Text(
                          controller.isLoading.value
                              ? 'Cargando...'
                              : 'Seleccionar desde Galería',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 45),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Área de visualización de imagen
              Obx(() {
                if (controller.errorMessage.value.isNotEmpty) {
                  return Card(
                    color: Colors.red.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.errorMessage.value,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                if (controller.hasSelectedImage) {
                  return Column(
                    children: [
                      Card(
                        child: Column(
                          children: [
                            // Header con información de la imagen
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Imagen seleccionada',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: controller.clearSelectedImage,
                                    tooltip: 'Limpiar imagen',
                                  ),
                                ],
                              ),
                            ),
                            
                            // Imagen
                            Container(
                              width: double.infinity,
                              height: 300,
                              padding: const EdgeInsets.all(16.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(controller.selectedImagePath.value),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Error al cargar la imagen',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            
                            // Botones de procesamiento
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  // Botón para extraer y procesar credencial INE
                                  Obx(() => ElevatedButton.icon(
                                    onPressed: (controller.isExtractingText.value || controller.isProcessingCredential.value)
                                        ? null
                                        : controller.extractAndProcessIneCredential,
                                    icon: (controller.isExtractingText.value || controller.isProcessingCredential.value)
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.auto_fix_high),
                                    label: Text(
                                      (controller.isExtractingText.value || controller.isProcessingCredential.value)
                                          ? 'Procesando...'
                                          : 'Extraer y Procesar INE',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 45),
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Área de credencial procesada
                      Obx(() {
                        if (controller.hasProcessedCredential) {
                          final credential = controller.processedCredential.value!;
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
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
                                      Icons.credit_card,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Credencial INE Procesada:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: controller.clearProcessedCredential,
                                      tooltip: 'Limpiar credencial',
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildCredentialField('Nombre', credential.nombre),
                                _buildCredentialField('CURP', credential.curp),
                                _buildCredentialField('Clave de Elector', credential.claveElector),
                                _buildCredentialField('Fecha de Nacimiento', credential.fechaNacimiento),
                                _buildCredentialField('Sexo', credential.sexo),
                                _buildCredentialField('Domicilio', credential.domicilio),
                                _buildCredentialField('Año de Registro', credential.anoRegistro),
                                _buildCredentialField('Sección', credential.seccion),
                                _buildCredentialField('Vigencia', credential.vigencia),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      
                      // Área de texto extraído (colapsible)
                      Obx(() {
                        if (controller.extractedText.value.isNotEmpty) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.text_snippet,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Texto Extraído (Raw)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: controller.clearExtractedText,
                                tooltip: 'Limpiar texto',
                                iconSize: 20,
                              ),
                              children: [
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(maxHeight: 150),
                                  child: SingleChildScrollView(
                                    child: Container(
                                      width: double.infinity,
                                      child: SelectableText(
                                        controller.extractedText.value,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  );
                }
                
                // Estado inicial - sin imagen seleccionada
                return Card(
                  child: Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay imagen seleccionada',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Selecciona una imagen para comenzar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}