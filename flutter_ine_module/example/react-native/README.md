# Ejemplo de Integración INE Processor - React Native

Este ejemplo demuestra cómo integrar y usar el módulo INE Processor en una aplicación React Native.

## Características del Ejemplo

- Selección de imágenes desde la galería
- Captura de fotos con la cámara
- Procesamiento de documentos INE
- Visualización de resultados detallados
- Manejo de errores y permisos
- Interfaz de usuario intuitiva

## Requisitos Previos

- React Native 0.70+
- Android SDK 21+
- Módulo INE Processor compilado (archivo AAR)
- Permisos de cámara y almacenamiento

## Instalación

### 1. Configurar el proyecto React Native

```bash
# Crear nuevo proyecto React Native (si no existe)
npx react-native init IneProcessorApp
cd IneProcessorApp

# Instalar dependencias del ejemplo
npm install react-native-image-picker
```

### 2. Configurar el módulo INE Processor

1. Copia el archivo `ine_processor_module-release.aar` a `android/app/libs/`

2. Modifica `android/app/build.gradle`:

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
    // ... otras dependencias
}
```

### 3. Configurar permisos

En `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<uses-feature
    android:name="android.hardware.camera"
    android:required="true" />
<uses-feature
    android:name="android.hardware.camera.autofocus"
    android:required="false" />
```

### 4. Configurar react-native-image-picker

```bash
# Para Android
npx react-native link react-native-image-picker

# O si usas autolinking (RN 0.60+)
cd ios && pod install && cd ..
```

## Uso del Ejemplo

### 1. Copiar el componente

Copia `IneProcessorExample.js` a tu proyecto React Native:

```bash
cp IneProcessorExample.js /path/to/your/react-native-project/src/components/
```

### 2. Integrar en tu aplicación

En tu `App.js` o componente principal:

```javascript
import React from 'react';
import { SafeAreaView } from 'react-native';
import IneProcessorExample from './src/components/IneProcessorExample';

const App = () => {
  return (
    <SafeAreaView style={{ flex: 1 }}>
      <IneProcessorExample />
    </SafeAreaView>
  );
};

export default App;
```

### 3. Ejecutar la aplicación

```bash
# Iniciar Metro
npx react-native start

# En otra terminal, ejecutar en Android
npx react-native run-android
```

## Funcionalidades del Ejemplo

### Selección de Imágenes

- **Galería**: Permite seleccionar imágenes existentes del dispositivo
- **Cámara**: Captura nuevas fotos directamente desde la aplicación
- **Vista previa**: Muestra la imagen seleccionada antes del procesamiento

### Procesamiento de INE

- **Validación**: Verifica que se haya seleccionado una imagen
- **Permisos**: Solicita y verifica permisos necesarios
- **Procesamiento**: Llama al módulo nativo para analizar el documento
- **Resultados**: Muestra información detallada del procesamiento

### Manejo de Resultados

El ejemplo muestra:

- **Estado del procesamiento** (exitoso/error)
- **Texto extraído** mediante OCR
- **Rostros detectados** con nivel de confianza
- **Códigos detectados** (QR/barras) con formato y valor
- **Ruta de imagen procesada**
- **Timestamp** del procesamiento
- **Mensajes de error** detallados

## Estructura del Código

```javascript
// Importaciones necesarias
import { NativeModules } from 'react-native';
const { IneProcessorModule } = NativeModules;

// Función principal de procesamiento
const processIneDocument = async () => {
  try {
    const result = await IneProcessorModule.processIneDocument(imagePath);
    // Manejar resultado exitoso
  } catch (error) {
    // Manejar errores específicos
    switch (error.code) {
      case 'FILE_NOT_FOUND':
        // Archivo no encontrado
        break;
      case 'INVALID_IMAGE_FORMAT':
        // Formato inválido
        break;
      // ... otros casos
    }
  }
};
```

## Personalización

### Estilos

Puedes modificar los estilos en el objeto `styles` al final del archivo:

```javascript
const styles = StyleSheet.create({
  // Personaliza colores, tamaños, etc.
  button: {
    backgroundColor: '#TU_COLOR',
    // ... otros estilos
  },
});
```

### Funcionalidades Adicionales

Puedes extender el ejemplo agregando:

- Guardado de resultados en almacenamiento local
- Envío de datos a un servidor
- Validación adicional de documentos
- Procesamiento por lotes
- Historial de procesamiento

## Solución de Problemas

### Error: "IneProcessorModule is undefined"

1. Verifica que el archivo AAR esté en `android/app/libs/`
2. Confirma la configuración en `build.gradle`
3. Limpia y reconstruye el proyecto:

```bash
cd android
./gradlew clean
cd ..
npx react-native run-android
```

### Error de permisos

1. Verifica los permisos en `AndroidManifest.xml`
2. Solicita permisos en tiempo de ejecución
3. Verifica configuración de `react-native-image-picker`

### Error de dependencias ML Kit

1. Verifica las versiones de las dependencias
2. Asegúrate de que sean compatibles entre sí
3. Limpia la caché de Gradle si es necesario

## Mejores Prácticas

1. **Validación de entrada**: Siempre valida las imágenes antes del procesamiento
2. **Manejo de errores**: Implementa manejo robusto de errores
3. **Permisos**: Solicita permisos de manera apropiada
4. **Performance**: Considera el procesamiento en background para imágenes grandes
5. **UX**: Proporciona feedback visual durante el procesamiento

## Recursos Adicionales

- [Documentación React Native](https://reactnative.dev/docs/getting-started)
- [react-native-image-picker](https://github.com/react-native-image-picker/react-native-image-picker)
- [Google ML Kit](https://developers.google.com/ml-kit)
- [Android Permissions](https://developer.android.com/guide/topics/permissions/overview)

## Soporte

Para problemas específicos del módulo INE Processor, consulta la documentación principal del módulo o contacta al equipo de desarrollo.