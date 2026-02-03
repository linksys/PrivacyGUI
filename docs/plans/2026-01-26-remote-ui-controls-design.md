# Remote Read-Only Mode - UI Controls Protection Design

**Date:** 2026-01-26
**Status:** Design Complete, Ready for Implementation

## Overview

Extend the remote read-only mode protection to the UI layer by disabling all interactive controls that can trigger router configuration changes when users access remotely via Linksys Cloud.

## Problem Statement

The current implementation provides:
1. ✅ Global banner notification
2. ✅ RouterRepository defensive layer (blocks JNAP SET operations)

**Missing protection**: UI controls remain enabled in remote mode, creating poor user experience:
- Users can toggle switches but changes are blocked at service layer
- Form Save buttons appear enabled but fail when clicked
- No visual indication that controls are disabled

## Goals

1. **Disable all configuration controls** in remote mode at UI layer
2. **Distinguish between two operation modes**:
   - **Immediate mode**: Switches that directly trigger JNAP operations
   - **Form mode**: Pages with Save buttons that batch changes
3. **Maintain consistent UX**: Disabled controls should visually indicate they cannot be used

## Non-Goals

- Disabling read-only operations (GET, status checks)
- Disabling pure UI state controls (filters, sorting, display options)
- Modifying ui_kit_library external dependency

## Architecture

### Protection Layers

```
┌─────────────────────────────────────────┐
│ Layer 1: UI Controls (NEW)              │
│   - RemoteAwareSwitch (immediate mode)  │
│   - UiKitBottomBarConfig (form mode)    │
├─────────────────────────────────────────┤
│ Layer 2: User Notification              │
│   - RemoteReadOnlyBanner (existing)     │
├─────────────────────────────────────────┤
│ Layer 3: Service Defense                │
│   - RouterRepository checks (existing)  │
└─────────────────────────────────────────┘
```

### Two Operation Modes

#### Mode A: Immediate Effect (Direct JNAP Operations)

**Characteristics**:
- Switch directly triggers provider action
- No intermediate form state
- No Save button required
- Changes apply immediately

**Example** (Dashboard Quick Panel):
```dart
AppSwitch(
  value: isWiFiEnabled,
  onChanged: (value) {
    // Directly calls JNAP operation
    ref.read(wifiProvider.notifier).toggleWiFi(value);
  },
)
```

**Solution**: Use `RemoteAwareSwitch` wrapper

#### Mode B: Form Mode (Deferred Save)

**Characteristics**:
- Switch only updates local form state
- Changes tracked via `isDirty` flag
- Requires explicit Save button click
- Uses `UiKitBottomBarConfig` for bottom bar

**Example** (Instant-Safety):
```dart
AppSwitch(
  value: enableSafeBrowsing,
  onChanged: (enable) {
    // Only updates local state
    _notifier.setSafeBrowsingEnabled(enable);
  },
)

bottomBar: UiKitBottomBarConfig(
  isPositiveEnabled: state.isDirty,
  onPositiveTap: _saveSettings, // Actual JNAP operation
),
```

**Solution**: Enhance `UiKitBottomBarConfig` to auto-disable Save button

## Design Details

### 1. RemoteAwareSwitch Component

**Purpose**: Wrapper for `AppSwitch` that automatically disables in remote mode

**Location**: `lib/page/components/views/remote_aware_switch.dart`

**Implementation**:
```dart
class RemoteAwareSwitch extends ConsumerWidget {
  const RemoteAwareSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReadOnly = ref.watch(
      remoteAccessProvider.select((state) => state.isRemoteReadOnly),
    );

    return AppSwitch(
      value: value,
      onChanged: isReadOnly ? null : onChanged,
    );
  }
}
```

**API**: Identical to `AppSwitch` for easy drop-in replacement

**Usage**:
```dart
// Before
AppSwitch(
  value: isEnabled,
  onChanged: (value) => updateSetting(value),
)

// After
RemoteAwareSwitch(
  value: isEnabled,
  onChanged: (value) => updateSetting(value),
)
```

### 2. UiKitBottomBarConfig Enhancement

**Purpose**: Auto-disable Save button in remote mode for all form pages

**Location**: `lib/page/components/ui_kit_page_view.dart`

**Changes**:

#### 2.1 Add checkRemoteReadOnly parameter

```dart
class UiKitBottomBarConfig {
  final String? positiveLabel;
  final String? negativeLabel;
  final VoidCallback? onPositiveTap;
  final VoidCallback? onNegativeTap;
  final bool isPositiveEnabled;
  final bool isNegativeEnabled;
  final bool isDestructive;
  final bool checkRemoteReadOnly;  // NEW

  const UiKitBottomBarConfig({
    this.positiveLabel,
    this.negativeLabel,
    this.onPositiveTap,
    this.onNegativeTap,
    this.isPositiveEnabled = true,
    this.isNegativeEnabled = true,
    this.isDestructive = false,
    this.checkRemoteReadOnly = true,  // NEW: default true
  });
}
```

#### 2.2 Modify _buildBottomBarConfig()

```dart
PageBottomBarConfig? _buildBottomBarConfig() {
  if (widget.bottomBar == null) return null;

  final bottomBar = widget.bottomBar!;

  // Check remote read-only mode
  final isRemoteReadOnly = bottomBar.checkRemoteReadOnly
    ? ref.watch(remoteAccessProvider.select((state) => state.isRemoteReadOnly))
    : false;

  return PageBottomBarConfig(
    positiveLabel: bottomBar.positiveLabel ?? loc(context).save,
    negativeLabel: bottomBar.negativeLabel,
    onPositiveTap: bottomBar.onPositiveTap,
    onNegativeTap: () {
      bottomBar.onNegativeTap?.call();
      if (bottomBar.onNegativeTap == null) {
        context.pop();
      }
    },
    isPositiveEnabled: bottomBar.isPositiveEnabled && !isRemoteReadOnly,  // MODIFIED
    isNegativeEnabled: bottomBar.isNegativeEnabled,
    isDestructive: bottomBar.isDestructive,
  );
}
```

**Benefits**:
- All form pages automatically protected
- No changes needed in individual pages
- Opt-out available via `checkRemoteReadOnly: false` for special cases

## Implementation Strategy

### Phase 1: Core Components (Priority: High)

1. **Create RemoteAwareSwitch**
   - Implement component
   - Write unit tests (enable/disable behavior)
   - Write widget tests (visual state)

2. **Enhance UiKitBottomBarConfig**
   - Add `checkRemoteReadOnly` parameter
   - Modify `_buildBottomBarConfig()` method
   - Add tests for button disable logic

3. **Import statement cleanup**
   - Add to components export files

### Phase 2: Replace Immediate Mode Switches (Priority: High)

Identify and replace switches that directly trigger JNAP operations:

**Identification criteria**:
- Switch `onChanged` directly calls provider methods that trigger JNAP operations
- No Save button on the page
- Changes apply immediately

**Process**:
1. Search for `AppSwitch` usage across codebase
2. Trace `onChanged` callback to determine if it's immediate mode
3. Replace with `RemoteAwareSwitch` if immediate mode
4. Test each replacement

**Estimated files**: 15-20 switches (exact count TBD during implementation)

**Key pages to check**:
- Dashboard Quick Panel
- WiFi Settings main page
- Node detail settings
- VPN status toggles
- Any other "instant action" switches

### Phase 3: Verification & Testing (Priority: High)

1. **Manual testing**:
   - Use `BuildConfig.forceCommandType = ForceCommand.remote` to test
   - Verify all immediate switches are disabled
   - Verify all Save buttons are disabled
   - Check visual feedback (grayed out)

2. **Automated testing**:
   - Unit tests for RemoteAwareSwitch
   - Unit tests for UiKitBottomBarConfig
   - Integration tests for key pages

3. **Regression testing**:
   - Run full test suite
   - Ensure no existing functionality broken

## Testing Strategy

### Unit Tests

**RemoteAwareSwitch** (`test/page/components/views/remote_aware_switch_test.dart`):
- ✅ Switch enabled in local mode
- ✅ Switch disabled in remote mode (onChanged = null)
- ✅ Value displays correctly in both modes
- ✅ Reactive update when loginType changes

**UiKitBottomBarConfig**:
- ✅ Save button enabled in local mode when isDirty
- ✅ Save button disabled in remote mode regardless of isDirty
- ✅ Opt-out works with checkRemoteReadOnly: false
- ✅ Cancel button unaffected

### Widget Tests

**RemoteAwareSwitch**:
- ✅ Visual state shows disabled appearance in remote mode
- ✅ onChanged not triggered when disabled
- ✅ Matches AppSwitch behavior in local mode

**Form Pages**:
- ✅ Save button visually disabled in remote mode
- ✅ onPositiveTap not triggered when disabled

### Integration Tests

- ✅ Dashboard Quick Panel switches disabled in remote mode
- ✅ Instant-Safety Save button disabled in remote mode
- ✅ Banner + disabled controls work together
- ✅ Switching from local to remote updates UI state

## Edge Cases & Considerations

### 1. Already Disabled Switches

**Scenario**: Switch already disabled due to other conditions (e.g., feature not available)

**Solution**: Remote check uses AND logic:
```dart
onChanged: isReadOnly ? null : (isFeatureAvailable ? callback : null)
```

### 2. Pure UI Controls

**Scenario**: Switch controls only UI state (filters, display options)

**Solution**: Continue using `AppSwitch`, do not replace with `RemoteAwareSwitch`

### 3. Mixed Form Pages

**Scenario**: Page has both immediate switches and a Save button

**Solution**:
- Use `RemoteAwareSwitch` for immediate switches
- Use `UiKitBottomBarConfig` for Save button
- Both protections apply independently

### 4. Opt-Out Requirement

**Scenario**: Save button that doesn't trigger JNAP operations (rare)

**Solution**: Use `checkRemoteReadOnly: false`:
```dart
bottomBar: UiKitBottomBarConfig(
  checkRemoteReadOnly: false,  // Opt out of remote check
  isPositiveEnabled: isDirty,
  onPositiveTap: saveUIPreferences,
)
```

## Migration Guide

### For Immediate Mode Switches

**Before**:
```dart
AppSwitch(
  value: isFeatureEnabled,
  onChanged: (value) => toggleFeature(value),
)
```

**After**:
```dart
RemoteAwareSwitch(
  value: isFeatureEnabled,
  onChanged: (value) => toggleFeature(value),
)
```

### For Form Mode Pages

**No changes required** - all pages using `UiKitBottomBarConfig` automatically protected.

**Exception** (if Save button should work in remote mode):
```dart
bottomBar: UiKitBottomBarConfig(
  checkRemoteReadOnly: false,  // Only if truly needed
  isPositiveEnabled: state.isDirty,
  onPositiveTap: _saveSettings,
)
```

## Files to Modify

### New Files
- `lib/page/components/views/remote_aware_switch.dart`
- `test/page/components/views/remote_aware_switch_test.dart`

### Modified Files
- `lib/page/components/ui_kit_page_view.dart` (UiKitBottomBarConfig)
- 15-20 page files (replace AppSwitch with RemoteAwareSwitch)
  - Exact list determined during implementation
  - Each replacement requires code review to confirm it's immediate mode

### Test Files
- `test/page/components/ui_kit_page_view_test.dart` (if exists)
- Integration tests for affected pages

## Success Criteria

1. ✅ All immediate-mode switches disabled in remote mode
2. ✅ All form Save buttons disabled in remote mode
3. ✅ Pure UI controls remain functional
4. ✅ Visual feedback clear (grayed out/disabled appearance)
5. ✅ No functionality broken in local mode
6. ✅ All tests passing (unit, widget, integration)
7. ✅ Manual testing confirms expected behavior

## Risks & Mitigations

### Risk 1: Missing Some Switches

**Risk**: Not all immediate-mode switches identified and replaced

**Mitigation**:
- Systematic codebase search for `AppSwitch`
- Code review for each switch usage
- RouterRepository defensive layer provides backup protection

### Risk 2: Breaking Existing Functionality

**Risk**: Changes break local mode behavior

**Mitigation**:
- Comprehensive test coverage
- No changes to switch behavior in local mode
- Careful testing of each replacement

### Risk 3: UX Confusion

**Risk**: Users don't understand why controls are disabled

**Mitigation**:
- Banner remains visible explaining remote mode
- Disabled visual state (standard Material Design)
- Documentation in usage guide

## Future Enhancements

1. **Tooltip on Hover**: Show "Disabled in remote mode" tooltip
2. **Extend to Other Controls**: Checkbox, Radio, IconButton wrappers
3. **Granular Permissions**: Allow some operations in remote mode
4. **Analytics**: Track attempts to use disabled controls

## References

- Original Design: `docs/plans/2026-01-20-remote-read-only-mode-design.md`
- Usage Guide: `docs/plans/2026-01-20-remote-read-only-mode-usage.md`
- RouterRepository Implementation: `lib/core/jnap/router_repository.dart:75-157`
