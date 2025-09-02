import '../services/logger_service.dart';

/// Utilidad para determinar el lado de una credencial INE basado en etiquetas de texto
class CredentialSideDetector {
  static final LoggerService _logger = LoggerService.instance;

  /// Etiquetas que indican que es el lado frontal de la credencial
  static const List<String> _frontalLabels = [
    'NOMBRE',
    'DOMICILIO',
    'CREDENCIAL PARA VOTAR',
    'CLAVE DE ELECTOR',
    'CURP',
  ];

  /// Determina el lado de una credencial INE basado en la presencia de etiquetas específicas
  ///
  /// Reglas de detección:
  /// - Si contiene 1 o más etiquetas frontales: lado frontal
  /// - Si no contiene ninguna etiqueta frontal: lado reverso
  ///
  /// Retorna un Map con:
  /// - 'lado': 'frontal' o 'reverso'
  /// - 'tipo_detectado': 'detectado' o 'desconocido'
  /// - 'confianza': nivel de confianza de la detección (0.0 - 1.0)
  /// - 'detalles': información adicional sobre la detección
  static Map<String, dynamic> detectSide(String extractedText) {
    try {
      _logger.info(
        'CredentialSideDetector',
        'Iniciando detección de lado basada en texto',
      );

      // Convertir texto a mayúsculas para comparación
      final upperText = extractedText.toUpperCase();

      // Buscar etiquetas frontales en el texto
      final foundLabels = <String>[];
      for (final label in _frontalLabels) {
        if (upperText.contains(label)) {
          foundLabels.add(label);
        }
      }

      // Determinar el lado basado en las etiquetas encontradas
      final sideAnalysis = _analyzeSideFromLabels(foundLabels, upperText);

      _logger.info(
        'CredentialSideDetector',
        'Detección de lado completada: ${sideAnalysis['lado']} - Etiquetas encontradas: ${foundLabels.length}',
      );

      return sideAnalysis;
    } catch (e) {
      _logger.error('CredentialSideDetector', 'Error en detección de lado: $e');

      // Retornar resultado por defecto en caso de error
      return {
        'lado': 'frontal',
        'tipo_detectado': 'desconocido',
        'confianza': 0.0,
        'detalles': {
          'error': e.toString(),
          'metodo': 'fallback',
          'labels_found': 0,
        },
      };
    }
  }

  /// Analiza las etiquetas encontradas para determinar el lado de la credencial
  static Map<String, dynamic> _analyzeSideFromLabels(
    List<String> foundLabels,
    String upperText,
  ) {
    final labelCount = foundLabels.length;

    if (labelCount >= 2) {
      // Si se encontraron etiquetas frontales = lado frontal
      final confianza = _calculateFrontalConfidence(labelCount, foundLabels);
      return {
        'lado': 'frontal',
        'tipo_detectado': 'detectado',
        'confianza': confianza,
        'detalles': {
          'labels_found': labelCount,
          'found_labels': foundLabels,
          'razon': 'Etiquetas frontales detectadas: ${foundLabels.join(", ")}',
          'metodo': 'text_analysis',
        },
      };
    } else {
      // Si no se encontraron etiquetas frontales = lado reverso
      return {
        'lado': 'reverso',
        'tipo_detectado': 'detectado',
        'confianza':
            0.85, // Alta confianza para reverso sin etiquetas frontales
        'detalles': {
          'labels_found': 0,
          'found_labels': [],
          'razon': 'No se encontraron etiquetas frontales',
          'metodo': 'text_analysis',
        },
      };
    }
  }

  /// Calcula la confianza para detección frontal basado en las etiquetas encontradas
  static double _calculateFrontalConfidence(
    int labelCount,
    List<String> foundLabels,
  ) {
    // Confianza base según número de etiquetas encontradas
    double confianza = 0.7; // Base

    // Bonus por cada etiqueta adicional
    confianza += (labelCount - 1) * 0.1;

    // Bonus especial por etiquetas clave
    if (foundLabels.contains('INSTITUTO NACIONAL ELECTORAL')) {
      confianza += 0.1; // Etiqueta muy específica del frontal
    }

    if (foundLabels.contains('CREDENCIAL PARA VOTAR')) {
      confianza += 0.1; // Etiqueta muy específica del frontal
    }

    // Máxima confianza si se encuentran múltiples etiquetas clave
    if (labelCount >= 3) {
      confianza += 0.05; // Bonus por múltiples etiquetas
    }

    return confianza.clamp(0.0, 1.0);
  }

  /// Valida si el lado detectado es consistente con el tipo de credencial
  static bool isConsistentWithCredentialType(
    String detectedSide,
    String credentialType,
  ) {
    // Todos los tipos de credencial pueden tener lado frontal o reverso
    // La nueva lógica basada en texto es más confiable que la anterior basada en QR
    return detectedSide == 'frontal' || detectedSide == 'reverso';
  }
}
