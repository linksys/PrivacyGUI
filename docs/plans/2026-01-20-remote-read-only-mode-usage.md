# Remote Read-Only Mode - Usage Guide

**Date:** 2026-01-21
**Status:** Implementation Complete

## Overview

When users connect remotely via Linksys Cloud, all router configuration changes (JNAP SET commands) are automatically disabled for security. This guide shows how to integrate remote read-only checks into your UI components.

## Quick Start

### 1. Check Remote Read-Only Status

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';

class MySettingsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the remote read-only status
    final isReadOnly = ref.watch(
      remoteAccessProvider.select((state) => state.isRemoteReadOnly),
    );

    // Use it to disable controls
    return ElevatedButton(
      onPressed: isReadOnly ? null : _onSave,
      child: const Text('Save Settings'),
    );
  }
}
```

### 2. Disable Different Control Types

#### Buttons
```dart
ElevatedButton(
  onPressed: isReadOnly ? null : _onSave,
  child: const Text('Save'),
)
```

#### Switches
```dart
Switch(
  value: state.isEnabled,
  onChanged: isReadOnly ? null : (value) => _updateSetting(value),
)
```

#### Text Fields
```dart
TextField(
  enabled: !isReadOnly,
  controller: _controller,
)
```

#### IconButtons
```dart
IconButton(
  icon: const Icon(Icons.edit),
  onPressed: isReadOnly ? null : _onEdit,
)
```

## Architecture

### Component Hierarchy

```
remoteAccessProvider (Provider<RemoteAccessState>)
    ↓ watches
authProvider (AsyncNotifierProvider<AuthState>)
    ↓ provides
LoginType (local / remote / none)
```

### State Flow

```
User logs in remotely
    ↓
authProvider updates with LoginType.remote
    ↓
remoteAccessProvider recomputes (isRemoteReadOnly = true)
    ↓
UI widgets rebuild with disabled controls
    ↓
Banner appears at top of screen
```

## Banner

A global banner automatically appears at the top of the screen when in remote mode. No action needed - already integrated into [lib/page/components/layouts/root_container.dart](../../lib/page/components/layouts/root_container.dart).

**Banner message**: "Remote View Mode - Setting changes are disabled"

## Defensive Layer

Even if UI controls are enabled by mistake, RouterRepository will **block all write operations** at the service layer:

```dart
// In RouterRepository.send()
if (!_isReadOnlyOperation(action) && _isRemoteReadOnly()) {
  throw const UnexpectedError(
    message: 'Write operations are not allowed in remote read-only mode',
  );
}
```

**Allowed operations** (allowlist):
- `get*` - Get operations (getDeviceInfo, getWANSettings, etc.)
- `is*` - Status checks (isAdminPasswordDefault, etc.)
- `check*` - Validation operations (checkAdminPassword, etc.)

**Blocked operations**: Everything else, including:
- `set*` - All SET operations
- `reboot` - Device reboot
- `factoryReset` - Factory reset
- `deleteDevice` - Device deletion
- etc.

## Best Practices

### DO ✅

```dart
// Use select() to optimize rebuilds
final isReadOnly = ref.watch(
  remoteAccessProvider.select((state) => state.isRemoteReadOnly),
);

// Disable controls that trigger SET operations
ElevatedButton(
  onPressed: isReadOnly ? null : _onSave,
  child: const Text('Save'),
)
```

### DON'T ❌

```dart
// Don't watch entire auth state if you only need remote status
final auth = ref.watch(authProvider); // Rebuilds on every auth change
final isReadOnly = auth.loginType == LoginType.remote; // ❌

// Don't hide controls completely - disable them instead
if (!isReadOnly) { // ❌
  return ElevatedButton(
    onPressed: _onSave,
    child: const Text('Save'),
  );
}
// User won't see the button, won't understand why
```

### When to Use

Apply remote read-only checks to:
- **Any button that saves settings** (Save, Apply, Update, etc.)
- **Any switch/checkbox that changes router state** (Enable WiFi, etc.)
- **Any input field for configuration** (SSID, Password, IP address, etc.)
- **Any action that modifies data** (Add, Delete, Edit, etc.)

Do NOT apply to:
- **View/Read operations** (Refresh, View Details, etc.)
- **Navigation** (Back, Cancel, etc.)
- **Local UI state** (Expand/Collapse, Filter, Sort, etc.)

## Testing

### Unit Tests

See [test/providers/remote_access/](../../test/providers/remote_access/) for examples:

```dart
test('UI is disabled in remote mode', () {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(() => TestAuthNotifier(
        const AsyncValue.data(AuthState(loginType: LoginType.remote)),
      )),
    ],
  );

  final isReadOnly = container.read(remoteAccessProvider).isRemoteReadOnly;
  expect(isReadOnly, true);
});
```

### Widget Tests

```dart
testWidgets('Save button is disabled in remote mode', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => TestAuthNotifier(
          const AsyncValue.data(AuthState(loginType: LoginType.remote)),
        )),
      ],
      child: MySettingsWidget(),
    ),
  );

  final saveButton = find.text('Save');
  expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNull);
});
```

## Compile-Time Testing

For testing remote mode behavior without actual remote login:

```dart
// In BuildConfig
BuildConfig.forceCommandType = ForceCommand.remote;
```

This will force the app into remote read-only mode regardless of actual `loginType`.

## Related Files

### Core Implementation
- [lib/providers/remote_access/remote_access_provider.dart](../../lib/providers/remote_access/remote_access_provider.dart) - Provider logic
- [lib/providers/remote_access/remote_access_state.dart](../../lib/providers/remote_access/remote_access_state.dart) - State class
- [lib/page/components/views/remote_read_only_banner.dart](../../lib/page/components/views/remote_read_only_banner.dart) - Banner widget
- [lib/core/jnap/router_repository.dart](../../lib/core/jnap/router_repository.dart) - Defensive checks

### Tests
- [test/providers/remote_access/remote_access_provider_test.dart](../../test/providers/remote_access/remote_access_provider_test.dart)
- [test/providers/remote_access/remote_access_state_test.dart](../../test/providers/remote_access/remote_access_state_test.dart)
- [test/page/components/views/remote_read_only_banner_test.dart](../../test/page/components/views/remote_read_only_banner_test.dart)
- [test/core/jnap/router_repository_test.dart](../../test/core/jnap/router_repository_test.dart) - Defensive checks tests

## Future Enhancements

1. **Exception List**: Allowlist specific SET operations in remote mode
2. **Granular Permissions**: Different permission levels (read-only, limited-write, full-access)
3. **Custom Messages**: Per-feature explanations of why controls are disabled
4. **Temporary Override**: Allow privileged operations with additional confirmation

## Questions?

See the design document: [docs/plans/2026-01-20-remote-read-only-mode-design.md](./2026-01-20-remote-read-only-mode-design.md)
