# Service Contract: AutoParentFirstLoginService

**Date**: 2026-01-07
**Feature**: 001-auto-parent-login-service
**Reference**: constitution.md Article IX Section 9.2

---

## Overview

`AutoParentFirstLoginService` is a stateless service class that encapsulates JNAP communication for the first-time login flow in the auto-parent (Linksys App/Router) setup process.

---

## Provider Definition

```dart
/// Riverpod provider for AutoParentFirstLoginService
final autoParentFirstLoginServiceProvider = Provider<AutoParentFirstLoginService>((ref) {
  return AutoParentFirstLoginService(
    ref.watch(routerRepositoryProvider),
  );
});
```

---

## Class Definition

```dart
/// Stateless service for auto-parent first-time login operations.
///
/// Handles JNAP communication for:
/// - Setting user acknowledged auto configuration
/// - Configuring firmware update policy
/// - Checking internet connection status
///
/// Follows constitution.md Article VI Section 6.2:
/// - Handles all JNAP API communication
/// - Returns simple results (void, bool), not raw JNAP responses
/// - Stateless (no internal state)
/// - Dependencies injected via constructor
class AutoParentFirstLoginService {
  AutoParentFirstLoginService(this._routerRepository);

  final RouterRepository _routerRepository;
}
```

---

## Method Contracts

### setUserAcknowledgedAutoConfiguration

**Purpose**: Mark that user has acknowledged the auto-configuration on the router.

**Signature**:
```dart
/// Sets userAcknowledgedAutoConfiguration flag on the router.
///
/// Awaits the JNAP response to ensure the operation completes.
///
/// JNAP Action: [JNAPAction.setUserAcknowledgedAutoConfiguration]
///
/// Returns: [Future<void>] completes when operation succeeds
///
/// Throws: [ServiceError] if operation fails
Future<void> setUserAcknowledgedAutoConfiguration()
```

**Behavior**:
- Sends JNAP action and **awaits** the response
- Catches `JNAPError` and converts to `ServiceError`
- Propagates errors to caller for proper handling

**JNAP Details**:
| Property | Value |
|----------|-------|
| Action | `JNAPAction.setUserAcknowledgedAutoConfiguration` |
| fetchRemote | `true` |
| cacheLevel | `CacheLevel.noCache` |
| data | `{}` |
| auth | `true` |

---

### setFirmwareUpdatePolicy

**Purpose**: Fetch current firmware settings and set the update policy to auto-update.

**Signature**:
```dart
/// Fetches current firmware update settings and enables auto-update policy.
///
/// If fetching current settings fails, uses default settings:
/// - updatePolicy: firmwareUpdatePolicyAuto
/// - autoUpdateWindow: startMinute=0, durationMinutes=240
///
/// JNAP Actions:
/// - GET: [JNAPAction.getFirmwareUpdateSettings]
/// - SET: [JNAPAction.setFirmwareUpdateSettings]
///
/// Returns: [Future<void>] completes when settings are saved
///
/// Throws: [ServiceError] if save operation fails
Future<void> setFirmwareUpdatePolicy()
```

**Behavior**:
1. Fetch current settings via `getFirmwareUpdateSettings`
2. On fetch success: modify `updatePolicy` to `firmwareUpdatePolicyAuto`
3. On fetch failure: use fallback default settings
4. Save modified settings via `setFirmwareUpdateSettings`

**Default Fallback**:
```dart
FirmwareUpdateSettings(
  updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
  autoUpdateWindow: FirmwareAutoUpdateWindow(
    startMinute: 0,
    durationMinutes: 240,
  ),
)
```

**JNAP Details (GET)**:
| Property | Value |
|----------|-------|
| Action | `JNAPAction.getFirmwareUpdateSettings` |
| fetchRemote | `true` |
| auth | `true` |

**JNAP Details (SET)**:
| Property | Value |
|----------|-------|
| Action | `JNAPAction.setFirmwareUpdateSettings` |
| fetchRemote | `true` |
| cacheLevel | `CacheLevel.noCache` |
| data | `firmwareUpdateSettings.toMap()` |
| auth | `true` |

---

### checkInternetConnection

**Purpose**: Check if router has internet connection with retry logic.

**Signature**:
```dart
/// Checks internet connection status via JNAP with retry logic.
///
/// Uses [ExponentialBackoffRetryStrategy] with:
/// - maxRetries: 5
/// - initialDelay: 2 seconds
/// - maxDelay: 2 seconds
///
/// JNAP Action: [JNAPAction.getInternetConnectionStatus]
///
/// Returns: [Future<bool>]
/// - `true` if connectionStatus == 'InternetConnected'
/// - `false` if not connected, retries exhausted, or error occurred
///
/// Throws: Nothing (returns false on all error conditions)
Future<bool> checkInternetConnection()
```

**Behavior**:
1. Create `ExponentialBackoffRetryStrategy` with configured parameters
2. Execute JNAP call with retry strategy
3. Check `connectionStatus` field in response
4. Return `true` if connected, retry if not
5. Return `false` after max retries or on any error

**JNAP Details**:
| Property | Value |
|----------|-------|
| Action | `JNAPAction.getInternetConnectionStatus` |
| fetchRemote | `true` |
| auth | `true` |

**Retry Configuration**:
| Parameter | Value |
|-----------|-------|
| maxRetries | 5 |
| initialDelay | 2 seconds |
| maxDelay | 2 seconds |
| shouldRetry | `(result) => !result` (retry if false) |

---

## Error Handling

Per constitution.md Article XIII:

| Method | Error Strategy |
|--------|----------------|
| `setUserAcknowledgedAutoConfiguration` | Catch `JNAPError`, throw `ServiceError` via `mapJnapErrorToServiceError()` |
| `setFirmwareUpdatePolicy` | Catch `JNAPError`, throw `ServiceError` via `mapJnapErrorToServiceError()` |
| `checkInternetConnection` | Catch all errors, return `false` |

---

## Dependencies

| Dependency | Injected Via | Purpose |
|------------|--------------|---------|
| `RouterRepository` | Constructor | JNAP communication |

---

## Usage Example

```dart
// In AutoParentFirstLoginNotifier
class AutoParentFirstLoginNotifier extends AutoDisposeNotifier<AutoParentFirstLoginState> {
  Future<void> finishFirstTimeLogin([bool failCheck = false]) async {
    final service = ref.read(autoParentFirstLoginServiceProvider);

    if (!failCheck) {
      final isConnected = await service.checkInternetConnection();
      logger.i('[FirstTime]: Internet connection status: $isConnected');
      await service.setUserAcknowledgedAutoConfiguration(); // now awaited
    }

    await service.setFirmwareUpdatePolicy();
  }
}
```
