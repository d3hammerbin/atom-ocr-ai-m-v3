# Algoritmos de Similitud de Cadenas para OCR

Esta implementación proporciona algoritmos de similitud de cadenas para manejar variantes de texto OCR en el procesamiento de credenciales INE.

## Algoritmos Implementados

### 1. Distancia de Levenshtein
- **Propósito**: Calcula el número mínimo de operaciones (inserción, eliminación, sustitución) necesarias para transformar una cadena en otra.
- **Uso**: Ideal para detectar errores de caracteres individuales.
- **Ejemplo**: "VIGENCIA" vs "IGENCIA" = 1 operación (eliminar 'V')

### 2. Similitud de Jaro
- **Propósito**: Mide la similitud basada en caracteres coincidentes y transposiciones.
- **Uso**: Efectivo para detectar errores de transposición y caracteres faltantes.
- **Ventaja**: Mejor rendimiento con cadenas de longitud similar.

### 3. Similitud de Jaro-Winkler
- **Propósito**: Extensión de Jaro que da mayor peso a las coincidencias al inicio de las cadenas.
- **Uso**: Excelente para etiquetas OCR donde los primeros caracteres suelen ser más precisos.
- **Recomendado**: Algoritmo principal para detección de etiquetas INE.

## Métodos Principales

### `findBestMatch()`
Encuentra la mejor coincidencia de una cadena objetivo en una lista de candidatos.

```dart
final result = StringSimilarityUtils.findBestMatch(
  'IGENCIA',
  ['VIGENCIA', 'NOMBRE', 'DOMICILIO'],
  threshold: 0.7,
);
// Resultado: {'match': 'VIGENCIA', 'score': 0.85, 'found': true}
```

### `findAllMatches()`
Encuentra todas las coincidencias que superen el umbral especificado.

```dart
final matches = StringSimilarityUtils.findAllMatches(
  'VIGEN',
  ['VIGENCIA', 'VIGENTE', 'VIGENCIA2030'],
  threshold: 0.6,
);
// Retorna lista ordenada por puntuación descendente
```

## Integración en IneCredentialProcessorService

### Método `_findLabelWithSimilarity()`
Busca etiquetas en el texto OCR usando:
1. **Coincidencia exacta** (prioridad alta)
2. **Similitud de cadenas** (fallback inteligente)

```dart
final result = _findLabelWithSimilarity(
  lines,
  ['VIGENCIA', 'VIGENC', 'VIGEN'],
  threshold: 0.7,
);
```

### Extracción de Vigencia Mejorada
El método `_extractVigenciaWithSimilarity()` maneja variantes comunes:
- VIGENCIA → IGENCIA, VIGEN, GENCIA, VIGENT
- Umbral: 0.6 (más permisivo debido a errores frecuentes)
- Búsqueda de fechas en línea actual y siguientes

## Umbrales Recomendados

| Etiqueta | Umbral | Razón |
|----------|--------|-------|
| VIGENCIA | 0.6 | Errores OCR muy comunes |
| NOMBRE | 0.7 | Balance entre precisión y cobertura |
| DOMICILIO | 0.7 | Variantes moderadas |
| CLAVE DE ELECTOR | 0.8 | Evitar falsos positivos |
| CURP | 0.8 | Datos críticos, mayor precisión |

## Variantes Comunes Detectadas

### VIGENCIA
- IGENCIA (V faltante)
- VIGEN (CIA faltante)
- GENCIA (VI faltante)
- VIGENT (CIA → T)
- VIGENC (A faltante)

### NOMBRE
- NOMERE (B → E)
- NOMBE (R faltante)
- OMBRE (N faltante)

### DOMICILIO
- DOMICILO (I faltante)
- DOMCILIO (I faltante)
- DOMICIIO (L → I)

## Beneficios de la Implementación

1. **Robustez**: Maneja errores OCR comunes automáticamente
2. **Flexibilidad**: Umbrales configurables por tipo de etiqueta
3. **Rendimiento**: Búsqueda exacta primero, similitud como fallback
4. **Escalabilidad**: Fácil agregar nuevas variantes y etiquetas
5. **Precisión**: Múltiples algoritmos para diferentes tipos de errores

## Ejemplo de Uso Completo

```dart
// Texto OCR con errores
final ocrText = '''
INSTITUTO NACIONAL ELECTORAL
CREDENCIAL PARA VOTAR
JUAN PÉREZ GARCÍA
IGENCIA 15/03/2030
CLAVE DE ELECTOR: PRGJN85031512H400
''';

// Procesar con algoritmos de similitud
final credencial = IneCredentialProcessorService.processCredential(ocrText);

// Resultado: vigencia = "15/03/2030" (detectada desde "IGENCIA")
print('Vigencia detectada: ${credencial.vigencia}');
```

## Consideraciones de Rendimiento

- **Complejidad**: O(n*m) para Levenshtein, O(n) para Jaro-Winkler
- **Optimización**: Búsqueda exacta primero reduce cálculos innecesarios
- **Memoria**: Algoritmos optimizados para cadenas cortas (etiquetas)
- **Escalabilidad**: Rendimiento adecuado para listas de etiquetas típicas (< 50 elementos)

## Extensibilidad

Para agregar nuevas etiquetas o variantes:

1. Actualizar listas de etiquetas en métodos específicos
2. Ajustar umbrales según precisión requerida
3. Agregar casos de prueba para nuevas variantes
4. Documentar patrones de error observados

Esta implementación proporciona una base sólida para el manejo inteligente de errores OCR en el procesamiento de credenciales INE.