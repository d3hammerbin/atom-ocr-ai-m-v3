import 'dart:math';

/// Utilidades para cálculo de similitud entre strings
/// Útil para comparar texto extraído con patrones esperados
class StringSimilarityUtils {
  /// Calcula la similitud de Jaro-Winkler entre dos strings
  static double jaroWinklerSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    final jaro = _jaroSimilarity(s1, s2);
    if (jaro < 0.7) return jaro;
    
    // Calcular prefijo común (máximo 4 caracteres)
    int prefix = 0;
    final maxPrefix = min(min(s1.length, s2.length), 4);
    
    for (int i = 0; i < maxPrefix; i++) {
      if (s1[i] == s2[i]) {
        prefix++;
      } else {
        break;
      }
    }
    
    return jaro + (0.1 * prefix * (1 - jaro));
  }
  
  /// Calcula la similitud de Jaro entre dos strings
  static double _jaroSimilarity(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;
    
    if (len1 == 0 && len2 == 0) return 1.0;
    if (len1 == 0 || len2 == 0) return 0.0;
    
    final matchWindow = (max(len1, len2) / 2 - 1).floor();
    if (matchWindow < 0) return 0.0;
    
    final s1Matches = List.filled(len1, false);
    final s2Matches = List.filled(len2, false);
    
    int matches = 0;
    int transpositions = 0;
    
    // Identificar matches
    for (int i = 0; i < len1; i++) {
      final start = max(0, i - matchWindow);
      final end = min(i + matchWindow + 1, len2);
      
      for (int j = start; j < end; j++) {
        if (s2Matches[j] || s1[i] != s2[j]) continue;
        
        s1Matches[i] = true;
        s2Matches[j] = true;
        matches++;
        break;
      }
    }
    
    if (matches == 0) return 0.0;
    
    // Calcular transposiciones
    int k = 0;
    for (int i = 0; i < len1; i++) {
      if (!s1Matches[i]) continue;
      
      while (!s2Matches[k]) {
        k++;
      }
      
      if (s1[i] != s2[k]) transpositions++;
      k++;
    }
    
    return (matches / len1 + matches / len2 + (matches - transpositions / 2) / matches) / 3.0;
  }
  
  /// Calcula la distancia de Levenshtein entre dos strings
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );
    
    // Inicializar primera fila y columna
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    // Llenar la matriz
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }
    
    return matrix[s1.length][s2.length];
  }
  
  /// Calcula la similitud basada en distancia de Levenshtein (0.0 a 1.0)
  static double levenshteinSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    final distance = levenshteinDistance(s1, s2);
    final maxLength = max(s1.length, s2.length);
    
    return 1.0 - (distance / maxLength);
  }
  
  /// Calcula la similitud de coseno entre dos strings
  static double cosineSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    final vector1 = _getCharacterVector(s1);
    final vector2 = _getCharacterVector(s2);
    
    return _calculateCosine(vector1, vector2);
  }
  
  /// Convierte un string en un vector de frecuencias de caracteres
  static Map<String, int> _getCharacterVector(String text) {
    final vector = <String, int>{};
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i].toLowerCase();
      vector[char] = (vector[char] ?? 0) + 1;
    }
    
    return vector;
  }
  
  /// Calcula la similitud de coseno entre dos vectores
  static double _calculateCosine(Map<String, int> vector1, Map<String, int> vector2) {
    final allKeys = {...vector1.keys, ...vector2.keys};
    
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (final key in allKeys) {
      final v1 = vector1[key] ?? 0;
      final v2 = vector2[key] ?? 0;
      
      dotProduct += v1 * v2;
      norm1 += v1 * v1;
      norm2 += v2 * v2;
    }
    
    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }
  
  /// Encuentra la mejor coincidencia de un texto en una lista de opciones
  static MatchResult findBestMatch(String target, List<String> options, {double threshold = 0.6}) {
    if (options.isEmpty) {
      return MatchResult(bestMatch: '', similarity: 0.0, index: -1);
    }
    
    double bestSimilarity = 0.0;
    String bestMatch = '';
    int bestIndex = -1;
    
    for (int i = 0; i < options.length; i++) {
      final similarity = jaroWinklerSimilarity(target.toLowerCase(), options[i].toLowerCase());
      
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestMatch = options[i];
        bestIndex = i;
      }
    }
    
    // Solo devolver resultado si supera el umbral
    if (bestSimilarity >= threshold) {
      return MatchResult(bestMatch: bestMatch, similarity: bestSimilarity, index: bestIndex);
    }
    
    return MatchResult(bestMatch: '', similarity: 0.0, index: -1);
  }
  
  /// Encuentra todas las coincidencias que superan un umbral
  static List<MatchResult> findAllMatches(String target, List<String> options, {double threshold = 0.6}) {
    final matches = <MatchResult>[];
    
    for (int i = 0; i < options.length; i++) {
      final similarity = jaroWinklerSimilarity(target.toLowerCase(), options[i].toLowerCase());
      
      if (similarity >= threshold) {
        matches.add(MatchResult(bestMatch: options[i], similarity: similarity, index: i));
      }
    }
    
    // Ordenar por similitud descendente
    matches.sort((a, b) => b.similarity.compareTo(a.similarity));
    
    return matches;
  }
  
  /// Calcula la similitud fonética usando Soundex
  static double soundexSimilarity(String s1, String s2) {
    final soundex1 = _soundex(s1);
    final soundex2 = _soundex(s2);
    
    return soundex1 == soundex2 ? 1.0 : 0.0;
  }
  
  /// Implementación básica del algoritmo Soundex
  static String _soundex(String text) {
    if (text.isEmpty) return '0000';
    
    final cleanText = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (cleanText.isEmpty) return '0000';
    
    final soundexMap = {
      'B': '1', 'F': '1', 'P': '1', 'V': '1',
      'C': '2', 'G': '2', 'J': '2', 'K': '2', 'Q': '2', 'S': '2', 'X': '2', 'Z': '2',
      'D': '3', 'T': '3',
      'L': '4',
      'M': '5', 'N': '5',
      'R': '6',
    };
    
    String result = cleanText[0];
    String previousCode = soundexMap[cleanText[0]] ?? '0';
    
    for (int i = 1; i < cleanText.length && result.length < 4; i++) {
      final char = cleanText[i];
      final code = soundexMap[char] ?? '0';
      
      if (code != '0' && code != previousCode) {
        result += code;
      }
      
      if (code != '0') {
        previousCode = code;
      }
    }
    
    // Rellenar con ceros si es necesario
    while (result.length < 4) {
      result += '0';
    }
    
    return result;
  }
  
  /// Normaliza un texto para comparación
  static String normalizeForComparison(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
  
  /// Calcula múltiples métricas de similitud
  static SimilarityMetrics calculateAllMetrics(String s1, String s2) {
    return SimilarityMetrics(
      jaroWinkler: jaroWinklerSimilarity(s1, s2),
      levenshtein: levenshteinSimilarity(s1, s2),
      cosine: cosineSimilarity(s1, s2),
      soundex: soundexSimilarity(s1, s2),
    );
  }
  
  /// Calcula una similitud promedio ponderada
  static double calculateWeightedSimilarity(String s1, String s2, {
    double jaroWinklerWeight = 0.4,
    double levenshteinWeight = 0.3,
    double cosineWeight = 0.2,
    double soundexWeight = 0.1,
  }) {
    final metrics = calculateAllMetrics(s1, s2);
    
    return (metrics.jaroWinkler * jaroWinklerWeight) +
           (metrics.levenshtein * levenshteinWeight) +
           (metrics.cosine * cosineWeight) +
           (metrics.soundex * soundexWeight);
  }
}

/// Resultado de una búsqueda de coincidencia
class MatchResult {
  final String bestMatch;
  final double similarity;
  final int index;
  
  const MatchResult({
    required this.bestMatch,
    required this.similarity,
    required this.index,
  });
  
  @override
  String toString() {
    return 'MatchResult(bestMatch: $bestMatch, similarity: ${similarity.toStringAsFixed(3)}, index: $index)';
  }
}

/// Métricas de similitud múltiples
class SimilarityMetrics {
  final double jaroWinkler;
  final double levenshtein;
  final double cosine;
  final double soundex;
  
  const SimilarityMetrics({
    required this.jaroWinkler,
    required this.levenshtein,
    required this.cosine,
    required this.soundex,
  });
  
  /// Calcula el promedio de todas las métricas
  double get average => (jaroWinkler + levenshtein + cosine + soundex) / 4.0;
  
  /// Calcula el máximo de todas las métricas
  double get maximum => [jaroWinkler, levenshtein, cosine, soundex].reduce(max);
  
  /// Calcula el mínimo de todas las métricas
  double get minimum => [jaroWinkler, levenshtein, cosine, soundex].reduce(min);
  
  @override
  String toString() {
    return 'SimilarityMetrics(jaroWinkler: ${jaroWinkler.toStringAsFixed(3)}, '
           'levenshtein: ${levenshtein.toStringAsFixed(3)}, '
           'cosine: ${cosine.toStringAsFixed(3)}, '
           'soundex: ${soundex.toStringAsFixed(3)})';
  }
}