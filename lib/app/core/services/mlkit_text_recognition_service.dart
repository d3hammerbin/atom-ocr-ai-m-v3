import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'logger_service.dart';

/// Servicio independiente para reconocimiento de texto usando Google ML Kit
class MLKitTextRecognitionService {
  static final _instance = MLKitTextRecognitionService._internal();
  factory MLKitTextRecognitionService() => _instance;
  MLKitTextRecognitionService._internal();

  // Instancia del reconocedor de texto
  TextRecognizer? _textRecognizer;
  
  // Logger service para registrar eventos
  final LoggerService _logger = LoggerService.instance;

  /// Obtiene la instancia del reconocedor de texto, inicializándola si es necesario
  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Inicializa el servicio ML Kit
  Future<void> initialize() async {
    try {
      // Forzar la inicialización del reconocedor
      _recognizer;
      _logger.info('MLKitTextRecognitionService', 'Servicio inicializado correctamente');
    } catch (e) {
      _logger.error('MLKitTextRecognitionService', 'Error al inicializar servicio: $e');
      rethrow;
    }
  }

  /// Extrae texto de una imagen usando ML Kit
  /// 
  /// [imagePath] - Ruta del archivo de imagen
  /// Retorna el texto extraído o null si hay error
  Future<String?> extractTextFromImage(String imagePath) async {
    try {
      _logger.info('MLKitTextRecognitionService', 'Iniciando extracción de texto desde: $imagePath');
      
      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        _logger.warning('MLKitTextRecognitionService', 'El archivo de imagen no existe: $imagePath');
        return null;
      }

      // Crear InputImage desde el archivo
      final inputImage = InputImage.fromFilePath(imagePath);
      
      // Procesar la imagen con ML Kit
      final RecognizedText recognizedText = await _recognizer.processImage(inputImage);
      
      // Extraer el texto completo
      final String extractedText = recognizedText.text;
      
      _logger.info('MLKitTextRecognitionService', 'Texto extraído exitosamente. Longitud: ${extractedText.length} caracteres');
      _logger.debug('MLKitTextRecognitionService', 'Texto extraído: $extractedText');
      
      return extractedText.isNotEmpty ? extractedText : null;
      
    } catch (e) {
      _logger.error('MLKitTextRecognitionService', 'Error al extraer texto de la imagen: $e');
      return null;
    }
  }

  /// Extrae texto detallado con información de bloques, líneas y elementos
  /// 
  /// [imagePath] - Ruta del archivo de imagen
  /// Retorna un mapa con información detallada del texto extraído
  Future<Map<String, dynamic>?> extractDetailedTextFromImage(String imagePath) async {
    try {
      _logger.info('MLKitTextRecognitionService', 'Iniciando extracción detallada de texto desde: $imagePath');
      
      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        _logger.warning('MLKitTextRecognitionService', 'El archivo de imagen no existe: $imagePath');
        return null;
      }

      // Crear InputImage desde el archivo
      final inputImage = InputImage.fromFilePath(imagePath);
      
      // Procesar la imagen con ML Kit
      final RecognizedText recognizedText = await _recognizer.processImage(inputImage);
      
      // Construir información detallada
      final Map<String, dynamic> detailedResult = {
        'fullText': recognizedText.text,
        'blocks': [],
        'totalBlocks': recognizedText.blocks.length,
        'extractedAt': DateTime.now().toIso8601String(),
      };

      // Procesar cada bloque de texto
      for (int i = 0; i < recognizedText.blocks.length; i++) {
        final TextBlock block = recognizedText.blocks[i];
        
        final Map<String, dynamic> blockInfo = {
          'blockIndex': i,
          'text': block.text,
          'boundingBox': {
            'left': block.boundingBox.left,
            'top': block.boundingBox.top,
            'right': block.boundingBox.right,
            'bottom': block.boundingBox.bottom,
          },
          'lines': [],
        };

        // Procesar líneas dentro del bloque
        for (int j = 0; j < block.lines.length; j++) {
          final TextLine line = block.lines[j];
          
          final Map<String, dynamic> lineInfo = {
            'lineIndex': j,
            'text': line.text,
            'boundingBox': {
              'left': line.boundingBox.left,
              'top': line.boundingBox.top,
              'right': line.boundingBox.right,
              'bottom': line.boundingBox.bottom,
            },
            'elements': line.elements.map((element) => {
              'text': element.text,
              'boundingBox': {
                'left': element.boundingBox.left,
                'top': element.boundingBox.top,
                'right': element.boundingBox.right,
                'bottom': element.boundingBox.bottom,
              },
            }).toList(),
          };
          
          blockInfo['lines'].add(lineInfo);
        }
        
        detailedResult['blocks'].add(blockInfo);
      }
      
      _logger.info('MLKitTextRecognitionService', 'Extracción detallada completada. Bloques encontrados: ${recognizedText.blocks.length}');
      
      return detailedResult;
      
    } catch (e) {
      _logger.error('MLKitTextRecognitionService', 'Error al extraer texto detallado de la imagen: $e');
      return null;
    }
  }

  /// Libera los recursos del servicio
  Future<void> dispose() async {
    try {
      if (_textRecognizer != null) {
        await _textRecognizer!.close();
        _textRecognizer = null;
      }
      _logger.info('MLKitTextRecognitionService', 'Recursos liberados correctamente');
    } catch (e) {
      _logger.error('MLKitTextRecognitionService', 'Error al liberar recursos: $e');
    }
  }

  /// Verifica si el servicio está disponible en la plataforma actual
  static bool isSupported() {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Obtiene información sobre las capacidades del servicio
  Map<String, dynamic> getServiceInfo() {
    return {
      'serviceName': 'MLKit Text Recognition Service',
      'version': '1.0.0',
      'supportedPlatforms': ['Android', 'iOS'],
      'currentPlatform': Platform.operatingSystem,
      'isSupported': isSupported(),
      'script': 'Latin',
      'features': [
        'Basic text extraction',
        'Detailed text analysis with bounding boxes',
        'Block, line, and element level recognition',
        'Automatic language detection for Latin scripts'
      ],
    };
  }
}