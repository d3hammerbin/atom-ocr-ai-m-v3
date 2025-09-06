import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'device_controller.dart';
import '../../data/models/user_model.dart';
import '../../core/services/user_session_service.dart';

/// Página para mostrar información detallada del dispositivo
class DeviceInfoPage extends GetView<DeviceController> {
  const DeviceInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Dispositivo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshDeviceInfo(),
          ),
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
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refreshDeviceInfo(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        
        final device = controller.currentDevice.value;
        if (device == null) {
          return const Center(
            child: Text('No se pudo obtener información del dispositivo'),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoSection(),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Identificación',
                [
                  _buildInfoRow('Número de Serie', device.serialNumber ?? 'No disponible'),
                  _buildInfoRow('ID del Dispositivo', device.deviceId ?? 'No disponible'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Sistema Operativo',
                [
                  _buildInfoRow('Versión Android', device.androidVersion ?? 'Desconocida'),
                  _buildInfoRow('Nivel de API', device.sdkInt?.toString() ?? 'Desconocido'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Hardware',
                [
                  _buildInfoRow('Modelo', device.model ?? 'Desconocido'),
                  _buildInfoRow('Marca', device.brand ?? 'Desconocida'),
                  _buildInfoRow('Dispositivo de baja RAM', device.isLowRamDevice ? 'Sí' : 'No'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Arquitecturas Soportadas',
                [
                  _buildInfoRow('32 bits', device.supported32BitAbis ?? 'No disponible'),
                  _buildInfoRow('64 bits', device.supported64BitAbis ?? 'No disponible'),
                  _buildInfoRow('Todas', device.supportedAbis ?? 'No disponible'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Almacenamiento',
                [
                  _buildInfoRow('Espacio libre', _formatBytes(device.freeDiskSize)),
                  _buildInfoRow('Espacio total', _formatBytes(device.totalDiskSize)),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Memoria RAM',
                [
                  _buildInfoRow('RAM física', _formatBytes(device.physicalRamSize)),
                  _buildInfoRow('RAM disponible', _formatBytes(device.availableRamSize)),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Procesador (CPU)',
                [
                  _buildInfoRow('Tipo', device.cpuType ?? 'No disponible'),
                  _buildInfoRow('Núcleos', device.cpuCores?.toString() ?? 'No disponible'),
                  _buildInfoRow('Arquitectura', device.cpuArchitecture ?? 'No disponible'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Tarjeta Gráfica (GPU)',
                [
                  _buildInfoRow('Fabricante', device.gpuVendor ?? 'No disponible'),
                  _buildInfoRow('Modelo', device.gpuRenderer ?? 'No disponible'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Pantalla',
                [
                  _buildInfoRow('Ancho', device.screenWidth != null ? '${device.screenWidth!.toInt()} px' : 'No disponible'),
                  _buildInfoRow('Alto', device.screenHeight != null ? '${device.screenHeight!.toInt()} px' : 'No disponible'),
                  _buildInfoRow('Densidad', device.screenDensity != null ? '${device.screenDensity!.toStringAsFixed(2)} dpi' : 'No disponible'),
                  _buildInfoRow('Frecuencia', device.screenRefreshRate != null ? '${device.screenRefreshRate!.toStringAsFixed(1)} Hz' : 'No disponible'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Batería',
                [
                  _buildInfoRow('Nivel', device.batteryLevel != null ? '${device.batteryLevel}%' : 'No disponible'),
                  _buildInfoRow('Estado', device.batteryStatus ?? 'No disponible'),
                  _buildInfoRow('Salud', device.batteryHealth ?? 'No disponible'),
                  _buildInfoRow('Temperatura', device.batteryTemperature != null ? '${device.batteryTemperature}°C' : 'No disponible'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Sensores Disponibles',
                [
                  _buildSensorsInfo(device.availableSensors),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Información de Registro',
                [
                  _buildInfoRow('Fecha de registro', device.createdAt?.toString() ?? 'No disponible'),
                  _buildInfoRow('Última actualización', device.updatedAt?.toString() ?? 'No disponible'),
                ],
              ),
              const SizedBox(height: 16),
              _buildAppInfoSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildUserInfoSection() {
    final userSessionService = Get.find<UserSessionService>();
    final currentUser = userSessionService.currentUser;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Get.theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Información del Usuario',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (currentUser != null) ...[
              _buildInfoRow('ID de Usuario', currentUser.id.toString()),
              _buildInfoRow('Identificador', currentUser.identifier),
              _buildInfoRow('Fecha de Creación', _formatDateTime(currentUser.createdAt)),
              if (currentUser.updatedAt != null)
                _buildInfoRow('Última Actualización', _formatDateTime(currentUser.updatedAt)),
              if (currentUser.lastLoginAt != null)
                _buildInfoRow('Último Acceso', _formatDateTime(currentUser.lastLoginAt)),
            ] else ...[
              const Text('No hay usuario activo'),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.apps, color: Get.theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Información de la Aplicación',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Modo Debug', _isDebugMode().toString()),
            _buildInfoRow('Plataforma Flutter', Platform.operatingSystem),
            _buildInfoRow('Versión del SO', Platform.operatingSystemVersion),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorsInfo(String? sensorsJson) {
    if (sensorsJson == null || sensorsJson.isEmpty) {
      return const Text(
        'No hay sensores disponibles',
        style: TextStyle(
          fontWeight: FontWeight.w400,
          color: Colors.grey,
        ),
      );
    }

    try {
      final List<dynamic> sensors = json.decode(sensorsJson);
      if (sensors.isEmpty) {
        return const Text(
          'No hay sensores disponibles',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sensors.map<Widget>((sensor) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(
                  Icons.sensors,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sensor.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } catch (e) {
      return const Text(
        'Error al cargar sensores',
        style: TextStyle(
          fontWeight: FontWeight.w400,
          color: Colors.red,
        ),
      );
    }
  }
  
  String _formatBytes(int? bytes) {
    if (bytes == null) return 'No disponible';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  bool _isDebugMode() {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
}