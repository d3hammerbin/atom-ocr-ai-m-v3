# Guía de Integración React Native

Esta guía detalla los pasos específicos para integrar el módulo Flutter INE Processor en tu aplicación React Native.

## Pasos de Integración

### 1. Compilar el Módulo Flutter

```bash
cd flutter_ine_module
flutter pub get
flutter build aar
```

### 2. Configurar el Proyecto React Native

#### Agregar al `android/settings.gradle`:
```gradle
include ':flutter_ine_module'
project(':flutter_ine_module').projectDir = new File('../flutter_ine_module/android')
```

#### Modificar `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }
}

dependencies {
    implementation project(':flutter_ine_module')
    
    // Dependencias de Google ML Kit (si no están incluidas)
    implementation 'com.google.mlkit:text-recognition:16.0.0'
    implementation 'com.google.mlkit:face-detection:16.1.5'
    implementation 'com.google.mlkit:barcode-scanning:17.2.0'
    
    // Otras dependencias...
}
```

#### Actualizar `MainApplication.java` o `MainApplication.kt`:

**Java:**
```java
import com.atom.ine_processor.IneProcessorPackage;

public class MainApplication extends Application implements ReactApplication {
    // ...
    
    @Override
    protected List<ReactPackage> getPackages() {
        return Arrays.<ReactPackage>asList(
            new MainReactPackage(),
            new IneProcessorPackage() // Agregar esta línea
        );
    }
}
```

**Kotlin:**
```kotlin
import com.atom.ine_processor.IneProcessorPackage

class MainApplication : Application(), ReactApplication {
    // ...
    
    override fun getPackages(): List<ReactPackage> {
        return listOf(
            MainReactPackage(),
            IneProcessorPackage() // Agregar esta línea
        )
    }
}
```

### 3. Configurar Permisos

#### Agregar al `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permisos requeridos -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- Características de hardware -->
    <uses-feature 
        android:name="android.hardware.camera" 
        android:required="true" />
    <uses-feature 
        android:name="android.hardware.camera.autofocus" 
        android:required="false" />
    
    <application>
        <!-- Metadatos para Google ML Kit -->
        <meta-data
            android:name="com.google.mlkit.vision.DEPENDENCIES"
            android:value="ocr,face,barcode" />
        
        <!-- Tu actividad principal -->
        <activity android:name=".MainActivity">
            <!-- ... -->
        </activity>
    </application>
</manifest>
```

### 4. Instalar Dependencias JavaScript

```bash
npm install react-native-image-picker
# o
yarn add react-native-image-picker
```

### 5. Configurar react-native-image-picker

#### Para Android, agregar al `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### 6. Implementar en tu Componente

```javascript
import React from 'react';
import IneProcessorExample from './path/to/react_native_integration';

const App = () => {
  return <IneProcessorExample />;
};

export default App;
```

## Estructura de Archivos Recomendada

```
tu-proyecto-rn/
├── android/
│   ├── app/
│   │   ├── build.gradle (modificado)
│   │   └── src/main/
│   │       ├── AndroidManifest.xml (modificado)
│   │       └── java/com/tuapp/
│   │           └── MainApplication.java (modificado)
│   └── settings.gradle (modificado)
├── flutter_ine_module/ (módulo Flutter)
├── src/
│   └── components/
│       └── IneProcessor.js (tu implementación)
└── package.json
```

## Solución de Problemas Comunes

### Error: "Module not found"
- Verifica que el módulo esté correctamente agregado en `settings.gradle`
- Asegúrate de que el path del proyecto sea correcto
- Ejecuta `cd android && ./gradlew clean` y luego `npx react-native run-android`

### Error de permisos
- Verifica que todos los permisos estén declarados en `AndroidManifest.xml`
- Solicita permisos en tiempo de ejecución usando `PermissionsAndroid`

### Error de compilación Gradle
- Verifica que las versiones de SDK sean compatibles
- Asegúrate de tener Java 11+ instalado
- Limpia el proyecto: `cd android && ./gradlew clean`

### Error de ML Kit
- Verifica que los metadatos de Google ML Kit estén configurados
- Asegúrate de que las dependencias de ML Kit estén incluidas

## Ejemplo de Uso Básico

```javascript
import { NativeModules } from 'react-native';

const { IneProcessor } = NativeModules;

// Función simple para procesar una credencial
const processIneCredential = async (imagePath) => {
  try {
    const options = {
      extractSignature: true,
      extractPhoto: true,
      enableOcr: true,
      detectQrCodes: true,
      detectBarcodes: true,
      validateData: true,
    };
    
    const result = await IneProcessor.processCredential(imagePath, options);
    
    if (result.success) {
      console.log('Datos extraídos:', result.data);
      return result.data;
    } else {
      console.error('Error:', result.message);
      return null;
    }
  } catch (error) {
    console.error('Error procesando credencial:', error);
    return null;
  }
};
```

## Consideraciones de Rendimiento

- El procesamiento de imágenes puede ser intensivo en recursos
- Considera mostrar un indicador de carga durante el procesamiento
- Optimiza el tamaño de las imágenes antes del procesamiento
- Implementa manejo de errores robusto

## Seguridad

- Los datos de credenciales son sensibles, manéjalos con cuidado
- No almacenes datos de credenciales en texto plano
- Considera encriptar los datos antes de almacenarlos
- Implementa validaciones adicionales en el backend