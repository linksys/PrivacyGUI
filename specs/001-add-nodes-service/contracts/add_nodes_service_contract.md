# AddNodesService Contract

**Feature**: 001-add-nodes-service
**Date**: 2026-01-06
**Location**: `lib/page/nodes/services/add_nodes_service.dart`

## Provider Definition

```dart
/// Riverpod provider for AddNodesService
final addNodesServiceProvider = Provider<AddNodesService>((ref) {
  return AddNodesService(ref.watch(routerRepositoryProvider));
});
```

## Class Definition

```dart
/// Stateless service for Add Nodes / Bluetooth Auto-Onboarding operations
///
/// Encapsulates JNAP communication for node onboarding, separating
/// business logic from state management (AddNodesNotifier).
///
/// Reference: constitution Article VI - Service Layer Principle
class AddNodesService {
  /// Constructor injection of RouterRepository
  AddNodesService(this._routerRepository);

  final RouterRepository _routerRepository;
}
```

---

## Method Contracts

### setAutoOnboardingSettings

```dart
/// Enables Bluetooth auto-onboarding on the router
///
/// Sends JNAPAction.setBluetoothAutoOnboardingSettings with
/// isAutoOnboardingEnabled = true
///
/// Throws:
///   - [NetworkError] if router communication fails
///   - [UnauthorizedError] if authentication expired
///   - [UnexpectedError] for other JNAP failures
Future<void> setAutoOnboardingSettings() async
```

**JNAP Action**: `setBluetoothAutoOnboardingSettings`
**Auth**: Required (`auth: true`)

---

### getAutoOnboardingSettings

```dart
/// Fetches current Bluetooth auto-onboarding setting
///
/// Returns:
///   - `true` if auto-onboarding is enabled
///   - `false` if disabled or not configured
///
/// Throws:
///   - [NetworkError] if router communication fails
///   - [UnauthorizedError] if authentication expired
///   - [UnexpectedError] for other JNAP failures
Future<bool> getAutoOnboardingSettings() async
```

**JNAP Action**: `getBluetoothAutoOnboardingSettings`
**Auth**: Required (`auth: true`)

---

### pollAutoOnboardingStatus

```dart
/// Polls auto-onboarding status until Idle or Complete
///
/// Parameters:
///   - [oneTake]: If true, polls once and returns immediately
///
/// Returns: Stream emitting status maps:
/// ```dart
/// {
///   'status': 'Idle' | 'Onboarding' | 'Complete',
///   'deviceOnboardingStatus': List<Map<String, dynamic>>,
/// }
/// ```
///
/// Stream completes when:
///   - Status reaches 'Idle' or 'Complete'
///   - Max retries exhausted (18 retries × 10s = 3 minutes)
///
/// Throws:
///   - [NetworkError] if all retries fail
///   - [UnauthorizedError] if authentication expired
Stream<Map<String, dynamic>> pollAutoOnboardingStatus({bool oneTake = false})
```

**JNAP Action**: `getBluetoothAutoOnboardingStatus`
**Auth**: Required (`auth: true`)
**Polling Config**:
- `maxRetry`: 1 (oneTake) or 18
- `retryDelayInMilliSec`: 10000
- `firstDelayInMilliSec`: 100 (oneTake) or 3000

---

### startAutoOnboarding

```dart
/// Initiates the Bluetooth auto-onboarding process
///
/// Internally calls JNAPAction.startBlueboothAutoOnboarding
///
/// Throws:
///   - [NetworkError] if router communication fails
///   - [UnauthorizedError] if authentication expired
///   - [UnexpectedError] for other JNAP failures
Future<void> startAutoOnboarding() async
```

**JNAP Action**: `startBlueboothAutoOnboarding` (note: typo preserved from API)
**Auth**: Required (`auth: true`)

---

### pollForNodesOnline

```dart
/// Polls for onboarded nodes to come online
///
/// Parameters:
///   - [onboardedMACList]: MAC addresses to watch for
///   - [refreshing]: If true, uses shorter timeouts for refresh operations
///
/// Returns: Stream of device lists where each emission contains
/// all currently visible nodes (nodeType != null)
///
/// Stream completes when:
///   - All MAC addresses found in online nodes with connections, OR
///   - Max retries exhausted
///
/// Polling Config:
///   - Normal: 20s first delay, 20s retry delay, 9 + (MACs × 6) retries
///   - Refreshing: 1s first delay, 3s retry delay, 5 retries
///
/// Note: Stream completion with partial results is NOT an error.
/// Provider handles empty/partial results per clarification session.
Stream<List<LinksysDevice>> pollForNodesOnline(
  List<String> onboardedMACList, {
  bool refreshing = false,
})
```

**JNAP Action**: `getDevices`
**Auth**: Required (`auth: true`)

---

### pollNodesBackhaulInfo

```dart
/// Polls backhaul info for child nodes and enriches device data
///
/// Parameters:
///   - [nodes]: List of nodes to get backhaul info for
///   - [refreshing]: If true, uses shorter timeouts
///
/// Returns: Stream of enriched LinksysDevice lists with
/// wirelessConnectionInfo and connectionType populated from backhaul data
///
/// Polling Config:
///   - Normal: 3s delay, 20 retries
///   - Refreshing: 1s first delay, 3s retry delay, 1 retry
///
/// Stream completes when:
///   - All child node UUIDs found in backhaul info, OR
///   - Max retries exhausted
Stream<List<LinksysDevice>> pollNodesBackhaulInfo(
  List<LinksysDevice> nodes, {
  bool refreshing = false,
})
```

**JNAP Action**: `getBackhaulInfo`
**Auth**: Required (`auth: true`)

---

## Error Handling Contract

All methods follow constitution Article XIII error mapping:

```dart
// Pattern for all methods
try {
  // JNAP operation
} on JNAPError catch (e) {
  throw mapJnapErrorToServiceError(e);
}
```

| JNAPError Pattern | ServiceError |
|-------------------|--------------|
| Network/timeout | `NetworkError` |
| `_ErrorUnauthorized` | `UnauthorizedError` |
| Other | `UnexpectedError(originalError: e)` |

---

## Usage Example

```dart
// In AddNodesNotifier
class AddNodesNotifier extends AutoDisposeNotifier<AddNodesState> {
  AddNodesService get _service => ref.read(addNodesServiceProvider);

  Future<void> startAutoOnboarding() async {
    try {
      await _service.setAutoOnboardingSettings();
      await _service.startBluetoothAutoOnboarding();

      await for (final status in _service.pollAutoOnboardingStatus()) {
        // Update UI state based on status
        if (status['status'] == 'Onboarding') {
          state = state.copyWith(loadingMessage: 'onboarding');
        }
      }

      final macList = _extractOnboardedMACs(/* from last status */);
      await for (final devices in _service.pollForNodesOnline(macList)) {
        // Process devices...
      }
    } on NetworkError {
      // Handle network issues
    } on ServiceError catch (e) {
      // Handle other service errors
    }
  }
}
```

---

## Testing Contract

Service tests MUST mock RouterRepository and verify:

1. **setAutoOnboardingSettings**: Calls correct JNAP action with auth
2. **getAutoOnboardingSettings**: Returns boolean from JNAP output
3. **pollAutoOnboardingStatus**: Transforms JNAPResult to status map
4. **startAutoOnboarding**: Calls correct JNAP action
5. **pollForNodesOnline**: Transforms devices, handles stream completion
6. **pollNodesBackhaulInfo**: Merges backhaul info into LinksysDevice
7. **Error mapping**: JNAPError → ServiceError for each method
