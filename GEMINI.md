## Resumen del Proyecto

Esta es una aplicación Flutter llamada "Atom OCR AI Mobile v3". Es una aplicación móvil para el reconocimiento óptico de caracteres (OCR) con un enfoque en el procesamiento de credenciales del INE de México. Utiliza GetX para la gestión de estado y la navegación, y Google ML Kit para la funcionalidad de OCR.

La aplicación está estructurada utilizando un enfoque modular, con diferentes módulos para características como `home`, `ocr`, `camera` y `credentials_list`. También incluye servicios para gestionar las preferencias del usuario, la versión de la aplicación, el registro de logs y más.

## Compilación y Ejecución

Para compilar y ejecutar el proyecto, sigue estos pasos:

1.  **Clona el repositorio:**
    ```bash
    git clone <repository-url>
    cd atom-ocr-ai-m-v3
    ```

2.  **Instala las dependencias:**
    ```bash
    flutter pub get
    ```

3.  **Configura las variables de entorno:**
    Crea un archivo `.env` en la raíz del proyecto y añade las variables necesarias.

4.  **Ejecuta la aplicación:**
    ```bash
    flutter run
    ```

## Convenciones de Desarrollo

*   **Gestión de Estado:** El proyecto utiliza GetX para la gestión de estado. Se utilizan controladores para gestionar el estado de cada pantalla y `bindings` para inyectar las dependencias.
*   **Navegación:** GetX también se utiliza para la navegación. Las rutas se definen en el archivo `lib/app/routes/app_pages.dart`.
*   **Arquitectura Modular:** El proyecto está dividido en módulos, donde cada módulo representa una característica. Esto ayuda a mantener el código organizado y mantenible.
*   **Servicios:** El proyecto utiliza servicios para proporcionar funcionalidades comunes, como el registro de logs, las preferencias del usuario y el control de versiones de la aplicación.
*   **Pruebas:** El proyecto incluye pruebas unitarias y de widgets. Ejecuta las pruebas usando el comando `flutter test`.