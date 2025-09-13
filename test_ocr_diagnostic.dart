import 'dart:io';
import 'lib/app/core/services/ocr_diagnostic_service.dart';

/// Script para diagnosticar el problema específico de la credencial
/// donde se detecta "5256" como domicilio en lugar de "2570" como sección
Future<void> main() async {
  // Ruta de la imagen problemática
  final imagePath = '/storage/emulated/0/Pictures/atom_ocr_cropped_1756956964501.jpg.jpg';
  
  print('🔍 Iniciando diagnóstico de OCR para imagen problemática...');
  print('📁 Imagen: $imagePath');
  print('');
  
  try {
    // Verificar si estamos en un entorno donde podemos acceder al archivo
    // (esto funcionará mejor cuando se ejecute en el dispositivo)
    final file = File(imagePath);
    
    if (!await file.exists()) {
      print('⚠️ NOTA: El archivo no está disponible en este entorno.');
      print('   Este script debe ejecutarse en el dispositivo Android donde está la imagen.');
      print('   Alternativamente, copia la imagen al directorio del proyecto.');
      print('');
      
      // Sugerir alternativas
      print('💡 ALTERNATIVAS:');
      print('   1. Ejecutar este script desde la aplicación Flutter en el dispositivo');
      print('   2. Copiar la imagen a: assets/test_images/problematic_credential.jpg');
      print('   3. Usar adb para copiar: adb pull "$imagePath" ./test_image.jpg');
      return;
    }
    
    // Realizar análisis diagnóstico
    final analysis = await OcrDiagnosticService.analyzeImage(imagePath);
    
    // Imprimir reporte detallado
    OcrDiagnosticService.printDetailedReport(analysis);
    
    // Análisis específico del problema reportado
    print('\n🎯 ANÁLISIS ESPECÍFICO DEL PROBLEMA REPORTADO:');
    print('   Problema: Se detecta "5256" como domicilio en lugar de "2570" como sección');
    print('');
    
    final credential = analysis['processed_credential'];
    final numbers = analysis['four_digit_numbers'] as List;
    
    // Buscar los números específicos mencionados
    final number5256 = numbers.where((n) => n['number'] == '5256').toList();
    final number2570 = numbers.where((n) => n['number'] == '2570').toList();
    
    if (number5256.isNotEmpty) {
      print('🔍 Número "5256" encontrado:');
      for (final num in number5256) {
        print('   • Línea ${num['line_index']}: "${num['line_content']}"');
        print('   • Contexto: ${num['context']}');
        print('   • ¿Está en domicilio extraído? ${credential['domicilio'].contains('5256')}');
      }
      print('');
    } else {
      print('❌ Número "5256" NO encontrado en el análisis');
    }
    
    if (number2570.isNotEmpty) {
      print('🔍 Número "2570" encontrado:');
      for (final num in number2570) {
        print('   • Línea ${num['line_index']}: "${num['line_content']}"');
        print('   • Contexto: ${num['context']}');
        print('   • ¿Está en sección extraída? ${credential['seccion'] == '2570'}');
      }
      print('');
    } else {
      print('❌ Número "2570" NO encontrado en el análisis');
    }
    
    // Recomendaciones específicas
    print('💡 RECOMENDACIONES PARA SOLUCIONAR EL PROBLEMA:');
    
    final domicilioAnalysis = analysis['domicilio_analysis'];
    if (domicilioAnalysis['method_used'] == 'fallback_pattern') {
      print('   1. El domicilio se está extrayendo usando el método fallback');
      print('      que incluye cualquier línea con números > 10 caracteres.');
      print('      Esto puede estar capturando números de sección.');
      print('');
      print('   2. SOLUCIÓN: Mejorar la detección de la etiqueta DOMICILIO');
      print('      o excluir líneas que contengan contexto de sección.');
    }
    
    final seccionAnalysis = analysis['seccion_analysis'];
    if (!seccionAnalysis['seccion_label_found']) {
      print('   3. No se encontró etiqueta SECCIÓN explícita.');
      print('      SOLUCIÓN: Mejorar la detección de variantes de SECCIÓN.');
    }
    
    final issues = analysis['potential_issues'] as List<String>;
    if (issues.isNotEmpty) {
      print('   4. Problemas detectados automáticamente:');
      for (final issue in issues) {
        print('      • $issue');
      }
    }
    
  } catch (e) {
    print('❌ Error durante el diagnóstico: $e');
    print('');
    print('💡 SUGERENCIAS:');
    print('   • Asegúrate de que la imagen existe en la ruta especificada');
    print('   • Ejecuta este script desde la aplicación Flutter en el dispositivo');
    print('   • Verifica los permisos de acceso al almacenamiento');
  }
}

/// Función auxiliar para ejecutar desde la aplicación Flutter
/// Llama a esta función desde un botón en la UI para diagnosticar
Future<void> runDiagnosticFromApp() async {
  await main();
}

/// Función para diagnosticar una imagen alternativa
Future<void> diagnoseAlternativeImage(String imagePath) async {
  print('🔍 Diagnosticando imagen alternativa: $imagePath');
  
  try {
    final analysis = await OcrDiagnosticService.analyzeImage(imagePath);
    OcrDiagnosticService.printDetailedReport(analysis);
  } catch (e) {
    print('❌ Error: $e');
  }
}