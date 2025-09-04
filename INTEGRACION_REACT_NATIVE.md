# Integración del Servicio INE con React Native

Esta documentación describe cómo integrar el servicio de procesamiento de credenciales INE mexicanas con aplicaciones React Native usando un Android Service nativo.

## Arquitectura

La solución está compuesta por tres componentes principales:

1. **Android Service Nativo** (`android_ine_service`): Servicio enlazado que expone el procesamiento de credenciales INE mediante AIDL
2. **Native Module de React Native** (`react_native_ine_module`): Módulo que conecta React Native con el Android Service
3. **Motor de Procesamiento Flutter**: Lógica de procesamiento existente en el proyecto `atom-ocr-ai-m-v3`

## Componentes del Android Service

### Interfaces AIDL

- **`IIneProcessorService.aidl`**: Interfaz principal del servicio
- **`IIneProcessorCallback.aidl`**: Interfaz de callback para comunicación asíncrona
- **`CredentialResult.aidl`**: Definición del objeto parcelable para resultados

### Clases Java

- **`IneProcessorService.java`**: Implementación del servicio Android
- **`IneProcessingWorker.java`**: Worker de WorkManager para procesamiento en background
- **`IneNativeProcessor.java`**: Puente entre el servicio Android y el motor Flutter
- **`CredentialResult.java`**: Modelo de datos parcelable para resultados
- **`IneProcessingResultReceiver.java`**: Receptor de resultados para comunicación asíncrona

## Componentes del Native Module

### Módulo React Native

- **`IneProcessorModule.java`**: Módulo nativo que conecta con el Android Service
- **`IneProcessorPackage.java`**: Paquete que registra el módulo en React Native
- **`index.ts`**: API TypeScript para JavaScript/React Native

## Instalación y Configuración

### 1. Configuración del Android Service

#### Agregar al `settings.gradle` del proyecto principal:

```gradle
include ':android_ine_service'
project(':android_ine_service').projectDir = new File(rootProject.projectDir, '../android_ine_service')
```

#### Agregar al `build.gradle` de la app:

```gradle
dependencies {
    implementation project(':android_ine_service')
}
```

#### Configurar en `AndroidManifest.xml` de la app:

```xml
<!-- Agregar permisos -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- Declarar el servicio -->
<service
    android:name="mx.d3c.dev.ine.IneProcessorService"
    android:enabled="true"
    android:exported="true"
    android:foregroundServiceType="dataProcessing">
    <intent-filter>
        <action android:name="mx.d3c.dev.ine.INE_PROCESSOR_SERVICE" />
    </intent-filter>
</service>
```

### 2. Configuración del Native Module

#### Instalar el paquete npm:

```bash
npm install react-native-ine-processor
# o
yarn add react-native-ine-processor
```

#### Para React Native < 0.60, agregar manualmente:

**android/settings.gradle:**
```gradle
include ':react-native-ine-processor'
project(':react-native-ine-processor').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-ine-processor/android')
```

**android/app/build.gradle:**
```gradle
dependencies {
    implementation project(':react-native-ine-processor')
}
```

**MainApplication.java:**
```java
import com.ineprocessor.IneProcessorPackage;

@Override
protected List<ReactPackage> getPackages() {
    return Arrays.<ReactPackage>asList(
        new MainReactPackage(),
        new IneProcessorPackage() // Agregar esta línea
    );
}
```

## Uso en React Native

### Importación

```typescript
import IneProcessor, {
  processCredential,
  processCredentialAsync,
  isValidCredential,
  CredentialResult,
  ProcessingConfig,
  ErrorCode
} from 'react-native-ine-processor';
```

### Procesamiento Síncrono

```typescript
const processImage = async (imagePath: string) => {
  try {
    const config: ProcessingConfig = {
      strictValidation: true,
      validateCurp: true,
      validateClaveElector: true,
      timeoutMs: 30000
    };
    
    const result: CredentialResult = await processCredential(imagePath, config);
    
    if (result.acceptable) {
      console.log('Credencial procesada:', result);
      console.log('Nombre:', result.nombre);
      console.log('CURP:', result.curp);
      console.log('Clave de elector:', result.claveElector);
    } else {
      console.log('Credencial no aceptable:', result.errorMessage);
    }
  } catch (error) {
    console.error('Error procesando credencial:', error);
  }
};
```

### Procesamiento Asíncrono con Callbacks

```typescript
const processImageAsync = async (imagePath: string) => {
  try {
    const taskId = await processCredentialAsync(
      imagePath,
      {
        strictValidation: true,
        ocrMode: 'accurate'
      },
      {
        onProgress: (progress) => {
          console.log(`Progreso: ${progress.progress}% - ${progress.status}`);
        },
        onComplete: (taskId, result) => {
          console.log('Procesamiento completado:', result);
        },
        onError: (taskId, errorCode, errorMessage) => {
          console.error('Error:', errorCode, errorMessage);
        },
        onCancelled: (taskId) => {
          console.log('Procesamiento cancelado:', taskId);
        }
      }
    );
    
    console.log('Tarea iniciada:', taskId);
    
    // Opcionalmente cancelar después de 10 segundos
    setTimeout(async () => {
      const cancelled = await cancelTask(taskId);
      console.log('Tarea cancelada:', cancelled);
    }, 10000);
    
  } catch (error) {
    console.error('Error iniciando procesamiento:', error);
  }
};
```

### Validación de Credencial

```typescript
const validateImage = async (imagePath: string) => {
  try {
    const isValid = await isValidCredential(imagePath);
    
    if (isValid) {
      console.log('La imagen contiene una credencial INE válida');
      // Proceder con el procesamiento completo
      await processImage(imagePath);
    } else {
      console.log('La imagen no parece ser una credencial INE');
    }
  } catch (error) {
    console.error('Error validando imagen:', error);
  }
};
```

### Verificación del Servicio

```typescript
const checkService = async () => {
  try {
    const isAvailable = await isServiceAvailable();
    
    if (isAvailable) {
      const serviceInfo = await getServiceInfo();
      console.log('Servicio disponible:', serviceInfo);
    } else {
      console.log('Servicio no disponible');
    }
  } catch (error) {
    console.error('Error verificando servicio:', error);
  }
};
```

## Tipos de Datos

### CredentialResult

```typescript
interface CredentialResult {
  // Datos del lado frontal - Comunes para T2 y T3
  nombre?: string;
  domicilio?: string;
  claveElector?: string;
  curp?: string;
  anoRegistro?: string;
  fechaNacimiento?: string;
  sexo?: string;
  seccion?: string;
  vigencia?: string;
  
  // Datos del lado frontal - Específicos para T2
  apellidoPaterno?: string; // Solo credenciales T2
  apellidoMaterno?: string; // Solo credenciales T2
  estado?: string; // Solo credenciales T2
  municipio?: string; // Solo credenciales T2
  localidad?: string; // Solo credenciales T2
  emision?: string; // Solo credenciales T2
  
  // Datos del MRZ (lado reverso)
  mrzContent?: string;
  mrzDocumentNumber?: string;
  mrzNationality?: string;
  mrzBirthDate?: string;
  mrzExpiryDate?: string;
  mrzSex?: string;
  mrzName?: string;
  
  // Metadatos del procesamiento
  tipo?: CredentialType; // 't2' | 't3'
  lado?: CredentialSide; // 'frontal' | 'reverso'
  
  // Rutas de imágenes extraídas
  photoPath?: string;
  signaturePath?: string;
  qrContent?: string;
  qrImagePath?: string;
  barcodeContent?: string;
  barcodeImagePath?: string;
  mrzImagePath?: string;
  signatureHuellaImagePath?: string;
  
  // Metadatos del procesamiento
  acceptable?: boolean;
  processingTimeMs?: number;
  confidence?: number;
  errorMessage?: string;
}
```

### ProcessingConfig

```typescript
interface ProcessingConfig {
  // Configuración de calidad de imagen
  minImageWidth?: number; // Default: 800
  minImageHeight?: number; // Default: 600
  maxImageSize?: number; // Default: 10MB
  
  // Configuración de OCR
  ocrLanguage?: string; // Default: 'spa'
  ocrMode?: 'fast' | 'accurate'; // Default: 'accurate'
  
  // Configuración de validación
  strictValidation?: boolean; // Default: true
  validateCurp?: boolean; // Default: true
  validateClaveElector?: boolean; // Default: true
  
  // Configuración de timeout
  timeoutMs?: number; // Default: 30000
}
```

## Manejo de Errores

### Códigos de Error

```typescript
enum ErrorCode {
  UNKNOWN = 0,
  FILE_NOT_FOUND = 1,
  INVALID_IMAGE = 2,
  PROCESSING_FAILED = 3,
  SERVICE_UNAVAILABLE = 4,
  PERMISSION_DENIED = 5,
  TIMEOUT = 6,
}
```

### Manejo de Excepciones

```typescript
try {
  const result = await processCredential(imagePath);
  // Procesar resultado
} catch (error) {
  if (error.code === 'SERVICE_NOT_AVAILABLE') {
    console.log('El servicio INE no está disponible');
  } else if (error.code === 'PROCESSING_ERROR') {
    console.log('Error durante el procesamiento:', error.message);
  } else {
    console.log('Error desconocido:', error);
  }
}
```

## Consideraciones de Rendimiento

### Procesamiento en Background

- El servicio utiliza WorkManager para procesamiento en background
- Las tareas no bloquean el hilo principal de React Native
- Se puede procesar múltiples credenciales simultáneamente

### Gestión de Memoria

- Las imágenes se procesan de forma eficiente sin cargar completamente en memoria
- Los resultados se limpian automáticamente después del procesamiento
- Se recomienda limitar el tamaño de imagen a 10MB

### Optimizaciones

```typescript
// Configuración optimizada para velocidad
const fastConfig: ProcessingConfig = {
  ocrMode: 'fast',
  strictValidation: false,
  timeoutMs: 15000
};

// Configuración optimizada para precisión
const accurateConfig: ProcessingConfig = {
  ocrMode: 'accurate',
  strictValidation: true,
  validateCurp: true,
  validateClaveElector: true,
  timeoutMs: 45000
};
```

## Solución de Problemas

### Servicio No Disponible

1. Verificar que el servicio esté declarado en AndroidManifest.xml
2. Confirmar que los permisos estén otorgados
3. Verificar que la aplicación tenga acceso a archivos externos

### Errores de Procesamiento

1. Verificar que la imagen sea válida y legible
2. Confirmar que la imagen contenga una credencial INE
3. Verificar el tamaño y formato de la imagen

### Problemas de Rendimiento

1. Reducir el tamaño de la imagen antes del procesamiento
2. Usar procesamiento asíncrono para múltiples imágenes
3. Implementar cache de resultados si es necesario

## Ejemplo Completo

```typescript
import React, { useState } from 'react';
import { View, Button, Text, Alert } from 'react-native';
import { launchImageLibrary } from 'react-native-image-picker';
import IneProcessor, { CredentialResult } from 'react-native-ine-processor';

const IneProcessorExample = () => {
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

export default IneProcessorExample;
```

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Ver el archivo LICENSE para más detalles.

## Soporte

Para reportar problemas o solicitar características, por favor crear un issue en el repositorio del proyecto.