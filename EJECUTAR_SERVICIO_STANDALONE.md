# Ejecutar Aplicación con Vista del Servicio INE

## Resumen

Esta guía explica cómo ejecutar la aplicación mostrando directamente la vista del servicio INE (IneServiceActivity) en lugar de la vista principal de Flutter.

## Configuración Realizada

### 1. AndroidManifest.xml Modificado

- **IneServiceActivity** ahora es la actividad principal (LAUNCHER)
- **MainActivity** (Flutter) es secundaria y no se exporta
- La aplicación se abre directamente en el servicio INE

### 2. Modo Standalone Implementado

Cuando la aplicación se abre sin parámetros específicos:
- Usa automáticamente imagen de prueba: `/data/local/tmp/test_credencial_back.jpg`
- Configura lado por defecto: "reverso"
- Si no encuentra la imagen, activa modo test con datos mock

## Métodos para Ejecutar

### Método 1: Usando VS Code (Recomendado)

1. **Abrir VS Code**:
   - Abre el proyecto en VS Code
   - Ve a "Run and Debug" (Ctrl+Shift+D)

2. **Seleccionar configuración**:
   - Elige "TRAE - Solo Servicio INE (Standalone)" del dropdown
   - Presiona F5 para ejecutar

3. **Resultado**:
   - La aplicación se abrirá directamente en IneServiceActivity
   - Mostrará la interfaz del servicio INE
   - Funcionará en modo standalone

### Método 2: Compilar APK y Ejecutar

1. **Compilar APK**:
   ```bash
   flutter build apk --debug
   ```

2. **Instalar en dispositivo**:
   ```bash
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

3. **Abrir aplicación**:
   - Desde el launcher del dispositivo
   - O usando ADB: `adb shell am start -n com.example.atom_ocr_ai_m_v3/.IneServiceActivity`

### Método 3: Línea de Comandos

```bash
flutter run --dart-define=STANDALONE_INE_SERVICE=true --dart-define=SERVICE_ID=TRAE
```

## Preparación de Imágenes de Prueba

### Subir Imagen de Prueba (Opcional)

Para mejor experiencia, sube una imagen de credencial INE:

```bash
# Imagen del reverso (por defecto)
adb push ruta/local/credencial_reverso.jpg /data/local/tmp/test_credencial_back.jpg

# Imagen frontal (opcional)
adb push ruta/local/credencial_frontal.jpg /data/local/tmp/test_credencial_front.jpg
```

### Sin Imagen de Prueba

Si no subes imagen:
- La aplicación detectará automáticamente que no existe
- Activará modo test con datos mock
- Podrás probar la funcionalidad sin imagen real

## Interfaz del Servicio Standalone

### Elementos de la UI

1. **Título**: "Servicio de Procesamiento INE"
2. **Preview de Imagen**: Muestra la imagen a procesar
3. **Información del Lado**: Indica si es frontal o reverso
4. **Barra de Progreso**: Durante el procesamiento
5. **Estado**: Información del modo actual
6. **Botones**:
   - "Procesar": Inicia el procesamiento
   - "Cancelar": Cancela la operación

### Estados de la Aplicación

**Modo Standalone con Imagen**:
```
Modo Standalone - Lado: REVERSO
Aplicación iniciada en modo standalone
Usando imagen de prueba: /data/local/tmp/test_credencial_back.jpg
```

**Modo Test (sin imagen)**:
```
Modo Test - Usando datos de ejemplo
Presiona 'Procesar' para ver resultado mock
```

## Monitoreo y Logs

### Ver Logs en Tiempo Real

```bash
# Logs generales del servicio
adb logcat | Select-String -Pattern "IneServiceActivity"

# Logs específicos de modo standalone
adb logcat | Select-String -Pattern "standalone|Standalone"

# Logs de procesamiento
adb logcat | Select-String -Pattern "procesada|resultado|MRZ"
```

### Logs Esperados

```
IneServiceActivity: Modo standalone detectado - usando valores por defecto
IneServiceActivity: Configurando modo standalone
IneServiceActivity: Imagen de prueba no encontrada, usando modo test
```

## Funcionalidades Disponibles

### En Modo Standalone

1. **Procesamiento Real**: Si hay imagen de prueba
2. **Procesamiento Mock**: Si no hay imagen
3. **Interfaz Completa**: Todos los elementos UI funcionan
4. **Logs Detallados**: Para debugging
5. **Manejo de Errores**: Graceful error handling

### Resultados

**Con Imagen Real**:
- Procesamiento completo de credencial INE
- Extracción de datos reales
- Respuesta JSON estructurada

**Modo Test**:
- Datos mock predefinidos
- Simulación de procesamiento exitoso
- Respuesta JSON de ejemplo

## Ventajas del Modo Standalone

1. **Inicio Rápido**: No carga Flutter innecesariamente
2. **Enfoque Específico**: Solo funcionalidad INE
3. **Debugging Fácil**: Logs específicos del servicio
4. **Pruebas Directas**: Sin navegación adicional
5. **Menor Consumo**: Menos recursos que la app completa

## Volver a la Aplicación Principal

Para volver a usar MainActivity como principal:

1. Editar `AndroidManifest.xml`
2. Mover intent-filter MAIN/LAUNCHER de IneServiceActivity a MainActivity
3. Cambiar `android:exported="true"` en MainActivity
4. Recompilar la aplicación

## Solución de Problemas

### La aplicación no se abre
- Verificar que el APK esté instalado correctamente
- Revisar logs: `adb logcat | grep -i error`
- Verificar permisos en AndroidManifest.xml

### No se muestra la imagen
- Verificar que existe: `adb shell ls -la /data/local/tmp/`
- Usar modo test si no hay imagen disponible
- Revisar permisos de lectura del archivo

### El procesamiento falla
- Verificar logs de IneServiceActivity
- Probar con modo test primero
- Verificar inicialización de Flutter bridge

## Comandos Útiles

```bash
# Forzar cierre de la app
adb shell am force-stop com.example.atom_ocr_ai_m_v3

# Limpiar datos de la app
adb shell pm clear com.example.atom_ocr_ai_m_v3

# Verificar actividad principal
adb shell dumpsys package com.example.atom_ocr_ai_m_v3 | grep -A 5 -B 5 MAIN

# Abrir directamente el servicio
adb shell am start -n com.example.atom_ocr_ai_m_v3/.IneServiceActivity
```

Esta configuración te permite ejecutar la aplicación mostrando directamente la vista del servicio INE, ideal para desarrollo, testing y demostraciones específicas del procesamiento de credenciales.