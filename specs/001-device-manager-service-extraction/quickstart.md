# Quickstart: Device Manager Service Extraction

**Feature**: 001-device-manager-service-extraction
**Date**: 2025-12-28

## Overview

This guide provides the essential information to implement the DeviceManagerService extraction.

## Goal

Extract JNAP communication logic from `DeviceManagerNotifier` to `DeviceManagerService` so that:
1. Provider has zero imports from `jnap/models/`, `jnap/result/`, or `jnap/actions/`
2. Service handles all JNAP communication and data transformation
3. All existing functionality works identically

## Files to Create

### 1. DeviceManagerService
**Path**: `lib/core/jnap/services/device_manager_service.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
// ... all JNAP model imports

final deviceManagerServiceProvider = Provider<DeviceManagerService>((ref) {
  return DeviceManagerService(ref.watch(routerRepositoryProvider));
});

class DeviceManagerService {
  final RouterRepository _routerRepository;

  DeviceManagerService(this._routerRepository);

  /// Move ALL transformation logic from DeviceManagerNotifier.createState() here
  DeviceManagerState transformPollingData(CoreTransactionData? pollingResult) {
    // Copy the entire createState() implementation
    // Move _getWirelessConnections, _getDeviceListAndLocations, etc.
  }

  Future<List<RawDeviceProperty>> updateDeviceNameAndIcon({...}) async {
    // Move from DeviceManagerNotifier.updateDeviceNameAndIcon()
  }

  Future<Map<String, bool>> deleteDevices(List<String> deviceIds) async {
    // Move from DeviceManagerNotifier.deleteDevices()
  }

  Future<void> deauthClient(String macAddress) async {
    // Move from DeviceManagerNotifier.deauthClient()
  }
}
```

### 2. Service Tests
**Path**: `test/core/jnap/services/device_manager_service_test.dart`

### 3. Provider Tests
**Path**: `test/core/jnap/providers/device_manager_provider_test.dart`

### 4. Test Data Builder
**Path**: `test/mocks/test_data/device_manager_test_data.dart`

## Files to Modify

### DeviceManagerNotifier
**Path**: `lib/core/jnap/providers/device_manager_provider.dart`

**Remove these imports**:
```dart
// DELETE these lines:
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
// ... all jnap/models imports
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
```

**Keep these imports**:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/services/device_manager_service.dart';  // ADD
```

**Modify build()**:
```dart
@override
DeviceManagerState build() {
  final coreTransactionData = ref.watch(pollingProvider).value;
  final service = ref.read(deviceManagerServiceProvider);
  return service.transformPollingData(coreTransactionData);
}
```

**Keep these methods in Notifier** (they query cached state, not JNAP):
- `isEmptyState()`
- `getSsidConnectedBy()`
- `getBandConnectedBy()`
- `findParent()`
- `_getWirelessSignalOf()` (private helper)
- `_getBandFromKnownInterfacesOf()` (private helper)

## Implementation Order

1. **Create service file** with empty methods
2. **Move transformation logic** (`createState()` and helpers)
3. **Move write operations** (`updateDeviceNameAndIcon`, `deleteDevices`, `deauthClient`)
4. **Update provider** to use service
5. **Remove JNAP imports** from provider
6. **Write tests** for service
7. **Write tests** for provider
8. **Verify** with architecture compliance check

## Verification Commands

```bash
# Check provider has no JNAP imports
grep -E "import.*jnap/(models|result|actions)" lib/core/jnap/providers/device_manager_provider.dart
# Expected: No output

# Check service has JNAP imports
grep -E "import.*jnap/models" lib/core/jnap/services/device_manager_service.dart
# Expected: Multiple imports

# Run tests
flutter test test/core/jnap/services/device_manager_service_test.dart
flutter test test/core/jnap/providers/device_manager_provider_test.dart

# Run all tests to check for regressions
./run_tests.sh
```

## Common Pitfalls

1. **Don't move state query methods** - Methods like `getSsidConnectedBy()` stay in Notifier
2. **Keep DeviceManagerState imports** - The state class is the public API, not a JNAP model
3. **Handle null polling data** - Service must return empty/default state, not throw
4. **Maintain polling refresh** - After write operations, trigger `pollingProvider.notifier.forcePolling()`

## Reference

- **Spec**: [spec.md](./spec.md)
- **Research**: [research.md](./research.md)
- **Contract**: [contracts/device_manager_service_contract.md](./contracts/device_manager_service_contract.md)
- **Similar Implementation**: `lib/page/advanced_settings/firewall/services/firewall_settings_service.dart`
