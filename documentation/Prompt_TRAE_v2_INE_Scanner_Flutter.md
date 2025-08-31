# Prompt TRAE v2 — **INE Credential Scanner (Flutter, Offline, Android-first)**

> **Objetivo:** Generar una app móvil **100% offline** que escanee credenciales INE (frente y reverso), extraiga datos estructurados y lea QR Model 2. El objetivo es **Android únicamente**, con arquitectura **Flutter** optimizada para Android.

---

## 0) Metadatos del proyecto
- **Nombre de proyecto:** `atom_ocr_ai_m_v2`
- **ID de paquete (Android):** `mx.d3c.dev.atom_ocr_ai_m_v2`
- **Lenguaje:** Flutter (Dart) + nativo Android (Kotlin) vía Platform Channels/FFI
- **Modo:** Offline estricto (sin red); si no hay conectividad, la app sigue funcionando.
- **Build:** Android 8.1+ (SDK 27+) recomendado; target SDK actual.

---

## 1) Stack técnico (offline, open‑source)
1) **Flutter UI** para toda la interfaz.
2) **Manejador de estados:** **GetX** para gestión reactiva de estado, navegación, inyección de dependencias y controladores.
3) **Cámara y preview:** `camera` (o `camerax` vía plugin) con **análisis de frames** a baja resolución paralelo al preview.
4) **Lectura de QR (reverso):** **ZXing** embebido (Android: `zxing-android-embedded`) expuesto a Flutter; alternativa `qr_code_scanner` si cumple offline.
5) **OCR (frente y MRZ opcional):** **Tesseract** on-device (spa+eng). Android: `tesseract4android`/`tess-two` vía NDK; expuesto a Flutter.
6) **Procesamiento de imagen:** **OpenCV** (Android NDK) para: detección de documento, dewarp, binarización adaptativa, deblur, métricas de calidad, segmentación de firma y recorte de foto.
7) **Validadores/Reglas:** lógica Dart pura (regex, checksums, fechas).

> **Nota:** No usar servicios cloud. Todos los modelos (`.traineddata` de Tesseract y libs nativas) se empaquetan en el APK/AAB. Los datos se almacenan localmente.

---

## 2) Historias de usuario clave
- **US-01 (Escaneo guiado):** Como ciudadano, quiero una guía visual que me ayude a alinear la credencial para obtener una captura válida con retroalimentación en tiempo real (nitidez, enfoque, exposición, skew, glare).
- **US-02 (Extracción Frente):** Como operador, quiero extraer `${NOMBRE}`, `${SEXO}`, `${DOMICILIO}`, `${CLAVE_DE_ELECTOR}`, `${CURP}`, `${AÑO_DE_REGISTRO}`, `${FECHA_DE_NACIMIENTO}`, `${SECCION}`, `${VIGENCIA}`, **foto** y **firma** del frente.
- **US-03 (Lectura Reverso):** Como operador, quiero leer el **código QR Model 2** del reverso (obligatorio) y, de forma opcional, **MRZ**.
- **US-04 (Modo offline):** Como institución, necesito que todo funcione **sin Internet** y que los datos se procesen localmente.
- **US-05 (Exportación local):** Como operador, quiero revisar y exportar el JSON resultante al almacenamiento local o compartir por intent nativo (si procede).
- **US-06 (Almacenamiento oculto):** Como usuario, quiero que las imágenes capturadas se almacenen en una carpeta oculta del dispositivo para mayor privacidad.
- **US-07 (Compartir datos):** Como operador, quiero poder compartir los datos capturados directamente desde la aplicación usando intents nativos de Android.
- **US-08 (Logs de debug):** Como desarrollador, quiero que la aplicación genere y guarde logs detallados cuando esté en modo debug para facilitar la resolución de problemas.

---

## 3) Flujo del usuario
1. **Pantalla de inicio**: Formulario moderno con estilo oscuro y bordes redondeados que contiene:
   - **Dos botones de selección** de lado del documento:
     - **Frontal** (estado normal)
     - **Reverso** (estado normal)
   - **Botón principal** con ícono de cámara y texto "Iniciar Captura" (habilitado cuando se selecciona un lado)
   - **Sección secundaria** "Documentos Guardados" que muestra acceso rápido para ver documentos procesados
   - **Diseño centrado** con espaciado suficiente entre controles, tipografía clara y jerarquía visual marcada en títulos y botones
2. **Cámara con overlay**: marco con proporción de la credencial; indicadores en tiempo real (nitidez, exposición, skew, glare).
   - **Guías de alineación visual**: Overlay transparente basado en máscaras PNG ubicadas en `./assets/roi_templates/masks/standard/`:
     - **Frente**: `t1_front.png` - Overlay tenue que muestra las áreas de interés
     - **Reverso**: `t1_back.png` - Overlay tenue que muestra las áreas de interés
   - **Interpretación de máscaras**:
     - **Zonas grises** (RGB 128,128,128): Esquinas de referencia para alineación
     - **Zonas negras** (RGB 0,0,0): Áreas descartables que no requieren alineación
     - **Zonas blancas** (RGB 255,255,255): Áreas de interés críticas que deben estar bien alineadas
   - **Implementación del overlay**: Transparencia del 30-40% sobre la vista de cámara para permitir visualización clara del documento mientras se proporciona guía de alineación
   - **Retroalimentación visual**: Cambio de color del overlay (verde cuando está bien alineado, amarillo para ajustes menores, rojo para mala alineación)
3. Auto-disparo o botón **capturar** cuando la calidad ≥ umbrales.
4. **Pipeline de procesamiento** (en segundo plano con indicador de progreso).
5. **Vista de verificación**: Formulario moderno con estilo oscuro y bordes redondeados que contiene:
   - **Título principal**: "Resultados de la Captura"
   - **Vista previa** de la identificación escaneada (imagen centrada)
   - **Sección "Texto Completo (Sin Tratar)"**: Bloque multilínea con salida bruta del OCR
   - **Sección "Datos Estructurados"** con campos listados:
     - Nombre, Sexo, Clave, CURP, Clave de Registro
     - Año de Registro, Fecha de Nacimiento, Sección, Vigencia
   - **Tres botones de acción** (parte inferior):
     - **Guardar** (azul con ícono de disco)
     - **Cancelar** (estilo neutro)
     - **Compartir** (con ícono de compartir)
   - **Jerarquía visual**: títulos en negritas, bloques separados, botones alineados horizontalmente
6. **Guardar/Exportar** JSON + imágenes recortadas (frente, reverso, foto, firma).

---

## 4) Requisitos funcionales (detallados)
### 4.1 Guía visual y calidad en tiempo real
- Overlay con marco del documento y reglas (“alinear bordes”, “evitar reflejos”).
- **Métricas** (cada ~200–300 ms):
  - **Nitidez:** Varianza del Laplaciano ≥ `V_LAP_MIN` (p.ej. 120).
  - **Exposición:** Histograma; brillo medio en rango [`B_MIN`,`B_MAX`].
  - **Skew:** Ángulo del rectángulo mínimo de contornos del documento ≤ `SKEW_MAX` (p.ej. 3°).
  - **Glare:** % de saturación > umbral en highlights ≤ `GLARE_MAX`.
- Semáforo: **Rojo/Ámbar/Verde** + micro‑tips.

### 4.2 Frente — extracción de datos
- **Detección del documento** (OpenCV): bordes → contornos → homografía (dewarp).
- **Zonificación/ROIs por plantilla INE** (JSON de layout por versión).
- **Preprocesado por ROI:** grayscale → blur ligero → **binarización adaptativa** (Sauvola/Nick) → dilate/erode según campo.
- **OCR Tesseract** (spa+eng, whitelist por campo).
- **Post-proceso por campo:** regex, normalización, validadores.
  - `${CURP}`: regex + validación de fecha/ENTIDAD.
  - `${CLAVE_DE_ELECTOR}`: patrón conocido; limpiar artefactos.
  - `${FECHA_DE_NACIMIENTO}`, `${AÑO_DE_REGISTRO}`, `${VIGENCIA}`: parse dd/mm/aaaa o aa.
  - `${SEXO}`: mapear {H/M} a {Hombre/Mujer}.
  - `${DOMICILIO}`: normalizar abreviaturas comunes.
- **Foto del titular**: recorte ROI; guardado como PNG/JPEG.
- **Firma**: segmentación por umbral adaptativo + apertura morfológica; export PNG con fondo blanco.

### 4.3 Reverso — QR y MRZ (opcional)
- **QR obligatorio**: ZXing (Model 2). Soportar desenfoque moderado y rotación.
- **MRZ opcional**: OCR + validación **ICAO 9303** (checksums 7‑3‑1).

---

## 5) Arquitectura y organización de código
```
/lib
  /ui
    home_screen.dart        (pantalla de inicio con formulario moderno)
    camera_overlay.dart
    preview_screen.dart
    review_screen.dart
    export_screen.dart      (exportación controlada)
    widgets/
      quality_badge.dart
      side_selection_buttons.dart  (botones frontal/reverso)
      capture_button.dart          (botón principal con ícono de cámara)
      saved_documents_section.dart (sección de documentos guardados)
      verification_title.dart      (título "Resultados de la Captura")
      id_preview_widget.dart       (vista previa de identificación escaneada)
      raw_text_section.dart        (sección de texto completo sin tratar)
      structured_data_section.dart (sección de datos estructurados)
      action_buttons_row.dart      (fila de botones Guardar/Cancelar/Compartir)
  /controllers
    home_controller.dart         (GetX Controller para pantalla de inicio)
    scan_controller.dart         (GetX Controller para escaneo)
    camera_controller.dart       (GetX Controller para cámara)
    verification_controller.dart (GetX Controller para vista de verificación)
    export_controller.dart       (GetX Controller para exportación)
  /services
    qr_service.dart         (canal a ZXing)
    ocr_service.dart        (canal a Tesseract)
    image_service.dart      (canal a OpenCV)
    template_loader.dart    (layouts INE)
    validators.dart         (CURP, fechas, etc.)
    export_service.dart     (exportación de datos)
    storage_service.dart    (gestión de carpeta oculta para imágenes)
    share_service.dart      (compartir datos capturados)
    logging_service.dart    (logs de debug y errores)
    mask_processor_service.dart  (extracción de ROIs desde máscaras binarias)
    mask_resolution_service.dart (selección automática de resolución óptima)
    dynamic_mask_service.dart    (escalado dinámico de máscaras)
    roi_service.dart            (procesamiento principal con OCR por áreas)
  /models
    ine_front_result.dart
    ine_back_result.dart
    quality_metrics.dart
    export_package.dart     (paquete de exportación)
  /utils
    file_io.dart
/android
  (módulos nativos Kotlin + NDK para OpenCV/Tesseract/ZXing)
/assets
  /tessdata  (spa.traineddata, eng.traineddata)
  /roi_templates
    /masks
      /standard          # 1580x980 - Resolución estándar (DISPONIBLE)
        t1_front.png     # Máscara frontal para overlay y ROI
        t1_back.png      # Máscara reverso para overlay y ROI
      # /high            # 2370x1470 - Resolución alta (FUTURO)
      # /ultra           # 3160x1960 - Resolución máxima (FUTURO)
    /config
      mask_config.json   # Configuración de resoluciones y rutas
      roi_config.json    # Configuración de campos y validaciones OCR
  /templates (ine_vX_layout.json)
```

**Patrón:** UI (Flutter) ←→ **GetX Controllers** ←→ **Capa de dominio** (Dart puro) ←→ **Capa nativa** (Kotlin/NDK).  
**GetX:** Gestión reactiva de estado, navegación, inyección de dependencias y binding de controladores.  
**Canales/FFI:** definir métodos `analyzeFrame()`, `dewarpAndCrop()`, `ocrRoi()`, `readQr()`.  
**Nota:** Las configuraciones de máscaras ROI y templates están disponibles en `./assets/roi_templates/config/` con `mask_config.json` y `roi_config.json`.

---

## 6) Interfaz y accesibilidad
### 6.1 Pantalla de Inicio
- **Formulario moderno** con estilo oscuro y bordes redondeados
- **Botones de selección de lado**:
  - Estado normal: borde gris, texto blanco
  - Estado activo: resaltado en azul (#2196F3), borde azul
- **Botón principal "Iniciar Captura"**:
  - Ícono de cámara (Material Icons: camera_alt)
  - Fondo azul (#2196F3), texto blanco
  - Bordes redondeados (12dp)
  - Elevación sutil (4dp)
- **Sección "Documentos Guardados"**:
  - Título con tipografía secundaria
  - Lista de acceso rápido con iconos
  - Separadores visuales claros
- **Diseño centrado** con padding consistente (16dp)
- **Jerarquía visual**: títulos 18sp bold, subtítulos 16sp medium, texto 14sp regular

### 6.2 Vista de Verificación
- **Formulario moderno** con estilo oscuro y bordes redondeados (12dp)
- **Título principal "Resultados de la Captura"**:
  - Tipografía: 20sp bold, color blanco
  - Centrado con margin superior (24dp)
- **Vista previa de identificación**:
  - Imagen centrada con bordes redondeados (8dp)
  - Sombra sutil (elevation 2dp)
  - Aspect ratio mantenido, max width 280dp
- **Sección "Texto Completo (Sin Tratar)"**:
  - Título: 16sp medium, color gris claro (#B0BEC5)
  - Bloque de texto: fondo gris oscuro (#37474F), padding 12dp
  - Texto monoespaciado (Courier), 12sp, color blanco
  - Scroll vertical habilitado, max height 120dp
- **Sección "Datos Estructurados"**:
  - Título: 16sp medium, color gris claro (#B0BEC5)
  - Campos en lista vertical con separadores
  - Etiquetas: 14sp medium, color gris claro
  - Valores: 14sp regular, color blanco
  - Padding entre campos: 8dp
- **Botones de acción** (parte inferior):
  - **Guardar**: fondo azul (#2196F3), ícono save (Material Icons)
  - **Cancelar**: fondo gris (#616161), sin ícono
  - **Compartir**: fondo verde (#4CAF50), ícono share (Material Icons)
  - Alineación horizontal, spacing 12dp, height 48dp
  - Bordes redondeados (8dp), elevación (2dp)
- **Layout general**: padding 16dp, scroll vertical, spacing entre secciones 20dp

### 6.3 Cámara y Navegación
- **CameraX** en modo continuo; botón captura + autodisparo opcional.
- Overlays con alto contraste; textos ≥ 14sp; soporte **dark mode**.
- **Permisos**: `CAMERA`, almacenamiento (scoped storage).
- Mensajes de error claros y localizados (es-MX).

---

## 7) Rendimiento y límites
- Latencia de lectura **QR** < 200 ms (en frames estables).
- Pipeline frente (dewarp + OCR campos) **< 2.5 s** en gama media.
- Consumo de RAM objetivo **< 220 MB** en procesamiento.
- Apagar OCR en tiempo real; solo tras captura.
- Control térmico: limitar FPS de análisis a 8–12.

---

## 8) Validación y formato de salida
### 8.1 JSON de salida (frente)
```json
{
  "id": "uuid-v4",
  "timestamp": "2024-01-01T12:00:00Z",
  "nombre": "${NOMBRE}",
  "sexo": "${SEXO}",
  "domicilio": "${DOMICILIO}",
  "clave_de_elector": "${CLAVE_DE_ELECTOR}",
  "curp": "${CURP}",
  "anio_registro": "${AÑO_DE_REGISTRO}",
  "fecha_nacimiento": "${FECHA_DE_NACIMIENTO}",
  "seccion": "${SECCION}",
  "vigencia": "${VIGENCIA}",
  "foto_path": "/storage/emulated/0/Android/data/com.app/.hidden/photos/uuid-v4_foto.png",
  "firma_path": "/storage/emulated/0/Android/data/com.app/.hidden/signatures/uuid-v4_firma.png",
  "quality": { "lap_var": 0, "brightness": 0, "skew_deg": 0, "glare_pct": 0 }
}
```

### 8.2 JSON reverso
```json
{
  "id": "uuid-v4",
  "timestamp": "2024-01-01T12:00:00Z",
  "qr_payload": "${QR_DATA}",
  "mrz": "${MRZ_DATA}",
  "front_record_id": "<uuid del registro frontal asociado>"
}
```

### 8.3 Paquete de exportación
```json
{
  "export_id": "uuid-v4",
  "timestamp": "2024-01-01T12:00:00Z",
  "front_data": {
    "record_id": "uuid-v4",
    "data": "<JSON completo del frente con paths de imágenes>"
  },
  "back_data": {
    "record_id": "uuid-v4",
    "data": "<JSON completo del reverso>"
  },
  "image_files": [
    "/storage/emulated/0/Android/data/com.app/.hidden/photos/uuid-v4_foto.png",
    "/storage/emulated/0/Android/data/com.app/.hidden/signatures/uuid-v4_firma.png"
  ]
}
```

---

## 9) Templates INE (versionado)

### 9.1 Archivos de Template Disponibles
- **Máscaras binarias existentes**:
  - `t1_front.png`: Máscara para frente de INE (disponible en `/documentation/masks/`)
  - `t1_back.png`: Máscara para reverso de INE (disponible en `/documentation/masks/`)
  - `t1_front_muestra.jpg` y `t1_back_muestra.jpg`: Imágenes de referencia

### 9.2 Estructura de Template JSON
Archivo `templates/ine_t1_layout.json` con **coordenadas normalizadas** (0..1) basado en máscaras existentes:

```json
{
  "template_id": "ine_t1",
  "version": "1.0",
  "description": "Template para INE basado en máscaras t1_front.png y t1_back.png",
  "front": {
    "mask_file": "t1_front.png",
    "regions": {
      "nombre": { "x": 0.15, "y": 0.25, "width": 0.45, "height": 0.08 },
      "sexo": { "x": 0.15, "y": 0.35, "width": 0.12, "height": 0.06 },
      "domicilio": { "x": 0.15, "y": 0.42, "width": 0.45, "height": 0.12 },
      "clave_elector": { "x": 0.15, "y": 0.58, "width": 0.35, "height": 0.06 },
      "curp": { "x": 0.15, "y": 0.66, "width": 0.35, "height": 0.06 },
      "anio_registro": { "x": 0.15, "y": 0.74, "width": 0.15, "height": 0.06 },
      "fecha_nacimiento": { "x": 0.35, "y": 0.74, "width": 0.20, "height": 0.06 },
      "seccion": { "x": 0.15, "y": 0.82, "width": 0.15, "height": 0.06 },
      "vigencia": { "x": 0.35, "y": 0.82, "width": 0.20, "height": 0.06 },
      "foto": { "x": 0.65, "y": 0.25, "width": 0.25, "height": 0.35 },
      "firma": { "x": 0.65, "y": 0.65, "width": 0.25, "height": 0.15 }
    }
  },
  "back": {
    "mask_file": "t1_back.png",
    "regions": {
      "qr_code": { "x": 0.65, "y": 0.15, "width": 0.30, "height": 0.30 },
      "mrz": { "x": 0.05, "y": 0.85, "width": 0.90, "height": 0.12 }
    }
  }
}
```

### 9.3 Detección y Selección de Template
- **Detección heurística**: Análisis de características específicas del documento
- **Selección automática**: Basada en dimensiones y patrones detectados
- **Fallback manual**: Opción de selección manual si la detección automática falla

---

## 9.4) Sistema de Máscaras ROI y Configuración

### Conceptos de Máscaras Binarias
- **Blanco (RGB 255,255,255)**: Áreas de interés donde extraer texto
- **Negro (RGB 0,0,0)**: Áreas a descartar completamente
- **Gris (RGB 128,128,128)**: Áreas de referencia/alineación para overlay visual

### Configuración de Resoluciones (`mask_config.json`)
**Basado en archivos existentes**: `t1_front.png` y `t1_back.png` disponibles en `/documentation/masks/`

> **Nota**: Por el momento, los templates de mask y ROI están disponibles únicamente para resolución estándar.

```json
{
  "resolution_tiers": {
    "standard": {
      "width": 1580,
      "height": 980,
      "min_input_width": 400,
      "max_input_width": 4000,
      "path": "masks/standard/",
      "files": {
        "front": "t1_front.png",
        "back": "t1_back.png"
      },
      "status": "available"
    }
  },
  "future_resolutions": {
    "high": {
      "width": 2370,
      "height": 1470,
      "status": "planned"
    },
    "ultra": {
      "width": 3160,
      "height": 1960,
      "status": "planned"
    }
  },
  "aspect_ratio": 1.6122,
  "tolerance": 0.1,
  "base_template": "ine_t1",
  "default_resolution": "standard"
}
```

### Configuración de Campos ROI (`roi_config.json`)
```json
{
  "ine_frontal": {
    "mask_file": "t1_front.png",
    "fields": {
      "nombre": {
        "priority": 1,
        "ocr_config": "text_enhanced",
        "validation": "name_pattern"
      },
      "sexo": {
        "priority": 2,
        "ocr_config": "single_char",
        "validation": "gender_pattern"
      },
      "curp": {
        "priority": 1,
        "ocr_config": "alphanumeric",
        "validation": "curp_pattern"
      },
      "fecha_nacimiento": {
        "priority": 2,
        "ocr_config": "date_pattern",
        "validation": "date_format"
      },
      "clave_elector": {
        "priority": 1,
        "ocr_config": "alphanumeric",
        "validation": "clave_pattern"
      }
    }
  },
  "ine_reverso": {
    "mask_file": "t1_back.png",
    "fields": {
      "qr_code": {
        "priority": 1,
        "ocr_config": "qr_detection",
        "validation": "qr_model2"
      },
      "mrz": {
        "priority": 3,
        "ocr_config": "mrz_pattern",
        "validation": "icao_9303"
      }
    }
  }
}
```

### Configuraciones OCR Específicas
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
    },
    "single_char": {
      "tesseract_config": "--psm 10 -c tessedit_char_whitelist=HM",
      "preprocessing": ["binarize", "morphology_open"]
    }
  }
}
```

### Servicios de Procesamiento de Máscaras
- **MaskProcessorService**: Extracción de ROIs desde máscaras binarias
- **MaskResolutionService**: Selección automática de resolución óptima
- **DynamicMaskService**: Escalado dinámico de máscaras según imagen de entrada
- **ROIService**: Procesamiento principal con OCR por áreas de interés

### Especificaciones Técnicas de Máscaras
- **Formato**: PNG sin compresión con canal alfa
- **Profundidad**: 8 bits por canal RGB
- **Tamaño objetivo**: 50-100 KB por máscara
- **Escalado**: Mantener proporción 1.6122 (790x490 base)

---

## 10) Privacidad
- Todo local. No enviar datos fuera del dispositivo.
- Limpieza de temporales tras exportación (opt‑in).
- Registros mínimos y solo técnicos (sin PII en logs).

---

## 11) Pruebas y QA
- **Unitarias** (Dart): validadores (CURP, fechas), parser QR.
- **Instrumentadas** (Android): cámara y canales nativos.
- **Conjuntos de imágenes de prueba** (frente/reverso) empaquetados en `dev_assets/` con diversas condiciones: baja luz, skew, glare, grano.
- **Criterios de aceptación:**
  - ≥ 95% lectura correcta de **QR** en reverso.
  - ≥ 90% exactitud de campos clave en frente con imágenes en foco.
  - Detección de **firma** y **foto** consistente (recorte dentro del ROI > 95%).

---



## 12) Tareas para el generador (TRAE v2)
1. **Crear proyecto Flutter** con la estructura indicada.
2. **Implementar pantalla de inicio** (`home_screen.dart`) con:
   - Formulario moderno con estilo oscuro y bordes redondeados
   - Botones de selección de lado (Frontal/Reverso) con estados visuales
   - Botón principal "Iniciar Captura" con ícono de cámara
   - Sección "Documentos Guardados" para acceso rápido
   - Widgets modulares: `side_selection_buttons.dart`, `capture_button.dart`, `saved_documents_section.dart`
   - Controlador `home_controller.dart` para gestión de estado
3. Implementar **pantalla de cámara** con overlay y semáforo de calidad (usar métricas dummy primero y luego conectar a nativo).
4. Implementar **canal nativo** Android:
   - **ZXing** para `readQr(imageBytes, width, height, rotation)`.
   - **OpenCV** para `detectAndDewarp(docFrame)` y `measureQuality(docFrame)`.
   - **Tesseract** para `ocrRoi(croppedBytes, lang, whitelist)`.
5. Implementar **pipeline de frente**: capturar → dewarp → extraer ROIs → OCR → post-proc → almacenar.
6. Implementar **pipeline de reverso**: lectura QR (obligatoria) + MRZ opcional → almacenar.
7. Añadir **validadores** y normalizadores de datos.
8. **Base de datos**: Configurar SQLite y DAOs para operaciones CRUD.
9. **Sistema de Máscaras ROI**: Implementar servicios completos de procesamiento:
   - `MaskProcessorService`: Carga y procesamiento de máscaras binarias PNG
   - `MaskResolutionService`: Selección automática de resolución (standard/high/ultra)
   - `DynamicMaskService`: Escalado dinámico según dimensiones de entrada
   - `ROIService`: Extracción de texto por áreas de interés con OCR específico
   - Configuración JSON: `mask_config.json` y `roi_config.json` en `assets/roi_templates/config/`
10. **Vista de verificación** (`review_screen.dart`) con:
   - Formulario moderno con estilo oscuro y bordes redondeados
   - Título "Resultados de la Captura" (20sp bold, centrado)
   - Vista previa de identificación escaneada (imagen centrada, bordes redondeados)
   - Sección "Texto Completo (Sin Tratar)" con bloque multilínea scrolleable
   - Sección "Datos Estructurados" con campos: Nombre, Sexo, Clave, CURP, etc.
   - Tres botones de acción: Guardar (azul), Cancelar (gris), Compartir (verde)
   - Widgets modulares: `verification_title.dart`, `id_preview_widget.dart`, `raw_text_section.dart`, `structured_data_section.dart`, `action_buttons_row.dart`
   - Controlador `verification_controller.dart` para gestión de estado y acciones
11. **Sistema de exportación** simple.
12. **Almacenamiento en carpeta oculta**: Implementar `storage_service.dart` para guardar imágenes en directorio oculto (`.ine_scanner/`).
13. **Funcionalidad de compartir**: Implementar `share_service.dart` usando `share_plus` para compartir datos capturados.
14. **Sistema de logging**: Implementar `logging_service.dart` que genere logs detallados solo en modo debug.
15. Scripts **Gradle** y empaquetado con assets (`tessdata`, `templates`, máscaras ROI y configuraciones JSON).

---

## 13) Dependencias (sugeridas)
- Flutter: `camera`, `path_provider`, `permission_handler`, `get` (GetX), `json_serializable`, `share_plus` (compartir archivos), `logger` (logging en debug), `image` (procesamiento de imágenes y máscaras), `path` (manipulación de rutas).
- Base de datos: `sqflite`, `convert`.
- Nativo Android:
  - OpenCV (AAR/NDK).
  - ZXing (`zxing-android-embedded` o core).
  - Tesseract (`tesseract4android`/`tess-two`) + `spa.traineddata`, `eng.traineddata`.
- Evitar libs que requieran red/licencias online.

### Dependencias específicas sugeridas:
- `get: ^4.6.5` (estado)
- `camera: ^0.10.5` (cámara)
- `path_provider: ^2.1.1` (rutas)
- `sqflite: ^2.3.0` (base de datos)
- `share_plus: ^7.2.1` (compartir)
- `permission_handler: ^11.0.1` (permisos)
- `logger: ^2.0.2` (logging)
- `image: ^4.1.3` (procesamiento de imágenes y máscaras)
- `path: ^1.8.3` (manipulación de rutas de archivos)
- `json_serializable: ^6.7.1` (serialización JSON)
- `convert: ^3.1.1` (conversiones de datos)

---

## 14) Entregables
- Proyecto compilable **Android** con CI básico (Gradle).
- APK de **debug** funcional.
- Documentación técnica: cómo compilar, dónde colocar `tessdata`, cómo actualizar templates ROIs, cómo ajustar umbrales de calidad.
- **Guía de exportación**: procedimientos para exportar datos.

---

### Notas finales
- **Prioridad de implementación**: 
  1. Reverso (QR) para cerrar el "camino feliz"
  2. OCR del frente con preprocesado
  3. Almacenamiento en carpeta oculta para imágenes
  4. Sistema de logging en modo debug
  5. Funcionalidad de compartir datos
  6. Sistema de exportación simple
- Mantener los **umbrales** en un archivo de configuración (`assets/config.json`).

> **Fin del prompt. Genera el proyecto y el código base siguiendo estas especificaciones.**
