/// Script simple para probar la lógica de corrección de sección/domicilio
void main() {
  print('🔍 PRUEBA SIMPLE DE CORRECCIÓN SECCIÓN/DOMICILIO');
  print('=' * 60);
  
  // Simular texto OCR problemático
  const String problematicText = '''
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
  
  print('📝 Texto OCR simulado:');
  print(problematicText);
  
  // Analizar líneas
  final lines = problematicText.split('\n');
  print('\n📊 ANÁLISIS DE LÍNEAS:');
  print('-' * 40);
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    
    // Buscar números de 4 dígitos
    final fourDigitNumbers = RegExp(r'\b\d{4}\b').allMatches(line);
    if (fourDigitNumbers.isNotEmpty) {
      for (final match in fourDigitNumbers) {
        final number = match.group(0)!;
        print('   Línea $i: "$line" -> Número 4 dígitos: $number');
        
        // Analizar contexto
        final context = _analyzeContext(lines, i);
        print('     Contexto: $context');
      }
    }
  }
  
  // Extraer sección y domicilio
  print('\n🔍 EXTRACCIÓN:');
  print('-' * 40);
  
  final seccion = _extractSeccion(lines);
  final domicilio = _extractDomicilio(lines);
  
  print('✅ Sección extraída: "$seccion"');
  print('✅ Domicilio extraído: "$domicilio"');
  
  // Verificar corrección
  if (seccion == '2570' && domicilio.contains('5256')) {
    print('\n🎉 ¡CORRECCIÓN EXITOSA!');
    print('   ✅ Sección correcta: 2570');
    print('   ✅ Domicilio contiene: 5256');
  } else {
    print('\n⚠️  Resultado inesperado:');
    print('   Sección: $seccion');
    print('   Domicilio: $domicilio');
  }
}

/// Analiza el contexto de una línea
String _analyzeContext(List<String> lines, int index) {
  final contexts = <String>[];
  
  // Línea anterior
  if (index > 0) {
    final prevLine = lines[index - 1].trim().toLowerCase();
    if (prevLine.contains('sección') || prevLine.contains('seccion')) {
      contexts.add('DESPUÉS_DE_SECCIÓN');
    }
    if (prevLine.contains('domicilio')) {
      contexts.add('DESPUÉS_DE_DOMICILIO');
    }
  }
  
  // Línea actual
  final currentLine = lines[index].trim().toLowerCase();
  if (currentLine.contains('sección') || currentLine.contains('seccion')) {
    contexts.add('LÍNEA_SECCIÓN');
  }
  if (currentLine.contains('domicilio')) {
    contexts.add('LÍNEA_DOMICILIO');
  }
  if (currentLine.contains('av ') || currentLine.contains('calle') || currentLine.contains('col ')) {
    contexts.add('DIRECCIÓN');
  }
  
  return contexts.isEmpty ? 'NEUTRO' : contexts.join(', ');
}

/// Extrae la sección con validación de contexto
String _extractSeccion(List<String> lines) {
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim().toLowerCase();
    
    // Buscar línea con "SECCIÓN"
    if (line.contains('sección') || line.contains('seccion')) {
      // Buscar número en la misma línea
      final match = RegExp(r'\b(\d{4})\b').firstMatch(lines[i]);
      if (match != null) {
        final number = match.group(1)!;
        if (_isValidSeccion(number)) {
          return number;
        }
      }
      
      // Buscar en la siguiente línea
      if (i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim();
        final nextMatch = RegExp(r'\b(\d{4})\b').firstMatch(nextLine);
        if (nextMatch != null) {
          final number = nextMatch.group(1)!;
          if (_isValidSeccion(number)) {
            return number;
          }
        }
      }
    }
  }
  
  return '';
}

/// Extrae el domicilio
String _extractDomicilio(List<String> lines) {
  final domicilioLines = <String>[];
  bool inDomicilio = false;
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    
    if (line.toLowerCase().contains('domicilio')) {
      inDomicilio = true;
      
      // Verificar si hay contenido en la misma línea
      final content = line.toLowerCase().replaceAll('domicilio', '').trim();
      if (content.isNotEmpty && content.length > 3) {
        domicilioLines.add(content);
      }
      continue;
    }
    
    if (inDomicilio) {
      // Parar si encontramos otra etiqueta
      if (line.toLowerCase().contains('sección') || 
          line.toLowerCase().contains('seccion') ||
          line.toLowerCase().contains('clave') ||
          line.toLowerCase().contains('año')) {
        break;
      }
      
      if (line.isNotEmpty && line.length > 3) {
        domicilioLines.add(line);
      }
    }
  }
  
  return domicilioLines.join(' ').trim();
}

/// Valida si un número puede ser una sección
bool _isValidSeccion(String number) {
  final num = int.tryParse(number);
  if (num == null) return false;
  
  // Las secciones suelen estar entre 1 y 9999
  // Evitar años (1900-2100)
  if (num >= 1900 && num <= 2100) return false;
  
  return num >= 1 && num <= 9999;
}