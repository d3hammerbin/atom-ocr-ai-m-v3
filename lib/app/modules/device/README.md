# Módulo de Información del Dispositivo

Este módulo implementa la funcionalidad para obtener y gestionar información detallada del dispositivo Android utilizando el plugin `device_info_plus`.

## Características Implementadas

### 1. Modelo de Datos (DeviceModel)
- Almacena información completa del dispositivo
- Incluye identificadores únicos (número de serie, ID del dispositivo)
- Información del sistema operativo (versión Android, nivel de API)
- Especificaciones de hardware (modelo, marca, RAM, almacenamiento)
- Arquitecturas soportadas (32-bit, 64-bit)
- Timestamps de creación y actualización

### 2. Servicio de Información del Dispositivo (DeviceInfoService)
- Obtiene información del dispositivo usando `device_info_plus`
- Maneja permisos para acceder al número de serie en Android 10+
- Calcula espacio de almacenamiento disponible y total
- Obtiene información de memoria RAM disponible
- Guarda automáticamente la información en la base de datos

### 3. Repositorio de Dispositivos (DeviceRepository)
- CRUD completo para datos de dispositivos
- Consultas por usuario, número de serie, rango de fechas
- Operaciones de upsert (insertar o actualizar)
- Gestión de dispositivos por usuario

### 4. Controlador y UI (DeviceController & DeviceInfoPage)
- Controlador reactivo usando GetX
- Interfaz de usuario para mostrar información del dispositivo
- Manejo de estados de carga y errores
- Funcionalidad de actualización manual

## Estructura de Archivos

```
lib/app/modules/device/
├── device_binding.dart      # Configuración de dependencias
├── device_controller.dart   # Lógica de negocio
├── device_info_page.dart    # Interfaz de usuario
└── README.md               # Esta documentación

lib/app/data/
├── models/
│   └── device_model.dart    # Modelo de datos
└── repositories/
    └── device_repository.dart # Acceso a datos

lib/app/core/services/
└── device_info_service.dart # Servicio principal
```

## Base de Datos

### Tabla `device`
- `id`: Clave primaria autoincremental
- `user_id`: Referencia al usuario (clave foránea)
- `serial_number`: Número de serie del dispositivo
- `device_id`: ID único del dispositivo
- `android_version`: Versión de Android
- `sdk_int`: Nivel de API de Android
- `model`: Modelo del dispositivo
- `brand`: Marca del dispositivo
- `supported_32_bit_abis`: Arquitecturas de 32 bits soportadas
- `supported_64_bit_abis`: Arquitecturas de 64 bits soportadas
- `supported_abis`: Todas las arquitecturas soportadas
- `physical_ram_size`: Tamaño de RAM física
- `available_ram_size`: RAM disponible
- `free_disk_size`: Espacio libre en disco
- `total_disk_size`: Espacio total en disco
- `is_low_ram_device`: Indicador de dispositivo de baja RAM
- `created_at`: Fecha de creación
- `updated_at`: Fecha de última actualización

## Uso

### 1. Registrar Dependencias
```dart
// En tu archivo de rutas o main.dart
Get.put(DeviceBinding());
```

### 2. Obtener Información del Dispositivo
```dart
final deviceController = Get.find<DeviceController>();
await deviceController.loadDeviceInfo();
```

### 3. Acceder a la Información
```dart
final device = deviceController.currentDevice.value;
print('Modelo: ${device?.model}');
print('Versión Android: ${device?.androidVersion}');
```

### 4. Mostrar la Página de Información
```dart
Get.to(() => const DeviceInfoPage());
```

## Permisos Requeridos

Para Android 10+ (API 29+), se requiere el permiso `READ_PHONE_STATE` para acceder al número de serie:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

## Dependencias

- `device_info_plus: ^11.5.0` - Información del dispositivo
- `permission_handler` - Manejo de permisos (ya incluido)
- `get` - Gestión de estado y dependencias
- `sqflite` - Base de datos local

## Notas Técnicas

1. **Número de Serie**: En Android 10+, requiere permisos especiales. Si no está disponible, se usa el ID del dispositivo como alternativa.

2. **RAM Física**: La propiedad `totalMemory` no está disponible en `device_info_plus`, por lo que se almacena como `null`.

3. **Almacenamiento**: Se calcula usando `path_provider` para obtener el directorio de la aplicación.

4. **Identificación Única**: Se prioriza el número de serie, pero se usa el ID del dispositivo como respaldo.

## Integración con la Arquitectura Existente

Este módulo sigue los patrones establecidos en la aplicación:
- Uso de GetX para gestión de estado
- Patrón Repository para acceso a datos
- Servicios para lógica de negocio
- Modelos con métodos `fromMap`, `toMap`, `copyWith`
- Integración con el sistema de base de datos existente