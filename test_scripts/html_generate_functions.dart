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
    .toolbar {
      display: flex; gap: 1rem; align-items: center; flex-wrap: wrap;
      margin-bottom: 1.5rem; padding: 0.75rem 1rem;
      background: var(--color-surface); border: 1px solid var(--color-border); border-radius: 0.75rem;
    }
    .toolbar-group { display: flex; align-items: center; gap: 0.5rem; }
    .toolbar-group label { font-size: 0.75rem; text-transform: uppercase; color: var(--color-text-muted); }
    .btn-group { display: flex; gap: 0; }
    .btn-group button {
      padding: 0.375rem 0.75rem; font-size: 0.8rem; border: 1px solid var(--color-border);
      background: var(--color-bg); color: var(--color-text); cursor: pointer;
      transition: background 0.15s;
    }
    .btn-group button:first-child { border-radius: 0.375rem 0 0 0.375rem; }
    .btn-group button:last-child { border-radius: 0 0.375rem 0.375rem 0; }
    .btn-group button.active {
      background: var(--color-accent); color: #fff; border-color: var(--color-accent);
    }
    .search-box {
      padding: 0.375rem 0.75rem; font-size: 0.85rem;
      border: 1px solid var(--color-border); border-radius: 0.375rem;
      background: var(--color-bg); color: var(--color-text);
      width: 200px;
    }
    .search-box::placeholder { color: var(--color-text-muted); }
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
      cursor: pointer;
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
    /* Lightbox */
    .lightbox {
      display: none; position: fixed; inset: 0; z-index: 1000;
      background: rgba(0,0,0,0.92); align-items: center; justify-content: center;
      flex-direction: column;
    }
    .lightbox.open { display: flex; }
    .lightbox img {
      max-width: 90vw; max-height: 75vh; object-fit: contain;
      border-radius: 0.5rem; box-shadow: 0 4px 24px rgba(0,0,0,0.5);
    }
    .lightbox .lb-caption {
      color: #f1f5f9; margin-top: 0.75rem; font-size: 0.875rem; text-align: center;
    }
    .lightbox .lb-close {
      position: absolute; top: 1rem; right: 1.5rem;
      color: #f1f5f9; font-size: 2rem; cursor: pointer; line-height: 1;
    }
    .lightbox .lb-nav {
      position: absolute; top: 50%; transform: translateY(-50%);
      color: #f1f5f9; font-size: 2.5rem; cursor: pointer; padding: 0.5rem;
      user-select: none; opacity: 0.7; transition: opacity 0.2s;
    }
    .lightbox .lb-nav:hover { opacity: 1; }
    .lightbox .lb-prev { left: 1.5rem; }
    .lightbox .lb-next { right: 1.5rem; }
    /* Overlay slider */
    .overlay-container {
      position: relative; display: inline-block; margin: 0 auto;
      max-width: 100%; overflow: hidden; border-radius: 0.25rem;
      border: 1px solid var(--color-border);
    }
    .overlay-container img {
      display: block; max-width: 100%; height: auto;
    }
    .overlay-actual {
      position: absolute; top: 0; left: 0; width: 100%; height: 100%;
      overflow: hidden;
    }
    .overlay-actual img {
      position: absolute; top: 0; left: 0; width: var(--full-width); height: auto;
    }
    .overlay-slider {
      position: absolute; top: 0; bottom: 0; width: 3px;
      background: var(--color-accent); cursor: ew-resize; z-index: 2;
    }
    .overlay-slider::after {
      content: ''; position: absolute; top: 50%; left: 50%;
      transform: translate(-50%, -50%);
      width: 20px; height: 20px; border-radius: 50%;
      background: var(--color-accent); border: 2px solid #fff;
      box-shadow: 0 2px 6px rgba(0,0,0,0.3);
    }
    .overlay-labels {
      display: flex; justify-content: space-between; padding: 0.25rem 0.5rem;
      font-size: 0.65rem; color: var(--color-text-muted); text-transform: uppercase;
    }
    /* Locale grouping in failures */
    .locale-group-header {
      padding: 0.5rem 1rem; font-size: 0.8rem; font-weight: 600;
      background: var(--color-border); color: var(--color-text-muted);
      text-transform: uppercase; letter-spacing: 0.05em;
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

  <div class="toolbar">
    <div class="toolbar-group">
      <label>Quick Filter</label>
      <div class="btn-group" id="quick-filter">
        <button class="active" onclick="setQuickFilter('all')">All</button>
        <button onclick="setQuickFilter('failures')">Failures Only</button>
      </div>
    </div>
    <div class="toolbar-group">
      <label>Group By</label>
      <div class="btn-group" id="group-toggle">
        <button class="active" onclick="setGroupBy('feature')">Feature</button>
        <button onclick="setGroupBy('locale')">Locale</button>
      </div>
    </div>
    <div class="toolbar-group">
      <input type="text" class="search-box" id="searchBox" placeholder="Search tests..." oninput="renderResults()">
    </div>
  </div>

  <div class="filters" id="filterBar"></div>
  <div class="results" id="resultsContainer"></div>

  <div class="lightbox" id="lightbox">
    <span class="lb-close" onclick="closeLightbox()">&times;</span>
    <span class="lb-nav lb-prev" onclick="navLightbox(-1)">&lsaquo;</span>
    <span class="lb-nav lb-next" onclick="navLightbox(1)">&rsaquo;</span>
    <img id="lb-img" src="" alt="">
    <div class="lb-caption" id="lb-caption"></div>
  </div>

  <script>
    const DATA = ${jsonEncode(result)};
    let currentGroupBy = 'feature';
    let quickFilter = 'all';

    function init() {
      renderSummary();
      renderCoverage();
      renderFilters();
      renderResults();
    }

    function setQuickFilter(mode) {
      quickFilter = mode;
      document.querySelectorAll('#quick-filter button').forEach(b => b.classList.remove('active'));
      const idx = mode === 'all' ? 0 : 1;
      document.querySelectorAll('#quick-filter button')[idx].classList.add('active');
      if (mode === 'failures') {
        document.querySelectorAll('input[name="result"]').forEach(cb => {
          cb.checked = cb.value === 'error';
        });
      } else {
        document.querySelectorAll('input[name="result"]').forEach(cb => { cb.checked = true; });
      }
      renderResults();
    }

    function setGroupBy(mode) {
      currentGroupBy = mode;
      document.querySelectorAll('#group-toggle button').forEach(b => b.classList.remove('active'));
      const idx = mode === 'feature' ? 0 : 1;
      document.querySelectorAll('#group-toggle button')[idx].classList.add('active');
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
      const locales = [...new Set(DATA.tests.map(t => t.locale).filter(Boolean))].sort();
      const devices = [...new Set(DATA.tests.map(t => t.deviceType).filter(Boolean))].sort();
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
      const search = (document.getElementById('searchBox')?.value || '').toLowerCase();
      return { locales, devices, results, search };
    }

    function renderResults() {
      const filters = getFilters();
      const tests = DATA.tests.filter(function(t) {
        if (!filters.locales.includes(t.locale)) return false;
        if (!filters.devices.includes(t.deviceType)) return false;
        if (!filters.results.includes(t.result)) return false;
        if (filters.search) {
          const name = (t.tsName || t.name || '').toLowerCase();
          const feature = (t.testCaseFilePath || '').toLowerCase();
          if (!name.includes(filters.search) && !feature.includes(filters.search)) return false;
        }
        return true;
      });

      const groups = {};
      tests.forEach(function(t) {
        let groupKey;
        if (currentGroupBy === 'locale') {
          groupKey = t.locale || 'unknown';
        } else {
          const path = t.testCaseFilePath || '';
          const match = path.match(/page\\/([^/]+)/);
          groupKey = match ? match[1] : 'other';
        }
        if (!groups[groupKey]) groups[groupKey] = [];
        groups[groupKey].push(t);
      });

      let html = '';
      const sortedGroups = Object.keys(groups).sort();
      sortedGroups.forEach(function(groupName) {
        const groupTests = groups[groupName];
        const failCount = groupTests.filter(t => t.result === 'error').length;
        const badgeClass = failCount > 0 ? 'badge-fail' : 'badge-pass';
        const badgeText = failCount > 0 ? failCount + ' failed' : 'all pass';

        html += '<div class="feature-group">';
        html += '<div class="feature-header" onclick="toggleFeature(this)">';
        html += '<span>' + groupName + ' (' + groupTests.length + ')</span>';
        html += '<span class="feature-badge ' + badgeClass + '">' + badgeText + '</span>';
        html += '</div>';
        html += '<div class="feature-body' + (failCount > 0 ? ' open' : '') + '">';

        // Sub-group by locale when grouped by feature (for cross-locale failure view)
        if (currentGroupBy === 'feature' && failCount > 0) {
          const localeGroups = {};
          groupTests.forEach(function(t) {
            const loc = t.locale || 'unknown';
            if (!localeGroups[loc]) localeGroups[loc] = [];
            localeGroups[loc].push(t);
          });
          const sortedLocales = Object.keys(localeGroups).sort();
          const hasMultipleLocales = sortedLocales.length > 1;

          sortedLocales.forEach(function(loc) {
            if (hasMultipleLocales) {
              const locFails = localeGroups[loc].filter(t => t.result === 'error').length;
              html += '<div class="locale-group-header">' + loc + (locFails > 0 ? ' (' + locFails + ' failed)' : ' (all pass)') + '</div>';
            }
            localeGroups[loc].forEach(function(t) { html += renderTestRow(t); });
          });
        } else {
          groupTests.forEach(function(t) { html += renderTestRow(t); });
        }

        html += '</div></div>';
      });

      document.getElementById('resultsContainer').innerHTML = html;
      initOverlaySliders();
    }

    function renderTestRow(t) {
      const isPass = t.result === 'success';
      const icon = isPass ? '&#10003;' : '&#10007;';
      const iconClass = isPass ? 'pass' : 'fail';
      const rowClass = isPass ? '' : ' fail';
      const name = t.tsName || t.name || 'unknown';

      let html = '<div class="test-row' + rowClass + '">';
      html += '<span class="test-icon ' + iconClass + '">' + icon + '</span>';
      html += '<span class="test-name">' + escapeHtml(name) + '</span>';
      html += '<span class="test-meta">' + (t.deviceType || '') + ' / ' + (t.locale || '') + '</span>';
      html += '</div>';

      if (!isPass) {
        html += '<div class="failure-details">';
        if (t.failureImages) {
          // Standard 3-column comparison
          html += '<div class="image-comparison">';
          html += renderImage('Expected', t.failureImages.expected);
          html += renderImage('Actual', t.failureImages.actual);
          html += renderImage('Diff', t.failureImages.diff);
          html += '</div>';
          // Overlay slider (expected vs actual)
          if (t.failureImages.expected && t.failureImages.actual) {
            html += '<div style="margin-top:0.75rem;">';
            html += '<div class="overlay-labels"><span>Expected</span><span>Actual</span></div>';
            html += '<div class="overlay-container" data-overlay>';
            html += '<img src="' + t.failureImages.expected + '" class="overlay-base" alt="Expected">';
            html += '<div class="overlay-actual" style="width:50%"><img src="' + t.failureImages.actual + '" alt="Actual"></div>';
            html += '<div class="overlay-slider" style="left:50%"></div>';
            html += '</div>';
            html += '</div>';
          }
        }
        if (t.messages && t.messages.length > 0) {
          html += '<div class="error-message">' + escapeHtml(t.messages.join('\\n')) + '</div>';
        }
        html += '</div>';
      }
      return html;
    }

    function renderImage(label, src) {
      if (!src) return '<figure><figcaption>' + label + '</figcaption><div style="padding:2rem;color:var(--color-text-muted)">N/A</div></figure>';
      return '<figure><figcaption>' + label + '</figcaption><img src="' + src + '" alt="' + label + '" loading="lazy" onclick="openLightbox(this)"></figure>';
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

    // Lightbox
    let lbImages = [];
    let lbIndex = 0;

    function openLightbox(img) {
      lbImages = [...document.querySelectorAll('.image-comparison img[onclick]')];
      lbIndex = lbImages.indexOf(img);
      if (lbIndex === -1) lbIndex = 0;
      showLightboxImage();
      document.getElementById('lightbox').classList.add('open');
    }

    function closeLightbox() {
      document.getElementById('lightbox').classList.remove('open');
    }

    function navLightbox(dir) {
      lbIndex = (lbIndex + dir + lbImages.length) % lbImages.length;
      showLightboxImage();
    }

    function showLightboxImage() {
      const img = lbImages[lbIndex];
      document.getElementById('lb-img').src = img.src;
      const figure = img.closest('figure');
      const label = figure ? figure.querySelector('figcaption')?.textContent || '' : '';
      const details = figure ? figure.closest('.failure-details') : null;
      const row = details ? details.previousElementSibling : null;
      const testName = row ? row.querySelector('.test-name')?.textContent || '' : '';
      const pos = (lbIndex + 1) + '/' + lbImages.length;
      document.getElementById('lb-caption').textContent = pos + ' — ' + testName + ' (' + label + ')';
    }

    document.addEventListener('keydown', (e) => {
      const lb = document.getElementById('lightbox');
      if (!lb.classList.contains('open')) return;
      if (e.key === 'Escape') closeLightbox();
      else if (e.key === 'ArrowLeft') navLightbox(-1);
      else if (e.key === 'ArrowRight') navLightbox(1);
    });

    document.getElementById('lightbox').addEventListener('click', (e) => {
      if (e.target === document.getElementById('lightbox')) closeLightbox();
    });

    // Overlay slider interaction
    function initOverlaySliders() {
      document.querySelectorAll('[data-overlay]').forEach(container => {
        const slider = container.querySelector('.overlay-slider');
        const actualLayer = container.querySelector('.overlay-actual');
        if (!slider || !actualLayer) return;

        let dragging = false;
        const onMove = (e) => {
          if (!dragging) return;
          const rect = container.getBoundingClientRect();
          let x = (e.clientX || e.touches[0].clientX) - rect.left;
          x = Math.max(0, Math.min(x, rect.width));
          const pct = (x / rect.width) * 100;
          slider.style.left = pct + '%';
          actualLayer.style.width = pct + '%';
        };
        slider.addEventListener('mousedown', () => { dragging = true; });
        slider.addEventListener('touchstart', () => { dragging = true; });
        document.addEventListener('mouseup', () => { dragging = false; });
        document.addEventListener('touchend', () => { dragging = false; });
        document.addEventListener('mousemove', onMove);
        document.addEventListener('touchmove', onMove);

        // Set actual image width to container full width
        const baseImg = container.querySelector('.overlay-base');
        baseImg.addEventListener('load', () => {
          const actualImg = actualLayer.querySelector('img');
          actualImg.style.width = baseImg.offsetWidth + 'px';
          container.style.setProperty('--full-width', baseImg.offsetWidth + 'px');
        });
      });
    }

    document.addEventListener('DOMContentLoaded', init);
  </script>
</body>
</html>
''';
}
