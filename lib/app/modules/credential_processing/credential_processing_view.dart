import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atom_ocr_ai_m_v3/app/modules/credential_processing/credential_processing_controller.dart';
import 'package:atom_ocr_ai_m_v3/app/core/utils/validation_utils.dart';

class CredentialProcessingView extends GetView<CredentialProcessingController> {
  const CredentialProcessingView({super.key});

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
        title: const Text('Procesamiento de Credencial'),
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
              // Contenedor para imagen frontal
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.credit_card,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Imagen Frontal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.frontImagePath.value.isNotEmpty) {
                          return Container(
                            width: double.infinity,
                            height: 200,
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
                                File(controller.frontImagePath.value),
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
                                          'Error al cargar imagen frontal',
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
                          );
                        } else {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                              color: Colors.grey.shade50,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No hay imagen frontal',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Contenedor para imagen trasera
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Imagen Trasera',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.backImagePath.value.isNotEmpty) {
                          return Container(
                            width: double.infinity,
                            height: 200,
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
                                File(controller.backImagePath.value),
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
                                          'Error al cargar imagen trasera',
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
                          );
                        } else {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                              color: Colors.grey.shade50,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No hay imagen trasera',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.retakePhotos,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Volver a Tomar'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => ElevatedButton.icon(
                      onPressed: controller.isProcessing.value ? null : controller.processCredential,
                      icon: controller.isProcessing.value 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_fix_high),
                      label: Text(controller.isProcessing.value ? 'Procesando...' : 'Procesar'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )),
                  ),
                ],
              ),
              
              // Área de credencial procesada
              const SizedBox(height: 20),
              Obx(() {
                if (controller.processedCredential.value != null) {
                  final credential = controller.processedCredential.value!;
                  
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado
                          Row(
                            children: [
                              Icon(
                                Icons.verified_user,
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
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Indicador de estado de aceptabilidad
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            margin: const EdgeInsets.only(bottom: 16.0),
                            decoration: BoxDecoration(
                              color: credential.nombre.isNotEmpty && credential.curp.isNotEmpty
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: credential.nombre.isNotEmpty && credential.curp.isNotEmpty
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  credential.nombre.isNotEmpty && credential.curp.isNotEmpty
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: credential.nombre.isNotEmpty && credential.curp.isNotEmpty
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    credential.nombre.isNotEmpty && credential.curp.isNotEmpty
                                        ? 'Credencial procesada correctamente'
                                        : 'Credencial procesada con datos incompletos',
                                    style: TextStyle(
                                      color: credential.nombre.isNotEmpty && credential.curp.isNotEmpty
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
                          
                          // Campos de datos
                          _buildCredentialField('Nombre', credential.nombre, 
                            isValid: credential.nombre.isNotEmpty ? ValidationUtils.isValidName(credential.nombre) : null),
                          _buildCredentialField('CURP', credential.curp,
                            isValid: credential.curp.isNotEmpty ? ValidationUtils.isValidCurpFormat(credential.curp) : null),
                          _buildCredentialField('Clave de Elector', credential.claveElector, 
                            isValid: ValidationUtils.isValidClaveElector(credential.claveElector)),
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
                          if (credential.tipo == 't2' || credential.tipo == 't3') ...[
                            _buildCredentialField('Estado', credential.estado,
                              isValid: credential.estado.isNotEmpty ? ValidationUtils.isValidState(credential.estado) : null),
                            _buildCredentialField('Municipio', credential.municipio,
                              isValid: credential.municipio.isNotEmpty ? ValidationUtils.isValidMunicipality(credential.municipio) : null),
                            _buildCredentialField('Localidad', credential.localidad,
                              isValid: credential.localidad.isNotEmpty ? ValidationUtils.isValidLocality(credential.localidad) : null),
                            
                            // Contenido del QR (para credenciales T2 y T3)
                            if (credential.qrContent.isNotEmpty)
                              _buildCredentialField('Contenido QR', credential.qrContent),
                            
                            // Contenido del código de barras (para credenciales T2 y T3)
                            if (credential.barcodeContent.isNotEmpty)
                              _buildCredentialField('Contenido Código de Barras', credential.barcodeContent),
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
                                      width: 120,
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
                                              color: Colors.grey.shade200,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 30,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Error al cargar imagen',
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
                          
                          // Sección de MRZ extraído (para credenciales T2 y T3)
                          if ((credential.tipo == 't2' || credential.tipo == 't3') && credential.mrzContent.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.teal.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.text_fields,
                                        color: Colors.teal.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Código MRZ Extraído',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: SelectableText(
                                      credential.mrzContent,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // Sección de código QR extraído (para credenciales T2 y T3 traseras)
                          if ((credential.tipo == 't2' || credential.tipo == 't3') && credential.qrImagePath.isNotEmpty) ...[
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
                                        'Código QR Extraído',
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
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 30,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Error al cargar imagen',
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
                          
                          // Sección de código de barras extraído (para credenciales T2 y T3)
                          if ((credential.tipo == 't2' || credential.tipo == 't3') && credential.barcodeImagePath.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.view_stream,
                                        color: Colors.orange.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Código de Barras Extraído',
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
                                      height: 60,
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
                                          File(credential.barcodeImagePath),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Error al cargar imagen',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 8,
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
                                      credential.barcodeContent.isNotEmpty
                                          ? 'Código de barras detectado y extraído automáticamente de la esquina superior izquierda'
                                          : 'Región de código de barras extraída de la esquina superior izquierda (sin contenido decodificado)',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
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
                                        'Firma Extraída',
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
                                      height: 80,
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
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Error al cargar imagen',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 8,
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
                          
                          const SizedBox(height: 16),
                          
                          // Botón Guardar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Implementar guardado
                                Get.offAllNamed('/credentials-list');
                              },
                              icon: const Icon(Icons.save),
                              label: const Text('Guardar Credencial'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
}