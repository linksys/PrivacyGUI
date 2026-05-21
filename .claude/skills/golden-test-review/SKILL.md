---
name: golden-test-review
description: Use when creating new golden tests for a USP page OR reviewing existing golden tests for completeness. Trigger when user mentions golden test, screenshot test, golden coverage, visual test, or asks to review/create localization tests for a page. Trigger keywords - golden test, screenshot test, golden, 截圖測試, 擷圖, golden coverage, review golden, add golden, 新增golden, 檢查golden, 漏擷圖.
---

# Golden Test Review & Creation

## Purpose

Ensure every USP page has complete golden test coverage per the project's golden test specification. The absolute rule:

> **只要畫面不同就要擷圖！！！！！！！ If the user sees something different, it needs a golden screenshot. NO EXCEPTIONS.**

This skill handles two modes:
1. **CREATE** — Write golden tests for a page that has none
2. **REVIEW** — Audit existing golden tests and identify missing coverage

## When to Use

- User asks to create golden tests for a new page
- User asks to review/audit existing golden test coverage
- User asks if all visual states are captured
- User mentions "漏了什麼" or "有沒有遺漏" regarding golden tests

## Step 0: Read the Spec (MANDATORY — BLOCKING PREREQUISITE)

**YOU MUST READ THE SPEC BEFORE DOING ANYTHING ELSE. No analysis, no suggestions, no code generation until the spec has been fully read. This is non-negotiable.**

Read these files IN ORDER before any other action:

1. **`doc/screenshot_test/golden_test_specification.md`** — The single source of truth. Read it EVERY TIME this skill is invoked, even if you think you remember it. The spec may have been updated. Do NOT rely on the summary in this skill file — the spec owns all decisions about coverage requirements, naming, structure, and patterns.
2. The target page's production code (`lib/page/{feature}/views/usp_*_view.dart` and all sub-components in `views/components/`, `views/dialogs/`)
3. The existing golden test file (if reviewing): `test/usp_test/page/{feature}/localizations/usp_*_view_test.dart`
4. The existing mock and fixture files:
   - `test/usp_test/golden_framework/mocks/mock_{feature}.dart`
   - `test/usp_test/page/{feature}/fixtures/{feature}_test_data.dart`

**If you skip reading the spec, your output WILL be wrong. The spec contains details not captured in this skill file.**

## Step 1: Analyze the View (Both Modes)

Read the view's `build()` method and all sub-components. Identify EVERY conditional branch that produces different visual output:

### Checklist — What Produces Different Screenshots

| Source | What to Look For | Example State Key |
|--------|-----------------|-------------------|
| `if/else` on data | Feature enabled/disabled | `enabled`, `disabled` |
| `switch` on enum | Connection modes | `dhcp`, `static_ip`, `pppoe` |
| Empty vs populated list | List/CRUD views | `rules_list`, `empty` |
| `isDirty` check | Edit mode indicator (save/revert buttons) | `edit_dirty` |
| Validation errors | Error messages/icons visible | `validation_error` |
| Tab views | Each tab shows different content | interaction: `tab_xxx` |
| Dialogs | Add/edit/delete confirmations | interaction: `dialog_add`, `dialog_edit`, `dialog_delete` |
| Tooltips/popovers | Error tooltips, info popovers | interaction: `validation_error_tooltip` |
| Loading/error | Shared — only if page has custom loading/error UI | (usually skipped — shared test covers) |

### For Each Tab in a Tabbed View

EVERY tab must have:
- Its default data view (via interaction to switch tabs)
- Its empty state (via interaction to switch tabs with empty data)
- Its add dialog (via interaction)
- Its edit dialog (via interaction)
- Its delete confirmation dialog (if applicable)
- Its validation errors (if the dialog has validation)

### For Dialogs

Identify every dialog the page can show:
- Add dialogs (one per tab/list)
- Edit dialogs (one per tab/list, pre-filled with data)
- Delete confirmation dialogs
- Validation error states within dialogs (all fields invalid simultaneously)

## Step 2: Build the Coverage Matrix

Create a table of ALL required screenshots:

```markdown
| # | Type | Key | Description | Status |
|---|------|-----|-------------|--------|
| 1 | state | `rules_list` | Default view with data | ... |
| 2 | state | `empty` | Empty list view | ... |
| 3 | state | `edit_dirty` | Dirty state with save/revert | ... |
| 4 | interaction | `tab_xxx` | Switch to XXX tab | ... |
| ... | ... | ... | ... | ... |
```

For REVIEW mode, mark each as:
- COVERED — existing test covers this
- MISSING — no test captures this visual state
- INCORRECT — test exists but implementation is wrong (e.g., dialog not actually showing)

## Step 3: Execution

### CREATE Mode

1. Create the mock file if it doesn't exist: `test/usp_test/golden_framework/mocks/mock_{feature}.dart`
2. Create the fixtures file if it doesn't exist: `test/usp_test/page/{feature}/fixtures/{feature}_test_data.dart`
3. Create the test file: `test/usp_test/page/{feature}/localizations/usp_{feature}_view_test.dart`
4. Write complete `GoldenTestConfig` covering ALL identified states and interactions

### REVIEW Mode

1. Compare the coverage matrix against the existing test file
2. Report all MISSING and INCORRECT cases
3. Propose specific code changes to fix gaps
4. Implement the fixes after user approval

## Technical Patterns (Learned from Experience)

### Button Finding in UI Kit

`AppIconButton` uses `AppInteractionSensor` with `GestureDetector(behavior: HitTestBehavior.opaque)`. Tapping the inner `Icon` widget does NOT propagate to the gesture handler.

```dart
// WRONG — won't trigger the button
await tester.tap(find.byIcon(Icons.add));

// CORRECT — tap the AppIconButton itself
final addBtn = find.descendant(
  of: find.byType(UspSinglePortTab),
  matching: find.byType(AppIconButton),
);
await tester.tap(addBtn.first);
```

### Tab Switching Requires Multiple Pumps

`TabBarView` animation needs time to complete before the new tab's buttons are in the widget tree:

```dart
// Switch tab
await tester.tap(find.textContaining('Port Range'));
await tester.pump();
// Wait for animation to complete
for (int i = 0; i < 10; i++) {
  await tester.pump(const Duration(milliseconds: 50));
}
// NOW the tab content is rendered and interactive
```

### Dialog Display: showAppDialog vs showDialog

UI Kit's `AppDialog` does NOT include a `Material` widget. The standard Flutter `showDialog` creates a new overlay route that loses the `Portal` ancestor from the golden runner's widget tree.

**Rule**: If the production code uses `showAppDialog`, the dialog will render correctly. If you see `showDialog` with an `AppDialog`-based dialog, it will crash with either:
- `No Material widget found` (from TextField/AppTextField)
- `PortalNotFoundError` (from AppSelectAutoComplete/overlay components)

The fix is to use `showAppDialog` in production code, which wraps with `Theme > Portal > Material(type: transparency)`.

### Identifying Buttons in Row-Based Lists

For lists where each row has edit/delete buttons plus a header add button:

```dart
// Button order in UspSinglePortTab:
// [0]=add(header), [1]=edit(row1), [2]=delete(row1), [3]=edit(row2), [4]=delete(row2)
final buttons = find.descendant(
  of: find.byType(UspSinglePortTab),
  matching: find.byType(AppIconButton),
);
await tester.tap(buttons.at(1)); // edit first row
await tester.tap(buttons.at(2)); // delete first row
```

### Validation in Dialogs

To trigger validation errors in a dialog:
1. Open the dialog (tap add button)
2. Find all `EditableText` widgets on screen
3. Enter invalid values into each field
4. Pump to let validation run

```dart
final allFields = find.byType(EditableText);
final count = allFields.evaluate().length;
if (count < expectedFieldCount) return;
final baseIndex = count - expectedFieldCount; // dialog fields are at the end

await tester.tap(allFields.at(baseIndex));
await tester.pump();
tester.testTextInput.enterText('invalid-value');
await tester.pump();
```

### Dialog After Tab Switch

When opening a dialog on a non-default tab, you need the full sequence:

```dart
// 1. Switch tab
await tester.tap(find.textContaining('Port Range'));
await tester.pump();
for (int i = 0; i < 10; i++) {
  await tester.pump(const Duration(milliseconds: 50));
}
// 2. Find button in the target tab
final addBtn = find.descendant(
  of: find.byType(UspPortRangeTab),
  matching: find.byType(AppIconButton),
);
// 3. Tap and wait for dialog
await tester.tap(addBtn.first);
await tester.pump();
for (int i = 0; i < 10; i++) {
  await tester.pump(const Duration(milliseconds: 50));
}
```

## State Key Naming Rules

From the spec — state keys must be **descriptive and self-explanatory**:

| Rule | Bad | Good |
|------|-----|------|
| No generic prefix | `data`, `data_all_off` | `all_on`, `all_off` |
| Describe visual state | `data_enabled` | `dhcp_enabled` |
| Use distinguishing characteristic | `data_1`, `data_2` | `idle`, `running` |

## Interaction Naming

Name by what becomes visible:

| Key Pattern | Purpose |
|------------|---------|
| `tab_{name}` | Switch to a different tab |
| `empty_{name}` | Tab/view in empty state (via tab switch) |
| `dialog_add_{type}` | Open add dialog |
| `dialog_edit_{type}` | Open edit dialog (pre-filled) |
| `dialog_delete` | Open delete confirmation |
| `dialog_validation_{type}` | Dialog with all validation errors shown |
| `validation_error_tooltip` | Tap error icons to show tooltips |

## Shared States (Do NOT Include)

These are tested once in `shared_states_test.dart` — DO NOT duplicate per feature:
- Saving spinner (`doSomethingWithSpinner`)
- Loading state (shared loading UI)
- Generic error state (shared error UI)

## Output Format

After analysis, present findings to the user as:

### For REVIEW Mode:

```
## Coverage Report: {feature_name}

### Summary
- Total required screenshots: X
- Currently covered: Y
- Missing: Z

### Missing Cases
| # | Type | Key | What's Not Captured |
|---|------|-----|---------------------|
| 1 | interaction | dialog_edit_xxx | Edit dialog for XXX tab |
| ... | ... | ... | ... |

### Proposed Changes
[specific code changes needed]
```

### For CREATE Mode:

```
## Golden Test Plan: {feature_name}

### Coverage Matrix
[full table of all states/interactions]

### Files to Create
1. Mock: test/usp_test/golden_framework/mocks/mock_{feature}.dart
2. Fixtures: test/usp_test/page/{feature}/fixtures/{feature}_test_data.dart
3. Test: test/usp_test/page/{feature}/localizations/usp_{feature}_view_test.dart

[proceed to implement after user approval]
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Only testing the default tab | EVERY tab needs its own screenshots |
| Testing empty state only for default tab | EVERY tab needs empty state if it has a list |
| Missing edit dialog (only testing add) | Edit dialogs show pre-filled data — different visual |
| Using `find.byIcon` for AppIconButton | Use `find.byType(AppIconButton)` with descendant scope |
| Single pump after tab switch | Need 10x50ms pumps for TabBarView animation |
| Not scoping button finder to specific tab | Use `find.descendant(of: find.byType(TabWidget), ...)` |
| Assuming validation exists without checking | Read the dialog source — some dialogs have no validation |
| Adding saving_spinner per feature | This is shared — test once in shared_states_test.dart |
