# Prompt para Aplicación de Pruebas del Servicio INE

## Objetivo

Crear una aplicación Flutter de pruebas que permita invocar y validar el funcionamiento del **Servicio de Procesamiento INE** (`mx.d3c.dev.atom_ocr_ai_m_v3`) desde una aplicación externa.

## Especificaciones del Proyecto

### Metadatos
- **Nombre del proyecto**: `ine_service_tester`
- **ID de paquete**: `com.example.ine_service_tester`
- **Plataforma**: Android únicamente
- **Framework**: Flutter con Dart
- **SDK mínimo**: Android 8.1+ (API 27+)

### Arquitectura y Dependencias

**Gestión de Estado:**
- **GetX** para manejo de estado reactivo, navegación e inyección de dependencias

**Dependencias principales:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.5
  image_picker: ^1.0.4
  path_provider: ^2.1.1
  permission_handler: ^11.0.1
  file_picker: ^6.1.1
```

**Permisos requeridos (android/app/src/main/AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
```

## Funcionalidades Requeridas

### 1. Pantalla Principal de Pruebas

**Componentes de UI:**
- **AppBar** con título "Probador Servicio INE"
- **Selector de imagen**: Botón para seleccionar imagen desde galería o cámara
- **Preview de imagen**: Mostrar imagen seleccionada con dimensiones reducidas
- **Selector de lado**: RadioButtons para "Frontal" y "Reverso"
- **Botón de prueba**: "Invocar Servicio INE" (habilitado solo con imagen seleccionada)
- **Área de resultados**: Sección expandible para mostrar respuesta JSON
- **Indicador de carga**: CircularProgressIndicator durante procesamiento
- **Botones de acción**: Limpiar, Copiar JSON, Compartir resultado

### 2. Servicio de Invocación Nativa

**Implementar clase `IneServiceInvoker`:**

```dart
class IneServiceInvoker {
  static const String TARGET_PACKAGE = "mx.d3c.dev.atom_ocr_ai_m_v3";
  static const String TARGET_ACTIVITY = "mx.d3c.dev.atom_ocr_ai_m_v3.IneServiceActivity";
  
  static Future<Map<String, dynamic>> invokeIneService({
    required String imagePath,
    required String side,
  }) async {
    // Implementar invocación mediante MethodChannel
    // Crear ResultReceiver para recibir respuesta
    // Manejar timeouts y errores
  }
}
```

### 3. Controlador Principal

**Clase `TestController` con GetX:**

```dart
class TestController extends GetxController {
  // Estados observables
  final selectedImagePath = ''.obs;
  final selectedSide = 'frontal'.obs;
  final isProcessing = false.obs;
  final testResult = Rxn<Map<String, dynamic>>();
  final errorMessage = ''.obs;
  
  // Métodos principales
  Future<void> selectImage();
  Future<void> invokeIneService();
  void clearResults();
  void copyJsonToClipboard();
  void shareResult();
}
```

### 4. Interfaz de Usuario Detallada

**Diseño Material 3:**
- **Tema oscuro y claro** con soporte automático
- **Cards elevadas** para cada sección
- **Colores de estado**: Verde para éxito, rojo para errores, azul para información
- **Animaciones suaves** en transiciones de estado
- **Responsive design** para diferentes tamaños de pantalla

**Secciones de la UI:**

1. **Sección de Imagen:**
   - Placeholder cuando no hay imagen
   - Preview con bordes redondeados
   - Información de la imagen (nombre, tamaño, dimensiones)
   - Botón flotante para cambiar imagen

2. **Sección de Configuración:**
   - RadioListTile para selección de lado
   - Información sobre cada opción
   - Validación visual de selección

3. **Sección de Resultados:**
   - **Estado de carga**: Indicador con mensaje "Procesando credencial..."
   - **Resultado exitoso**: JSON formateado con syntax highlighting
   - **Resultado con error**: Mensaje de error con detalles
   - **Métricas**: Tiempo de procesamiento, tamaño de respuesta

4. **Sección de Acciones:**
   - Botón principal: "Probar Servicio INE"
   - Botones secundarios: Limpiar, Copiar, Compartir
   - Estados deshabilitados cuando corresponda

### 5. Manejo de Errores y Validaciones

**Validaciones previas:**
- Verificar que el servicio INE esté instalado
- Validar formato y tamaño de imagen
- Confirmar permisos de almacenamiento
- Verificar conectividad entre aplicaciones

**Manejo de errores:**
- **Servicio no encontrado**: Mensaje con instrucciones de instalación
- **Timeout**: Reintentos automáticos con límite
- **Errores de permisos**: Guía para otorgar permisos
- **Errores de formato**: Sugerencias de imágenes válidas

### 6. Funcionalidades Adicionales

**Historial de pruebas:**
- Almacenar últimas 10 pruebas realizadas
- Mostrar timestamp, imagen usada y resultado
- Opción para repetir prueba anterior

**Configuración avanzada:**
- Timeout configurable (5-30 segundos)
- Modo debug con logs detallados
- Exportar logs de prueba

**Utilidades:**
- Validador de JSON de respuesta
- Comparador de resultados entre pruebas
- Generador de reportes de prueba

## Estructura de Archivos Sugerida

```
lib/
├── main.dart
├── app/
│   ├── controllers/
│   │   └── test_controller.dart
│   ├── services/
│   │   ├── ine_service_invoker.dart
│   │   ├── image_service.dart
│   │   └── storage_service.dart
│   ├── widgets/
│   │   ├── image_selector_widget.dart
│   │   ├── side_selector_widget.dart
│   │   ├── result_display_widget.dart
│   │   └── action_buttons_widget.dart
│   ├── views/
│   │   └── test_screen.dart
│   └── utils/
│       ├── constants.dart
│       ├── validators.dart
│       └── formatters.dart
```

## Casos de Prueba a Implementar

### Casos Exitosos
1. **Credencial frontal válida**: Imagen clara de lado frontal
2. **Credencial reverso válida**: Imagen clara de lado reverso
3. **Diferentes resoluciones**: Probar con imágenes de distintos tamaños
4. **Diferentes formatos**: JPG, PNG, WEBP

### Casos de Error
1. **Imagen no válida**: Archivo que no es imagen
2. **Credencial no INE**: Imagen de otro documento
3. **Imagen borrosa**: Calidad insuficiente para OCR
4. **Lado incorrecto**: Especificar lado contrario al real
5. **Servicio no instalado**: Cuando el APK del servicio no está presente

### Casos Límite
1. **Imágenes muy grandes**: > 10MB
2. **Imágenes muy pequeñas**: < 100KB
3. **Timeout**: Procesamiento que excede tiempo límite
4. **Múltiples invocaciones**: Llamadas simultáneas al servicio

## Criterios de Éxito

**Funcionalidad:**
- ✅ Invocación exitosa del servicio INE
- ✅ Recepción y parseo correcto de respuestas JSON
- ✅ Manejo robusto de errores y timeouts
- ✅ Interfaz intuitiva y responsive

**Rendimiento:**
- ✅ Tiempo de respuesta < 10 segundos para imágenes típicas
- ✅ Uso eficiente de memoria durante procesamiento
- ✅ Sin memory leaks en uso prolongado

**Usabilidad:**
- ✅ Flujo de prueba claro y directo
- ✅ Feedback visual apropiado en cada estado
- ✅ Mensajes de error comprensibles
- ✅ Documentación de uso incluida

## Entregables

1. **Código fuente completo** de la aplicación Flutter
2. **APK de pruebas** compilado y firmado
3. **Documentación de uso** con capturas de pantalla
4. **Reporte de pruebas** con casos ejecutados y resultados
5. **Guía de instalación** y configuración

## Notas Técnicas

- **Comunicación nativa**: Usar MethodChannel para invocar intents de Android
- **Gestión de archivos**: Implementar copia temporal de imágenes si es necesario
- **Permisos runtime**: Solicitar permisos dinámicamente en Android 6+
- **Compatibilidad**: Probar en diferentes versiones de Android (8.1 - 14)
- **Optimización**: Redimensionar imágenes grandes antes de enviar al servicio

## Consideraciones de Seguridad

- **Validación de entrada**: Verificar tipos y tamaños de archivo
- **Limpieza de datos**: Eliminar archivos temporales después de uso
- **Permisos mínimos**: Solicitar solo permisos estrictamente necesarios
- **Manejo de datos sensibles**: No almacenar información de credenciales procesadas

Esta aplicación servirá como herramienta de validación y demostración del servicio de procesamiento INE, permitiendo verificar su correcto funcionamiento desde aplicaciones externas.