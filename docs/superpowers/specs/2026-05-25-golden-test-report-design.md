# Golden Test Verification Report — Design Spec

## Overview

Enhance the existing golden test infrastructure to produce an automated HTML report after running tests in **verification mode** (without `--update-goldens`). The report provides pass/fail statistics, failure image comparison (expected/actual/diff), and USP view coverage analysis.

## Goals

1. Single command (`run_golden_verify.sh`) to verify golden tests and produce a report
2. Self-contained HTML report viewable both locally and as CI artifact
3. Visual failure diagnosis via three-way image comparison
4. Coverage visibility: which USP views have golden tests and which don't

## Non-Goals

- GitHub Actions workflow (future work)
- Replacing the update-goldens flow (`run_generate_loc_snapshots.sh`)
- Code coverage (lcov) integration

## Architecture

### Flow

```
run_golden_verify.sh [-l locales] [-s screens] [-f file] [-v version] [--embed]
  │
  ├─ 1. flutter test --tags=loc --file-reporter json:snapshots/tests.json
  │     (verification mode — no --update-goldens)
  │     Failures produce images in: test/usp_test/page/{feature}/localizations/goldens/failures/
  │
  ├─ 2. dart test_scripts/test_result_parser.dart snapshots/tests.json "{locale}"
  │     Parses JSON output → structured test results with failure image paths
  │
  ├─ 3. dart test_scripts/combine_results.dart snapshots "{version}" [--embed]
  │     Combines locale results + scans coverage + generates HTML report
  │
  └─ Output: snapshots/golden_verify_report.html
```

### File Changes

| File | Action | Description |
|------|--------|-------------|
| `run_golden_verify.sh` | **New** | Verification mode entry script |
| `test_scripts/test_result_parser.dart` | **Modify** | Add failure image path extraction from error messages |
| `test_scripts/combine_results.dart` | **Modify** | Add coverage scanning logic, accept `--embed` flag |
| `test_scripts/html_generate_functions.dart` | **Rewrite** | New self-contained HTML template |
| `run_generate_loc_snapshots.sh` | **Simplify** | Remove report generation calls |

## Detailed Design

### 1. `run_golden_verify.sh`

```bash
#!/bin/bash
set -e

# Parameters: -l locales, -s screens, -f file, -v version, --embed
# Defaults: locales="en", screens="480,1280", version="0.0.1.1"

# Run flutter test WITHOUT --update-goldens
flutter test --file-reporter json:snapshots/tests.json --tags=loc \
  --dart-define=locales="$locale" \
  --dart-define=screens="$screens" \
  --dart-define=visualEffects=0 || true  # Don't exit on test failure

# Parse results per locale
dart test_scripts/test_result_parser.dart snapshots/tests.json "$locale"

# Generate combined report with coverage
dart test_scripts/combine_results.dart snapshots "$version" $embed_flag

echo "Report: snapshots/golden_verify_report.html"
```

Key difference from `run_generate_loc_snapshots.sh`:
- No `--update-goldens` flag
- `|| true` to continue after failures (we want the report)
- Does NOT move/copy golden files around
- Does NOT run `grep_loc_fils.dart`

### 2. `test_result_parser.dart` — Failure Image Extraction

When a golden test fails, Flutter outputs an error message like:

```
Golden file test failed. Diff is available at:
  test/usp_test/page/firewall/localizations/goldens/failures/firewall-edit_dirty-phone480-en_isolatedDiff.png
```

The parser will:
1. Capture the full error message from the JSON `message` field (already collected)
2. Extract file paths matching `*/failures/*` pattern using regex
3. Derive the three image paths from the base name:
   - `{name}_masterImage.png` (expected)
   - `{name}_testImage.png` (actual)
   - `{name}_isolatedDiff.png` (diff)
4. Add a `failureImages` field to the test result JSON:

```json
{
  "name": "firewall-edit_dirty",
  "result": "error",
  "messages": ["Golden file test failed..."],
  "failureImages": {
    "expected": "relative/path/to/masterImage.png",
    "actual": "relative/path/to/testImage.png",
    "diff": "relative/path/to/isolatedDiff.png"
  }
}
```

### 3. `combine_results.dart` — Coverage Scanning

New responsibility: scan project directories to determine golden test coverage.

```dart
// Scan lib/page/*/views/usp_*_view.dart
// Check for corresponding test/usp_test/page/{feature}/localizations/*_test.dart
// Produce:
{
  "coverage": {
    "total": 22,
    "covered": 18,
    "percentage": 81.8,
    "missing": ["port_forwarding", "static_routing", "dmz", "ipv6_port_service"],
    "covered_list": ["firewall", "dashboard", ...]
  }
}
```

`--embed` flag: when present, reads failure image files and converts to base64 data URIs before injecting into HTML.

### 4. HTML Report Template

Self-contained single-file HTML with embedded CSS and JS (no external CDN dependencies).

#### Layout Sections

**Header**
- Title: "Golden Test Verification Report"
- Version, timestamp, locale/device summary

**Summary Panel**
- Total / Pass / Fail counts with percentages
- Donut chart (pure CSS or inline canvas — no Chart.js CDN)

**Coverage Panel**
- Coverage bar: "{covered}/{total} USP views covered ({percentage}%)"
- Collapsible list of missing views
- Collapsible list of covered views

**Filter Bar**
- Checkbox filters: Locale, Device Type, Result (pass/fail)
- Real-time table filtering via JS

**Results Table**
- Grouped by feature (collapsible)
- Each test case row: name, device, locale, result (color-coded)
- Failed rows expand to show:
  - Three-column image comparison (Expected | Actual | Diff)
  - Error message text in monospace block

#### Styling Principles
- Modern, clean layout (CSS Grid/Flexbox)
- Color scheme: green (#22c55e) pass, red (#ef4444) fail, neutral grays
- Responsive — works on different screen widths
- Dark/light system preference support via `prefers-color-scheme`
- No external dependencies — all inline

### 5. `run_generate_loc_snapshots.sh` Simplification

Remove these lines:
- `dart test_scripts/combine_results.dart snapshots "$version"` (report generation)

Keep:
- `flutter test ... --update-goldens` (golden file generation)
- `dart test_scripts/test_result_parser.dart` — optional, can be removed too since no report is generated
- File reorganization (`grep_loc_fils.dart`)

## Output Structure

After running `run_golden_verify.sh`:

```
snapshots/
├── tests.json                          (raw flutter test output — deleted after parse)
├── localizations-test-reports-en.json  (parsed per-locale results)
├── golden_verify_report.html           (final report)
└── (no image files moved here — they stay in test/ tree)
```

Failure images remain in place: `test/usp_test/page/{feature}/localizations/goldens/failures/`

## Edge Cases

1. **All tests pass**: Report shows 100% pass, no failure detail section, coverage panel still shows missing views
2. **No tests run**: Report shows 0 total with a "No tests found" message
3. **Missing failure images**: If parser can't find the expected failure files, show error message only (graceful fallback)
4. **Single file mode** (`-f`): Run one test file, report covers only that file (no coverage scan)

## Future Extensions (Out of Scope)

- GitHub Actions workflow with artifact upload
- Historical trend tracking (pass rate over time)
- Slack/Teams notification on failure
- Interactive image overlay (slider comparison)
