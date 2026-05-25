# Golden Test Verification Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an automated HTML report that runs golden tests in verification mode and produces a self-contained report with pass/fail stats, failure image comparison, and USP view coverage.

**Architecture:** Extend the existing `test_scripts/` Dart utilities to extract failure images and scan coverage, then generate a new self-contained HTML report. A new shell script `run_golden_verify.sh` orchestrates the flow without `--update-goldens`.

**Tech Stack:** Dart (test result parsing, HTML generation), Bash (orchestration), vanilla HTML/CSS/JS (report UI)

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `run_golden_verify.sh` | Create | Entry script: runs flutter test in verify mode, invokes parsers, outputs report |
| `test_scripts/test_result_parser.dart` | Modify | Add failure image path extraction from error messages |
| `test_scripts/combine_results.dart` | Modify | Add coverage scanning, `--embed` flag, call new report generator |
| `test_scripts/html_generate_functions.dart` | Rewrite | New self-contained HTML template with image comparison & coverage |
| `run_generate_loc_snapshots.sh` | Modify | Remove report generation calls (lines 47) |

---

## Task 1: Modify `test_result_parser.dart` — Extract Failure Image Paths

**Files:**
- Modify: `test_scripts/test_result_parser.dart:163-195`

When a golden test fails, Flutter's JSON output includes a `message` field containing paths like:
```
test/usp_test/page/firewall/localizations/goldens/failures/firewall-edit_dirty-phone480-en_isolatedDiff.png
```

We need to parse these paths and add a `failureImages` object to the test result.

- [ ] **Step 1: Add `extractFailureImages` function**

Add this function after the existing `extractInfo` function (after line 217):

```dart
void extractFailureImages(Map<String, dynamic> test) {
  final messages = test['messages'] as List<String>?;
  if (messages == null || messages.isEmpty) return;

  final fullMessage = messages.join('\n');
  final failurePathRegex = RegExp(r'([\w/._-]+/failures/[\w._-]+\.png)');
  final matches = failurePathRegex.allMatches(fullMessage);

  if (matches.isEmpty) return;

  String? diffPath;
  String? actualPath;
  String? expectedPath;

  for (final match in matches) {
    final path = match.group(1)!;
    if (path.contains('isolatedDiff') || path.contains('maskedDiff')) {
      diffPath = path;
    } else if (path.contains('testImage')) {
      actualPath = path;
    } else if (path.contains('masterImage')) {
      expectedPath = path;
    }
  }

  if (diffPath != null || actualPath != null || expectedPath != null) {
    test['failureImages'] = <String, String?>{
      'expected': expectedPath,
      'actual': actualPath,
      'diff': diffPath,
    };
  }
}
```

- [ ] **Step 2: Call `extractFailureImages` when a test has error result**

In the `handleTestRecord` function, inside the `json['testID'] != null` branch, after the message is added (around line 191), add a call to extract failure images when the result is an error:

Replace lines 184-192:
```dart
      for (var element in result) {
        element['result'] = json['result'];
      }
    }
    if (json['message'] != null) {
      for (var element in result) {
        addOrAppendData<String>(element, 'messages', json['message']);
      }
    }
```

With:
```dart
      for (var element in result) {
        element['result'] = json['result'];
      }
    }
    if (json['message'] != null) {
      for (var element in result) {
        addOrAppendData<String>(element, 'messages', json['message']);
        if (json['result'] != null && json['result'] != 'success') {
          extractFailureImages(element);
        }
      }
    }
```

- [ ] **Step 3: Verify the parser runs without errors**

Run:
```bash
dart test_scripts/test_result_parser.dart --help 2>&1 || echo "OK - no --help flag expected"
```

The script expects a file argument; just confirm it doesn't have syntax errors by checking Dart analysis:
```bash
dart analyze test_scripts/test_result_parser.dart
```
Expected: No errors (warnings are acceptable since these are scripts).

- [ ] **Step 4: Commit**

```bash
git add test_scripts/test_result_parser.dart
git commit -m "feat: extract failure image paths in test result parser

Add extractFailureImages() to parse golden test failure messages and
extract expected/actual/diff image paths into a failureImages field."
```

---

## Task 2: Modify `combine_results.dart` — Add Coverage Scanning and `--embed` Flag

**Files:**
- Modify: `test_scripts/combine_results.dart`

- [ ] **Step 1: Add coverage scanning function**

Add the following function before `main()` (after the imports, line 4):

```dart
Map<String, dynamic> scanCoverage() {
  final viewDir = Directory('lib/page');
  final testDir = Directory('test/usp_test/page');

  if (!viewDir.existsSync()) {
    return {'total': 0, 'covered': 0, 'percentage': 0.0, 'missing': [], 'covered_list': []};
  }

  final viewFiles = viewDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.contains('/views/usp_') && f.path.endsWith('_view.dart'))
      .toList();

  final List<String> coveredViews = [];
  final List<String> missingViews = [];

  for (final viewFile in viewFiles) {
    final pathParts = viewFile.path.split('/');
    final pageIndex = pathParts.indexOf('page');
    if (pageIndex == -1 || pageIndex + 1 >= pathParts.length) continue;
    final feature = pathParts[pageIndex + 1];

    final testPattern = Directory('${testDir.path}/$feature/localizations');
    if (testPattern.existsSync()) {
      final testFiles = testPattern
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'));
      if (testFiles.isNotEmpty) {
        if (!coveredViews.contains(feature)) coveredViews.add(feature);
        continue;
      }
    }
    if (!missingViews.contains(feature)) missingViews.add(feature);
  }

  final total = coveredViews.length + missingViews.length;
  final percentage = total > 0 ? (coveredViews.length / total * 100.0) : 0.0;

  return {
    'total': total,
    'covered': coveredViews.length,
    'percentage': double.parse(percentage.toStringAsFixed(1)),
    'missing': missingViews..sort(),
    'covered_list': coveredViews..sort(),
  };
}
```

- [ ] **Step 2: Update `main()` to accept `--embed` flag and include coverage**

Replace the entire `main()` function:

```dart
void main(List<String> args) {
  if (args.isEmpty) {
    print('No folder path provided');
    exit(1);
  }
  final folderStr = args[0];
  final folder = Directory(folderStr);
  if (!folder.existsSync()) {
    print('Folder<$folderStr> does not exist');
    exit(1);
  }
  final version = args.length > 1 ? args[1] : '0.0.0';
  final embedImages = args.contains('--embed');

  // find json files on target folder
  final files = folder.listSync().where((e) => e.path.endsWith('.json'));
  if (files.isEmpty) {
    print('No JSON files found in $folderStr');
    exit(1);
  }
  // convert json object from files
  final jsonObjects = files
      .map((e) => List.from(jsonDecode(File(e.path).readAsStringSync())))
      .reduce((value, list) => value..addAll(list))
      .map((e) => e as Map<String, dynamic>)
      .toList();

  // collect all the locales
  final Set<String> localeSet = {};
  for (final jsonObject in jsonObjects) {
    final locale = jsonObject['locale'];
    if (locale != null) {
      localeSet.add(locale);
    }
  }
  final locales = localeSet.toList();

  // collect all the devices
  final Set<String> deviceSet = {};
  for (final jsonObject in jsonObjects) {
    final device = jsonObject['deviceType'];
    if (device != null) {
      deviceSet.add(device);
    }
  }
  final devices = deviceSet.toList();

  // Embed failure images as base64 if --embed flag is set
  if (embedImages) {
    for (final test in jsonObjects) {
      final failureImages = test['failureImages'] as Map<String, dynamic>?;
      if (failureImages == null) continue;
      for (final key in ['expected', 'actual', 'diff']) {
        final path = failureImages[key] as String?;
        if (path != null) {
          final file = File(path);
          if (file.existsSync()) {
            final bytes = file.readAsBytesSync();
            final b64 = base64Encode(bytes);
            failureImages[key] = 'data:image/png;base64,$b64';
          }
        }
      }
    }
  }

  // Scan coverage
  final coverage = scanCoverage();

  final resultObj = <String, dynamic>{};
  resultObj['counting'] = {
    'success': jsonObjects.where((e) => e['result'] == 'success').length,
    'fail': jsonObjects.where((e) => e['result'] == 'error').length,
    'total': jsonObjects.length,
  };
  resultObj['tests'] = jsonObjects;
  resultObj['locales'] = locales;
  resultObj['devices'] = devices;
  resultObj['coverage'] = coverage;
  resultObj['version'] = version;
  resultObj['timestamp'] = DateTime.now().toIso8601String();
  resultObj['embedImages'] = embedImages;

  final htmlReport = generateHTMLReport(resultObj, version);
  final reportHTMLFile =
      File('$folderStr/golden_verify_report.html');
  if (!reportHTMLFile.existsSync()) {
    reportHTMLFile.createSync(recursive: true);
  }
  reportHTMLFile.writeAsStringSync(htmlReport);
  print('Report generated: ${reportHTMLFile.path}');
}
```

- [ ] **Step 3: Verify no syntax errors**

```bash
dart analyze test_scripts/combine_results.dart
```
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add test_scripts/combine_results.dart
git commit -m "feat: add coverage scanning and --embed flag to combine_results

Scans lib/page/*/views/usp_*_view.dart against test/usp_test/page/*/
to calculate golden test coverage. The --embed flag converts failure
images to base64 data URIs for self-contained CI artifacts."
```

---

## Task 3: Rewrite `html_generate_functions.dart` — New Report Template

**Files:**
- Rewrite: `test_scripts/html_generate_functions.dart`

- [ ] **Step 1: Replace the entire file with the new template**

```dart
part of 'combine_results.dart';

String generateHTMLReport(Map<String, dynamic> result, String version) {
  final timestamp = result['timestamp'] ?? DateTime.now().toIso8601String();
  final embedImages = result['embedImages'] ?? false;

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Golden Test Report $version</title>
  <style>
    :root {
      --color-pass: #22c55e;
      --color-fail: #ef4444;
      --color-bg: #ffffff;
      --color-surface: #f8fafc;
      --color-border: #e2e8f0;
      --color-text: #1e293b;
      --color-text-muted: #64748b;
      --color-accent: #3b82f6;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --color-bg: #0f172a;
        --color-surface: #1e293b;
        --color-border: #334155;
        --color-text: #f1f5f9;
        --color-text-muted: #94a3b8;
      }
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: var(--color-bg);
      color: var(--color-text);
      padding: 2rem;
      line-height: 1.6;
    }
    h1 { font-size: 1.5rem; margin-bottom: 0.25rem; }
    .subtitle { color: var(--color-text-muted); font-size: 0.875rem; margin-bottom: 2rem; }
    .panels { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-bottom: 2rem; }
    .panel {
      background: var(--color-surface);
      border: 1px solid var(--color-border);
      border-radius: 0.75rem;
      padding: 1.5rem;
    }
    .panel h2 { font-size: 1rem; margin-bottom: 1rem; }
    .stats { display: flex; gap: 2rem; align-items: center; }
    .stat-item { text-align: center; }
    .stat-value { font-size: 1.75rem; font-weight: 700; }
    .stat-label { font-size: 0.75rem; color: var(--color-text-muted); text-transform: uppercase; }
    .stat-pass .stat-value { color: var(--color-pass); }
    .stat-fail .stat-value { color: var(--color-fail); }
    .donut-container { width: 100px; height: 100px; }
    .coverage-bar-container { margin: 0.75rem 0; }
    .coverage-bar {
      height: 8px;
      background: var(--color-border);
      border-radius: 4px;
      overflow: hidden;
    }
    .coverage-bar-fill {
      height: 100%;
      background: var(--color-accent);
      border-radius: 4px;
      transition: width 0.3s;
    }
    .coverage-text { font-size: 0.875rem; color: var(--color-text-muted); margin-top: 0.25rem; }
    .missing-list {
      margin-top: 0.75rem;
      font-size: 0.8rem;
      color: var(--color-fail);
    }
    .missing-list summary { cursor: pointer; font-weight: 500; }
    .missing-list ul { margin-top: 0.5rem; padding-left: 1.5rem; }
    .filters {
      display: flex;
      gap: 1.5rem;
      flex-wrap: wrap;
      margin-bottom: 1.5rem;
      padding: 1rem;
      background: var(--color-surface);
      border: 1px solid var(--color-border);
      border-radius: 0.75rem;
    }
    .filter-group h3 { font-size: 0.75rem; text-transform: uppercase; color: var(--color-text-muted); margin-bottom: 0.5rem; }
    .filter-group label { margin-right: 0.75rem; font-size: 0.875rem; cursor: pointer; }
    .filter-group input { margin-right: 0.25rem; }
    .results { margin-top: 1rem; }
    .feature-group {
      border: 1px solid var(--color-border);
      border-radius: 0.5rem;
      margin-bottom: 0.75rem;
      overflow: hidden;
    }
    .feature-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0.75rem 1rem;
      background: var(--color-surface);
      cursor: pointer;
      user-select: none;
      font-weight: 600;
    }
    .feature-header:hover { background: var(--color-border); }
    .feature-badge {
      font-size: 0.75rem;
      padding: 0.125rem 0.5rem;
      border-radius: 9999px;
      font-weight: 500;
    }
    .badge-pass { background: #dcfce7; color: #166534; }
    .badge-fail { background: #fef2f2; color: #991b1b; }
    @media (prefers-color-scheme: dark) {
      .badge-pass { background: #14532d; color: #86efac; }
      .badge-fail { background: #450a0a; color: #fca5a5; }
    }
    .feature-body { display: none; }
    .feature-body.open { display: block; }
    .test-row {
      display: flex;
      align-items: center;
      padding: 0.5rem 1rem;
      border-top: 1px solid var(--color-border);
      font-size: 0.875rem;
    }
    .test-row.fail { background: #fef2f2; }
    @media (prefers-color-scheme: dark) { .test-row.fail { background: #1c1917; } }
    .test-icon { margin-right: 0.5rem; font-size: 1rem; }
    .test-icon.pass { color: var(--color-pass); }
    .test-icon.fail { color: var(--color-fail); }
    .test-name { flex: 1; }
    .test-meta { font-size: 0.75rem; color: var(--color-text-muted); }
    .failure-details {
      padding: 1rem;
      border-top: 1px solid var(--color-border);
      background: var(--color-surface);
    }
    .image-comparison {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      gap: 0.75rem;
      margin-bottom: 0.75rem;
    }
    .image-comparison figure { text-align: center; }
    .image-comparison figcaption {
      font-size: 0.75rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
      text-transform: uppercase;
      color: var(--color-text-muted);
    }
    .image-comparison img {
      max-width: 100%;
      height: auto;
      border: 1px solid var(--color-border);
      border-radius: 0.25rem;
    }
    .error-message {
      font-family: 'SF Mono', 'Fira Code', monospace;
      font-size: 0.75rem;
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: 0.25rem;
      padding: 0.75rem;
      white-space: pre-wrap;
      word-break: break-all;
      max-height: 150px;
      overflow-y: auto;
      color: var(--color-fail);
    }
  </style>
</head>
<body>
  <h1>Golden Test Verification Report</h1>
  <p class="subtitle">Version $version &mdash; Generated $timestamp</p>

  <div class="panels">
    <div class="panel">
      <h2>Test Summary</h2>
      <div class="stats">
        <div class="stat-item"><div class="stat-value" id="totalCount">0</div><div class="stat-label">Total</div></div>
        <div class="stat-item stat-pass"><div class="stat-value" id="passCount">0</div><div class="stat-label">Pass</div></div>
        <div class="stat-item stat-fail"><div class="stat-value" id="failCount">0</div><div class="stat-label">Fail</div></div>
        <div class="donut-container"><canvas id="donutChart" width="100" height="100"></canvas></div>
      </div>
    </div>
    <div class="panel">
      <h2>Coverage</h2>
      <div id="coveragePanel"></div>
    </div>
  </div>

  <div class="filters" id="filterBar"></div>
  <div class="results" id="resultsContainer"></div>

  <script>
    const DATA = ${jsonEncode(result)};

    function init() {
      renderSummary();
      renderCoverage();
      renderFilters();
      renderResults();
    }

    function renderSummary() {
      const c = DATA.counting;
      document.getElementById('totalCount').textContent = c.total;
      document.getElementById('passCount').textContent = c.success;
      document.getElementById('failCount').textContent = c.fail;
      drawDonut(c.success, c.fail);
    }

    function drawDonut(pass, fail) {
      const canvas = document.getElementById('donutChart');
      const ctx = canvas.getContext('2d');
      const total = pass + fail;
      if (total === 0) return;
      const cx = 50, cy = 50, r = 40, inner = 25;
      const passAngle = (pass / total) * Math.PI * 2;
      const startAngle = -Math.PI / 2;

      ctx.beginPath();
      ctx.arc(cx, cy, r, startAngle, startAngle + passAngle);
      ctx.arc(cx, cy, inner, startAngle + passAngle, startAngle, true);
      ctx.closePath();
      ctx.fillStyle = '#22c55e';
      ctx.fill();

      ctx.beginPath();
      ctx.arc(cx, cy, r, startAngle + passAngle, startAngle + Math.PI * 2);
      ctx.arc(cx, cy, inner, startAngle + Math.PI * 2, startAngle + passAngle, true);
      ctx.closePath();
      ctx.fillStyle = '#ef4444';
      ctx.fill();

      ctx.fillStyle = getComputedStyle(document.body).color;
      ctx.font = 'bold 14px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(Math.round((pass / total) * 100) + '%', cx, cy);
    }

    function renderCoverage() {
      const cov = DATA.coverage;
      if (!cov) { document.getElementById('coveragePanel').textContent = 'No coverage data'; return; }
      const pct = cov.percentage;
      let html = '<div class="coverage-bar-container">';
      html += '<div class="coverage-bar"><div class="coverage-bar-fill" style="width:' + pct + '%"></div></div>';
      html += '<div class="coverage-text">' + cov.covered + '/' + cov.total + ' USP views covered (' + pct + '%)</div>';
      html += '</div>';
      if (cov.missing && cov.missing.length > 0) {
        html += '<details class="missing-list"><summary>' + cov.missing.length + ' views missing golden tests</summary><ul>';
        cov.missing.forEach(function(v) { html += '<li>' + v + '</li>'; });
        html += '</ul></details>';
      }
      document.getElementById('coveragePanel').innerHTML = html;
    }

    function renderFilters() {
      const bar = document.getElementById('filterBar');
      const locales = [...new Set(DATA.tests.map(t => t.locale).filter(Boolean))];
      const devices = [...new Set(DATA.tests.map(t => t.deviceType).filter(Boolean))];
      let html = '';

      html += '<div class="filter-group"><h3>Locale</h3>';
      locales.forEach(function(l) { html += '<label><input type="checkbox" name="locale" value="' + l + '" checked onchange="renderResults()">' + l + '</label>'; });
      html += '</div>';

      html += '<div class="filter-group"><h3>Device</h3>';
      devices.forEach(function(d) { html += '<label><input type="checkbox" name="device" value="' + d + '" checked onchange="renderResults()">' + d + '</label>'; });
      html += '</div>';

      html += '<div class="filter-group"><h3>Result</h3>';
      html += '<label><input type="checkbox" name="result" value="success" checked onchange="renderResults()">Pass</label>';
      html += '<label><input type="checkbox" name="result" value="error" checked onchange="renderResults()">Fail</label>';
      html += '</div>';

      bar.innerHTML = html;
    }

    function getFilters() {
      const locales = [...document.querySelectorAll('input[name="locale"]:checked')].map(e => e.value);
      const devices = [...document.querySelectorAll('input[name="device"]:checked')].map(e => e.value);
      const results = [...document.querySelectorAll('input[name="result"]:checked')].map(e => e.value);
      return { locales, devices, results };
    }

    function renderResults() {
      const filters = getFilters();
      const tests = DATA.tests.filter(function(t) {
        return filters.locales.includes(t.locale) &&
               filters.devices.includes(t.deviceType) &&
               filters.results.includes(t.result);
      });

      // Group by feature (extract from testCaseFilePath)
      const groups = {};
      tests.forEach(function(t) {
        const path = t.testCaseFilePath || '';
        const match = path.match(/page\\/([^/]+)/);
        const feature = match ? match[1] : 'other';
        if (!groups[feature]) groups[feature] = [];
        groups[feature].push(t);
      });

      let html = '';
      const sortedFeatures = Object.keys(groups).sort();
      sortedFeatures.forEach(function(feature) {
        const featureTests = groups[feature];
        const failCount = featureTests.filter(t => t.result === 'error').length;
        const badgeClass = failCount > 0 ? 'badge-fail' : 'badge-pass';
        const badgeText = failCount > 0 ? failCount + ' failed' : 'all pass';

        html += '<div class="feature-group">';
        html += '<div class="feature-header" onclick="toggleFeature(this)">';
        html += '<span>' + feature + ' (' + featureTests.length + ')</span>';
        html += '<span class="feature-badge ' + badgeClass + '">' + badgeText + '</span>';
        html += '</div>';
        html += '<div class="feature-body' + (failCount > 0 ? ' open' : '') + '">';

        featureTests.forEach(function(t) {
          const isPass = t.result === 'success';
          const icon = isPass ? '&#10003;' : '&#10007;';
          const iconClass = isPass ? 'pass' : 'fail';
          const rowClass = isPass ? '' : ' fail';
          const name = t.tsName || t.name || 'unknown';

          html += '<div class="test-row' + rowClass + '">';
          html += '<span class="test-icon ' + iconClass + '">' + icon + '</span>';
          html += '<span class="test-name">' + escapeHtml(name) + '</span>';
          html += '<span class="test-meta">' + (t.deviceType || '') + ' / ' + (t.locale || '') + '</span>';
          html += '</div>';

          if (!isPass) {
            html += '<div class="failure-details">';
            if (t.failureImages) {
              html += '<div class="image-comparison">';
              html += renderImage('Expected', t.failureImages.expected);
              html += renderImage('Actual', t.failureImages.actual);
              html += renderImage('Diff', t.failureImages.diff);
              html += '</div>';
            }
            if (t.messages && t.messages.length > 0) {
              html += '<div class="error-message">' + escapeHtml(t.messages.join('\\n')) + '</div>';
            }
            html += '</div>';
          }
        });

        html += '</div></div>';
      });

      document.getElementById('resultsContainer').innerHTML = html;
    }

    function renderImage(label, src) {
      if (!src) return '<figure><figcaption>' + label + '</figcaption><div style="padding:2rem;color:var(--color-text-muted)">N/A</div></figure>';
      return '<figure><figcaption>' + label + '</figcaption><img src="' + src + '" alt="' + label + '" loading="lazy"></figure>';
    }

    function toggleFeature(header) {
      const body = header.nextElementSibling;
      body.classList.toggle('open');
    }

    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    document.addEventListener('DOMContentLoaded', init);
  </script>
</body>
</html>
''';
}
```

- [ ] **Step 2: Verify no syntax errors**

```bash
dart analyze test_scripts/html_generate_functions.dart
```
Expected: No errors (the `part of` directive means it's analyzed with `combine_results.dart`):
```bash
dart analyze test_scripts/combine_results.dart
```

- [ ] **Step 3: Commit**

```bash
git add test_scripts/html_generate_functions.dart
git commit -m "feat: rewrite HTML report template with modern UI

Self-contained HTML with embedded CSS/JS. Includes donut chart,
coverage panel, filter bar, collapsible feature groups, and
three-way image comparison for failures. Supports dark mode."
```

---

## Task 4: Create `run_golden_verify.sh`

**Files:**
- Create: `run_golden_verify.sh`

- [ ] **Step 1: Create the script**

```bash
#!/bin/bash
set -e

EMBED_FLAG=""

while getopts l:s:f:v:-: flag
do
    case "${flag}" in
        l) locales=${OPTARG};;
        s) screens=${OPTARG};;
        f) file=${OPTARG};;
        v) version=${OPTARG};;
        -)
            case "${OPTARG}" in
                embed) EMBED_FLAG="--embed";;
            esac
            ;;
    esac
done

if [ -z "$locales" ]; then
  locales="en"
fi
if [ -z "$screens" ]; then
  screens="480,1280"
fi
if [ -z "$version" ]; then
  version="0.0.1.1"
fi

echo "*********************Golden Test Verification********************"
echo "Locales: $locales"
echo "Screens: $screens"
echo "Version: $version"
echo "Embed images: ${EMBED_FLAG:-no}"

mkdir -p ./snapshots/

if [ -z "$file" ]; then
  IFS=',' read -ra LOCS <<< "$locales"
  for locale in "${LOCS[@]}"; do
    echo "Verifying golden tests for locale: $locale, screens: $screens"
    flutter test --file-reporter json:snapshots/tests.json --tags=loc \
      --dart-define=locales="$locale" \
      --dart-define=screens="$screens" \
      --dart-define=visualEffects=0 || true
    dart test_scripts/test_result_parser.dart snapshots/tests.json "$locale"
    rm -f snapshots/tests.json
  done

  dart test_scripts/combine_results.dart snapshots "$version" $EMBED_FLAG
  echo ""
  echo "Report generated: snapshots/golden_verify_report.html"
else
  echo "Target file: $file"
  flutter test "$file" --file-reporter json:snapshots/tests.json --tags=loc \
    --dart-define=locales="$locales" \
    --dart-define=screens="$screens" \
    --dart-define=visualEffects=0 || true
  dart test_scripts/test_result_parser.dart snapshots/tests.json "$locales"
  rm -f snapshots/tests.json
  dart test_scripts/combine_results.dart snapshots "$version" $EMBED_FLAG
  echo ""
  echo "Report generated: snapshots/golden_verify_report.html"
fi

echo "Golden Test Verification Finished!******************************************"
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x run_golden_verify.sh
```

- [ ] **Step 3: Verify script syntax**

```bash
bash -n run_golden_verify.sh
```
Expected: no output (means no syntax errors).

- [ ] **Step 4: Commit**

```bash
git add run_golden_verify.sh
git commit -m "feat: add run_golden_verify.sh for verification-mode testing

Runs golden tests without --update-goldens, parses results, and
generates an HTML report with pass/fail stats, failure image
comparison, and coverage analysis. Supports --embed for CI artifacts."
```

---

## Task 5: Simplify `run_generate_loc_snapshots.sh` — Remove Report Generation

**Files:**
- Modify: `run_generate_loc_snapshots.sh:42-47`

- [ ] **Step 1: Remove the report generation call**

In `run_generate_loc_snapshots.sh`, remove line 47:
```bash
  dart test_scripts/combine_results.dart snapshots "$version"
```

Also remove the `test_result_parser.dart` call on line 42 and the `rm` on line 43, since without report generation these intermediate JSONs aren't needed:

Replace lines 41-47:
```bash
      flutter test --file-reporter json:snapshots/tests.json --tags=loc --update-goldens --dart-define=locales="$locale" --dart-define=screens="$screens" --dart-define=visualEffects=0
      dart test_scripts/test_result_parser.dart snapshots/tests.json "$locale" "$screenStr"
      rm snapshots/tests.json
    done
  # done
  
  dart test_scripts/combine_results.dart snapshots "$version"
```

With:
```bash
      flutter test --tags=loc --update-goldens --dart-define=locales="$locale" --dart-define=screens="$screens" --dart-define=visualEffects=0
    done
```

- [ ] **Step 2: Remove the now-unused `version` variable usage from the non-file branch**

The `version` variable and its default are still used elsewhere — check if it's still referenced. After the removal above, `version` is only used in the echo at the top. You can leave the variable declaration and echo (they're informational) or remove them. Leave them for consistency with the `-v` flag parsing.

- [ ] **Step 3: Verify script syntax**

```bash
bash -n run_generate_loc_snapshots.sh
```
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add run_generate_loc_snapshots.sh
git commit -m "refactor: remove report generation from snapshot update script

Report generation is now handled exclusively by run_golden_verify.sh.
The update script focuses solely on regenerating golden baseline files."
```

---

## Task 6: End-to-End Smoke Test

- [ ] **Step 1: Run the verify script on a single test file to confirm the full pipeline works**

Pick one test file that you know will pass:
```bash
./run_golden_verify.sh -f test/usp_test/page/firewall/localizations/usp_firewall_view_test.dart -v test
```

Expected: Script completes, produces `snapshots/golden_verify_report.html`.

- [ ] **Step 2: Open the report and verify it renders correctly**

```bash
open snapshots/golden_verify_report.html
```

Check:
- Summary panel shows correct total/pass/fail
- Coverage panel shows USP view coverage with missing list
- Filter checkboxes work
- Feature groups are collapsible
- If any test fails, verify image comparison appears

- [ ] **Step 3: Test the `--embed` flag**

```bash
./run_golden_verify.sh -f test/usp_test/page/firewall/localizations/usp_firewall_view_test.dart -v test --embed
```

Check: Report still works, and if there were failures, images are embedded as base64 (check HTML source for `data:image/png;base64,`).

- [ ] **Step 4: Verify the update script still works**

```bash
./run_generate_loc_snapshots.sh -f test/usp_test/page/firewall/localizations/usp_firewall_view_test.dart
```

Expected: Golden files update, no report is generated (no `screenshot_test_reports_*.html` in snapshots/).

- [ ] **Step 5: Final commit (if any fixups were needed)**

```bash
git add -A
git commit -m "fix: address issues found during smoke test"
```
