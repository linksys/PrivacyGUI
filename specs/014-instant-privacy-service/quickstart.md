# Quickstart: InstantPrivacyService Extraction

**Date**: 2026-01-02
**Branch**: `001-instant-privacy-service`

## Overview

This guide walks through implementing the InstantPrivacyService extraction from InstantPrivacyNotifier.

## Prerequisites

- Branch: `001-instant-privacy-service`
- Flutter SDK 3.3+
- Understanding of constitution.md Articles V, VI, XIII

## Step-by-Step Implementation

### Step 1: Create Service File

Create `lib/page/instant_privacy/services/instant_privacy_service.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

final instantPrivacyServiceProvider = Provider<InstantPrivacyService>((ref) {
  return InstantPrivacyService(ref.watch(routerRepositoryProvider));
});

class InstantPrivacyService {
  InstantPrivacyService(this._routerRepository);

  final RouterRepository _routerRepository;

  // Implement methods per contracts/instant_privacy_service_contract.md
}
```

### Step 2: Create Test Data Builder

Create `test/mocks/test_data/instant_privacy_test_data.dart`:

```dart
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

class InstantPrivacyTestData {
  static JNAPSuccess createMacFilterSettingsSuccess({
    String macFilterMode = 'Disabled',
    int maxMacAddresses = 32,
    List<String> macAddresses = const [],
  }) => JNAPSuccess(
    result: 'OK',
    output: {
      'macFilterMode': macFilterMode,
      'maxMACAddresses': maxMacAddresses,
      'macAddresses': macAddresses,
    },
  );

  static JNAPSuccess createStaBssidsSuccess({
    List<String> staBssids = const [],
  }) => JNAPSuccess(
    result: 'OK',
    output: {'staBSSIDS': staBssids},
  );

  static JNAPSuccess createLocalDeviceSuccess({
    String deviceId = 'test-device-id',
  }) => JNAPSuccess(
    result: 'OK',
    output: {'deviceID': deviceId},
  );
}
```

### Step 3: Create Service Tests

Create `test/page/instant_privacy/services/instant_privacy_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// ... imports

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late InstantPrivacyService service;
  late MockRouterRepository mockRepo;

  setUp(() {
    mockRepo = MockRouterRepository();
    service = InstantPrivacyService(mockRepo);
  });

  group('InstantPrivacyService - fetchMacFilterSettings', () {
    test('returns settings and status on success', () async {
      // Arrange
      when(() => mockRepo.send(any(), fetchRemote: any(named: 'fetchRemote'), auth: any(named: 'auth')))
          .thenAnswer((_) async => InstantPrivacyTestData.createMacFilterSettingsSuccess());

      // Act
      final (settings, status) = await service.fetchMacFilterSettings();

      // Assert
      expect(settings, isNotNull);
      expect(status, isNotNull);
      expect(status!.mode, MacFilterMode.disabled);
    });

    // Add more tests per contract
  });
}
```

### Step 4: Update Provider

Modify `lib/page/instant_privacy/providers/instant_privacy_provider.dart`:

**Remove imports**:
```dart
// DELETE these:
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
```

**Add import**:
```dart
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';
```

**Update performFetch**:
```dart
@override
Future<(InstantPrivacySettings?, InstantPrivacyStatus?)> performFetch({
  bool forceRemote = false,
  bool updateStatusOnly = false,
}) async {
  final service = ref.read(instantPrivacyServiceProvider);
  final deviceList = ref.read(deviceManagerProvider).deviceList;

  final (settings, status) = await service.fetchMacFilterSettings(
    forceRemote: forceRemote,
    updateStatusOnly: updateStatusOnly,
  );

  if (settings != null) {
    final myMac = await service.fetchMyMacAddress(deviceList);
    return (settings.copyWith(myMac: myMac), status);
  }

  return (settings, status);
}
```

**Update performSave**:
```dart
@override
Future<void> performSave() async {
  final service = ref.read(instantPrivacyServiceProvider);
  final nodesMacAddresses = ref
      .read(deviceManagerProvider)
      .nodeDevices
      .map((e) => e.getMacAddress().toUpperCase())
      .toList();

  await service.saveMacFilterSettings(
    state.settings.current,
    nodesMacAddresses,
  );
}
```

### Step 5: Update Provider Tests

Modify `test/page/instant_privacy/providers/instant_privacy_provider_test.dart`:

```dart
class MockInstantPrivacyService extends Mock implements InstantPrivacyService {}

// Update tests to mock Service instead of RouterRepository
```

### Step 6: Run Verification

```bash
# Check architecture compliance
grep -r "import.*jnap/models" lib/page/instant_privacy/providers/
# Should return no results

grep -r "import.*jnap/actions" lib/page/instant_privacy/providers/
# Should return no results

# Run tests
flutter test test/page/instant_privacy/
```

## File Summary

| File | Action |
|------|--------|
| `lib/page/instant_privacy/services/instant_privacy_service.dart` | CREATE |
| `lib/page/instant_privacy/providers/instant_privacy_provider.dart` | MODIFY |
| `test/mocks/test_data/instant_privacy_test_data.dart` | CREATE |
| `test/page/instant_privacy/services/instant_privacy_service_test.dart` | CREATE |
| `test/page/instant_privacy/providers/instant_privacy_provider_test.dart` | MODIFY |

## Success Criteria Verification

| Criterion | Verification Command |
|-----------|---------------------|
| SC-001: No JNAP imports in Provider | `grep -r "import.*jnap/models" lib/page/instant_privacy/providers/` |
| SC-004/005: Architecture compliance | Same grep commands |
| SC-006: Service test coverage ≥90% | `flutter test --coverage` |
| SC-003: Existing tests pass | `flutter test test/page/instant_privacy/` |

## Next Steps

After implementation:
1. Run `/speckit.tasks` to generate detailed task breakdown
2. Execute tasks sequentially
3. Run architecture compliance checks
4. Submit for code review
