# Remote Read-Only Mode - UI Controls Protection Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Disable all interactive UI controls (switches and save buttons) that trigger router configuration changes when users access the application remotely via Linksys Cloud.

**Architecture:** Two-component approach: (1) RemoteAwareSwitch wrapper for immediate-effect switches, (2) UiKitBottomBarConfig enhancement to auto-disable form Save buttons. Both components watch remoteAccessProvider and disable controls when isRemoteReadOnly is true.

**Tech Stack:** Flutter/Dart, Riverpod (state management), ui_kit_library (UI components), flutter_test (testing)

---

## Task 1: Create RemoteAwareSwitch Component

**Files:**
- Create: `lib/page/components/views/remote_aware_switch.dart`
- Create: `test/page/components/views/remote_aware_switch_test.dart`
- Reference: `lib/providers/remote_access/remote_access_provider.dart` (existing)

### Step 1: Write failing test for RemoteAwareSwitch enabled in local mode

Create test file with first test case:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/components/views/remote_aware_switch.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';
import 'package:ui_kit_library/ui_kit.dart';

// Test helper to create AuthNotifier with specific state
class TestAuthNotifier extends AuthNotifier {
  final AsyncValue<AuthState> testState;

  TestAuthNotifier(this.testState);

  @override
  Future<AuthState> build() async {
    state = testState;
    return testState.when(
      data: (data) => data,
      loading: () => AuthState.empty(),
      error: (_, __) => AuthState.empty(),
    );
  }
}

void main() {
  group('RemoteAwareSwitch', () {
    testWidgets('is enabled in local mode', (WidgetTester tester) async {
      bool? callbackValue;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => TestAuthNotifier(
                  const AsyncValue.data(
                    AuthState(loginType: LoginType.local),
                  ),
                )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RemoteAwareSwitch(
                value: false,
                onChanged: (value) {
                  callbackValue = value;
                },
              ),
            ),
          ),
        ),
      );

      // Find the switch
      final switchFinder = find.byType(AppSwitch);
      expect(switchFinder, findsOneWidget);

      // Get the switch widget
      final appSwitch = tester.widget<AppSwitch>(switchFinder);

      // Verify onChanged is not null (enabled)
      expect(appSwitch.onChanged, isNotNull);

      // Trigger the callback
      appSwitch.onChanged?.call(true);

      // Verify callback was invoked
      expect(callbackValue, true);
    });
  });
}
```

### Step 2: Run test to verify it fails

Run: `flutter test test/page/components/views/remote_aware_switch_test.dart`

Expected: FAIL with "RemoteAwareSwitch not found" or similar import error

### Step 3: Write minimal RemoteAwareSwitch implementation

Create the component file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A switch widget that automatically disables in remote read-only mode.
///
/// This widget wraps AppSwitch and monitors the remote access state.
/// When the application is in remote read-only mode (user logged in remotely
/// or forced remote mode), the switch's onChanged callback is set to null,
/// effectively disabling user interaction.
///
/// Use this for switches that directly trigger JNAP SET operations.
/// For switches that only modify local UI state, use regular AppSwitch.
class RemoteAwareSwitch extends ConsumerWidget {
  const RemoteAwareSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// The current value of the switch
  final bool value;

  /// Callback when switch is toggled (disabled in remote mode)
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

### Step 4: Run test to verify it passes

Run: `flutter test test/page/components/views/remote_aware_switch_test.dart`

Expected: PASS - 1 test passing

### Step 5: Commit

```bash
git add lib/page/components/views/remote_aware_switch.dart test/page/components/views/remote_aware_switch_test.dart
git commit -m "feat(remote-access): add RemoteAwareSwitch component with local mode test

Add wrapper component for AppSwitch that auto-disables in remote mode.
Initial test verifies switch is enabled in local mode.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Add RemoteAwareSwitch Disabled State Test

**Files:**
- Modify: `test/page/components/views/remote_aware_switch_test.dart`

### Step 1: Write failing test for disabled state in remote mode

Add test to existing test file:

```dart
testWidgets('is disabled in remote mode', (WidgetTester tester) async {
  bool? callbackValue;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => TestAuthNotifier(
              const AsyncValue.data(
                AuthState(loginType: LoginType.remote),
              ),
            )),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: RemoteAwareSwitch(
            value: false,
            onChanged: (value) {
              callbackValue = value;
            },
          ),
        ),
      ),
    ),
  );

  // Find the switch
  final switchFinder = find.byType(AppSwitch);
  expect(switchFinder, findsOneWidget);

  // Get the switch widget
  final appSwitch = tester.widget<AppSwitch>(switchFinder);

  // Verify onChanged is null (disabled)
  expect(appSwitch.onChanged, isNull);
});
```

### Step 2: Run test to verify it passes

Run: `flutter test test/page/components/views/remote_aware_switch_test.dart`

Expected: PASS - 2 tests passing (implementation already handles this)

### Step 3: Commit

```bash
git add test/page/components/views/remote_aware_switch_test.dart
git commit -m "test(remote-access): add RemoteAwareSwitch disabled state test

Verify switch is disabled (onChanged = null) in remote mode.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Add RemoteAwareSwitch Value Display Test

**Files:**
- Modify: `test/page/components/views/remote_aware_switch_test.dart`

### Step 1: Write test for value display in remote mode

Add test to verify value still displays correctly when disabled:

```dart
testWidgets('displays correct value in remote mode', (WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => TestAuthNotifier(
              const AsyncValue.data(
                AuthState(loginType: LoginType.remote),
              ),
            )),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: RemoteAwareSwitch(
            value: true,
            onChanged: (value) {},
          ),
        ),
      ),
    ),
  );

  // Find the switch
  final switchFinder = find.byType(AppSwitch);
  expect(switchFinder, findsOneWidget);

  // Get the switch widget
  final appSwitch = tester.widget<AppSwitch>(switchFinder);

  // Verify value is preserved
  expect(appSwitch.value, true);

  // Verify it's disabled
  expect(appSwitch.onChanged, isNull);
});
```

### Step 2: Run test to verify it passes

Run: `flutter test test/page/components/views/remote_aware_switch_test.dart`

Expected: PASS - 3 tests passing

### Step 3: Commit

```bash
git add test/page/components/views/remote_aware_switch_test.dart
git commit -m "test(remote-access): verify RemoteAwareSwitch preserves value when disabled

Ensure switch value displays correctly even when disabled in remote mode.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Add RemoteAwareSwitch Reactive Update Test

**Files:**
- Modify: `test/page/components/views/remote_aware_switch_test.dart`

### Step 1: Write test for reactive loginType changes

Add test to verify switch updates when loginType changes:

```dart
testWidgets('updates state when loginType changes', (WidgetTester tester) async {
  // Create a notifier we can control
  final authNotifier = TestAuthNotifier(
    const AsyncValue.data(AuthState(loginType: LoginType.local)),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => authNotifier),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: RemoteAwareSwitch(
            value: false,
            onChanged: (value) {},
          ),
        ),
      ),
    ),
  );

  // Initially enabled (local mode)
  var appSwitch = tester.widget<AppSwitch>(find.byType(AppSwitch));
  expect(appSwitch.onChanged, isNotNull);

  // Change to remote mode
  authNotifier.state = const AsyncValue.data(
    AuthState(loginType: LoginType.remote),
  );
  await tester.pump();

  // Now should be disabled
  appSwitch = tester.widget<AppSwitch>(find.byType(AppSwitch));
  expect(appSwitch.onChanged, isNull);
});
```

### Step 2: Run test to verify it passes

Run: `flutter test test/page/components/views/remote_aware_switch_test.dart`

Expected: PASS - 4 tests passing

### Step 3: Commit

```bash
git add test/page/components/views/remote_aware_switch_test.dart
git commit -m "test(remote-access): verify RemoteAwareSwitch reacts to loginType changes

Ensure switch state updates reactively when loginType transitions between
local and remote modes.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Enhance UiKitBottomBarConfig with Remote Check

**Files:**
- Modify: `lib/page/components/ui_kit_page_view.dart:32-49` (UiKitBottomBarConfig class)

### Step 1: Add checkRemoteReadOnly parameter to UiKitBottomBarConfig

Modify the class definition:

```dart
/// Custom bottom bar configuration
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

### Step 2: Verify no syntax errors

Run: `flutter analyze lib/page/components/ui_kit_page_view.dart`

Expected: No issues found

### Step 3: Commit

```bash
git add lib/page/components/ui_kit_page_view.dart
git commit -m "feat(remote-access): add checkRemoteReadOnly param to UiKitBottomBarConfig

Add optional parameter to control whether Save button should be disabled
in remote mode. Defaults to true for automatic protection.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Implement Remote Check in _buildBottomBarConfig

**Files:**
- Modify: `lib/page/components/ui_kit_page_view.dart:485-508` (_buildBottomBarConfig method)
- Add import: `lib/providers/remote_access/remote_access_provider.dart`

### Step 1: Add import for remoteAccessProvider

Add import at top of file:

```dart
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
```

### Step 2: Modify _buildBottomBarConfig to check remote mode

Locate the `_buildBottomBarConfig()` method around line 485 and modify it:

```dart
/// Native conversion of PrivacyGUI bottom bar parameters
PageBottomBarConfig? _buildBottomBarConfig() {
  if (widget.bottomBar == null) return null;

  final bottomBar = widget.bottomBar!;

  // Check remote read-only mode
  final isRemoteReadOnly = bottomBar.checkRemoteReadOnly
      ? ref.watch(remoteAccessProvider.select((state) => state.isRemoteReadOnly))
      : false;

  // T078: Native PrivacyGUI localization support
  // Note: PrivacyGUI localization will be added when needed

  return PageBottomBarConfig(
    positiveLabel: bottomBar.positiveLabel ?? loc(context).save,
    negativeLabel: bottomBar.negativeLabel,
    onPositiveTap: bottomBar.onPositiveTap,
    onNegativeTap: () {
      // Native navigation handling with context.pop integration
      bottomBar.onNegativeTap?.call();
      if (bottomBar.onNegativeTap == null) {
        context.pop(); // Default back navigation
      }
    },
    isPositiveEnabled: bottomBar.isPositiveEnabled && !isRemoteReadOnly,  // MODIFIED
    isNegativeEnabled: bottomBar.isNegativeEnabled,
    isDestructive: bottomBar.isDestructive,
  );
}
```

### Step 3: Verify no syntax errors

Run: `flutter analyze lib/page/components/ui_kit_page_view.dart`

Expected: No issues found

### Step 4: Run full test suite to check for regressions

Run: `./run_tests.sh`

Expected: All existing tests pass (no behavioral changes in local mode)

### Step 5: Commit

```bash
git add lib/page/components/ui_kit_page_view.dart
git commit -m "feat(remote-access): auto-disable Save button in remote mode

Modify _buildBottomBarConfig to check remoteAccessProvider and disable
positive button when isRemoteReadOnly is true. Respects checkRemoteReadOnly
flag for opt-out scenarios.

All form pages using UiKitBottomBarConfig now automatically protected.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Find and Catalog All AppSwitch Usages

**Files:**
- Create: `docs/plans/2026-01-26-switch-replacement-catalog.md`

### Step 1: Search for all AppSwitch usages

Run search command:

```bash
grep -r "AppSwitch(" lib/page --include="*.dart" -n > /tmp/switch_usages.txt
```

### Step 2: Review and categorize each usage

For each found usage, determine:
1. **File and line number**
2. **Switch purpose** (what does it control?)
3. **Operation mode**:
   - IMMEDIATE: onChanged directly calls provider that triggers JNAP
   - FORM: onChanged updates local state, page has Save button
   - UI_ONLY: Pure UI state (filters, display options)
4. **Action required**:
   - REPLACE: Change to RemoteAwareSwitch
   - NO_ACTION: Keep as AppSwitch (form mode or UI-only)

### Step 3: Create catalog document

Create structured catalog:

```markdown
# AppSwitch Replacement Catalog

Generated: 2026-01-26

## Summary
- Total AppSwitch usages: [COUNT]
- Requires replacement: [COUNT]
- Form mode (auto-protected): [COUNT]
- UI-only (no action): [COUNT]

## Immediate Mode Switches (Require RemoteAwareSwitch)

### 1. [File Path]:[Line]
**Purpose:** [What it controls]
**Trace:** onChanged → [provider.method] → [JNAP action]
**Action:** REPLACE with RemoteAwareSwitch

[Repeat for each immediate mode switch]

## Form Mode Switches (Auto-Protected)

### 1. [File Path]:[Line]
**Purpose:** [What it controls]
**Page:** Has UiKitBottomBarConfig with Save button
**Action:** NO_ACTION (auto-protected by Task 6)

[Repeat for each form mode switch]

## UI-Only Switches (No Action)

### 1. [File Path]:[Line]
**Purpose:** [What it controls]
**Reason:** Pure UI state (no JNAP operations)
**Action:** NO_ACTION

[Repeat for each UI-only switch]
```

### Step 4: Manual review of each switch

Go through each found usage:
1. Read the onChanged callback
2. Trace the method call chain
3. Determine if it triggers JNAP operation
4. Categorize accordingly

### Step 5: Save catalog

Save the completed catalog to `docs/plans/2026-01-26-switch-replacement-catalog.md`

### Step 6: Commit catalog

```bash
git add docs/plans/2026-01-26-switch-replacement-catalog.md
git commit -m "docs(remote-access): catalog all AppSwitch usages for replacement

Comprehensive review of all AppSwitch usages categorized by operation mode.
Identifies which switches require replacement with RemoteAwareSwitch.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 8: Replace Immediate Mode Switches (Batch 1)

**Files:**
- [To be determined based on Task 7 catalog]
- Example structure assuming 3-5 switches per batch

### Step 1: Select first batch from catalog

Choose 3-5 immediate mode switches from catalog for first batch.

### Step 2: Replace AppSwitch with RemoteAwareSwitch

For each file:
1. Add import: `import 'package:privacy_gui/page/components/views/remote_aware_switch.dart';`
2. Replace `AppSwitch(` with `RemoteAwareSwitch(`
3. Verify all parameters remain the same

Example replacement:

```dart
// Before
AppSwitch(
  value: isFeatureEnabled,
  onChanged: (value) => _notifier.toggleFeature(value),
)

// After
RemoteAwareSwitch(
  value: isFeatureEnabled,
  onChanged: (value) => _notifier.toggleFeature(value),
)
```

### Step 3: Test each modified page

For each modified file:
1. Run specific page tests if they exist
2. Manually test in local mode (switch should work)
3. Test with `BuildConfig.forceCommandType = ForceCommand.remote` (switch should be disabled)

### Step 4: Commit batch

```bash
git add [modified files]
git commit -m "feat(remote-access): replace AppSwitch with RemoteAwareSwitch in [pages]

Replace immediate-mode switches in:
- [Page 1]: [Switch purpose]
- [Page 2]: [Switch purpose]
- [Page 3]: [Switch purpose]

These switches directly trigger JNAP operations and must be disabled
in remote mode.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Replace Immediate Mode Switches (Remaining Batches)

**Repeat Task 8 structure for remaining switches**

Process all remaining immediate-mode switches identified in catalog, working in batches of 3-5 switches per commit.

Each batch follows same pattern:
1. Select switches from catalog
2. Replace AppSwitch with RemoteAwareSwitch
3. Test each modification
4. Commit batch

Continue until all immediate-mode switches from catalog are replaced.

---

## Task 10: Integration Testing

**Files:**
- Create: `test/integration/remote_read_only_ui_test.dart`

### Step 1: Write integration test for dashboard switches

Create comprehensive integration test:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';
// Import other necessary files

void main() {
  group('Remote Read-Only Mode UI Integration', () {
    testWidgets('all immediate switches disabled in remote mode', (tester) async {
      // Setup: Create app with remote login
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => TestAuthNotifier(
              const AsyncValue.data(AuthState(loginType: LoginType.remote)),
            )),
          ],
          child: MyApp(),
        ),
      );

      // Navigate to dashboard or page with switches
      // Verify banner is visible
      expect(find.text('Remote View Mode - Setting changes are disabled'), findsOneWidget);

      // Find all RemoteAwareSwitch instances
      final switches = find.byType(RemoteAwareSwitch);

      // Verify each switch is disabled
      for (final switchFinder in switches.evaluate()) {
        final switch = tester.widget<RemoteAwareSwitch>(find.byWidget(switchFinder.widget));
        expect(switch.onChanged, isNull);
      }
    });

    testWidgets('form Save buttons disabled in remote mode', (tester) async {
      // Setup: Navigate to a form page (e.g., Instant-Safety)
      // Verify Save button is disabled
      // Verify form fields can still be modified (local state)
    });
  });
}
```

### Step 2: Run integration test

Run: `flutter test test/integration/remote_read_only_ui_test.dart`

Expected: PASS

### Step 3: Commit

```bash
git add test/integration/remote_read_only_ui_test.dart
git commit -m "test(remote-access): add integration tests for UI controls protection

Comprehensive tests verifying:
- All RemoteAwareSwitch instances disabled in remote mode
- Form Save buttons disabled via UiKitBottomBarConfig
- Banner visible and controls disabled together

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 11: Update Usage Documentation

**Files:**
- Modify: `docs/plans/2026-01-20-remote-read-only-mode-usage.md`

### Step 1: Add RemoteAwareSwitch usage examples

Add new section to usage guide:

```markdown
## Using RemoteAwareSwitch

For switches that directly trigger JNAP operations (immediate effect):

### Basic Usage

```dart
import 'package:privacy_gui/page/components/views/remote_aware_switch.dart';

RemoteAwareSwitch(
  value: isFeatureEnabled,
  onChanged: (value) {
    ref.read(myProvider.notifier).toggleFeature(value);
  },
)
```

### When to Use RemoteAwareSwitch

Use RemoteAwareSwitch when:
- ✅ Switch onChanged directly calls a provider method
- ✅ That provider method triggers JNAP SET operations
- ✅ Changes apply immediately (no Save button)

Do NOT use RemoteAwareSwitch when:
- ❌ Page has a Save button (use regular AppSwitch - auto-protected)
- ❌ Switch only modifies local UI state
- ❌ Switch controls pure frontend behavior

### Form Pages with Save Buttons

No changes needed! All pages using `UiKitBottomBarConfig` automatically
have their Save buttons disabled in remote mode.

```dart
// This is automatically protected - no changes needed
bottomBar: UiKitBottomBarConfig(
  isPositiveEnabled: state.isDirty,  // Auto-disabled in remote mode
  onPositiveTap: _saveSettings,
),
```

### Opt-Out (Rare Cases)

If you have a Save button that shouldn't be disabled in remote mode:

```dart
bottomBar: UiKitBottomBarConfig(
  checkRemoteReadOnly: false,  // Opt out of auto-disable
  isPositiveEnabled: state.isDirty,
  onPositiveTap: _saveUIPreferences,  // Non-JNAP operation
),
```
```

### Step 2: Commit documentation update

```bash
git add docs/plans/2026-01-20-remote-read-only-mode-usage.md
git commit -m "docs(remote-access): add RemoteAwareSwitch usage guide

Document when and how to use RemoteAwareSwitch for immediate-effect
switches. Clarify that form pages are auto-protected.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 12: Run Full Test Suite and Verify

**Files:**
- None (verification task)

### Step 1: Run complete test suite

Run: `./run_tests.sh`

Expected: All 2752+ tests pass

### Step 2: Run specific remote-access tests

Run: `flutter test test/providers/remote_access/ test/page/components/views/remote_aware_switch_test.dart test/core/jnap/router_repository_test.dart`

Expected: All remote-access related tests pass

### Step 3: Manual testing with force remote mode

1. Modify main.dart temporarily:
```dart
void main() {
  BuildConfig.forceCommandType = ForceCommand.remote;  // Force remote mode
  runApp(MyApp());
}
```

2. Run app: `flutter run`
3. Verify:
   - Banner appears at top
   - All RemoteAwareSwitch instances are grayed out/disabled
   - Form Save buttons are disabled
   - Pure UI controls still work

4. Revert main.dart changes

### Step 4: Document verification results

Create verification report (optional):

```markdown
# Remote UI Controls - Verification Report

Date: 2026-01-26

## Test Results
- Unit tests: ✅ PASS (X tests)
- Integration tests: ✅ PASS (Y tests)
- Full test suite: ✅ PASS (2752+ tests)

## Manual Testing
- ✅ Banner displays in remote mode
- ✅ RemoteAwareSwitch instances disabled
- ✅ Form Save buttons disabled
- ✅ Local mode unchanged
- ✅ Pure UI controls functional

## Coverage
- RemoteAwareSwitch: X usages replaced
- Form pages auto-protected: Y pages
- No regressions detected
```

### Step 5: Final commit (if verification doc created)

```bash
git add docs/verification/2026-01-26-remote-ui-controls-verification.md
git commit -m "docs(remote-access): add verification report for UI controls protection

Document test results and manual verification of remote read-only mode
UI controls protection implementation.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Success Criteria

Implementation is complete when:

1. ✅ RemoteAwareSwitch component created and tested
2. ✅ UiKitBottomBarConfig enhanced with checkRemoteReadOnly
3. ✅ All immediate-mode switches cataloged
4. ✅ All immediate-mode switches replaced with RemoteAwareSwitch
5. ✅ Integration tests pass
6. ✅ Full test suite passes (no regressions)
7. ✅ Manual testing confirms expected behavior
8. ✅ Documentation updated

## Notes

- **Critical**: Task 7 (cataloging) must be thorough - trace every onChanged callback
- **Testing**: Use `BuildConfig.forceCommandType = ForceCommand.remote` for manual testing
- **Commits**: Frequent small commits per task for easy rollback
- **Reviews**: Each batch of switch replacements should be reviewed before proceeding
- **Defense-in-depth**: RouterRepository provides backup protection if any switches missed

## Estimated Effort

- Tasks 1-6: Core components (~2-3 hours)
- Task 7: Cataloging switches (~1-2 hours)
- Tasks 8-9: Replacing switches (~2-4 hours, depends on count)
- Tasks 10-12: Testing and docs (~1-2 hours)

**Total**: ~6-11 hours depending on number of switches requiring replacement
