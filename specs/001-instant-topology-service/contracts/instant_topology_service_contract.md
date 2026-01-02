# API Contract: InstantTopologyService

**Branch**: `001-instant-topology-service`
**Date**: 2026-01-02
**Location**: `lib/page/instant_topology/services/instant_topology_service.dart`

---

## Provider Definition

```dart
/// Riverpod provider for InstantTopologyService
final instantTopologyServiceProvider = Provider<InstantTopologyService>((ref) {
  return InstantTopologyService(
    ref.watch(routerRepositoryProvider),
  );
});
```

---

## Class Definition

```dart
/// Stateless service for topology node operations.
///
/// Encapsulates JNAP communication for reboot, factory reset, and LED blink
/// operations, following the three-layer architecture (Article V, VI).
///
/// All JNAP errors are converted to [ServiceError] subtypes.
class InstantTopologyService {
  InstantTopologyService(this._routerRepository);

  final RouterRepository _routerRepository;

  // ... methods defined below
}
```

---

## Method Contracts

### 1. rebootNodes

```dart
/// Reboots one or more network nodes.
///
/// **Parameters:**
/// - [deviceUUIDs]: List of device UUIDs to reboot. Empty list means master node only.
///
/// **Behavior:**
/// - Empty list: Sends single `JNAPAction.reboot` to master node
/// - Non-empty list: Sends `JNAPAction.reboot2` transaction for each UUID (reverse order)
/// - After transaction: Waits for all specified nodes to go offline
///
/// **Returns:** Future<void> - Completes when nodes are offline
///
/// **Throws:**
/// - [NodeOperationFailedError]: If reboot command fails
/// - [TopologyTimeoutError]: If nodes don't go offline within timeout
/// - [UnexpectedError]: For unexpected JNAP errors
///
/// **Example:**
/// ```dart
/// // Reboot master node only
/// await service.rebootNodes([]);
///
/// // Reboot specific child nodes
/// await service.rebootNodes(['uuid-1', 'uuid-2']);
/// ```
Future<void> rebootNodes(List<String> deviceUUIDs);
```

---

### 2. factoryResetNodes

```dart
/// Factory resets one or more network nodes.
///
/// **Parameters:**
/// - [deviceUUIDs]: List of device UUIDs to reset. Empty list means master node only.
///
/// **Behavior:**
/// - Empty list: Sends single `JNAPAction.factoryReset` to master node
/// - Non-empty list: Sends `JNAPAction.factoryReset2` transaction (reverse order)
/// - After transaction: Waits for all specified nodes to go offline
///
/// **Returns:** Future<void> - Completes when nodes are offline
///
/// **Throws:**
/// - [NodeOperationFailedError]: If factory reset command fails
/// - [TopologyTimeoutError]: If nodes don't go offline within timeout
/// - [UnexpectedError]: For unexpected JNAP errors
///
/// **Example:**
/// ```dart
/// // Factory reset master node
/// await service.factoryResetNodes([]);
///
/// // Factory reset child nodes (bottom-up order)
/// await service.factoryResetNodes(['uuid-leaf', 'uuid-parent']);
/// ```
Future<void> factoryResetNodes(List<String> deviceUUIDs);
```

---

### 3. startBlinkNodeLED

```dart
/// Starts LED blinking on a specific node.
///
/// **Parameters:**
/// - [deviceId]: The device ID of the node to blink
///
/// **Returns:** Future<void> - Completes when blink command is sent
///
/// **Throws:**
/// - [NodeOperationFailedError]: If blink command fails (device: deviceId, operation: 'blinkStart')
/// - [UnexpectedError]: For unexpected JNAP errors
///
/// **Example:**
/// ```dart
/// await service.startBlinkNodeLED('device-123');
/// ```
Future<void> startBlinkNodeLED(String deviceId);
```

---

### 4. stopBlinkNodeLED

```dart
/// Stops LED blinking on all nodes.
///
/// **Returns:** Future<void> - Completes when stop command is sent
///
/// **Throws:**
/// - [NodeOperationFailedError]: If stop command fails (device: '', operation: 'blinkStop')
/// - [UnexpectedError]: For unexpected JNAP errors
///
/// **Example:**
/// ```dart
/// await service.stopBlinkNodeLED();
/// ```
Future<void> stopBlinkNodeLED();
```

---

### 5. waitForNodesOffline (Internal)

```dart
/// Waits for specified nodes to go offline.
///
/// **Parameters:**
/// - [deviceUUIDs]: List of device UUIDs to monitor
/// - [maxRetry]: Maximum number of polling attempts (default: 20)
/// - [retryDelayMs]: Delay between retries in milliseconds (default: 3000)
///
/// **Behavior:**
/// - Polls `JNAPAction.getDevices` at intervals
/// - Completes when all specified devices report offline status
/// - Times out after maxRetry × retryDelayMs milliseconds
///
/// **Returns:** Future<void> - Completes when all nodes are offline
///
/// **Throws:**
/// - [TopologyTimeoutError]: If timeout exceeded (includes timeout duration and device IDs)
///
/// **Note:** This is an internal method called by rebootNodes and factoryResetNodes.
/// It may be made public for testing purposes but is not intended for direct use.
///
/// **Example:**
/// ```dart
/// await service.waitForNodesOffline(
///   ['uuid-1', 'uuid-2'],
///   maxRetry: 10,
///   retryDelayMs: 1000,
/// );
/// ```
Future<void> waitForNodesOffline(
  List<String> deviceUUIDs, {
  int maxRetry = 20,
  int retryDelayMs = 3000,
});
```

---

## Error Handling

### Error Mapping from JNAP

```dart
/// Maps JNAP errors to ServiceError for topology operations.
///
/// Uses the centralized mapper from `jnap_error_mapper.dart` for common errors,
/// with topology-specific handling for operation failures.
ServiceError _mapJnapError(JNAPError error, String deviceId, String operation) {
  // For common errors, use centralized mapper
  final commonError = mapJnapErrorToServiceError(error);
  if (commonError is! UnexpectedError) {
    return commonError;
  }

  // For topology-specific errors
  return NodeOperationFailedError(
    deviceId: deviceId,
    operation: operation,
    originalError: error,
  );
}
```

---

## Usage in Provider

```dart
// lib/page/instant_topology/providers/instant_topology_provider.dart

class InstantTopologyNotifier extends Notifier<InstantTopologyState> {
  Future<void> reboot([List<String> deviceUUIDs = const []]) async {
    final service = ref.read(instantTopologyServiceProvider);
    try {
      await service.rebootNodes(deviceUUIDs);
    } on TopologyTimeoutError catch (e) {
      // Handle timeout - nodes didn't go offline in time
      logger.w('Reboot timeout for devices: ${e.deviceIds}');
    } on NodeOperationFailedError catch (e) {
      // Handle operation failure
      logger.e('Reboot failed for ${e.deviceId}: ${e.operation}');
    } on ServiceError catch (e) {
      // Handle other service errors
      logger.e('Unexpected error: $e');
    }
  }

  Future<void> toggleBlinkNode(String deviceId, [bool stopOnly = false]) async {
    final service = ref.read(instantTopologyServiceProvider);
    final prefs = await SharedPreferences.getInstance();
    final currentBlinkDevice = prefs.get(pBlinkingNodeId);

    try {
      if (currentBlinkDevice != null && deviceId != currentBlinkDevice) {
        await service.stopBlinkNodeLED();
      }
      await service.startBlinkNodeLED(deviceId);
      await prefs.setString(pBlinkingNodeId, deviceId);
    } on ServiceError catch (e) {
      logger.e('Blink operation failed: $e');
    }
  }
}
```

---

## JNAP Actions Used

| Service Method | JNAP Action | Auth Required |
|----------------|-------------|---------------|
| `rebootNodes` (master) | `JNAPAction.reboot` | Yes |
| `rebootNodes` (children) | `JNAPAction.reboot2` | Yes |
| `factoryResetNodes` (master) | `JNAPAction.factoryReset` | Yes |
| `factoryResetNodes` (children) | `JNAPAction.factoryReset2` | Yes |
| `startBlinkNodeLED` | `JNAPAction.startBlinkNodeLed` | Yes |
| `stopBlinkNodeLED` | `JNAPAction.stopBlinkNodeLed` | Yes |
| `waitForNodesOffline` | `JNAPAction.getDevices` | Yes |
