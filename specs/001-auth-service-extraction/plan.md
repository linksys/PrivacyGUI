# Implementation Plan: Auth Service Layer Extraction

**Branch**: `001-auth-service-extraction` | **Date**: 2025-12-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-auth-service-extraction/spec.md`

## Summary

Extract authentication business logic from `AuthNotifier` into a stateless `AuthService` class, following Article VI of the constitution. The service will encapsulate session token management, credential persistence, and authentication flows (cloud/local/RA login), while `AuthNotifier` delegates to the service and focuses solely on state management. Uses `Result<T, AuthError>` types for error handling.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: flutter_riverpod, flutter_secure_storage, shared_preferences
**Storage**: FlutterSecureStorage (credentials), SharedPreferences (preferences)
**Testing**: flutter_test with Mocktail for mocking
**Target Platform**: iOS, Android, Web, macOS
**Project Type**: Mobile (Flutter cross-platform)
**Performance Goals**: N/A (refactoring - maintain existing performance)
**Constraints**: Full backward compatibility with existing AuthProvider API
**Scale/Scope**: Single feature refactoring, ~5 files modified/created

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| **I: Test Coverage** | Unit tests for Services | PASS | AuthService will have full unit tests with Mocktail |
| **I.2: Testing Standards** | Tests use Mocktail | PASS | Confirmed in spec clarifications |
| **I.3: Test Organization** | Tests in `test/page/[feature]/services/` | PASS | Will use `test/providers/auth/` (matches existing location) |
| **V: Simplicity** | Avoid future-proofing | PASS | Only extracting existing logic, no new features |
| **V.2: Feature Structure** | Consistent structure | PASS | Adding `services/` alongside existing `providers/` |
| **VI: Service Layer** | Complex business logic in Services | PASS | Primary goal of this refactor |
| **VI.2: Service Responsibilities** | Stateless, constructor injection | PASS | FR-004, FR-005 in spec |
| **VI.3: File Organization** | `lib/page/[feature]/services/` | ADJUST | Auth is in `lib/providers/auth/`, will add `services/` subfolder |
| **VI.4: Provider-Service Separation** | Clear separation | PASS | Core requirement of this refactor |
| **VII: Anti-Abstraction** | No framework wrappers | PASS | Service is legitimate abstraction per VII.2 |
| **VIII: Testing Strategy** | Test pyramid approach | PASS | Unit tests for service, existing tests for notifier |

**Gate Status**: PASS - All constitution requirements met or appropriately adjusted.

**File Organization Note**: Auth lives in `lib/providers/auth/` rather than `lib/page/auth/` due to being a cross-cutting concern. Service will be placed at `lib/providers/auth/auth_service.dart` alongside existing `auth_provider.dart` and `auth_exception.dart`.

## Project Structure

### Documentation (this feature)

```text
specs/001-auth-service-extraction/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (internal API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/providers/auth/
├── auth_provider.dart       # MODIFY: Refactor to delegate to AuthService
├── auth_service.dart        # CREATE: New stateless service
├── auth_exception.dart      # EXISTING: Already has auth exceptions
├── auth_error.dart          # CREATE: AuthError sealed class for Result types
├── auth_result.dart         # CREATE: Result<T, AuthError> type alias
└── ra_session_provider.dart # EXISTING: No changes needed

test/providers/auth/
├── auth_provider_test.dart  # MODIFY: Update tests for refactored notifier
└── auth_service_test.dart   # CREATE: Comprehensive service unit tests
```

**Structure Decision**: Auth is a cross-cutting provider (not a page-specific feature), so it resides in `lib/providers/auth/`. The service follows the same location pattern, keeping auth concerns co-located.

## Complexity Tracking

> No violations requiring justification. This refactor follows constitution patterns exactly.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | - | - |
