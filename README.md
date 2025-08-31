# Atom OCR AI Mobile v3

Aplicación móvil Flutter para reconocimiento óptico de caracteres (OCR) con inteligencia artificial.

## Descripción

Atom OCR AI es una aplicación móvil desarrollada en Flutter que permite capturar imágenes y extraer texto utilizando tecnología OCR avanzada. La aplicación está diseñada con una arquitectura limpia utilizando GetX para el manejo de estados y navegación.

## Características

- Captura de imágenes desde cámara
- Selección de imágenes desde galería
- Extracción de texto mediante OCR
- Interfaz de usuario intuitiva
- Arquitectura modular con GetX
- Soporte para Android API 33+

## Estructura del Proyecto

```
lib/
├── app/
│   ├── core/
│   │   ├── utils/
│   │   ├── values/
│   │   └── widgets/
│   ├── data/
│   │   ├── models/
│   │   ├── providers/
│   │   └── repositories/
│   ├── global_widgets/
│   ├── modules/
│   │   ├── home/
│   │   ├── ocr/
│   │   └── camera/
│   └── routes/
└── main.dart
```

## Requisitos

- Flutter SDK 3.7.0+
- Dart 3.0+
- Android SDK API 33+
- iOS 11.0+

## Instalación

1. Clona el repositorio:
```bash
git clone <repository-url>
cd atom-ocr-ai-m-v3
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Configura las variables de entorno en el archivo `.env`

4. Ejecuta la aplicación:
```bash
flutter run
```

## Configuración

La aplicación utiliza un archivo `.env` para la configuración. Las variables principales incluyen:

- `APP_NAME`: Nombre de la aplicación
- `OCR_PROVIDER`: Proveedor de OCR
- `OCR_LANGUAGE`: Idioma para el reconocimiento
- `CAMERA_QUALITY`: Calidad de la cámara

## Arquitectura

El proyecto sigue una arquitectura limpia con separación de responsabilidades:

- **Modules**: Contiene las funcionalidades principales (Home, OCR, Camera)
- **Core**: Utilidades, valores y widgets compartidos
- **Data**: Modelos, proveedores y repositorios
- **Routes**: Configuración de navegación con GetX

## Dependencias Principales

- `get`: Manejo de estados y navegación
- `flutter`: Framework de desarrollo

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT.

## Contacto

Para más información, contacta al equipo de desarrollo.
