# Research: NodeDetail Service Extraction

**Date**: 2026-01-02
**Feature**: 001-node-detail-service

## Research Summary

This document captures the research findings for extracting NodeDetailService from NodeDetailNotifier.

## 1. Service Pattern Implementation

### Decision
Follow the established Service pattern used in `RouterPasswordService` as the reference implementation.

### Rationale
- `RouterPasswordService` (`lib/page/instant_admin/services/router_password_service.dart`) provides a proven pattern
- Consistent with constitution.md Article VI requirements
- Uses constructor injection for RouterRepository dependency
- Maps JNAPError to ServiceError using centralized mapper

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|-----------------|
| Inherit from base service class | Over-engineering, no existing pattern in codebase |
| Use method injection (pass repo per call) | Violates constructor injection pattern (constitution Section 6.2) |

## 2. Error Mapping Strategy

### Decision
Use centralized `mapJnapErrorToServiceError()` from `lib/core/errors/jnap_error_mapper.dart`.

### Rationale
- Already exists and handles common JNAP errors
- Consistent with other Services in codebase
- Falls back to `UnexpectedError` for unmapped errors
- Keeps error mapping DRY across services

### Relevant Errors for LED Blink Operations
The LED blink JNAP actions (`startBlinkNodeLed`, `stopBlinkNodeLed`) may throw:
- `_ErrorUnauthorized` → `UnauthorizedError`
- Network failures → `UnexpectedError` (fallback)

No custom error types needed for this feature.

## 3. State Transformation Approach

### Decision
Service provides transformation helper methods; Provider creates state by calling these helpers.

### Rationale
- Clarified in spec.md Session 2026-01-02
- Aligns with constitution Article VI Section 6.2: "Services SHALL be stateless"
- Provider retains state management responsibility
- Service only transforms JNAP model data to primitive/UI values

### Implementation Pattern
```dart
// Service - stateless transformation helper
class NodeDetailService {
  /// Transforms RawDevice to UI-appropriate values
  Map<String, dynamic> transformDeviceToUIValues(
    RawDevice device,
    RawDevice? masterDevice,
    WanStatus? wanStatus,
  ) {
    return {
      'location': device.getDeviceLocation(),
      'isMaster': device.deviceID == masterDevice?.deviceID,
      // ... other transformed values
    };
  }
}

// Provider - uses helper to create state
class NodeDetailNotifier {
  NodeDetailState createState(...) {
    final service = ref.read(nodeDetailServiceProvider);
    final values = service.transformDeviceToUIValues(device, master, wanStatus);
    return NodeDetailState(
      location: values['location'],
      // ...
    );
  }
}
```

## 4. JNAP Actions to Extract

### Decision
Extract `startBlinkNodeLed` and `stopBlinkNodeLed` JNAP actions to Service.

### Current Implementation
```dart
// In NodeDetailNotifier (BEFORE)
Future startBlinkNodeLED(String deviceId) async {
  final repository = ref.read(routerRepositoryProvider);
  return repository.send(
    JNAPAction.startBlinkNodeLed,
    data: {'deviceID': deviceId},
    fetchRemote: true,
    cacheLevel: CacheLevel.noCache,
    auth: true,
  );
}
```

### Target Implementation
```dart
// In NodeDetailService (AFTER)
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
```

## 5. SharedPreferences Usage

### Decision
Keep SharedPreferences usage in Provider layer.

### Rationale
- SharedPreferences tracks UI state (which device is currently blinking)
- This is a UI concern, not JNAP communication
- Per spec.md Assumptions: "SharedPreferences usage for blink tracking will remain in the Provider layer"

## 6. Dependencies Analysis

### Imports to REMOVE from Provider
```dart
// These will be removed from node_detail_provider.dart
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
```

### Imports to REMOVE from State
```dart
// This will be removed from node_detail_state.dart
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
```

### Imports to ADD to Service
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
```

## 7. Test Data Builder Pattern

### Decision
Create `NodeDetailTestData` class for JNAP mock responses.

### Location
`test/mocks/test_data/node_detail_test_data.dart`

### Structure
```dart
class NodeDetailTestData {
  static JNAPSuccess createBlinkNodeSuccess() => JNAPSuccess(
    result: 'ok',
    output: {},
  );

  static JNAPError createBlinkNodeError(String errorResult) => JNAPError(
    result: errorResult,
    error: null,
  );
}
```

## 8. Reference Implementations Reviewed

| File | Key Patterns Extracted |
|------|----------------------|
| `router_password_service.dart` | Service provider definition, constructor injection, JNAPError mapping |
| `health_check_service.dart` | Data transformation helpers |
| `jnap_error_mapper.dart` | Centralized error mapping function |

## Research Conclusion

All NEEDS CLARIFICATION items have been resolved. The implementation approach is:
1. Create `NodeDetailService` following `RouterPasswordService` pattern
2. Move LED blink JNAP calls to Service with error mapping
3. Add transformation helpers for device data
4. Keep SharedPreferences in Provider
5. Create test data builder and comprehensive tests
