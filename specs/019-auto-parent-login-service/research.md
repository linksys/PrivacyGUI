# Research: AutoParentFirstLogin Service Extraction

**Date**: 2026-01-07
**Feature**: 001-auto-parent-login-service

## Research Summary

This refactoring task requires no external research as it follows established patterns within the codebase. All unknowns have been resolved by examining existing implementations.

---

## 1. Service Layer Pattern

### Decision
Use the established Service pattern from `router_password_service.dart`.

### Rationale
- Constitution.md Article VI Section 6.6 explicitly references this file as a reference implementation
- Consistent with existing codebase patterns
- Provides clear separation between JNAP communication and state management

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| Keep JNAP in Provider | Violates constitution.md Article V, VI |
| Create abstract interface | Over-engineering; Article VII Section 7.1 prohibits unnecessary abstractions |

### Reference Implementation
```dart
// lib/page/instant_admin/services/router_password_service.dart
final routerPasswordServiceProvider = Provider<RouterPasswordService>((ref) {
  return RouterPasswordService(
    ref.watch(routerRepositoryProvider),
    const FlutterSecureStorage(),
  );
});

class RouterPasswordService {
  RouterPasswordService(this._routerRepository, this._secureStorage);

  final RouterRepository _routerRepository;
  final FlutterSecureStorage _secureStorage;

  // Methods handle JNAP, catch JNAPError, throw ServiceError
}
```

---

## 2. Error Handling Pattern

### Decision
Use centralized `mapJnapErrorToServiceError()` from `lib/core/errors/jnap_error_mapper.dart`.

### Rationale
- Constitution.md Article XIII mandates Service layer converts JNAPError → ServiceError
- Centralized mapper already exists; no need to duplicate logic
- Future-proofs against JNAP replacement

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| Custom error mapping in Service | Duplicates existing mapper; inconsistent |
| Let JNAPError propagate to Provider | Violates Article XIII Section 13.3 |

### Usage Pattern
```dart
try {
  await _routerRepository.send(...);
} on JNAPError catch (e) {
  throw mapJnapErrorToServiceError(e);
}
```

---

## 3. Retry Strategy Placement

### Decision
Keep `ExponentialBackoffRetryStrategy` in Service layer (not Provider).

### Rationale
- Retry logic is part of business logic / API communication strategy
- Service layer owns JNAP communication decisions
- Keeps Provider focused on state management

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| Retry in Provider | Provider should delegate, not implement communication details |
| Remove retry | Changes existing behavior; spec requires preserving current retry logic |

---

## 4. Await Pattern (Updated)

### Decision
**Change from fire-and-forget to awaited pattern** for both `setUserAcknowledgedAutoConfiguration()` and `setFirmwareUpdatePolicy()`.

### Rationale
- User feedback: both operations should be awaited for proper sequencing
- Ensures operations complete before proceeding
- Allows proper error propagation to caller
- More predictable behavior for debugging and testing

### Implementation
```dart
// In Provider: call WITH await
await service.setUserAcknowledgedAutoConfiguration();
await service.setFirmwareUpdatePolicy();

// In Service: properly awaited
Future<void> setUserAcknowledgedAutoConfiguration() async {
  try {
    await _routerRepository.send(...); // Now awaited
  } on JNAPError catch (e) {
    throw mapJnapErrorToServiceError(e);
  }
}
```

---

## 5. Test Data Builder Pattern

### Decision
Create `AutoParentFirstLoginTestData` following constitution.md Article I Section 1.6.2.

### Rationale
- Standardized test data location: `test/mocks/test_data/`
- Provides reusable JNAP mock responses for Service tests
- Follows `[Feature]TestData` naming convention

### Structure
```dart
// test/mocks/test_data/auto_parent_first_login_test_data.dart
class AutoParentFirstLoginTestData {
  static JNAPSuccess createInternetConnectionStatusSuccess({
    String connectionStatus = 'InternetConnected',
  }) => JNAPSuccess(
    result: 'ok',
    output: {'connectionStatus': connectionStatus},
  );

  static JNAPSuccess createFirmwareUpdateSettingsSuccess({
    String updatePolicy = 'AutoUpdate',
    int startMinute = 0,
    int durationMinutes = 240,
  }) => JNAPSuccess(
    result: 'ok',
    output: {
      'updatePolicy': updatePolicy,
      'autoUpdateWindow': {
        'startMinute': startMinute,
        'durationMinutes': durationMinutes,
      },
    },
  );
}
```

---

## Resolved Unknowns

| Unknown | Resolution |
|---------|------------|
| Service pattern to follow | `router_password_service.dart` |
| Error mapping approach | Use `mapJnapErrorToServiceError()` |
| Retry strategy location | Keep in Service layer |
| Await behavior | **Changed**: All JNAP operations are now awaited |
| Test data builder structure | Follow `[Feature]TestData` pattern |
| State class testing | **Required**: `AutoParentFirstLoginState` must have tests |

---

## No Outstanding NEEDS CLARIFICATION

All technical decisions resolved via existing codebase patterns and constitution.md guidelines.
