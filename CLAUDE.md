# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Authority**: For all architectural decisions (testing, naming, provider structure, services, error handling, UI Kit usage), `constitution.md` is the source of truth and **supersedes this file** in case of conflict. Read it before any non-trivial feature work.

## Project Overview

This is a Flutter application for managing Linksys networking devices. It provides a comprehensive interface for users to monitor and control their network settings, connected devices, and router functionalities. The app supports both local (Bluetooth/HTTP) and cloud-based device interactions.

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
# Web build with parameters: buildNumber, force, href, cloud, picker, ca, themeSource, themeJson, themeStudio
./build_web.sh <buildNumber> <force> <href> <cloud> <picker> <ca> [themeSource] [themeJson] [themeStudio]

# Examples:
./build_web.sh 100 false "/" prod false true                           # Default theme
./build_web.sh 100 false "/" prod false true cicd '{"style":"neo"}'    # Override theme with JSON
./build_web.sh 100 false "/" prod false true network "https://..."     # Load theme from network
./build_web.sh 100 false "/" qa false true "" "" true                  # Enable theme studio
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
- **Pattern**: Two-tier provider taxonomy for USP pages (L1 session cache / L2 editable working copy) — see `constitution.md` Article IV
- **App-level providers**: `lib/providers/` (auth, theme, app_settings, routing redirection)
- **Feature providers**: `lib/page/[feature]/providers/`

### Navigation
- **Router**: `go_router` for declarative routing
- **Structure**: Route definitions in `lib/route/`
- **Pattern**: Feature-based route organization

### Core Systems
- **USP Protocol**: TR-181 router communication via WASM client (`lib/core/usp/`)
- **Cloud API**: Linksys cloud endpoints & HTTP client (`lib/core/cloud/`)
- **Session**: Connection lifecycle & device info bootstrap (`lib/core/session/`)
- **Auth**: USP auth is an additional local channel that runs alongside the legacy auth flow (`lib/core/usp/providers/usp_auth_coordinator.dart`)
- **Errors**: Unified `ServiceError` at `lib/core/errors/service_error.dart` (see constitution Article XIII)
- **Utils**: Logger, storage, crypto, device helpers (`lib/core/utils/`)
- **PWA**: Install prompt & web-specific logic (`lib/core/pwa/`)

### Core Framework
- **Base infrastructure** in `lib/framework/`: `FeatureState<TSettings, TStatus>`, `Preservable`, `PreservableContract`, `PreservableAutoDisposeNotifierMixin` — used by all Type A (Form) / Type B (CRUD List) USP feature pages for dirty-guard save/revert flows
- **Guide**: `doc/dirty_guard/dirty_guard_framework_guide.md`
- **Rule**: `PreservableContract` has exactly one canonical definition in `lib/framework/preservable_contract.dart` — duplicating it silently breaks `LinksysRoute` dirty check at runtime (constitution Article IV Rule 4)

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
- **Test Data Builders**: `test/mocks/test_data/[feature]_test_data.dart` — centralized USP codegen model factories (constitution Article I §1.6.2)
- **Golden Tests**: Screenshot testing with localization support
- **Test Categories**: Tagged system (golden, loc, ui, functional)

## Key Dependencies and Tools

### Core Flutter Dependencies
- `riverpod` & `flutter_riverpod`: State management
- `go_router`: Navigation and routing
- `http`: Network communication
- `shared_preferences` & `flutter_secure_storage`: Local data storage

### Custom Components
- `privacygui_widgets`: Local plugin in `plugins/widgets/`
- `ui_kit_library`: Shared UI components from external Git repository

### UI Component Policy
**UI Kit First**: all UI components MUST be searched for in `ui_kit_library` first. If a needed component is missing, stop and ask the user via AskUserQuestion — do not implement it yourself. See constitution Article XIV.

### Testing Framework
- `mocktail`: Mocking for unit tests (primary, per constitution Article I §1.6.1)
- `mockito`: Legacy — used only by existing tests; new tests MUST use mocktail
- `golden_toolkit`: Screenshot testing

## Development Patterns

### Code Style
- Uses `flutter_lints` with custom overrides in `analysis_options.yaml`
- Disables `prefer_const_constructors` rule
- English comments only (per global CLAUDE.md instructions)

### Asset Management
- Icons: `assets/icons/`
- Resources: `assets/resources/`
- Localization: Built-in Flutter i18n with `intl` package

## Network Device Integration

### USP (TR-181 via WASM)
- **Protocol**: TR-181 object model served via WASM USP client
- **Codegen API**: `lib/generated/*.g.dart` — generated by `tools/usp-codegen` from YAML definitions in `linksys/usp_framework`
- **Transport layer**: `lib/core/usp/` (WASM client, SSE subscriptions, mutation lock)
- **Provider architecture**: L1 (session cache, not autoDispose) + L2 (editable working copy, autoDispose) — see `constitution.md` Article IV
- **Error handling**: USP errors MUST be mapped to `ServiceError` via `mapUspErrorToServiceError()` in the Service layer (constitution Article XIII)
- **Vendored artifacts**: `tools/usp-codegen` binary and `web/usp_client.*` — see `doc/usp/vendored-artifacts.md`

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

### Screenshot Testing Details
- Supports multiple locales and screen dimensions
- Automated golden file generation and comparison
- Custom test result parsing and HTML report generation
- Organized output in `snapshots/` directory

## Common Development Workflows

### Adding New Features
0. **Required first**: Read `constitution.md` in full — it governs all feature work (testing, naming, provider architecture, services, error handling, UI Kit)
1. Create feature directory in `lib/page/[feature_name]/` with subdirs: `views/`, `providers/`, `services/`, `models/` (as needed)
2. Implement business logic in `lib/page/[feature_name]/services/` (constitution Article VI)
3. Implement state management in `lib/page/[feature_name]/providers/`
4. Add route definitions in `lib/route/`
5. Add unit tests under `test/page/[feature_name]/` with corresponding subdirs
6. Update assets if UI resources are needed

### Debugging Network Issues
- Use logger package for structured logging
- USP request/subscription logs are prefixed with `[USP]` / `[WASM]` / `[SSE]` for grep-friendly diagnostics
- Network connectivity helpers in `lib/core/`

### Localization Updates
- Modify ARB files for new strings
- Run screenshot tests to validate UI layout
- Test across different locales using test scripts

## Vendored USP Artifacts
The `tools/usp-codegen` binary and `web/usp_client.{js,wasm}` are built from `linksys/usp_framework` and checked in. See `doc/usp/vendored-artifacts.md` for the version manifest and update procedure before bumping any of them.
