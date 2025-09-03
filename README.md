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

La aplicación soporta el procesamiento de tres tipos de credenciales del Instituto Nacional Electoral (INE) de México, clasificadas cronológicamente de la más antigua a la más nueva:

### Tipo 1 - Credenciales Más Antiguas
- **Identificadores**: Contienen los campos "EDAD" y/o "FOLIO"
- **Características**: Formato más antiguo del INE
- **Detección**: Se identifica por la presencia de al menos uno de estos campos específicos

### Tipo 2 - Credenciales Intermedias
- **Identificadores**: Contienen los campos "ESTADO", "MUNICIPIO" y/o "LOCALIDAD"
- **Características**: Incluyen información geográfica detallada
- **Detección**: Se identifica cuando no es Tipo 1 pero contiene campos de ubicación
- **Campos adicionales**: Estado, Municipio, Localidad

### Tipo 3 - Credenciales Más Recientes
- **Identificadores**: No contienen ninguna de las etiquetas específicas de Tipo 1 o Tipo 2
- **Características**: Formato más moderno y simplificado
- **Detección**: Se identifica por exclusión cuando no cumple criterios de tipos anteriores
- **Formato de vigencia**: YYYY-YYYY (rango de años)
- **Validación de nombres**: Normalización automática eliminando números y caracteres especiales
- **Procesamiento especializado**: Métodos optimizados para extracción de datos específicos del formato T3

### Lógica de Detección
1. **Prioridad Tipo 1**: Si contiene "EDAD" o "FOLIO" → Tipo 1
2. **Prioridad Tipo 2**: Si no es Tipo 1 pero contiene "ESTADO", "MUNICIPIO" o "LOCALIDAD" → Tipo 2
3. **Por defecto Tipo 3**: Si no contiene ninguna etiqueta específica → Tipo 3

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
  - Aplicable a todos los tipos de credencial (T1, T2, T3, T4)
- **Validación de consistencia**: Verifica que el lado detectado contenga los datos esperados según el tipo de credencial

### Sistema Híbrido de Detección de Códigos QR
- **Arquitectura de tres niveles**: Implementación de sistema robusto con múltiples métodos de fallback para detección de códigos QR
- **Detección por Finder Patterns**: Algoritmo principal que detecta patrones de búsqueda QR (1:1:3:1:1) según especificación QR Model 2
- **Respaldo con Google ML Kit**: Segundo nivel que utiliza ML Kit para detección en imagen completa cuando falla el método principal
- **Región fija optimizada**: Tercer nivel de fallback que utiliza región predefinida como último recurso
- **Compatibilidad Android mejorada**: Corrección de errores de MethodChannel mediante uso de archivos temporales en lugar de InputImageMetadata
- **Gestión de memoria optimizada**: Limpieza automática de archivos temporales y cierre de recursos ML Kit
- **Detección inteligente**: Algoritmos que buscan automáticamente patrones característicos del QR Model 2
- **Manejo robusto de errores**: Sistema de recuperación que garantiza extracción exitosa del código QR
- **Logging detallado**: Sistema de trazabilidad completo para diagnóstico y depuración del proceso de detección
- **Rendimiento optimizado**: Especificación de formato QR para acelerar el procesamiento con ML Kit

### Sistema Híbrido de Detección de Códigos de Barras para Credenciales T2
- **Arquitectura de tres niveles**: Implementación de sistema robusto con múltiples métodos de fallback para detección de códigos de barras
- **Detección por patrones específicos**: Algoritmo principal que busca patrones característicos de códigos de barras en la región superior izquierda
- **Respaldo con Google ML Kit**: Segundo nivel que utiliza ML Kit para detección de códigos de barras en imagen completa
- **Región fija optimizada**: Tercer nivel de fallback que utiliza región predefinida específica para códigos de barras T2
- **Compatibilidad mejorada**: Uso de archivos temporales para evitar errores de MethodChannel en Android
- **Gestión de memoria optimizada**: Limpieza automática de archivos temporales y cierre de recursos ML Kit
- **Detección inteligente de tamaño**: Algoritmos que detectan tanto códigos de barras grandes como pequeños
- **Integración automática**: Sistema que se activa automáticamente durante el procesamiento de credenciales T2
- **Visualización en interfaz**: Contenedor especializado que muestra la imagen del código de barras extraído y su contenido decodificado
- **Almacenamiento seguro**: Los códigos de barras extraídos se guardan en el directorio de documentos con nombres únicos
- **Logging detallado**: Sistema de trazabilidad completo para diagnóstico del proceso de detección de códigos de barras
- **Manejo robusto de errores**: Sistema de recuperación que garantiza la continuidad del procesamiento aunque falle la detección

### Sistema de Detección MRZ (Machine Readable Zone) para Credenciales T2
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
- **Logs de depuración detallados**: Implementación de sistema de logging exhaustivo en el método de detección de tipos
- **Análisis de texto completo**: Registro del texto completo extraído por OCR para diagnóstico de problemas de reconocimiento
- **Detección de etiquetas específicas**: Logging de todas las etiquetas T1 y T2 encontradas durante el análisis
- **Patrones de reverso T2**: Registro detallado de patrones específicos detectados en el lado reverso de credenciales T2
- **Resumen de detección**: Logging del proceso completo de clasificación con justificación del tipo asignado
- **Patrones mejorados para T2**: Implementación de patrones adicionales para detectar credenciales T2 con texto corto o mal reconocido
- **Optimización de compatibilidad**: Eliminación de caracteres especiales en logs para garantizar compatibilidad con sistemas de logging
- **Diagnóstico de OCR**: Herramientas para identificar problemas de reconocimiento de texto que afecten la clasificación
- **Validación de consistencia**: Sistema que verifica la coherencia entre el tipo detectado y el contenido de la credencial

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
