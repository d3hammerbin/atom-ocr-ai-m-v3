import 'dart:math';

/// Utilidades para validación de datos de credenciales INE
class ValidationUtils {
  /// Valida el formato de una CURP
  static bool isValidCURP(String curp) {
    if (curp.length != 18) return false;
    
    // Patrón básico de CURP: 4 letras, 6 dígitos, 1 letra, 1 dígito, 1 letra, 5 caracteres alfanuméricos
    final curpPattern = RegExp(r'^[A-Z]{4}[0-9]{6}[HM][A-Z]{2}[A-Z0-9]{3}[0-9]$');
    return curpPattern.hasMatch(curp.toUpperCase());
  }
  
  /// Valida el formato de una clave de elector
  static bool isValidClaveElector(String clave) {
    if (clave.length != 18) return false;
    
    // Patrón básico: 6 letras, 8 dígitos, 4 dígitos
    final clavePattern = RegExp(r'^[A-Z]{6}[0-9]{8}[0-9]{4}$');
    return clavePattern.hasMatch(clave.toUpperCase());
  }
  
  /// Valida el formato de una fecha en formato DD/MM/YYYY
  static bool isValidDate(String fecha) {
    if (fecha.isEmpty) return false;
    
    try {
      final parts = fecha.split('/');
      if (parts.length != 3) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > DateTime.now().year + 10) return false;
      
      // Validación básica de fecha
      final date = DateTime(year, month, day);
      return date.day == day && date.month == month && date.year == year;
    } catch (e) {
      return false;
    }
  }
  
  /// Valida el formato de una sección electoral
  static bool isValidSeccion(String seccion) {
    if (seccion.isEmpty) return false;
    
    // Debe ser un número de 4 dígitos
    final seccionPattern = RegExp(r'^[0-9]{4}$');
    return seccionPattern.hasMatch(seccion);
  }
  
  /// Valida que el sexo sea válido (H o M)
  static bool isValidSexo(String sexo) {
    return sexo.toUpperCase() == 'H' || sexo.toUpperCase() == 'M';
  }
  
  /// Valida que el año de registro sea válido
  static bool isValidAnioRegistro(String anio) {
    if (anio.isEmpty) return false;
    
    try {
      final year = int.parse(anio);
      return year >= 1990 && year <= DateTime.now().year;
    } catch (e) {
      return false;
    }
  }
  
  /// Valida que la vigencia sea válida (formato YYYY)
  static bool isValidVigencia(String vigencia) {
    if (vigencia.isEmpty) return false;
    
    try {
      final year = int.parse(vigencia);
      final currentYear = DateTime.now().year;
      return year >= currentYear && year <= currentYear + 20;
    } catch (e) {
      return false;
    }
  }
  
  /// Valida que un nombre no esté vacío y tenga formato válido
  static bool isValidNombre(String nombre) {
    if (nombre.isEmpty) return false;
    
    // Solo letras, espacios, acentos y algunos caracteres especiales
    final nombrePattern = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s\-]+$');
    return nombrePattern.hasMatch(nombre) && nombre.trim().length >= 2;
  }
  
  /// Valida que un domicilio tenga formato básico válido
  static bool isValidDomicilio(String domicilio) {
    if (domicilio.isEmpty) return false;
    
    // Debe tener al menos 10 caracteres y contener letras y números
    return domicilio.length >= 10 && 
           RegExp(r'[a-zA-Z]').hasMatch(domicilio) && 
           RegExp(r'[0-9]').hasMatch(domicilio);
  }
  
  /// Calcula la confianza de los datos extraídos (0.0 a 1.0)
  static double calculateDataConfidence(Map<String, String?> extractedData) {
    int validFields = 0;
    int totalFields = 0;
    
    final validations = {
      'curp': (String? value) => value != null && isValidCURP(value),
      'claveElector': (String? value) => value != null && isValidClaveElector(value),
      'nombre': (String? value) => value != null && isValidNombre(value),
      'fechaNacimiento': (String? value) => value != null && isValidDate(value),
      'sexo': (String? value) => value != null && isValidSexo(value),
      'seccion': (String? value) => value != null && isValidSeccion(value),
      'vigencia': (String? value) => value != null && isValidVigencia(value),
      'domicilio': (String? value) => value != null && isValidDomicilio(value),
    };
    
    for (final entry in validations.entries) {
      totalFields++;
      if (entry.value(extractedData[entry.key])) {
        validFields++;
      }
    }
    
    return totalFields > 0 ? validFields / totalFields : 0.0;
  }
  
  /// Verifica si los datos mínimos requeridos están presentes
  static bool hasMinimumRequiredData(Map<String, String?> extractedData) {
    final requiredFields = ['nombre', 'claveElector', 'curp'];
    
    for (final field in requiredFields) {
      final value = extractedData[field];
      if (value == null || value.isEmpty) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Limpia y normaliza un texto extraído
  static String cleanExtractedText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Múltiples espacios a uno solo
        .replaceAll(RegExp(r'[^\w\s\-\/áéíóúÁÉÍÓÚñÑ]'), '') // Remover caracteres especiales excepto acentos
        .toUpperCase();
  }
  
  /// Extrae números de un texto
  static List<String> extractNumbers(String text) {
    final numberPattern = RegExp(r'\b\d+\b');
    return numberPattern.allMatches(text).map((match) => match.group(0)!).toList();
  }
  
  /// Extrae fechas potenciales de un texto
  static List<String> extractDates(String text) {
    final datePatterns = [
      RegExp(r'\b\d{1,2}/\d{1,2}/\d{4}\b'), // DD/MM/YYYY
      RegExp(r'\b\d{1,2}-\d{1,2}-\d{4}\b'), // DD-MM-YYYY
      RegExp(r'\b\d{4}/\d{1,2}/\d{1,2}\b'), // YYYY/MM/DD
      RegExp(r'\b\d{4}-\d{1,2}-\d{1,2}\b'), // YYYY-MM-DD
    ];
    
    final dates = <String>[];
    for (final pattern in datePatterns) {
      dates.addAll(pattern.allMatches(text).map((match) => match.group(0)!));
    }
    
    return dates;
  }
  
  /// Normaliza una fecha al formato DD/MM/YYYY
  static String? normalizeDateFormat(String date) {
    try {
      // Remover espacios y caracteres no deseados
      date = date.trim().replaceAll(RegExp(r'[^\d\/\-]'), '');
      
      if (date.contains('/')) {
        final parts = date.split('/');
        if (parts.length == 3) {
          // Si el año está al final (DD/MM/YYYY)
          if (parts[2].length == 4) {
            return '${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[2]}';
          }
          // Si el año está al inicio (YYYY/MM/DD)
          else if (parts[0].length == 4) {
            return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
          }
        }
      } else if (date.contains('-')) {
        final parts = date.split('-');
        if (parts.length == 3) {
          // Si el año está al final (DD-MM-YYYY)
          if (parts[2].length == 4) {
            return '${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[2]}';
          }
          // Si el año está al inicio (YYYY-MM-DD)
          else if (parts[0].length == 4) {
            return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
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
    
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
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
  
  /// Calcula la similitud entre dos strings (0.0 a 1.0)
  static double calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    final distance = levenshteinDistance(s1.toLowerCase(), s2.toLowerCase());
    final maxLength = max(s1.length, s2.length);
    
    return 1.0 - (distance / maxLength);
  }
}