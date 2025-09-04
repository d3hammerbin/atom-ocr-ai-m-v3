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
- Interfaz de usuario intuitiva
- Arquitectura modular con GetX
- Soporte para Android API 33+

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
- **Campos específicos del lado frontal**: 
  - Apellido Paterno
  - Apellido Materno
  - Estado
  - Municipio
  - Localidad
  - Emisión
- **Campos comunes frontales**: Nombre, Domicilio, Clave de Elector, CURP, Año de Registro, Fecha de Nacimiento, Sexo, Sección, Vigencia
- **Campos del lado reverso**: Códigos QR, códigos de barras y MRZ con datos adicionales
- **Formato de vigencia**: YYYY (año único)
- **Procesamiento**: Extracción diferenciada de datos del frente según campos específicos de T2

### Tipo 3 - Credenciales con Múltiples Códigos QR
- **Identificador principal**: Contienen 3 códigos QR
- **Características**: Formato más moderno y simplificado
- **Campos del lado frontal**: Solo campos comunes (sin información geográfica específica)
- **Campos comunes frontales**: Nombre, Domicilio, Clave de Elector, CURP, Año de Registro, Fecha de Nacimiento, Sexo, Sección, Vigencia
- **Campos del lado reverso**: Múltiples códigos QR y MRZ con datos adicionales
- **Formato de vigencia**: YYYY-YYYY (rango de años)
- **Validación de nombres**: Normalización automática eliminando números y caracteres especiales
- **Procesamiento**: Extracción optimizada para formato T3 sin campos geográficos específicos

### Estructura de Datos Diferenciada

La aplicación implementa una **estructura de datos unificada** que soporta ambos tipos de credencial:

#### Campos Frontales Comunes (T2 y T3)
- `nombre`: Nombre completo del titular
- `domicilio`: Dirección del titular
- `claveElector`: Clave de elector única
- `curp`: CURP del titular
- `anoRegistro`: Año de registro
- `fechaNacimiento`: Fecha de nacimiento
- `sexo`: Sexo del titular
- `seccion`: Sección electoral
- `vigencia`: Vigencia de la credencial

#### Campos Frontales Específicos de T2
- `apellidoPaterno`: Apellido paterno (solo T2)
- `apellidoMaterno`: Apellido materno (solo T2)
- `estado`: Estado de emisión (solo T2)
- `municipio`: Municipio de emisión (solo T2)
- `localidad`: Localidad de emisión (solo T2)
- `emision`: Fecha de emisión (solo T2)

#### Campos MRZ (Lado Reverso)
- `mrzContent`: Contenido completo del MRZ
- `mrzDocumentNumber`: Número de documento del MRZ
- `mrzNationality`: Nacionalidad del MRZ
- `mrzBirthDate`: Fecha de nacimiento del MRZ
- `mrzExpiryDate`: Fecha de expiración del MRZ
- `mrzSex`: Sexo del MRZ
- `mrzName`: Nombre del MRZ

#### Metadatos de Procesamiento
- `tipo`: Tipo de credencial detectado (T2/T3)
- `lado`: Lado del documento procesado (frontal/reverso)
- Rutas de imágenes extraídas (foto, firma, QR, códigos de barras, MRZ)

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
