import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'processing_controller.dart';

class ProcessingView extends GetView<ProcessingController> {
  const ProcessingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: controller.cancelProcessing,
        ),
        title: const Text(
          'Procesando Credencial',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Preview de la imagen
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: controller.capturedImage != null
                        ? Image.file(
                            controller.capturedImage!,
                            fit: BoxFit.contain,
                          )
                        : const Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.white54,
                              size: 64,
                            ),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Estado de procesamiento
              Obx(() => controller.isProcessing.value
                  ? _buildProcessingIndicator()
                  : _buildResults()),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProcessingIndicator() {
    return Column(
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 16),
        Obx(() => Text(
          controller.processingStatus.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        )),
      ],
    );
  }
  
  Widget _buildResults() {
    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Extraída:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: SingleChildScrollView(
                child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: controller.credentialData.entries
                      .map((entry) => _buildDataRow(
                            _formatLabel(entry.key),
                            entry.value,
                          ))
                      .toList(),
                )),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.retryProcessing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reprocesar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.saveCredential,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Divider(color: Colors.white24, height: 16),
        ],
      ),
    );
  }
  
  String _formatLabel(String key) {
    switch (key) {
      case 'nombre':
        return 'NOMBRE COMPLETO';
      case 'curp':
        return 'CURP';
      case 'clave_elector':
        return 'CLAVE DE ELECTOR';
      case 'seccion':
        return 'SECCIÓN';
      case 'localidad':
        return 'LOCALIDAD';
      case 'municipio':
        return 'MUNICIPIO';
      case 'estado':
        return 'ESTADO';
      case 'vigencia':
        return 'VIGENCIA';
      case 'emision':
        return 'EMISIÓN';
      default:
        return key.toUpperCase();
    }
  }
}