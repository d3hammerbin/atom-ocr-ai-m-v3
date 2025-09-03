/// Ejemplo de uso de los algoritmos de similitud de cadenas
/// para manejar variantes de texto OCR en credenciales INE

import '../utils/string_similarity_utils.dart';

void main() {
  // Ejemplo 1: Variantes comunes de "VIGENCIA"
  print('=== Ejemplo 1: Detección de variantes de VIGENCIA ===');
  final vigenciaVariants = ['VIGENCIA', 'IGENCIA', 'VIGEN', 'GENCIA', 'VIGENT'];
  final ocrTexts = ['IGENCIA', 'VIGEN', 'VIGENC', 'GENCIA'];
  
  for (final ocrText in ocrTexts) {
    final result = StringSimilarityUtils.findBestMatch(
      ocrText,
      vigenciaVariants,
      threshold: 0.6,
    );
    
    print('OCR: "$ocrText" -> Mejor coincidencia: "${result['match']}" (${(result['score'] * 100).toStringAsFixed(1)}%)');
  }
  
  print('\n=== Ejemplo 2: Comparación de algoritmos ===');
  final target = 'VIGENCIA';
  final variants = ['IGENCIA', 'VIGEN', 'VIGENT', 'GENCIA'];
  
  for (final variant in variants) {
    final levenshtein = StringSimilarityUtils.levenshteinSimilarity(target, variant);
    final jaroWinkler = StringSimilarityUtils.jaroWinklerSimilarity(target, variant);
    
    print('"$target" vs "$variant":');
    print('  Levenshtein: ${(levenshtein * 100).toStringAsFixed(1)}%');
    print('  Jaro-Winkler: ${(jaroWinkler * 100).toStringAsFixed(1)}%');
    print('');
  }
  
  print('=== Ejemplo 3: Detección en texto OCR simulado ===');
  final simulatedOcrLines = [
    'INSTITUTO NACIONAL ELECTORAL',
    'CREDENCIAL PARA VOTAR',
    'JUAN PÉREZ GARCÍA',
    'IGENCIA 15/03/2030', // "VIGENCIA" con error OCR
    'CLAVE DE ELECTOR: PRGJN85031512H400',
    'CURP: PEGJ850315HDFRZN09',
  ];
  
  final vigenciaLabels = ['VIGENCIA', 'VIGENC', 'VIGEN', 'IGENCIA', 'GENCIA'];
  
  for (int i = 0; i < simulatedOcrLines.length; i++) {
    final line = simulatedOcrLines[i];
    final words = line.split(' ');
    
    for (final word in words) {
      final result = StringSimilarityUtils.findBestMatch(
        word,
        vigenciaLabels,
        threshold: 0.6,
      );
      
      if (result['found'] == true) {
        print('Línea $i: "$line"');
        print('Detectado: "$word" -> "${result['match']}" (${(result['score'] * 100).toStringAsFixed(1)}%)');
        
        // Extraer fecha de la misma línea
        final datePattern = RegExp(r'\b(\d{2}/\d{2}/\d{4})\b');
        final dateMatch = datePattern.firstMatch(line);
        if (dateMatch != null) {
          print('Fecha extraída: ${dateMatch.group(0)}');
        }
        print('');
      }
    }
  }
  
  print('=== Ejemplo 4: Múltiples coincidencias ===');
  final nameVariants = ['NOMBRE', 'NOMERE', 'NOMBE', 'OMBRE'];
  final testText = 'NOMERE';
  
  final allMatches = StringSimilarityUtils.findAllMatches(
    testText,
    nameVariants,
    threshold: 0.5,
  );
  
  print('Texto OCR: "$testText"');
  print('Todas las coincidencias encontradas:');
  for (final match in allMatches) {
    print('  "${match['match']}" - ${(match['score'] * 100).toStringAsFixed(1)}%');
  }
}

/// Función de utilidad para probar diferentes umbrales
void testThresholds() {
  print('\n=== Prueba de umbrales ===');
  final target = 'VIGENCIA';
  final variant = 'IGENCIA';
  final thresholds = [0.5, 0.6, 0.7, 0.8, 0.9];
  
  final similarity = StringSimilarityUtils.jaroWinklerSimilarity(target, variant);
  print('Similitud entre "$target" y "$variant": ${(similarity * 100).toStringAsFixed(1)}%');
  
  for (final threshold in thresholds) {
    final result = StringSimilarityUtils.findBestMatch(
      variant,
      [target],
      threshold: threshold,
    );
    
    final status = result['found'] == true ? '✓ DETECTADO' : '✗ NO DETECTADO';
    print('Umbral ${(threshold * 100).toInt()}%: $status');
  }
}

/// Recomendaciones de umbrales para diferentes tipos de etiquetas
void showThresholdRecommendations() {
  print('\n=== Recomendaciones de umbrales ===');
  print('VIGENCIA: 0.6 (errores comunes: IGENCIA, VIGEN, GENCIA)');
  print('NOMBRE: 0.7 (errores comunes: NOMERE, NOMBE)');
  print('DOMICILIO: 0.7 (errores comunes: DOMICILO, DOMCILIO)');
  print('CLAVE DE ELECTOR: 0.8 (más estricto para evitar falsos positivos)');
  print('CURP: 0.8 (más estricto para evitar falsos positivos)');
  print('\nNota: Umbrales más bajos (0.5-0.6) permiten más variaciones pero pueden generar falsos positivos.');
  print('Umbrales más altos (0.8-0.9) son más estrictos pero pueden perder variaciones válidas.');
}