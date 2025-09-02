/// Utilidades para validación de documentos oficiales mexicanos
/// 
/// Esta librería proporciona funciones para validar el formato de:
/// - CURP (Clave Única de Registro de Población)
/// - RFC (Registro Federal de Contribuyentes)
class ValidationUtils {
  /// Valida SOLO el FORMATO de un CURP (sin calcular/verificar el dígito verificador).
  /// 
  /// Seccionamiento (posiciones 1–18):
  ///  1: Inicial del primer apellido (A–Z)
  ///  2: Primera vocal del primer apellido (A,E,I,O,U)
  ///  3: Inicial del segundo apellido (A–Z; X si no hay)
  ///  4: Inicial del nombre (A–Z)
  ///  5–6: Año de nacimiento (00–99)
  ///  7–8: Mes (01–12)
  ///  9–10: Día (01–31)
  ///  11: Sexo (H/M)
  ///  12–13: Entidad federativa (AS, BC, BS, CC, CL, CM, CS, CH, DF, DG, GT, GR, HG,
  ///        JC, MC, MN, MS, NT, NL, OC, PL, QT, QR, SP, SL, SR, TC, TL, TS, VZ, YN, ZS, NE)
  ///  14: Consonante interna del primer apellido (B–Z sin vocales)
  ///  15: Consonante interna del segundo apellido
  ///  16: Consonante interna del nombre
  ///  17: Homoclave (A–Z o 0–9)
  ///  18: Dígito verificador (0–9) — aquí SOLO se valida que sea dígito; NO se calcula.
  /// 
  /// Nota: Esta función valida estructura y rangos básicos de fecha, pero no calendario real
  /// (p. ej., no detecta 31/02). Elimina espacios/guiones y valida en mayúsculas.
  static bool isValidCurpFormat(String raw) {
    final curp = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    final re = RegExp(
      r'^'
      r'[A-Z]'                               // 1
      r'[AEIOU]'                             // 2
      r'[A-Z]'                               // 3
      r'[A-Z]'                               // 4
      r'\d{2}'                               // 5–6: año
      r'(0[1-9]|1[0-2])'                     // 7–8: mes
      r'(0[1-9]|[12]\d|3[01])'               // 9–10: día
      r'[HM]'                                // 11: sexo
      r'(AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|'
        'JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|'
        'TC|TL|TS|VZ|YN|ZS|NE)'              // 12–13: entidad
      r'[B-DF-HJ-NP-TV-Z]{3}'                // 14–16: consonantes internas
      r'[A-Z0-9]'                            // 17: homoclave
      r'\d'                                  // 18: dígito verificador (formato)
      r'$'
    );

    return re.hasMatch(curp);
  }

  /// Valida SOLO el FORMATO de un RFC mexicano (sin calcular/verificar el dígito).
  /// Soporta Persona Física (13) y Persona Moral (12).
  /// 
  /// Seccionamiento:
  /// PF (13):
  ///  1–4  Letras del nombre (A–Z, Ñ)
  ///  5–6  Año (00–99)
  ///  7–8  Mes (01–12)
  ///  9–10 Día (01–31)
  ///  11–13 Homoclave (A–Z, 0–9)
  /// 
  /// PM (12):
  ///  1–3  Letras de la razón social (A–Z, Ñ, &)
  ///  4–5  Año (00–99)
  ///  6–7  Mes (01–12)
  ///  8–9  Día (01–31)
  ///  10–12 Homoclave (A–Z, 0–9)
  /// 
  /// Nota: Solo valida estructura y rangos básicos de fecha.
  ///       Normaliza a mayúsculas y elimina caracteres no permitidos.
  static bool isValidRfcFormat(String raw) {
    final rfc = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9Ñ&]'), '');
    final re = RegExp(
      r'^(?:'
      r'[A-ZÑ&]{3}\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])[A-Z0-9]{3}' // PM (12)
      r'|'
      r'[A-ZÑ&]{4}\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])[A-Z0-9]{3}' // PF (13)
      r')$'
    );
    return re.hasMatch(rfc);
  }

  /// Limpia un CURP removiendo espacios, guiones y caracteres especiales
  static String cleanCurp(String curp) {
    return curp.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Valida el formato de una clave de elector (18 caracteres alfanuméricos)
  /// La clave de elector debe tener exactamente 18 caracteres que pueden ser letras (A-Z) o números (0-9)
  /// Elimina espacios y caracteres especiales antes de validar
  static bool isValidClaveElector(String raw) {
    final clave = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return clave.length == 18 && RegExp(r'^[A-Z0-9]{18}$').hasMatch(clave);
  }

  /// Limpia una clave de elector removiendo espacios y caracteres especiales
  static String cleanClaveElector(String clave) {
    return clave.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Limpia un RFC removiendo espacios, guiones y caracteres especiales
  /// Mantiene solo letras (A-Z, Ñ), números (0-9) y ampersand (&)
  static String cleanRfc(String rfc) {
    return rfc.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9Ñ&]'), '');
  }

  /// Formatea un CURP con guiones para mejor legibilidad
  /// Ejemplo: ABCD123456HDFGHI01 -> ABCD-123456-HDFGHI-01
  static String formatCurp(String curp) {
    final cleaned = cleanCurp(curp);
    if (cleaned.length != 18) return cleaned;
    
    return '${cleaned.substring(0, 4)}-${cleaned.substring(4, 10)}-${cleaned.substring(10, 16)}-${cleaned.substring(16, 18)}';
  }

  /// Formatea un RFC con guiones para mejor legibilidad
  /// Persona Física (13): ABCD123456ABC -> ABCD-123456-ABC
  /// Persona Moral (12): ABC123456ABC -> ABC-123456-ABC
  static String formatRfc(String rfc) {
    final cleaned = cleanRfc(rfc);
    
    if (cleaned.length == 13) {
      // Persona Física: ABCD-123456-ABC
      return '${cleaned.substring(0, 4)}-${cleaned.substring(4, 10)}-${cleaned.substring(10, 13)}';
    } else if (cleaned.length == 12) {
      // Persona Moral: ABC-123456-ABC
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 9)}-${cleaned.substring(9, 12)}';
    }
    
    return cleaned; // Retorna sin formato si no tiene longitud válida
  }

  /// Valida que un nombre contenga solo letras (A-Z) y espacios
  /// Normaliza a mayúsculas y elimina espacios múltiples
  static bool isValidName(String name) {
    final cleaned = name.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return false;
    return RegExp(r'^[A-Z\s]+$').hasMatch(cleaned);
  }

  /// Valida fecha de nacimiento en formato DD/MM/YYYY
  /// Acepta fechas con o sin separadores y las normaliza
  static bool isValidBirthDate(String date) {
    String cleaned = date.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Debe tener exactamente 8 dígitos
    if (cleaned.length != 8) return false;
    
    final day = int.tryParse(cleaned.substring(0, 2));
    final month = int.tryParse(cleaned.substring(2, 4));
    final year = int.tryParse(cleaned.substring(4, 8));
    
    if (day == null || month == null || year == null) return false;
    
    // Validaciones básicas de rango
    if (day < 1 || day > 31) return false;
    if (month < 1 || month > 12) return false;
    if (year < 1900 || year > DateTime.now().year) return false;
    
    return true;
  }

  /// Formatea fecha de nacimiento a formato DD/MM/YYYY
  static String formatBirthDate(String date) {
    String cleaned = date.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 8) return date;
    
    return '${cleaned.substring(0, 2)}/${cleaned.substring(2, 4)}/${cleaned.substring(4, 8)}';
  }

  /// Valida sexo (H para hombre, M para mujer)
  static bool isValidSex(String sex) {
    final cleaned = sex.trim().toUpperCase();
    return cleaned == 'H' || cleaned == 'M';
  }

  /// Valida año de registro en formato YYYY + 2 dígitos (YYYYNN)
  /// Ejemplo: 202400, 201999
  static bool isValidRegistrationYear(String yearCode) {
    final cleaned = yearCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 6) return false;
    
    final year = int.tryParse(cleaned.substring(0, 4));
    final code = cleaned.substring(4, 6);
    
    if (year == null) return false;
    if (year < 1900 || year > DateTime.now().year + 10) return false;
    if (!RegExp(r'^\d{2}$').hasMatch(code)) return false;
    
    return true;
  }

  /// Valida sección como 4 dígitos numéricos
  static bool isValidSection(String section) {
    final cleaned = section.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.length == 4 && RegExp(r'^\d{4}$').hasMatch(cleaned);
  }

  /// Valida vigencia en formato YYYY o YYYY-YYYY (para T3)
  static bool isValidVigencia(String vigencia) {
    if (vigencia.isEmpty) return false;
    
    // Verificar formato YYYY-YYYY (para T3)
    final rangeMatch = RegExp(r'^(\d{4})-(\d{4})$').firstMatch(vigencia);
    if (rangeMatch != null) {
      final year1 = int.tryParse(rangeMatch.group(1)!);
      final year2 = int.tryParse(rangeMatch.group(2)!);
      if (year1 == null || year2 == null) return false;
      
      final currentYear = DateTime.now().year;
      return year1 >= 1900 && year1 <= currentYear + 50 &&
             year2 >= 1900 && year2 <= currentYear + 50 &&
             year2 > year1;
    }
    
    // Verificar formato YYYY (para T2 y otros)
    final cleaned = vigencia.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 4) return false;
    
    final year = int.tryParse(cleaned);
    if (year == null) return false;
    
    return year >= 1900 && year <= DateTime.now().year + 50;
  }

  /// Valida estado como valor numérico (cualquier cantidad de dígitos)
  static bool isValidState(String state) {
    final cleaned = state.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.isNotEmpty && RegExp(r'^\d+$').hasMatch(cleaned);
  }

  /// Valida municipio como código numérico de 3 dígitos
  static bool isValidMunicipality(String municipality) {
    final cleaned = municipality.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.length == 3 && RegExp(r'^\d{3}$').hasMatch(cleaned);
  }

  /// Valida localidad como código numérico de 4 dígitos
  static bool isValidLocality(String locality) {
    final cleaned = locality.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.length == 4 && RegExp(r'^\d{4}$').hasMatch(locality);
  }

  /// Limpia y normaliza un nombre removiendo números y espacios múltiples
  static String cleanName(String name) {
    return name.trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[0-9]'), '') // Eliminar números
        .replaceAll(RegExp(r'\s+'), ' ') // Normalizar espacios
        .trim(); // Eliminar espacios al inicio y final después de limpiar
  }

  /// Limpia un nombre que ya ha sido normalizado con OCR (no elimina números convertidos a letras)
  static String cleanNormalizedName(String name) {
    return name.trim()
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), ' ') // Solo normalizar espacios
        .trim(); // Eliminar espacios al inicio y final
  }

  /// Limpia código numérico removiendo caracteres no numéricos
  static String cleanNumericCode(String code) {
    return code.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Valida si el lado de la credencial es válido
  static bool isValidSide(String side) {
    return side == 'frontal' || side == 'reverso';
  }

  /// Valida si el lado es consistente con el tipo de credencial
  /// T1: típicamente solo frontal (no tienen QR)
  /// T2 y T3: pueden ser frontal o reverso
  static bool isSideConsistentWithType(String side, String type) {
    if (side.isEmpty) return true; // Lado vacío es válido durante procesamiento
    
    if (!isValidSide(side)) return false;
    
    // T1 típicamente no tiene QR, por lo que debería ser frontal
    if (type == 't1') {
      return side == 'frontal';
    }
    
    // T2 y T3 pueden ser frontal o reverso
    if (type == 't2' || type == 't3') {
      return true; // Ambos lados son válidos
    }
    
    // Para tipos desconocidos, aceptar cualquier lado válido
    return isValidSide(side);
  }

  /// Valida si una credencial con lado específico contiene los datos esperados
  /// Frontal: típicamente contiene datos personales (nombre, domicilio, etc.)
  /// Reverso: típicamente contiene códigos QR y datos adicionales
  static bool hasExpectedDataForSide(String side, Map<String, String> credentialData) {
    if (side.isEmpty || !isValidSide(side)) return true; // No validar si lado no está definido
    
    if (side == 'frontal') {
      // El lado frontal debería tener datos personales básicos
      return credentialData['nombre']?.isNotEmpty == true ||
             credentialData['domicilio']?.isNotEmpty == true ||
             credentialData['claveElector']?.isNotEmpty == true;
    }
    
    if (side == 'reverso') {
      // El lado reverso puede tener menos datos de texto (más QRs)
      // Esta validación es más flexible ya que el reverso puede tener pocos datos de texto
      return true;
    }
    
    return true;
  }
}