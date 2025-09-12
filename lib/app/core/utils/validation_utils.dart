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
      r'[A-Z]' // 1
      r'[AEIOU]' // 2
      r'[A-Z]' // 3
      r'[A-Z]' // 4
      r'\d{2}' // 5–6: año
      r'(0[1-9]|1[0-2])' // 7–8: mes
      r'(0[1-9]|[12]\d|3[01])' // 9–10: día
      r'[HM]' // 11: sexo
      r'(AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|'
      'JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|'
      'TC|TL|TS|VZ|YN|ZS|NE)' // 12–13: entidad
      r'[B-DF-HJ-NP-TV-Z]{3}' // 14–16: consonantes internas
      r'[A-Z0-9]' // 17: homoclave
      r'\d' // 18: dígito verificador (formato)
      r'$',
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
      r')$',
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

  /// Valida GRANULARMENTE el formato de una Clave de Elector del INE (18 caracteres)
  ///
  /// Estructura oficial de la Clave de Elector:
  ///  Posiciones 1-6: Consonantes de apellidos y nombre (solo consonantes A-Z, excluyendo vocales)
  ///  Posiciones 7-14: 8 dígitos (año de nacimiento + mes + día + código de entidad federativa)
  ///  Posición 15: Letra de género (M=Mujer, H=Hombre, X=No especificado)
  ///  Posiciones 16-18: 3 dígitos del sistema (números 0-9)
  ///
  /// Esta validación es más estricta que isValidClaveElector ya que verifica
  /// cada posición según las reglas oficiales del INE.
  static bool isValidClaveElectorGranular(String raw) {
    final clave = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    // Debe tener exactamente 18 caracteres
    if (clave.length != 18) return false;

    // Posiciones 1-6: Solo consonantes (excluir A, E, I, O, U)
    final consonantes = clave.substring(0, 6);
    if (!RegExp(r'^[BCDFGHJKLMNPQRSTVWXYZ]{6}$').hasMatch(consonantes)) {
      return false;
    }

    // Posiciones 7-14: 8 dígitos (año + mes + día + entidad)
    final digitos = clave.substring(6, 14);
    if (!RegExp(r'^\d{8}$').hasMatch(digitos)) {
      return false;
    }

    // Validar año (posiciones 7-8): debe ser un año válido
    final ano = int.tryParse(digitos.substring(0, 2));
    if (ano == null) return false;

    // Validar mes (posiciones 9-10): 01-12
    final mes = int.tryParse(digitos.substring(2, 4));
    if (mes == null || mes < 1 || mes > 12) return false;

    // Validar día (posiciones 11-12): 01-31
    final dia = int.tryParse(digitos.substring(4, 6));
    if (dia == null || dia < 1 || dia > 31) return false;

    // Posiciones 13-14: código de entidad federativa (00-99, pero típicamente 01-32)
    final entidad = int.tryParse(digitos.substring(6, 8));
    if (entidad == null || entidad < 0 || entidad > 99) return false;

    // Posición 15: Letra de género (M, H, X)
    final genero = clave.substring(14, 15);
    if (!RegExp(r'^[MHX]$').hasMatch(genero)) {
      return false;
    }

    // Posiciones 16-18: 3 dígitos del sistema
    final digitosFinales = clave.substring(15, 18);
    if (!RegExp(r'^\d{3}$').hasMatch(digitosFinales)) {
      return false;
    }

    return true;
  }

  /// Sanitiza una Clave de Elector corrigiendo errores comunes de OCR por posición
  ///
  /// Aplica correcciones específicas según la posición en la estructura:
  ///  - Posiciones 1-6: Convierte a consonantes válidas
  ///  - Posiciones 7-14: Convierte a dígitos
  ///  - Posición 15: Convierte a letra de género válida (M/H/X)
  ///  - Posiciones 16-18: Convierte a dígitos (como especificó el usuario)
  static String sanitizeClaveElector(String raw) {
    String clave = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    // Si no tiene 18 caracteres, retornar como está
    if (clave.length != 18) return clave;

    String result = '';

    // Posiciones 1-6: Consonantes (corregir caracteres mal interpretados)
    for (int i = 0; i < 6; i++) {
      String char = clave[i];
      bool wasDigit = RegExp(r'[0-9]').hasMatch(char);

      // Corregir dígitos a letras similares
      if (wasDigit) {
        switch (char) {
          case '0':
            char = 'O';
            break;
          case '1':
            char = 'I';
            break;
          case '3':
            char = 'I';
            break;
          case '5':
            char = 'S';
            break;
          case '8':
            char = 'B';
            break;
          case '6':
            char = 'G';
            break;
        }
      }

      // Convertir vocales a consonantes (tanto originales como las que vinieron de dígitos)
      if (RegExp(r'[AEIOU]').hasMatch(char)) {
        switch (char) {
          case 'A':
            char = 'R';
            break;
          case 'E':
            char = 'F';
            break;
          case 'I':
            char = 'L';
            break;
          case 'O':
            char = 'Q';
            break;
          case 'U':
            char = 'V';
            break;
        }
      }

      result += char;
    }

    // Posiciones 7-14: Dígitos (corregir letras mal interpretadas)
    for (int i = 6; i < 14; i++) {
      String char = clave[i];
      // Corregir errores comunes de OCR en dígitos
      switch (char) {
        case 'O':
          char = '0';
          break;
        case 'I':
          char = '1';
          break;
        case 'L':
          char = '1';
          break;
        case 'S':
          char = '5';
          break;
        case 'B':
          char = '8';
          break;
        case 'G':
          char = '6';
          break;
        case 'Z':
          char = '2';
          break;
        case 'T':
          char = '7';
          break;
        case 'H':
          char = '0';
          break; // H específicamente a 0
        default:
          // Si sigue siendo letra, convertir a dígito por defecto
          if (RegExp(r'[A-Z]').hasMatch(char)) {
            char = '0';
          }
          break;
      }

      result += char;
    }

    // Posición 15: Género (M, H, X)
    String genero = clave[14];
    // Corregir errores comunes para género
    if (genero == '0' || genero == 'O') genero = 'H';
    if (genero == '1' || genero == 'I' || genero == 'L') genero = 'H';
    if (!RegExp(r'^[MHX]$').hasMatch(genero)) {
      genero = 'H'; // Por defecto H si no es válido
    }
    result += genero;

    // Posiciones 16-18: 3 dígitos finales (como especificó el usuario)
    for (int i = 15; i < 18; i++) {
      String char = clave[i];
      // Corregir errores comunes de OCR para que sean números
      char = char
          .replaceAll('O', '0')
          .replaceAll('I', '1')
          .replaceAll('L', '1')
          .replaceAll('S', '5')
          .replaceAll('B', '8')
          .replaceAll('G', '6')
          .replaceAll('Z', '2')
          .replaceAll('T', '7')
          .replaceAll('A', '4');

      // Si sigue siendo letra, convertir a dígito por defecto
      if (RegExp(r'[A-Z]').hasMatch(char)) {
        char = '0';
      }

      result += char;
    }

    return result;
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
      return year1 >= 1900 &&
          year1 <= currentYear + 50 &&
          year2 >= 1900 &&
          year2 <= currentYear + 50 &&
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
    return name
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[0-9]'), '') // Eliminar números
        .replaceAll(RegExp(r'\s+'), ' ') // Normalizar espacios
        .trim(); // Eliminar espacios al inicio y final después de limpiar
  }

  /// Limpia un nombre que ya ha sido normalizado con OCR (no elimina números convertidos a letras)
  static String cleanNormalizedName(String name) {
    return name
        .trim()
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
  /// T2 y T3: pueden ser frontal o reverso
  /// (T1 deshabilitado completamente)
  static bool isSideConsistentWithType(String side, String type) {
    if (side.isEmpty) return true; // Lado vacío es válido durante procesamiento

    if (!isValidSide(side)) return false;

    // T1 deshabilitado - solo se procesan T2 y T3
    if (type == 't1') {
      return false;
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
  static bool hasExpectedDataForSide(
    String side,
    Map<String, String> credentialData,
  ) {
    if (side.isEmpty || !isValidSide(side))
      return true; // No validar si lado no está definido

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

  /// Valida CURP con verificación granular de cada posición según especificaciones oficiales
  ///
  /// Formato CURP (18 posiciones):
  /// 1-4: Solo letras mayúsculas (apellidos y nombre)
  /// 5-10: Solo números (fecha YYMMDD)
  /// 11: Solo 'H' o 'M' (sexo)
  /// 12-13: Códigos de estado válidos (AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS)
  /// 14-16: Solo letras mayúsculas (consonantes internas)
  /// 17: Letra mayúscula o número (homoclave)
  /// 18: Solo números 0-9 (dígito verificador)
  static bool isValidCurpGranular(String raw) {
    if (raw.isEmpty) return false;

    final curp = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    // Debe tener exactamente 18 caracteres
    if (curp.length != 18) return false;

    // Posiciones 1-4: Solo letras mayúsculas
    for (int i = 0; i < 4; i++) {
      if (!RegExp(r'^[A-Z]$').hasMatch(curp[i])) return false;
    }

    // Posiciones 5-10: Solo números (fecha YYMMDD)
    for (int i = 4; i < 10; i++) {
      if (!RegExp(r'^[0-9]$').hasMatch(curp[i])) return false;
    }

    // Validar fecha específicamente
    final year = int.tryParse(curp.substring(4, 6));
    final month = int.tryParse(curp.substring(6, 8));
    final day = int.tryParse(curp.substring(8, 10));

    if (year == null || month == null || day == null) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;

    // Posición 11: Solo 'H' o 'M'
    if (!RegExp(r'^[HM]$').hasMatch(curp[10])) return false;

    // Posiciones 12-13: Códigos de estado válidos
    final stateCode = curp.substring(11, 13);
    final validStateCodes = {
      'AS',
      'BC',
      'BS',
      'CC',
      'CL',
      'CM',
      'CS',
      'CH',
      'DF',
      'DG',
      'GT',
      'GR',
      'HG',
      'JC',
      'MC',
      'MN',
      'MS',
      'NT',
      'NL',
      'OC',
      'PL',
      'QT',
      'QR',
      'SP',
      'SL',
      'SR',
      'TC',
      'TS',
      'TL',
      'VZ',
      'YN',
      'ZS',
      'NE',
    };
    if (!validStateCodes.contains(stateCode)) return false;

    // Posiciones 14-16: Solo letras mayúsculas
    for (int i = 13; i < 16; i++) {
      if (!RegExp(r'^[A-Z]$').hasMatch(curp[i])) return false;
    }

    // Posición 17: Letra mayúscula o número
    if (!RegExp(r'^[A-Z0-9]$').hasMatch(curp[16])) return false;

    // Posición 18: Solo números 0-9
    if (!RegExp(r'^[0-9]$').hasMatch(curp[17])) return false;

    return true;
  }

  /// Sanea y corrige CURP aplicando reglas de conversión específicas por posición
  ///
  /// Reglas de saneamiento:
  /// - Posiciones 1-4: Convierte números a letras equivalentes
  /// - Posiciones 5-10: Elimina caracteres no numéricos
  /// - Posición 11: Convierte a mayúscula, permite solo 'H' o 'M'
  /// - Posiciones 12-13: Convierte a mayúscula y valida códigos de estado
  /// - Posiciones 14-16: Convierte números a letras equivalentes
  /// - Posición 17: Conserva solo letras mayúsculas o números
  /// - Posición 18: Elimina caracteres no numéricos
  static String sanitizeCurp(String raw) {
    if (raw.isEmpty) return '';

    // Normalizar a mayúsculas y limpiar caracteres especiales básicos
    String curp = raw.toUpperCase().replaceAll(RegExp(r'[\s\-_]'), '');

    // Si el CURP ya tiene 18 caracteres, intentar devolverlo directamente
    // Patrón estricto: 4 letras + 6 números + H/M + 5 letras + alfanumérico + número
    if (curp.length == 18 &&
        RegExp(r'^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]$').hasMatch(curp)) {
      return curp;
    }

    // Para CURPs de 18 caracteres que parecen válidos
    if (curp.length == 18 && RegExp(r'^[A-Z0-9]{18}$').hasMatch(curp)) {
      // Si sigue exactamente el patrón estándar, devolverlo directamente
      if (RegExp(
        r'^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]$',
      ).hasMatch(curp)) {
        return curp;
      }
      
      // Para CURPs que no siguen el patrón estándar pero tienen estructura válida:
      // - Contienen H o M (género)
      // - Contienen números (fecha)
      // - Solo caracteres alfanuméricos válidos
      // - Tienen longitud correcta
      if (curp.contains(RegExp(r'[HM]')) && 
          curp.contains(RegExp(r'[0-9]')) &&
          !curp.contains(RegExp(r'[^A-Z0-9]'))) {
        // Verificar que tenga una estructura mínima reconocible
        // Al menos 4 letras y 6 números en total
        final letters = curp.replaceAll(RegExp(r'[^A-Z]'), '').length;
        final numbers = curp.replaceAll(RegExp(r'[^0-9]'), '').length;
        if (letters >= 4 && numbers >= 6) {
          return curp;
        }
      }
    }

    // Mapeo de números a letras para conversión
    const numberToLetter = {
      '0': 'O',
      '1': 'I',
      '2': 'Z',
      '3': 'E',
      '4': 'A',
      '5': 'S',
      '6': 'G',
      '7': 'T',
      '8': 'B',
      '9': 'G',
    };

    // Procesar cada posición de manera más flexible
    List<String> positions = List.filled(18, '');
    int inputIndex = 0;

    for (int pos = 0; pos < 18 && inputIndex < curp.length; pos++) {
      String char = curp[inputIndex];

      if (pos < 4) {
        // Posiciones 1-4: Solo letras, convertir números si es necesario
        if (RegExp(r'^[A-Z]$').hasMatch(char)) {
          positions[pos] = char;
          inputIndex++;
        } else if (RegExp(r'^[0-9]$').hasMatch(char)) {
          positions[pos] = numberToLetter[char] ?? 'X';
          inputIndex++;
        } else {
          inputIndex++; // Saltar carácter inválido
          pos--; // Reintentar esta posición
        }
      } else if (pos >= 4 && pos < 10) {
        // Posiciones 5-10: Solo números
        if (RegExp(r'^[0-9]$').hasMatch(char)) {
          positions[pos] = char;
          inputIndex++;
        } else {
          inputIndex++; // Saltar carácter inválido
          pos--; // Reintentar esta posición
        }
      } else if (pos == 10) {
        // Posición 11: Solo H o M
        if (char == 'H' || char == 'M') {
          positions[pos] = char;
          inputIndex++;
        } else if (char == 'F') {
          positions[pos] = 'M';
          inputIndex++;
        } else {
          inputIndex++; // Saltar carácter inválido
          pos--; // Reintentar esta posición
        }
      } else if (pos >= 11 && pos < 13) {
        // Posiciones 12-13: Solo letras para códigos de estado
        if (RegExp(r'^[A-Z]$').hasMatch(char)) {
          positions[pos] = char;
          inputIndex++;
        } else {
          inputIndex++; // Saltar carácter inválido
          pos--; // Reintentar esta posición
        }
      } else if (pos >= 13 && pos < 16) {
        // Posiciones 14-16: Solo letras, convertir números si es necesario
        if (RegExp(r'^[A-Z]$').hasMatch(char)) {
          positions[pos] = char;
          inputIndex++;
        } else if (RegExp(r'^[0-9]$').hasMatch(char)) {
          positions[pos] = numberToLetter[char] ?? 'X';
          inputIndex++;
        } else {
          inputIndex++; // Saltar carácter inválido
          pos--; // Reintentar esta posición
        }
      } else if (pos == 16) {
        // Posición 17: Letras o números
        if (RegExp(r'^[A-Z0-9]$').hasMatch(char)) {
          positions[pos] = char;
          inputIndex++;
        } else {
          inputIndex++; // Saltar carácter inválido
          pos--; // Reintentar esta posición
        }
      } else if (pos == 17) {
        // Posición 18: Solo números
        if (RegExp(r'^[0-9]$').hasMatch(char)) {
          positions[pos] = char;
          inputIndex++;
        } else {
          inputIndex++; // Saltar carácter inválido
          pos--; // Reintentar esta posición
        }
      }
    }

    // Construir resultado con todas las posiciones procesadas
    String result = '';
    for (int i = 0; i < 18; i++) {
      if (positions[i].isNotEmpty) {
        result += positions[i];
      }
      // No hacer break - continuar procesando todas las posiciones
    }

    // Validar y corregir código de estado en posiciones 12-13 si está completo
    if (result.length >= 13) {
      final stateCode = result.substring(11, 13);
      final validStateCodes = {
        'AS',
        'BC',
        'BS',
        'CC',
        'CL',
        'CM',
        'CS',
        'CH',
        'DF',
        'DG',
        'GT',
        'GR',
        'HG',
        'JC',
        'MC',
        'MN',
        'MS',
        'NT',
        'NL',
        'OC',
        'PL',
        'QT',
        'QR',
        'SP',
        'SL',
        'SR',
        'TC',
        'TS',
        'TL',
        'VZ',
        'YN',
        'ZS',
        'NE',
      };

      if (!validStateCodes.contains(stateCode)) {
        // Si el código no es válido, intentar corregir con códigos comunes
        const commonCorrections = {
          'MX': 'DF',
          'CD': 'DF',
          'CM': 'CM',
          'NE': 'NL',
          'JA': 'JC',
          'MI': 'MC',
          'GU': 'GT',
          'QR': 'QR',
        };

        if (commonCorrections.containsKey(stateCode)) {
          result =
              result.substring(0, 11) +
              commonCorrections[stateCode]! +
              result.substring(13);
        } else {
          // Default a DF si no se puede corregir
          result = result.substring(0, 11) + 'DF' + result.substring(13);
        }
      }
    }

    return result;
  }
}
