# Manual de Instalación Local - Módulo React Native INE

## Descripción

Este manual te guiará paso a paso para instalar el módulo React Native INE de forma local en tu nuevo proyecto. El módulo permite procesar credenciales INE T2 y T3, extrayendo datos tanto del lado frontal como del reverso.

## Requisitos Previos

- React Native >= 0.60.0
- Android SDK configurado
- Node.js >= 14.0.0
- npm o yarn

## Contenido del Paquete

El archivo ZIP contiene:

```
react-native-ine-processor/
├── package.json                 # Configuración del módulo
├── README.md                   # Este manual
├── src/
│   └── index.ts               # API TypeScript del módulo
├── android/
│   ├── build.gradle           # Configuración Gradle del módulo RN
│   └── src/main/              # Código Java del módulo RN
├── android_service/
│   ├── build.gradle           # Configuración del servicio Android
│   └── src/main/              # Servicio nativo Android con AIDL
├── flutter_engine/
│   ├── pubspec.yaml           # Dependencias Flutter
│   └── lib/                   # Motor de procesamiento Flutter
└── examples/
    ├── IneScanner.tsx         # Componente de ejemplo
    └── verifyInstallation.ts  # Script de verificación
```

## Instalación Paso a Paso

### 1. Extraer el Paquete

1. Extrae el archivo `react-native-ine-processor.zip` en la raíz de tu proyecto React Native:

```bash
# En la raíz de tu proyecto React Native
unzip react-native-ine-processor.zip
```

### 2. Instalar como Dependencia Local

2. Agrega la dependencia local en tu `package.json`:

```json
{
  "dependencies": {
    "react-native-ine-processor": "file:./react-native-ine-processor",
    "react-native-image-picker": "^5.0.0"
  }
}
```

3. Instala las dependencias:

```bash
npm install
```

### 3. Configuración Android

#### 3.1 Actualizar settings.gradle

En `android/settings.gradle`, agrega:

```gradle
include ':react-native-ine-processor'
project(':react-native-ine-processor').projectDir = new File(rootProject.projectDir, '../react-native-ine-processor/android')

include ':android-ine-service'
project(':android-ine-service').projectDir = new File(rootProject.projectDir, '../react-native-ine-processor/android_service')

include ':flutter-engine'
project(':flutter-engine').projectDir = new File(rootProject.projectDir, '../react-native-ine-processor/flutter_engine')
```

#### 3.2 Actualizar app/build.gradle

En `android/app/build.gradle`, en la sección `dependencies`:

```gradle
dependencies {
    implementation project(':react-native-ine-processor')
    implementation project(':android-ine-service')
    implementation project(':flutter-engine')
    implementation 'androidx.work:work-runtime:2.8.1'
    implementation 'com.google.mlkit:text-recognition:16.0.0'
    // ... otras dependencias existentes
}
```

#### 3.3 Actualizar AndroidManifest.xml

En `android/app/src/main/AndroidManifest.xml`, agrega los permisos:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />

<application>
    <!-- Servicio INE -->
    <service
        android:name="com.ineprocessor.IneProcessorService"
        android:enabled="true"
        android:exported="false" />
    
    <!-- ... resto de tu configuración -->
</application>
```

#### 3.4 Actualizar MainApplication.java

En `android/app/src/main/java/.../MainApplication.java`:

```java
import com.ineprocessor.IneProcessorPackage;

public class MainApplication extends Application implements ReactApplication {
    // ...
    
    @Override
    protected List<ReactPackage> getPackages() {
        @SuppressWarnings("UnnecessaryLocalVariable")
        List<ReactPackage> packages = new PackageList(this).getPackages();
        
        // Agregar el paquete INE
        packages.add(new IneProcessorPackage());
        
        return packages;
    }
    
    // ...
}
```

### 4. Configuración de Gradle del Proyecto

#### 4.1 Actualizar build.gradle del proyecto

En `android/build.gradle`, asegúrate de tener:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://www.jitpack.io' }
        maven { url 'https://storage.googleapis.com/download.flutter.io' }
    }
}
```

### 5. Limpiar y Reconstruir

```bash
# Limpiar cache de React Native
npx react-native start --reset-cache

# Limpiar proyecto Android
cd android
./gradlew clean
cd ..

# Reconstruir para Android
npx react-native run-android
```

## Uso del Módulo

### Importación Básica

```typescript
import IneProcessor, {
  processCredential,
  isValidCredential,
  CredentialResult,
  ProcessingConfig
} from 'react-native-ine-processor';
```

### Ejemplo de Uso Completo

Copia el archivo `examples/IneScanner.tsx` a tu proyecto y úsalo como referencia:

```typescript
import React, { useState } from 'react';
import { View, Button, Text, Alert } from 'react-native';
import { launchImageLibrary } from 'react-native-image-picker';
import IneProcessor, { CredentialResult } from 'react-native-ine-processor';

const IneScanner = () => {
  const [result, setResult] = useState<CredentialResult | null>(null);
  const [processing, setProcessing] = useState(false);

  const selectAndProcessImage = () => {
    launchImageLibrary({ mediaType: 'photo' }, async (response) => {
      if (response.assets && response.assets[0]) {
        const imagePath = response.assets[0].uri;
        
        setProcessing(true);
        
        try {
          // Verificar si es una credencial válida
          const isValid = await IneProcessor.isValidCredential(imagePath);
          
          if (!isValid) {
            Alert.alert('Error', 'La imagen no parece ser una credencial INE');
            return;
          }
          
          // Procesar la credencial
          const processingResult = await IneProcessor.processCredential(
            imagePath,
            {
              strictValidation: true,
              ocrMode: 'accurate'
            }
          );
          
          setResult(processingResult);
          
          if (processingResult.acceptable) {
            Alert.alert('Éxito', 'Credencial procesada correctamente');
          } else {
            Alert.alert('Advertencia', 'Credencial procesada pero con errores');
          }
          
        } catch (error) {
          Alert.alert('Error', `Error procesando credencial: ${error.message}`);
        } finally {
          setProcessing(false);
        }
      }
    });
  };

  return (
    <View style={{ padding: 20 }}>
      <Button
        title={processing ? 'Procesando...' : 'Seleccionar y Procesar INE'}
        onPress={selectAndProcessImage}
        disabled={processing}
      />
      
      {result && (
        <View style={{ marginTop: 20 }}>
          <Text>Nombre: {result.nombre}</Text>
          <Text>CURP: {result.curp}</Text>
          <Text>Clave de Elector: {result.claveElector}</Text>
          <Text>Tipo: {result.tipo}</Text>
          <Text>Aceptable: {result.acceptable ? 'Sí' : 'No'}</Text>
        </View>
      )}
    </View>
  );
};

export default IneScanner;
```

## Estructura de Datos

### CredentialResult

El resultado del procesamiento incluye:

```typescript
interface CredentialResult {
  // Datos comunes (T2 y T3)
  nombre?: string;
  domicilio?: string;
  claveElector?: string;
  curp?: string;
  fechaNacimiento?: string;
  sexo?: string;
  
  // Datos específicos T2
  apellidoPaterno?: string; // Solo credenciales T2
  apellidoMaterno?: string; // Solo credenciales T2
  estado?: string; // Solo credenciales T2
  municipio?: string; // Solo credenciales T2
  
  // Datos MRZ (lado reverso)
  mrzContent?: string;
  mrzDocumentNumber?: string;
  mrzNationality?: string;
  mrzBirthDate?: string;
  mrzExpiryDate?: string;
  mrzSex?: string;
  
  // Metadatos
  tipo?: 't2' | 't3';
  lado?: 'frontal' | 'reverso';
  acceptable?: boolean;
  confidence?: number;
  errorMessage?: string;
}
```

## Verificación de Instalación

Usa el script `examples/verifyInstallation.ts` para verificar que todo esté funcionando:

```typescript
import { verifyIneProcessor } from './react-native-ine-processor/examples/verifyInstallation';

// En tu componente principal
useEffect(() => {
  verifyIneProcessor().then(isWorking => {
    console.log('Módulo INE funcionando:', isWorking);
  });
}, []);
```

## Solución de Problemas

### Error: "Module not found"
1. Verificar que la carpeta `react-native-ine-processor` esté en la raíz del proyecto
2. Ejecutar `npm install` nuevamente
3. Limpiar cache: `npx react-native start --reset-cache`

### Error: "Service not available"
1. Verificar permisos en AndroidManifest.xml
2. Confirmar que el servicio esté declarado correctamente
3. Revisar que las dependencias Gradle estén configuradas

### Error de compilación Android
1. Limpiar proyecto: `cd android && ./gradlew clean`
2. Verificar versiones de dependencias en build.gradle
3. Revisar configuración de settings.gradle

### Problemas de rendimiento
1. Reducir tamaño de imagen antes del procesamiento
2. Usar configuración `ocrMode: 'fast'` para velocidad
3. Implementar procesamiento asíncrono

## Configuraciones Recomendadas

### Para Velocidad
```typescript
const fastConfig: ProcessingConfig = {
  ocrMode: 'fast',
  strictValidation: false,
  timeoutMs: 15000
};
```

### Para Precisión
```typescript
const accurateConfig: ProcessingConfig = {
  ocrMode: 'accurate',
  strictValidation: true,
  validateCurp: true,
  validateClaveElector: true,
  timeoutMs: 45000
};
```

## Soporte

Para problemas o dudas:
1. Revisar este manual completo
2. Verificar la configuración paso a paso
3. Consultar los logs de Android Studio para errores específicos
4. Probar con el componente de ejemplo incluido

## Licencia

Este módulo está licenciado bajo la Licencia MIT.