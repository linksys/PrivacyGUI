part of 'combine_results.dart';

String generateHTMLReport(Map<String, dynamic> result, String version) {
  final timestamp = result['timestamp'] ?? DateTime.now().toIso8601String();

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
      display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem;
      margin-bottom: 1.5rem;
      padding: 1rem;
      background: var(--color-surface);
      border: 1px solid var(--color-border);
      border-radius: 0.75rem;
    }
    @media (max-width: 768px) { .filters { grid-template-columns: 1fr; } }
    .filter-group h3 { font-size: 0.75rem; text-transform: uppercase; color: var(--color-text-muted); margin-bottom: 0.5rem; }
    .filter-group .filter-actions { margin-bottom: 0.375rem; }
    .filter-group .filter-actions a {
      font-size: 0.7rem; color: var(--color-accent); cursor: pointer; margin-right: 0.75rem; text-decoration: none;
    }
    .filter-group .filter-actions a:hover { text-decoration: underline; }
    .filter-group .chip-container { display: flex; flex-wrap: wrap; gap: 0.375rem; }
    .filter-chip {
      display: inline-flex; align-items: center; padding: 0.25rem 0.75rem;
      font-size: 0.8rem; border-radius: 9999px; cursor: pointer; user-select: none;
      border: 1px solid var(--color-border); background: var(--color-bg); color: var(--color-text-muted);
      transition: all 0.15s;
    }
    .filter-chip:hover { border-color: var(--color-accent); }
    .filter-chip.active {
      background: var(--color-accent); color: #fff; border-color: var(--color-accent);
    }
    .filter-chip input { display: none; }
    .back-to-top {
      position: fixed; bottom: 2rem; right: 2rem; z-index: 900;
      width: 44px; height: 44px; border-radius: 50%;
      background: var(--color-accent); color: #fff; border: none;
      font-size: 1.25rem; cursor: pointer; display: none;
      align-items: center; justify-content: center;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
      transition: opacity 0.2s;
    }
    .back-to-top.visible { display: flex; }
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
    .view-golden {
      font-size: 0.75rem; color: var(--color-accent); cursor: pointer;
      margin-right: 0.75rem; text-decoration: none; white-space: nowrap;
    }
    .view-golden:hover { text-decoration: underline; }
    .overflow-badge {
      font-size: 0.65rem; padding: 0.125rem 0.375rem;
      border-radius: 3px; background: #fef3c7; color: #92400e;
      font-weight: 600; margin-left: 0.5rem;
    }
    .overflow-sites {
      padding: 0.375rem 1rem 0.5rem 2.25rem;
      background: var(--color-surface);
      border-top: 1px dashed var(--color-border);
    }
    .overflow-site {
      font-size: 0.7rem; color: #92400e; font-family: ui-monospace, monospace;
      word-break: break-all; cursor: help;
    }
    .raw-log-btn {
      font-size: 0.6rem; padding: 0 0.3rem; margin-left: 0.4rem;
      border: 1px solid currentColor; border-radius: 3px; background: none;
      color: inherit; cursor: pointer; font-family: inherit; opacity: 0.75;
      vertical-align: 1px;
    }
    .raw-log-btn:hover { opacity: 1; }
    /* Raw log viewer: an overlay rather than an inline expander so the row
       keeps its height — a dump runs ~37 lines and would bury the table. */
    .log-modal {
      display: none; position: fixed; inset: 0; z-index: 1100;
      background: rgba(0,0,0,0.7); align-items: center; justify-content: center;
      padding: 2rem;
    }
    .log-modal.open { display: flex; }
    .log-modal .lm-panel {
      background: var(--color-bg); border: 1px solid var(--color-border);
      border-radius: 0.5rem; width: min(900px, 100%); max-height: 85vh;
      display: flex; flex-direction: column; overflow: hidden;
    }
    .log-modal .lm-head {
      display: flex; align-items: center; gap: 0.75rem;
      padding: 0.75rem 1rem; border-bottom: 1px solid var(--color-border);
    }
    .log-modal .lm-title {
      font-size: 0.8rem; font-weight: 600; flex: 1;
      font-family: ui-monospace, monospace; word-break: break-all;
    }
    .log-modal .lm-copy {
      font-size: 0.7rem; padding: 0.25rem 0.6rem; cursor: pointer;
      border: 1px solid var(--color-border); border-radius: 0.25rem;
      background: var(--color-surface); color: inherit; white-space: nowrap;
    }
    .log-modal .lm-close {
      font-size: 1.5rem; line-height: 1; cursor: pointer; opacity: 0.6;
    }
    .log-modal .lm-close:hover { opacity: 1; }
    .log-modal pre {
      margin: 0; padding: 1rem; overflow: auto; flex: 1;
      font-size: 0.7rem; line-height: 1.5; white-space: pre-wrap;
      word-break: break-word; font-family: ui-monospace, monospace;
    }
    @media (prefers-color-scheme: dark) {
      .overflow-badge { background: #78350f; color: #fde68a; }
      .overflow-site { color: #fbbf24; }
    }
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
      flex-direction: column; overflow: hidden;
    }
    .lightbox.open { display: flex; }
    .lightbox .lb-img-container {
      max-width: 90vw; max-height: 75vh; overflow: auto;
      cursor: default; position: relative;
    }
    .lightbox .lb-img-container.zoomed { cursor: grab; }
    .lightbox .lb-img-container.zoomed:active { cursor: grabbing; }
    .lightbox .lb-img-container img {
      display: block; max-width: 90vw; max-height: 75vh; object-fit: contain;
      border-radius: 0.5rem; box-shadow: 0 4px 24px rgba(0,0,0,0.5);
    }
    .lightbox .lb-img-container.zoomed img {
      max-width: none; max-height: none;
    }
    .lightbox .lb-caption {
      color: #f1f5f9; margin-top: 0.75rem; font-size: 0.875rem; text-align: center;
    }
    .lightbox .lb-zoom-hint {
      color: #94a3b8; font-size: 0.7rem; margin-top: 0.25rem;
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

  <!-- Hidden unless `overflowReportUnreadable` is set, i.e. the file existed and
       did not parse. A run that overflowed nothing writes no file at all and is
       not this case. -->
  <div id="overflowUnreadable" style="display:none;margin:0 0 12px;padding:10px 14px;border-left:4px solid #f59e0b;background:#fffbeb;color:#92400e;border-radius:4px"></div>

  <div class="panels">
    <div class="panel">
      <h2>Test Summary</h2>
      <div class="stats">
        <div class="stat-item"><div class="stat-value" id="totalCount">0</div><div class="stat-label">Total</div></div>
        <div class="stat-item stat-pass"><div class="stat-value" id="passCount">0</div><div class="stat-label">Pass</div></div>
        <div class="stat-item stat-fail"><div class="stat-value" id="failCount">0</div><div class="stat-label">Fail</div></div>
        <!-- Hidden while zero, which is every healthy run: a tile that reads 0
             forever teaches a reader to stop looking at it. -->
        <div class="stat-item" id="incompleteTile" style="display:none"><div class="stat-value" id="incompleteCount" style="color:#f59e0b">0</div><div class="stat-label">Incomplete</div></div>
        <div class="stat-item"><div class="stat-value" id="overflowCount" style="color:#f59e0b">0</div><div class="stat-label">Overflow</div></div>
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
        <button onclick="setQuickFilter('overflow')">Overflow Only</button>
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

  <button class="back-to-top" id="backToTop" onclick="window.scrollTo({top:0,behavior:'smooth'})">&uarr;</button>

  <div class="lightbox" id="lightbox">
    <span class="lb-close" onclick="closeLightbox()">&times;</span>
    <span class="lb-nav lb-prev" onclick="navLightbox(-1)">&lsaquo;</span>
    <span class="lb-nav lb-next" onclick="navLightbox(1)">&rsaquo;</span>
    <div class="lb-img-container" id="lb-container">
      <img id="lb-img" src="" alt="">
    </div>
    <div class="lb-caption" id="lb-caption"></div>
    <div class="lb-zoom-hint">Scroll to zoom &middot; Click image to reset</div>
  </div>

  <div class="log-modal" id="logModal">
    <div class="lm-panel">
      <div class="lm-head">
        <span class="lm-title" id="lm-title"></span>
        <button class="lm-copy" id="lm-copy" onclick="copyRawLog()">Copy</button>
        <span class="lm-close" onclick="closeRawLog()">&times;</span>
      </div>
      <pre id="lm-body"></pre>
    </div>
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
      const idx = mode === 'all' ? 0 : mode === 'failures' ? 1 : 2;
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
      // Tests that started and never reported a result — a suite killed mid-run.
      // Surfaced because Total counts them, so without this tile the panel would
      // show a Total that Pass and Fail cannot add up to and give no clue why
      // (#1404). `|| 0` covers a report generated before the bucket existed.
      const incomplete = c.incomplete || 0;
      document.getElementById('incompleteTile').style.display =
        incomplete > 0 ? '' : 'none';
      document.getElementById('incompleteCount').textContent = incomplete;
      // A '?' rather than a 0 when the overflow report could not be read. Zero is
      // a measurement and this is the absence of one, and the two used to render
      // identically — a run full of overflows read as all-clean off this tile.
      const overflowUnknown = !!DATA.overflowReportUnreadable;
      const overflowTile = document.getElementById('overflowCount');
      overflowTile.textContent = overflowUnknown ? '?' : (DATA.overflowCount || 0);
      overflowTile.title = overflowUnknown
        ? DATA.overflowReportUnreadable
        : '';
      const banner = document.getElementById('overflowUnreadable');
      banner.style.display = overflowUnknown ? 'block' : 'none';
      if (overflowUnknown) {
        banner.textContent =
          'Overflow detail unavailable: ' + DATA.overflowReportUnreadable;
      }
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
      html += '<div class="filter-actions"><a onclick="toggleAll(' + "'locale'" + ',true)">All</a><a onclick="toggleAll(' + "'locale'" + ',false)">None</a></div>';
      html += '<div class="chip-container">';
      locales.forEach(function(l) { html += '<label class="filter-chip active"><input type="checkbox" name="locale" value="' + l + '" checked onchange="toggleChip(this)">' + l + '</label>'; });
      html += '</div></div>';

      html += '<div class="filter-group"><h3>Device</h3>';
      html += '<div class="filter-actions"><a onclick="toggleAll(' + "'device'" + ',true)">All</a><a onclick="toggleAll(' + "'device'" + ',false)">None</a></div>';
      html += '<div class="chip-container">';
      const standardDevices = devices.filter(d => d.startsWith('phone') || d.startsWith('desktop'));
      const componentDevices = devices.filter(d => !d.startsWith('phone') && !d.startsWith('desktop'));
      standardDevices.forEach(function(d) { html += '<label class="filter-chip active"><input type="checkbox" name="device" value="' + d + '" checked onchange="toggleChip(this)">' + d + '</label>'; });
      if (componentDevices.length > 0) {
        html += '<label class="filter-chip active"><input type="checkbox" name="device" value="_components" checked onchange="toggleChip(this)">Components (' + componentDevices.length + ' sizes)</label>';
      }
      html += '</div></div>';

      html += '<div class="filter-group"><h3>Result</h3>';
      html += '<div class="filter-actions"><a onclick="toggleAll(' + "'result'" + ',true)">All</a><a onclick="toggleAll(' + "'result'" + ',false)">None</a></div>';
      html += '<div class="chip-container">';
      html += '<label class="filter-chip active"><input type="checkbox" name="result" value="success" checked onchange="toggleChip(this)">Pass</label>';
      html += '<label class="filter-chip active"><input type="checkbox" name="result" value="error" checked onchange="toggleChip(this)">Fail</label>';
      html += '</div></div>';

      bar.innerHTML = html;
    }

    function toggleChip(input) {
      const chip = input.closest('.filter-chip');
      chip.classList.toggle('active', input.checked);
      renderResults();
    }

    function isStandardDevice(d) {
      return d.startsWith('phone') || d.startsWith('desktop');
    }

    function getFilters() {
      const locales = [...document.querySelectorAll('input[name="locale"]:checked')].map(e => e.value);
      const rawDevices = [...document.querySelectorAll('input[name="device"]:checked')].map(e => e.value);
      const includeComponents = rawDevices.includes('_components');
      const standardDevices = rawDevices.filter(d => d !== '_components');
      const results = [...document.querySelectorAll('input[name="result"]:checked')].map(e => e.value);
      const search = (document.getElementById('searchBox')?.value || '').toLowerCase();
      return { locales, standardDevices, includeComponents, results, search };
    }

    function matchDevice(device, filters) {
      if (isStandardDevice(device)) return filters.standardDevices.includes(device);
      return filters.includeComponents;
    }

    function renderResults() {
      const filters = getFilters();
      const tests = DATA.tests.filter(function(t) {
        if (!filters.locales.includes(t.locale)) return false;
        if (!matchDevice(t.deviceType || '', filters)) return false;
        if (!filters.results.includes(t.result)) return false;
        if (quickFilter === 'overflow' && !t.hasOverflow) return false;
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
    }

    function renderTestRow(t) {
      const isPass = t.result === 'success';
      const icon = isPass ? '&#10003;' : '&#10007;';
      const iconClass = isPass ? 'pass' : 'fail';
      const rowClass = isPass ? '' : ' fail';
      const name = t.tsName || t.name || 'unknown';
      const overflowTag = t.hasOverflow ? '<span class="overflow-badge">OVERFLOW</span>' : '';

      let html = '<div class="test-row' + rowClass + '" data-overflow="' + (t.hasOverflow ? 'true' : 'false') + '">';
      html += '<span class="test-icon ' + iconClass + '">' + icon + '</span>';
      html += '<span class="test-name">' + escapeHtml(name) + overflowTag + '</span>';
      if (isPass && t.goldenPath) {
        const goldenCaption = name + ' (' + (t.deviceType || '') + ' / ' + (t.locale || '') + ')';
        html += '<a class="view-golden" data-golden-src="' + escapeHtml(t.goldenPath) + '" data-golden-caption="' + escapeHtml(goldenCaption) + '" onclick="openGolden(this)">View golden</a>';
      }
      html += '<span class="test-meta">' + (t.deviceType || '') + ' / ' + (t.locale || '') + '</span>';
      html += '</div>';

      // Outside the !isPass block: an overflow does not fail the test, so the
      // detail has to render on passing rows too — that is where it was
      // previously invisible beyond the badge (#1197).
      // A site with neither a label nor a log has nothing to show beyond the
      // badge above, so it is skipped rather than rendered as a blank line.
      const sites = (t.overflowSites || []).filter(s => s.label || s.logIndex != null);
      if (sites.length > 0) {
        html += '<div class="overflow-sites">';
        for (const site of sites) {
          const where = (site.file || '') + (site.line ? ':' + site.line : '');
          // Falls back to the amount-less message when nothing parsed: the row
          // still needs something to hang the raw log button on, and that case
          // is exactly when the log matters most.
          const text = site.label || 'location unresolved';
          html += '<div class="overflow-site" title="' + escapeAttr(where + '\\n' + (site.message || '')) + '">' + escapeHtml(text) + renderRawLogButton(site) + '</div>';
        }
        html += '</div>';
      }

      if (!isPass) {
        html += '<div class="failure-details">';
        if (t.failureImages) {
          // Standard 3-column comparison
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
      return html;
    }

    function renderImage(label, src) {
      if (!src) return '<figure><figcaption>' + label + '</figcaption><div style="padding:2rem;color:var(--color-text-muted)">N/A</div></figure>';
      return '<figure><figcaption>' + label + '</figcaption><img src="' + escapeHtml(src) + '" alt="' + label + '" loading="lazy" onclick="openLightbox(this)"></figure>';
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

    // escapeHtml goes through textContent, which leaves quotes intact — fine in
    // element content, but it would break out of an attribute. Flutter's raw
    // overflow message is arbitrary text, so tooltips use this instead.
    function escapeAttr(text) {
      return String(text == null ? '' : text)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;')
        .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    // Raw log viewer.
    //
    // The dumps live in one table and the button carries only an index, because
    // a single culprit appears in every golden that renders it and a dump runs
    // 2-4KB. Inlining it per row would multiply the report for no added detail.
    // The title travels in a data attribute rather than as an inline call
    // argument: it is generated text that would otherwise need quoting for both
    // HTML and JavaScript at once.
    function renderRawLogButton(site) {
      if (site.logIndex == null) return '';
      return '<button class="raw-log-btn" data-log-index="' + site.logIndex + '" data-log-title="' + escapeAttr(site.label || 'Overflow raw log') + '" onclick="openRawLog(this)">raw log</button>';
    }

    function openRawLog(btn) {
      const log = (DATA.overflowLogs || [])[Number(btn.dataset.logIndex)];
      if (log == null) return;
      document.getElementById('lm-title').textContent = btn.dataset.logTitle || 'Overflow raw log';
      document.getElementById('lm-body').textContent = log;
      document.getElementById('lm-copy').textContent = 'Copy';
      document.getElementById('logModal').classList.add('open');
    }

    function closeRawLog() {
      document.getElementById('logModal').classList.remove('open');
    }

    function copyRawLog() {
      const btn = document.getElementById('lm-copy');
      const text = document.getElementById('lm-body').textContent;
      // Reports are opened over file:// as often as over http://, and the async
      // clipboard API is unavailable on an insecure origin, so fall back to a
      // throwaway textarea rather than silently doing nothing.
      const done = () => { btn.textContent = 'Copied'; };
      if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(text).then(done, () => legacyCopy(text, done));
      } else {
        legacyCopy(text, done);
      }
    }

    function legacyCopy(text, done) {
      const area = document.createElement('textarea');
      area.value = text;
      area.style.position = 'fixed';
      area.style.opacity = '0';
      document.body.appendChild(area);
      area.select();
      try { document.execCommand('copy'); done(); } catch (e) { /* nothing to do */ }
      document.body.removeChild(area);
    }

    document.getElementById('logModal').addEventListener('click', (e) => {
      if (e.target === document.getElementById('logModal')) closeRawLog();
    });

    // Lightbox — holds a list of { src, caption } items
    let lbImages = [];
    let lbIndex = 0;

    // Open the comparison images (expected/actual/diff) with cross-image nav
    function openLightbox(img) {
      const nodes = [...document.querySelectorAll('.image-comparison img[onclick]')];
      lbImages = nodes.map(function(node) {
        const figure = node.closest('figure');
        const label = figure ? figure.querySelector('figcaption')?.textContent || '' : '';
        const details = figure ? figure.closest('.failure-details') : null;
        const row = details ? details.previousElementSibling : null;
        const testName = row ? row.querySelector('.test-name')?.textContent || '' : '';
        return { src: node.src, caption: testName + ' (' + label + ')' };
      });
      lbIndex = nodes.indexOf(img);
      if (lbIndex === -1) lbIndex = 0;
      openLightboxAt(lbImages, lbIndex);
    }

    // Open a single golden image (no cross-image nav)
    function openGolden(link) {
      const src = link.getAttribute('data-golden-src');
      const caption = link.getAttribute('data-golden-caption') || '';
      openLightboxAt([{ src: src, caption: caption }], 0);
    }

    function openLightboxAt(images, index) {
      lbImages = images;
      lbIndex = index;
      const single = lbImages.length <= 1;
      document.querySelector('.lb-prev').style.display = single ? 'none' : '';
      document.querySelector('.lb-next').style.display = single ? 'none' : '';
      showLightboxImage();
      document.getElementById('lightbox').classList.add('open');
    }

    function closeLightbox() {
      document.getElementById('lightbox').classList.remove('open');
    }

    function navLightbox(dir) {
      if (lbImages.length <= 1) return;
      lbIndex = (lbIndex + dir + lbImages.length) % lbImages.length;
      showLightboxImage();
    }

    var showLightboxImage = function() {
      const item = lbImages[lbIndex];
      if (!item) return;
      document.getElementById('lb-img').src = item.src;
      const pos = lbImages.length > 1 ? (lbIndex + 1) + '/' + lbImages.length + ' — ' : '';
      document.getElementById('lb-caption').textContent = pos + item.caption;
    };

    document.addEventListener('keydown', (e) => {
      // The log modal sits above the lightbox, so it claims Escape first.
      if (document.getElementById('logModal').classList.contains('open')) {
        if (e.key === 'Escape') closeRawLog();
        return;
      }
      const lb = document.getElementById('lightbox');
      if (!lb.classList.contains('open')) return;
      if (e.key === 'Escape') closeLightbox();
      else if (e.key === 'ArrowLeft') navLightbox(-1);
      else if (e.key === 'ArrowRight') navLightbox(1);
    });

    document.getElementById('lightbox').addEventListener('click', (e) => {
      if (e.target === document.getElementById('lightbox')) closeLightbox();
    });

    function toggleAll(name, checked) {
      document.querySelectorAll('input[name="' + name + '"]').forEach(cb => {
        cb.checked = checked;
        const chip = cb.closest('.filter-chip');
        if (chip) chip.classList.toggle('active', checked);
      });
      renderResults();
    }

    // Back-to-top scroll listener
    window.addEventListener('scroll', () => {
      const btn = document.getElementById('backToTop');
      if (window.scrollY > 400) btn.classList.add('visible');
      else btn.classList.remove('visible');
    });

    // Lightbox zoom (uses actual width/height for real scrollable overflow)
    (function() {
      const container = document.getElementById('lb-container');
      const lbImg = document.getElementById('lb-img');
      let scale = 1;
      let baseW = 0, baseH = 0;
      let panning = false;
      let didPan = false;
      let startX = 0, startY = 0, scrollLeftStart = 0, scrollTopStart = 0;

      function captureBase() {
        baseW = lbImg.naturalWidth;
        baseH = lbImg.naturalHeight;
        const maxW = window.innerWidth * 0.9;
        const maxH = window.innerHeight * 0.75;
        const ratio = Math.min(maxW / baseW, maxH / baseH, 1);
        baseW = baseW * ratio;
        baseH = baseH * ratio;
      }

      function applyZoom() {
        if (scale <= 1) {
          lbImg.style.width = '';
          lbImg.style.height = '';
          container.classList.remove('zoomed');
          container.scrollTo(0, 0);
        } else {
          lbImg.style.width = (baseW * scale) + 'px';
          lbImg.style.height = (baseH * scale) + 'px';
          container.classList.add('zoomed');
        }
      }

      function resetZoom() {
        scale = 1;
        applyZoom();
      }

      container.addEventListener('wheel', (e) => {
        e.preventDefault();
        if (!baseW) captureBase();
        const rect = container.getBoundingClientRect();
        const mx = e.clientX - rect.left + container.scrollLeft;
        const my = e.clientY - rect.top + container.scrollTop;
        const prevScale = scale;
        const delta = e.deltaY > 0 ? -0.25 : 0.25;
        scale = Math.max(1, Math.min(scale + delta, 6));
        applyZoom();
        if (scale > 1 && prevScale > 1) {
          const factor = scale / prevScale;
          container.scrollLeft = mx * factor - (e.clientX - rect.left);
          container.scrollTop = my * factor - (e.clientY - rect.top);
        }
      }, { passive: false });

      lbImg.addEventListener('click', (e) => {
        if (didPan) { e.stopPropagation(); didPan = false; return; }
        if (scale > 1) { e.stopPropagation(); resetZoom(); }
      });

      container.addEventListener('mousedown', (e) => {
        if (scale <= 1) return;
        panning = true;
        didPan = false;
        startX = e.clientX;
        startY = e.clientY;
        scrollLeftStart = container.scrollLeft;
        scrollTopStart = container.scrollTop;
        e.preventDefault();
      });

      document.addEventListener('mousemove', (e) => {
        if (!panning) return;
        const dx = e.clientX - startX;
        const dy = e.clientY - startY;
        if (Math.abs(dx) > 3 || Math.abs(dy) > 3) didPan = true;
        container.scrollLeft = scrollLeftStart - dx;
        container.scrollTop = scrollTopStart - dy;
      });

      document.addEventListener('mouseup', () => { panning = false; });

      // Reset zoom when navigating or opening new image
      const origShow = showLightboxImage;
      showLightboxImage = function() { resetZoom(); baseW = 0; origShow(); };
    })();

    document.addEventListener('DOMContentLoaded', init);
  </script>
</body>
</html>
''';
}
