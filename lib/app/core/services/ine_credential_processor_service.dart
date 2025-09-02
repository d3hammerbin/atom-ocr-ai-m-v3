import '../../../app/data/models/credencial_ine_model.dart';
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
    'SEXO',
    'AÑO DE REGISTRO',
    'FECHA DE NACIMIENTO',
    // 'SECCIÓN', //
    // 'VIGENCIA', // Removido para permitir extracción de vigencia
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

  /// Etiquetas específicas para credenciales Tipo 1 (más antiguas)
  static const List<String> _tipo1Labels = [
    'EDAD',
    'FOLIO',
  ];

  /// Etiquetas específicas para credenciales Tipo 2
  static const List<String> _tipo2Labels = [
    'ESTADO',
    'MUNICIPIO',
    'LOCALIDAD',
  ];

  /// Verifica si el texto extraído corresponde a una credencial INE
  static bool isIneCredential(String extractedText) {
    final upperText = extractedText.toUpperCase();
    return _ineKeywords.any((keyword) => upperText.contains(keyword));
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

    // Filtrar líneas no deseadas
    final filteredLines = _filterUnwantedText(lines);

    // Extraer información adicional usando similitud de cadenas
    final additionalInfo = extractAdditionalInfoWithSimilarity(lines);

    // Detectar tipo de credencial
    final tipoCredencial = _detectCredentialType(lines);

    // Extraer campos específicos
    return CredencialIneModel(
      nombre: _extractNombre(filteredLines),
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
      estado: tipoCredencial == 'Tipo 2' ? _extractEstado(filteredLines) : '',
      municipio: tipoCredencial == 'Tipo 2' ? _extractMunicipio(filteredLines) : '',
      localidad: tipoCredencial == 'Tipo 2' ? _extractLocalidad(filteredLines) : '',
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
        if (line.contains(label)) {
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

        final result = StringSimilarityUtils.findBestMatch(
          word,
          targetLabels,
          threshold: threshold,
          useJaroWinkler: true,
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
      final line = lines[i].toUpperCase();

      // Buscar "CREDENCIAL" o "VOTAR" como punto de referencia
      if (line.contains('CREDENCIAL') || line.contains('VOTAR')) {
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
    ];

    // Búsqueda específica para el caso "SECCIÓN IGENCIA" o similar
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toUpperCase();

      // Detectar líneas que contengan tanto SECCIÓN como alguna variante de VIGENCIA
      if (line.contains('SECCIÓN') || line.contains('SECCION')) {
        for (final label in vigenciaLabels) {
          if (line.contains(label)) {
            // Buscar en líneas siguientes el patrón "NÚMERO YYYY-YYYY"
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

    final result = _findLabelWithSimilarity(
      lines,
      vigenciaLabels,
      threshold:
          0.5, // Umbral más bajo para vigencia debido a errores comunes de OCR
    );

    if (result['found'] == true) {
      final index = result['index'] as int;

      // Buscar fecha en la misma línea
      final line = lines[index].trim();
      // Patrón actualizado para incluir formato YYYY-YYYY y fechas tradicionales
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
    
    // Contar cuántas etiquetas de Tipo 1 están presentes
    int tipo1FieldsFound = 0;
    for (final label in _tipo1Labels) {
      if (upperLines.any((line) => line.contains(label))) {
        tipo1FieldsFound++;
      }
    }
    
    // Contar cuántas etiquetas de Tipo 2 están presentes
    int tipo2FieldsFound = 0;
    for (final label in _tipo2Labels) {
      if (upperLines.any((line) => line.contains(label))) {
        tipo2FieldsFound++;
      }
    }
    
    // Lógica de detección:
    // Tipo 1: tiene EDAD o FOLIO
    // Tipo 2: tiene ESTADO, MUNICIPIO o LOCALIDAD (pero no EDAD/FOLIO)
    // Tipo 3: no tiene ninguna de las etiquetas anteriores
    if (tipo1FieldsFound > 0) {
      return 'Tipo 1';
    } else if (tipo2FieldsFound > 0) {
      return 'Tipo 2';
    } else {
      return 'Tipo 3';
    }
  }

  /// Extrae el estado de la credencial (solo para Tipo 2)
  static String _extractEstado(List<String> lines) {
    return _extractFieldAfterLabel(lines, ['ESTADO']);
  }

  /// Extrae el municipio de la credencial (solo para Tipo 2)
  static String _extractMunicipio(List<String> lines) {
    return _extractFieldAfterLabel(lines, ['MUNICIPIO']);
  }

  /// Extrae la localidad de la credencial (solo para Tipo 2)
  static String _extractLocalidad(List<String> lines) {
    return _extractFieldAfterLabel(lines, ['LOCALIDAD']);
  }

  /// Método auxiliar para extraer un campo después de encontrar su etiqueta
  static String _extractFieldAfterLabel(List<String> lines, List<String> labels) {
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
