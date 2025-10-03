## Project Overview

This is a Flutter application called "Atom OCR AI Mobile v3". It's a mobile app for optical character recognition (OCR) with a focus on processing Mexican INE credentials. It uses GetX for state management and navigation, and Google ML Kit for the OCR functionality.

The application is structured using a modular approach, with different modules for features like `home`, `ocr`, `camera`, and `credentials_list`. It also includes services for managing user preferences, app version, logging, and more.

## Building and Running

To build and run the project, follow these steps:

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd atom-ocr-ai-m-v3
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure environment variables:**
    Create a `.env` file in the root of the project and add the necessary variables.

4.  **Run the application:**
    ```bash
    flutter run
    ```

## Development Conventions

*   **State Management:** The project uses GetX for state management. Controllers are used to manage the state of each screen, and bindings are used to inject the dependencies.
*   **Navigation:** GetX is also used for navigation. The routes are defined in the `lib/app/routes/app_pages.dart` file.
*   **Modular Architecture:** The project is divided into modules, with each module representing a feature. This helps to keep the code organized and maintainable.
*   **Services:** The project uses services to provide common functionality, such as logging, user preferences, and app versioning.
*   **Testing:** The project includes unit and widget tests. Run tests using the `flutter test` command.
