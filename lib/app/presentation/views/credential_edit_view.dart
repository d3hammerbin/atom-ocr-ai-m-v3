import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/credential_edit_controller.dart';

class CredentialEditView extends StatelessWidget {
  const CredentialEditView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CredentialEditController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Credencial'),
        actions: [
          Obx(
            () =>
                controller.isSaving.value
                    ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: controller.saveChanges,
                      tooltip: 'Guardar cambios',
                    ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: Colors.red[700], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Volver'),
                ),
              ],
            ),
          );
        }

        final credential = controller.credential.value;
        if (credential == null) {
          return const Center(
            child: Text(
              'No se encontró la credencial',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return Obx(() => AbsorbPointer(
          absorbing: controller.isSaving.value,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de imágenes
                  _buildImagesSection(credential),
                  const SizedBox(height: 24),

                  // Información personal
                  _buildPersonalInfoSection(controller),
                  const SizedBox(height: 24),

                  // Información electoral
                  _buildElectoralInfoSection(controller),
                  const SizedBox(height: 24),

                  // Información de ubicación
                  _buildLocationInfoSection(controller),
                  const SizedBox(height: 32),

                  // Botones de acción
                  _buildActionButtons(controller),
                ],
              ),
            ),
          ),
        ));
      }),
    );
  }

  Widget _buildImagesSection(credential) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image_outlined, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Imágenes de la Credencial',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Grid de imágenes
            _buildImageGrid(credential),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(credential) {
    final images = <Map<String, String>>[];

    // Solo mostrar imágenes frontal y trasera como referencia
    if (credential.frontImagePath != null &&
        credential.frontImagePath!.isNotEmpty) {
      images.add({
        'path': credential.frontImagePath!,
        'label': 'Imagen Frontal',
      });
    }
    if (credential.backImagePath != null &&
        credential.backImagePath!.isNotEmpty) {
      images.add({
        'path': credential.backImagePath!,
        'label': 'Imagen Trasera',
      });
    }

    if (images.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No hay imágenes disponibles',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return _buildImageTile(image['path']!, image['label']!);
      },
    );
  }

  Widget _buildImageTile(String imagePath, String label) {
    // Ajustar altura especial para imagen MRZ
    final isMrzImage = label.toLowerCase().contains('mrz');
    final aspectRatio = isMrzImage ? 3.0 : 1.2; // MRZ más alta

    return GestureDetector(
      onTap: () => _showImageDialog(imagePath, label),
      child: Card(
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child:
                    File(imagePath).existsSync()
                        ? Image.file(
                          File(imagePath),
                          fit:
                              isMrzImage
                                  ? BoxFit.fitWidth
                                  : BoxFit.cover, // Ajuste especial para MRZ
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                        : const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imagePath, String label) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(imagePath),
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 64,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(CredentialEditController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Información Personal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            TextFormField(
              controller: controller.nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator:
                  (value) => controller.validateRequired(value, 'El nombre'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: controller.curpController,
              decoration: const InputDecoration(
                labelText: 'CURP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fingerprint),
                hintText: 'AAAA######HAAAAA##',
              ),
              validator: controller.validateCurp,
              textCapitalization: TextCapitalization.characters,
              maxLength: 18,
            ),
            const SizedBox(height: 16),

            // DatePicker para fecha de nacimiento
            GestureDetector(
              onTap: () => controller.selectDate(Get.context!),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: controller.fechaNacimientoController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Nacimiento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: 'DD/MM/YYYY',
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  validator: controller.validateDate,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown para sexo
            Obx(
              () => DropdownButtonFormField<String>(
                value:
                    controller.selectedSexo.value.isEmpty
                        ? null
                        : controller.selectedSexo.value,
                decoration: const InputDecoration(
                  labelText: 'Sexo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                items:
                    controller.sexoOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option['value'],
                        child: Text(option['label']!),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.selectedSexo.value = newValue;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona el sexo';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElectoralInfoSection(CredentialEditController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_vote_outlined, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Información Electoral',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            TextFormField(
              controller: controller.claveElectorController,
              decoration: const InputDecoration(
                labelText: 'Clave de Elector',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              validator: controller.validateClaveElector,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: controller.seccionController,
              decoration: const InputDecoration(
                labelText: 'Sección Electoral',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.anoRegistroController,
                    decoration: const InputDecoration(
                      labelText: 'Año de Registro',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.date_range),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller.vigenciaController,
                    decoration: const InputDecoration(
                      labelText: 'Vigencia',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfoSection(CredentialEditController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_city_outlined, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Información de Ubicación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            TextFormField(
              controller: controller.domicilioController,
              decoration: const InputDecoration(
                labelText: 'Domicilio',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Dropdown para estado
            Obx(
              () => DropdownButtonFormField<String>(
                value:
                    controller.selectedEstado.value.isEmpty
                        ? null
                        : controller.selectedEstado.value,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                items:
                    controller.estadosMexico.map((estado) {
                      return DropdownMenuItem<String>(
                        value: estado,
                        child: Text(estado),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.selectedEstado.value = newValue;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona un estado';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(CredentialEditController controller) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Obx(
            () => ElevatedButton.icon(
              onPressed:
                  controller.isSaving.value ? null : controller.saveChanges,
              icon:
                  controller.isSaving.value
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save),
              label: Text(
                controller.isSaving.value ? 'Guardando...' : 'Guardar Cambios',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }
}
