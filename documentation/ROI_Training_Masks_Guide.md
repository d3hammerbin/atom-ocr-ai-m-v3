# Guía de Entrenamiento y Máscaras ROI - INE Scanner Flutter

## Introducción

Este documento describe la metodología para definir, entrenar y utilizar Áreas de Interés (ROI) mediante máscaras binarias para el proyecto INE Scanner Flutter.

## 1. Conceptos Fundamentales

### Máscaras Binarias
- **Blanco (255,255,255)**: Áreas de interés donde extraer texto
- **Negro (0,0,0)**: Áreas a descartar completamente
- **Gris (128,128,128)**: Áreas de referencia/alineación (opcional)

### Ventajas del Enfoque
1. **Visual e Intuitivo**: Fácil crear y editar máscaras en cualquier editor de imágenes
2. **Precisión**: Control pixel-perfect de las áreas de interés
3. **Flexibilidad**: Fácil agregar/quitar campos modificando la máscara
4. **Validación**: Verificación automática si un punto está en área válida
5. **Optimización**: Procesamiento solo en áreas blancas, ignorando áreas negras

## 2. Dimensiones y Resoluciones

### Tamaños Base Recomendados
Para imágenes de credenciales de **790x490 píxeles**:

- **Resolución estándar**: 1580x980 píxeles (2x la resolución actual)
- **Resolución alta**: 2370x1470 píxeles (3x la resolución actual)
- **Resolución máxima**: 3160x1960 píxeles (4x la resolución actual)

### Justificación del Escalado
- **Precisión**: Mayor detalle en los bordes de las ROIs
- **Escalabilidad**: Compatibilidad con cámaras de mayor resolución
- **Interpolación**: Mejor calidad al redimensionar
- **Futuro**: Preparado para mejoras de hardware

## 3. Estructura de Archivos

```
assets/roi_templates/
├── masks/
│   ├── standard/          # 1580x980
│   │   ├── ine_frontal_mask.png
│   │   └── ine_reverso_mask.png
│   ├── high/              # 2370x1470
│   │   ├── ine_frontal_mask.png
│   │   └── ine_reverso_mask.png
│   └── ultra/             # 3160x1960
│       ├── ine_frontal_mask.png
│       └── ine_reverso_mask.png
└── config/
    ├── mask_config.json
    └── roi_config.json
```

## 4. Configuración JSON

### Configuración de Resoluciones
```json
{
  "resolution_tiers": {
    "standard": {
      "width": 1580,
      "height": 980,
      "min_input_width": 400,
      "max_input_width": 1000,
      "path": "masks/standard/"
    },
    "high": {
      "width": 2370,
      "height": 1470,
      "min_input_width": 1001,
      "max_input_width": 1800,
      "path": "masks/high/"
    },
    "ultra": {
      "width": 3160,
      "height": 1960,
      "min_input_width": 1801,
      "max_input_width": 4000,
      "path": "masks/ultra/"
    }
  },
  "aspect_ratio": 1.6122,
  "tolerance": 0.1
}
```

### Configuración de Campos ROI
```json
{
  "ine_frontal": {
    "mask_file": "ine_frontal_mask.png",
    "fields": {
      "nombre": {
        "priority": 1,
        "ocr_config": "text_enhanced",
        "validation": "name_pattern"
      },
      "apellidos": {
        "priority": 1,
        "ocr_config": "text_enhanced",
        "validation": "name_pattern"
      },
      "fecha_nacimiento": {
        "priority": 2,
        "ocr_config": "date_pattern",
        "validation": "date_format"
      }
    }
  },
  "ine_reverso": {
    "mask_file": "ine_reverso_mask.png",
    "fields": {
      "curp": {
        "priority": 1,
        "ocr_config": "alphanumeric",
        "validation": "curp_pattern"
      },
      "clave_elector": {
        "priority": 2,
        "ocr_config": "alphanumeric",
        "validation": "clave_pattern"
      }
    }
  }
}
```

## 5. Implementación de Servicios

### Servicio de Procesamiento de Máscaras
```dart
class MaskProcessorService {
  static Future<List<Rect>> extractROIsFromMask(String maskPath) async {
    // Cargar máscara binaria
    final maskImage = await loadImageFromAssets(maskPath);
    
    // Encontrar contornos de áreas blancas
    final whiteAreas = await _findWhiteRegions(maskImage);
    
    // Convertir a coordenadas normalizadas
    return _normalizeCoordinates(whiteAreas, maskImage.width, maskImage.height);
  }
  
  static Future<bool> isPointInROI(Point point, String maskPath) async {
    final maskImage = await loadImageFromAssets(maskPath);
    final pixelColor = getPixelColor(maskImage, point.x, point.y);
    
    // Verificar si el pixel es blanco (área de interés)
    return pixelColor.red > 200 && pixelColor.green > 200 && pixelColor.blue > 200;
  }
}
```

### Servicio de Selección de Resolución
```dart
class MaskResolutionService {
  static String selectOptimalMaskPath(int imageWidth, int imageHeight, String documentType) {
    final aspectRatio = imageWidth / imageHeight;
    
    // Verificar proporción (790/490 ≈ 1.61)
    if ((aspectRatio - 1.6122).abs() > 0.1) {
      throw Exception('Proporción de imagen no válida para credencial INE');
    }
    
    // Seleccionar resolución según tamaño de entrada
    String tier;
    if (imageWidth <= 1000) {
      tier = 'standard';
    } else if (imageWidth <= 1800) {
      tier = 'high';
    } else {
      tier = 'ultra';
    }
    
    return 'assets/roi_templates/masks/$tier/${documentType}_mask.png';
  }
  
  static Future<String> getScaledMask(String originalMaskPath, int targetWidth, int targetHeight) async {
    // Cargar máscara original
    final originalMask = await loadImageFromAssets(originalMaskPath);
    
    // Escalar manteniendo proporción
    final scaledMask = await scaleImageMaintainAspect(
      originalMask, 
      targetWidth, 
      targetHeight
    );
    
    // Guardar temporalmente
    final tempPath = await saveTempMask(scaledMask);
    return tempPath;
  }
}
```

### Servicio de ROI Principal
```dart
class ROIService {
  Future<Map<String, String>> processImageWithMask(
    String imagePath, 
    String documentType
  ) async {
    // 1. Cargar configuración y máscara
    final config = await loadROIConfig(documentType);
    final maskPath = 'assets/roi_templates/${config.maskFile}';
    
    // 2. Extraer ROIs de la máscara
    final rois = await MaskProcessorService.extractROIsFromMask(maskPath);
    
    // 3. Aplicar OCR solo en áreas blancas
    final results = <String, String>{};
    for (final roi in rois) {
      final croppedImage = await cropImageToROI(imagePath, roi);
      final text = await performOCR(croppedImage);
      
      // 4. Asociar texto extraído con campo correspondiente
      final fieldName = await identifyField(roi, config.fields);
      if (fieldName != null) {
        results[fieldName] = text;
      }
    }
    
    return results;
  }
}
```

### Servicio de Escalado Dinámico
```dart
class DynamicMaskService {
  static Future<String> prepareMaskForImage(
    String imagePath, 
    String documentType
  ) async {
    // 1. Obtener dimensiones de la imagen
    final imageInfo = await getImageDimensions(imagePath);
    
    // 2. Seleccionar máscara base
    final baseMaskPath = MaskResolutionService.selectOptimalMaskPath(
      imageInfo.width, 
      imageInfo.height, 
      documentType
    );
    
    // 3. Escalar si es necesario
    if (needsScaling(imageInfo, baseMaskPath)) {
      return await MaskResolutionService.getScaledMask(
        baseMaskPath,
        imageInfo.width,
        imageInfo.height
      );
    }
    
    return baseMaskPath;
  }
}
```

## 6. Integración con OpenCV Nativo

### Procesador de Máscaras Android
```java
public class MaskROIProcessor {
    public static List<Rect> extractROIsFromMask(String maskPath) {
        Mat mask = Imgcodecs.imread(maskPath, Imgcodecs.IMREAD_GRAYSCALE);
        
        // Binarizar la imagen (por si tiene ruido)
        Mat binary = new Mat();
        Imgproc.threshold(mask, binary, 200, 255, Imgproc.THRESH_BINARY);
        
        // Encontrar contornos de áreas blancas
        List<MatOfPoint> contours = new ArrayList<>();
        Mat hierarchy = new Mat();
        Imgproc.findContours(binary, contours, hierarchy, 
                           Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE);
        
        List<Rect> rois = new ArrayList<>();
        for (MatOfPoint contour : contours) {
            Rect boundingRect = Imgproc.boundingRect(contour);
            // Filtrar áreas muy pequeñas
            if (boundingRect.area() > 100) {
                rois.add(boundingRect);
            }
        }
        
        return rois;
    }
}
```

## 7. Proceso de Entrenamiento

### Fase 1: Análisis Manual
1. **Recolección de muestras**: 50-100 imágenes de INE reales
2. **Análisis de variaciones**: Diferentes formatos, años, estados
3. **Identificación de patrones**: Posiciones consistentes de campos
4. **Documentación de excepciones**: Casos especiales o problemáticos

### Fase 2: Creación de Máscaras Base
1. **Herramienta de anotación**: Desarrollo de interfaz para marcar ROIs
2. **Máscaras manuales**: Creación inicial basada en análisis
3. **Validación cruzada**: Pruebas con diferentes muestras
4. **Refinamiento iterativo**: Ajustes basados en resultados

### Fase 3: Entrenamiento Automático
1. **Detección de bloques de texto**: Uso de OpenCV para encontrar áreas con texto
2. **Correlación con campos**: Asociación automática de bloques con campos específicos
3. **Optimización de máscaras**: Ajuste automático de áreas basado en resultados OCR
4. **Validación estadística**: Métricas de precisión y recall

### Fase 4: Sistema de Validación Cruzada
1. **División de datos**: 70% entrenamiento, 20% validación, 10% prueba
2. **Métricas de evaluación**: Precisión por campo, tiempo de procesamiento
3. **Casos edge**: Manejo de credenciales dañadas o parcialmente visibles
4. **Optimización continua**: Mejora basada en datos de producción

## 8. Configuraciones OCR Específicas

### Configuraciones por Tipo de Campo
```json
{
  "ocr_configs": {
    "text_enhanced": {
      "tesseract_config": "--psm 8 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZÁÉÍÓÚÑ ",
      "preprocessing": ["denoise", "sharpen", "contrast_enhance"]
    },
    "date_pattern": {
      "tesseract_config": "--psm 8 -c tessedit_char_whitelist=0123456789/",
      "preprocessing": ["binarize", "morphology_close"]
    },
    "alphanumeric": {
      "tesseract_config": "--psm 8 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
      "preprocessing": ["denoise", "binarize"]
    }
  }
}
```

## 9. Herramientas para Crear Máscaras

### Herramientas Recomendadas
- **GIMP**: Para máscaras precisas y profesionales
- **Photoshop**: Herramientas avanzadas de selección
- **Paint.NET**: Alternativa gratuita y fácil de usar
- **Herramienta personalizada**: Desarrollo de interfaz específica para el proyecto

### Especificaciones Técnicas
- **Formato**: PNG con canal alfa
- **Profundidad**: 8 bits por canal
- **Compresión**: Sin pérdida
- **Tamaño aproximado**: 50-100 KB por máscara

## 10. Consideraciones de Rendimiento

### Optimizaciones
1. **Caché de máscaras**: Almacenamiento en memoria de máscaras frecuentemente usadas
2. **Procesamiento paralelo**: OCR simultáneo de múltiples ROIs
3. **Escalado inteligente**: Uso de la resolución mínima necesaria
4. **Filtrado temprano**: Descarte de áreas sin texto antes del OCR

### Métricas de Rendimiento
- **Tiempo de procesamiento**: < 3 segundos por credencial
- **Precisión de extracción**: > 95% para campos principales
- **Uso de memoria**: < 100MB durante procesamiento
- **Tamaño de assets**: < 5MB total de máscaras

## 11. Mantenimiento y Actualización

### Proceso de Actualización
1. **Monitoreo continuo**: Análisis de errores en producción
2. **Reentrenamiento periódico**: Actualización con nuevos datos
3. **Versionado de máscaras**: Control de versiones para rollback
4. **Testing automatizado**: Validación de nuevas versiones

### Métricas de Calidad
- **Tasa de éxito por campo**
- **Tiempo promedio de procesamiento**
- **Casos de error más frecuentes**
- **Satisfacción del usuario**

Este enfoque de máscaras binarias proporciona una base sólida y escalable para el reconocimiento preciso de campos en credenciales INE.