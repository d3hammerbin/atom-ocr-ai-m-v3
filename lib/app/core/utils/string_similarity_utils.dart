/// Utilidades para calcular similitud entre cadenas de texto
/// Útil para manejar variantes de texto OCR con errores
class StringSimilarityUtils {
  /// Calcula la distancia de Levenshtein entre dos cadenas
  /// Retorna el número mínimo de operaciones (inserción, eliminación, sustitución)
  /// necesarias para transformar una cadena en otra
  static int levenshteinDistance(String s1, String s2) {
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
          matrix[i - 1][j] + 1, // eliminación
          matrix[i][j - 1] + 1, // inserción
          matrix[i - 1][j - 1] + cost, // sustitución
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Calcula el porcentaje de similitud basado en la distancia de Levenshtein
  /// Retorna un valor entre 0.0 (completamente diferente) y 1.0 (idéntico)
  static double levenshteinSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    return 1.0 - (distance / maxLength);
  }

  /// Calcula la similitud de Jaro entre dos cadenas
  static double jaroSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;

    final matchWindow = ((s1.length > s2.length ? s1.length : s2.length) / 2) - 1;
    if (matchWindow < 0) return 0.0;

    final s1Matches = List.filled(s1.length, false);
    final s2Matches = List.filled(s2.length, false);

    int matches = 0;
    int transpositions = 0;

    // Identificar coincidencias
    for (int i = 0; i < s1.length; i++) {
      final start = (i - matchWindow) > 0 ? (i - matchWindow).toInt() : 0;
      final end = (i + matchWindow + 1) < s2.length ? (i + matchWindow + 1).toInt() : s2.length;

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
    for (int i = 0; i < s1.length; i++) {
      if (!s1Matches[i]) continue;
      while (!s2Matches[k]) k++;
      if (s1[i] != s2[k]) transpositions++;
      k++;
    }

    return (matches / s1.length + matches / s2.length + (matches - transpositions / 2) / matches) / 3.0;
  }

  /// Calcula la similitud de Jaro-Winkler entre dos cadenas
  /// Da mayor peso a las coincidencias al inicio de las cadenas
  static double jaroWinklerSimilarity(String s1, String s2, {double prefixScale = 0.1}) {
    final jaroSim = jaroSimilarity(s1, s2);
    if (jaroSim < 0.7) return jaroSim;

    int prefixLength = 0;
    int maxPrefix = s1.length < s2.length ? s1.length : s2.length;
    maxPrefix = maxPrefix < 4 ? maxPrefix : 4;

    for (int i = 0; i < maxPrefix; i++) {
      if (s1[i] == s2[i]) {
        prefixLength++;
      } else {
        break;
      }
    }

    return jaroSim + (prefixLength * prefixScale * (1 - jaroSim));
  }

  /// Encuentra la mejor coincidencia de una cadena objetivo en una lista de candidatos
  /// Retorna un mapa con la mejor coincidencia y su puntuación de similitud
  static Map<String, dynamic> findBestMatch(
    String target,
    List<String> candidates, {
    double threshold = 0.6,
    bool useJaroWinkler = true,
  }) {
    String? bestMatch;
    double bestScore = 0.0;

    for (final candidate in candidates) {
      final score = useJaroWinkler
          ? jaroWinklerSimilarity(target.toUpperCase(), candidate.toUpperCase())
          : levenshteinSimilarity(target.toUpperCase(), candidate.toUpperCase());

      if (score > bestScore && score >= threshold) {
        bestScore = score;
        bestMatch = candidate;
      }
    }

    return {
      'match': bestMatch,
      'score': bestScore,
      'found': bestMatch != null,
    };
  }

  /// Encuentra todas las coincidencias que superen el umbral especificado
  static List<Map<String, dynamic>> findAllMatches(
    String target,
    List<String> candidates, {
    double threshold = 0.6,
    bool useJaroWinkler = true,
  }) {
    final matches = <Map<String, dynamic>>[];

    for (final candidate in candidates) {
      final score = useJaroWinkler
          ? jaroWinklerSimilarity(target.toUpperCase(), candidate.toUpperCase())
          : levenshteinSimilarity(target.toUpperCase(), candidate.toUpperCase());

      if (score >= threshold) {
        matches.add({
          'match': candidate,
          'score': score,
        });
      }
    }

    // Ordenar por puntuación descendente
    matches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return matches;
  }
}