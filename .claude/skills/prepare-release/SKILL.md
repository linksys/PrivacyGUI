---
name: prepare-release
description: Verify project readiness before a release. Runs full test suite, static analysis, formatting check, screenshot test validation, and version verification. Use before tagging or publishing a release build. Trigger keywords (English) - prepare release, release check, pre-release, release ready, verify release. Trigger keywords (Chinese) - 準備發版, 發版檢查, 發版前檢查, 檢查發版, 發版準備, release 檢查.
---

# Pre-Release Verification

## Purpose

Perform a full verification of the project before creating a release build. This ensures all tests pass, code quality is clean, and the version is properly set. Modeled after a release preparation workflow adapted for PrivacyGUI.

## When to Use This Skill

- Before creating a release build (`build_web.sh`)
- Before tagging a release version
- When the user says: "prepare release", "release check", "準備發版", "發版檢查"

## When NOT to Use This Skill

- During normal development (use `review-pr-readiness` instead)
- For hotfix branches where only a targeted check is needed

## Execution Workflow

### Phase 1: Pre-Release Checks

**Step 1.1: Verify Version**

Read `pubspec.yaml` and report the current version:

```bash
grep '^version:' pubspec.yaml
```

- Display the current version to the user
- Ask the user to confirm this is the intended release version
- If the user wants to update the version, assist with the change

**Step 1.2: Run Static Analysis**

```bash
flutter analyze
```

- If errors or warnings are found:
  - List each issue with file path, line number, and description
  - Severity: **ERROR** — must fix before release
- If clean: report PASS

**Step 1.3: Check Formatting**

```bash
dart format --set-exit-if-changed --output=none lib/ test/
```

- If unformatted files found:
  - List them
  - Severity: **ERROR** — must fix before release
  - Suggestion: "Run `dart format lib/ test/` to fix all"
- If clean: report PASS

### Phase 2: Test Suite

**Step 2.1: Run Unit Tests**

```bash
./run_tests.sh
```

- Report total passed, failed, skipped counts
- If any test fails:
  - List each failure: test file, test name, failure reason
  - Severity: **ERROR** — must fix before release
- If all pass: report PASS

**Step 2.2: Verify Screenshot Tests (If UI Changes Exist)**

Check if any View files changed since the last release tag:

```bash
git diff --name-only <last_release_tag>...HEAD -- 'lib/page/*/views/*.dart'
```

If View files changed:
- Remind the user to run screenshot tests:
  ```bash
  ./run_generate_loc_snapshots.sh
  ```
- Severity: **WARNING** — recommend running before release
- Note: Do NOT auto-run this — it can be time-consuming. Just remind the user.

If no View files changed: report SKIP (no UI changes)

### Phase 3: Build Verification

**Step 3.1: Verify Dependencies**

```bash
flutter pub get
```

- If dependency resolution fails: **ERROR**
- If clean: report PASS

**Step 3.2: Dry Run Build Check (Optional)**

Ask the user if they want to run a test build:

```bash
flutter build web --target=lib/main.dart --build-number=0 --dart-define=force=false --dart-define=cloud_env=prod --dart-define=enable_env_picker=false --dart-define=ca=true
```

- This is optional — the user decides whether to run it
- If build fails: **ERROR** — report the build output
- If build succeeds: report PASS

### Phase 4: Report

```
## Pre-Release Verification Report

Version: <version from pubspec.yaml>
Date: <current date>

### Results

#### Code Quality
- [PASS/ERROR] Static Analysis: <summary>
- [PASS/ERROR] Formatting: <summary>

#### Tests
- [PASS/ERROR] Unit Tests: <passed>/<total> passed
- [PASS/WARN/SKIP] Screenshot Tests: <summary>

#### Build
- [PASS/ERROR] Dependencies: <summary>
- [PASS/ERROR/SKIP] Build Check: <summary>

### Overall: [READY / NOT READY]

<if NOT READY: list all blocking issues>
<if READY: "All checks passed. Ready to proceed with release.">

### Recommended Next Steps
1. <action items based on results>
```

## Decision Criteria

The release is considered **READY** when ALL of the following are true:
- Static analysis: 0 errors
- Formatting: all files formatted
- Unit tests: all passing
- Dependencies: resolved successfully

The release is considered **NOT READY** if any of the above fail.

**WARNING-level items** (screenshot tests) do not block the release but are flagged as recommendations.

## Important Notes

- This skill is primarily **read-only** — it only modifies files if the user explicitly requests a version bump
- Communicate with the user in Traditional Chinese (Taiwan)
- Always ask for user confirmation before any version changes
- The build verification step is optional and should be offered, not auto-run
- If `./run_tests.sh` takes a long time, inform the user and let them decide to continue or skip
