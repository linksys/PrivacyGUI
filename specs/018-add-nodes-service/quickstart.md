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

---

# Scope Extension: AddWiredNodesService (2026-01-07)

## Implementation Order (Wired)

1. **Create BackhaulInfoUIModel** (new file)
2. **Create AddWiredNodesService** (new file)
3. **Create Test Data Builder** (new file)
4. **Create AddWiredNodesService Tests** (new file)
5. **Refactor AddWiredNodesNotifier** (modify existing)
6. **Update AddWiredNodesState** (modify existing)
7. **Create AddWiredNodesNotifier Tests** (new file)
8. **Create AddWiredNodesState Tests** (new file)
9. **Verify Architecture Compliance** (grep checks)

---

## Step W1: Create BackhaulInfoUIModel

**File**: `lib/page/nodes/models/backhaul_info_ui_model.dart`

```dart
import 'dart:convert';

import 'package:equatable/equatable.dart';

/// UI-friendly representation of backhaul information
///
/// Replaces BackHaulInfoData (JNAP model) in State/Provider layers.
/// Per constitution Article V Section 5.3.1 - separate models per layer.
class BackhaulInfoUIModel extends Equatable {
  final String deviceUUID;
  final String connectionType;
  final String timestamp;

  const BackhaulInfoUIModel({
    required this.deviceUUID,
    required this.connectionType,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [deviceUUID, connectionType, timestamp];

  Map<String, dynamic> toMap() => {
    'deviceUUID': deviceUUID,
    'connectionType': connectionType,
    'timestamp': timestamp,
  };

  factory BackhaulInfoUIModel.fromMap(Map<String, dynamic> map) =>
      BackhaulInfoUIModel(
        deviceUUID: map['deviceUUID'] ?? '',
        connectionType: map['connectionType'] ?? '',
        timestamp: map['timestamp'] ?? '',
      );

  String toJson() => json.encode(toMap());

  factory BackhaulInfoUIModel.fromJson(String source) =>
      BackhaulInfoUIModel.fromMap(json.decode(source));
}
```

---

## Step W2: Create AddWiredNodesService

**File**: `lib/page/nodes/services/add_wired_nodes_service.dart`

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart';

/// Riverpod provider for AddWiredNodesService
final addWiredNodesServiceProvider = Provider<AddWiredNodesService>((ref) {
  return AddWiredNodesService(ref.watch(routerRepositoryProvider));
});

/// Result container for pollBackhaulChanges stream emissions
class BackhaulPollResult {
  final List<BackhaulInfoUIModel> backhaulList;
  final int foundCounting;
  final bool anyOnboarded;

  const BackhaulPollResult({
    required this.backhaulList,
    required this.foundCounting,
    required this.anyOnboarded,
  });
}

/// Stateless service for Add Wired Nodes operations
class AddWiredNodesService {
  AddWiredNodesService(this._routerRepository);

  final RouterRepository _routerRepository;

  // Implement methods per contract...
}
```

---

## Step W3: Create Test Data Builder (Wired)

**File**: `test/mocks/test_data/add_wired_nodes_test_data.dart`

```dart
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for AddWiredNodesService tests
class AddWiredNodesTestData {
  /// Create wired auto-onboarding settings success response
  static JNAPSuccess createWiredAutoOnboardingSettingsSuccess({
    bool isEnabled = false,
  }) => JNAPSuccess(
    result: 'ok',
    output: {'isAutoOnboardingEnabled': isEnabled},
  );

  /// Create backhaul info success response
  static JNAPSuccess createBackhaulInfoSuccess({
    List<Map<String, dynamic>>? devices,
  }) => JNAPSuccess(
    result: 'ok',
    output: {'backhaulDevices': devices ?? []},
  );

  /// Create getDevices success response
  static JNAPSuccess createDevicesSuccess({
    List<Map<String, dynamic>>? devices,
  }) => JNAPSuccess(
    result: 'ok',
    output: {'devices': devices ?? []},
  );

  /// Create a sample backhaul device entry
  static Map<String, dynamic> createBackhaulDevice({
    String deviceUUID = 'test-uuid-123',
    String connectionType = 'Wired',
    String? timestamp,
  }) => {
    'deviceUUID': deviceUUID,
    'connectionType': connectionType,
    'timestamp': timestamp ?? DateTime.now().toIso8601String(),
  };

  /// Create JNAP error
  static JNAPError createJNAPError({String result = 'ErrorUnknown'}) =>
      JNAPError(result: result);
}
```

---

## Step W4: Refactor AddWiredNodesNotifier

**File**: `lib/page/nodes/providers/add_wired_nodes_provider.dart`

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
import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart';
import 'package:privacy_gui/page/nodes/services/add_wired_nodes_service.dart';
```

**Refactor pattern**:
```dart
// BEFORE:
final repo = ref.read(routerRepositoryProvider);
await repo.send(JNAPAction.setWiredAutoOnboardingSettings, ...);

// AFTER:
final service = ref.read(addWiredNodesServiceProvider);
await service.setAutoOnboardingEnabled(true);
```

---

## Step W5: Update AddWiredNodesState

**File**: `lib/page/nodes/providers/add_wired_nodes_state.dart`

**Change**:
```dart
// BEFORE:
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
// ...
final List<BackHaulInfoData>? backhaulSnapshot;

// AFTER:
import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart';
// ...
final List<BackhaulInfoUIModel>? backhaulSnapshot;
```

---

## Step W6: Verify Architecture Compliance (Extended)

```bash
# Wired Provider should NOT import JNAP models/result/actions
grep -r "import.*jnap/models" lib/page/nodes/providers/add_wired*
grep -r "import.*jnap/result" lib/page/nodes/providers/add_wired*
grep -r "import.*jnap/actions" lib/page/nodes/providers/add_wired*
# Expected: No output for all three

# Wired Service SHOULD import JNAP models
grep -r "import.*jnap/models" lib/page/nodes/services/add_wired*
# Expected: add_wired_nodes_service.dart

# Run analyzer
flutter analyze lib/page/nodes/

# Run tests
flutter test test/page/nodes/
```

---

## Common Pitfalls (Wired-specific)

1. **Don't forget to update State import** - State uses BackhaulInfoUIModel now
2. **Move timestamp comparison logic to Service** - DateFormat parsing belongs in Service
3. **Keep deviceManagerProvider read in Notifier** - It's state coordination, not JNAP
4. **Keep idleCheckerPauseProvider in Notifier** - It's UI lifecycle coordination
