# Quickstart: Dashboard Manager Service Extraction

**Date**: 2025-12-29
**Estimated Effort**: Small (~2-3 hours)
**Reference**: [DeviceManagerService](../../lib/core/jnap/services/device_manager_service.dart)

## Prerequisites

- [x] Understand constitution.md Article V, VI, XIII
- [x] Review DeviceManagerService as reference implementation
- [x] Read current dashboard_manager_provider.dart

## Implementation Order

### Step 1: Create Service File

**File**: `lib/core/jnap/services/dashboard_manager_service.dart`

1. Copy structure from `device_manager_service.dart`
2. Create `dashboardManagerServiceProvider`
3. Create `DashboardManagerService` class with `RouterRepository` injection
4. Move `createState()` logic → `transformPollingData()` method
5. Move `_getMainRadioList()` and `_getGuestRadioList()` helpers
6. Implement `checkRouterIsBack()` with error handling
7. Implement `checkDeviceInfo()` with caching logic
8. Add `_mapJnapError()` helper for ServiceError conversion

### Step 2: Refactor Provider

**File**: `lib/core/jnap/providers/dashboard_manager_provider.dart`

1. Remove JNAP imports:
   - `jnap/actions/better_action.dart`
   - `jnap/models/device_info.dart`
   - `jnap/models/guest_radio_settings.dart`
   - `jnap/models/radio_info.dart`
   - `jnap/models/soft_sku_settings.dart`
   - `jnap/result/jnap_result.dart`
   - `jnap/router_repository.dart`

2. Add service import:
   ```dart
   import 'package:privacy_gui/core/jnap/services/dashboard_manager_service.dart';
   ```

3. Refactor `build()` method:
   ```dart
   @override
   DashboardManagerState build() {
     final coreTransactionData = ref.watch(pollingProvider).value;
     final service = ref.read(dashboardManagerServiceProvider);
     return service.transformPollingData(coreTransactionData);
   }
   ```

4. Remove `createState()`, `_getMainRadioList()`, `_getGuestRadioList()` methods

5. Delegate `checkRouterIsBack()`:
   ```dart
   Future<NodeDeviceInfo> checkRouterIsBack() async {
     final service = ref.read(dashboardManagerServiceProvider);
     final prefs = await SharedPreferences.getInstance();
     final currentSN = prefs.getString(pCurrentSN) ?? prefs.getString(pPnpConfiguredSN);
     return service.checkRouterIsBack(currentSN ?? '');
   }
   ```

6. Delegate `checkDeviceInfo()`:
   ```dart
   Future<NodeDeviceInfo> checkDeviceInfo(String? serialNumber) async {
     final service = ref.read(dashboardManagerServiceProvider);
     return service.checkDeviceInfo(state.deviceInfo);
   }
   ```

7. Keep `saveSelectedNetwork()` unchanged (no JNAP calls)

### Step 3: Add ServiceError Types (if needed)

**File**: `lib/core/errors/service_error.dart`

Check if `SerialNumberMismatchError` and `ConnectivityError` exist. If not, add:

```dart
final class SerialNumberMismatchError extends ServiceError {
  final String expected;
  final String actual;
  const SerialNumberMismatchError({required this.expected, required this.actual});
}

final class ConnectivityError extends ServiceError {
  final String? message;
  const ConnectivityError({this.message});
}
```

### Step 4: Create Test Data Builder

**File**: `test/mocks/test_data/dashboard_manager_test_data.dart`

```dart
class DashboardManagerTestData {
  static JNAPSuccess createDeviceInfoSuccess({
    String serialNumber = 'TEST123',
    String modelNumber = 'MX5300',
  }) => JNAPSuccess(
    result: 'OK',
    output: {
      'serialNumber': serialNumber,
      'modelNumber': modelNumber,
      // ... other fields
    },
  );

  // Add methods for each JNAP action response
  // Add createSuccessfulPollingData() for complete test scenarios
}
```

### Step 5: Write Service Tests

**File**: `test/core/jnap/services/dashboard_manager_service_test.dart`

Test groups:
- `transformPollingData` - null input, complete success, partial failure
- `checkRouterIsBack` - success, SN mismatch, connectivity failure
- `checkDeviceInfo` - cached hit, cache miss with API success, API failure

### Step 6: Write Provider Tests

**File**: `test/core/jnap/providers/dashboard_manager_provider_test.dart`

Test groups:
- `build` - delegates to service correctly
- `checkRouterIsBack` - delegates and handles errors
- `checkDeviceInfo` - delegates with correct cached value

### Step 7: Verify Architecture Compliance

Run compliance checks:

```bash
# Should return 0 results for Provider JNAP imports
grep -r "import.*jnap/models" lib/core/jnap/providers/dashboard_manager_provider.dart
grep -r "import.*jnap/result" lib/core/jnap/providers/dashboard_manager_provider.dart
grep -r "import.*jnap/actions" lib/core/jnap/providers/dashboard_manager_provider.dart

# Should have results for Service JNAP imports
grep -r "import.*jnap/models" lib/core/jnap/services/dashboard_manager_service.dart
```

### Step 8: Run Tests

```bash
# Run service tests
flutter test test/core/jnap/services/dashboard_manager_service_test.dart

# Run provider tests
flutter test test/core/jnap/providers/dashboard_manager_provider_test.dart

# Run all tests to check for regressions
./run_tests.sh
```

## Verification Checklist

- [ ] Service created at correct location
- [ ] Provider has no JNAP imports
- [ ] Service tests pass (≥90% coverage)
- [ ] Provider tests pass (≥85% coverage)
- [ ] Existing dashboard functionality unchanged
- [ ] `flutter analyze` passes
- [ ] Architecture compliance checks pass

## Common Pitfalls

1. **Don't forget `intl` import**: The `DateFormat` class is used in time parsing - keep it in service
2. **SharedPreferences**: Keep in provider for `checkRouterIsBack()` - service receives SN as parameter
3. **BenchMarkLogger**: Keep in provider for `checkDeviceInfo()` - or move to service
4. **State access**: Service receives values as parameters, doesn't access provider state
