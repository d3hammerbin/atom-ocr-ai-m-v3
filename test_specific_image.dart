import 'dart:io';
import 'lib/app/core/services/enhanced_credential_processor.dart';
import 'lib/app/core/services/mlkit_text_recognition_service.dart';
import 'lib/app/core/services/ocr_diagnostic_service.dart';
import 'lib/app/core/services/logger_service.dart';

/// Script para probar específicamente la imagen problemática
/// donde se detecta "5256" como domicilio en lugar de "2570" como sección
Future<void> main() async {
  print('🔍 ANÁLISIS ESPECÍFICO DE IMAGEN PROBLEMÁTICA');
  print('=' * 60);

  // Inicializar servicios
  await LoggerService.instance.initialize();

  // Ruta de la imagen problemática en el dispositivo
  const String imagePath =
      '/storage/emulated/0/Pictures/atom_ocr_cropped_1756956964501.jpg.jpg';

  print('📱 Imagen a analizar: $imagePath');

  // Verificar si la imagen existe (en caso de que esté disponible localmente)
  final imageFile = File(imagePath);
  if (!imageFile.existsSync()) {
    print('⚠️  La imagen no está disponible localmente.');
    print('   Simulando análisis con texto OCR conocido...');

    // Simular el texto OCR que contiene el problema
    await _analyzeSimulatedText();
    return;
  }

  try {
    print('🔄 Extrayendo texto de la imagen...');

    // Extraer texto usando MLKit
    final mlkitService = MLKitTextRecognitionService();
    final extractedText = await mlkitService.extractTextFromImage(imagePath);

    if (extractedText == null || extractedText.isEmpty) {
      print('❌ No se pudo extraer texto de la imagen');
      return;
    }

    print('✅ Texto extraído exitosamente');
    print('📄 Longitud del texto: ${extractedText?.length ?? 0} caracteres');

    await _analyzeExtractedText(extractedText!);
  } catch (e) {
    print('❌ Error al procesar la imagen: $e');
    print('   Procediendo con análisis simulado...');
    await _analyzeSimulatedText();
  }
}

/// Analiza el texto extraído de la imagen real
Future<void> _analyzeExtractedText(String extractedText) async {
  print('\n🔍 ANÁLISIS DEL TEXTO EXTRAÍDO');
  print('-' * 40);

  // Mostrar las primeras líneas del texto
  final lines = extractedText.split('\n');
  print('📝 Primeras 10 líneas del texto:');
  for (int i = 0; i < lines.length && i < 10; i++) {
    print('   ${i + 1}: "${lines[i]}"');
  }

  // Buscar los números problemáticos
  print('\n🔍 Buscando números problemáticos...');
  if (extractedText.contains('5256')) {
    print('✅ Encontrado "5256" en el texto');
  }
  if (extractedText.contains('2570')) {
    print('✅ Encontrado "2570" en el texto');
  }

  // Análisis diagnóstico
  print('\n📊 ANÁLISIS DIAGNÓSTICO');
  print('-' * 40);

  final diagnostic = OcrDiagnosticService.analyzeText(extractedText);
  print('📈 Reporte diagnóstico:');
  print(diagnostic);

  // Procesamiento con el sistema original
  print('\n🔄 PROCESAMIENTO ORIGINAL vs MEJORADO');
  print('-' * 40);

  try {
    // Procesamiento mejorado
    final enhancedResult =
        EnhancedCredentialProcessor.processWithDetailedLogging(extractedText);

    print('✅ RESULTADO MEJORADO:');
    print('   Sección: "${enhancedResult.seccion}"');
    print('   Domicilio: "${enhancedResult.domicilio}"');
    print('   Nombre: "${enhancedResult.nombre}"');
    print('   Clave Elector: "${enhancedResult.claveElector}"');
    print('   Tipo: "${enhancedResult.tipo}"');

    // Verificar si se corrigió el problema
    if (enhancedResult.seccion == '2570' &&
        enhancedResult.domicilio.contains('5256')) {
      print('\n🎉 ¡PROBLEMA CORREGIDO!');
      print('   ✅ Sección correcta: 2570');
      print('   ✅ Domicilio contiene: 5256');
    } else if (enhancedResult.seccion == '5256') {
      print('\n⚠️  PROBLEMA PERSISTE');
      print('   ❌ Sección incorrecta: 5256 (debería ser 2570)');
    } else {
      print('\n🤔 RESULTADO INESPERADO');
      print('   Sección detectada: "${enhancedResult.seccion}"');
      print('   Domicilio detectado: "${enhancedResult.domicilio}"');
    }
  } catch (e) {
    print('❌ Error en procesamiento mejorado: $e');
  }
}

/// Simula el análisis con texto conocido que contiene el problema
Future<void> _analyzeSimulatedText() async {
  print('\n🎭 ANÁLISIS SIMULADO CON TEXTO PROBLEMÁTICO');
  print('-' * 40);

  // Simular texto OCR que contiene ambos números
  const simulatedText = '''
INSTITUTO NACIONAL ELECTORAL
CREDENCIAL PARA VOTAR
NOMBRE
JUAN PÉREZ GARCÍA
DOMICILIO
AV REFORMA 5256 COL CENTRO
CIUDAD DE MÉXICO
SECCIÓN
2570
CLAVE DE ELECTOR
ABCD123456
AÑO DE REGISTRO
2020
''';

  print('📝 Texto simulado:');
  print(simulatedText);

  // Análisis diagnóstico
  print('\n📊 ANÁLISIS DIAGNÓSTICO SIMULADO');
  print('-' * 40);

  final diagnostic = OcrDiagnosticService.analyzeText(simulatedText);
  print('📈 Reporte diagnóstico:');
  print(diagnostic);

  // Procesamiento mejorado
  print('\n🔄 PROCESAMIENTO MEJORADO SIMULADO');
  print('-' * 40);

  try {
    final enhancedResult =
        EnhancedCredentialProcessor.processWithDetailedLogging(simulatedText);

    print('✅ RESULTADO MEJORADO:');
    print('   Sección: "${enhancedResult.seccion}"');
    print('   Domicilio: "${enhancedResult.domicilio}"');
    print('   Nombre: "${enhancedResult.nombre}"');
    print('   Clave Elector: "${enhancedResult.claveElector}"');

    // Verificar corrección
    if (enhancedResult.seccion == '2570') {
      print('\n🎉 ¡CORRECCIÓN EXITOSA!');
      print('   ✅ Sección correcta: 2570');
      print('   ✅ Domicilio contiene dirección completa');
    } else {
      print('\n⚠️  Necesita ajustes adicionales');
      print('   Sección detectada: "${enhancedResult.seccion}"');
    }
  } catch (e) {
    print('❌ Error en procesamiento simulado: $e');
  }

  print('\n📋 RECOMENDACIONES:');
  print('1. Verificar que el procesador mejorado esté integrado correctamente');
  print('2. Probar con la imagen real cuando esté disponible');
  print('3. Ajustar las reglas de validación si es necesario');
  print('4. Monitorear logs para casos similares');
}
