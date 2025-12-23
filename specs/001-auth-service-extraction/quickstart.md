# Quickstart: Auth Service Layer Extraction

**Branch**: `001-auth-service-extraction` | **Date**: 2025-12-10

## Overview

This guide provides a quick reference for implementing the AuthService extraction. For full details, see [spec.md](./spec.md), [plan.md](./plan.md), and [research.md](./research.md).

---

## Key Files to Create

| File | Purpose |
|------|---------|
| `lib/providers/auth/auth_result.dart` | `AuthResult<T>` sealed class (Success/Failure) |
| `lib/providers/auth/auth_error.dart` | `AuthError` sealed class with error types |
| `lib/providers/auth/auth_service.dart` | Stateless service with all business logic |
| `test/providers/auth/auth_service_test.dart` | Unit tests with Mocktail |

---

## Key Files to Modify

| File | Changes |
|------|---------|
| `lib/providers/auth/auth_provider.dart` | Delegate to AuthService, keep state management only |

---

## Implementation Order

1. **Create `auth_result.dart`** - Result type foundation
2. **Create `auth_error.dart`** - Error type hierarchy
3. **Create `auth_service.dart`** - Extract business logic
4. **Refactor `auth_provider.dart`** - Delegate to service
5. **Create `auth_service_test.dart`** - Full unit test coverage
6. **Update existing tests** - Ensure backward compatibility

---

## Quick Reference: AuthResult Pattern

```dart
// In auth_result.dart
sealed class AuthResult<T> {
  const AuthResult();

  R when<R>({
    required R Function(T value) success,
    required R Function(AuthError error) failure,
  });
}

final class AuthSuccess<T> extends AuthResult<T> {
  final T value;
  const AuthSuccess(this.value);
  // ... implement when()
}

final class AuthFailure<T> extends AuthResult<T> {
  final AuthError error;
  const AuthFailure(this.error);
  // ... implement when()
}
```

---

## Quick Reference: AuthService Provider

```dart
// In auth_service.dart
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(routerRepositoryProvider),
    ref.watch(cloudRepositoryProvider),
    const FlutterSecureStorage(),
  );
});

class AuthService {
  final RouterRepository _routerRepository;
  final LinksysCloudRepository _cloudRepository;
  final FlutterSecureStorage _secureStorage;

  AuthService(
    this._routerRepository,
    this._cloudRepository,
    this._secureStorage,
  );

  // Business logic methods...
}
```

---

## Quick Reference: AuthNotifier Delegation

```dart
// In auth_provider.dart (refactored)
class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthService _authService;

  @override
  Future<AuthState> build() {
    _authService = ref.watch(authServiceProvider);
    return Future.value(AuthState.empty());
  }

  Future cloudLogin({
    required String username,
    required String password,
    SessionToken? sessionToken,
  }) async {
    state = const AsyncValue.loading();
    final result = await _authService.cloudLogin(
      username: username,
      password: password,
      existingToken: sessionToken,
    );
    state = result.when(
      success: (authState) => AsyncValue.data(authState),
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );
  }

  // Other methods follow same pattern...
}
```

---

## Quick Reference: Testing with Mocktail

```dart
// In auth_service_test.dart
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockRouterRepository extends Mock implements RouterRepository {}
class MockCloudRepository extends Mock implements LinksysCloudRepository {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AuthService authService;
  late MockRouterRepository mockRouter;
  late MockCloudRepository mockCloud;
  late MockSecureStorage mockStorage;

  setUp(() {
    mockRouter = MockRouterRepository();
    mockCloud = MockCloudRepository();
    mockStorage = MockSecureStorage();
    authService = AuthService(mockRouter, mockCloud, mockStorage);
  });

  group('cloudLogin', () {
    test('returns success with valid credentials', () async {
      // Arrange
      when(() => mockCloud.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => SessionToken(...));

      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final result = await authService.cloudLogin(
        username: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockStorage.write(
        key: pSessionToken,
        value: any(named: 'value'),
      )).called(1);
    });
  });
}
```

---

## Error Type Quick Reference

| Error Type | When to Use |
|------------|-------------|
| `NoSessionTokenError` | No token in storage |
| `SessionTokenExpiredError` | Token expired, no refresh possible |
| `TokenRefreshError` | Refresh API call failed |
| `InvalidCredentialsError` | Wrong username/password |
| `JnapError` | JNAP API returned error |
| `CloudApiError` | Cloud API returned error |
| `StorageError` | FlutterSecureStorage operation failed |
| `NetworkError` | Network connectivity issue |

---

## Validation Checklist

Before marking implementation complete:

- [ ] All AuthService methods return `AuthResult<T>`
- [ ] AuthNotifier delegates all business logic to AuthService
- [ ] AuthNotifier public API unchanged (backward compatibility)
- [ ] Unit tests cover all AuthService methods
- [ ] All existing tests pass
- [ ] No business logic remains in AuthNotifier
- [ ] Mocktail used for all mocks
- [ ] Code follows constitution Article VI patterns

---

## Related Documentation

- [Feature Specification](./spec.md)
- [Implementation Plan](./plan.md)
- [Research Findings](./research.md)
- [Data Model](./data-model.md)
- [API Contract](./contracts/auth_service_contract.md)
- [Constitution](../../.specify/memory/constitution.md) (Article VI)
