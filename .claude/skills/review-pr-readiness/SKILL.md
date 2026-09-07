---
name: review-pr-readiness
description: Review current branch changes for PR readiness. Checks code quality (dart format, flutter analyze), UI Kit library usage in Views, runs affected tests, and verifies test coverage. Use before creating a Pull Request. Trigger keywords (English) - review pr, check pr, pr ready, pre-pr check, review before pr. Trigger keywords (Chinese) - 檢查 PR, PR 檢查, 準備 PR, PR 審查, 發 PR 前檢查.
---

# Pre-PR Readiness Review

## Purpose

Perform a comprehensive review of all branch changes before creating a Pull Request. This skill checks code quality, UI Kit library compliance, and test coverage to catch issues before they reach code review.

## When to Use This Skill

- Before creating a Pull Request
- When the user says: "review pr", "check pr", "pr ready", "準備 PR", "檢查 PR", "發 PR 前檢查"
- When the user is about to run `gh pr create`

## When NOT to Use This Skill

- Documentation-only branches (only `.md` files changed)
- Branches with no `.dart` file changes

## Execution Workflow

### Phase 0: Determine Scope

**Step 0.1: Identify Base Branch and Changed Files**

```bash
# Detect base branch (main or dev-*)
git merge-base --fork-point main HEAD 2>/dev/null || git merge-base main HEAD

# Get all changed Dart files compared to base branch
git diff --name-only <base>...HEAD -- '*.dart'
```

**Step 0.2: Filter and Categorize Files**

- If NO `.dart` files changed, report "No Dart files changed — skipping review" and **STOP**
- Categorize changed files (use recursive `**` globs to match nested features):
  - `lib/page/**/views/**/*.dart` → View files
  - `lib/page/**/providers/**/*.dart` → Provider files
  - `lib/page/**/services/**/*.dart` → Service files
  - `lib/page/**/models/**/*.dart` → Model files
  - `test/**/*.dart` → Test files
  - Other `lib/**/*.dart` → Other source files

### Phase 1: Code Quality

**Step 1.1: Check Formatting**

Run `dart format` in dry-run mode on ALL changed `.dart` files. Use `fvm dart format` to ensure the correct SDK version is used:

```bash
fvm dart format --set-exit-if-changed --output=none <changed_dart_files>
```

If `fvm` is not available, fall back to `dart format`.

- If exit code is non-zero, list the unformatted files
- Severity: **ERROR**
- Suggestion: "Run `fvm dart format <file>` to fix"

**Step 1.2: Run Static Analysis**

```bash
flutter analyze
```

- Filter results to only show issues in the changed files
- Severity: **ERROR** for errors, **WARNING** for warnings, **INFO** for info
- Suggestion: Quote the specific lint rule and how to fix

**Step 1.3: Check Imports**

From `flutter analyze` output, specifically highlight:
- `unused_import` warnings
- Unsorted imports (if detected)

Severity: **WARNING**

### Phase 2: UI Kit Usage (Only If View Files Changed)

**Step 2.1: Scan for Non-UI-Kit Widget Usage**

For each changed View file, check for direct usage of Flutter Material/Cupertino widgets that have UI Kit equivalents:

```
# Pattern → UI Kit Equivalent
ElevatedButton / TextButton / OutlinedButton  → AppButton
Text(                                          → AppText
TextField / TextFormField                      → AppTextFormField
Checkbox(                                      → AppCheckbox
Switch(                                        → AppSwitch
AlertDialog / SimpleDialog                     → showSimpleAppDialog
CircularProgressIndicator                      → AppLoader (inline) or AppSpinnerDialog (modal)
Card(                                          → AppCard
SizedBox(height: / SizedBox(width:            → AppGap / AppSpacing
```

For each detection:
- Severity: **WARNING**
- Suggestion: "Consider using `<UIKit equivalent>` from ui_kit_library instead of `<Material widget>`"

**Step 2.2: Verify UI Kit Import**

For each changed View file that renders UI, verify it imports:
```dart
import 'package:ui_kit_library/ui_kit.dart';
```

If not found:
- Severity: **INFO**
- Suggestion: "Add `import 'package:ui_kit_library/ui_kit.dart';`"

### Phase 3: Constitution Compliance

Checks implementation against architecture rules defined in `constitution.md`.

**Step 3.1: Test Framework Compliance (Article I §1.6.1)**

For each **new** test file in the branch (files that don't exist in base branch):

```bash
# Check for mockito usage in new test files
grep -l "import 'package:mockito" <new_test_files>
grep -l "@GenerateMocks" <new_test_files>
```

- If mockito imports or `@GenerateMocks` found in NEW test files:
- Severity: **WARNING**
- Suggestion: "New tests should use `mocktail` instead of `mockito` (constitution Article I §1.6.1). Mockito is only allowed in existing legacy tests."

**Step 3.2: Architecture Compliance — No Codegen in Providers/Views (Article V §5.4.3)**

For each changed provider file (`lib/page/**/providers/**/*.dart`) and view file (`lib/page/**/views/**/*.dart`):

```bash
# Check for direct generated/ imports (prohibited)
grep -E "import.*'package:privacy_gui/generated/" <provider_and_view_files>
```

- If `generated/` imports found:
- Severity: **ERROR**
- Suggestion: "Direct imports from `lib/generated/` are prohibited in providers and views (constitution Article V §5.4.3). Move codegen calls to the Service layer."

**Step 3.3: Service Layer Pattern (Article VI)**

For each changed provider file, check if it calls codegen methods directly:

```bash
# Check for direct .fetch(), .save(), .add(), .delete() calls on generated classes
grep -E "\.(fetch|save|add|delete)\(.*UspClient" <provider_files>
```

- If direct codegen method calls found in providers:
- Severity: **WARNING**
- Suggestion: "USP operations should go through the Service layer, not called directly from providers (constitution Article VI)."

**Step 3.4: Error Handling Compliance (Article XIII)**

For each changed service file (`lib/page/**/services/**/*.dart`):

```bash
# Check for raw USP exceptions not mapped to ServiceError
grep -E "throw UspException|rethrow" <service_files>
```

- If raw USP exceptions are thrown without mapping:
- Severity: **INFO**
- Suggestion: "USP errors should be mapped to `ServiceError` using `mapUspErrorToServiceError()` (constitution Article XIII)."

**Step 3.5: Naming Conventions (Article III)**

For each **new** file in the branch:

```bash
# Check provider file naming (recursive to match nested features)
# Files in lib/page/**/providers/ should end with _provider.dart or _notifier.dart
find lib/page -path '*/providers/*.dart' | grep -v -E "(_provider|_notifier)\.dart$"

# Check service file naming (recursive to match nested features)
# Files in lib/page/**/services/ should end with _service.dart
find lib/page -path '*/services/*.dart' | grep -v -E "_service\.dart$"
```

- If provider files don't follow `*_provider.dart` or `*_notifier.dart` naming:
- Severity: **WARNING**
- Suggestion: "Provider files should be named `*_provider.dart` or `*_notifier.dart` (constitution Article III)."

- If service files don't follow `*_service.dart` naming:
- Severity: **WARNING**
- Suggestion: "Service files should be named `*_service.dart` (constitution Article III)."

**Step 3.6: Provider Architecture — AutoDispose (Article IV)**

For each changed provider file (`lib/page/*/providers/*.dart`):

```bash
# Check if file contains L1 indicators (session cache) with autoDispose (prohibited)
# L1 indicators: "DataProvider", "CacheProvider", comments mentioning "L1" or "session cache"
grep -l "autoDispose" <provider_files> | xargs --no-run-if-empty grep -l -E "(DataProvider|CacheProvider|// ?L1|session.?cache)"

# Check if file contains L2 indicators (working copy) without autoDispose (should have it)
# L2 indicators: "NotifierProvider", "StateProvider", comments mentioning "L2" or "working copy"
grep -L "autoDispose" <provider_files> | xargs --no-run-if-empty grep -l -E "(NotifierProvider|// ?L2|working.?copy)"
```

- If L1 (session cache) provider has `autoDispose`:
- Severity: **WARNING**
- Suggestion: "L1 session-cache providers should NOT use `autoDispose` — they persist across page navigation (constitution Article IV)."

- If L2 (working copy) provider lacks `autoDispose`:
- Severity: **INFO**
- Suggestion: "L2 working-copy providers should typically use `autoDispose` to clean up on page exit (constitution Article IV)."

**Step 3.7: Test Data Location (Article I §1.6.2)**

For each **new** test file, check if it defines test data inline:

```bash
# Check for inline test data factories (should be in test/mocks/test_data/)
grep -l -E "class.*TestData|Factory\(\)|\.fromJson\(\{" <new_test_files>
```

- If new test files define substantial test data inline (more than simple literals):
- Severity: **INFO**
- Suggestion: "Consider moving reusable test data to `test/mocks/test_data/[feature]_test_data.dart` (constitution Article I §1.6.2)."

**Step 3.8: E2E Test Hook Compliance (Article XVI)**

Applies to changed View/component files (`lib/**/*.dart` that render UI). Only run if such files changed. These checks are **heuristic** — a static grep cannot prove two attributes sit on the *same* widget, so report candidates and instruct the reviewer to confirm by reading the widget. Never emit ERROR from this step.

**3.8.1 — `semanticLabel` test-slug where the host forwards `identifier` (Rule 16.1.1)**

A kebab-case slug in `semanticLabel:` is a test hook in the wrong place when the host widget forwards `identifier`. It is announced aloud by screen readers (real a11y defect) and should be `identifier:`.

```bash
# Kebab-slug semanticLabel usages in changed files (candidates)
grep -rnE "semanticLabel: *'[a-z][a-z0-9-]*'" <changed_view_files>
```

For each hit, read the host widget and classify:
- Host **forwards `identifier`** (AppButton, AppIconButton, AppTextField, AppSwitch, AppListTile, AppCheckbox, AppRadio, raw `Semantics`, …): **WARNING** — "Move test slug from `semanticLabel:` to `identifier:` (Article XVI Rule 16.1.1). `semanticLabel` is announced by screen readers; use it only for genuine localized a11y text."
- Host **exposes only `semanticLabel`** (e.g. `AppMenuCard` / `AppSectionItemData`): **INFO** — "Tolerated interim hook (Rule 16.1.2); tech debt pending `identifier` passthrough in ui_kit. Do not fix in `lib/`."

To tell them apart, grep the host widget's ui_kit source (or `lib/` for app-defined widgets) for `identifier`:
```bash
grep -rl "final String? identifier" ../../ui_kit/lib/src <app_widget_dirs>
```

**3.8.2 — Both `identifier` and a test-slug `semanticLabel` on one widget (Rule 16.1.1)**

```bash
# Files carrying BOTH — inspect whether they land on the same widget
for f in <changed_view_files>; do
  grep -qE "identifier: *'[a-z]" "$f" && grep -qE "semanticLabel: *'[a-z][a-z0-9-]*'" "$f" && echo "$f"
done
```

- For each flagged file, read the widgets: if one widget has both, **WARNING** — "Remove the redundant test-slug `semanticLabel`; the `identifier` is the anchor (Article XVI Rule 16.1.1)."

**3.8.3 — Raw `Semantics(label:)` test slug (Rule 16.3)**

A bare `label:` on a raw `Semantics` is announced aloud AND invisible to the E2E generator (which matches the attribute name `semanticLabel`, not `label`).

```bash
# label: directly under Semantics( — slug is literal or interpolated
grep -rnE -A1 "Semantics\(" <changed_view_files> | grep -E "label: *'[a-z]"
```

- For each hit: **WARNING** — "Use `Semantics(identifier: '…')` not `label:` — a bare `label` is read by screen readers and is not picked up by `gen-identifiers.mts` (Article XVI §16.3)."

**3.8.4 — Row-index-based identifier (Rule 16.3)**

Per-instance identifiers must derive from data, not list position.

```bash
# Interpolated index or trailing numeric literal in an identifier
grep -rnE "identifier: *'[^']*-[0-9]+'" <changed_view_files>
grep -rnE "identifier: *[\"'][^\"']*\\\$\{?(index|i|idx)\}?" <changed_view_files>
```

- For each hit: **WARNING** — "Per-instance identifiers must embed a data-derived key (a slug helper), not a row index like `pf-edit-0` (Article XVI §16.3). A row-index identifier is a positional selector in disguise."

**Note on the SSOT contract (Article XVI §16.4)**: if this branch renames an identifier value OR migrates a hook `semanticLabel:` → `identifier:` (even with an unchanged slug), remind the user: the E2E selector map is derived from app source — regenerate it (`npm run gen:ids` in the e2e repo) and migrate any spec that located the control by its old mechanism (`getByRole({name})` → `byIdentifier()`). This is a cross-repo contract change, not an app-only edit.

### Phase 4: Test Coverage

**Step 4.1: Check Test File Existence**

For each changed source file in `lib/`, check if a corresponding test file exists:

| Source File Pattern | Expected Test File Pattern |
|---|---|
| `lib/page/[feature]/providers/[name].dart` | `test/page/[feature]/providers/[name]_test.dart` |
| `lib/page/[feature]/services/[name].dart` | `test/page/[feature]/services/[name]_test.dart` |
| `lib/page/[feature]/models/[name].dart` | `test/page/[feature]/models/[name]_test.dart` |

Note: View files (`views/*.dart`) are excluded — they are covered by widget/golden tests.

For each missing test file:
- Severity: **WARNING**
- Suggestion: "No test file found at `<expected_path>`. Consider adding unit tests."

**Step 4.2: Check Test Files Were Updated**

If a source file was changed but its existing test file was NOT changed in this branch:
- Severity: **INFO**
- Suggestion: "Source `<name>.dart` was modified but its test was not updated. Verify tests still cover the changes."

**Step 4.3: Run Affected Tests (MANDATORY)**

This step is **not optional** — it MUST run before the gate stamp can be issued. Static checks cannot catch logic regressions (e.g., tests that verify behavior that was removed or changed).

**Collect test files to run:**

1. For each changed source file in `lib/`, find its **direct** test file:
   - `lib/page/[feature]/services/[name].dart` → `test/page/[feature]/services/[name]_test.dart`
   - `lib/page/[feature]/providers/[name].dart` → `test/page/[feature]/providers/[name]_test.dart`
   - `lib/page/[feature]/models/[name].dart` → `test/page/[feature]/models/[name]_test.dart`

2. For each changed source file, find **dependent** test files that import it:
   ```bash
   # Find tests that import the changed source file
   grep -rl "import.*<changed_file_package_path>" test/ --include="*.dart"
   ```

3. Include any test files that were directly changed in the branch.

4. Deduplicate the collected list.

**Run the tests:**

```bash
flutter test <collected_test_files> 2>&1
```

- If ALL tests pass:
  - Severity: **PASS**
  - Report: "Affected tests: <count> files, <total_tests> tests passed"

- If any tests FAIL:
  - Severity: **ERROR** (blocks gate stamp)
  - Report each failing test name and a one-line summary of the failure
  - Suggestion: "Fix failing tests before creating PR. These tests verify behavior affected by your changes."

**Important notes:**
- If the collected test list is empty (no test files found for changed sources), report as INFO and move on
- If `flutter test` times out (>5 minutes), report as WARNING with suggestion to run manually
- This step catches the exact scenario where source behavior changed but tests still assert old behavior

### Phase 4.5: Golden Test Coverage (Only If View Files Changed)

**IMPORTANT**: This phase only runs if View files (`lib/page/**/views/**/*.dart`) are changed or added.

**Step 4.5.1: Check Golden Test File Existence**

For each changed/new View file, check if a corresponding golden test exists:

| View File Pattern | Expected Golden Test Pattern |
|---|---|
| `lib/page/[feature]/views/usp_[name]_view.dart` | `test/usp_test/page/[feature]/localizations/usp_[name]_view_test.dart` OR `test/usp_test/page/[feature]/localizations/[name]_view_test.dart` |
| `lib/page/[feature]/views/[name]_view.dart` | `test/usp_test/page/[feature]/localizations/[name]_view_test.dart` |
| `lib/page/[feature]/views/dialogs/[name]_dialog.dart` | Included in parent view's golden test OR `test/usp_test/page/[feature]/localizations/[name]_dialog_test.dart` |

For each missing golden test file:
- Severity: **WARNING**
- Suggestion: "No golden test found for `<view_file>`. Consider adding golden tests at `<expected_path>`. Use `/golden-test-review` skill for guidance."

**Step 4.5.2: Check Golden Test File Was Updated**

If a View file was changed but its existing golden test was NOT changed in this branch:
- Severity: **INFO**
- Suggestion: "View `<name>_view.dart` was modified but its golden test was not updated. If visual output changed, run `flutter test --update-goldens <test_file>`."

**Step 4.5.3: Analyze View States Coverage (Deep Check)**

For each changed View file that HAS a corresponding golden test, perform a coverage analysis:

1. **Extract view conditionals**: Read the view file and identify all conditional branches that produce different visual output:
   - `switch` statements on enums (e.g., `FirmwareUpdatePhase`)
   - `if/else` on state properties (e.g., `state.isDirty`, `state.hasError`)
   - Empty vs populated lists
   - Tab views (each tab is a different visual state)
   - Dialogs shown via `showDialog`, `showAppDialog`, etc.

2. **Extract golden test states**: Read the golden test file and extract all state keys from `GoldenTestConfig.states` and `GoldenTestConfig.interactions`:
   ```dart
   // Look for patterns like:
   states: {
     'idle_no_file': (overrides) => ...,
     'uploading': (overrides) => ...,
   },
   interactions: {
     'dialog_recovery': Interaction(...),
   },
   ```

3. **Compare coverage**: Check if all identified visual states have corresponding golden test entries.

For each missing state/interaction:
- Severity: **WARNING**
- Suggestion: "View `<name>_view.dart` has visual state `<state>` (from `<condition>`) but no golden test covers it. Add state key `<suggested_key>` to the golden test."

**Step 4.5.4: Check Mock and Fixture Files**

For each golden test file, verify supporting files exist:

```bash
# Check mock file exists
test -f test/usp_test/golden_framework/mocks/mock_[feature].dart

# Check fixture file exists
test -f test/usp_test/page/[feature]/fixtures/[feature]_test_data.dart
```

For missing files:
- Severity: **INFO**
- Suggestion: "Golden test for `[feature]` is missing mock file at `test/usp_test/golden_framework/mocks/mock_[feature].dart`."

**Step 4.5.5: Run Golden Tests (Optional Verification)**

If the user explicitly requests verification OR if there are concerns about test validity:

```bash
flutter test test/usp_test/page/[feature]/localizations/ 2>&1 | tail -20
```

- If tests fail:
- Severity: **ERROR**
- Suggestion: "Golden tests for `[feature]` are failing. Run `flutter test --update-goldens <path>` to regenerate baselines if visual changes are intentional."

### Phase 5: Report

```
## Pre-PR Readiness Report

Branch: <branch_name>
Base: <base_branch>
Changed Dart files: <count>

### Code Quality
- [PASS/WARN/ERROR] Formatting: <summary>
- [PASS/WARN/ERROR] Static Analysis: <summary>
- [PASS/WARN] Imports: <summary>

### UI Kit Usage
- [PASS/WARN/SKIP] Compliance: <summary>

### Constitution Compliance
- [PASS/WARN] Test framework (mocktail): <summary>
- [PASS/ERROR] Architecture (no codegen in providers/views): <summary>
- [PASS/WARN] Service layer pattern: <summary>
- [PASS/INFO] Error handling: <summary>
- [PASS/WARN] Naming conventions: <summary>
- [PASS/WARN/INFO] Provider autoDispose: <summary>
- [PASS/INFO] Test data location: <summary>
- [PASS/WARN/INFO/SKIP] E2E test hooks (identifier vs semanticLabel, Article XVI): <summary>

### Test Coverage
- [PASS/WARN] Test files: <summary>
- [PASS/INFO] Test freshness: <summary>
- [PASS/ERROR] Affected tests execution: <summary>

### Golden Test Coverage (if View files changed)
- [PASS/WARN/SKIP] Golden test existence: <summary>
- [PASS/INFO] Golden test freshness: <summary>
- [PASS/WARN] State coverage: <summary>
- [PASS/INFO] Mock/fixture files: <summary>

### Issues Found: <total_count>
- ERROR: <count>
- WARNING: <count>
- INFO: <count>

<detailed issue list grouped by category>

### Recommended Actions Before PR
<numbered list ordered by severity>
```

## Severity Levels

| Level | Meaning | Recommendation |
|---|---|---|
| **ERROR** | Static analysis errors, build failures | Fix before creating PR |
| **WARNING** | Missing tests, non-UI-Kit widgets | Strongly recommend fixing |
| **INFO** | Test freshness, minor suggestions | Optional, nice to have |

### Phase 6: Gate Stamp

After presenting the report to the user, if there are **no ERROR-level issues** and the user confirms they want to proceed:

```bash
touch /tmp/.pr-review-passed
```

This stamp file is consumed by the `pr_gate.py` hook to allow `gh pr create` through. It is:
- **One-shot**: deleted after a single successful `gh pr create`
- **Time-limited**: expires after 10 minutes

Do NOT create the stamp if there are unresolved ERROR-level issues (including test failures from Step 4.3).

## Important Notes

- This skill is **read-only** — it does NOT modify any files (except the gate stamp)
- All findings are recommendations, not enforced blocks
- Communicate with the user in Traditional Chinese (Taiwan)
- If a command fails to execute, report the failure and continue with remaining checks
- Group similar issues together for readability
- If the branch is clean, report a brief success message
