---
name: review-pr-readiness
description: Review current branch changes for PR readiness. Checks code quality (dart format, flutter analyze), UI Kit library usage in Views, and test file coverage. Use before creating a Pull Request. Trigger keywords (English) - review pr, check pr, pr ready, pre-pr check, review before pr. Trigger keywords (Chinese) - 檢查 PR, PR 檢查, 準備 PR, PR 審查, 發 PR 前檢查.
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
- Categorize changed files:
  - `lib/page/*/views/*.dart` → View files
  - `lib/page/*/providers/*.dart` → Provider files
  - `lib/page/*/services/*.dart` → Service files
  - `lib/page/*/models/*.dart` → Model files
  - `test/**/*.dart` → Test files
  - Other `lib/**/*.dart` → Other source files

### Phase 1: Code Quality

**Step 1.1: Check Formatting**

Run `dart format` in dry-run mode on ALL changed `.dart` files:

```bash
dart format --set-exit-if-changed --output=none <changed_dart_files>
```

- If exit code is non-zero, list the unformatted files
- Severity: **ERROR**
- Suggestion: "Run `dart format <file>` to fix"

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
CircularProgressIndicator                      → AppSpinnerDialog
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

### Phase 3: Test Coverage

**Step 3.1: Check Test File Existence**

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

**Step 3.2: Check Test Files Were Updated**

If a source file was changed but its existing test file was NOT changed in this branch:
- Severity: **INFO**
- Suggestion: "Source `<name>.dart` was modified but its test was not updated. Verify tests still cover the changes."

### Phase 4: Report

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

### Test Coverage
- [PASS/WARN] Test files: <summary>
- [PASS/INFO] Test freshness: <summary>

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

### Phase 5: Gate Stamp

After presenting the report to the user, if there are **no ERROR-level issues** and the user confirms they want to proceed:

```bash
touch /tmp/.pr-review-passed
```

This stamp file is consumed by the `pr_gate.py` hook to allow `gh pr create` through. It is:
- **One-shot**: deleted after a single successful `gh pr create`
- **Time-limited**: expires after 10 minutes

Do NOT create the stamp if there are unresolved ERROR-level issues.

## Important Notes

- This skill is **read-only** — it does NOT modify any files (except the gate stamp)
- All findings are recommendations, not enforced blocks
- Communicate with the user in Traditional Chinese (Taiwan)
- If a command fails to execute, report the failure and continue with remaining checks
- Group similar issues together for readability
- If the branch is clean, report a brief success message
