# Implementation Checklist: Device Manager Service Extraction

**Purpose**: Validate implementation completeness and architecture compliance for service extraction
**Created**: 2025-12-28
**Feature**: [spec.md](../spec.md) | [plan.md](../plan.md)

## Architecture Compliance

- [x] CHK001 `DeviceManagerService` created at `lib/core/jnap/services/device_manager_service.dart`
- [x] CHK002 `deviceManagerServiceProvider` defined as `Provider<DeviceManagerService>`
- [x] CHK003 Service constructor accepts `RouterRepository` as dependency
- [x] CHK004 `DeviceManagerNotifier` imports `deviceManagerServiceProvider` from service file
- [x] CHK005 Provider file has ZERO imports from `core/jnap/models/`
- [x] CHK006 Provider file has ZERO imports from `core/jnap/result/`
- [x] CHK007 Provider file has ZERO imports from `core/jnap/actions/`

## Service Methods

- [x] CHK008 `transformPollingData(CoreTransactionData?)` method implemented
- [x] CHK009 `transformPollingData` returns empty/default state when input is null
- [x] CHK010 `updateDeviceNameAndIcon()` method implemented with correct signature
- [x] CHK011 `deleteDevices(List<String>)` method implemented
- [x] CHK012 `deleteDevices` returns empty map immediately when input list is empty
- [x] CHK013 `deauthClient(String macAddress)` method implemented

## Provider Delegation

- [x] CHK014 `DeviceManagerNotifier.build()` uses `ref.read(deviceManagerServiceProvider)`
- [x] CHK015 `build()` delegates to `service.transformPollingData()`
- [x] CHK016 `updateDeviceNameAndIcon()` delegates to service
- [x] CHK017 `deleteDevices()` delegates to service
- [x] CHK018 `deauthClient()` delegates to service

## State Query Methods (Stay in Notifier)

- [x] CHK019 `isEmptyState()` remains in `DeviceManagerNotifier`
- [x] CHK020 `getSsidConnectedBy()` remains in `DeviceManagerNotifier`
- [x] CHK021 `getBandConnectedBy()` remains in `DeviceManagerNotifier`
- [x] CHK022 `findParent()` remains in `DeviceManagerNotifier`

## Error Handling

- [x] CHK023 Service maps JNAP errors to `ServiceError` types
- [x] CHK024 `updateDeviceNameAndIcon` throws `ServiceError` on JNAP failure
- [x] CHK025 `deleteDevices` returns partial success map on partial failure
- [x] CHK026 `deauthClient` throws `ServiceError` on JNAP failure

## Test Coverage

- [x] CHK027 Service test file created at `test/core/jnap/services/device_manager_service_test.dart`
- [x] CHK028 Provider test file created at `test/core/jnap/providers/device_manager_provider_test.dart`
- [x] CHK029 Test data builder created at `test/mocks/test_data/device_manager_test_data.dart`
- [x] CHK030 Service tests cover `transformPollingData` with null input
- [x] CHK031 Service tests cover `transformPollingData` with valid data
- [x] CHK032 Service tests cover `updateDeviceNameAndIcon` success case
- [x] CHK033 Service tests cover `updateDeviceNameAndIcon` error case
- [x] CHK034 Service tests cover `deleteDevices` with empty list
- [x] CHK035 Service tests cover `deleteDevices` with valid IDs
- [x] CHK036 Service tests cover `deauthClient` success case
- [x] CHK037 Provider tests verify delegation to service
- [x] CHK038 Service test coverage ≥ 90%
- [x] CHK039 Provider test coverage ≥ 85%

## Regression Verification

- [x] CHK040 All existing tests pass (`./run_tests.sh`)
- [ ] CHK041 Device list displays correctly in UI
- [ ] CHK042 Device name/icon updates work
- [ ] CHK043 Device deletion works
- [ ] CHK044 Client deauthentication works

## Verification Commands

```bash
# Check provider has no JNAP imports (should output nothing)
grep -E "import.*jnap/(models|result|actions)" lib/core/jnap/providers/device_manager_provider.dart

# Check service has JNAP imports (should output multiple lines)
grep -E "import.*jnap/models" lib/core/jnap/services/device_manager_service.dart

# Run service tests
flutter test test/core/jnap/services/device_manager_service_test.dart

# Run provider tests
flutter test test/core/jnap/providers/device_manager_provider_test.dart

# Run full test suite
./run_tests.sh
```

## Notes

- Check items off as completed: `[x]`
- CHK005-CHK007 are the critical success criteria for architecture compliance
- CHK019-CHK022 ensure helper methods stay in notifier (they query cached state, not JNAP)
- CHK038-CHK039 must be verified with coverage tools before marking complete
