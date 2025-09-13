import 'dart:io';
import 'package:flutter/foundation.dart';
import 'mlkit_text_recognition_service.dart';
import 'ine_credential_processor_service.dart';

/// Servicio de diagnóstico para analizar problemas de OCR
/// Especialmente útil para detectar confusiones entre sección y domicilio
class OcrDiagnosticService {
  static const String _tag = 'OcrDiagnostic';

  /// Analiza una imagen y proporciona diagnóstico detallado del OCR
  static Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    try {
      print('🔍 [$_tag] Iniciando análisis diagnóstico de: $imagePath');
      
      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Archivo no encontrado: $imagePath');
      }

      // Obtener instancia del servicio OCR
      final ocrService = MLKitTextRecognitionService();
      
      // Extraer texto básico
      final basicText = await ocrService.extractTextFromImage(imagePath);
      
      // Extraer texto detallado con coordenadas
      final detailedResult = await ocrService.extractDetailedTextFromImage(imagePath);
      
      // Procesar con el servicio de credenciales
      final credential = IneCredentialProcessorService.processCredentialText(basicText ?? '');
      
      // Analizar líneas individualmente
      final lines = (basicText ?? '').split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      // Buscar números de 4 dígitos en todas las líneas
      final fourDigitNumbers = <Map<String, dynamic>>[];
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final matches = RegExp(r'\b(\d{4})\b').allMatches(line);
        for (final match in matches) {
          final number = match.group(1) ?? '';
          fourDigitNumbers.add({
            'number': number,
            'line_index': i,
            'line_content': line,
            'is_year': RegExp(r'^(19|20)\d{2}\$').hasMatch(number),
            'context': _analyzeNumberContext(line, number),
          });
        }
      }
      
      // Analizar extracción de domicilio paso a paso
      final domicilioAnalysis = _analyzeDomicilioExtraction(lines);
      
      // Analizar extracción de sección paso a paso
      final seccionAnalysis = _analyzeSeccionExtraction(lines, credential.tipo);
      
      return {
        'image_path': imagePath,
        'basic_text': basicText,
        'detailed_result': detailedResult,
        'processed_credential': {
          'tipo': credential.tipo,
          'nombre': credential.nombre,
          'domicilio': credential.domicilio,
          'seccion': credential.seccion,
          'clave_elector': credential.claveElector,
        },
        'lines_analysis': lines.asMap().entries.map((entry) => {
          'index': entry.key,
          'content': entry.value,
          'uppercase': entry.value.toUpperCase(),
          'contains_domicilio': entry.value.toUpperCase().contains('DOMICILIO'),
          'contains_seccion': entry.value.toUpperCase().contains('SECCIÓN') || entry.value.toUpperCase().contains('SECCION'),
          'four_digit_numbers': RegExp(r'\b\d{4}\b').allMatches(entry.value).map((m) => m.group(0)).toList(),
        }).toList(),
        'four_digit_numbers': fourDigitNumbers,
        'domicilio_analysis': domicilioAnalysis,
        'seccion_analysis': seccionAnalysis,
        'potential_issues': _identifyPotentialIssues(fourDigitNumbers, domicilioAnalysis, seccionAnalysis),
      };
      
    } catch (e) {
      print('❌ [$_tag] Error en análisis: $e');
      return {
        'error': e.toString(),
        'image_path': imagePath,
      };
    }
  }
  
  /// Analiza el contexto de un número de 4 dígitos
  /// Determina si un número de 4 dígitos es probablemente un año
  static bool _isLikelyYear(String number) {
    final year = int.tryParse(number);
    if (year == null) return false;
    
    // Años típicos en credenciales (nacimiento, emisión, vigencia)
    final currentYear = DateTime.now().year;
    return year >= 1900 && year <= currentYear + 10;
  }

  static String _analyzeNumberContext(String line, String number) {
    final upperLine = line.toUpperCase();
    
    if (upperLine.contains('DOMICILIO')) return 'domicilio_context';
    if (upperLine.contains('SECCIÓN') || upperLine.contains('SECCION')) return 'seccion_context';
    if (upperLine.contains('MUNICIPIO')) return 'municipio_context';
    if (upperLine.contains('VIGENCIA')) return 'vigencia_context';
    if (upperLine.contains('EMISIÓN') || upperLine.contains('EMISION')) return 'emision_context';
    if (upperLine.contains('/')) return 'date_context';
    if (upperLine.contains('CALLE') || upperLine.contains('AV ') || upperLine.contains('COL ')) return 'address_context';
    
    return 'unknown_context';
  }
  
  /// Analiza paso a paso la extracción de domicilio
  static Map<String, dynamic> _analyzeDomicilioExtraction(List<String> lines) {
    final analysis = {
      'method_used': 'unknown',
      'domicilio_label_found': false,
      'domicilio_label_line': -1,
      'extracted_lines': <String>[],
      'fallback_lines': <String>[],
    };
    
    // Simular el método _extractDomicilio
    List<String> domicilioLines = [];
    
    // Buscar etiqueta DOMICILIO
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      
      if (line.contains('DOMICILIO') || line.contains('DOMICILIo') || line.contains('DOMICILI')) {
        analysis['method_used'] = 'label_based';
        analysis['domicilio_label_found'] = true;
        analysis['domicilio_label_line'] = i;
        
        // Extraer siguientes 3 líneas
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isNotEmpty) {
            domicilioLines.add(nextLine);
            (analysis['extracted_lines'] as List<String>).add(nextLine);
          }
        }
        break;
      }
    }
    
    // Si no se encontró etiqueta, usar fallback
    if (domicilioLines.isEmpty) {
      analysis['method_used'] = 'fallback_pattern';
      
      for (final line in lines) {
        final upperLine = line.toUpperCase();
        
        if (upperLine.contains('CLAVE DE ELECTOR') || upperLine.contains('CLAVE ELECTOR')) {
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
          (analysis['fallback_lines'] as List<String>).add(line);
        }
      }
    }
    
    return analysis;
  }
  
  /// Analiza paso a paso la extracción de sección
  static Map<String, dynamic> _analyzeSeccionExtraction(List<String> lines, String credentialType) {
    final analysis = {
      'credential_type': credentialType,
      'method_used': 'unknown',
      'seccion_label_found': false,
      'seccion_label_line': -1,
      'candidate_numbers': <Map<String, dynamic>>[],
      'selected_number': '',
      'selection_reason': '',
    };
    
    // Determinar qué método se usaría
    String methodToUse = 'standard';
    if (credentialType == 't2') methodToUse = 't2';
    if (credentialType == 't3') methodToUse = 't3';
    
    analysis['method_used'] = methodToUse;
    
    // Simular extracción según el tipo
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      
      if (line.contains('SECCIÓN') || line.contains('SECCION')) {
        analysis['seccion_label_found'] = true;
        analysis['seccion_label_line'] = i;
        
        // Buscar números en líneas siguientes
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();
          final matches = RegExp(r'\b(\d{4})\b').allMatches(nextLine);
          for (final match in matches) {
            final number = match.group(1) ?? '';
            final isYear = RegExp(r'^(19|20)\d{2}\$').hasMatch(number);
            (analysis['candidate_numbers'] as List<Map<String, dynamic>>).add({
              'number': number,
              'line': nextLine,
              'is_year': isYear,
              'valid_candidate': !isYear,
            });
          }
        }
      }
      
      // También buscar números en cualquier línea (método estándar)
      final matches = RegExp(r'\b(\d{4})\b').allMatches(line);
      for (final match in matches) {
        final number = match.group(1) ?? '';
        final isYear = RegExp(r'^(19|20)\d{2}\$').hasMatch(number);
        final hasDateContext = line.contains('/');
        
        if (!isYear && !hasDateContext) {
          (analysis['candidate_numbers'] as List<Map<String, dynamic>>).add({
            'number': number,
            'line': line,
            'is_year': false,
            'has_date_context': false,
            'valid_candidate': true,
            'method': 'any_line_search',
          });
        }
      }
    }
    
    return analysis;
  }
  
  /// Identifica problemas potenciales en la extracción
  static List<String> _identifyPotentialIssues(
    List<Map<String, dynamic>> fourDigitNumbers,
    Map<String, dynamic> domicilioAnalysis,
    Map<String, dynamic> seccionAnalysis,
  ) {
    final issues = <String>[];
    
    // Verificar si hay números que podrían ser confundidos
    final addressNumbers = fourDigitNumbers.where((n) => 
        n['context'] == 'address_context' || n['context'] == 'domicilio_context'
    ).toList();
    
    final sectionNumbers = fourDigitNumbers.where((n) => 
        n['context'] == 'seccion_context'
    ).toList();
    
    if (addressNumbers.isNotEmpty && sectionNumbers.isNotEmpty) {
      issues.add('Números de 4 dígitos encontrados tanto en contexto de domicilio como de sección');
    }
    
    if (domicilioAnalysis['method_used'] == 'fallback_pattern') {
      issues.add('Extracción de domicilio usando método fallback (puede incluir números de sección)');
    }
    
    if (!seccionAnalysis['seccion_label_found']) {
      issues.add('No se encontró etiqueta SECCIÓN explícita');
    }
    
    final candidateNumbers = seccionAnalysis['candidate_numbers'] as List;
    if (candidateNumbers.length > 1) {
      issues.add('Múltiples candidatos para número de sección encontrados');
    }
    
    return issues;
  }
  
  /// Imprime un reporte detallado del análisis
  static void printDetailedReport(Map<String, dynamic> analysis) {
    print('\n' + '=' * 60);
    print('🔍 REPORTE DIAGNÓSTICO OCR');
    print('=' * 60);
    
    if (analysis.containsKey('error')) {
      print('❌ ERROR: ${analysis['error']}');
      return;
    }
    
    print('📁 Imagen: ${analysis['image_path']}');
    print('📋 Tipo de credencial: ${analysis['processed_credential']['tipo']}');
    print('');
    
    print('📝 DATOS EXTRAÍDOS:');
    final credential = analysis['processed_credential'];
    print('  • Nombre: ${credential['nombre']}');
    print('  • Domicilio: ${credential['domicilio']}');
    print('  • Sección: ${credential['seccion']}');
    print('  • Clave Elector: ${credential['clave_elector']}');
    print('');
    
    print('🔢 NÚMEROS DE 4 DÍGITOS ENCONTRADOS:');
    final numbers = analysis['four_digit_numbers'] as List;
    for (final number in numbers) {
      print('  • ${number['number']} - Línea ${number['line_index']}: "${number['line_content']}"');
      print('    Contexto: ${number['context']}, Es año: ${number['is_year']}');
    }
    print('');
    
    print('🏠 ANÁLISIS DE DOMICILIO:');
    final domicilio = analysis['domicilio_analysis'];
    print('  • Método usado: ${domicilio['method_used']}');
    print('  • Etiqueta encontrada: ${domicilio['domicilio_label_found']}');
    if (domicilio['domicilio_label_found']) {
      print('  • Línea de etiqueta: ${domicilio['domicilio_label_line']}');
      print('  • Líneas extraídas: ${domicilio['extracted_lines']}');
    } else {
      print('  • Líneas fallback: ${domicilio['fallback_lines']}');
    }
    print('');
    
    print('🗳️ ANÁLISIS DE SECCIÓN:');
    final seccion = analysis['seccion_analysis'];
    print('  • Método usado: ${seccion['method_used']}');
    print('  • Etiqueta encontrada: ${seccion['seccion_label_found']}');
    if (seccion['seccion_label_found']) {
      print('  • Línea de etiqueta: ${seccion['seccion_label_line']}');
    }
    final candidates = seccion['candidate_numbers'] as List;
    print('  • Candidatos encontrados: ${candidates.length}');
    for (final candidate in candidates) {
      print('    - ${candidate['number']} en "${candidate['line']}" (válido: ${candidate['valid_candidate']})');
    }
    print('');
    
    print('⚠️ PROBLEMAS POTENCIALES:');
    final issues = analysis['potential_issues'] as List<String>;
    if (issues.isEmpty) {
      print('  • No se detectaron problemas obvios');
    } else {
      for (final issue in issues) {
        print('  • $issue');
      }
    }
    
    print('\n' + '=' * 60);
  }

  /// Analiza texto directamente sin necesidad de imagen
  /// Útil para análisis de texto ya extraído
  static Map<String, dynamic> analyzeText(String text) {
    try {
      print('🔍 [$_tag] Iniciando análisis de texto directo');
      
      // Procesar con el servicio de credenciales
      final credential = IneCredentialProcessorService.processCredentialText(text);
      
      // Analizar líneas individualmente
      final lines = text.split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      // Buscar números de 4 dígitos en todas las líneas
      final fourDigitNumbers = <Map<String, dynamic>>[];
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final matches = RegExp(r'\b(\d{4})\b').allMatches(line);
        for (final match in matches) {
          final number = match.group(1) ?? '';
          fourDigitNumbers.add({
            'number': number,
            'line_index': i,
            'line_content': line,
            'context': _analyzeNumberContext(line, number),
            'is_year': _isLikelyYear(number),
          });
        }
      }
      
      // Análisis específicos
      final domicilioAnalysis = _analyzeDomicilioExtraction(lines);
      final seccionAnalysis = _analyzeSeccionExtraction(lines, credential.tipo ?? 'desconocido');
      
      // Detectar problemas potenciales
      final potentialIssues = <String>[];
      
      // Verificar si hay números que podrían estar mal clasificados
      final seccionNumbers = fourDigitNumbers.where((n) => 
          n['context'].toString().contains('sección') || 
          n['context'].toString().contains('electoral')).toList();
      final domicilioNumbers = fourDigitNumbers.where((n) => 
          n['context'].toString().contains('domicilio') || 
          n['context'].toString().contains('dirección')).toList();
      
      if (seccionNumbers.isEmpty && domicilioNumbers.isNotEmpty) {
        potentialIssues.add('No se encontraron números en contexto de sección, pero sí en domicilio');
      }
      
      if (credential.seccion?.isEmpty == true && credential.domicilio?.isNotEmpty == true) {
        potentialIssues.add('Sección vacía pero domicilio tiene contenido - posible confusión');
      }
      
      return {
        'processed_credential': credential,
        'text_lines': lines,
        'four_digit_numbers': fourDigitNumbers,
        'domicilio_analysis': domicilioAnalysis,
        'seccion_analysis': seccionAnalysis,
        'potential_issues': potentialIssues,
        'analysis_timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('❌ [$_tag] Error en análisis de texto: $e');
      return {
        'error': e.toString(),
        'analysis_timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}