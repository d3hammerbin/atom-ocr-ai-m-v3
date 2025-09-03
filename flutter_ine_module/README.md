# INE Processor Module

Módulo Flutter para el procesamiento de documentos de identificación (INE) mexicanos utilizando Google ML Kit. Este módulo proporciona funcionalidades de reconocimiento de texto, detección facial y escaneo de códigos de barras/QR.

## Características

- Reconocimiento de texto OCR en documentos INE
- Detección y análisis facial
- Escaneo de códigos de barras y QR
- Procesamiento de imágenes optimizado
- Integración nativa con React Native
- Soporte completo para Android

## Requisitos del Sistema

### Android
- Android SDK 21 o superior
- Android Gradle Plugin 8.1.4+
- Gradle 8.4+
- Java 17 o superior
- Kotlin 1.9.10+

### Flutter
- Flutter SDK 3.0+
- Dart 3.0+

## Instalación

### 1. Agregar el AAR al proyecto React Native

1. Copia el archivo `ine_processor_module-release.aar` desde `flutter_ine_module/.android/build/outputs/aar/` a tu proyecto React Native en `android/app/libs/`

2. En tu archivo `android/app/build.gradle`, agrega:

```gradle
android {
    ...
    repositories {
        flatDir {
            dirs 'libs'
        }
    }
}

dependencies {
    implementation(name: 'ine_processor_module-release', ext: 'aar')
    implementation 'com.google.mlkit:text-recognition:16.0.0'
    implementation 'com.google.mlkit:face-detection:16.1.5'
    implementation 'com.google.mlkit:barcode-scanning:17.2.0'
    implementation 'androidx.camera:camera-core:1.3.0'
    implementation 'androidx.camera:camera-camera2:1.3.0'
    implementation 'androidx.camera:camera-lifecycle:1.3.0'
    implementation 'androidx.camera:camera-view:1.3.0'
}
```

### 2. Configurar permisos

En tu archivo `android/app/src/main/AndroidManifest.xml`, agrega:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<uses-feature
    android:name="android.hardware.camera"
    android:required="true" />
<uses-feature
    android:name="android.hardware.camera.autofocus"
    android:required="false" />
```

### 3. Configurar ProGuard (Opcional)

Si usas ProGuard, agrega estas reglas en `android/app/proguard-rules.pro`:

```proguard
-keep class com.google.mlkit.** { *; }
-keep class com.atom.ine_processor.** { *; }
-dontwarn com.google.mlkit.**
```

## Uso

### Importar el módulo

```javascript
import { NativeModules } from 'react-native';
const { IneProcessorModule } = NativeModules;
```

### Procesar documento INE

```javascript
// Procesar imagen de INE
const processIne = async (imagePath) => {
  try {
    const result = await IneProcessorModule.processIneDocument(imagePath);
    console.log('Resultado del procesamiento:', result);
    return result;
  } catch (error) {
    console.error('Error procesando INE:', error);
    throw error;
  }
};

// Ejemplo de uso
const imagePath = '/path/to/ine/image.jpg';
processIne(imagePath)
  .then(result => {
    // Manejar resultado exitoso
    console.log('Texto extraído:', result.extractedText);
    console.log('Rostros detectados:', result.facesDetected);
    console.log('Códigos detectados:', result.barcodesDetected);
  })
  .catch(error => {
    // Manejar error
    console.error('Error:', error.message);
  });
```

### Respuesta del procesamiento

El método `processIneDocument` retorna un objeto con la siguiente estructura:

```javascript
{
  "success": true,
  "extractedText": "Texto extraído del documento",
  "facesDetected": [
    {
      "boundingBox": {
        "left": 100,
        "top": 150,
        "right": 300,
        "bottom": 350
      },
      "confidence": 0.95
    }
  ],
  "barcodesDetected": [
    {
      "value": "Contenido del código",
      "format": "QR_CODE",
      "boundingBox": {
        "left": 50,
        "top": 400,
        "right": 250,
        "bottom": 600
      }
    }
  ],
  "processedImagePath": "/path/to/processed/image.jpg",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Manejo de Errores

El módulo puede lanzar los siguientes tipos de errores:

- `FILE_NOT_FOUND`: El archivo de imagen no existe
- `INVALID_IMAGE_FORMAT`: Formato de imagen no soportado
- `PROCESSING_ERROR`: Error durante el procesamiento
- `PERMISSION_DENIED`: Permisos de cámara o almacenamiento denegados

```javascript
try {
  const result = await IneProcessorModule.processIneDocument(imagePath);
} catch (error) {
  switch (error.code) {
    case 'FILE_NOT_FOUND':
      console.error('Archivo no encontrado');
      break;
    case 'INVALID_IMAGE_FORMAT':
      console.error('Formato de imagen inválido');
      break;
    case 'PROCESSING_ERROR':
      console.error('Error de procesamiento');
      break;
    case 'PERMISSION_DENIED':
      console.error('Permisos denegados');
      break;
    default:
      console.error('Error desconocido:', error.message);
  }
}
```

## Compilación del Módulo

Para compilar el módulo desde el código fuente:

```bash
# Navegar al directorio del módulo
cd flutter_ine_module

# Obtener dependencias
flutter pub get

# Compilar AAR
cd .android
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
.\gradlew assembleRelease
```

El archivo AAR se generará en `.android/build/outputs/aar/ine_processor_module-release.aar`

## Estructura del Proyecto

```
flutter_ine_module/
├── lib/
│   ├── ine_processor_module.dart          # Punto de entrada principal
│   ├── services/
│   │   └── ine_processor_service.dart     # Servicio principal
│   ├── models/
│   │   ├── ine_processing_result.dart     # Modelo de resultado
│   │   ├── face_detection_result.dart     # Modelo de detección facial
│   │   └── barcode_detection_result.dart  # Modelo de código de barras
│   └── utils/
│       └── image_utils.dart               # Utilidades de imagen
├── android/
│   └── src/main/kotlin/com/atom/ine_processor/
│       └── IneProcessorPlugin.kt          # Plugin nativo Android
├── .android/                              # Configuración de compilación
├── pubspec.yaml                           # Dependencias Flutter
└── README.md                              # Este archivo
```

## Dependencias

### Flutter
- `google_mlkit_text_recognition`: ^0.11.0
- `google_mlkit_face_detection`: ^0.9.0
- `google_mlkit_barcode_scanning`: ^0.8.0
- `image`: ^4.1.3
- `camera`: ^0.10.5+5
- `path_provider`: ^2.1.1
- `path`: ^1.8.3
- `intl`: ^0.18.1
- `crypto`: ^3.0.3

### Android Nativo
- Google ML Kit Text Recognition
- Google ML Kit Face Detection
- Google ML Kit Barcode Scanning
- AndroidX Camera

## Soporte

Este módulo está diseñado específicamente para el procesamiento de documentos INE mexicanos y utiliza las mejores prácticas de Google ML Kit para garantizar precisión y rendimiento.

## Licencia

Este proyecto es de uso interno y está sujeto a las políticas de la organización.