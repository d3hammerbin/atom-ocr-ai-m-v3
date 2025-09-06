import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../controllers/credential_details_controller.dart';
import '../../data/models/credential_model.dart';

class CredentialDetailsView extends StatelessWidget {
  const CredentialDetailsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CredentialDetailsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Credencial'),
        actions: [
          Obx(() => controller.credential.value != null
              ? IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareCredentialInfo(controller.credential.value!),
                  tooltip: 'Compartir información',
                )
              : const SizedBox()),
          // Menú oculto pero no eliminado
          Obx(() => Visibility(
            visible: false, // Oculto pero disponible
            child: controller.credential.value != null
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          controller.editCredential();
                          break;
                        case 'delete':
                          _showDeleteDialog(context, controller);
                          break;
                        case 'refresh':
                          controller.refreshCredential();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Actualizar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox(),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refreshCredential(),
                  child: const Text('Reintentar'),
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

        return RefreshIndicator(
          onRefresh: controller.refreshCredential,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(credential),
                const SizedBox(height: 16),
                _buildPersonalInfoCard(credential),
                const SizedBox(height: 16),
                _buildElectoralInfoCard(credential),
                const SizedBox(height: 16),
                _buildAddressCard(credential),
                const SizedBox(height: 16),
                _buildImagesCard(credential),
                const SizedBox(height: 16),
                _buildExtractedContentCard(credential),
                const SizedBox(height: 16),
                _buildMetadataCard(credential),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeaderCard(CredentialModel credential) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue[100],
              backgroundImage: credential.photoPath != null && credential.photoPath!.isNotEmpty
                  ? FileImage(File(credential.photoPath!))
                  : null,
              child: credential.photoPath == null || credential.photoPath!.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue[700],
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              credential.nombre ?? 'Sin nombre',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                'CURP: ${credential.curp ?? 'No disponible'}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(CredentialModel credential) {
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Fecha de Nacimiento', credential.fechaNacimiento),
            _buildInfoRow('Sexo', credential.sexo),
            _buildInfoRow('CURP', credential.curp),
            _buildInfoRow('Tipo de Credencial', credential.tipo?.toUpperCase()),
            _buildInfoRow('Lado', credential.lado)
          ],
        ),
      ),
    );
  }

  Widget _buildElectoralInfoCard(CredentialModel credential) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_vote, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Información Electoral',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Clave de Elector', credential.claveElector),
            _buildInfoRow('Año de Registro', credential.anoRegistro),
            _buildInfoRow('Vigencia', credential.vigencia),
            // Emisión no está disponible en el modelo actual
            _buildInfoRow('Sección', credential.seccion),
            _buildInfoRow('Localidad', credential.localidad),
            _buildInfoRow('Municipio', credential.municipio),
            _buildInfoRow('Estado', credential.estado),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(CredentialModel credential) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Dirección',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Domicilio', credential.domicilio),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesCard(CredentialModel credential) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Imágenes Capturadas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildImageGrid(credential),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(CredentialModel credential) {
    final images = [
      {'path': credential.photoPath, 'label': 'Foto', 'icon': Icons.face},
      {'path': credential.signaturePath, 'label': 'Firma', 'icon': Icons.draw},
      {'path': credential.qrImagePath, 'label': 'QR', 'icon': Icons.qr_code},
      {'path': credential.barcodeImagePath, 'label': 'Código de Barras', 'icon': Icons.barcode_reader},
      {'path': credential.mrzImagePath, 'label': 'MRZ', 'icon': Icons.text_fields},
      {'path': credential.signatureHuellaImagePath, 'label': 'Huella', 'icon': Icons.fingerprint},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        final path = image['path'] as String?;
        final label = image['label'] as String;
        final icon = image['icon'] as IconData;
        
        return GestureDetector(
          onTap: path != null && path.isNotEmpty 
              ? () => _showImageDialog(context, path, label)
              : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: path != null && path.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                icon,
                                size: 32,
                                color: Colors.grey[400],
                              );
                            },
                          ),
                        )
                      : Icon(
                          icon,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: path != null && path.isNotEmpty 
                        ? Colors.blue[50] 
                        : Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: path != null && path.isNotEmpty 
                          ? Colors.blue[700] 
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExtractedContentCard(CredentialModel credential) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_snippet_outlined, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Contenidos Extraídos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildExpandableContent('Contenido QR', credential.qrContent),
            _buildExpandableContent('Contenido Código de Barras', credential.barcodeContent),
            _buildExpandableContent('Contenido MRZ', credential.mrzContent),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableContent(String title, String? content) {
    if (content == null || content.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.remove_circle_outline, color: Colors.grey[400], size: 16),
            const SizedBox(width: 8),
            Text(
              '$title: No disponible',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      leading: Icon(Icons.check_circle_outline, color: Colors.green[600], size: 16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: SelectableText(
            content,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataCard(CredentialModel credential) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Información del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Fecha de Captura', credential.fechaCaptura != null 
                ? _formatDateTime(credential.fechaCaptura!) 
                : null),
            _buildInfoRow('Fecha de Creación', credential.createdAt != null 
                ? _formatDateTime(credential.createdAt!) 
                : null),
            _buildInfoRow('Última Actualización', credential.updatedAt != null 
                ? _formatDateTime(credential.updatedAt!) 
                : null),
            _buildInfoRow('ID de Usuario', credential.userId?.toString()),
            _buildInfoRow('ID de Credencial', credential.id?.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'No disponible',
              style: TextStyle(
                color: value != null ? Colors.black87 : Colors.grey[400],
                fontStyle: value != null ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showImageDialog(BuildContext context, String imagePath, String label) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar la imagen',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Método para compartir la información de la credencial
  void _shareCredentialInfo(CredentialModel credential) async {
    try {
      // Construir el texto con la información de la credencial
      final StringBuffer info = StringBuffer();
      info.writeln('=== INFORMACIÓN DE CREDENCIAL ===\n');
      
      // Información básica
      info.writeln('📋 DATOS GENERALES:');
      info.writeln('• Nombre: ${credential.nombre?.isNotEmpty == true ? credential.nombre : "No disponible"}');
      info.writeln('• CURP: ${credential.curp?.isNotEmpty == true ? credential.curp : "No disponible"}');
      info.writeln('• Clave de Elector: ${credential.claveElector?.isNotEmpty == true ? credential.claveElector : "No disponible"}');
      info.writeln('• Fecha de Nacimiento: ${credential.fechaNacimiento?.isNotEmpty == true ? credential.fechaNacimiento : "No disponible"}');
      info.writeln('• Sexo: ${credential.sexo?.isNotEmpty == true ? credential.sexo : "No disponible"}');
      info.writeln('• Domicilio: ${credential.domicilio?.isNotEmpty == true ? credential.domicilio : "No disponible"}');
      info.writeln('• Año de Registro: ${credential.anoRegistro?.isNotEmpty == true ? credential.anoRegistro : "No disponible"}');
      info.writeln('• Sección: ${credential.seccion?.isNotEmpty == true ? credential.seccion : "No disponible"}');
      info.writeln('• Vigencia: ${credential.vigencia?.isNotEmpty == true ? credential.vigencia : "No disponible"}');
      info.writeln('• Tipo: ${credential.tipo?.isNotEmpty == true ? credential.tipo!.toUpperCase() : "No disponible"}');
      info.writeln('• Lado: ${credential.lado?.isNotEmpty == true ? credential.lado : "No detectado"}\n');
      
      // Información específica para T2 y T3
      if (credential.tipo == 't2' || credential.tipo == 't3') {
        info.writeln('📍 DATOS DE UBICACIÓN:');
        info.writeln('• Estado: ${credential.estado?.isNotEmpty == true ? credential.estado : "No disponible"}');
        info.writeln('• Municipio: ${credential.municipio?.isNotEmpty == true ? credential.municipio : "No disponible"}');
        info.writeln('• Localidad: ${credential.localidad?.isNotEmpty == true ? credential.localidad : "No disponible"}\n');
        
        // Información de códigos
        if (credential.qrContent?.isNotEmpty == true) {
          info.writeln('🔲 CÓDIGO QR:');
          info.writeln('${credential.qrContent}\n');
        }
        
        if (credential.barcodeContent?.isNotEmpty == true) {
          info.writeln('📊 CÓDIGO DE BARRAS:');
          info.writeln('${credential.barcodeContent}\n');
        }
        
        if (credential.mrzContent?.isNotEmpty == true) {
          info.writeln('📄 CÓDIGO MRZ:');
          info.writeln('${credential.mrzContent}\n');
        }
      }
      
      // Información de imágenes extraídas
      info.writeln('🖼️ IMÁGENES EXTRAÍDAS:');
      if (credential.photoPath?.isNotEmpty == true) {
        info.writeln('• ✅ Fotografía del rostro');
      }
      if (credential.signaturePath?.isNotEmpty == true) {
        info.writeln('• ✅ Firma');
      }
      if (credential.qrImagePath?.isNotEmpty == true) {
        info.writeln('• ✅ Imagen del código QR');
      }
      if (credential.barcodeImagePath?.isNotEmpty == true) {
        info.writeln('• ✅ Imagen del código de barras');
      }
      
      // Información de metadatos
      info.writeln('\n📅 METADATOS:');
      info.writeln('• Fecha de captura: ${credential.fechaCaptura?.toString().split('.')[0] ?? "No disponible"}');
      if (credential.createdAt != null) {
        info.writeln('• Fecha de creación: ${credential.createdAt!.toString().split('.')[0]}');
      }
      if (credential.updatedAt != null) {
        info.writeln('• Última actualización: ${credential.updatedAt!.toString().split('.')[0]}');
      }
      info.writeln('• ID de credencial: ${credential.id ?? "No disponible"}');
      
      info.writeln('\n📱 Procesado con ATOM OCR AI M v3');
      info.writeln('⏰ ${DateTime.now().toString().split('.')[0]}');
      
      // Preparar lista de archivos para compartir
      final List<String> filesToShare = [];
      
      // Agregar imágenes extraídas disponibles
      if (credential.photoPath?.isNotEmpty == true && File(credential.photoPath!).existsSync()) {
        filesToShare.add(credential.photoPath!);
      }
      if (credential.signaturePath?.isNotEmpty == true && File(credential.signaturePath!).existsSync()) {
        filesToShare.add(credential.signaturePath!);
      }
      if (credential.qrImagePath?.isNotEmpty == true && File(credential.qrImagePath!).existsSync()) {
        filesToShare.add(credential.qrImagePath!);
      }
      if (credential.barcodeImagePath?.isNotEmpty == true && File(credential.barcodeImagePath!).existsSync()) {
        filesToShare.add(credential.barcodeImagePath!);
      }
      if (credential.mrzImagePath?.isNotEmpty == true && File(credential.mrzImagePath!).existsSync()) {
        filesToShare.add(credential.mrzImagePath!);
      }
      if (credential.signatureHuellaImagePath?.isNotEmpty == true && File(credential.signatureHuellaImagePath!).existsSync()) {
        filesToShare.add(credential.signatureHuellaImagePath!);
      }
      
      // Compartir información de la credencial
      String shareText = info.toString();
      
      if (filesToShare.isNotEmpty) {
        shareText += '\n\n📎 ARCHIVOS ADJUNTOS:';
        shareText += '\n• ${filesToShare.length} imagen(es) extraída(s) de la credencial';
        
        // Crear archivo temporal con el texto para incluirlo junto con las imágenes
        final tempDir = await getTemporaryDirectory();
        final textFile = File('${tempDir.path}/credential_info_${DateTime.now().millisecondsSinceEpoch}.txt');
        await textFile.writeAsString(shareText);
        
        // Agregar el archivo de texto a la lista de archivos
        List<XFile> allFiles = [XFile(textFile.path)];
        allFiles.addAll(filesToShare.map((path) => XFile(path)));
        
        // Compartir todo junto en un solo correo
        await Share.shareXFiles(
          allFiles,
          subject: 'Información de Credencial',
        );
        
        // Limpiar archivo temporal después de un delay
        Future.delayed(const Duration(seconds: 5), () {
          if (textFile.existsSync()) {
            textFile.deleteSync();
          }
        });
      } else {
        // Si no hay imágenes, compartir solo el texto
        await Share.share(
          shareText,
          subject: 'Información de Credencial',
        );
      }
      
    } catch (e) {
      // Mostrar error si falla el compartir
      Get.snackbar(
        'Error',
        'No se pudo compartir la información: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showDeleteDialog(BuildContext context, CredentialDetailsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta credencial? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteCredential();
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
}