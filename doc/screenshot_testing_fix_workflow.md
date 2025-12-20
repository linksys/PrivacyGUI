# Screenshot Testing Fix Workflow

## Overview

This document defines the workflow for fixing screenshot tests after UI Kit migration. The goal is to ensure all tests pass successfully.

---

## Quick Summary

1. Run screenshot test (use `-s "480"` during development)
2. If test fails → Analyze error → Fix → Retest
3. Repeat until test passes on 480w
4. ⚠️ **CRITICAL**: Verify with `-s "480,1280"` (both screen sizes)
5. Record results in `MIGRATION_TEST_RESULTS.md` with screen size coverage note
6. Update checklist and move to next test

---

## Detailed Workflow

### Phase 1: Execute Test

#### Development/Debugging Phase
```bash
# Use 480w only for faster iteration during development and debugging
sh ./run_generate_loc_snapshots.sh -c true -f test/page/{feature}/localizations/{view}_test.dart -l "en" -s "480"
```

#### Final Verification Phase
```bash
# ⚠️ REQUIRED: Test with BOTH screen sizes before marking test as complete
sh ./run_generate_loc_snapshots.sh -c true -f test/page/{feature}/localizations/{view}_test.dart -l "en" -s "480,1280"
```

**Important Notes**:
- **Development**: Use `-s "480"` for faster iteration during development
- **Final Sign-off**: Must verify with `-s "480,1280"` (mobile & desktop) before recording results
- Tests are executed for each screen size variant (e.g., 7 tests × 2 sizes = 14 total test executions)

---

### Phase 2: Analyze Test Result

#### ✅ **Test PASSED**
- No action needed for test itself
- Record results in `doc/MIGRATION_TEST_RESULTS.md` (see [Phase 6](#phase-6-record-results))
- Move to next test

#### ❌ **Test FAILED**
Categorize the error type:

| Error Type | Description | Action |
|------------|-------------|--------|
| **Widget Assertion Failed** | `expect(find.byType(Widget))` fails | [Fix Test Assertions](#fix-1-widget-assertion-failed) |
| **Widget Not Found** | `findsOneWidget` but actually finds 0 or more | [Fix Test Assertions](#fix-1-widget-assertion-failed) |
| **Runtime Error** | Exception during test execution | [Fix Runtime Issues](#fix-2-runtime-error) |
| **Timeout / Hang** | Test doesn't complete | [Fix Timeout Issues](#fix-3-timeout--hang) |
| **Overflow Warning** | `RenderFlex overflowed by X pixels` | [Assess and Handle Overflow](#fix-4-overflow-warning) |

---

### Phase 3: Fix Issues

#### Fix 1: Widget Assertion Failed

**Common Cause**: Test expects `privacygui_widgets` components but code now uses `ui_kit_library`.

**Steps**:

1. **Read Implementation File**
   ```bash
   # Open the actual implementation
   code lib/page/{feature}/{view}.dart
   ```

2. **Identify Widget Types**
   - Check what widgets are actually used
   - Note any keys assigned to widgets

3. **Update Test Assertions**
   ```dart
   // OLD - privacygui_widgets
   expect(find.byType(CustomButton), findsOneWidget);
   expect(find.byType(LoadingSpinner), findsOneWidget);

   // NEW - ui_kit_library
   expect(find.byType(AppButton), findsOneWidget);
   expect(find.byType(AppLoader), findsOneWidget);
   ```

4. **Update Imports**
   ```dart
   // OLD
   import 'package:privacygui_widgets/widgets.dart';

   // NEW
   import 'package:ui_kit_library/ui_kit.dart';
   ```

**Common Widget Mappings**:
| Old (privacygui_widgets) | New (ui_kit_library) |
|-------------------------|----------------------|
| `CustomButton` | `AppButton` |
| `LoadingSpinner` | `AppLoader` |
| `CustomTextField` | `AppTextField` |
| `CustomExpansionCard` | `AppExpansionPanel` |
| `CustomText` | `AppText` |

#### Fix 1.5: Widget Not Found - Add Key to Implementation (Preferred)

**When to use**: Test fails with `findsOneWidget` expecting 1 but finds 0, especially for:
- Images/SVGs in dialogs (semanticsLabel may not work)
- Dynamically created widgets
- Widgets inside complex widget trees

**Strategy**: Add `Key` to the implementation file first, then update the test to use `find.byKey()`.

**Steps**:

1. **Open Implementation File**
   ```bash
   code lib/page/{feature}/{view}.dart
   ```

2. **Add Key to Target Widget**
   ```dart
   // Before - no key
   Container(
     child: Assets.images.myImage.svg(),
   )

   // After - with unique key
   Container(
     key: const Key('myFeature_myImage'),
     child: Assets.images.myImage.svg(),
   )
   ```

3. **Update Test to Use Key Finder**
   ```dart
   // Before - may fail with semanticsLabel
   expect(find.bySemanticsLabel('my image'), findsOneWidget);

   // After - reliable key finder
   expect(find.byKey(const Key('myFeature_myImage')), findsOneWidget);
   ```

**Key Naming Convention**:
- Use `camelCase` format
- Prefix with feature/view name for uniqueness
- Examples: `pnpModemLightsOffTipStep3`, `dashboardMenuIcon`, `loginPasswordField`

**Benefits**:
- More reliable than semanticsLabel in complex widget trees
- Works in dialogs, overlays, and modal contexts
- Provides stable testing anchors for UI automation

#### Fix 2: Runtime Error

**Common Causes**:

**A. MissingPluginException (e.g., package_info)**

```dart
// Error: MissingPluginException: No implementation found for method getAll on channel dev.fluttercommunity.plus/package_info
```

**Solution**: Mock the plugin in test setup (if needed in future, currently skip these tests)

**B. Missing Mock Provider**

```dart
// Error: Provider not found
```

**Solution**: Ensure all required providers are mocked in `TestHelper.setup()`

**C. Async Operation Not Completed**

```dart
// Error: Test timeout or assertion before data loads
```

**Solution**: Add appropriate `await tester.pump()` or `await tester.pumpAndSettle()`

#### Fix 3: Timeout / Hang

**Cause**: Usually infinite animations or uncompleted async operations

**Check**:
1. Animations should be disabled by default (verify `testHelper.disableAnimations = true`)
2. All async operations use `await`
3. No infinite loops in test logic

**Solution**:
```dart
// Ensure animations are disabled
setUp(() {
  testHelper.setup();
  // testHelper.disableAnimations is already true by default
});

// Ensure async operations complete
await tester.pumpAndSettle();  // Completes immediately with animations disabled
```

#### Fix 4: Overflow Warning - Test Height Adjustment

**Example**:
```
A RenderFlex overflowed by 42 pixels on the bottom.
```

**Solution 1: Increase Test Viewport Height (Recommended)**

If content legitimately needs more height (e.g., topology views, long forms), adjust the test screen dimensions instead of modifying the implementation:

```dart
// Example from instant_topology_view_test.dart
final _desktopTallScreens = responsiveDesktopScreens
    .map((screen) => screen.copyWith(height: 1600))  // Increased from default 720px
    .toList();

final _topologyScreens = [
  ...responsiveMobileScreens.map((screen) => screen.copyWith(height: 1280)),  // Taller mobile
  ..._desktopTallScreens,
];

// Use in testLocalizations:
testLocalizations(
  'Test name',
  (tester, locale, config) async {
    // Test code
  },
  helper: testHelper,
  screens: _topologyScreens,  // Use custom tall screens
);
```

**When to use this approach**:
- Content naturally requires more vertical space (e.g., topology diagrams, long lists)
- Layout is correct but viewport is too short for testing
- Desktop users will have larger screens in production
- Mobile content legitimately needs scroll

**Solution 2: Assess Visual Impact (If height adjustment not appropriate)**

**Decision**: Check generated golden file to assess severity

1. **Check Golden File**
   ```bash
   # Golden files are in snapshots/ after test
   ls -la snapshots/

   # Open the golden file to visually inspect
   open snapshots/{TEST_ID}-01-{description}-Device480w-en.png
   ```

2. **Assess Severity**

   **🔴 CRITICAL - Must Fix Immediately**:
   - Content is completely invisible/cut off
   - Core UI elements (buttons, text) are not visible
   - Layout is completely broken
   - Yellow/black overflow indicator covers important content

   Example scenarios:
   ```
   ❌ Main action button is cut off and not visible
   ❌ Error message text is completely hidden
   ❌ Form fields are pushed off screen
   ❌ Navigation elements are not accessible
   ```

   **🟡 MODERATE - Should Fix (But Not Blocking)**:
   - Minor visual elements are cut off (margins, padding)
   - Secondary content slightly overflows
   - Overflow affects aesthetics but not functionality

   Example scenarios:
   ```
   ⚠️ Bottom padding is cut by 10px
   ⚠️ Decorative element slightly overflows
   ⚠️ Scroll indicator is partially hidden
   ```

   **🟢 MINOR - Record and Ignore**:
   - Tiny overflow (< 5px) due to rounding
   - Overflow in hidden/offscreen area
   - No visual impact on generated golden file

   Example scenarios:
   ```
   ✅ 2px overflow due to font rendering
   ✅ Overflow in offscreen scrollable area
   ✅ Sub-pixel rendering difference
   ```

3. **Action Based on Severity**

   **For CRITICAL (🔴)**:
   ```markdown
   ❌ MUST FIX - Test marked as FAILED

   Reason: [Describe what's broken]
   Action: Fix layout in implementation file
   ```

   **For MODERATE (🟡)**:
   ```markdown
   ⚠️ SHOULD FIX - Test marked as PASSED with warning

   Note: [Describe the visual issue]
   Action: Create issue/ticket for future fix
   ```

   **For MINOR (🟢)**:
   ```markdown
   ✅ PASSED - Overflow acceptable

   Note: Minor overflow (Xpx), no visual impact
   ```

4. **Fixing Critical Overflow**

   If overflow is CRITICAL, update implementation file:

   ```dart
   // Common causes and fixes:

   // Cause 1: Fixed height too small
   // Fix: Use flexible height or increase size
   Container(
     height: 600,  // Increase if content needs more space
     child: Column(/* ... */),
   )

   // Cause 2: Missing scrollable container
   // Fix: Wrap in SingleChildScrollView or ListView
   SingleChildScrollView(
     child: Column(/* ... */),
   )

   // Cause 3: Constraints too tight
   // Fix: Use Flexible or Expanded widgets
   Column(
     children: [
       Flexible(child: /* ... */),  // Instead of fixed size
     ],
   )
   ```

**Example Recording**:

```markdown
| File | Test | Result | Overflow | Severity | Notes |
|------|------|--------|----------|----------|-------|
| `login.dart` | `login_test.dart` | ❌ Failed | 200px | 🔴 Critical | Login button not visible, fixing layout |
| `dashboard.dart` | `dashboard_test.dart` | ⚠️ Passed | 42px | 🟡 Moderate | Bottom margin cut off, logged for future fix |
| `settings.dart` | `settings_test.dart` | ✅ Passed | 2px | 🟢 Minor | Font rendering, acceptable |
```

---

### Phase 4: Clarification Protocol

**When to Ask for Clarification**:
- ❓ Uncertain if a behavior change is correct
- ❓ Unable to determine the correct widget type
- ❓ Test logic is unclear and needs domain knowledge
- ❓ Unsure how to mock a specific scenario

**Clarification Format**:

```markdown
❓ Need Clarification

**File**: lib/page/{feature}/{view}.dart
**Test**: test/page/{feature}/localizations/{view}_test.dart
**Error Type**: [Widget Assertion / Runtime Error / Other]

**Issue**:
[Clear description of the problem]

**What I Found**:
[What you observed in the code/test]

**Question**:
[Specific question that needs answering]

**Current Assumption**:
[What you think might be the answer]

**Waiting for**: [Confirmation / Decision / Information]
```

**Important**:
- ❌ **Do NOT guess** when uncertain
- ✅ **Do ask** for clarification immediately
- ✅ **Be specific** about what you need to know

---

### Phase 5: Retest

After fixing:

```bash
# Development retest (480w only for quick feedback)
sh ./run_generate_loc_snapshots.sh -c true -f test/page/{feature}/localizations/{view}_test.dart -l "en" -s "480"

# ⚠️ FINAL VERIFICATION: Test with BOTH screen sizes
sh ./run_generate_loc_snapshots.sh -c true -f test/page/{feature}/localizations/{view}_test.dart -l "en" -s "480,1280"

# Check result
if [ $? -eq 0 ]; then
  echo "✅ Test PASSED on BOTH screen sizes - Update MIGRATION_TEST_RESULT.md"
else
  echo "❌ Test FAILED - Return to Phase 2"
fi
```

**Important**: Only proceed to Phase 6 (recording results) after verifying tests pass on **both 480w and 1280w** screen sizes.

---

### Phase 6: Record Results

After each test completion (pass or fail), document the results in `doc/MIGRATION_TEST_RESULTS.md`.

⚠️ **CRITICAL**: Only record results after verifying tests pass on **BOTH 480w and 1280w** screen sizes.

#### Recording Format

Add a new section for each completed test with the following information:

```markdown
### N. ✅/⚠️ Test Name (test_file_name.dart)

**Test File**: `test/path/to/test_file.dart`
**Implementation**: `lib/path/to/implementation.dart`
**Status**: ✅ PASSED / ⚠️ PASSED WITH WARNINGS / ❌ FAILED (X/Y)
**Date**: YYYY-MM-DD
**Test Coverage**: Both 480w (mobile) and 1280w (desktop) screen sizes

**Results**:
- Total Tests: X (including all screen size variants)
- Passed: Y
- Failed: Z

**Test Breakdown**:
- List individual test scenarios and their status
- Note: Each test runs on 2 screen sizes (480w, 1280w)

**Golden Files Generated**: N files
- List key golden files

**Issues Fixed** (if any):
- Describe fixes applied to test or implementation

**Notes**: Additional observations
```

#### Quick Recording Steps

1. **Verify both screen sizes tested**:
   - Confirm test output shows both `Device480w-en` and `Device1280w-en` variants
   - Example: `00:24 +14` means 14 total tests (7 unique tests × 2 screen sizes)

2. **Copy template** from existing entries in `MIGRATION_TEST_RESULTS.md`

3. **Fill in test statistics**:
   - Count from test output: `00:XX +Y -Z` (Y = passed, Z = failed)
   - Total includes all screen size variants
   - Calculate pass rate: `(Y / (Y + Z)) * 100%`

4. **Add screen size coverage note**:
   ```markdown
   **Test Coverage**: Both 480w (mobile) and 1280w (desktop) screen sizes
   ```

5. **Document failures**:
   - Copy error messages
   - Note error locations (file:line)
   - Assess severity

6. **Record fixes**:
   - Test file changes
   - Implementation file changes (if any)
   - Code snippets for significant changes

7. **List golden files**:
   - Count: `ls test/.../goldens/ | grep "TEST_PREFIX" | wc -l`
   - List key files for reference

8. **Update progress table** at top of document

9. **Update checklist** in "Remaining Test Files" section

#### Example Entry

See existing entries in `MIGRATION_TEST_RESULTS.md` for full examples:
- FAQ List View (100% pass, no issues)
- Dashboard Home View (79.4% pass, minor overflow)
- Dashboard Menu View (93.3% pass, icon change fix)
- PNP Admin View (85.7% pass, widget finder fix)

---

### Phase 7: Final Verification (Optional)

When test passes with basic parameters, optionally verify with full parameters:

```bash
# Test with multiple locales and screens
sh ./run_generate_loc_snapshots.sh -c true -f test/page/{feature}/localizations/{view}_test.dart -l "en,es,ja" -s "480,1280"
```

**Note**: This is optional and only needed for comprehensive verification.

---

## Common Patterns

### Pattern 1: Widget Type Update

```dart
// Before
expect(find.byType(CustomButton), findsOneWidget);

// After
expect(find.byType(AppButton), findsOneWidget);
```

### Pattern 2: Import Update

```dart
// Before
import 'package:privacygui_widgets/widgets.dart';

// After
import 'package:ui_kit_library/ui_kit.dart';
```

### Pattern 3: Widget Predicate Update

```dart
// Before
expect(
  find.byWidgetPredicate((widget) =>
    widget is CustomButton && widget.text == 'Login'
  ),
  findsOneWidget,
);

// After
expect(
  find.widgetWithText(AppButton, testHelper.loc(context).login),
  findsOneWidget,
);
```

---

## Pre-Test Checklist

Before running screenshot test:

```bash
# 1. Verify implementation file is migrated
grep -n "privacygui_widgets" lib/page/{feature}/{view}.dart
# Expected: No output (or only hide statements)

# 2. Static analysis
flutter analyze lib/page/{feature}/{view}.dart
# Expected: No errors (warnings are OK)

# 3. Verify test file exists
ls test/page/{feature}/localizations/{view}_test.dart
# Expected: File found
```

---

## Decision Tree

```
Run Test
  │
  ├─ PASS ✅
  │   └─ Record in MIGRATION_TEST_RESULTS.md → Done
  │
  └─ FAIL ❌
      │
      ├─ Widget Assertion Failed
      │   ├─ Can identify correct widget type?
      │   │   ├─ Yes → Update assertion → Retest
      │   │   └─ No → ❓ Ask for clarification
      │   │
      │   └─ Is widget type obvious from implementation?
      │       ├─ Yes → Update → Retest
      │       └─ No → ❓ Ask for clarification
      │
      ├─ Runtime Error
      │   ├─ MissingPluginException
      │   │   └─ Skip for now (known issue)
      │   │
      │   ├─ Missing Mock
      │   │   └─ Add mock to TestHelper → Retest
      │   │
      │   └─ Unknown error
      │       └─ ❓ Ask for clarification
      │
      ├─ Timeout
      │   ├─ Check animations disabled
      │   ├─ Check async operations
      │   └─ If still unclear → ❓ Ask for clarification
      │
      └─ Overflow Warning
          ├─ Check golden file
          ├─ Critical (content not visible) → ❌ Fix implementation → Retest
          ├─ Moderate (minor visual issue) → ⚠️ Log and accept
          └─ Minor (< 5px, no impact) → ✅ Ignore
```

---

## Success Criteria

A test is considered **completed** when:
- ✅ Test exits with code 0 (all assertions pass) OR has only minor/moderate issues
- ✅ No widget assertion failures (or all fixed)
- ✅ No runtime errors (except known issues like `MissingPluginException`)
- ✅ No **critical** overflow issues (content must be visible)
- ✅ Results recorded in `doc/MIGRATION_TEST_RESULTS.md`
- ✅ Progress table and checklist updated

**Note**:
- Minor overflow warnings (🟢) are acceptable and don't prevent completion
- Moderate overflow warnings (🟡) should be logged but don't block completion
- Critical overflow issues (🔴) must be fixed immediately
- Golden files are generated but not validated for visual comparison (only checked for severe layout issues)

---

## Example Session

```bash
# 1. Run test
$ sh ./run_generate_loc_snapshots.sh -c true -f test/page/login/localizations/login_local_view_test.dart -l "en" -s "480"

# Result: Failed - Widget not found

# 2. Read implementation
$ code lib/page/login/login_local_view.dart
# Found: Uses AppButton from ui_kit_library

# 3. Update test
$ code test/page/login/localizations/login_local_view_test.dart
# Changed: CustomButton → AppButton

# 4. Retest
$ sh ./run_generate_loc_snapshots.sh -c true -f test/page/login/localizations/login_local_view_test.dart -l "en" -s "480"

# Result: Passed ✅

# 5. Record results
$ code doc/MIGRATION_TEST_RESULTS.md
# Added new entry with test statistics, fixes, and golden files
# Updated progress table and checklist
```

---

## Related Documentation

- [screenshot_testing_knowledge_base.md](screenshot_testing_knowledge_base.md) - Complete testing reference
- [screenshot_testing_guideline.md](screenshot_testing_guideline.md) - Official guidelines
- [MIGRATION_TEST_RESULTS.md](MIGRATION_TEST_RESULTS.md) - Test results tracking and progress
- [SCREENSHOT_TEST_COVERAGE.md](SCREENSHOT_TEST_COVERAGE.md) - Coverage analysis and test file list

---

**Last Updated**: 2025-12-19
**Status**: Active workflow for UI Kit migration screenshot testing
