# Atom OCR AI Mobile v3

Aplicación móvil Flutter para reconocimiento óptico de caracteres (OCR) con inteligencia artificial.

## Descripción

Atom OCR AI es una aplicación móvil desarrollada en Flutter que permite capturar imágenes y extraer texto utilizando tecnología OCR avanzada. La aplicación está diseñada con una arquitectura limpia utilizando GetX para el manejo de estados y navegación.

## Características

- Captura de imágenes desde cámara
- Selección de imágenes desde galería
- Extracción de texto mediante OCR
- Procesamiento especializado de credenciales INE
- Detección automática de tipos de credenciales
- Servicio INE nativo para Android con procesamiento automático
- Interfaz de usuario intuitiva
- Arquitectura modular con GetX
- Soporte para Android API 33+
- Integración con aplicaciones externas mediante ResultReceiver
- Modo standalone para pruebas y desarrollo

## Tipos de Credenciales INE

El sistema procesa únicamente credenciales **Tipo 2 (T2)** y **Tipo 3 (T3)**, ya que el procesamiento de **Tipo 1 (T1)** ha sido completamente deshabilitado.

### Detección de Tipos de Credencial

La detección del tipo de credencial utiliza un **enfoque híbrido**:

#### Lado Frontal
- Utiliza **análisis de texto OCR** (lógica original)
- Detecta el tipo basándose en campos específicos presentes en el texto extraído
- Mantiene la lógica de detección priorizada existente

#### Lado Reverso
- Utiliza **conteo de códigos QR** para mayor precisión:
  - **Tipo 2 (T2)**: Se identifica por la presencia de **1 código QR**
  - **Tipo 3 (T3)**: Se identifica por la presencia de **3 códigos QR**
  - **Fallback**: Si el conteo no es 1 ni 3, se asume **Tipo 3 (T3)** por defecto

Esta implementación híbrida mantiene el funcionamiento correcto del lado frontal mientras mejora la precisión en la detección del tipo para el procesamiento del lado reverso.

### Tipo 2 - Credenciales con Un Código QR
- **Identificador principal**: Contienen exactamente 1 código QR
- **Características**: Incluyen información geográfica detallada (Estado, Municipio, Localidad)
- **Campos específicos**: Estado, Municipio, Localidad, códigos de barras y MRZ en el reverso
- **Formato de vigencia**: YYYY (año único)
- **Procesamiento**: Extracción de datos del frente y reverso con códigos QR, de barras y MRZ

### Tipo 3 - Credenciales con Múltiples Códigos QR
- **Identificador principal**: Contienen 3 códigos QR
- **Características**: Formato más moderno y simplificado
- **Formato de vigencia**: YYYY-YYYY (rango de años)
- **Validación de nombres**: Normalización automática eliminando números y caracteres especiales
- **Procesamiento**: Extracción optimizada para formato T3 con múltiples códigos QR

La aplicación extrae automáticamente los campos específicos según el tipo detectado y valida la completitud de los datos de acuerdo a las características de cada tipo de credencial.

## Mejoras Recientes

### Sistema de Extracción de Firmas para Credenciales T3
- **Extracción automática de firmas**: Implementación de sistema especializado para extraer firmas de credenciales T3 frontales
- **Detección basada en OCR**: Utiliza reconocimiento de texto para localizar referencias específicas y calcular la región de la firma
- **Referencias de posicionamiento**: Sistema que busca etiquetas clave como "CLAVE DE ELECTOR", "CURP" y "FECHA DE NACIMIENTO" para determinar la ubicación exacta de la firma
- **Algoritmo de cálculo de región**: Calcula automáticamente las coordenadas de la firma basándose en las posiciones de las etiquetas de referencia detectadas
- **Procesamiento de imagen avanzado**: Mejora la calidad de la imagen de la firma extraída mediante técnicas de procesamiento digital
- **Integración con detección facial**: La extracción de firma se activa únicamente cuando se ha detectado y extraído exitosamente la fotografía del rostro
- **Almacenamiento seguro**: Las firmas extraídas se guardan en el directorio de documentos de la aplicación con nombres únicos
- **Visualización en interfaz**: Contenedor especializado en la vista para mostrar la firma extraída junto con los demás datos de la credencial

### Sistema de Extracción de Firma y Huella Digital para Credenciales T2
- **Extracción automática especializada**: Implementación de sistema dedicado para extraer la región de firma y huella digital de credenciales T2
- **Región de extracción optimizada**: Configuración precisa de coordenadas para capturar la zona específica donde se ubican la firma y huella digital
- **Coordenadas calibradas**: Región definida entre 32%-62% de altura y 17.5%-82.5% de ancho para máxima precisión
- **Ajustes de posicionamiento**: Sistema de coordenadas ajustable que permite optimización fina de la región de extracción
- **Procesamiento de imagen especializado**: Técnicas específicas para mejorar la calidad y claridad de la imagen extraída
- **Integración con visualización**: La imagen extraída se muestra automáticamente en la interfaz cuando se detecta una credencial T2
- **Almacenamiento estructurado**: Las imágenes de firma y huella se guardan con nomenclatura específica en el directorio de documentos
- **Validación de tipo**: El sistema se activa únicamente para credenciales identificadas como tipo T2
- **Optimización continua**: Coordenadas ajustables para adaptarse a variaciones en el diseño de credenciales T2

### Optimizaciones del Sistema OCR
- **Inicialización lazy mejorada**: Corrección del error de inicialización múltiple en `MLKitTextRecognitionService` mediante implementación de patrón lazy
- **Búsqueda de texto flexible**: Sistema de detección de referencias con múltiples niveles de flexibilidad para mejorar la precisión
- **Logs de diagnóstico avanzados**: Implementación de sistema de logging detallado con emojis para facilitar la depuración del proceso OCR
- **Búsqueda alternativa amplia**: Mecanismo de fallback que utiliza patrones de texto más amplios cuando la búsqueda exacta no encuentra resultados
- **Manejo robusto de errores**: Sistema de manejo de excepciones mejorado con mensajes descriptivos y recuperación automática

### Optimizaciones para Credenciales T3
- **Normalización de nombres**: Implementación de limpieza automática que elimina números y caracteres especiales de los nombres extraídos
- **Formato de vigencia mejorado**: Soporte completo para el formato YYYY-YYYY específico de credenciales T3
- **Validación especializada**: Sistema de validación que reconoce y acepta el formato de rango de años para vigencia
- **Limpieza de datos**: Eliminación automática de espacios y caracteres no válidos en campos de vigencia
- **Métodos de extracción optimizados**: Algoritmos específicos para el procesamiento eficiente de credenciales T3

### Detección de Lado de Credencial
- **Detección automática**: Sistema que determina si la imagen corresponde al lado frontal o reverso de la credencial
- **Basado en etiquetas de texto**: Utiliza la presencia de etiquetas específicas en el texto extraído para la clasificación
- **Etiquetas frontales identificadoras**:
  - "INSTITUTO NACIONAL ELECTORAL"
  - "CREDENCIAL PARA VOTAR"
  - "CLAVE DE ELECTOR"
  - "CURP"
- **Reglas de detección**:
  - **Lado frontal**: Si contiene una o más etiquetas frontales identificadoras
  - **Lado reverso**: Si no contiene ninguna etiqueta frontal identificadora
- **Características del sistema**:
  - Búsqueda insensible a mayúsculas y minúsculas
  - Nivel de confianza proporcional al número de etiquetas encontradas
  - Aplicable únicamente a credenciales T2 y T3 (T1 deshabilitado completamente)
  - Enfoque híbrido: Análisis OCR para lado frontal, conteo QR para lado reverso
- **Validación de consistencia**: Verifica que el lado detectado contenga los datos esperados según el tipo de credencial

### Sistema Híbrido de Detección de Códigos QR para Credenciales T2 y T3
- **Arquitectura de tres niveles**: Implementación de sistema robusto con múltiples métodos de fallback para detección de códigos QR
- **Detección por Finder Patterns**: Algoritmo principal que detecta patrones de búsqueda QR (1:1:3:1:1) según especificación QR Model 2
- **Respaldo con Google ML Kit**: Segundo nivel que utiliza ML Kit para detección en imagen completa cuando falla el método principal
- **Región fija optimizada**: Tercer nivel de fallback que utiliza región predefinida como último recurso
- **Compatibilidad Android mejorada**: Corrección de errores de MethodChannel mediante uso de archivos temporales en lugar de InputImageMetadata
- **Gestión de memoria optimizada**: Limpieza automática de archivos temporales y cierre de recursos ML Kit
- **Detección inteligente**: Algoritmos que buscan automáticamente patrones característicos del QR Model 2
- **Integración automática**: Sistema que se activa automáticamente durante el procesamiento de credenciales T2 y T3 reverso
- **Manejo robusto de errores**: Sistema de recuperación que garantiza extracción exitosa del código QR
- **Logging detallado**: Sistema de trazabilidad completo para diagnóstico y depuración del proceso de detección
- **Rendimiento optimizado**: Especificación de formato QR para acelerar el procesamiento con ML Kit

### Sistema Híbrido de Detección de Códigos de Barras para Credenciales T2 y T3
- **Arquitectura de tres niveles**: Implementación de sistema robusto con múltiples métodos de fallback para detección de códigos de barras
- **Detección por patrones específicos**: Algoritmo principal que busca patrones característicos de códigos de barras en la región superior izquierda
- **Respaldo con Google ML Kit**: Segundo nivel que utiliza ML Kit para detección de códigos de barras en imagen completa
- **Región fija optimizada**: Tercer nivel de fallback que utiliza región predefinida específica para códigos de barras
- **Compatibilidad mejorada**: Uso de archivos temporales para evitar errores de MethodChannel en Android
- **Gestión de memoria optimizada**: Limpieza automática de archivos temporales y cierre de recursos ML Kit
- **Detección inteligente de tamaño**: Algoritmos que detectan tanto códigos de barras grandes como pequeños
- **Integración automática**: Sistema que se activa automáticamente durante el procesamiento de credenciales T2 y T3 reverso
- **Visualización en interfaz**: Contenedor especializado que muestra la imagen del código de barras extraído y su contenido decodificado
- **Almacenamiento seguro**: Los códigos de barras extraídos se guardan en el directorio de documentos con nombres únicos
- **Logging detallado**: Sistema de trazabilidad completo para diagnóstico del proceso de detección de códigos de barras
- **Manejo robusto de errores**: Sistema de recuperación que garantiza la continuidad del procesamiento aunque falle la detección

### Sistema de Detección MRZ (Machine Readable Zone) para Credenciales T2 y T3
- **Arquitectura híbrida de tres niveles**: Implementación robusta con múltiples métodos de fallback para detección de códigos MRZ
- **Detección por patrones OACI**: Algoritmo principal que busca patrones MRZ estándar (3 líneas x 30 caracteres) según especificaciones OACI
- **Respaldo con Google ML Kit**: Segundo nivel que utiliza ML Kit Text Recognition para detección en imagen completa
- **Región fija optimizada**: Tercer nivel de fallback que utiliza región predefinida en la parte inferior de la credencial
- **Validación de formato**: Sistema que verifica que el MRZ detectado cumpla con el estándar de 90 caracteres (3x30)
- **Formateo automático**: Limpieza y normalización de la cadena MRZ eliminando espacios y saltos de línea
- **Parsing de datos OACI**: Extracción e interpretación de datos según estándares internacionales de documentos de viaje
- **Integración con modelo de datos**: Campos MRZ añadidos al modelo CredencialIneModel para almacenamiento estructurado
- **Procesamiento condicional**: Sistema que procesa MRZ únicamente en credenciales T2 y T3 según el tipo detectado
- **Visualización en interfaz**: Contenedor especializado que muestra la cadena MRZ formateada y sus datos interpretados
- **Almacenamiento seguro**: Los datos MRZ se almacenan de forma estructurada junto con los demás campos de la credencial
- **Logging detallado**: Sistema de trazabilidad completo para diagnóstico del proceso de detección MRZ
- **Manejo robusto de errores**: Sistema de recuperación que garantiza la continuidad del procesamiento aunque falle la detección MRZ

### Sistema de Diagnóstico Avanzado para Detección de Tipos de Credencial
- **Logs de depuración detallados**: Sistema completo de trazabilidad para el proceso de detección de tipos T2 y T3
- **Enfoque híbrido de detección**: Combina análisis de texto OCR (lado frontal) con conteo de códigos QR (lado reverso)
- **Detección frontal por OCR**: Utiliza análisis de texto para identificar tipos basándose en campos específicos presentes
- **Detección reverso por QRs**: Conteo automático de códigos QR para diferenciación precisa entre T2 (1 QR) y T3 (≥2 QRs)
- **Criterio de detección por lado**: Lado frontal usa OCR, lado reverso usa conteo de QRs
- **Compatibilidad mantenida**: Preserva la lógica original de detección frontal mientras mejora la precisión del reverso
- **Método legacy disponible**: Mantenimiento del método anterior de detección por patrones como respaldo
- **Jerarquía híbrida**: OCR (frontal) → Conteo QRs (reverso) → T2 (1 QR) → T3 (≥2 QRs) → T3 (por defecto)
- **Logs sin emojis**: Formato optimizado para compatibilidad con sistemas de logging y depuración
- **Resumen de detección**: Información consolidada del proceso de clasificación híbrido
- **Diagnóstico de errores**: Identificación de casos donde el conteo de QRs no coincide con los valores esperados
- **Trazabilidad completa**: Seguimiento paso a paso del proceso híbrido de detección
- **Procesamiento condicional**: Sistema que solo procesa credenciales T2 y T3, ignorando completamente T1

### Correcciones de Visualización para Credenciales T3
- **Problema identificado**: La interfaz de usuario limitaba la visualización de datos extraídos únicamente a credenciales T2
- **Corrección implementada**: Extensión de condiciones de visualización para incluir credenciales T3 en todas las secciones
- **Secciones corregidas**:
  - **MRZ (Machine Readable Zone)**: Visualización de códigos MRZ formateados para credenciales T2 y T3
  - **Códigos QR**: Mostrar imágenes y contenido de códigos QR extraídos del lado reverso para ambos tipos
  - **Códigos de barras**: Visualización de imágenes y contenido decodificado para credenciales T2 y T3
  - **Campos específicos**: Estado, Municipio y Localidad ahora visibles para ambos tipos de credencial
- **Impacto**: Los datos procesados correctamente para credenciales T3 ahora se muestran completamente en la interfaz
- **Compatibilidad**: Mantiene funcionalidad completa para credenciales T2 mientras habilita visualización para T3
- **Validación**: Verificación de que todos los campos extraídos se muestren según el tipo de credencial detectado

## Servicio INE Nativo para Android

### Descripción del Servicio
El proyecto incluye un servicio nativo Android (`IneServiceActivity`) que permite el procesamiento automático de credenciales INE mediante integración con aplicaciones externas o uso standalone para pruebas.

### Características del Servicio
- **Procesamiento automático**: Inicia el procesamiento automáticamente cuando se proporcionan imagen y lado
- **Integración externa**: Soporte para `ResultReceiver` para comunicación con aplicaciones cliente
- **Modo standalone**: Capacidad de ejecutarse independientemente para pruebas y desarrollo
- **Detección de lado**: Identificación automática entre lado frontal y reverso de credenciales
- **Soporte multi-tipo**: Compatible con credenciales T2 y T3 (T1 deshabilitado)
- **Interfaz nativa**: UI Android nativa con Material Design y tema oscuro

### Modos de Operación

#### 1. Modo Aplicación Externa
- Requiere `ResultReceiver` para envío de resultados
- Procesamiento automático al recibir imagen y lado
- Cierre automático después de completar el procesamiento
- Ideal para integración con aplicaciones cliente

#### 2. Modo Test/Standalone
- Activado con parámetro `testMode="true"`
- Procesamiento automático sin `ResultReceiver`
- Interfaz completa para visualización de resultados
- Perfecto para pruebas y desarrollo

#### 3. Modo Manual
- Sin `ResultReceiver` ni `testMode`
- Requiere interacción del usuario (botón "PROCESAR")
- Control manual del flujo de procesamiento

### Parámetros de Entrada
- `image_path`: Ruta absoluta de la imagen a procesar
- `side`: Lado de la credencial ("frontal" o "reverso")
- `testMode`: Modo de prueba ("true" para activar)
- `imageUri`: URI alternativo para la imagen (opcional)

### Flujo de Procesamiento Automático
1. **Inicialización**: La actividad recibe parámetros del intent
2. **Carga de imagen**: Se carga la imagen desde `image_path` o `imageUri`
3. **Inicialización del bridge**: Se configura el puente con Flutter
4. **Procesamiento automático**: Se inicia si se cumplen las condiciones:
   - `bitmap != null` (imagen cargada)
   - `side != null` (lado especificado)
   - `resultReceiver != null` O `testMode == "true"`
5. **Resultado**: Se envía vía `ResultReceiver` o se muestra en interfaz

### Uso mediante ADB
```bash
# Procesamiento frontal
adb shell am start -n com.example.atom_ocr_ai_m_v3/.IneServiceActivity \
  --es image_path "/data/local/tmp/credencial_front.jpg" \
  --es side "frontal" \
  --es testMode "true"

# Procesamiento reverso
adb shell am start -n com.example.atom_ocr_ai_m_v3/.IneServiceActivity \
  --es image_path "/data/local/tmp/credencial_back.jpg" \
  --es side "reverso" \
  --es testMode "true"
```

### Integración con Aplicaciones Cliente
```java
// Ejemplo de integración desde aplicación cliente
Intent intent = new Intent();
intent.setComponent(new ComponentName(
    "com.example.atom_ocr_ai_m_v3", 
    "com.example.atom_ocr_ai_m_v3.IneServiceActivity"
));
intent.putExtra("image_path", imagePath);
intent.putExtra("side", "frontal");
intent.putExtra("resultReceiver", resultReceiver);
startActivity(intent);
```

### Datos Extraídos
El servicio extrae y estructura los siguientes datos según el tipo de credencial:

#### Credenciales T2 y T3
- **Datos personales**: Nombre, apellidos, CURP, clave de elector
- **Información temporal**: Fecha de nacimiento, año de registro, vigencia
- **Datos geográficos**: Domicilio, sección, estado, municipio, localidad
- **Datos biométricos**: Fotografía, firma (T2: firma+huella, T3: solo firma)
- **Códigos**: QR, códigos de barras, MRZ (Machine Readable Zone)

### Arquitectura del Servicio
- **IneServiceActivity.kt**: Actividad principal Android nativa
- **Bridge Flutter**: Comunicación con servicios Flutter de procesamiento
- **MLKit Integration**: Reconocimiento de texto y códigos
- **Material Design UI**: Interfaz nativa con tema oscuro optimizado
- **Gestión de memoria**: Limpieza automática de recursos y archivos temporales

### Validaciones Mejoradas
- **Vigencia flexible**: Soporte para formatos YYYY (T2) y YYYY-YYYY (T3)
- **Nombres limpios**: Validación que asegura que los nombres contengan solo letras y espacios
- **Consistencia de datos**: Aplicación uniforme de reglas de limpieza y validación
- **Validación de lado**: Verificación de que el lado detectado sea consistente con el tipo y contenga los datos esperados

## Estructura del Proyecto

```
lib/
├── app/
│   ├── core/
│   │   ├── utils/
│   │   ├── values/
│   │   └── widgets/
│   ├── data/
│   │   ├── models/
│   │   ├── providers/
│   │   └── repositories/
│   ├── global_widgets/
│   ├── modules/
│   │   ├── home/
│   │   ├── ocr/
│   │   └── camera/
│   └── routes/
└── main.dart
```

## Requisitos

- Flutter SDK 3.7.0+
- Dart 3.0+
- Android SDK API 33+
- iOS 11.0+

## Instalación

1. Clona el repositorio:
```bash
git clone <repository-url>
cd atom-ocr-ai-m-v3
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Configura las variables de entorno en el archivo `.env`

4. Ejecuta la aplicación:
```bash
flutter run
```

## Configuración

La aplicación utiliza un archivo `.env` para la configuración. Las variables principales incluyen:

- `APP_NAME`: Nombre de la aplicación
- `OCR_PROVIDER`: Proveedor de OCR
- `OCR_LANGUAGE`: Idioma para el reconocimiento
- `CAMERA_QUALITY`: Calidad de la cámara

## Arquitectura

El proyecto sigue una arquitectura limpia con separación de responsabilidades:

- **Modules**: Contiene las funcionalidades principales (Home, OCR, Camera)
- **Core**: Utilidades, valores y widgets compartidos
- **Data**: Modelos, proveedores y repositorios
- **Routes**: Configuración de navegación con GetX

## Dependencias Principales

- `get`: Manejo de estados y navegación
- `google_mlkit_text_recognition`: Reconocimiento óptico de caracteres (OCR)
- `image_picker`: Captura y selección de imágenes
- `flutter`: Framework de desarrollo

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT.

## Contacto

Para más información, contacta al equipo de desarrollo.
