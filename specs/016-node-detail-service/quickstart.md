# Quickstart: NodeDetail Service Extraction

**Feature**: 001-node-detail-service
**Date**: 2026-01-02

## Overview

This guide provides step-by-step instructions for implementing the NodeDetail service extraction.

## Prerequisites

- Flutter SDK 3.3+
- Project dependencies installed (`flutter pub get`)
- Understanding of Riverpod state management
- Familiarity with constitution.md Articles V, VI, XIII

## Implementation Steps

### Step 1: Create the Service File

Create `lib/page/nodes/services/node_detail_service.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';

final nodeDetailServiceProvider = Provider<NodeDetailService>((ref) {
  return NodeDetailService(ref.watch(routerRepositoryProvider));
});

class NodeDetailService {
  NodeDetailService(this._routerRepository);

  final RouterRepository _routerRepository;

  // Implement methods per contract...
}
```

### Step 2: Implement JNAP Methods

Add LED blink methods to the Service:

```dart
Future<void> startBlinkNodeLED(String deviceId) async {
  try {
    await _routerRepository.send(
      JNAPAction.startBlinkNodeLed,
      data: {'deviceID': deviceId},
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      auth: true,
    );
  } on JNAPError catch (e) {
    throw mapJnapErrorToServiceError(e);
  }
}

Future<void> stopBlinkNodeLED() async {
  try {
    await _routerRepository.send(
      JNAPAction.stopBlinkNodeLed,
      auth: true,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    );
  } on JNAPError catch (e) {
    throw mapJnapErrorToServiceError(e);
  }
}
```

### Step 3: Implement Transformation Helper

Add the transformation method:

```dart
Map<String, dynamic> transformDeviceToUIValues({
  required RawDevice device,
  required RawDevice? masterDevice,
  required WanStatus? wanStatus,
}) {
  final isMaster = device.deviceID == masterDevice?.deviceID;

  return {
    'location': device.getDeviceLocation(),
    'isMaster': isMaster,
    'isOnline': device.isOnline(),
    'isWiredConnection': device.getConnectionType() == DeviceConnectionType.wired,
    'signalStrength': device.signalDecibels ?? 0,
    'serialNumber': device.unit.serialNumber ?? '',
    'modelNumber': device.model.modelNumber ?? '',
    'firmwareVersion': device.unit.firmwareVersion ?? '',
    'hardwareVersion': device.model.hardwareVersion ?? '',
    'lanIpAddress': device.connections.firstOrNull?.ipAddress ?? '',
    'wanIpAddress': wanStatus?.wanConnection?.ipAddress ?? '',
    'upstreamDevice': isMaster
        ? 'INTERNET'
        : (device.upstream?.getDeviceLocation() ??
            masterDevice?.getDeviceLocation() ??
            ''),
    'isMLO': device.wirelessConnectionInfo?.isMultiLinkOperation ?? false,
    'macAddress': device.getMacAddress(),
  };
}
```

### Step 4: Update the Provider

Modify `lib/page/nodes/providers/node_detail_provider.dart`:

1. Remove JNAP imports
2. Add Service import
3. Refactor `createState` to use Service
4. Refactor `startBlinkNodeLED`/`stopBlinkNodeLED` to delegate to Service
5. Add error handling for `ServiceError`

### Step 5: Update the State File

Modify `lib/page/nodes/providers/node_detail_state.dart`:

1. Remove `import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';`

### Step 6: Create Test Data Builder

Create `test/mocks/test_data/node_detail_test_data.dart`:

```dart
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

class NodeDetailTestData {
  static JNAPSuccess createBlinkNodeSuccess() => JNAPSuccess(
    result: 'ok',
    output: {},
  );

  // Add more factory methods...
}
```

### Step 7: Write Service Tests

Create `test/page/nodes/services/node_detail_service_test.dart` with:
- Tests for `startBlinkNodeLED`
- Tests for `stopBlinkNodeLED`
- Tests for `transformDeviceToUIValues`
- Error handling tests

### Step 8: Write Provider Tests

Create `test/page/nodes/providers/node_detail_provider_test.dart` with:
- Tests for `createState`
- Tests for `toggleBlinkNode`
- ServiceError handling tests

### Step 9: Verify Architecture Compliance

Run the compliance checks:

```bash
# Should return 0 results
grep -r "import.*jnap/models" lib/page/nodes/providers/
grep -r "import.*jnap/actions" lib/page/nodes/providers/
grep -r "import.*jnap/command" lib/page/nodes/providers/
grep -r "on JNAPError" lib/page/nodes/providers/

# Should pass
flutter analyze lib/page/nodes/
```

### Step 10: Run Tests

```bash
flutter test test/page/nodes/
```

## Verification Checklist

- [ ] `NodeDetailService` created in `lib/page/nodes/services/`
- [ ] JNAP imports removed from `node_detail_provider.dart`
- [ ] JNAP import removed from `node_detail_state.dart`
- [ ] Service methods delegate JNAP calls with error mapping
- [ ] Provider uses Service for JNAP operations
- [ ] Provider only catches `ServiceError`, not `JNAPError`
- [ ] Service test coverage ≥90%
- [ ] Provider test coverage ≥85%
- [ ] `flutter analyze` passes
- [ ] Architecture compliance checks pass

## Common Pitfalls

1. **Forgetting to map errors**: Always wrap JNAP calls in try-catch and use `mapJnapErrorToServiceError()`
2. **Leaving JNAP imports**: Double-check all imports are removed from Provider
3. **State management in Service**: Service must be stateless - no class fields for state
4. **SharedPreferences**: Keep in Provider, not Service (it's UI state concern)

## Reference Files

- Service pattern: `lib/page/instant_admin/services/router_password_service.dart`
- Error mapper: `lib/core/errors/jnap_error_mapper.dart`
- Constitution: `.specify/memory/constitution.md`
