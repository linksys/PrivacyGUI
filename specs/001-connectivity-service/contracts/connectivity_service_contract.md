# ConnectivityService Contract

**Date**: 2026-01-02
**Feature**: 001-connectivity-service

## Overview

This document defines the API contract for `ConnectivityService`, the service layer component responsible for connectivity-related JNAP operations.

## Service Definition

### Class: ConnectivityService

**Location**: `lib/providers/connectivity/services/connectivity_service.dart`

**Dependencies**:
- `RouterRepository` (constructor injection)

**Provider**:
```dart
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(ref.watch(routerRepositoryProvider));
});
```

---

## Methods

### 1. testRouterType

**Purpose**: Determine the type of router connection based on device serial number.

**Signature**:
```dart
Future<RouterType> testRouterType(String? gatewayIp) async
```

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `gatewayIp` | `String?` | No | The gateway IP address to test |

**Returns**: `Future<RouterType>`
- `RouterType.behindManaged` - Connected to the managed router (serial numbers match)
- `RouterType.behind` - Connected to a different Linksys router
- `RouterType.others` - Not connected to a Linksys router or unreachable

**Error Handling**:
- This method **never throws**
- On any JNAP error → returns `RouterType.others`
- On empty serial number → returns `RouterType.others`
- On SharedPreferences error → returns `RouterType.others`

**JNAP Actions Used**:
- `JNAPAction.getDeviceInfo` - Retrieves router serial number

**Example Usage**:
```dart
final service = ref.read(connectivityServiceProvider);
final routerType = await service.testRouterType('192.168.1.1');

switch (routerType) {
  case RouterType.behindManaged:
    // User is connected to their managed router
    break;
  case RouterType.behind:
    // User is connected to a different Linksys router
    break;
  case RouterType.others:
    // User is not connected to a Linksys router
    break;
}
```

---

### 2. fetchRouterConfiguredData

**Purpose**: Check if the router has been configured (password changed from default).

**Signature**:
```dart
Future<RouterConfiguredData> fetchRouterConfiguredData() async
```

**Parameters**: None

**Returns**: `Future<RouterConfiguredData>`
```dart
RouterConfiguredData(
  isDefaultPassword: bool,  // true if password is factory default
  isSetByUser: bool,        // true if password was set by user
)
```

**Error Handling**:
- Throws `ServiceError` on JNAP failure
- Uses `mapJnapErrorToServiceError()` for error conversion

**Possible Errors**:
| Error Type | When |
|------------|------|
| `ConnectivityError` | Router unreachable |
| `UnauthorizedError` | Authentication required |
| `UnexpectedError` | Other JNAP errors |

**JNAP Actions Used**:
- `JNAPAction.isAdminPasswordDefault` (via `fetchIsConfigured()`)

**Example Usage**:
```dart
final service = ref.read(connectivityServiceProvider);

try {
  final configData = await service.fetchRouterConfiguredData();

  if (configData.isDefaultPassword) {
    // Router has default password, guide user to set up
  } else if (configData.isSetByUser) {
    // Router is configured
  }
} on ConnectivityError {
  // Router not reachable
} on ServiceError catch (e) {
  // Handle other errors
}
```

---

## Integration with ConnectivityNotifier

After refactoring, `ConnectivityNotifier` will use the service as follows:

```dart
class ConnectivityNotifier extends Notifier<ConnectivityState>
    with ConnectivityListener, AvailabilityChecker {

  Future<RouterType> _testRouterType(String? gatewayIp) async {
    final service = ref.read(connectivityServiceProvider);
    return service.testRouterType(gatewayIp);
  }

  Future<RouterConfiguredData> isRouterConfigured() async {
    final service = ref.read(connectivityServiceProvider);
    return service.fetchRouterConfiguredData();
  }
}
```

---

## Testing Contract

### Mock Setup
```dart
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockRouterRepository extends Mock implements RouterRepository {}
```

### Required Test Cases

**testRouterType**:
1. Returns `RouterType.behindManaged` when serial numbers match
2. Returns `RouterType.behind` when serial numbers differ
3. Returns `RouterType.others` when JNAP call fails
4. Returns `RouterType.others` when serial number is empty
5. Returns `RouterType.others` when gateway IP is null

**fetchRouterConfiguredData**:
1. Returns correct data on successful JNAP response
2. Throws `ServiceError` on JNAP failure
3. Handles default password state correctly
4. Handles user-set password state correctly
