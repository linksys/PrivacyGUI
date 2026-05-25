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
