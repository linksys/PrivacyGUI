# Quickstart: AddNodesService Implementation

**Feature**: 001-add-nodes-service
**Date**: 2026-01-06

## Prerequisites

- Flutter SDK 3.3+
- Existing codebase with RouterRepository configured
- Understanding of Riverpod provider patterns

## Implementation Order

1. **Create AddNodesService** (new file)
2. **Create Test Data Builder** (new file)
3. **Create AddNodesService Tests** (new file)
4. **Refactor AddNodesNotifier** (modify existing)
5. **Create AddNodesNotifier Tests** (new file)
6. **Verify Architecture Compliance** (grep checks)

---

## Step 1: Create AddNodesService

**File**: `lib/page/nodes/services/add_nodes_service.dart`

```dart
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

/// Riverpod provider for AddNodesService
final addNodesServiceProvider = Provider<AddNodesService>((ref) {
  return AddNodesService(ref.watch(routerRepositoryProvider));
});

/// Stateless service for Add Nodes / Bluetooth Auto-Onboarding operations
class AddNodesService {
  AddNodesService(this._routerRepository);

  final RouterRepository _routerRepository;

  // Implement methods per contract...
}
```

**Key Points**:
- Service imports JNAP models (allowed per Article V)
- Service imports jnap_error_mapper for error conversion
- Service is stateless (only holds RouterRepository)

---

## Step 2: Create Test Data Builder

**File**: `test/mocks/test_data/add_nodes_test_data.dart`

```dart
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for AddNodesService tests
class AddNodesTestData {
  /// Create auto-onboarding settings success response
  static JNAPSuccess createAutoOnboardingSettingsSuccess({
    bool isEnabled = true,
  }) => JNAPSuccess(
    result: 'ok',
    output: {'isAutoOnboardingEnabled': isEnabled},
  );

  /// Create auto-onboarding status response
  static JNAPSuccess createAutoOnboardingStatusSuccess({
    String status = 'Idle',
    List<Map<String, dynamic>>? deviceOnboardingStatus,
  }) => JNAPSuccess(
    result: 'ok',
    output: {
      'autoOnboardingStatus': status,
      'deviceOnboardingStatus': deviceOnboardingStatus ?? [],
    },
  );

  /// Create getDevices success response
  static JNAPSuccess createDevicesSuccess({
    List<Map<String, dynamic>>? devices,
  }) => JNAPSuccess(
    result: 'ok',
    output: {'devices': devices ?? []},
  );

  /// Create backhaul info success response
  static JNAPSuccess createBackhaulInfoSuccess({
    List<Map<String, dynamic>>? backhaulDevices,
  }) => JNAPSuccess(
    result: 'ok',
    output: {'backhaulDevices': backhaulDevices ?? []},
  );
}
```

---

## Step 3: Create Service Tests

**File**: `test/page/nodes/services/add_nodes_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/nodes/services/add_nodes_service.dart';

import '../../../mocks/test_data/add_nodes_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late AddNodesService service;
  late MockRouterRepository mockRepo;

  setUp(() {
    mockRepo = MockRouterRepository();
    service = AddNodesService(mockRepo);
  });

  group('AddNodesService - setAutoOnboardingSettings', () {
    test('sends correct JNAP action with auth', () async {
      when(() => mockRepo.send(any(), data: any(named: 'data'), auth: true))
          .thenAnswer((_) async => AddNodesTestData.createAutoOnboardingSettingsSuccess());

      await service.setAutoOnboardingSettings();

      verify(() => mockRepo.send(
        JNAPAction.setBluetoothAutoOnboardingSettings,
        data: {'isAutoOnboardingEnabled': true},
        auth: true,
      )).called(1);
    });

    test('throws ServiceError on JNAP failure', () async {
      when(() => mockRepo.send(any(), data: any(named: 'data'), auth: true))
          .thenThrow(JNAPError(result: 'ErrorUnknown'));

      expect(
        () => service.setAutoOnboardingSettings(),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  // Add more test groups per contract...
}
```

---

## Step 4: Refactor AddNodesNotifier

**File**: `lib/page/nodes/providers/add_nodes_provider.dart`

**Remove these imports**:
```dart
// DELETE these lines:
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
```

**Add these imports**:
```dart
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/nodes/services/add_nodes_service.dart';
```

**Refactor pattern**:
```dart
// BEFORE (in Notifier):
final repo = ref.read(routerRepositoryProvider);
await repo.send(JNAPAction.setBluetoothAutoOnboardingSettings, ...);

// AFTER:
final service = ref.read(addNodesServiceProvider);
await service.setAutoOnboardingSettings();
```

---

## Step 5: Create Provider Tests

**File**: `test/page/nodes/providers/add_nodes_provider_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/services/add_nodes_service.dart';

class MockAddNodesService extends Mock implements AddNodesService {}

void main() {
  late MockAddNodesService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockAddNodesService();
    container = ProviderContainer(overrides: [
      addNodesServiceProvider.overrideWithValue(mockService),
    ]);
  });

  tearDown(() => container.dispose());

  // Test Provider delegates to Service correctly...
}
```

---

## Step 6: Verify Architecture Compliance

Run these checks after implementation:

```bash
# Provider should NOT import JNAP models
grep -r "import.*jnap/models" lib/page/nodes/providers/
# Expected: No output

# Provider should NOT import JNAP result
grep -r "import.*jnap/result" lib/page/nodes/providers/
# Expected: No output

# Provider should NOT import JNAP actions
grep -r "import.*jnap/actions" lib/page/nodes/providers/
# Expected: No output

# Service SHOULD import JNAP models
grep -r "import.*jnap/models" lib/page/nodes/services/
# Expected: add_nodes_service.dart

# Run analyzer
flutter analyze lib/page/nodes/

# Run tests
flutter test test/page/nodes/
```

---

## Common Pitfalls

1. **Don't import JNAPAction in Provider** - Use service methods instead
2. **Don't check `is JNAPSuccess` in Provider** - Service handles this
3. **Don't catch JNAPError in Provider** - Only catch ServiceError
4. **Keep LinksysDevice import** - It's from core/utils, not jnap/models

---

## Reference Files

- Service pattern: `lib/page/instant_admin/services/router_password_service.dart`
- Error mapping: `lib/core/errors/jnap_error_mapper.dart`
- ServiceError types: `lib/core/errors/service_error.dart`
- Test data pattern: `test/mocks/test_data/` (existing examples)
