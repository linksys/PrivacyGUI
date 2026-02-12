# Linksys App

This is a Flutter-based application for managing Linksys networking devices. It provides a comprehensive interface for users to monitor and control their network settings, connected devices, and other router functionalities.

## 🚀 Overview

The Linksys App allows users to interact with their Linksys routers both locally and remotely via the cloud. It is designed to provide a seamless and intuitive user experience for managing a home network.

### Key Features:
- **Dashboard:** At-a-glance view of your network status, connected devices, and internet speed.
- **Wi-Fi Settings:** Manage your main and guest Wi-Fi networks, including passwords, security types, and channel settings.
- **Device Management:** View all devices connected to your network, prioritize them, and block unwanted devices.
- **Parental Controls:** (If applicable) Set up rules and schedules for internet access.
- **Advanced Settings:** Configure port forwarding, DMZ, firewall settings, and more.
- **Network Troubleshooting:** Tools to diagnose and resolve common network issues.

## 📂 Project Structure

The repository is organized as a standard Flutter project with the following key directories:

-   `lib/`: Contains all the Dart source code for the application.
    -   `lib/main.dart`: The main entry point of the application.
    -   `lib/app.dart`: The root widget of the application.
    -   `lib/core/`: Core functionalities like Bluetooth, HTTP communication, caching, and JNAP (Linksys's API protocol).
    -   `lib/page/`: Contains the UI and business logic for different pages/screens of the app.
    -   `lib/providers/`: State management using Riverpod.
    -   `lib/route/`: Navigation logic using `go_router`.
    -   `lib/util/`: Utility classes and helper functions.
-   `assets/`: Static assets like icons and images.
-   `test/`: Unit and widget tests.
-   `integration_test/`: Integration tests for the application.
-   `tools/`: Helper scripts for development.
-   `plugins/`: Local custom plugins.

## 🏁 Getting Started

Follow these instructions to get the project up and running on your local machine for development and testing purposes.

### Prerequisites

-   [Flutter SDK](https://flutter.dev/docs/get-started/install): Ensure you have a recent version of Flutter installed (>=3.3.0).
-   [Dart SDK](https://dart.dev/get-dart): Ensure you have a compatible Dart version installed (>=3.0.0).
-   An IDE like [VS Code](https://code.visualstudio.com/) with the Flutter plugin or [Android Studio](https://developer.android.com/studio).

### Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd privacy_gui
    ```

2.  **Install dependencies:**
    Run the following command to fetch all the required packages.
    ```bash
    flutter pub get
    ```

### Running the Application

1.  **Connect a device:**
    Make sure you have a simulator/emulator running or a physical device connected.

2.  **Run the app:**
    ```bash
    flutter run
    ```

## 📦 Building for Production

This repository includes shell scripts to simplify the build process for different platforms:

-   **Web:**
    ```bash
    # Usage: ./build_web.sh <buildNumber> <force> <href> <cloud> <picker> <ca> [themeSource] [themeJson]

    # Example with default theme
    ./build_web.sh 100 false "/" prod false true normal ""

    # Example with theme override
    ./build_web.sh 100 false "/" prod false true cicd '{"style":"flat","colorScheme":{"primary":"#FF5722"}}'
    ```

    **Parameters:**
    - `buildNumber`: Build version number
    - `force`: Force rebuild (true/false)
    - `href`: Base href for web deployment
    - `cloud`: Cloud environment (prod/qa/dev)
    - `picker`: Enable environment picker (true/false)
    - `ca`: Certificate authority setting
    - `themeSource` (optional): Theme source override (normal/cicd/network/assets/default)
    - `themeJson` (optional): JSON string for theme configuration

## 🧪 Running Tests

This project contains several types of tests.

### Functional Unit Tests (Non-UI)

To run the suite of functional (non-UI) unit tests, use the provided script. This will execute all tests that are not tagged as `golden`, `loc`, or `ui`.

```bash
./run_tests.sh
```

### Screenshot Tests (Golden Files)

For running screenshot tests, which verify UI consistency, use the `run_generate_loc_snapshots.sh` script. This script specifically runs tests tagged with `loc`.

-   **Run all screenshot tests (default settings)**:
    ```bash
    ./run_generate_loc_snapshots.sh
    ```

-   **Run with specific locales and screen sizes**:
    ```bash
    # Test for Spanish and Japanese with screen widths of 400 and 800
    ./run_generate_loc_snapshots.sh -l "es,ja" -s "400,800"
    ```

-   **Run a single test file**:
    ```bash
    ./run_generate_loc_snapshots.sh -f test/page/your/specific_test.dart
    ```

For more details on creating and updating screenshot tests, refer to [SCREENSHOT_TESTING.md](SCREENSHOT_TESTING.md).

### UI Widget Tests

To run tests that are specifically tagged for UI widgets (and are not screenshot tests), you can use the following command:

```bash
flutter test --tags ui

```

## ♿ Accessibility (WCAG)

PrivacyGUI adheres to WCAG 2.1 Level AA standards. For detailed documentation on accessibility testing, integration, and compliance analysis, please refer to the **[Accessibility Documentation](doc/accessibility/README.md)**.

## Contributing

Please follow the existing code style and conventions. Ensure that any new feature or bug fix is accompanied by relevant tests.