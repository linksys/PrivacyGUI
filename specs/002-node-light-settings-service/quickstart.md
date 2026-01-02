# Quickstart: NodeLightSettings Service Extraction

**Feature**: 002-node-light-settings-service
**Date**: 2026-01-02

## Overview

Extract `NodeLightSettingsService` from `NodeLightSettingsNotifier` to enforce three-layer architecture compliance.

## Prerequisites

- Flutter 3.3+
- Dart 3.0+
- Project dependencies installed (`flutter pub get`)

## Implementation Steps

### Step 1: Create Service File

Create `lib/core/jnap/services/node_light_settings_service.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

final nodeLightSettingsServiceProvider = Provider<NodeLightSettingsService>((ref) {
  return NodeLightSettingsService(ref.watch(routerRepositoryProvider));
});

class NodeLightSettingsService {
  final RouterRepository _routerRepository;

  NodeLightSettingsService(this._routerRepository);

  Future<NodeLightSettings> fetchSettings({bool forceRemote = false}) async {
    // Implementation
  }

  Future<NodeLightSettings> saveSettings(NodeLightSettings settings) async {
    // Implementation
  }

  ServiceError _mapJnapError(JNAPError error) {
    // Error mapping
  }
}
```

### Step 2: Refactor Provider

Update `lib/core/jnap/providers/node_light_settings_provider.dart`:

1. Remove JNAP imports:
   ```dart
   // REMOVE these:
   // import 'package:privacy_gui/core/jnap/actions/better_action.dart';
   // import 'package:privacy_gui/core/jnap/router_repository.dart';
   ```

2. Add service import:
   ```dart
   import 'package:privacy_gui/core/jnap/services/node_light_settings_service.dart';
   ```

3. Delegate methods to service:
   ```dart
   Future<NodeLightSettings> fetch([bool forceRemote = false]) async {
     final service = ref.read(nodeLightSettingsServiceProvider);
     state = await service.fetchSettings(forceRemote: forceRemote);
     return state;
   }
   ```

### Step 3: Write Tests

Create `test/core/jnap/services/node_light_settings_service_test.dart`:

```dart
void main() {
  group('NodeLightSettingsService', () {
    test('fetchSettings returns settings from JNAP', () async {
      // Test implementation
    });

    test('saveSettings persists and re-fetches', () async {
      // Test implementation
    });
  });
}
```

## Verification Commands

```bash
# Check no JNAP imports in provider
grep -r "import.*jnap/actions" lib/core/jnap/providers/node_light_settings_provider.dart
# Should return empty (no matches)

grep -r "import.*router_repository" lib/core/jnap/providers/node_light_settings_provider.dart
# Should return empty (no matches)

# Run static analysis
flutter analyze lib/core/jnap/providers/node_light_settings_provider.dart
flutter analyze lib/core/jnap/services/node_light_settings_service.dart

# Run tests
flutter test test/core/jnap/models/node_light_settings_test.dart
flutter test test/core/jnap/services/node_light_settings_service_test.dart
flutter test test/core/jnap/providers/node_light_settings_provider_test.dart
```

## File Checklist

| File | Action | Status |
|------|--------|--------|
| `lib/core/jnap/services/node_light_settings_service.dart` | Create | ☐ |
| `lib/core/jnap/providers/node_light_settings_provider.dart` | Refactor | ☐ |
| `test/core/jnap/models/node_light_settings_test.dart` | Create | ☐ |
| `test/core/jnap/services/node_light_settings_service_test.dart` | Create | ☐ |
| `test/core/jnap/providers/node_light_settings_provider_test.dart` | Create/Update | ☐ |

## Success Criteria Checklist

- [ ] Zero JNAP imports in provider file
- [ ] Service handles all JNAP communication
- [ ] Service maps errors to ServiceError types
- [ ] Provider delegates to service
- [ ] currentStatus getter remains in provider
- [ ] All tests pass
- [ ] flutter analyze passes
