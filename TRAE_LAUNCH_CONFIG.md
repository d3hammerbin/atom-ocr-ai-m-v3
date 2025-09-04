# Configuración de Launch.json para Servicio INE TRAE

## Configuraciones Disponibles

Se han agregado dos configuraciones específicas para probar el servicio INE con el ID TRAE:

### 1. TRAE - Servicio INE Debug

**Propósito**: Configuración para desarrollo y debugging del servicio INE.

**Parámetros**:
- `ENABLE_INE_SERVICE=true`: Habilita el servicio INE
- `DEBUG_MODE=true`: Activa logs detallados para debugging
- `SERVICE_ID=TRAE`: Identifica el servicio con el ID TRAE

**Uso**: Selecciona esta configuración cuando necesites debuggear el servicio INE paso a paso.

### 2. TRAE - Servicio INE Test Mode

**Propósito**: Configuración para pruebas automáticas del servicio INE.

**Parámetros**:
- `ENABLE_INE_SERVICE=true`: Habilita el servicio INE
- `TEST_MODE=true`: Activa el modo de prueba con datos mock
- `SERVICE_ID=TRAE`: Identifica el servicio con el ID TRAE
- `AUTO_LAUNCH_SERVICE=true`: Lanza automáticamente el servicio al iniciar

**Uso**: Selecciona esta configuración para pruebas rápidas con datos de ejemplo.

## Cómo Usar

1. **En VS Code**:
   - Ve a la pestaña "Run and Debug" (Ctrl+Shift+D)
   - Selecciona una de las configuraciones TRAE del dropdown
   - Presiona F5 o el botón de play

2. **Desde la línea de comandos**:
   ```bash
   # Para modo debug
   flutter run --dart-define=ENABLE_INE_SERVICE=true --dart-define=DEBUG_MODE=true --dart-define=SERVICE_ID=TRAE
   
   # Para modo test
   flutter run --dart-define=ENABLE_INE_SERVICE=true --dart-define=TEST_MODE=true --dart-define=SERVICE_ID=TRAE --dart-define=AUTO_LAUNCH_SERVICE=true
   ```

## Pruebas con ADB

Una vez que la aplicación esté ejecutándose, puedes probar el servicio INE usando comandos ADB:

```bash
# Probar con imagen frontal
adb shell am start -n com.example.atom_ocr_ai_m_v3/com.example.atom_ocr_ai_m_v3.IneServiceActivity -e imagePath "/data/local/tmp/test_credencial.jpg" -e side "frontal" -e testMode "true"

# Probar con imagen reverso
adb shell am start -n com.example.atom_ocr_ai_m_v3/com.example.atom_ocr_ai_m_v3.IneServiceActivity -e imagePath "/data/local/tmp/test_credencial_back.jpg" -e side "reverso" -e testMode "true"
```

## Variables de Entorno Disponibles

- `ENABLE_INE_SERVICE`: Habilita/deshabilita el servicio INE
- `DEBUG_MODE`: Activa logs detallados
- `TEST_MODE`: Usa datos mock para pruebas
- `SERVICE_ID`: Identificador del servicio (TRAE)
- `AUTO_LAUNCH_SERVICE`: Lanza automáticamente el servicio al iniciar

## Logs y Debugging

Cuando uses las configuraciones TRAE, los logs aparecerán en:
- **VS Code**: Debug Console
- **ADB**: `adb logcat | grep -E "(IneServiceActivity|Flutter|TRAE)"`

## Notas Importantes

1. Asegúrate de tener un dispositivo Android conectado o un emulador ejecutándose
2. Las imágenes de prueba deben estar en `/data/local/tmp/` del dispositivo
3. El servicio se ejecuta como una Activity independiente que puede ser invocada por aplicaciones externas
4. En modo test, el servicio usa datos mock predefinidos para simular el procesamiento de credenciales INE