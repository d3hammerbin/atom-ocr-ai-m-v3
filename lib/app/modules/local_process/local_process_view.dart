import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'local_process_controller.dart';
import '../../core/utils/validation_utils.dart';

class LocalProcessView extends GetView<LocalProcessController> {
  const LocalProcessView({super.key});

  Widget _buildCredentialField(String label, String? value, {bool? isValid}) {
    // Determinar el icono y color basado en la validación
    Widget? validationIcon;
    Color? textColor;
    
    if (value?.isNotEmpty == true && isValid != null) {
      if (isValid) {
        validationIcon = Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 16,
        );
        textColor = Colors.green.shade700;
      } else {
        validationIcon = Icon(
          Icons.cancel,
          color: Colors.red,
          size: 16,
        );
        textColor = Colors.red.shade700;
      }
    }
    
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
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    value?.isNotEmpty == true ? value! : 'No disponible',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor ?? (value?.isNotEmpty == true 
                          ? null 
                          : Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6)),
                      fontStyle: value?.isNotEmpty == true 
                          ? FontStyle.normal 
                          : FontStyle.italic,
                    ),
                  ),
                ),
                if (validationIcon != null) ...[
                  const SizedBox(width: 8),
                  validationIcon,
                ],
              ],
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
                          
                          // Debug: Verificar valores del QR
                          print('DEBUG LocalProcessView - QR Info:');
                          print('  tipo: ${credential.tipo}');
                          print('  lado: ${credential.lado}');
                          print('  qrImagePath: ${credential.qrImagePath}');
                          print('  qrContent: ${credential.qrContent}');
                          
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
                                // Indicador de estado de aceptabilidad
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12.0),
                                  margin: const EdgeInsets.only(bottom: 16.0),
                                  decoration: BoxDecoration(
                                    color: credential.isAcceptable 
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: credential.isAcceptable 
                                          ? Colors.green
                                          : Colors.orange,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        credential.isAcceptable 
                                            ? Icons.check_circle
                                            : Icons.warning,
                                        color: credential.isAcceptable 
                                            ? Colors.green
                                            : Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          credential.isAcceptable
                                              ? 'Credencial aceptable - Todos los campos requeridos están presentes'
                                              : 'Credencial incompleta - Faltan campos requeridos o se necesita nueva foto',
                                          style: TextStyle(
                                            color: credential.isAcceptable 
                                                ? Colors.green.shade700
                                                : Colors.orange.shade700,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildCredentialField('Nombre', credential.nombre, 
                                  isValid: credential.nombre.isNotEmpty ? ValidationUtils.isValidName(credential.nombre) : null),
                                _buildCredentialField('CURP', credential.curp,
                                  isValid: credential.curp.isNotEmpty ? ValidationUtils.isValidCurpFormat(credential.curp) : null),
                                _buildCredentialField('Clave de Elector', credential.claveElector, isValid: ValidationUtils.isValidClaveElector(credential.claveElector)),
                                _buildCredentialField('Fecha de Nacimiento', credential.fechaNacimiento,
                                  isValid: credential.fechaNacimiento.isNotEmpty ? ValidationUtils.isValidBirthDate(credential.fechaNacimiento) : null),
                                _buildCredentialField('Sexo', credential.sexo,
                                  isValid: credential.sexo.isNotEmpty ? ValidationUtils.isValidSex(credential.sexo) : null),
                                _buildCredentialField('Domicilio', credential.domicilio),
                                _buildCredentialField('Año de Registro', credential.anoRegistro,
                                  isValid: credential.anoRegistro.isNotEmpty ? ValidationUtils.isValidRegistrationYear(credential.anoRegistro) : null),
                                _buildCredentialField('Sección', credential.seccion,
                                  isValid: credential.seccion.isNotEmpty ? ValidationUtils.isValidSection(credential.seccion) : null),
                                _buildCredentialField('Vigencia', credential.vigencia,
                                  isValid: credential.vigencia.isNotEmpty ? ValidationUtils.isValidVigencia(credential.vigencia) : null),
                                _buildCredentialField('Tipo', credential.tipo),
                                _buildCredentialField('Lado', credential.lado.isNotEmpty ? credential.lado : 'No detectado'),
                                // Campos específicos para credenciales t2 y t3
                                if (credential.tipo == 't2') ...[
                                  _buildCredentialField('Estado', credential.estado,
                                    isValid: credential.estado.isNotEmpty ? ValidationUtils.isValidState(credential.estado) : null),
                                  _buildCredentialField('Municipio', credential.municipio,
                                    isValid: credential.municipio.isNotEmpty ? ValidationUtils.isValidMunicipality(credential.municipio) : null),
                                  _buildCredentialField('Localidad', credential.localidad,
                                    isValid: credential.localidad.isNotEmpty ? ValidationUtils.isValidLocality(credential.localidad) : null),
                                ],
                                
                                // Sección de fotografía del rostro extraída
                                if (credential.photoPath.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.face,
                                              color: Colors.blue.shade700,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Fotografía del Rostro Extraída',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Center(
                                          child: Container(
                                            width: 150,
                                            height: 150,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: Image.file(
                                                File(credential.photoPath),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    alignment: Alignment.center,
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.broken_image,
                                                          size: 32,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        const Text(
                                                          'Error al cargar',
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Center(
                                          child: Text(
                                            'Rostro detectado y extraído automáticamente',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // Sección de código QR extraído (para credenciales T2 traseras - mostrar imagen aunque no tenga contenido)
                                if (credential.tipo == 't2' && credential.lado == 'reverso' && credential.qrImagePath.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.purple.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.qr_code,
                                              color: Colors.purple.shade700,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Código QR Extraído (T2 Trasero)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Imagen del QR
                                            Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.file(
                                                  File(credential.qrImagePath),
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      alignment: Alignment.center,
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            Icons.broken_image,
                                                            size: 24,
                                                            color: Colors.grey,
                                                          ),
                                                          const SizedBox(height: 4),
                                                          const Text(
                                                            'Error al cargar',
                                                            style: TextStyle(
                                                              color: Colors.grey,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Contenido del QR
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Contenido del QR:',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                      color: Colors.purple.shade700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets.all(12.0),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade50,
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: Colors.grey.shade300,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      credential.qrContent.isNotEmpty 
                                                          ? credential.qrContent
                                                          : 'No se pudo decodificar el contenido',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontFamily: 'monospace',
                                                        color: credential.qrContent.isNotEmpty 
                                                            ? Colors.black87
                                                            : Colors.grey.shade600,
                                                      ),
                                                      maxLines: 6,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Center(
                                          child: Text(
                                            credential.qrContent.isNotEmpty 
                                                ? 'QR detectado y extraído automáticamente del lado trasero'
                                                : 'Región QR extraída del lado trasero (sin contenido decodificado)',
                                            style: TextStyle(
                                              color: Colors.purple.shade700,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // Sección de firma extraída (solo para credenciales T3)
                                if (credential.tipo == 't3' && credential.signaturePath.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.draw,
                                              color: Colors.green.shade700,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Firma Extraída (T3)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Center(
                                          child: Container(
                                            width: 200,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: Image.file(
                                                File(credential.signaturePath),
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    alignment: Alignment.center,
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.broken_image,
                                                          size: 32,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        const Text(
                                                          'Error al cargar',
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Center(
                                          child: Text(
                                            'Firma detectada y extraída automáticamente',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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