# Quickstart: Router Password Service Layer Extraction

**For Developers Implementing This Refactoring**

This guide provides step-by-step instructions to implement the router password service layer extraction following the approved specification and plan.

---

## Prerequisites

- [ ] Read [spec.md](./spec.md) for requirements
- [ ] Read [plan.md](./plan.md) for technical approach
- [ ] Review [contracts/router_password_service_contract.md](./contracts/router_password_service_contract.md) for API details
- [ ] Checkout branch `002-router-password-service`

---

## Quick Reference

| File | Action | Lines of Code |
|------|--------|---------------|
| `lib/page/instant_admin/services/router_password_service.dart` | CREATE | ~200 |
| `lib/page/instant_admin/providers/router_password_provider.dart` | REFACTOR | ~130 (existing) |
| `test/mocks/test_data/router_password_test_data.dart` | CREATE | ~100 |
| `test/page/instant_admin/services/router_password_service_test.dart` | CREATE | ~400 |
| `test/page/instant_admin/providers/router_password_provider_test.dart` | CREATE | ~300 |

**Estimated Effort**: 6-8 hours

---

## Implementation Steps

### Step 1: Create Test Data Builder (~30 min)

**File**: `test/mocks/test_data/router_password_test_data.dart`

1. Create file:
   ```bash
   mkdir -p test/mocks/test_data
   touch test/mocks/test_data/router_password_test_data.dart
   ```

2. Implement class with factory methods (see [data-model.md](./data-model.md#routerpasswordtestdata))

3. Verify:
   ```bash
   flutter analyze test/mocks/test_data/router_password_test_data.dart
   ```

**Reference**: constitution.md Article I Section 1.6.2

---

### Step 2: Create RouterPasswordService Skeleton (~30 min)

**File**: `lib/page/instant_admin/services/router_password_service.dart`

1. Create directories and file:
   ```bash
   mkdir -p lib/page/instant_admin/services
   touch lib/page/instant_admin/services/router_password_service.dart
   ```

2. Implement:
   - Import statements
   - Constructor with dependency injection
   - Method signatures (empty implementations)
   - `routerPasswordServiceProvider` definition

3. Verify:
   ```bash
   flutter analyze lib/page/instant_admin/services/router_password_service.dart
   ```

**Template**:
```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/extensions/_extensions.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

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

  Future<Map<String, dynamic>> fetchPasswordConfiguration() async {
    // TODO: Implement
    throw UnimplementedError();
  }

  // ... other methods
}
```

**Reference**: [Service Contract](./contracts/router_password_service_contract.md)

---

### Step 3: Implement Service Methods (~2 hours)

**File**: `lib/page/instant_admin/services/router_password_service.dart`

For each method, extract logic from `RouterPasswordNotifier`:

#### 3.1 fetchPasswordConfiguration()

**Source**: `RouterPasswordNotifier.fetch()` lines 22-49

**Extract**:
1. `fetchIsConfigured()` call
2. Password default/user-set checks
3. `getAdminPasswordHint` call (conditional)
4. FlutterSecureStorage read
5. Return map with all data

**Transform**:
```dart
// OLD (in notifier)
final results = await repo.fetchIsConfigured();
final bool isAdminDefault = ...
state = state.copyWith(isDefault: isAdminDefault, ...);

// NEW (in service)
final results = await _routerRepository.fetchIsConfigured();
final bool isAdminDefault = ...
return {
  'isDefault': isAdminDefault,
  'isSetByUser': isSetByUser,
  'hint': passwordHint,
  'storedPassword': password ?? '',
};
```

#### 3.2 setPasswordWithResetCode()

**Source**: `RouterPasswordNotifier.setAdminPasswordWithResetCode()` lines 51-69

**Extract**: Direct JNAP send call, remove state updates

#### 3.3 setPasswordWithCredentials()

**Source**: `RouterPasswordNotifier.setAdminPasswordWithCredentials()` lines 71-91

**Extract**: JNAP send call (exclude AuthProvider and fetch calls - those stay in notifier)

#### 3.4 verifyRecoveryCode()

**Source**: `RouterPasswordNotifier.checkRecoveryCode()` lines 93-119

**Extract**: JNAP send and error parsing, remove state updates

#### 3.5 persistPassword()

**New Method**: Wrapper for FlutterSecureStorage write

**Verify After Each Method**:
```bash
flutter analyze lib/page/instant_admin/services/router_password_service.dart
```

---

### Step 4: Write Service Unit Tests (~2 hours)

**File**: `test/page/instant_admin/services/router_password_service_test.dart`

1. Create directory and file:
   ```bash
   mkdir -p test/page/instant_admin/services
   touch test/page/instant_admin/services/router_password_service_test.dart
   ```

2. Implement test structure:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:mocktail/mocktail.dart';
   import 'package:flutter_secure_storage/flutter_secure_storage.dart';
   import 'package:privacy_gui/core/jnap/router_repository.dart';
   import 'package:privacy_gui/page/instant_admin/services/router_password_service.dart';
   import '../../../mocks/test_data/router_password_test_data.dart';

   class MockRouterRepository extends Mock implements RouterRepository {}
   class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

   void main() {
     late RouterPasswordService service;
     late MockRouterRepository mockRepository;
     late MockFlutterSecureStorage mockStorage;

     setUp(() {
       mockRepository = MockRouterRepository();
       mockStorage = MockFlutterSecureStorage();
       service = RouterPasswordService(mockRepository, mockStorage);
     });

     group('RouterPasswordService - fetchPasswordConfiguration', () {
       test('returns correct data on success', () async {
         // Arrange
         when(() => mockRepository.fetchIsConfigured())
             .thenAnswer((_) async => [
               ...RouterPasswordTestData.createFetchConfiguredSuccess().data,
             ]);
         // ... more mocking

         // Act
         final result = await service.fetchPasswordConfiguration();

         // Assert
         expect(result['isDefault'], false);
         // ... more assertions
       });

       // More tests...
     });

     // More groups...
   }
   ```

3. Write tests for all methods and error scenarios (aim for ≥90% coverage)

4. Run tests:
   ```bash
   flutter test test/page/instant_admin/services/router_password_service_test.dart
   ```

5. Check coverage:
   ```bash
   flutter test --coverage test/page/instant_admin/services/
   genhtml coverage/lcov.info -o coverage/html
   open coverage/html/index.html
   ```

**Target**: ≥90% coverage

---

### Step 5: Refactor RouterPasswordNotifier (~1 hour)

**File**: `lib/page/instant_admin/providers/router_password_provider.dart`

For each method:

#### 5.1 Update Imports

Add:
```dart
import 'package:privacy_gui/page/instant_admin/services/router_password_service.dart';
```

Remove (if no longer needed):
```dart
import 'dart:convert';  // Only if not used elsewhere
```

#### 5.2 Replace fetch()

**OLD** (lines 22-49):
```dart
Future fetch([bool force = false]) async {
  final repo = ref.read(routerRepositoryProvider);
  final results = await repo.fetchIsConfigured();
  // ... 25+ lines of JNAP logic
}
```

**NEW**:
```dart
Future fetch([bool force = false]) async {
  try {
    final service = ref.read(routerPasswordServiceProvider);
    final config = await service.fetchPasswordConfiguration();

    state = state.copyWith(
      isDefault: config['isDefault'] as bool,
      isSetByUser: config['isSetByUser'] as bool,
      adminPassword: config['storedPassword'] as String,
      hint: config['hint'] as String,
    );
    logger.d('[State]:[RouterPassword]:${state.toJson()}');
  } on JNAPError catch (error) {
    state = state.copyWith(error: error);
  } catch (error) {
    state = state.copyWith(error: error);
  }
}
```

#### 5.3 Replace setAdminPasswordWithResetCode()

**OLD**: Direct JNAP send
**NEW**: Call service, wrap in try-catch

#### 5.4 Replace setAdminPasswordWithCredentials()

**IMPORTANT**: Keep AuthProvider.localLogin call in notifier!

**OLD**:
```dart
Future setAdminPasswordWithCredentials(String? password, [String? hint]) async {
  final repo = ref.read(routerRepositoryProvider);
  final pwd = password ?? ref.read(authProvider).value?.localPassword;
  return repo.send(...).then<void>((value) async {
    await ref.read(authProvider.notifier).localLogin(...);
    await fetch(true);
  });
}
```

**NEW**:
```dart
Future setAdminPasswordWithCredentials(String? password, [String? hint]) async {
  try {
    final service = ref.read(routerPasswordServiceProvider);
    final pwd = password ?? ref.read(authProvider).value?.localPassword;

    await service.setPasswordWithCredentials(pwd ?? '', hint);

    // Keep AuthProvider interaction in notifier
    await ref.read(authProvider.notifier).localLogin(pwd ?? '', guardError: false);
    await fetch(true);
  } on JNAPError catch (error) {
    state = state.copyWith(error: error);
  }
}
```

#### 5.5 Replace checkRecoveryCode()

**OLD**: JNAP send with complex error handling
**NEW**: Call service, handle exceptions

#### 5.6 Verify Refactoring

```bash
flutter analyze lib/page/instant_admin/providers/router_password_provider.dart

# Verify no JNAP model imports (should return 0 results)
grep -r "import.*jnap/models" lib/page/instant_admin/providers/
```

---

### Step 6: Write Provider Unit Tests (~2 hours)

**File**: `test/page/instant_admin/providers/router_password_provider_test.dart`

1. Create file:
   ```bash
   touch test/page/instant_admin/providers/router_password_provider_test.dart
   ```

2. Implement test structure:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:mocktail/mocktail.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:privacy_gui/page/instant_admin/services/router_password_service.dart';
   import 'package:privacy_gui/page/instant_admin/providers/router_password_provider.dart';
   import 'package:privacy_gui/providers/auth/auth_provider.dart';

   class MockRouterPasswordService extends Mock implements RouterPasswordService {}
   class MockAuthNotifier extends Mock implements AuthNotifier {}

   void main() {
     late ProviderContainer container;
     late MockRouterPasswordService mockService;
     late MockAuthNotifier mockAuthNotifier;

     setUp(() {
       mockService = MockRouterPasswordService();
       mockAuthNotifier = MockAuthNotifier();

       container = ProviderContainer(
         overrides: [
           routerPasswordServiceProvider.overrideWithValue(mockService),
           authProvider.overrideWith(() => mockAuthNotifier),
         ],
       );
     });

     tearDown(() {
       container.dispose();
     });

     group('RouterPasswordNotifier - fetch', () {
       test('updates state on successful fetch', () async {
         // Arrange
         when(() => mockService.fetchPasswordConfiguration())
             .thenAnswer((_) async => {
               'isDefault': true,
               'isSetByUser': false,
               'hint': 'Test hint',
               'storedPassword': 'password123',
             });

         final notifier = container.read(routerPasswordProvider.notifier);

         // Act
         await notifier.fetch();

         // Assert
         final state = container.read(routerPasswordProvider);
         expect(state.isDefault, true);
         expect(state.hint, 'Test hint');
       });

       // More tests...
     });

     // More groups...
   }
   ```

3. Write tests for all public methods and error scenarios (aim for ≥85% coverage)

4. Run tests:
   ```bash
   flutter test test/page/instant_admin/providers/router_password_provider_test.dart
   ```

5. Check coverage:
   ```bash
   flutter test --coverage test/page/instant_admin/providers/
   ```

**Target**: ≥85% coverage

---

### Step 7: Verification (~30 min)

#### 7.1 Run All Tests

```bash
# Run all instant_admin tests
flutter test test/page/instant_admin/

# Run full test suite
./run_tests.sh
```

#### 7.2 Check Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Verify**:
- [ ] RouterPasswordService: ≥90% coverage
- [ ] RouterPasswordNotifier: ≥85% coverage
- [ ] Overall: ≥80% coverage

#### 7.3 Architecture Compliance Check

```bash
# Verify Provider layer has no JNAP imports (expect 0 results)
grep -r "import.*jnap/models" lib/page/instant_admin/providers/

# Verify UI layer has no JNAP imports (expect 0 results)
grep -r "import.*jnap/models" lib/page/instant_admin/views/

# Verify Service layer has JNAP imports (expect results)
grep -r "import.*jnap/models" lib/page/instant_admin/services/
```

**Expected**:
- [ ] 0 JNAP imports in providers/
- [ ] 0 JNAP imports in views/
- [ ] JNAP imports found in services/

#### 7.4 Lint Check

```bash
flutter analyze
dart format lib/page/instant_admin/services/
dart format lib/page/instant_admin/providers/ --set-exit-if-changed
```

#### 7.5 Manual Testing

1. Run app: `flutter run`
2. Navigate to router password settings
3. Test scenarios:
   - [ ] Fetch password configuration
   - [ ] Set password with reset code
   - [ ] Set password with credentials
   - [ ] Verify recovery code (valid/invalid)
   - [ ] Edge cases (network errors, invalid inputs)

---

## Success Criteria Checklist

From [spec.md](./spec.md):

- [ ] **SC-001**: All existing password management functionality works without regression
- [ ] **SC-002**: RouterPasswordService achieves ≥90% test coverage
- [ ] **SC-003**: RouterPasswordNotifier achieves ≥85% test coverage
- [ ] **SC-004**: Zero JNAP model imports in `lib/page/instant_admin/providers/`
- [ ] **SC-005**: Code review confirms separation of concerns
- [ ] **SC-006**: All unit tests execute in <5 seconds

---

## Common Pitfalls

### ❌ Don't

1. **Don't remove AuthProvider interaction from notifier**
   - `localLogin()` call stays in notifier, not service

2. **Don't change public APIs**
   - RouterPasswordNotifier method signatures must remain identical

3. **Don't skip error handling**
   - Every service call needs try-catch in notifier

4. **Don't use Mockito**
   - Constitution mandates Mocktail (Article I Section 1.6.1)

5. **Don't test entire codebase**
   - Only test instant_admin scope (Article I Section 1.3)

### ✅ Do

1. **Do use Test Data Builder**
   - Centralize JNAP mock responses in RouterPasswordTestData

2. **Do verify architecture compliance**
   - Run grep checks after refactoring

3. **Do maintain existing state structure**
   - RouterPasswordState unchanged

4. **Do follow naming conventions**
   - snake_case files, UpperCamelCase classes (Article III)

---

## Troubleshooting

### Tests Failing After Refactoring

**Problem**: Existing integration tests fail

**Solution**:
1. Check if notifier public API changed (should not)
2. Verify exception handling matches old behavior
3. Check state transitions match old implementation
4. Run single test: `flutter test test/path/to/test.dart -name 'test name'`

### Coverage Not Meeting Targets

**Problem**: Coverage below 90% for service or 85% for provider

**Solution**:
1. Identify untested branches: `flutter test --coverage`, open HTML report
2. Add tests for error scenarios
3. Test edge cases (empty strings, null values, network errors)
4. Verify Test Data Builder covers all JNAP response types

### Architecture Compliance Failing

**Problem**: grep finds JNAP imports in provider layer

**Solution**:
1. Remove JNAP model imports from provider file
2. Ensure service returns maps/primitives, not JNAP types
3. Move JNAP logic to service layer

---

## Next Steps After Completion

1. Create PR: `gh pr create --title "feat: Extract RouterPassword service layer" --body "$(cat specs/002-router-password-service/spec.md)"`
2. Request code review from team
3. Address review feedback
4. Merge to main branch
5. Update CLAUDE.md with service pattern examples (if applicable)

---

## Resources

- **Specification**: [spec.md](./spec.md)
- **Implementation Plan**: [plan.md](./plan.md)
- **Service Contract**: [contracts/router_password_service_contract.md](./contracts/router_password_service_contract.md)
- **Data Models**: [data-model.md](./data-model.md)
- **Research**: [research.md](./research.md)
- **Constitution**: [.specify/memory/constitution.md](../../.specify/memory/constitution.md)
- **CLAUDE.md**: [CLAUDE.md](../../CLAUDE.md)

---

## Questions?

If you encounter issues not covered in this guide:
1. Review constitution.md Article VI (Service Layer Principle)
2. Check AuthService reference implementation: `lib/providers/auth/auth_service.dart`
3. Ask team for clarification

**Good luck with the implementation!** 🚀
