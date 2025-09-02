import '../../../app/data/models/credencial_ine_model.dart';
import '../utils/validation_utils.dart';
import '../utils/string_similarity_utils.dart';

class IneCredentialProcessorService {
  /// Palabras clave que indican que es una credencial INE
  static const List<String> _ineKeywords = [
    'INSTITUTO NACIONAL ELECTORAL',
    'CREDENCIAL PARA VOTAR',
    'INE',
    'CLAVE DE ELECTOR',
    'CURP',
  ];

  /// Textos institucionales que deben ser filtrados completamente
  static const List<String> _unwantedTexts = [
    'INSTITUTO NACIONAL ELECTORAL',
    'MÉXICO',
    'MEXICO',
  ];

  /// Etiquetas de referencia necesarias para localizar datos pero que no deben aparecer en el resultado final
  static const List<String> _referenceLabels = [
    'CREDENCIAL PARA VOTAR',
    'NOMBRE',
    'NOMERE',
    'NOMRE',
    'DOMICILIO',
    'DOMICILIo',
    'DOMICILI',
    'CLAVE DE ELECTOR',
    'COL',
    'COLONIA',
    'ESTADO',
    'MUNICIPIO',
    'LOCALIDAD',
  ];

  /// Etiquetas específicas para credenciales t1 (más antiguas)
  static const List<String> _tipo1Labels = ['EDAD', 'FOLIO'];

  /// Etiquetas específicas para credenciales t2
  static const List<String> _tipo2Labels = ['ESTADO', 'MUNICIPIO', 'LOCALIDAD'];

  /// Configuración de tipos de credenciales y su procesamiento
  static const Map<String, Map<String, dynamic>> _credentialTypeConfig = {
    'Tipo 1': {
      'code': 't1',
      'process': false,
      'description': 'Credenciales más antiguas con EDAD/FOLIO',
      'requiredFields': [],
    },
    'Tipo 2': {
      'code': 't2',
      'process': true,
      'description': 'Credenciales con ESTADO/MUNICIPIO/LOCALIDAD',
      'requiredFields': [
        'NOMBRE',
        'CLAVE DE ELECTOR',
        'CURP',
        'SECCION',
        'VIGENCIA',
      ],
    },
    'Tipo 3': {
      'code': 't3',
      'process': true,
      'description': 'Credenciales más nuevas sin campos específicos',
      'requiredFields': [
        'NOMBRE',
        'CLAVE DE ELECTOR',
        'CURP',
        'SECCION',
        'VIGENCIA',
      ],
    },
  };

  /// Verifica si el texto extraído corresponde a una credencial INE
  static bool isIneCredential(String extractedText) {
    final upperText = extractedText.toUpperCase();
    return _ineKeywords.any((keyword) => upperText.contains(keyword));
  }

  /// Verifica si un tipo de credencial debe ser procesado
  static bool _shouldProcessCredentialType(String credentialType) {
    // Buscar la configuración por código
    for (final config in _credentialTypeConfig.values) {
      if (config['code'] == credentialType) {
        return config['process'] as bool;
      }
    }
    return false; // Por defecto no procesar tipos desconocidos
  }

  /// Verifica si una credencial cumple con los requisitos mínimos
  static bool isCredentialAcceptable(CredencialIneModel credential) {
    // Buscar la configuración del tipo de credencial
    Map<String, dynamic>? typeConfig;
    for (var config in _credentialTypeConfig.values) {
      if (config['code'] == credential.tipo) {
        typeConfig = config;
        break;
      }
    }

    if (typeConfig == null) return false;

    final requiredFields = typeConfig['requiredFields'] as List<String>;

    // Verificar cada campo requerido con validaciones específicas
    for (String field in requiredFields) {
      switch (field) {
        case 'NOMBRE':
          if (credential.nombre.isEmpty ||
              !ValidationUtils.isValidName(credential.nombre)) {
            return false;
          }
          break;
        case 'CLAVE DE ELECTOR':
          if (credential.claveElector.isEmpty ||
              !ValidationUtils.isValidClaveElector(credential.claveElector)) {
            return false;
          }
          break;
        case 'CURP':
          if (credential.curp.isEmpty ||
              !ValidationUtils.isValidCurpFormat(credential.curp)) {
            return false;
          }
          break;
        case 'SECCION':
          if (credential.seccion.isEmpty ||
              !ValidationUtils.isValidSection(credential.seccion)) {
            return false;
          }
          break;
        case 'VIGENCIA':
          if (credential.vigencia.isEmpty) {
            return false;
          }
          // Para T2, validar formato específico de vigencia
          if (credential.tipo == 't2') {
            // Extraer el año final de vigencia (formato: "YYYY YYYY" o solo "YYYY")
            final vigenciaParts = credential.vigencia.split(' ');
            final lastYear =
                vigenciaParts.isNotEmpty
                    ? vigenciaParts.last
                    : credential.vigencia;
            if (!ValidationUtils.isValidVigencia(lastYear)) {
              return false;
            }
          }
          // Para T3, validar formato específico de vigencia (YYYY-YYYY)
          if (credential.tipo == 't3') {
            if (!ValidationUtils.isValidVigencia(credential.vigencia)) {
              return false;
            }
          }
          break;
      }
    }

    // Validaciones adicionales específicas para credenciales T2
    if (credential.tipo == 't2') {
      // Validar fecha de nacimiento
      if (credential.fechaNacimiento.isNotEmpty &&
          !ValidationUtils.isValidBirthDate(credential.fechaNacimiento)) {
        return false;
      }

      // Validar sexo
      if (credential.sexo.isNotEmpty &&
          !ValidationUtils.isValidSex(credential.sexo)) {
        return false;
      }

      // Validar año de registro
      if (credential.anoRegistro.isNotEmpty &&
          !ValidationUtils.isValidRegistrationYear(
            credential.anoRegistro.replaceAll(' ', ''),
          )) {
        return false;
      }

      // Validar estado (debe ser numérico)
      if (credential.estado.isNotEmpty &&
          !ValidationUtils.isValidState(credential.estado)) {
        return false;
      }

      // Validar municipio (3 dígitos)
      if (credential.municipio.isNotEmpty &&
          !ValidationUtils.isValidMunicipality(credential.municipio)) {
        return false;
      }

      // Validar localidad (4 dígitos)
      if (credential.localidad.isNotEmpty &&
          !ValidationUtils.isValidLocality(credential.localidad)) {
        return false;
      }
    }

    return true; // Todos los campos requeridos están presentes y válidos
  }

  /// Procesa el texto extraído y devuelve un modelo estructurado
  static CredencialIneModel processCredentialText(String extractedText) {
    if (!isIneCredential(extractedText)) {
      return CredencialIneModel.empty();
    }

    // Dividir el texto en líneas y limpiar
    final lines =
        extractedText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

    // Detectar tipo de credencial primero
    final tipoCredencial = _detectCredentialType(lines);

    // Verificar si este tipo de credencial debe ser procesado
    if (!_shouldProcessCredentialType(tipoCredencial)) {
      // Retornar modelo con solo el tipo detectado para credenciales no procesadas
      return CredencialIneModel(
        nombre: '',
        domicilio: '',
        claveElector: '',
        curp: '',
        fechaNacimiento: '',
        sexo: '',
        anoRegistro: '',
        seccion: '',
        vigencia: '',
        tipo: tipoCredencial,
        estado: '',
        municipio: '',
        localidad: '',
      );
    }

    // Filtrar líneas no deseadas
    final filteredLines = _filterUnwantedText(lines);

    // Extraer información adicional usando similitud de cadenas
    final additionalInfo = extractAdditionalInfoWithSimilarity(lines);

    // Extraer campos específicos solo para tipos procesables (t2 y t3)
    // Para t2, usar métodos específicos que manejan campos en la misma línea
    if (tipoCredencial == 't2') {
      // Extraer datos con validación y limpieza
      final nombre = _extractNombre(filteredLines);
      final claveElector = _extractClaveElector(filteredLines);
      final fechaNacimiento = _extractFechaNacimientoT2(filteredLines);
      final sexo = _extractSexo(filteredLines);
      final anoRegistro = _extractAnoRegistroT2(filteredLines);
      final seccion = _extractSeccionT2(filteredLines);
      final vigencia = _extractVigenciaT2(filteredLines);
      final estado = _extractEstado(filteredLines);
      final municipio = _extractMunicipioT2(filteredLines);
      final localidad = _extractLocalidadT2(filteredLines);

      return CredencialIneModel(
        nombre:
            ValidationUtils.isValidName(nombre)
                ? ValidationUtils.cleanName(nombre)
                : nombre,
        domicilio: _extractDomicilio(filteredLines),
        claveElector:
            ValidationUtils.isValidClaveElector(claveElector)
                ? ValidationUtils.cleanClaveElector(claveElector)
                : claveElector,
        curp: _extractCurpT2(filteredLines),
        fechaNacimiento:
            ValidationUtils.isValidBirthDate(fechaNacimiento)
                ? ValidationUtils.formatBirthDate(fechaNacimiento)
                : fechaNacimiento,
        sexo: ValidationUtils.isValidSex(sexo) ? sexo.toUpperCase() : sexo,
        anoRegistro: anoRegistro,
        seccion:
            ValidationUtils.isValidSection(seccion)
                ? ValidationUtils.cleanNumericCode(seccion)
                : seccion,
        vigencia: vigencia,
        tipo: tipoCredencial,
        estado:
            ValidationUtils.isValidState(estado)
                ? ValidationUtils.cleanNumericCode(estado)
                : estado,
        municipio:
            ValidationUtils.isValidMunicipality(municipio)
                ? ValidationUtils.cleanNumericCode(municipio)
                : municipio,
        localidad:
            ValidationUtils.isValidLocality(localidad)
                ? ValidationUtils.cleanNumericCode(localidad)
                : localidad,
      );
    }

    // Para t3, usar métodos optimizados específicos
    if (tipoCredencial == 't3') {
      final nombre = _extractNombre(filteredLines);
      return CredencialIneModel(
        nombre:
            ValidationUtils.isValidName(nombre)
                ? ValidationUtils.cleanName(nombre)
                : nombre,
        domicilio: _extractDomicilio(filteredLines),
        claveElector: _extractClaveElector(filteredLines),
        curp: _extractCurpT3(filteredLines),
        fechaNacimiento: _extractFechaNacimientoT3(filteredLines),
        sexo: _extractSexo(filteredLines),
        anoRegistro: _extractAnoRegistroT3(filteredLines),
        seccion: _extractSeccionT3(filteredLines),
        vigencia: _extractVigenciaT3(filteredLines),
        tipo: tipoCredencial,
        estado: '',
        municipio: '',
        localidad: '',
      );
    }

    // Para otros tipos, usar métodos estándar
    final nombreStandard = _extractNombre(filteredLines);
    return CredencialIneModel(
      nombre:
          ValidationUtils.isValidName(nombreStandard)
              ? ValidationUtils.cleanName(nombreStandard)
              : nombreStandard,
      domicilio: _extractDomicilio(filteredLines),
      claveElector: _extractClaveElector(filteredLines),
      curp: _extractCurp(filteredLines),
      fechaNacimiento: _extractFechaNacimiento(filteredLines),
      sexo: _extractSexo(filteredLines),
      anoRegistro:
          additionalInfo['año_registro'] ?? _extractAnoRegistro(filteredLines),
      seccion: _extractSeccion(filteredLines),
      vigencia: additionalInfo['vigencia'] ?? _extractVigencia(filteredLines),
      tipo: tipoCredencial,
      estado: tipoCredencial == 't2' ? _extractEstado(filteredLines) : '',
      municipio: tipoCredencial == 't2' ? _extractMunicipio(filteredLines) : '',
      localidad: tipoCredencial == 't2' ? _extractLocalidad(filteredLines) : '',
    );
  }

  /// Filtra textos institucionales no deseados de las líneas
  static List<String> _filterUnwantedText(List<String> lines) {
    return lines.where((line) {
      final upperLine = line.toUpperCase();
      return !_unwantedTexts.any((unwanted) {
        // No filtrar líneas que contengan información de sexo
        if (unwanted.toUpperCase() == 'SEXO' &&
            (upperLine.contains('SEXO H') ||
                upperLine.contains('SEXO M') ||
                upperLine.contains('H') ||
                upperLine.contains('M'))) {
          return false;
        }
        return upperLine.contains(unwanted.toUpperCase()) &&
            line.length <= unwanted.length + 5;
      });
    }).toList();
  }

  /// Filtra etiquetas de referencia del resultado final
  static List<String> _filterReferenceLabels(List<String> lines) {
    return lines.where((line) {
      final upperLine = line.toUpperCase();
      return !_referenceLabels.any((label) {
        return upperLine.contains(label.toUpperCase()) &&
            line.length <= label.length + 5;
      });
    }).toList();
  }

  /// Encuentra la mejor coincidencia de una etiqueta usando algoritmos de similitud
  static Map<String, dynamic> _findLabelWithSimilarity(
    List<String> lines,
    List<String> targetLabels, {
    double threshold = 0.7,
  }) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toUpperCase();

      // Buscar coincidencias exactas primero
      for (final label in targetLabels) {
        // Habilitar normalización OCR para etiquetas críticas
        final criticalLabels = [
          'VIGENCIA',
          'NOMBRE',
          'DOMICILIO',
          'SECCION',
          'SECCIÓN',
        ];
        final shouldNormalizeOcr = targetLabels.any(
          (label) => criticalLabels.any(
            (critical) => label.toUpperCase().contains(critical),
          ),
        );

        final normalizedLabel =
            shouldNormalizeOcr
                ? StringSimilarityUtils.normalizeOcrCharacters(label)
                : label.toUpperCase();
        final normalizedLine =
            shouldNormalizeOcr
                ? StringSimilarityUtils.normalizeOcrCharacters(line)
                : line;

        if (normalizedLine.contains(normalizedLabel)) {
          return {
            'found': true,
            'index': i,
            'line': lines[i],
            'label': label,
            'similarity': 1.0,
            'method': 'exact',
          };
        }
      }

      // Buscar usando similitud de cadenas
      final words = line.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length < 3) continue; // Ignorar palabras muy cortas

        // Habilitar normalización OCR para etiquetas críticas
        final criticalLabels = [
          'VIGENCIA',
          'NOMBRE',
          'DOMICILIO',
          'SECCION',
          'SECCIÓN',
        ];
        final shouldNormalizeOcr = targetLabels.any(
          (label) => criticalLabels.any(
            (critical) => label.toUpperCase().contains(critical),
          ),
        );

        // Aplicar normalización OCR al texto de entrada si es necesario
        final processedWord =
            shouldNormalizeOcr
                ? StringSimilarityUtils.normalizeOcrCharacters(word)
                : word;

        final result = StringSimilarityUtils.findBestMatch(
          processedWord,
          targetLabels,
          threshold: threshold,
          useJaroWinkler: true,
          normalizeOcr: shouldNormalizeOcr,
        );

        if (result['found'] == true) {
          return {
            'found': true,
            'index': i,
            'line': lines[i],
            'label': result['match'],
            'similarity': result['score'],
            'method': 'similarity',
            'original_word': word,
          };
        }
      }
    }

    return {
      'found': false,
      'index': -1,
      'line': '',
      'label': '',
      'similarity': 0.0,
      'method': 'none',
    };
  }

  /// Extrae el nombre de la credencial
  static String _extractNombre(List<String> lines) {
    List<String> nombreLines = [];

    // Método 1: Usar "CREDENCIAL PARA VOTAR" como punto de referencia
    nombreLines = _extractNombreByCredentialReference(lines);

    // Método 2: Buscar variantes de la etiqueta NOMBRE/NOMERE
    if (nombreLines.isEmpty) {
      nombreLines = _extractNombreByLabel(lines);
    }

    // Método 3: Fallback con el método anterior
    if (nombreLines.isEmpty) {
      nombreLines = _extractNombreFallback(lines);
    }

    return nombreLines.join(' ').trim();
  }

  /// Extrae el nombre usando "CREDENCIAL PARA VOTAR" como referencia
  static List<String> _extractNombreByCredentialReference(List<String> lines) {
    List<String> nombreLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final upperLine = line.toUpperCase();

      // Buscar "CREDENCIAL" o "VOTAR" como punto de referencia
      if (upperLine.contains('CREDENCIAL') || upperLine.contains('VOTAR')) {
        // La siguiente línea después de "CREDENCIAL PARA VOTAR" contiene la etiqueta del nombre
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].toUpperCase();

          // Verificar si la siguiente línea contiene variantes de NOMBRE
          if (nextLine.contains('NOMBRE') ||
              nextLine.contains('NOMERE') ||
              nextLine.contains('NOMRE')) {
            // Extraer las siguientes 3 líneas después de la etiqueta del nombre
            for (int j = i + 2; j < lines.length && j <= i + 4; j++) {
              final dataLine = lines[j].trim();

              if (dataLine.isNotEmpty) {
                // Filtrar etiquetas de referencia del resultado final
                final filteredData = _filterReferenceLabels([dataLine]);
                if (filteredData.isNotEmpty) {
                  nombreLines.add(filteredData.first.toUpperCase());
                }
              }
            }
            break;
          }
        }
      }
    }

    return nombreLines;
  }

  /// Extrae el nombre buscando directamente las variantes de la etiqueta
  static List<String> _extractNombreByLabel(List<String> lines) {
    List<String> nombreLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Buscar variantes de la etiqueta NOMBRE
      if (line.contains('NOMBRE') ||
          line.contains('NOMERE') ||
          line.contains('NOMRE')) {
        // Extraer exactamente las siguientes 3 líneas después de encontrar la etiqueta
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();

          if (nextLine.isNotEmpty) {
            // Filtrar etiquetas de referencia del resultado final
            final filteredData = _filterReferenceLabels([nextLine]);
            if (filteredData.isNotEmpty) {
              nombreLines.add(filteredData.first.toUpperCase());
            }
          }
        }
        break;
      }
    }

    return nombreLines;
  }

  /// Método fallback para extraer el nombre
  static List<String> _extractNombreFallback(List<String> lines) {
    List<String> nombreLines = [];

    for (int i = 0; i < lines.length && nombreLines.length < 3; i++) {
      final line = lines[i].trim();

      if (RegExp(r'^[A-Za-zÀ-ÿ\s]+$').hasMatch(line) &&
          line.length > 2 &&
          line.length < 50) {
        final upperLine = line.toUpperCase();
        // Excluir textos institucionales y etiquetas de referencia
        if (!_unwantedTexts.any((unwanted) => upperLine.contains(unwanted)) &&
            !_referenceLabels.any((label) => upperLine.contains(label))) {
          nombreLines.add(line.toUpperCase());
        }
      }
    }

    return nombreLines;
  }

  /// Extrae el domicilio
  static String _extractDomicilio(List<String> lines) {
    List<String> domicilioLines = [];

    // Buscar la etiqueta DOMICILIO (con variantes) y extraer exactamente las siguientes 3 líneas
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Buscar variantes de DOMICILIO (incluyendo errores de OCR como 'DOMICILIo')
      if (line.contains('DOMICILIO') ||
          line.contains('DOMICILIo') ||
          line.contains('DOMICILI')) {
        // Extraer exactamente las siguientes 3 líneas después de encontrar DOMICILIO
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();

          if (nextLine.isNotEmpty) {
            // Filtrar etiquetas de referencia del resultado final
            final filteredData = _filterReferenceLabels([nextLine]);
            if (filteredData.isNotEmpty) {
              domicilioLines.add(filteredData.first.toUpperCase());
            }
          }
        }
        break;
      }
    }

    // Si no se encontró la etiqueta DOMICILIO, usar el método anterior como fallback
    if (domicilioLines.isEmpty) {
      for (final line in lines) {
        final upperLine = line.toUpperCase();
        // Buscar líneas que contengan direcciones pero detener en CLAVE DE ELECTOR
        if (upperLine.contains('CLAVE DE ELECTOR') ||
            upperLine.contains('CLAVE ELECTOR')) {
          break;
        }

        if ((upperLine.contains('AV ') ||
                upperLine.contains('CALLE ') ||
                upperLine.contains('COL ') ||
                RegExp(r'\d+').hasMatch(line)) &&
            line.length > 10 &&
            !upperLine.contains('CURP') &&
            !upperLine.contains('SEXO') &&
            !upperLine.contains('NOMBRE')) {
          domicilioLines.add(line.toUpperCase());
        }
      }
    }

    return domicilioLines.join(' ').trim();
  }

  /// Extrae la clave de elector
  static String _extractClaveElector(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta CLAVE DE ELECTOR, extraer el dato de la misma línea
      if (line.contains('CLAVE DE ELECTOR') || line.contains('CLAVE ELECTOR')) {
        // Buscar el patrón después de la etiqueta en la misma línea
        final match = RegExp(
          r'CLAVE\s+DE\s+ELECTOR\s+([A-Z0-9]{18})',
        ).firstMatch(line);
        if (match != null) {
          return match.group(1) ?? '';
        }

        // Fallback: buscar cualquier secuencia de 18 caracteres alfanuméricos en la línea
        final fallbackMatch = RegExp(r'[A-Z0-9]{18}').firstMatch(line);
        if (fallbackMatch != null) {
          return fallbackMatch.group(0) ?? '';
        }

        // Si no está en la misma línea, buscar en las siguientes líneas como fallback
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim().toUpperCase();
          final nextMatch = RegExp(r'[A-Z0-9]{18}').firstMatch(nextLine);
          if (nextMatch != null) {
            return nextMatch.group(0) ?? '';
          }
        }
      }

      // También buscar directamente en la línea actual
      final match = RegExp(r'[A-Z0-9]{18}').firstMatch(line);
      if (match != null && !line.contains('CURP')) {
        return match.group(0) ?? '';
      }
    }
    return '';
  }

  /// Extrae el CURP
  static String _extractCurp(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta CURP, buscar exactamente en la línea siguiente
      if (line.contains('CURP') && i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim().toUpperCase();

        // Buscar patrón de CURP (18 caracteres) sin guiones ni caracteres especiales
        final match = RegExp(
          r'[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]',
        ).firstMatch(nextLine);
        if (match != null) {
          return match.group(0) ?? '';
        }

        // Buscar CURP con guiones o espacios y limpiarlos
        final matchWithSeparators = RegExp(
          r'[A-Z]{4}[0-9]{6}[-\s]*[HM][A-Z]{5}[0-9A-Z][0-9]',
        ).firstMatch(nextLine);
        if (matchWithSeparators != null) {
          return (matchWithSeparators.group(0) ?? '').replaceAll(
            RegExp(r'[-\s]'),
            '',
          );
        }

        // Si la línea siguiente no está vacía pero no coincide con el patrón, devolverla tal como está
        if (nextLine.isNotEmpty) {
          return nextLine;
        }
      }

      // También buscar directamente en la línea actual como fallback
      final match = RegExp(
        r'[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]',
      ).firstMatch(line);
      if (match != null) {
        return match.group(0) ?? '';
      }
    }
    return '';
  }

  /// Extrae el CURP específicamente para credenciales t3
  /// Optimizado para el formato específico de credenciales T3
  static String _extractCurpT3(List<String> lines) {
    // Patrón CURP: 18 caracteres alfanuméricos específicos
    final curpPattern = RegExp(r'\b[A-Z]{4}\d{6}[HM][A-Z]{5}\d{2}\b');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Patrón 1: Buscar línea que contenga "CURP" seguida del código
      if (line.contains('CURP')) {
        // Buscar CURP en la misma línea
        final match = curpPattern.firstMatch(line);
        if (match != null) {
          return match.group(0) ?? '';
        }

        // Buscar CURP en las siguientes 2 líneas
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].toUpperCase();
          final nextMatch = curpPattern.firstMatch(nextLine);
          if (nextMatch != null) {
            return nextMatch.group(0) ?? '';
          }
        }
      }

      // Patrón 2: Buscar CURP en líneas que contengan solo el código (sin etiqueta)
      // Esto es común en T3 donde el CURP puede aparecer en una línea separada
      final match = curpPattern.firstMatch(line);
      if (match != null) {
        final curp = match.group(0) ?? '';
        // Validación adicional: verificar que la línea no contenga otros datos importantes
        if (!line.contains('VIGENCIA') &&
            !line.contains('EMISIÓN') &&
            !line.contains('EMISION') &&
            !line.contains('SECCIÓN') &&
            !line.contains('SECCION')) {
          return curp;
        }
      }

      // Patrón 3: Buscar patrones de CURP con posibles errores de OCR
      // Común en T3 donde la calidad de impresión puede variar
      final curpWithErrorsPattern = RegExp(
        r'\b[A-Z0-9]{4}\d{6}[HM][A-Z0-9]{5}\d{2}\b',
      );
      final errorMatch = curpWithErrorsPattern.firstMatch(line);
      if (errorMatch != null) {
        final potentialCurp = errorMatch.group(0) ?? '';
        // Aplicar correcciones comunes de OCR
        String correctedCurp = potentialCurp
            .replaceAll('0', 'O')
            .replaceAll('1', 'I')
            .replaceAll('5', 'S')
            .replaceAll('8', 'B');

        // Verificar si después de las correcciones coincide con el patrón CURP
        if (curpPattern.hasMatch(correctedCurp)) {
          return correctedCurp;
        }
      }
    }

    // Fallback: usar método estándar
    return _extractCurp(lines);
  }

  /// Extrae el CURP específicamente para credenciales t2
  static String _extractCurpT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Para t2, CURP está en la misma línea que la etiqueta
      if (line.contains('CURP')) {
        // Buscar patrón de CURP en la misma línea
        final match = RegExp(
          r'CURP\s+([A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9])',
        ).firstMatch(line);
        if (match != null) {
          return match.group(1) ?? '';
        }

        // Buscar cualquier patrón de CURP en la línea
        final fallbackMatch = RegExp(
          r'[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]',
        ).firstMatch(line);
        if (fallbackMatch != null) {
          return fallbackMatch.group(0) ?? '';
        }
      }
    }
    return '';
  }

  /// Extrae la fecha de nacimiento
  static String _extractFechaNacimiento(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta FECHA DE NACIMIENTO, buscar en líneas siguientes
      if (line.contains('FECHA DE NACIMIENTO') || line.contains('NACIMIENTO')) {
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          // Buscar patrón de fecha DD/MM/YYYY
          final match = RegExp(
            r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b',
          ).firstMatch(nextLine);
          if (match != null) {
            final day = match.group(1)?.padLeft(2, '0') ?? '';
            final month = match.group(2)?.padLeft(2, '0') ?? '';
            final year = match.group(3) ?? '';
            return '$day/$month/$year';
          }
        }
      }

      // También buscar directamente en la línea actual
      final match = RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b').firstMatch(line);
      if (match != null) {
        final day = match.group(1)?.padLeft(2, '0') ?? '';
        final month = match.group(2)?.padLeft(2, '0') ?? '';
        final year = match.group(3) ?? '';
        return '$day/$month/$year';
      }
    }
    return '';
  }

  /// Extrae la fecha de nacimiento específicamente para credenciales t3
  /// Optimizado para el formato específico de credenciales T3
  static String _extractFechaNacimientoT3(List<String> lines) {
    // Patrones de fecha comunes en T3
    final datePatterns = [
      RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b'), // DD/MM/YYYY
      RegExp(r'\b(\d{1,2})-(\d{1,2})-(\d{4})\b'), // DD-MM-YYYY
      RegExp(r'\b(\d{4})/(\d{1,2})/(\d{1,2})\b'), // YYYY/MM/DD
      RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b'), // YYYY-MM-DD
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Patrón 1: Buscar líneas que contengan "NACIMIENTO" o "NAC"
      if (line.contains('NACIMIENTO') || line.contains('NAC')) {
        // Buscar fecha en la misma línea
        for (final pattern in datePatterns) {
          final match = pattern.firstMatch(line);
          if (match != null &&
              ValidationUtils.isValidBirthDate(match.group(0) ?? '')) {
            return ValidationUtils.formatBirthDate(match.group(0) ?? '');
          }
        }

        // Buscar fecha en las siguientes 2 líneas
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j];
          for (final pattern in datePatterns) {
            final match = pattern.firstMatch(nextLine);
            if (match != null &&
                ValidationUtils.isValidBirthDate(match.group(0) ?? '')) {
              return ValidationUtils.formatBirthDate(match.group(0) ?? '');
            }
          }
        }
      }

      // Patrón 2: Buscar fechas que no sean de vigencia o emisión
      // Común en T3 donde la fecha puede aparecer sin etiqueta clara
      if (!line.contains('VIGENCIA') &&
          !line.contains('EMISIÓN') &&
          !line.contains('EMISION') &&
          !line.contains('REGISTRO')) {
        for (final pattern in datePatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final dateStr = match.group(0) ?? '';
            if (ValidationUtils.isValidBirthDate(dateStr)) {
              return ValidationUtils.formatBirthDate(dateStr);
            }
          }
        }
      }

      // Patrón 3: Buscar fechas con posibles errores de OCR
      // Común en T3 donde la calidad puede variar
      final ocrErrorPattern = RegExp(
        r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})\b',
      );
      final errorMatch = ocrErrorPattern.firstMatch(line);
      if (errorMatch != null) {
        final day = errorMatch.group(1) ?? '';
        final month = errorMatch.group(2) ?? '';
        final year = errorMatch.group(3) ?? '';
        final dateStr = '$day/$month/$year';

        if (ValidationUtils.isValidBirthDate(dateStr) &&
            !line.contains('VIGENCIA') &&
            !line.contains('EMISIÓN') &&
            !line.contains('EMISION')) {
          return ValidationUtils.formatBirthDate(dateStr);
        }
      }
    }

    // Fallback: usar método estándar
    return _extractFechaNacimiento(lines);
  }

  /// Extrae la fecha de nacimiento específicamente para credenciales t2
  /// Maneja el formato especial donde puede faltar "/" y necesita normalización numérica
  static String _extractFechaNacimientoT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta FECHA DE NACIMIENTO, buscar en líneas siguientes
      if (line.contains('FECHA DE NACIMIENTO') || line.contains('NACIMIENTO')) {
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          final processedDate = _processBirthDateT2(nextLine);
          if (processedDate.isNotEmpty) {
            return processedDate;
          }
        }
      }

      // También buscar directamente en la línea actual
      final processedDate = _processBirthDateT2(line);
      if (processedDate.isNotEmpty) {
        return processedDate;
      }
    }
    return '';
  }

  /// Procesa y normaliza una fecha de nacimiento para credenciales t2
  /// Maneja formatos como "1710/1997", "17101997", etc.
  static String _processBirthDateT2(String text) {
    if (text.isEmpty) return '';

    // Normalizar caracteres numéricos (OCR puede confundir algunos caracteres)
    String normalizedText = text
        .replaceAll(RegExp(r'[Oo]'), '0') // O -> 0
        .replaceAll(RegExp(r'[Il|]'), '1') // I, l, | -> 1
        .replaceAll(RegExp(r'[S]'), '5') // S -> 5 (en algunos casos)
        .replaceAll(RegExp(r'[B]'), '8'); // B -> 8 (en algunos casos)

    // Remover todos los caracteres que no sean dígitos
    String digitsOnly = normalizedText.replaceAll(RegExp(r'[^0-9]'), '');

    // Verificar si tenemos exactamente 8 dígitos (DDMMYYYY)
    if (digitsOnly.length == 8) {
      final day = digitsOnly.substring(0, 2);
      final month = digitsOnly.substring(2, 4);
      final year = digitsOnly.substring(4, 8);

      // Validar rangos básicos
      final dayInt = int.tryParse(day);
      final monthInt = int.tryParse(month);
      final yearInt = int.tryParse(year);

      if (dayInt != null &&
          monthInt != null &&
          yearInt != null &&
          dayInt >= 1 &&
          dayInt <= 31 &&
          monthInt >= 1 &&
          monthInt <= 12 &&
          yearInt >= 1900 &&
          yearInt <= 2100) {
        return '$day/$month/$year';
      }
    }

    // Buscar patrón de fecha con separadores existentes DD/MM/YYYY
    final match = RegExp(
      r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})\b',
    ).firstMatch(normalizedText);
    if (match != null) {
      final day = match.group(1)?.padLeft(2, '0') ?? '';
      final month = match.group(2)?.padLeft(2, '0') ?? '';
      final year = match.group(3) ?? '';

      // Validar rangos básicos
      final dayInt = int.tryParse(day);
      final monthInt = int.tryParse(month);
      final yearInt = int.tryParse(year);

      if (dayInt != null &&
          monthInt != null &&
          yearInt != null &&
          dayInt >= 1 &&
          dayInt <= 31 &&
          monthInt >= 1 &&
          monthInt <= 12 &&
          yearInt >= 1900 &&
          yearInt <= 2100) {
        return '$day/$month/$year';
      }
    }

    return '';
  }

  /// Extrae el sexo
  static String _extractSexo(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upperLine = line.toUpperCase();

      // Buscar patrones de sexo
      if (upperLine.contains('SEXO')) {
        // Verificar si H o M están en la misma línea
        if (upperLine.contains('SEXO H') || upperLine.contains('H')) {
          return 'H';
        } else if (upperLine.contains('SEXO M') || upperLine.contains('M')) {
          return 'M';
        }

        // Buscar en las siguientes 2 líneas
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim().toUpperCase();
          if (nextLine == 'H' || nextLine.contains('H')) {
            return 'H';
          } else if (nextLine == 'M' || nextLine.contains('M')) {
            return 'M';
          }
        }
      }

      // Buscar líneas que solo contengan H o M
      final trimmedLine = line.trim().toUpperCase();
      if (trimmedLine == 'H') {
        return 'H';
      } else if (trimmedLine == 'M') {
        return 'M';
      }
    }
    return '';
  }

  /// Extrae el año de registro
  static String _extractAnoRegistro(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta AÑO DE REGISTRO, buscar en líneas siguientes
      if (line.contains('AÑO DE REGISTRO') ||
          line.contains('ANO DE REGISTRO')) {
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          // Buscar patrón YYYY MM (año y mes)
          final match = RegExp(r'(20\d{2})\s+(\d{2})').firstMatch(nextLine);
          if (match != null) {
            return '${match.group(1)} ${match.group(2)}';
          }
          // Buscar solo año de 4 dígitos
          final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(nextLine);
          if (yearMatch != null) {
            return yearMatch.group(0) ?? '';
          }
        }
      }

      // Buscar patrón YYYY MM en cualquier línea
      final match = RegExp(r'(20\d{2})\s+(\d{2})').firstMatch(line);
      if (match != null && !line.contains('/')) {
        return '${match.group(1)} ${match.group(2)}';
      }
    }
    return '';
  }

  /// Extrae el año de registro específicamente para credenciales t3
  /// Optimizado para el formato específico de credenciales T3
  static String _extractAnoRegistroT3(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Patrón 1: Buscar líneas que contengan "REGISTRO" o "REG"
      if (line.contains('REGISTRO') || line.contains('REG')) {
        // Buscar año completo con código en la misma línea (formato: YYYY XX)
        final fullYearMatch = RegExp(
          r'\b(19|20)\d{2}\s+\d{2}\b',
        ).firstMatch(line);
        if (fullYearMatch != null) {
          final fullYear = fullYearMatch.group(0) ?? '';
          final yearPart = fullYear.split(' ')[0];
          final yearInt = int.tryParse(yearPart);
          if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
            return fullYear;
          }
        }

        // Si no encuentra el formato completo, buscar solo el año
        final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(line);
        if (yearMatch != null) {
          final year = yearMatch.group(0) ?? '';
          final yearInt = int.tryParse(year);
          if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
            return year;
          }
        }

        // Buscar año completo en las siguientes 2 líneas
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j];
          // Primero buscar formato completo YYYY XX
          final nextFullYearMatch = RegExp(
            r'\b(19|20)\d{2}\s+\d{2}\b',
          ).firstMatch(nextLine);
          if (nextFullYearMatch != null) {
            final fullYear = nextFullYearMatch.group(0) ?? '';
            final yearPart = fullYear.split(' ')[0];
            final yearInt = int.tryParse(yearPart);
            if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
              return fullYear;
            }
          }

          // Si no encuentra formato completo, buscar solo año
          final nextYearMatch = RegExp(
            r'\b(19|20)\d{2}\b',
          ).firstMatch(nextLine);
          if (nextYearMatch != null) {
            final year = nextYearMatch.group(0) ?? '';
            final yearInt = int.tryParse(year);
            if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
              return year;
            }
          }
        }
      }

      // Patrón 2: Buscar años que no sean de vigencia o nacimiento
      // Común en T3 donde el año de registro puede aparecer sin etiqueta clara
      if (!line.contains('VIGENCIA') &&
          !line.contains('NACIMIENTO') &&
          !line.contains('EMISIÓN') &&
          !line.contains('EMISION') &&
          !line.contains('/')) {
        // Primero buscar formato completo YYYY XX
        final fullYearMatch = RegExp(
          r'\b(19|20)\d{2}\s+\d{2}\b',
        ).firstMatch(line);
        if (fullYearMatch != null) {
          final fullYear = fullYearMatch.group(0) ?? '';
          final yearPart = fullYear.split(' ')[0];
          final yearInt = int.tryParse(yearPart);
          if (yearInt != null &&
              yearInt >= 1990 &&
              yearInt <= 2050 &&
              yearInt > 1970) {
            // Validación adicional: debe estar en una línea corta
            if (line.trim().length <= 20) {
              return fullYear;
            }
          }
        }

        // Si no encuentra formato completo, buscar solo año
        final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(line);
        if (yearMatch != null) {
          final year = yearMatch.group(0) ?? '';
          final yearInt = int.tryParse(year);
          // Validar rango y que no sea año de nacimiento típico
          if (yearInt != null &&
              yearInt >= 1990 &&
              yearInt <= 2050 &&
              yearInt > 1970) {
            // Evitar años de nacimiento comunes
            // Validación adicional: debe estar en una línea corta
            if (line.trim().length <= 15) {
              return year;
            }
          }
        }
      }

      // Patrón 3: Buscar patrones específicos de T3 como "AÑO YYYY XX" o "YYYY XX REG"
      final specificPatterns = [
        RegExp(r'AÑO\s+(19|20)\d{2}\s+\d{2}\b'), // AÑO YYYY XX
        RegExp(r'\b(19|20)\d{2}\s+\d{2}\s+REG'), // YYYY XX REG
        RegExp(r'REGISTRO\s+(19|20)\d{2}\s+\d{2}\b'), // REGISTRO YYYY XX
      ];

      for (final pattern in specificPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final fullYearMatch = RegExp(
            r'(19|20)\d{2}\s+\d{2}',
          ).firstMatch(match.group(0) ?? '');
          if (fullYearMatch != null) {
            final fullYear = fullYearMatch.group(0) ?? '';
            final yearPart = fullYear.split(' ')[0];
            final yearInt = int.tryParse(yearPart);
            if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
              return fullYear;
            }
          }
        }
      }

      // Patrones de fallback para formato simple
      final fallbackPatterns = [
        RegExp(r'AÑO\s+(19|20)\d{2}\b'),
        RegExp(r'\b(19|20)\d{2}\s+REG'),
        RegExp(r'REGISTRO\s+(19|20)\d{2}\b'),
      ];

      for (final pattern in fallbackPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final yearStr =
              RegExp(
                r'(19|20)\d{2}',
              ).firstMatch(match.group(0) ?? '')?.group(0) ??
              '';
          final yearInt = int.tryParse(yearStr);
          if (yearInt != null && yearInt >= 1950 && yearInt <= 2050) {
            return yearStr;
          }
        }
      }
    }

    // Fallback: usar método estándar
    return _extractAnoRegistro(lines);
  }

  /// Extrae el año de registro específicamente para credenciales t2 (misma línea)
  static String _extractAnoRegistroT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Para t2, buscar el patrón específico YYYY MM en la misma línea que CURP
      if (line.contains('CURP')) {
        // Buscar patrón YYYY MM (formato específico para t2: 2018 00)
        final match = RegExp(r'(20\d{2})\s+(\d{2})').firstMatch(line);
        if (match != null) {
          return '${match.group(1)} ${match.group(2)}';
        }
      }

      // También buscar en líneas que contengan año de registro
      if (line.contains('AÑO') ||
          line.contains('ANO') ||
          line.contains('REGISTRO')) {
        final match = RegExp(r'(20\d{2})\s+(\d{2})').firstMatch(line);
        if (match != null) {
          return '${match.group(1)} ${match.group(2)}';
        }
      }
    }
    return '';
  }

  /// Extrae la sección
  static String _extractSeccion(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta SECCIÓN, buscar en líneas siguientes
      if (line.contains('SECCIÓN') || line.contains('SECCION')) {
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          // Buscar número de sección (generalmente 4 dígitos)
          final match = RegExp(r'\b\d{4}\b').firstMatch(nextLine);
          if (match != null) {
            final section = match.group(0) ?? '';
            // Verificar que no sea un año
            if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
              return section;
            }
          }
        }
      }

      // Buscar número de sección en cualquier línea (evitando años)
      final match = RegExp(r'\b\d{4}\b').firstMatch(line);
      if (match != null) {
        final section = match.group(0) ?? '';
        // Verificar que no sea un año y no esté en contexto de fecha
        if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section) &&
            !line.contains('/')) {
          return section;
        }
      }
    }
    return '';
  }

  /// Extrae la sección específicamente para credenciales t3
  /// Optimizado para el formato específico de credenciales T3
  static String _extractSeccionT3(List<String> lines) {
    // Búsqueda específica para T3: patrones comunes en credenciales más nuevas
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Patrón 1: Buscar SECCIÓN seguida directamente de un número
      if (line.contains('SECCIÓN') || line.contains('SECCION')) {
        // Buscar número inmediatamente después de SECCIÓN
        final seccionPattern = RegExp(r'SECCI[ÓO]N\s+(\d{4})\b');
        final match = seccionPattern.firstMatch(line);
        if (match != null) {
          final section = match.group(1) ?? '';
          // Verificar que no sea un año
          if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
            return section;
          }
        }

        // Buscar en líneas siguientes si no está en la misma línea
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();
          final sectionMatch = RegExp(r'\b(\d{4})\b').firstMatch(nextLine);
          if (sectionMatch != null) {
            final section = sectionMatch.group(1) ?? '';
            // Verificar que no sea un año
            if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
              return section;
            }
          }
        }
      }

      // Patrón 2: Buscar líneas que contengan "SECCIÓN" y números en la misma línea
      // pero no necesariamente adyacentes (ej: "SECCIÓN ELECTORAL 1234")
      if (line.contains('SECCIÓN') || line.contains('SECCION')) {
        final allNumbers = RegExp(r'\b(\d{4})\b').allMatches(line);
        for (final match in allNumbers) {
          final section = match.group(1) ?? '';
          // Verificar que no sea un año y que esté en contexto de sección
          if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section) &&
              !line.contains('VIGENCIA') &&
              !line.contains('EMISIÓN') &&
              !line.contains('EMISION')) {
            return section;
          }
        }
      }

      // Patrón 3: Buscar números de 4 dígitos en líneas que no contengan fechas
      // Este es un patrón más agresivo para T3 donde la sección puede aparecer sin etiqueta
      if (!line.contains('/') &&
          !line.contains('VIGENCIA') &&
          !line.contains('EMISIÓN') &&
          !line.contains('EMISION') &&
          !line.contains('CURP') &&
          !line.contains('NACIMIENTO') &&
          !line.contains('REGISTRO')) {
        final sectionMatch = RegExp(r'\b(\d{4})\b').firstMatch(line);
        if (sectionMatch != null) {
          final section = sectionMatch.group(1) ?? '';
          // Verificar que no sea un año
          if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
            // Validación adicional: debe estar en una línea corta (probablemente solo la sección)
            if (line.trim().length <= 20) {
              return section;
            }
          }
        }
      }
    }

    // Fallback: usar método estándar
    return _extractSeccion(lines);
  }

  /// Extrae la sección específicamente para credenciales t2 (misma línea que municipio)
  static String _extractSeccionT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Para t2, sección está en la misma línea que municipio
      if ((line.contains('SECCIÓN') || line.contains('SECCION')) &&
          line.contains('MUNICIPIO')) {
        // Buscar número de sección en la misma línea
        final match = RegExp(r'\b(\d{4})\b').firstMatch(line);
        if (match != null) {
          final section = match.group(1) ?? '';
          // Verificar que no sea un año
          if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
            return section;
          }
        }
      }

      // También buscar en líneas que contengan ambas palabras clave
      if (line.contains('MUNICIPIO') &&
          (line.contains('SECCIÓN') || line.contains('SECCION'))) {
        final match = RegExp(r'\b(\d{4})\b').firstMatch(line);
        if (match != null) {
          final section = match.group(1) ?? '';
          if (!RegExp(r'^(19|20)\d{2}$').hasMatch(section)) {
            return section;
          }
        }
      }
    }
    return '';
  }

  /// Extrae la vigencia
  static String _extractVigencia(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Si encontramos la etiqueta VIGENCIA, buscar en líneas siguientes
      if (line.contains('VIGENCIA')) {
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          // Buscar patrón de vigencia (YYYY YYYY)
          final match = RegExp(r'(20\d{2})\s+(20\d{2})').firstMatch(nextLine);
          if (match != null) {
            return '${match.group(1)} ${match.group(2)}';
          }
          // Buscar patrón con guión
          final matchWithDash = RegExp(
            r'(20\d{2})\s*-\s*(20\d{2})',
          ).firstMatch(nextLine);
          if (matchWithDash != null) {
            return '${matchWithDash.group(1)} ${matchWithDash.group(2)}';
          }
        }
      }

      // Buscar patrón de vigencia en cualquier línea
      final match = RegExp(r'(20\d{2})\s+(20\d{2})').firstMatch(line);
      if (match != null && !line.contains('/')) {
        return '${match.group(1)} ${match.group(2)}';
      }
    }
    return '';
  }

  /// Extrae la vigencia específicamente para credenciales t3
  /// Optimizado para el formato específico de credenciales T3
  static String _extractVigenciaT3(List<String> lines) {
    // Primero intentar con el método de similitud mejorado
    final vigenciaWithSimilarity = _extractVigenciaWithSimilarity(lines);
    if (vigenciaWithSimilarity.isNotEmpty) {
      return _cleanVigenciaT3(vigenciaWithSimilarity);
    }

    // Búsqueda específica para T3: patrones comunes en credenciales más nuevas
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Buscar líneas que contengan VIGENCIA y extraer año inmediatamente después
      if (line.contains('VIGENCIA')) {
        // Patrón 1: VIGENCIA seguida de un año (formato común en T3)
        final vigenciaPattern = RegExp(r'VIGENCIA\s+(\d{4})\b');
        final match = vigenciaPattern.firstMatch(line);
        if (match != null) {
          return _cleanVigenciaT3(match.group(1) ?? '');
        }

        // Patrón 2: VIGENCIA con rango de años (YYYY-YYYY)
        final rangePattern = RegExp(r'VIGENCIA\s+(\d{4})\s*-\s*(\d{4})');
        final rangeMatch = rangePattern.firstMatch(line);
        if (rangeMatch != null) {
          return _cleanVigenciaT3(
            '${rangeMatch.group(1)}-${rangeMatch.group(2)}',
          );
        }

        // Patrón 3: Buscar en líneas siguientes si no está en la misma línea
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();

          // Buscar año de 4 dígitos
          final yearPattern = RegExp(r'\b(20\d{2})\b');
          final yearMatch = yearPattern.firstMatch(nextLine);
          if (yearMatch != null) {
            return _cleanVigenciaT3(yearMatch.group(1) ?? '');
          }

          // Buscar rango de años
          final nextRangePattern = RegExp(r'(\d{4})\s*-\s*(\d{4})');
          final nextRangeMatch = nextRangePattern.firstMatch(nextLine);
          if (nextRangeMatch != null) {
            return _cleanVigenciaT3(
              '${nextRangeMatch.group(1)}-${nextRangeMatch.group(2)}',
            );
          }
        }
      }

      // Búsqueda de patrones de vigencia sin etiqueta explícita
      // Común en T3 donde la vigencia puede aparecer sin la palabra "VIGENCIA"
      if (!line.contains('/') &&
          !line.contains('CURP') &&
          !line.contains('NACIMIENTO')) {
        // Buscar patrón de dos años consecutivos (formato YYYY YYYY)
        final doubleYearPattern = RegExp(r'\b(20\d{2})\s+(20\d{2})\b');
        final doubleMatch = doubleYearPattern.firstMatch(line);
        if (doubleMatch != null) {
          final year1 = int.parse(doubleMatch.group(1)!);
          final year2 = int.parse(doubleMatch.group(2)!);
          // Validar que sea un rango lógico de vigencia (diferencia de 5-15 años)
          if (year2 > year1 && (year2 - year1) >= 5 && (year2 - year1) <= 15) {
            return _cleanVigenciaT3(
              '${doubleMatch.group(1)}-${doubleMatch.group(2)}',
            );
          }
        }
      }
    }

    // Fallback: usar método estándar
    final fallbackVigencia = _extractVigencia(lines);
    return fallbackVigencia.isNotEmpty
        ? _cleanVigenciaT3(fallbackVigencia)
        : fallbackVigencia;
  }

  /// Limpia la vigencia T3 eliminando espacios y manteniendo solo números y guión
  static String _cleanVigenciaT3(String vigencia) {
    if (vigencia.isEmpty) return vigencia;

    // Eliminar todos los espacios y caracteres que no sean números o guión
    final cleaned = vigencia.replaceAll(RegExp(r'[^0-9-]'), '');

    // Validar que tenga el formato correcto YYYY-YYYY
    final formatMatch = RegExp(r'^(\d{4})-(\d{4})$').firstMatch(cleaned);
    if (formatMatch != null) {
      return cleaned;
    }

    // Si solo tiene números, intentar formar el formato YYYY-YYYY
    final numbersOnly = cleaned.replaceAll('-', '');
    if (numbersOnly.length == 8) {
      return '${numbersOnly.substring(0, 4)}-${numbersOnly.substring(4, 8)}';
    }

    // Si tiene formato YYYY, devolverlo tal como está
    if (RegExp(r'^\d{4}$').hasMatch(cleaned)) {
      return cleaned;
    }

    return vigencia; // Devolver original si no se puede limpiar
  }

  /// Extrae la vigencia específicamente para credenciales t2 (misma línea que localidad y emisión)
  static String _extractVigenciaT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Para t2, vigencia está en la misma línea que localidad y emisión
      if (line.contains('VIGENCIA') &&
          (line.contains('LOCALIDAD') ||
              line.contains('EMISIÓN') ||
              line.contains('EMISION'))) {
        // Buscar patrón de vigencia (YYYY YYYY) en la misma línea
        final match = RegExp(r'(20\d{2})\s+(20\d{2})').firstMatch(line);
        if (match != null) {
          return '${match.group(1)} ${match.group(2)}';
        }

        // Buscar patrón con guión
        final matchWithDash = RegExp(
          r'(20\d{2})\s*-\s*(20\d{2})',
        ).firstMatch(line);
        if (matchWithDash != null) {
          return '${matchWithDash.group(1)} ${matchWithDash.group(2)}';
        }

        // Buscar un solo año después de VIGENCIA (caso específico para t2)
        final vigenciaIndex = line.indexOf('VIGENCIA');
        if (vigenciaIndex != -1) {
          final afterVigencia = line.substring(
            vigenciaIndex + 8,
          ); // 8 = longitud de "VIGENCIA"
          final singleYearMatch = RegExp(
            r'\b(20\d{2})\b',
          ).firstMatch(afterVigencia);
          if (singleYearMatch != null) {
            return singleYearMatch.group(1) ?? '';
          }
        }
      }

      // También buscar en líneas que contengan las palabras clave
      if ((line.contains('LOCALIDAD') ||
              line.contains('EMISIÓN') ||
              line.contains('EMISION')) &&
          line.contains('VIGENCIA')) {
        final match = RegExp(r'(20\d{2})\s+(20\d{2})').firstMatch(line);
        if (match != null) {
          return '${match.group(1)} ${match.group(2)}';
        }

        // Buscar un solo año después de VIGENCIA como fallback
        final vigenciaIndex = line.indexOf('VIGENCIA');
        if (vigenciaIndex != -1) {
          final afterVigencia = line.substring(vigenciaIndex + 8);
          final singleYearMatch = RegExp(
            r'\b(20\d{2})\b',
          ).firstMatch(afterVigencia);
          if (singleYearMatch != null) {
            return singleYearMatch.group(1) ?? '';
          }
        }
      }
    }
    return '';
  }

  /// Corrige errores comunes de OCR
  static String correctOcrErrors(String text) {
    final corrections = {'0': 'O', '1': 'I', '5': 'S', '8': 'B', '@': 'A'};

    String corrected = text;
    corrections.forEach((wrong, correct) {
      corrected = corrected.replaceAll(wrong, correct);
    });

    return corrected;
  }

  /// Valida si los datos extraídos son suficientes
  static bool validateExtractedData(CredencialIneModel credencial) {
    // Campos mínimos requeridos para considerar válida la extracción
    return credencial.nombre.isNotEmpty ||
        credencial.curp.isNotEmpty ||
        credencial.claveElector.isNotEmpty;
  }

  /// Extrae la vigencia usando algoritmos de similitud para manejar variantes OCR
  static String _extractVigenciaWithSimilarity(List<String> lines) {
    final vigenciaLabels = [
      'VIGENCIA',
      'VIGENC',
      'VIGEN',
      'IGENCIA',
      'GENCIA',
      'VIGENT',
      'VIGENCI',
      'VGENCIA', // Variante donde falta 'I' (vGENCIA -> VGENCIA)
    ];

    // Búsqueda específica para el caso "SECCIÓN IGENCIA" o similar
    for (int i = 0; i < lines.length; i++) {
      final originalLine = lines[i].trim();
      final line = originalLine.toUpperCase();

      // Detectar líneas que contengan tanto SECCIÓN como alguna variante de VIGENCIA
      if (line.contains('SECCIÓN') || line.contains('SECCION')) {
        for (final label in vigenciaLabels) {
          final normalizedLabel = StringSimilarityUtils.normalizeOcrCharacters(
            label,
          );
          final normalizedLine = StringSimilarityUtils.normalizeOcrCharacters(
            line,
          );

          // Comparar etiqueta normalizada con contenido normalizado
          final labelIndex = normalizedLine.indexOf(normalizedLabel);
          if (labelIndex != -1) {
            // Buscar año inmediatamente después de la etiqueta en la misma línea
            final afterLabel =
                normalizedLine
                    .substring(labelIndex + normalizedLabel.length)
                    .trim();
            final yearAfterLabelPattern = RegExp(r'^\s*(\d{4})\b');
            final yearMatch = yearAfterLabelPattern.firstMatch(afterLabel);
            if (yearMatch != null) {
              return yearMatch.group(1) ?? '';
            }

            // Buscar en líneas siguientes el patrón "NÚMERO YYYY-YYYY" (formato tradicional)
            for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
              final nextLine = lines[j].trim();
              final sectionVigenciaPattern = RegExp(r'\b\d+\s+(\d{4}-\d{4})\b');
              final sectionMatch = sectionVigenciaPattern.firstMatch(nextLine);
              if (sectionMatch != null) {
                return sectionMatch.group(1) ?? '';
              }
            }
          }
        }
      }
    }

    // Búsqueda general en todas las líneas para casos como "LOCALIDAD 0001 EMISIÓN 2017 vGENCIA 2027"
    for (int i = 0; i < lines.length; i++) {
      final originalLine = lines[i].trim();
      final line = originalLine.toUpperCase();

      // Buscar variantes de VIGENCIA en la línea
      for (final label in vigenciaLabels) {
        final normalizedLabel = StringSimilarityUtils.normalizeOcrCharacters(
          label,
        );
        final normalizedLine = StringSimilarityUtils.normalizeOcrCharacters(
          line,
        );

        final labelIndex = normalizedLine.indexOf(normalizedLabel);
        if (labelIndex != -1) {
          // Buscar año inmediatamente después de la etiqueta en la misma línea
          final afterLabel =
              normalizedLine
                  .substring(labelIndex + normalizedLabel.length)
                  .trim();
          final yearAfterLabelPattern = RegExp(r'^\s*(\d{4})\b');
          final yearMatch = yearAfterLabelPattern.firstMatch(afterLabel);
          if (yearMatch != null) {
            return yearMatch.group(1) ?? '';
          }
        }
      }

      // También buscar usando el patrón original 'vGENCIA' directamente en la línea original
      if (originalLine.toUpperCase().contains('VGENCIA') ||
          originalLine.contains('vGENCIA')) {
        // Buscar año después de vGENCIA o VGENCIA
        final vgenciaPattern = RegExp(
          r'v?GENCIA\s+(\d{4})',
          caseSensitive: false,
        );
        final match = vgenciaPattern.firstMatch(originalLine);
        if (match != null) {
          return match.group(1) ?? '';
        }
      }
    }

    // Fallback: usar similitud de cadenas para casos no detectados
    final result = _findLabelWithSimilarity(
      lines,
      vigenciaLabels,
      threshold:
          0.5, // Umbral más bajo para vigencia debido a errores comunes de OCR
    );

    if (result['found'] == true) {
      final index = result['index'] as int;
      final line = lines[index].trim();
      final foundLabel = result['label'] as String;

      // Caso específico: buscar año inmediatamente después de la etiqueta VIGENCIA en la misma línea
      // Ejemplo: "LOCALIDAD 0001 EMISIÓN 2017 vGENCIA 2027"
      final normalizedLine = StringSimilarityUtils.normalizeOcrCharacters(line);
      final normalizedLabel = StringSimilarityUtils.normalizeOcrCharacters(
        foundLabel,
      );

      final labelIndex = normalizedLine.toUpperCase().indexOf(
        normalizedLabel.toUpperCase(),
      );
      if (labelIndex != -1) {
        final afterLabel =
            normalizedLine
                .substring(labelIndex + normalizedLabel.length)
                .trim();
        // Buscar un año de 4 dígitos inmediatamente después de la etiqueta
        final yearAfterLabelPattern = RegExp(r'^\s*(\d{4})\b');
        final yearMatch = yearAfterLabelPattern.firstMatch(afterLabel);
        if (yearMatch != null) {
          return yearMatch.group(1) ?? '';
        }
      }

      // Buscar fecha en la misma línea (patrones tradicionales)
      final datePattern = RegExp(
        r'\b(\d{4}-\d{4}|\d{2}[/-]\d{2}[/-]\d{4}|\d{4}[/-]\d{2}[/-]\d{2})\b',
      );
      final match = datePattern.firstMatch(line);
      if (match != null) {
        return match.group(0) ?? '';
      }

      // Buscar en líneas siguientes (hasta 2 líneas)
      for (int i = index + 1; i < lines.length && i <= index + 2; i++) {
        final nextLine = lines[i].trim();

        // Caso especial: línea con formato "NÚMERO YYYY-YYYY" (ej: "2438 2023-2033")
        final sectionVigenciaPattern = RegExp(r'\b\d+\s+(\d{4}-\d{4})\b');
        final sectionMatch = sectionVigenciaPattern.firstMatch(nextLine);
        if (sectionMatch != null) {
          return sectionMatch.group(1) ?? ''; // Retorna solo la parte YYYY-YYYY
        }

        // Búsqueda normal de fechas
        final nextMatch = datePattern.firstMatch(nextLine);
        if (nextMatch != null) {
          return nextMatch.group(0) ?? '';
        }
      }
    }

    return '';
  }

  /// Extrae información adicional usando similitud de cadenas
  static Map<String, String> extractAdditionalInfoWithSimilarity(
    List<String> lines,
  ) {
    final info = <String, String>{};

    // Extraer vigencia con similitud
    final vigencia = _extractVigenciaWithSimilarity(lines);
    if (vigencia.isNotEmpty) {
      info['vigencia'] = vigencia;
    }

    // Extraer año de registro usando similitud
    final registroLabels = ['AÑO', 'ANO', 'REGISTRO', 'REG'];
    final registroResult = _findLabelWithSimilarity(
      lines,
      registroLabels,
      threshold: 0.7,
    );

    if (registroResult['found'] == true) {
      final index = registroResult['index'] as int;
      final line = lines[index].trim();
      final yearPattern = RegExp(r'\b(19|20)\d{2}\b');
      final match = yearPattern.firstMatch(line);
      if (match != null) {
        info['año_registro'] = match.group(0) ?? '';
      }
    }

    // Extraer número de emisión usando similitud
    final emisionLabels = ['EMISIÓN', 'EMISION', 'EMIS', 'NUM'];
    final emisionResult = _findLabelWithSimilarity(
      lines,
      emisionLabels,
      threshold: 0.7,
    );

    if (emisionResult['found'] == true) {
      final index = emisionResult['index'] as int;
      final line = lines[index].trim();
      final numPattern = RegExp(r'\b\d{2,4}\b');
      final match = numPattern.firstMatch(line);
      if (match != null) {
        info['numero_emision'] = match.group(0) ?? '';
      }
    }

    return info;
  }

  /// Detecta el tipo de credencial basado en la presencia de campos específicos
  static String _detectCredentialType(List<String> lines) {
    final upperLines = lines.map((line) => line.toUpperCase()).toList();

    // Contar cuántas etiquetas de t1 están presentes
    int tipo1FieldsFound = 0;
    for (final label in _tipo1Labels) {
      if (upperLines.any((line) => line.contains(label))) {
        tipo1FieldsFound++;
      }
    }

    // Contar cuántas etiquetas de t2 están presentes
    int tipo2FieldsFound = 0;
    for (final label in _tipo2Labels) {
      if (upperLines.any((line) => line.contains(label))) {
        tipo2FieldsFound++;
      }
    }

    // Lógica de detección:
    // t1: tiene EDAD o FOLIO -> retorna 't1'
    // t2: tiene ESTADO, MUNICIPIO o LOCALIDAD (pero no EDAD/FOLIO) -> retorna 't2'
    // t3: no tiene ninguna de las etiquetas anteriores -> retorna 't3'
    if (tipo1FieldsFound > 0) {
      return _credentialTypeConfig['Tipo 1']!['code'];
    } else if (tipo2FieldsFound > 0) {
      return _credentialTypeConfig['Tipo 2']!['code'];
    } else {
      return _credentialTypeConfig['Tipo 3']!['code'];
    }
  }

  /// Extrae el estado de la credencial (solo para t2)
  static String _extractEstado(List<String> lines) {
    return _extractFieldAfterLabel(lines, ['ESTADO']);
  }

  /// Extrae el municipio de la credencial (solo para t2)
  static String _extractMunicipio(List<String> lines) {
    return _extractFieldAfterLabel(lines, ['MUNICIPIO']);
  }

  /// Extrae el código de municipio específicamente para credenciales t2
  /// Maneja el formato "MUNICIPIO 099 SECCIÓN 2530" extrayendo solo "099"
  static String _extractMunicipioT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Buscar línea que contenga tanto MUNICIPIO como SECCIÓN
      if (line.contains('MUNICIPIO') &&
          (line.contains('SECCIÓN') || line.contains('SECCION'))) {
        // Extraer el código numérico del municipio
        final municipioCode = _extractMunicipioCode(line);
        if (municipioCode.isNotEmpty) {
          return municipioCode;
        }
      }
    }
    return '';
  }

  /// Extrae el código numérico del municipio de una línea
  /// Ejemplo: "MUNICIPIO 099 SECCIÓN 2530" -> "099"
  static String _extractMunicipioCode(String line) {
    // Buscar patrón: MUNICIPIO seguido de espacio y números
    final match = RegExp(r'MUNICIPIO\s+(\d{3})').firstMatch(line);
    if (match != null) {
      return match.group(1) ?? '';
    }

    // Patrón alternativo: buscar números después de MUNICIPIO
    final parts = line.split('MUNICIPIO');
    if (parts.length > 1) {
      final afterMunicipio = parts[1].trim();
      // Extraer los primeros 3 dígitos encontrados
      final digitMatch = RegExp(r'(\d{3})').firstMatch(afterMunicipio);
      if (digitMatch != null) {
        return digitMatch.group(1) ?? '';
      }
    }

    return '';
  }

  /// Extrae la localidad de la credencial (solo para t2)
  static String _extractLocalidad(List<String> lines) {
    return _extractFieldAfterLabel(lines, ['LOCALIDAD']);
  }

  /// Extrae el código de localidad específicamente para credenciales t2
  /// Maneja el formato "LOCALIDAD 0001 EMISIÓN 2016 VIGENCIA 2026" extrayendo solo "0001"
  static String _extractLocalidadT2(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Buscar línea que contenga LOCALIDAD junto con VIGENCIA o EMISIÓN
      if (line.contains('LOCALIDAD') &&
          (line.contains('VIGENCIA') ||
              line.contains('EMISIÓN') ||
              line.contains('EMISION'))) {
        // Extraer el código numérico de la localidad
        final localidadCode = _extractLocalidadCode(line);
        if (localidadCode.isNotEmpty) {
          return localidadCode;
        }
      }
    }
    return '';
  }

  /// Extrae el código numérico de la localidad de una línea
  /// Ejemplo: "LOCALIDAD 0001 EMISIÓN 2016 VIGENCIA 2026" -> "0001"
  static String _extractLocalidadCode(String line) {
    // Buscar patrón: LOCALIDAD seguido de espacio y números
    final match = RegExp(r'LOCALIDAD\s+(\d{4})').firstMatch(line);
    if (match != null) {
      return match.group(1) ?? '';
    }

    // Patrón alternativo: buscar números después de LOCALIDAD
    final parts = line.split('LOCALIDAD');
    if (parts.length > 1) {
      final afterLocalidad = parts[1].trim();
      // Extraer los primeros 4 dígitos encontrados
      final digitMatch = RegExp(r'(\d{4})').firstMatch(afterLocalidad);
      if (digitMatch != null) {
        return digitMatch.group(1) ?? '';
      }
    }

    return '';
  }

  /// Método auxiliar para extraer un campo después de encontrar su etiqueta
  static String _extractFieldAfterLabel(
    List<String> lines,
    List<String> labels,
  ) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      for (final label in labels) {
        if (line.contains(label)) {
          // Buscar el valor en la misma línea después de la etiqueta
          final parts = line.split(label);
          if (parts.length > 1) {
            final value = parts[1].trim();
            if (value.isNotEmpty) {
              return _filterReferenceLabels([value]).isNotEmpty
                  ? _filterReferenceLabels([value]).first
                  : value;
            }
          }

          // Si no hay valor en la misma línea, buscar en la siguiente
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1].trim();
            if (nextLine.isNotEmpty) {
              final filteredData = _filterReferenceLabels([nextLine]);
              if (filteredData.isNotEmpty) {
                return filteredData.first;
              }
            }
          }
          break;
        }
      }
    }
    return '';
  }
}
