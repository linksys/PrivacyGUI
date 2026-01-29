# Quickstart: ConnectivityService Extraction

**Date**: 2026-01-02
**Feature**: 001-connectivity-service
**Estimated Effort**: 2-3 hours

## Overview

This guide provides step-by-step instructions for implementing the ConnectivityService extraction.

## Prerequisites

- Flutter development environment set up
- Familiarity with Riverpod state management
- Understanding of the three-layer architecture (constitution.md)

## Implementation Steps

### Step 1: Create ConnectivityService

**File**: `lib/providers/connectivity/services/connectivity_service.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/extensions/_extensions.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(ref.watch(routerRepositoryProvider));
});

class ConnectivityService {
  ConnectivityService(this._routerRepository);

  final RouterRepository _routerRepository;

  Future<RouterType> testRouterType(String? gatewayIp) async {
    // Implementation from _testRouterType()
  }

  Future<RouterConfiguredData> fetchRouterConfiguredData() async {
    // Implementation from isRouterConfigured()
  }
}
```

### Step 2: Implement testRouterType

Move logic from `ConnectivityNotifier._testRouterType()`:

```dart
Future<RouterType> testRouterType(String? gatewayIp) async {
  final routerSN = await _routerRepository
      .send(
        JNAPAction.getDeviceInfo,
        type: CommandType.local,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      )
      .then<String>(
          (value) => NodeDeviceInfo.fromJson(value.output).serialNumber)
      .onError((error, stackTrace) => '');

  if (routerSN.isEmpty) {
    return RouterType.others;
  }

  final prefs = await SharedPreferences.getInstance();
  final currentSN = prefs.get(pCurrentSN);

  if (routerSN.isNotEmpty && routerSN == currentSN) {
    return RouterType.behindManaged;
  }
  return RouterType.behind;
}
```

### Step 3: Implement fetchRouterConfiguredData

Move logic from `ConnectivityNotifier.isRouterConfigured()`:

```dart
Future<RouterConfiguredData> fetchRouterConfiguredData() async {
  try {
    final results = await _routerRepository.fetchIsConfigured();

    bool isDefaultPassword = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.isAdminPasswordDefault, Map.fromEntries(results))
        ?.output['isAdminPasswordDefault'] ?? false;

    bool isSetByUser = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.isAdminPasswordDefault, Map.fromEntries(results))
        ?.output['isAdminPasswordSetByUser'] ?? false;

    return RouterConfiguredData(
      isDefaultPassword: isDefaultPassword,
      isSetByUser: isSetByUser,
    );
  } on JNAPError catch (e) {
    throw mapJnapErrorToServiceError(e);
  }
}
```

### Step 4: Update ConnectivityNotifier

**File**: `lib/providers/connectivity/connectivity_provider.dart`

Remove JNAP imports and delegate to service:

```dart
// REMOVE these imports:
// import 'package:privacy_gui/core/jnap/command/base_command.dart';
// import 'package:privacy_gui/core/jnap/extensions/_extensions.dart';
// import 'package:privacy_gui/core/jnap/models/device_info.dart';
// import 'package:privacy_gui/core/jnap/actions/better_action.dart';
// import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
// import 'package:privacy_gui/core/jnap/router_repository.dart';

// ADD this import:
import 'package:privacy_gui/providers/connectivity/services/connectivity_service.dart';

class ConnectivityNotifier extends Notifier<ConnectivityState>
    with ConnectivityListener, AvailabilityChecker {

  // Replace _testRouterType implementation:
  Future<RouterType> _testRouterType(String? newIp) async {
    final service = ref.read(connectivityServiceProvider);
    return service.testRouterType(newIp);
  }

  // Replace isRouterConfigured implementation:
  Future<RouterConfiguredData> isRouterConfigured() async {
    final service = ref.read(connectivityServiceProvider);
    return service.fetchRouterConfiguredData();
  }
}
```

### Step 5: Create Unit Tests

**File**: `test/providers/connectivity/services/connectivity_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// ... imports

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late ConnectivityService service;
  late MockRouterRepository mockRepo;

  setUp(() {
    mockRepo = MockRouterRepository();
    service = ConnectivityService(mockRepo);
  });

  group('ConnectivityService - testRouterType', () {
    test('returns RouterType.others when JNAP fails', () async {
      when(() => mockRepo.send(any(), ...))
          .thenThrow(Exception('Network error'));

      final result = await service.testRouterType('192.168.1.1');

      expect(result, RouterType.others);
    });

    // Add more test cases...
  });

  group('ConnectivityService - fetchRouterConfiguredData', () {
    test('returns correct data on success', () async {
      // Mock setup and test...
    });
  });
}
```

### Step 6: Verify Architecture Compliance

Run these checks:

```bash
# Should return NO results (Provider has no JNAP imports)
grep -r "import.*jnap/models" lib/providers/connectivity/connectivity_provider.dart
grep -r "import.*jnap/result" lib/providers/connectivity/connectivity_provider.dart
grep -r "import.*jnap/actions" lib/providers/connectivity/connectivity_provider.dart

# Should return results (Service HAS JNAP imports)
grep -r "import.*jnap" lib/providers/connectivity/services/
```

## Verification Checklist

- [ ] `ConnectivityService` created with both methods
- [ ] `connectivityServiceProvider` defined
- [ ] `ConnectivityNotifier` delegates to service
- [ ] No JNAP imports in `connectivity_provider.dart`
- [ ] Unit tests created for service
- [ ] All tests pass
- [ ] App connectivity detection works correctly

## Common Issues

### Issue: SharedPreferences not available in tests

**Solution**: Mock `SharedPreferences` or pass it as a method parameter.

### Issue: Circular dependency with RouterConfiguredData

**Solution**: Keep `RouterConfiguredData` in `connectivity_provider.dart` and import it in the service.

## Reference Files

- Reference Service: `lib/page/instant_admin/services/router_password_service.dart`
- Error Mapper: `lib/core/errors/jnap_error_mapper.dart`
- Service Errors: `lib/core/errors/service_error.dart`
