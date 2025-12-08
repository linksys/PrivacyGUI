# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PrivacyGUI** (Linksys App) is a Flutter-based application for managing Linksys networking devices. It supports iOS, Android, and web platforms with local (JNAP protocol) and remote (cloud) communication capabilities.

- **Current Version**: 1.2.8+100000
- **Dart/Flutter**: SDK >=3.0.0, Flutter >=3.3.0
- **State Management**: Riverpod (flutter_riverpod 2.6.1)
- **Navigation**: go_router with custom routing layer
- **Localization**: 25+ languages via ARB files (l10n/app_*.arb)
- **Dependency Injection**: GetIt (singleton pattern) + Riverpod (functional)

---

## Essential Commands

### Development & Testing

```bash
# Install dependencies (run after pubspec.yaml changes)
flutter pub get

# Code generation (freezed, json_serializable, models)
flutter pub run build_runner build --delete-conflicting-outputs

# Format & lint (REQUIRED before commit)
dart format lib/ test/
flutter analyze                    # Must pass with 0 warnings

# Run tests
flutter test test/path/to/test_file.dart              # Single test file
flutter test test/path/to/test_file.dart -k "pattern" # Tests matching pattern
./run_tests.sh                                         # All tests (excludes golden/loc)

# Coverage report
flutter test --coverage
lcov --list coverage/lcov.info    # View coverage summary

# Golden/screenshot tests
./run_generate_loc_snapshots.sh                        # Default locales/sizes
./run_generate_loc_snapshots.sh -l "es,ja" -s "400"   # Custom locales & sizes
./clear_goldens.sh                                     # Clear before intentional UI changes
```

### Code Generation Tips

- **Auto-triggers on** `flutter pub get` (if enabled in pubspec.yaml)
- **Models**: Use `@freezed` or `json_serializable` - run build_runner after changes
- **Notifiers**: Riverpod codegen commented out; can be enabled if needed
- **Watch mode**: `flutter pub run build_runner watch` for continuous generation

### Building & Running

```bash
# Run app in debug (connect device/emulator first)
flutter run

# Run specific target (iOS/Android/web)
flutter run -d <device-id>

# Build web
./build_web.sh

# Build Android/iOS release
flutter build apk --release
flutter build ios --release
```

---

## Architecture & Layering

### Clean Architecture (3-Layer Model)

```
┌─────────────────────────────────────┐
│  Presentation (UI/Provider)         │
│  lib/page/*/views, lib/providers/   │
│  Responsibility: UI rendering,      │
│  state observation, error display   │
└────────────────┬────────────────────┘
                 │ depends on
┌────────────────▼────────────────────┐
│  Application (Service)              │
│  lib/page/*/providers/              │
│  Responsibility: business logic,    │
│  coordination, DTO/Model transform  │
└────────────────┬────────────────────┘
                 │ depends on
┌────────────────▼────────────────────┐
│  Data (Repository/Source)           │
│  lib/core/jnap/, lib/core/cloud/    │
│  Responsibility: API calls,         │
│  JNAP protocol, data parsing        │
└─────────────────────────────────────┘
```

**Key Rule**: One-way dependency flow. No circular dependencies. Always inject abstractions, not concrete implementations.

### Directory Structure

- **`lib/core/`**: Low-level infrastructure
  - `jnap/`: Local device communication (JNAP protocol, command queuing, device models)
  - `cloud/`: Remote device access via Linksys cloud (OAuth, API requests)
  - `http/`: HTTP client abstraction (platform-specific: mobile vs web)
  - `cache/`: Local storage (SharedPreferences, flutter_secure_storage)
  - `bluetooth/`: Bluetooth connectivity (iOS/Android only)
  - `utils/`: Logging, storage utilities, error handling

- **`lib/page/`**: Feature-specific UI and state
  - Each subdirectory represents a feature (dashboard, wifi_settings, nodes, etc.)
  - `*/views/`: UI components (widgets, screens)
  - `*/providers/`: Riverpod providers and notifiers for that feature
  - `*/models/`: Feature-specific DTOs/models (if needed)

- **`lib/providers/`**: Global/shared state
  - `auth/`: Authentication state (login, token, session)
  - `connectivity/`: Network status (WiFi, LAN, internet availability)
  - `app_settings/`: Theme, language, preferences
  - `root/`: Root-level notifiers (rarely used directly)

- **`lib/route/`**: Navigation and routing logic using go_router

- **`lib/util/`**, **`lib/utils.dart`**: Global utilities, validators, extensions

- **`lib/l10n/`**: Generated localization files (ARB → auto-generated)

### State Management Pattern: PreservableNotifierMixin

Most feature providers use a custom pattern combining Riverpod with `PreservableNotifierMixin`:

```dart
class MySettingsNotifier extends Notifier<MySettingsState>
    with PreservableNotifierMixin<MySettings, MyStatus, MySettingsState> {

  @override
  MySettingsState build() => MySettingsState(
    settings: Preservable(original: ..., current: ...),
    status: const MyStatus(),
  );

  @override
  Future<(MySettings?, MyStatus?)> performFetch({...}) async {
    // Fetch logic, return updated settings + status
  }
}
```

**Key Pattern**: Separates original (pristine) vs current (user-edited) state for undo/reset functionality.

### Error Handling & Results

- **No unchecked exceptions**: Service/Repository methods must never throw raw exceptions
- **Result Pattern**: Return `Future<Result<T, Failure>>` (uses custom Result or fpdart)
- **Failure Types**: Sealed class or enum defining all possible error cases
- **UI Layer**: Must use `fold`/`match` to handle success and failure paths explicitly

### Testing & Coverage Requirements

- **Minimum**: 80%+ overall coverage
- **Data/Application layers**: ≥90% coverage
- **Mocking**: Use `mocktail` for all dependencies; Riverpod provides test overrides
- **Test Organization**:
  - `test/core/`: Unit tests for data layer (low-level logic, no UI)
  - `test/page/*/`: Feature tests (services, providers, notifiers)
  - `test/common/`: Shared test utilities, mock helpers

### Immutability & Code Generation

- **Data Models**: Must use `@immutable` + `Equatable` + `copyWith` + `toJson`/`fromJson`
- **Generation**: Prefer `freezed` or `json_serializable` over manual implementation
- **Code Gen**: Run `flutter pub run build_runner build` after changes

---

## Project Constitution (Design Principles)

Adhered to via `.specify/memory/constitution.md` (v2.0):

### Core Principles

| Principle | Implementation |
|-----------|-----------------|
| **Clean Architecture** | 3-layer (Presentation → Application → Data), Adapter Pattern for JNAP/Cloud |
| **Test Coverage** | ≥80% overall, ≥90% Data layer; use mocktail for external deps |
| **Code Quality** | `flutter analyze` 0 warnings, `dart format` compliance required |
| **Immutability** | Models must use `@immutable`, `Equatable`, `copyWith`, serialization |
| **Documentation** | All public APIs require DartDoc comments |
| **Error Handling** | Result Pattern (Result<T, Failure>) for service/repo methods |
| **Localization** | NO hardcoded UI strings; use `loc(context)` from ARB files |
| **Security** | flutter_secure_storage for sensitive data, code obfuscation in Release |

### State Management Pattern

- **Riverpod** for reactive, functional state (test-friendly)
- **GetIt** for singletons only (themes, ServiceHelper) - rarely modified after init
- **PreservableNotifierMixin** for undo/reset: separates `original` (server) vs `current` (edited) state
- **Never mix**: Don't use GetIt inside Riverpod providers (breaks testability)

### Critical Gates
- JNAP actions & data models isolated in service/repository (not in Notifier/UI)
- One-way dependency flow (no circular dependencies)
- Mocking strategy: mock external deps (JNAP, Cloud API, DB), NOT business logic

---

## Important Files & Patterns

### Key Entry Points

- **`lib/main.dart`**: Initialization (storage, GetIt setup, error handlers, JNAP actions)
- **`lib/app.dart`**: Root ConsumerStatefulWidget (theme, routing, lifecycle)
- **`lib/di.dart`**: GetIt service locator setup (singletons like ServiceHelper, themes)

### JNAP Protocol Layer (Local Device Access)

Located in `lib/core/jnap/`:

```
jnap/
├── actions/           # JNAP action definitions (enum-like)
├── models/            # Device data models (Device, WiFiSettings, etc.)
├── command/           # JNAP command building & execution
├── router_repository.dart  # Repository for JNAP queries
└── jnap_command_queue.dart # Command queuing & deduplication
```

**Key Pattern**: `JNAPTransactionBuilder` batches multiple JNAP actions into a single request for efficiency.

### Cloud Layer (Remote Device Access)

Located in `lib/core/cloud/`:

```
cloud/
├── linksys_requests/   # Cloud API service methods
├── linksys_cloud_repository.dart  # Cloud repository
└── model/              # Cloud-specific data models
```

### Riverpod Providers: Pattern Recognition

- **Final providers**: Read-only data (usually from services)
  ```dart
  final userProvider = FutureProvider((ref) async { ... });
  ```

- **Notifier providers**: Mutable state with custom methods
  ```dart
  final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(...);
  ```

- **Family providers**: Parameterized providers
  ```dart
  final deviceDetailProvider = FutureProvider.family((ref, String deviceId) { ... });
  ```

### Routing via go_router

- Routes defined in `lib/route/router_provider.dart`
- Each route maps to a page with optional parameters
- Deep linking supported (URL-based navigation)
- Route state persisted in providers for UI sync

---

## Localization (I18N)

### Adding New Strings

1. Add entry to `lib/l10n/app_en.arb` (English reference)
   ```json
   "myNewString": "My new text"
   ```

2. Repeat for all supported languages in `lib/l10n/app_*.arb`

3. Run `flutter gen-l10n` or `flutter pub get` (auto-triggers)

4. In code, access via:
   ```dart
   Text(loc(context).myNewString)
   ```

**Rule**: NO hardcoded UI strings. All user-visible text must be localized.

---

## Code Review Checklist

Before submitting PR, ensure:

- [ ] `flutter analyze` passes with 0 warnings
- [ ] `dart format` applied to all changed files
- [ ] Tests pass: `./run_tests.sh`
- [ ] Coverage ≥80% (check with `flutter test --coverage`)
- [ ] No unchecked exceptions in service/repository layers
- [ ] Models use `@immutable`, `Equatable`, code generation (freezed)
- [ ] DartDoc added to all public APIs
- [ ] No hardcoded strings (use localization)
- [ ] Circular dependencies avoided (lint with `dart analyze`)
- [ ] Existing tests still pass (backward compatibility)

---

## Common Gotchas & Tips

### GetIt vs Riverpod

- **GetIt**: Singletons (GetIt.instance), rarely changed after init. Used for themes, ServiceHelper
- **Riverpod**: Functional, reactive state. Used for features, mutable state, tests
- **Never mix**: Don't use GetIt inside Riverpod providers for test compatibility

### JNAP Action Execution

- JNAP commands are async and may time out (local network latency)
- Use `JNAPCommandQueue` for request deduplication and queuing
- Always wrap in error handling (JNAP responses can indicate device errors)

### Device Connectivity

- Check `connectivityProvider` before attempting JNAP calls
- WiFi can be connected but device unreachable (network segmentation)
- Cloud fallback available if local unreachable

### Testing with Riverpod

- Use `ProviderContainer` to test providers in isolation
- Override providers in tests:
  ```dart
  container.override(mockProvider, MockNotifier());
  ```
- Never directly instantiate Notifiers; use provider overrides

### Screenshot/Golden Tests

- Stored in `test/page/*/snapshots/`
- Run `./clear_goldens.sh` before regenerating after intentional UI changes
- Useful for detecting unintended regressions in layouts

---

## Performance & Constraints

- **Max UI frame drops**: None during JNAP data fetch (use async, no blocking)
- **JNAP response time**: <200ms typical for local network
- **Cloud API**: <500ms typical (network-dependent)
- **Test execution**: Unit tests <100ms each (mock JNAP responses)
- **Startup time**: Minimize synchronous operations in `main()` and `initState`

---

## Additional Resources

- `.specify/memory/constitution.md`: Full governance, testing, security policies
- `README.md`: Build scripts, test commands, feature overview
- `.analyze_options.yaml`: Linter rules (prefer_const_constructors: ignore is in effect)
- `pubspec.yaml`: Dependency versions (riverpod, go_router, firebase*, flutter_secure_storage)

---

## Development Workflow & Special Notes

### Branch & Commit Strategy

- **Branch naming**: `peter/XXX` where XXX is Jira ticket key (e.g., `peter/NOW-685`)
- **Commit format**: `[TICKET]: Description` (e.g., `[NOW-685]: Refactor instant setup UI`)
- **All commits/PRs** must be in English (user preference)
- **Review**: User reviews PR content before merge

### Feature Specification & Planning (Speckit Integration)

For complex features/refactors, use the **Speckit workflow** in `.specify/` directory:

```bash
# 1. Create feature specification from natural language
/speckit.specify

# 2. Develop implementation plan with architecture decisions
/speckit.plan

# 3. Optionally clarify underspecified areas
/speckit.clarify

# 4. Generate actionable, dependency-ordered task list
/speckit.tasks

# 5. Cross-artifact consistency analysis (read-only)
/speckit.analyze

# 6. Generate GitHub issues from tasks
/speckit.taskstoissues

# 7. Execute implementation plan
/speckit.implement
```

**Current active feature**: `001-administration-service-refactor` (see `specs/` directory)

### Testing Strategy

- **Screenshot Tests**: Golden files in `test/page/*/snapshots/` - run separately with `./run_generate_loc_snapshots.sh`
- **Unit Tests**: <100ms per test target; use `mocktail` for mocking external dependencies
- **Coverage**: Minimum 80% overall, 90% for Data layer (service/repository)
- **Test organization**: Mirror `lib/` structure in `test/` (e.g., `lib/page/X/providers/` → `test/page/X/providers/`)

### Golden (Screenshot) Tests

- Store visual regression tests in `test/page/*/snapshots/`
- Run with `./run_generate_loc_snapshots.sh` (separate from unit tests)
- Always run `./clear_goldens.sh` before regenerating after intentional UI changes
- Useful for detecting unintended layout/style regressions

### Constitution & Standards

The project follows a strict **development constitution** (`.specify/memory/constitution.md`, v2.0):
- **3-layer architecture**: Presentation → Application → Data (one-way deps only)
- **State management**: Riverpod for reactive state, GetIt for singletons only
- **Testing**: ≥80% coverage, mock external deps only, NOT business logic
- **Code quality**: Zero lint warnings, proper formatting, all public APIs documented
- **Localization**: NO hardcoded strings; use ARB files + `loc(context)` accessor
