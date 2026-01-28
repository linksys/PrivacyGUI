# Quickstart: InstantTopology Service Extraction

**Branch**: `001-instant-topology-service`
**Date**: 2026-01-02

## Overview

This guide helps developers quickly understand and implement the InstantTopologyService extraction.

---

## TL;DR

Extract 5 JNAP-related methods from `InstantTopologyNotifier` to `InstantTopologyService`:
- `reboot()` → `rebootNodes()`
- `factoryReset()` → `factoryResetNodes()`
- `startBlinkNodeLED()` → `startBlinkNodeLED()`
- `stopBlinkNodeLED()` → `stopBlinkNodeLED()`
- `_waitForNodesOffline()` → `waitForNodesOffline()`

---

## Files to Create

### 1. Service File
```
lib/page/instant_topology/services/instant_topology_service.dart
```

### 2. Test Files
```
test/page/instant_topology/services/instant_topology_service_test.dart
test/mocks/test_data/instant_topology_test_data.dart
```

---

## Files to Modify

### 1. Add ServiceError types
```
lib/core/errors/service_error.dart
```

Add:
- `TopologyTimeoutError`
- `NodeOfflineError`
- `NodeOperationFailedError`

### 2. Update Provider
```
lib/page/instant_topology/providers/instant_topology_provider.dart
```

Remove:
- JNAP imports
- Direct `routerRepositoryProvider` usage
- `JNAPSuccess` type checks

Add:
- Service provider import
- Delegate to service methods
- Catch `ServiceError` types

---

## Implementation Steps

### Step 1: Add ServiceError Types (5 min)

Add to `lib/core/errors/service_error.dart`:

```dart
// Topology Operation Errors
final class TopologyTimeoutError extends ServiceError {
  final Duration timeout;
  final List<String> deviceIds;
  const TopologyTimeoutError({required this.timeout, required this.deviceIds});
}

final class NodeOfflineError extends ServiceError {
  final String deviceId;
  const NodeOfflineError({required this.deviceId});
}

final class NodeOperationFailedError extends ServiceError {
  final String deviceId;
  final String operation;
  final Object? originalError;
  const NodeOperationFailedError({
    required this.deviceId,
    required this.operation,
    this.originalError,
  });
}
```

### Step 2: Create Service (30 min)

Create `lib/page/instant_topology/services/instant_topology_service.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

final instantTopologyServiceProvider = Provider<InstantTopologyService>((ref) {
  return InstantTopologyService(ref.watch(routerRepositoryProvider));
});

class InstantTopologyService {
  InstantTopologyService(this._routerRepository);
  final RouterRepository _routerRepository;

  // Implement methods per contract...
}
```

### Step 3: Update Provider (20 min)

Modify `lib/page/instant_topology/providers/instant_topology_provider.dart`:

**Before:**
```dart
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
// ... more JNAP imports

Future reboot([List<String> deviceUUIDs = const []]) {
  final routerRepository = ref.read(routerRepositoryProvider);
  // ... direct JNAP calls
}
```

**After:**
```dart
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/instant_topology/services/instant_topology_service.dart';

Future<void> reboot([List<String> deviceUUIDs = const []]) async {
  final service = ref.read(instantTopologyServiceProvider);
  await service.rebootNodes(deviceUUIDs);
}
```

### Step 4: Write Tests (45 min)

Create service test with mock RouterRepository:

```dart
// test/page/instant_topology/services/instant_topology_service_test.dart
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late InstantTopologyService service;
  late MockRouterRepository mockRepo;

  setUp(() {
    mockRepo = MockRouterRepository();
    service = InstantTopologyService(mockRepo);
  });

  group('InstantTopologyService - rebootNodes', () {
    test('sends reboot action for master node when list is empty', () async {
      when(() => mockRepo.send(any(), ...)).thenAnswer((_) async => ...);
      await service.rebootNodes([]);
      verify(() => mockRepo.send(JNAPAction.reboot, ...)).called(1);
    });
    // ... more tests
  });
}
```

---

## Verification Checklist

Run these commands after implementation:

```bash
# 1. No JNAP imports in Provider
grep -r "import.*jnap/actions" lib/page/instant_topology/providers/
# Expected: No output

# 2. No RouterRepository in Provider
grep -r "routerRepositoryProvider" lib/page/instant_topology/providers/
# Expected: No output

# 3. Service has JNAP imports
grep -r "import.*jnap" lib/page/instant_topology/services/
# Expected: Multiple matches

# 4. Run tests
flutter test test/page/instant_topology/
# Expected: All tests pass

# 5. Run analyzer
dart analyze lib/page/instant_topology/
# Expected: No issues
```

---

## Reference Files

| Purpose | File |
|---------|------|
| Service Pattern | `lib/page/instant_admin/services/router_password_service.dart` |
| Error Mapper | `lib/core/errors/jnap_error_mapper.dart` |
| ServiceError | `lib/core/errors/service_error.dart` |
| Constitution | `.specify/memory/constitution.md` |
| Full Contract | `specs/001-instant-topology-service/contracts/instant_topology_service_contract.md` |

---

## Common Pitfalls

1. **Don't forget `auth: true`** - All topology JNAP actions require authentication
2. **Reverse order for multi-node** - Process nodes bottom-up (leaf nodes first)
3. **Keep SharedPreferences in Provider** - Blink tracking is UI state, not business logic
4. **Use `mapJnapErrorToServiceError`** - Don't reinvent error mapping
