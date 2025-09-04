# Guía de Pruebas - Servicio INE TRAE

## Resumen del Servicio

El servicio INE TRAE es una Activity independiente que procesa credenciales del INE (Instituto Nacional Electoral) y devuelve datos estructurados en formato JSON. Puede ser invocado por aplicaciones externas mediante Intents de Android.

## Configuración Previa

### 1. Preparar el Entorno de Desarrollo

1. **Configurar VS Code**:
   - Abre el proyecto en VS Code
   - Ve a "Run and Debug" (Ctrl+Shift+D)
   - Selecciona "TRAE - Servicio INE Test Mode" del dropdown

2. **Conectar Dispositivo Android**:
   ```bash
   adb devices
   ```
   Verifica que tu dispositivo aparezca en la lista.

### 2. Preparar Imágenes de Prueba

1. **Subir imágenes al dispositivo**:
   ```bash
   # Imagen frontal de credencial INE
   adb push ruta/local/credencial_frontal.jpg /data/local/tmp/test_credencial_front.jpg
   
   # Imagen reverso de credencial INE
   adb push ruta/local/credencial_reverso.jpg /data/local/tmp/test_credencial_back.jpg
   ```

## Métodos de Prueba

### Método 1: Usando Configuraciones de Launch.json

#### Prueba en Modo Debug
1. Selecciona "TRAE - Servicio INE Debug" en VS Code
2. Presiona F5 para iniciar
3. La aplicación se ejecutará con logs detallados
4. Usa comandos ADB para invocar el servicio (ver sección ADB)

#### Prueba en Modo Test
1. Selecciona "TRAE - Servicio INE Test Mode" en VS Code
2. Presiona F5 para iniciar
3. El servicio se lanzará automáticamente con datos mock
4. Revisa los logs en Debug Console

### Método 2: Usando Comandos ADB Directos

#### Compilar e Instalar APK
```bash
# Compilar APK de debug
flutter build apk --debug

# Instalar en dispositivo
adb install build/app/outputs/flutter-apk/app-debug.apk
```

#### Invocar el Servicio INE

**Procesar Credencial Frontal:**
```bash
adb shell am start -n com.example.atom_ocr_ai_m_v3/com.example.atom_ocr_ai_m_v3.IneServiceActivity \
  -e imagePath "/data/local/tmp/test_credencial_front.jpg" \
  -e side "frontal" \
  -e testMode "true"
```

**Procesar Credencial Reverso:**
```bash
adb shell am start -n com.example.atom_ocr_ai_m_v3/com.example.atom_ocr_ai_m_v3.IneServiceActivity \
  -e imagePath "/data/local/tmp/test_credencial_back.jpg" \
  -e side "reverso" \
  -e testMode "true"
```

**Con ResultReceiver (desde otra app):**
```bash
adb shell am start -n com.example.atom_ocr_ai_m_v3/com.example.atom_ocr_ai_m_v3.IneServiceActivity \
  -e imagePath "/data/local/tmp/test_credencial_front.jpg" \
  -e side "frontal" \
  -e testMode "false" \
  -e resultReceiver "com.tu.app.ResultReceiver"
```

### Método 3: Usando TestClient.java

1. **Compilar el cliente de prueba**:
   ```bash
   javac TestClient.java
   ```

2. **Ejecutar pruebas automatizadas**:
   ```bash
   java TestClient
   ```

## Monitoreo de Logs

### Logs Generales del Servicio
```bash
adb logcat | Select-String -Pattern "IneServiceActivity|Flutter|TRAE"
```

### Logs Específicos de Procesamiento
```bash
adb logcat | Select-String -Pattern "procesada|MRZ|JSON|credencial|resultado"
```

### Logs de Errores
```bash
adb logcat | Select-String -Pattern "FATAL|AndroidRuntime|CRASH|Exception|Error"
```

## Resultados Esperados

### Credencial Frontal (Tipo T1)
```json
{
  "success": true,
  "credentialType": "t1",
  "side": "frontal",
  "data": {
    "nombre": "JUAN CARLOS",
    "apellidoPaterno": "PÉREZ",
    "apellidoMaterno": "GONZÁLEZ",
    "fechaNacimiento": "01/01/1990",
    "sexo": "H",
    "domicilio": "CALLE EJEMPLO 123",
    "claveElector": "ABCD123456789"
  }
}
```

### Credencial Reverso (Tipo T2/T3)
```json
{
  "success": true,
  "credentialType": "t3",
  "side": "reverso",
  "data": {
    "mrzContent": "IDMEX2195843952<<06890854440789202140H3112319MEX<01<<12600<1CASTRO<SAAVEDRA<<ROGELI0<ISRAE",
    "fechaVencimiento": "2031",
    "lugarNacimiento": "MÉXICO"
  }
}
```

## Casos de Prueba

### Caso 1: Procesamiento Exitoso
- **Input**: Imagen válida de credencial INE
- **Esperado**: JSON con datos extraídos correctamente
- **Verificar**: Campo `success: true` y datos poblados

### Caso 2: Imagen Inválida
- **Input**: Imagen que no es credencial INE
- **Esperado**: Error con mensaje descriptivo
- **Verificar**: Campo `success: false` y mensaje de error

### Caso 3: Archivo No Encontrado
- **Input**: Ruta de imagen inexistente
- **Esperado**: Error de archivo no encontrado
- **Verificar**: Logs de error y manejo graceful

### Caso 4: Modo Test
- **Input**: Cualquier imagen con `testMode: true`
- **Esperado**: Datos mock predefinidos
- **Verificar**: Respuesta consistente con datos de prueba

## Solución de Problemas

### El servicio no se inicia
1. Verificar que el APK esté instalado: `adb shell pm list packages | grep atom_ocr`
2. Verificar permisos en AndroidManifest.xml
3. Revisar logs de sistema: `adb logcat | grep -i error`

### La imagen no se procesa
1. Verificar que la imagen existe: `adb shell ls -la /data/local/tmp/`
2. Verificar permisos de lectura
3. Probar con modo test para descartar problemas de procesamiento

### No se reciben resultados
1. Verificar implementación de ResultReceiver en app cliente
2. Usar modo test para verificar funcionamiento básico
3. Revisar logs de IneServiceActivity

## Comandos Útiles

```bash
# Limpiar logs
adb logcat -c

# Forzar cierre de la app
adb shell am force-stop com.example.atom_ocr_ai_m_v3

# Verificar actividades disponibles
adb shell dumpsys package com.example.atom_ocr_ai_m_v3 | grep -A 5 -B 5 Activity

# Verificar estado de la app
adb shell dumpsys activity activities | grep atom_ocr
```

## Integración con Aplicaciones Externas

Para integrar el servicio en tu aplicación:

1. **Crear Intent**:
   ```java
   Intent intent = new Intent();
   intent.setComponent(new ComponentName(
       "com.example.atom_ocr_ai_m_v3", 
       "com.example.atom_ocr_ai_m_v3.IneServiceActivity"
   ));
   intent.putExtra("imagePath", "/ruta/a/imagen.jpg");
   intent.putExtra("side", "frontal"); // o "reverso"
   intent.putExtra("testMode", "false");
   ```

2. **Implementar ResultReceiver** (opcional):
   ```java
   intent.putExtra("resultReceiver", myResultReceiver);
   ```

3. **Iniciar servicio**:
   ```java
   startActivity(intent);
   ```

## Notas Importantes

- El servicio procesa credenciales INE de tipos T1, T2 y T3
- Para credenciales T2 y T3 del reverso, devuelve el contenido MRZ
- El modo test usa datos mock para pruebas rápidas
- Los resultados se pueden recibir via ResultReceiver o logs
- La Activity se cierra automáticamente después del procesamiento