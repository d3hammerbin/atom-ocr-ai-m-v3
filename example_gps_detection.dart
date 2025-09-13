import 'package:flutter/material.dart';
import 'lib/app/core/services/gps_location_service.dart';

/// Ejemplo de uso de la detección de hardware GPS
class GpsDetectionExample extends StatefulWidget {
  const GpsDetectionExample({super.key});

  @override
  GpsDetectionExampleState createState() => GpsDetectionExampleState();
}

class GpsDetectionExampleState extends State<GpsDetectionExample> {
  bool? _hasGpsHardware;
  Map<String, dynamic>? _locationCapabilities;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkGpsHardware();
  }

  /// Verifica si el dispositivo tiene hardware GPS
  Future<void> _checkGpsHardware() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasGps = await GpsLocationService.instance.hasGpsHardware();
      final capabilities = await GpsLocationService.instance.getLocationCapabilities();
      
      setState(() {
        _hasGpsHardware = hasGps;
        _locationCapabilities = capabilities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasGpsHardware = null;
        _locationCapabilities = null;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar GPS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detección de GPS Hardware'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del Hardware GPS',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    if (_isLoading)
                      Center(child: CircularProgressIndicator())
                    else if (_hasGpsHardware != null)
                      Row(
                        children: [
                          Icon(
                            _hasGpsHardware! ? Icons.gps_fixed : Icons.gps_off,
                            color: _hasGpsHardware! ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          SizedBox(width: 16),
                          Text(
                            _hasGpsHardware!
                                ? 'GPS Hardware Disponible'
                                : 'GPS Hardware No Disponible',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _hasGpsHardware! ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Error al verificar GPS',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_locationCapabilities != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capacidades de Ubicación',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),
                      _buildCapabilityRow(
                        'Hardware GPS',
                        _locationCapabilities!['hasGpsHardware'] ?? false,
                      ),
                      _buildCapabilityRow(
                        'Servicios Habilitados',
                        _locationCapabilities!['isServiceEnabled'] ?? false,
                      ),
                      _buildCapabilityRow(
                        'Puede Obtener Ubicación',
                        _locationCapabilities!['canGetLocation'] ?? false,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Estado de Permisos: ${_locationCapabilities!['permissionStatus']}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _checkGpsHardware,
                child: Text('Verificar Nuevamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}