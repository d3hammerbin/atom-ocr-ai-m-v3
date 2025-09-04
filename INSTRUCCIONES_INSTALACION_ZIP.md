# 📦 Instalación Rápida - React Native INE Processor

## 🚀 Instalación en 3 Pasos

### 1. Extraer el Paquete
```bash
# En la raíz de tu proyecto React Native
unzip react-native-ine-processor.zip
```

### 2. Instalar como Dependencia Local
```bash
npm install ./react-native-ine-processor
```

### 3. Configurar Android

#### a) Actualizar `android/settings.gradle`:
```gradle
include ':android_ine_service'
project(':android_ine_service').projectDir = new File(rootProject.projectDir, '../react-native-ine-processor/android_service')

include ':flutter_ine_service'
project(':flutter_ine_service').projectDir = new File(rootProject.projectDir, '../react-native-ine-processor/flutter_engine/android')
```

#### b) Actualizar `android/app/build.gradle`:
```gradle
dependencies {
    implementation project(':android_ine_service')
    implementation project(':flutter_ine_service')
    // ... otras dependencias
}
```

#### c) Actualizar `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />

<application>
    <service
        android:name="com.ineservice.IneProcessorService"
        android:enabled="true"
        android:exported="false" />
</application>
```

#### d) Actualizar `MainApplication.java`:
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

## 🧹 Limpiar y Reconstruir
```bash
cd android
./gradlew clean
cd ..
npx react-native run-android
```

## 📱 Uso Básico
```typescript
import { processCredential } from 'react-native-ine-processor';

const result = await processCredential({
  imagePath: '/path/to/image.jpg',
  processingConfig: {
    extractFrontData: true,
    extractMRZ: true,
    validateFormat: true
  }
});

console.log('Datos extraídos:', result.frontData);
```

## 📋 Verificación de Instalación
Ejecuta el script incluido:
```typescript
import { verifyInstallation } from './react-native-ine-processor/examples/verifyInstallation';

verifyInstallation();
```

## 🆘 Problemas Comunes

### Error: "Module not found"
```bash
npm install
cd android && ./gradlew clean && cd ..
```

### Error: "Service not available"
- Verifica permisos en AndroidManifest.xml
- Asegúrate de que el servicio esté registrado

### Error de compilación Android
```bash
cd android
./gradlew clean
./gradlew build
```

## 📚 Documentación Completa
Consulta el archivo `README.md` dentro del paquete para documentación detallada.

---

**¿Necesitas ayuda?** Revisa los ejemplos en la carpeta `examples/` del paquete.