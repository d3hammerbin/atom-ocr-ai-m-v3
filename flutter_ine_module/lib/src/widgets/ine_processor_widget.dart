import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ine_processor_service.dart';
import '../models/processing_result.dart';
import '../models/credencial_ine_model.dart';

/// Widget principal que maneja la comunicación con React Native
/// Implementa MethodChannel para recibir comandos desde RN
class IneProcessorWidget extends StatefulWidget {
  const IneProcessorWidget({Key? key}) : super(key: key);

  @override
  State<IneProcessorWidget> createState() => _IneProcessorWidgetState();
}

class _IneProcessorWidgetState extends State<IneProcessorWidget> {
  static const MethodChannel _channel = MethodChannel('ine_processor_module');
  
  ProcessingResult? _lastResult;
  bool _isProcessing = false;
  String _statusMessage = 'Listo para procesar credenciales';
  
  @override
  void initState() {
    super.initState();
    _setupMethodChannel();
    _initializeService();
  }
  
  /// Configura el MethodChannel para recibir llamadas desde React Native
  void _setupMethodChannel() {
    _channel.setMethodCallHandler((MethodCall call) async {
      try {
        switch (call.method) {
          case 'processCredential':
            return await _handleProcessCredential(call.arguments);
          case 'getLastResult':
            return _getLastResultAsMap();
          case 'getStatus':
            return {
              'isProcessing': _isProcessing,
              'statusMessage': _statusMessage,
              'hasResult': _lastResult != null,
            };
          case 'initialize':
            return await _handleInitialize();
          case 'dispose':
            return await _handleDispose();
          default:
            throw PlatformException(
              code: 'UNIMPLEMENTED',
              message: 'Método ${call.method} no implementado',
            );
        }
      } catch (e) {
        throw PlatformException(
          code: 'ERROR',
          message: 'Error procesando método ${call.method}: $e',
        );
      }
    });
  }
  
  /// Inicializa el servicio de procesamiento
  Future<void> _initializeService() async {
    try {
      await IneProcessorService.initialize();
      setState(() {
        _statusMessage = 'Servicio inicializado correctamente';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error inicializando servicio: $e';
      });
    }
  }
  
  /// Maneja la inicialización desde React Native
  Future<Map<String, dynamic>> _handleInitialize() async {
    try {
      await IneProcessorService.initialize();
      setState(() {
        _statusMessage = 'Servicio inicializado desde RN';
      });
      return {
        'success': true,
        'message': 'Servicio inicializado correctamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inicializando servicio: $e',
      };
    }
  }
  
  /// Maneja el procesamiento de credenciales desde React Native
  Future<Map<String, dynamic>> _handleProcessCredential(dynamic arguments) async {
    if (arguments == null || arguments is! Map) {
      throw PlatformException(
        code: 'INVALID_ARGUMENTS',
        message: 'Argumentos inválidos para processCredential',
      );
    }
    
    final args = Map<String, dynamic>.from(arguments);
    final imagePath = args['imagePath'] as String?;
    
    if (imagePath == null || imagePath.isEmpty) {
      throw PlatformException(
        code: 'MISSING_IMAGE_PATH',
        message: 'La ruta de la imagen es requerida',
      );
    }
    
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Procesando credencial...';
    });
    
    try {
      // Crear opciones de procesamiento desde los argumentos
      final options = ProcessingOptions(
        extractPhoto: args['extractPhoto'] ?? true,
        extractSignature: args['extractSignature'] ?? true,
        performOCR: args['performOCR'] ?? true,
        detectQRCodes: args['detectQRCodes'] ?? true,
        detectBarcodes: args['detectBarcodes'] ?? true,
        validateData: args['validateData'] ?? true,
        outputDirectory: args['outputDirectory'],
      );
      
      // Procesar la credencial
      final result = await IneProcessorService.processCredentialImage(
        imagePath,
        options: options,
      );
      
      setState(() {
        _lastResult = result;
        _isProcessing = false;
        _statusMessage = result.success 
            ? 'Credencial procesada exitosamente'
            : 'Error procesando credencial: ${result.message}';
      });
      
      return _convertResultToMap(result);
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error procesando credencial: $e';
      });
      
      final errorResult = ProcessingResult.error(
        message: 'Error procesando credencial: $e',
        errorCode: 'PROCESSING_EXCEPTION',
      );
      
      _lastResult = errorResult;
      return _convertResultToMap(errorResult);
    }
  }
  
  /// Maneja la liberación de recursos
  Future<Map<String, dynamic>> _handleDispose() async {
    try {
      await IneProcessorService.dispose();
      setState(() {
        _statusMessage = 'Recursos liberados';
        _lastResult = null;
      });
      return {
        'success': true,
        'message': 'Recursos liberados correctamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error liberando recursos: $e',
      };
    }
  }
  
  /// Convierte ProcessingResult a Map para enviar a React Native
  Map<String, dynamic> _convertResultToMap(ProcessingResult result) {
    return {
      'success': result.success,
      'message': result.message,
      'errorCode': result.errorCode,
      'data': result.data?.toJson(),
      'metadata': result.metadata,
      'timestamp': result.timestamp.toIso8601String(),
    };
  }
  
  /// Obtiene el último resultado como Map
  Map<String, dynamic>? _getLastResultAsMap() {
    return _lastResult != null ? _convertResultToMap(_lastResult!) : null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('INE Processor Module'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado del servicio
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del Servicio',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isProcessing ? Icons.hourglass_empty : Icons.check_circle,
                          color: _isProcessing ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Último resultado
            if (_lastResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Último Resultado',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _lastResult!.success ? Icons.check_circle : Icons.error,
                            color: _lastResult!.success ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastResult!.message ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      if (_lastResult!.data != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Datos Extraídos:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _buildCredentialDataWidget(_lastResult!.data!),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay resultados disponibles',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Procesa una credencial desde React Native para ver los resultados aquí',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const Spacer(),
            
            // Información del módulo
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Módulo Flutter para React Native',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Procesamiento de credenciales INE mediante Add-to-App',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construye el widget para mostrar los datos de la credencial
  Widget _buildCredentialDataWidget(CredencialIneModel credential) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (credential.nombre?.isNotEmpty ?? false)
          _buildDataRow('Nombre', credential.nombre!),
        if (credential.claveElector?.isNotEmpty ?? false)
          _buildDataRow('Clave de Elector', credential.claveElector!),
        if (credential.curp?.isNotEmpty ?? false)
          _buildDataRow('CURP', credential.curp!),
        if (credential.tipoCredencial?.isNotEmpty ?? false)
          _buildDataRow('Tipo', credential.tipoCredencial!),
        if (credential.ladoCredencial?.isNotEmpty ?? false)
          _buildDataRow('Lado', credential.ladoCredencial!),
        if (credential.vigencia?.isNotEmpty ?? false)
          _buildDataRow('Vigencia', credential.vigencia!),
      ],
    );
  }
  
  /// Construye una fila de datos
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
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
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    // Liberar recursos si es necesario
    super.dispose();
  }
}