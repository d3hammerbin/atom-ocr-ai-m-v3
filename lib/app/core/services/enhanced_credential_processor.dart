import 'ine_credential_processor_service.dart';
import 'logger_service.dart';
import '../../../app/data/models/credencial_ine_model.dart';
import '../utils/string_similarity_utils.dart';
import '../utils/validation_utils.dart';

/// Procesador mejorado de credenciales que aborda problemas específicos
/// como la confusión entre números de sección y domicilio
class EnhancedCredentialProcessor {
  static const String _tag = 'EnhancedProcessor';

  /// Procesa una credencial con validaciones mejoradas para evitar confusiones
  /// entre sección y domicilio
  static CredencialIneModel processCredentialWithValidation(
    String extractedText, {
    Map<String, String> additionalInfo = const {},
  }) {
    print('🔧 [$_tag] Iniciando procesamiento mejorado de credencial');
    
    // Primero usar el procesador estándar
    final standardResult = IneCredentialProcessorService.processCredentialText(
      extractedText,
    );
    
    print('📋 [$_tag] Resultado estándar - Domicilio: "${standardResult.domicilio}", Sección: "${standardResult.seccion}"');
    
    // Aplicar validaciones y correcciones mejoradas
    final enhancedResult = _applyEnhancedValidations(extractedText, standardResult);
    
    print('✅ [$_tag] Resultado mejorado - Domicilio: "${enhancedResult.domicilio}", Sección: "${enhancedResult.seccion}"');
    
    return enhancedResult;
  }
  
  /// Aplica validaciones mejoradas para corregir problemas comunes
  static CredencialIneModel _applyEnhancedValidations(
    String extractedText,
    CredencialIneModel standardResult,
  ) {
    final lines = extractedText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    // Análisis mejorado de sección y domicilio
    final sectionDomicilioAnalysis = _analyzeSectionDomicilioConflict(lines, standardResult);
    
    String correctedDomicilio = standardResult.domicilio;
    String correctedSeccion = standardResult.seccion;
    
    // Aplicar correcciones si se detectan problemas
    if (sectionDomicilioAnalysis['has_conflict'] == true) {
      print('⚠️ [$_tag] Conflicto detectado entre sección y domicilio');
      
      correctedDomicilio = sectionDomicilioAnalysis['corrected_domicilio'] ?? standardResult.domicilio;
      correctedSeccion = sectionDomicilioAnalysis['corrected_seccion'] ?? standardResult.seccion;
      
      print('🔧 [$_tag] Domicilio corregido: "$correctedDomicilio"');
      print('🔧 [$_tag] Sección corregida: "$correctedSeccion"');
    }
    
    return standardResult.copyWith(
      domicilio: correctedDomicilio,
      seccion: correctedSeccion,
    );
  }
  
  /// Analiza conflictos específicos entre sección y domicilio
  static Map<String, dynamic> _analyzeSectionDomicilioConflict(
    List<String> lines,
    CredencialIneModel standardResult,
  ) {
    print('🔍 [$_tag] Analizando conflictos sección-domicilio...');
    
    final analysis = {
      'has_conflict': false,
      'corrected_domicilio': null,
      'corrected_seccion': null,
      'conflict_details': <String>[],
    };
    
    // Extraer todos los números de 4 dígitos con su contexto
    final fourDigitNumbers = <Map<String, dynamic>>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upperLine = line.toUpperCase();
      final matches = RegExp(r'\b(\d{4})\b').allMatches(line);
      
      for (final match in matches) {
        final number = match.group(1) ?? '';
        final isYear = RegExp(r'^(19|20)\d{2}\$').hasMatch(number);
        
        if (!isYear) {
          fourDigitNumbers.add({
            'number': number,
            'line_index': i,
            'line_content': line,
            'context': _determineNumberContext(upperLine),
            'in_domicilio_section': _isInDomicilioSection(lines, i),
            'in_seccion_section': _isInSeccionSection(lines, i),
          });
        }
      }
    }
    
    print('🔢 [$_tag] Números de 4 dígitos encontrados: ${fourDigitNumbers.length}');
    
    // Detectar si hay números en el domicilio que deberían ser sección
    final domicilioNumbers = _extractNumbersFromDomicilio(standardResult.domicilio);
    final seccionInDomicilio = fourDigitNumbers.where((num) => 
        domicilioNumbers.contains(num['number']) && 
        (num['context'] == 'seccion_context' || num['in_seccion_section'] == true)
    ).toList();
    
    if (seccionInDomicilio.isNotEmpty) {
      analysis['has_conflict'] = true;
      (analysis['conflict_details'] as List<String>).add('Números de sección encontrados en domicilio');
      
      // Corregir domicilio removiendo números de sección
      String correctedDomicilio = standardResult.domicilio;
      String correctedSeccion = standardResult.seccion;
      
      for (final conflictNum in seccionInDomicilio) {
        final number = conflictNum['number'];
        print('🔧 [$_tag] Removiendo "$number" del domicilio (es sección)');
        
        // Remover el número del domicilio
        correctedDomicilio = correctedDomicilio.replaceAll(number, '').trim();
        correctedDomicilio = correctedDomicilio.replaceAll(RegExp(r'\s+'), ' ').trim();
        
        // Si no hay sección o la sección actual es incorrecta, usar este número
        if (correctedSeccion.isEmpty || !_isValidSectionNumber(correctedSeccion)) {
          correctedSeccion = number;
          print('✅ [$_tag] Asignando "$number" como sección');
        }
      }
      
      analysis['corrected_domicilio'] = correctedDomicilio;
      analysis['corrected_seccion'] = correctedSeccion;
    }
    
    // Detectar si la sección actual está en contexto de domicilio
    if (standardResult.seccion.isNotEmpty) {
      final seccionInDomicilioContext = fourDigitNumbers.where((num) => 
          num['number'] == standardResult.seccion && 
          (num['context'] == 'domicilio_context' || num['in_domicilio_section'] == true)
      ).toList();
      
      if (seccionInDomicilioContext.isNotEmpty) {
        analysis['has_conflict'] = true;
        (analysis['conflict_details'] as List<String>).add('Sección actual encontrada en contexto de domicilio');
        
        // Buscar una sección alternativa más apropiada
        final betterSectionCandidates = fourDigitNumbers.where((num) => 
            num['number'] != standardResult.seccion &&
            (num['context'] == 'seccion_context' || num['in_seccion_section'] == true)
        ).toList();
        
        if (betterSectionCandidates.isNotEmpty) {
          final newSection = betterSectionCandidates.first['number'];
          print('🔧 [$_tag] Cambiando sección de "${standardResult.seccion}" a "$newSection"');
          analysis['corrected_seccion'] = newSection;
        }
      }
    }
    
    return analysis;
  }
  
  /// Determina el contexto de un número basado en la línea
  static String _determineNumberContext(String upperLine) {
    if (upperLine.contains('DOMICILIO')) return 'domicilio_context';
    if (upperLine.contains('SECCIÓN') || upperLine.contains('SECCION')) return 'seccion_context';
    if (upperLine.contains('MUNICIPIO')) return 'municipio_context';
    if (upperLine.contains('CALLE') || upperLine.contains('AV ') || upperLine.contains('COL ')) return 'address_context';
    if (upperLine.contains('VIGENCIA')) return 'vigencia_context';
    if (upperLine.contains('/')) return 'date_context';
    return 'unknown_context';
  }
  
  /// Verifica si una línea está en la sección de domicilio
  static bool _isInDomicilioSection(List<String> lines, int lineIndex) {
    // Buscar hacia atrás hasta encontrar la etiqueta DOMICILIO
    for (int i = lineIndex; i >= 0 && i >= lineIndex - 5; i--) {
      final line = lines[i].toUpperCase();
      if (line.contains('DOMICILIO')) {
        return true;
      }
      // Si encontramos otra etiqueta principal, no estamos en sección de domicilio
      if (line.contains('SECCIÓN') || line.contains('SECCION') || 
          line.contains('CLAVE DE ELECTOR') || line.contains('CURP')) {
        return false;
      }
    }
    return false;
  }
  
  /// Verifica si una línea está en la sección de sección electoral
  static bool _isInSeccionSection(List<String> lines, int lineIndex) {
    // Buscar hacia atrás hasta encontrar la etiqueta SECCIÓN
    for (int i = lineIndex; i >= 0 && i >= lineIndex - 3; i--) {
      final line = lines[i].toUpperCase();
      if (line.contains('SECCIÓN') || line.contains('SECCION')) {
        return true;
      }
    }
    
    // También buscar en la misma línea
    final currentLine = lines[lineIndex].toUpperCase();
    return currentLine.contains('SECCIÓN') || currentLine.contains('SECCION');
  }
  
  /// Extrae números de 4 dígitos de una cadena de domicilio
  static List<String> _extractNumbersFromDomicilio(String domicilio) {
    final matches = RegExp(r'\b(\d{4})\b').allMatches(domicilio);
    return matches.map((match) => match.group(1) ?? '').toList();
  }
  
  /// Valida si un número es una sección válida
  static bool _isValidSectionNumber(String section) {
    if (section.length != 4) return false;
    
    final num = int.tryParse(section);
    if (num == null) return false;
    
    // Las secciones electorales en México generalmente van de 0001 a 9999
    // pero excluimos años comunes
    if (num >= 1900 && num <= 2100) return false;
    
    return true;
  }
  
  /// Método de conveniencia para procesar con logging detallado
  static CredencialIneModel processWithDetailedLogging(
    String extractedText, {
    Map<String, String> additionalInfo = const {},
  }) {
    print('\n' + '=' * 50);
    print('🔧 PROCESAMIENTO MEJORADO DE CREDENCIAL');
    print('=' * 50);
    
    final result = processCredentialWithValidation(
      extractedText,
      additionalInfo: additionalInfo,
    );
    
    print('\n📋 RESULTADO FINAL:');
    print('  • Tipo: ${result.tipo}');
    print('  • Nombre: ${result.nombre}');
    print('  • Domicilio: "${result.domicilio}"');
    print('  • Sección: "${result.seccion}"');
    print('  • Clave Elector: ${result.claveElector}');
    print('=' * 50 + '\n');
    
    return result;
  }
}