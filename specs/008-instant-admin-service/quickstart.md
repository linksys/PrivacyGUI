# Quickstart: Instant Admin Service Extraction

**Feature**: 003-instant-admin-service
**Date**: 2025-12-22

## Overview

This guide provides quick reference for implementing the timezone and power table service extraction.

---

## Files to Create

| File | Type | Description |
|------|------|-------------|
| `lib/page/instant_admin/services/timezone_service.dart` | NEW | TimezoneService implementation |
| `lib/page/instant_admin/services/power_table_service.dart` | NEW | PowerTableService implementation |
| `test/page/instant_admin/services/timezone_service_test.dart` | NEW | TimezoneService unit tests |
| `test/page/instant_admin/services/power_table_service_test.dart` | NEW | PowerTableService unit tests |
| `test/mocks/test_data/instant_admin_test_data.dart` | NEW | Test data builder |

## Files to Modify

| File | Changes |
|------|---------|
| `lib/page/instant_admin/providers/timezone_provider.dart` | Remove JNAP calls, delegate to TimezoneService |
| `lib/page/instant_admin/providers/power_table_provider.dart` | Remove JNAP parsing, delegate to PowerTableService |

---

## Implementation Order

1. **Create Test Data Builder** (`instant_admin_test_data.dart`)
2. **Create TimezoneService** with tests
3. **Refactor TimezoneNotifier** to use TimezoneService
4. **Create PowerTableService** with tests
5. **Refactor PowerTableNotifier** to use PowerTableService
6. **Run architecture compliance checks**

---

## Service Template

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

/// Provider for [FeatureName]Service
final [featureName]ServiceProvider = Provider<[FeatureName]Service>((ref) {
  return [FeatureName]Service(ref.watch(routerRepositoryProvider));
});

/// Stateless service for [feature] JNAP operations
class [FeatureName]Service {
  [FeatureName]Service(this._routerRepository);

  final RouterRepository _routerRepository;

  Future<ReturnType> fetchSomething() async {
    try {
      final result = await _routerRepository.send(
        JNAPAction.getSomething,
        auth: true,
      );
      // Transform and return
      return _transformResult(result);
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  Future<void> saveSomething(DataType data) async {
    try {
      await _routerRepository.send(
        JNAPAction.setSomething,
        data: data.toMap(),
        auth: true,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }
}
```

---

## Test Template

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_admin/services/[feature]_service.dart';

import '../../../../mocks/test_data/instant_admin_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late [FeatureName]Service service;
  late MockRouterRepository mockRepository;

  setUp(() {
    mockRepository = MockRouterRepository();
    service = [FeatureName]Service(mockRepository);
  });

  group('[FeatureName]Service - fetch', () {
    test('returns data on success', () async {
      when(() => mockRepository.send(any(), auth: any(named: 'auth')))
          .thenAnswer((_) async => InstantAdminTestData.create[Feature]Success());

      final result = await service.fetch[Feature]();

      expect(result, isNotNull);
      verify(() => mockRepository.send(any(), auth: true)).called(1);
    });

    test('throws ServiceError on JNAP failure', () async {
      when(() => mockRepository.send(any(), auth: any(named: 'auth')))
          .thenThrow(JNAPError(result: 'ErrorUnknown'));

      expect(
        () => service.fetch[Feature](),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });
}
```

---

## Architecture Compliance Verification

After implementation, run:

```bash
# Check Provider layer has no JNAP model imports
grep -r "import.*jnap/models" lib/page/instant_admin/providers/
# Expected: Only timezone_state.dart (contains SupportedTimezone in status)

# Check Provider layer has no JNAP result imports
grep -r "import.*jnap/result" lib/page/instant_admin/providers/
# Expected: 0 results

# Check Service layer imports ServiceError
grep -r "import.*core/errors/service_error" lib/page/instant_admin/services/
# Expected: All service files

# Run tests
flutter test test/page/instant_admin/services/

# Check coverage
flutter test --coverage test/page/instant_admin/services/
```

---

## Key Imports

### For Service Files
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
// Feature-specific JNAP models
import 'package:privacy_gui/core/jnap/models/timezone.dart';
import 'package:privacy_gui/core/jnap/models/power_table_settings.dart';
```

### For Refactored Provider Files
```dart
// REMOVE these imports:
// import 'package:privacy_gui/core/jnap/actions/better_action.dart';
// import 'package:privacy_gui/core/jnap/router_repository.dart';
// import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

// ADD service import:
import 'package:privacy_gui/page/instant_admin/services/timezone_service.dart';
// or
import 'package:privacy_gui/page/instant_admin/services/power_table_service.dart';
```

---

## Reference Implementation

See `lib/page/instant_admin/services/router_password_service.dart` for a complete example of the service pattern in this feature module.
