import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

/// Página de información oculta del usuario y dispositivo
class HiddenInfoPage extends StatefulWidget {
  const HiddenInfoPage({super.key});

  @override
  State<HiddenInfoPage> createState() => _HiddenInfoPageState();
}

class _HiddenInfoPageState extends State<HiddenInfoPage> {
  final UserRepository _userRepository = Get.find<UserRepository>();
  
  UserModel? _currentUser;
  Map<String, dynamic> _deviceInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Cargar información del usuario actual
      final users = await _userRepository.getEnabledUsers();
      if (users.isNotEmpty) {
        _currentUser = users.first;
      }
      
      // Cargar información del dispositivo
      await _loadDeviceInfo();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt.toString(),
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'id': androidInfo.id,
          // 'androidId': androidInfo.androidId, // Removido por compatibilidad
          'board': androidInfo.board,
          'bootloader': androidInfo.bootloader,
          'display': androidInfo.display,
          'fingerprint': androidInfo.fingerprint,
          'hardware': androidInfo.hardware,
          'host': androidInfo.host,
          'product': androidInfo.product,
          'tags': androidInfo.tags,
          'type': androidInfo.type,
        };
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = {
          'platform': 'iOS',
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'model': iosInfo.model,
          'localizedModel': iosInfo.localizedModel,
          'identifierForVendor': iosInfo.identifierForVendor,
          'isPhysicalDevice': iosInfo.isPhysicalDevice.toString(),
        };
      }
    } catch (e) {
      _deviceInfo = {'error': 'No se pudo obtener información del dispositivo'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Sistema'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfoSection(),
                  const SizedBox(height: 24),
                  _buildDeviceInfoSection(),
                  const SizedBox(height: 24),
                  _buildAppInfoSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Información del Usuario',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (_currentUser != null) ...[
              _buildInfoRow('ID de Usuario', _currentUser!.id.toString()),
              _buildInfoRow('Identificador', _currentUser!.identifier),
              _buildInfoRow('Fecha de Creación', _formatDateTime(_currentUser!.createdAt)),
              if (_currentUser!.updatedAt != null)
                _buildInfoRow('Última Actualización', _formatDateTime(_currentUser!.updatedAt)),
              if (_currentUser!.lastLoginAt != null)
                _buildInfoRow('Último Acceso', _formatDateTime(_currentUser!.lastLoginAt)),
            ] else ...[
              const Text('No hay usuario activo'),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Información del Dispositivo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ..._deviceInfo.entries.map((entry) => 
              _buildInfoRow(_formatKey(entry.key), entry.value.toString())
            ),
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
                Icon(Icons.apps, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Información de la Aplicación',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatKey(String key) {
    return key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim().split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  bool _isDebugMode() {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
}