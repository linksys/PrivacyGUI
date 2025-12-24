# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application (privacy_gui v2.0.0) for managing Linksys networking devices. It provides a comprehensive interface for users to monitor and control their network settings, connected devices, and router functionalities. The app supports both local (Bluetooth/HTTP) and cloud-based device interactions.

## Development Commands

### Dependencies and Setup
```bash
flutter pub get                    # Install dependencies
```

### Running the Application
```bash
flutter run                       # Run on connected device/emulator
```

### Building
```bash
# Web build with parameters: buildNumber, force, href, cloud, picker, ca
./build_web.sh                   # Build for web platform
```

### Testing
```bash
# Functional unit tests (non-UI)
./run_tests.sh                   # Run tests excluding golden, loc, ui tags
./run_tests.sh <reportPath>      # Run tests with HTML report generation

# Screenshot tests (golden files)
./run_generate_loc_snapshots.sh                           # Default settings
./run_generate_loc_snapshots.sh -l "es,ja" -s "400,800"  # Specific locales/screens
./run_generate_loc_snapshots.sh -f test/path/file.dart   # Single test file

# UI widget tests
flutter test --tags ui          # Run UI-tagged tests

# Single test execution
flutter test path/to/test_file.dart
```

## Architecture and Code Organization

### State Management
- **Primary**: Riverpod for reactive state management
- **Pattern**: Provider-based architecture with clear separation of concerns
- **Location**: `lib/providers/` contains all state providers

### Navigation
- **Router**: `go_router` for declarative routing
- **Structure**: Route definitions in `lib/route/`
- **Pattern**: Feature-based route organization

### Core Systems
- **JNAP Protocol**: Custom Linksys API communication (`lib/core/jnap/`)
- **Bluetooth**: Device discovery and pairing (`lib/core/bluetooth/`)
- **HTTP Communication**: REST API interactions (`lib/core/http/`)
- **Caching**: Local data persistence and management (`lib/core/cache/`)

### Feature Organization
```
lib/page/               # Feature-specific pages and screens
├── dashboard/          # Network dashboard and overview
├── advanced_settings/  # Router configuration options
├── instant_setup/      # Device setup workflows
└── [other features]/   # Additional app features
```

### Testing Structure
- **Unit Tests**: `test/` directory with comprehensive coverage
- **Integration Tests**: `integration_test/` for end-to-end scenarios
- **Golden Tests**: Screenshot testing with localization support
- **Test Categories**: Tagged system (golden, loc, ui, functional)

## Key Dependencies and Tools

### Core Flutter Dependencies
- `riverpod` & `flutter_riverpod`: State management
- `go_router`: Navigation and routing
- `http`: Network communication
- `flutter_blue_plus`: Bluetooth connectivity
- `shared_preferences` & `flutter_secure_storage`: Local data storage

### Custom Components
- `privacygui_widgets`: Local plugin in `plugins/widgets/`
- `ui_kit_library`: Shared UI components from external Git repository

### Testing Framework
- `golden_toolkit`: Screenshot testing
- `mockito`: Mocking for unit tests
- `integration_test`: End-to-end testing

## Development Patterns

### Code Style
- Uses `flutter_lints` with custom overrides in `analysis_options.yaml`
- Disables `prefer_const_constructors` rule
- English comments only (per global CLAUDE.md instructions)

### Asset Management
- Icons: `assets/icons/`
- Resources: `assets/resources/`
- Localization: Built-in Flutter i18n with `intl` package

### Build Configuration
- Dart SDK: >=3.0.0 <4.0.0
- Flutter SDK: >=3.3.0 <4.0.0
- Multi-platform support with web-specific build scripts

## Network Device Integration

### JNAP (JSON Network Access Protocol)
- Linksys proprietary protocol for router communication
- Handles device configuration, monitoring, and control
- Located in `lib/core/jnap/` with comprehensive API coverage

### Connection Methods
- **Local**: Direct HTTP and Bluetooth communication
- **Cloud**: Remote device management via Linksys cloud services
- **Discovery**: Automatic network device detection

### Device Management Features
- Wi-Fi settings configuration
- Connected device monitoring
- Parental controls and access policies
- Advanced networking features (port forwarding, DMZ, etc.)

## Testing Philosophy

### Multi-Level Testing Approach
1. **Functional Unit Tests**: Core business logic without UI dependencies
2. **Screenshot Tests**: UI consistency across locales and screen sizes
3. **Widget Tests**: Individual component behavior validation
4. **Integration Tests**: End-to-end user workflows

### Screenshot Testing Details
- Supports multiple locales and screen dimensions
- Automated golden file generation and comparison
- Custom test result parsing and HTML report generation
- Organized output in `snapshots/` directory

## Common Development Workflows

### Adding New Features
1. Create feature directory in `lib/page/[feature_name]/`
2. Implement providers in `lib/providers/`
3. Add route definitions in `lib/route/`
4. Create comprehensive tests with appropriate tags
5. Update assets if UI resources are needed

### Debugging Network Issues
- Use logger package for structured logging
- JNAP protocol debugging tools in core module
- Network connectivity helpers in `lib/core/`

### Localization Updates
- Modify ARB files for new strings
- Run screenshot tests to validate UI layout
- Test across different locales using test scripts

## Active Technologies
- Dart 3.0+, Flutter 3.3+ + ui_kit_library (Git), privacygui_widgets (local plugin), flutter_riverpod, go_router (001-ui-kit-migration)
- Local preferences, shared_preferences, flutter_secure_storage (001-ui-kit-migration)

## Recent Changes
- 001-ui-kit-migration: Added Dart 3.0+, Flutter 3.3+ + ui_kit_library (Git), privacygui_widgets (local plugin), flutter_riverpod, go_router
