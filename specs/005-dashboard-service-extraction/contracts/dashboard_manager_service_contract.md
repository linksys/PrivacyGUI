# Service Contract: DashboardManagerService

**Version**: 1.0
**Date**: 2025-12-29
**Location**: `lib/core/jnap/services/dashboard_manager_service.dart`

## Overview

Stateless service that encapsulates all JNAP communication for dashboard functionality. Transforms raw polling data into `DashboardManagerState` and provides on-demand device info operations.

---

## Provider Definition

```dart
final dashboardManagerServiceProvider = Provider<DashboardManagerService>((ref) {
  return DashboardManagerService(ref.watch(routerRepositoryProvider));
});
```

---

## Class Definition

```dart
class DashboardManagerService {
  final RouterRepository _routerRepository;

  DashboardManagerService(this._routerRepository);

  // Public methods defined below
}
```

---

## Method Contracts

### transformPollingData

Transforms raw JNAP polling data into `DashboardManagerState`.

```dart
/// Transforms polling data into DashboardManagerState.
///
/// [pollingResult] - Raw JNAP transaction data from pollingProvider.
///                   Can be null during initial load.
///
/// Returns: Complete DashboardManagerState with all dashboard information.
///
/// Behavior:
/// - If [pollingResult] is null, returns empty default state
/// - Processes all available JNAP action results
/// - Skips failed actions gracefully (uses defaults for those fields)
/// - Never throws - always returns valid state
///
/// JNAP Actions Processed:
/// - getDeviceInfo → deviceInfo
/// - getRadioInfo → mainRadios
/// - getGuestRadioSettings → guestRadios, isGuestNetworkEnabled
/// - getSystemStats → uptimes, cpuLoad, memoryLoad
/// - getEthernetPortConnections → wanConnection, lanConnections
/// - getLocalTime → localTime
/// - getSoftSKUSettings → skuModelNumber
DashboardManagerState transformPollingData(CoreTransactionData? pollingResult);
```

**Input/Output**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pollingResult` | `CoreTransactionData?` | No | Raw polling data from pollingProvider |
| **Returns** | `DashboardManagerState` | - | Transformed state, never null |

**Example Usage**:

```dart
// In DashboardManagerNotifier.build()
DashboardManagerState build() {
  final coreTransactionData = ref.watch(pollingProvider).value;
  final service = ref.read(dashboardManagerServiceProvider);
  return service.transformPollingData(coreTransactionData);
}
```

---

### checkRouterIsBack

Verifies router is accessible and matches expected serial number.

```dart
/// Verifies router connectivity and serial number matching.
///
/// [expectedSerialNumber] - Serial number to match against router response.
///
/// Returns: NodeDeviceInfo if router is accessible and SN matches.
///
/// Throws:
/// - [SerialNumberMismatchError] if router responds but SN doesn't match
/// - [ConnectivityError] if router is not accessible
/// - [UnexpectedError] for other failures
Future<NodeDeviceInfo> checkRouterIsBack(String expectedSerialNumber);
```

**Input/Output**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `expectedSerialNumber` | `String` | Yes | Expected serial number from stored preferences |
| **Returns** | `NodeDeviceInfo` | - | Device info on success |
| **Throws** | `ServiceError` | - | On any failure |

**Example Usage**:

```dart
// In DashboardManagerNotifier
Future<NodeDeviceInfo> checkRouterIsBack() async {
  final service = ref.read(dashboardManagerServiceProvider);
  final prefs = await SharedPreferences.getInstance();
  final currentSN = prefs.getString(pCurrentSN) ?? prefs.getString(pPnpConfiguredSN);
  return service.checkRouterIsBack(currentSN ?? '');
}
```

---

### checkDeviceInfo

Fetches device info, using API call only if needed.

```dart
/// Fetches device information on-demand.
///
/// [cachedDeviceInfo] - Currently cached device info from state (may be null).
///
/// Returns: NodeDeviceInfo from cache if available, otherwise from API.
///
/// Throws:
/// - [ConnectivityError] if API call fails
/// - [UnexpectedError] for other failures
///
/// Note: This method receives cached value as parameter rather than
/// accessing provider state directly, keeping service stateless.
Future<NodeDeviceInfo> checkDeviceInfo(NodeDeviceInfo? cachedDeviceInfo);
```

**Input/Output**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cachedDeviceInfo` | `NodeDeviceInfo?` | No | Cached value from current state |
| **Returns** | `NodeDeviceInfo` | - | Cached or fresh device info |
| **Throws** | `ServiceError` | - | If API call fails |

**Example Usage**:

```dart
// In DashboardManagerNotifier
Future<NodeDeviceInfo> checkDeviceInfo(String? serialNumber) async {
  final service = ref.read(dashboardManagerServiceProvider);
  return service.checkDeviceInfo(state.deviceInfo);
}
```

---

## Error Handling

### ServiceError Types Used

```dart
// From lib/core/errors/service_error.dart

/// Thrown when serial number doesn't match expected value
final class SerialNumberMismatchError extends ServiceError {
  final String expected;
  final String actual;
  const SerialNumberMismatchError({required this.expected, required this.actual});
}

/// Thrown when router is not accessible
final class ConnectivityError extends ServiceError {
  final String? message;
  const ConnectivityError({this.message});
}

/// Thrown for unexpected failures
final class UnexpectedError extends ServiceError {
  final Object? originalError;
  final String? message;
  const UnexpectedError({this.originalError, this.message});
}
```

### Error Mapping

```dart
ServiceError _mapJnapError(JNAPError error) {
  return switch (error.result) {
    '_ErrorUnauthorized' => const UnauthorizedError(),
    _ => UnexpectedError(originalError: error, message: error.result),
  };
}
```

---

## Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
| `RouterRepository` | Constructor injection | JNAP API communication |
| `JNAPAction` | Static reference | Action identifiers |
| `JNAPSuccess`, `JNAPError` | Types | Response/error handling |
| JNAP Models | Imports | Data parsing |

---

## Testing Contract

### Required Test Cases

**transformPollingData()**:
- [ ] Returns default state when pollingResult is null
- [ ] Returns complete state when all actions succeed
- [ ] Returns partial state when some actions fail
- [ ] Correctly parses each JNAP action response
- [ ] Uses default localTime when parsing fails

**checkRouterIsBack()**:
- [ ] Returns NodeDeviceInfo when SN matches
- [ ] Throws SerialNumberMismatchError when SN doesn't match
- [ ] Throws ConnectivityError when router unreachable
- [ ] Maps JNAPError to ServiceError correctly

**checkDeviceInfo()**:
- [ ] Returns cached value immediately when available
- [ ] Makes API call when cached value is null
- [ ] Throws ServiceError on API failure
