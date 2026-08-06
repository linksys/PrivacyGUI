// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'overflow_details.dart';

/// Scans golden PNG files under test/golden_test/page/*/localizations/goldens/
/// and generates an HTML gallery report at test/golden_test/golden_gallery_report.html.
///
/// Usage: dart run test_scripts/generate_gallery_report.dart [version]
void main(List<String> args) {
  final version = args.isNotEmpty ? args[0] : '0.0.0';
  final baseDir = Directory('test/golden_test/page');

  if (!baseDir.existsSync()) {
    print('Directory test/golden_test/page does not exist');
    exit(1);
  }

  final entries = <_GoldenEntry>[];

  final pngFiles = baseDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.png') && f.path.contains('/goldens/'));

  for (final file in pngFiles) {
    final entry = _parseGoldenFile(file.path);
    if (entry != null) entries.add(entry);
  }

  entries.sort((a, b) {
    final cmp = a.feature.compareTo(b.feature);
    if (cmp != 0) return cmp;
    final cmp2 = a.viewName.compareTo(b.viewName);
    if (cmp2 != 0) return cmp2;
    final cmp3 = a.state.compareTo(b.state);
    if (cmp3 != 0) return cmp3;
    final cmp4 = a.device.compareTo(b.device);
    if (cmp4 != 0) return cmp4;
    return a.locale.compareTo(b.locale);
  });

  final overflowReport = loadOverflowReport();

  final html = _generateHtml(entries, version, overflowReport);
  final outputFile = File('test/golden_test/golden_gallery_report.html');
  outputFile.writeAsStringSync(html);
  print(
      'Gallery report generated: ${outputFile.path} (${entries.length} images)');
}

class _GoldenEntry {
  final String feature;
  final String viewName;
  final String state;
  final String device;
  final String locale;
  final String brightness;
  final String relativePath;

  _GoldenEntry({
    required this.feature,
    required this.viewName,
    required this.state,
    required this.device,
    required this.locale,
    required this.brightness,
    required this.relativePath,
  });
}

_GoldenEntry? _parseGoldenFile(String fullPath) {
  // Extract feature from path: .../page/{feature}/localizations/goldens/xxx.png
  final pathSegments = fullPath.split('/');
  final pageIdx = pathSegments.indexOf('page');
  if (pageIdx == -1 || pageIdx + 1 >= pathSegments.length) return null;
  final feature = pathSegments[pageIdx + 1];

  final fileName = pathSegments.last.replaceAll('.png', '');

  // Format: {viewName}-{stateKey}-{deviceName}-{locale}[-dark]
  final parts = fileName.split('-');
  if (parts.length < 4) return null;

  var brightness = 'light';
  var workingParts = List<String>.from(parts);
  if (workingParts.last == 'dark') {
    brightness = 'dark';
    workingParts.removeLast();
  }

  final locale = workingParts.removeLast();
  final device = workingParts.removeLast();

  // The remaining parts: first segment is viewName, rest is stateKey
  // viewName is the first underscore-delimited word group before the first '-'
  // But since viewName itself can have underscores, we rely on the known
  // pattern: viewName matches the feature directory name (or a prefix of parts)
  // Simplest: split into viewName (first element) and state (rest joined by '-')
  // Actually viewName can span multiple '-' segments if it has underscores...
  // The golden_runner uses: '$viewName-$stateKey-${device.name}-$localeTag'
  // where localeTag is the languageCode, or 'languageCode_COUNTRY' for regional
  // variants (e.g. 'es_AR'). Every field uses '_' internally — never '-' — so
  // the country code stays attached to the locale segment after the split.
  // Where viewName is snake_case (uses _ not -) and stateKey is snake_case (uses _ not -)
  // So the only '-' separators in the filename are between the 4 main fields!
  // Wait no — viewName like "unified_diagnostics" uses underscores, not dashes.
  // So the filename has exactly: viewName-stateKey-device-locale with '-' as separator
  // and each field internally uses '_' only.
  // WRONG — from examples: unified_diagnostics-manual_tools_nslookup_idle-desktop1280-en
  // That has 4 dash-separated segments where each can contain underscores. ✓

  // So workingParts should have exactly 2 items left: [viewName, stateKey]
  // But wait — what if viewName or stateKey contains a '-'? They shouldn't — they're snake_case.
  // However the golden file shows they DON'T contain dashes. So we just join remaining.
  if (workingParts.isEmpty) return null;

  // If only 1 remaining part, viewName == state (unlikely but handle it)
  String viewName;
  String state;
  if (workingParts.length == 1) {
    viewName = workingParts[0];
    state = workingParts[0];
  } else {
    // viewName and stateKey are both snake_case — the filename has exactly
    // viewName-stateKey as first two dash-delimited segments
    viewName = workingParts[0];
    state = workingParts.sublist(1).join('-');
  }

  // relativePath from test/golden_test/ to the image
  final goldenTestIdx = fullPath.indexOf('test/golden_test/');
  final relativePath = goldenTestIdx != -1
      ? fullPath.substring(goldenTestIdx + 'test/golden_test/'.length)
      : fullPath;

  return _GoldenEntry(
    feature: feature,
    viewName: viewName,
    state: state,
    device: device,
    locale: locale,
    brightness: brightness,
    relativePath: relativePath,
  );
}

/// Derives the golden file name from an entry (matches golden_runner.dart format).
String _entryGoldenName(_GoldenEntry entry) {
  final base =
      '${entry.viewName}-${entry.state}-${entry.device}-${entry.locale}';
  if (entry.brightness == 'dark') return '$base-dark';
  return base;
}

/// Escapes text interpolated into HTML.
///
/// Overflow detail carries file paths and Flutter's raw message, so it is not
/// guaranteed free of markup characters.
String _escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Renders the button that opens [site]'s raw diagnostics dump.
///
/// Carries only an index into the report's log table: the same culprit appears
/// in every golden that renders it, and a dump runs 2-4KB, so inlining it per
/// card would multiply the report for no added detail. Empty when the record
/// predates log capture.
String _rawLogButton(OverflowDetail site) {
  if (site.logIndex == null) return '';
  final title =
      _escapeHtml(site.label.isEmpty ? 'Overflow raw log' : site.label);
  return '<button class="raw-log-btn" data-log-index="${site.logIndex}" '
      'data-log-title="$title" onclick="openRawLog(this)">raw log</button>';
}

String _generateHtml(
    List<_GoldenEntry> entries, String version, OverflowReport overflowReport) {
  final overflowDetails = overflowReport.byGolden;
  final features = <String>{};
  final locales = <String>{};
  final devices = <String>{};
  for (final e in entries) {
    features.add(e.feature);
    locales.add(e.locale);
    devices.add(e.device);
  }
  final sortedFeatures = features.toList()..sort();
  final sortedLocales = locales.toList()..sort();
  final sortedDevices = devices.toList()..sort();

  final timestamp = DateTime.now().toIso8601String();

  final buffer = StringBuffer();
  buffer.writeln('''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Golden Gallery Report $version</title>
  <style>
    :root {
      --color-bg: #ffffff;
      --color-surface: #f8fafc;
      --color-border: #e2e8f0;
      --color-text: #1e293b;
      --color-text-muted: #64748b;
      --color-accent: #3b82f6;
      --thumb-min: 200px;
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
    .summary {
      display: flex; gap: 2rem; margin-bottom: 2rem; padding: 1rem;
      background: var(--color-surface); border: 1px solid var(--color-border); border-radius: 0.75rem;
    }
    .summary-item { text-align: center; }
    .summary-value { font-size: 1.5rem; font-weight: 700; color: var(--color-accent); }
    .summary-label { font-size: 0.75rem; color: var(--color-text-muted); text-transform: uppercase; }
    .toolbar {
      display: flex; gap: 1.5rem; align-items: center; flex-wrap: wrap;
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
      background: var(--color-bg); color: var(--color-text); width: 200px;
    }
    .search-box::placeholder { color: var(--color-text-muted); }
    .filters {
      display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem;
      margin-bottom: 1.5rem; padding: 1rem;
      background: var(--color-surface); border: 1px solid var(--color-border); border-radius: 0.75rem;
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
    .feature-section {
      border: 1px solid var(--color-border); border-radius: 0.75rem;
      margin-bottom: 1rem; overflow: hidden;
    }
    .feature-header {
      display: flex; justify-content: space-between; align-items: center;
      padding: 0.75rem 1rem; background: var(--color-surface);
      cursor: pointer; user-select: none; font-weight: 600;
    }
    .feature-header:hover { background: var(--color-border); }
    .feature-count { font-size: 0.75rem; color: var(--color-text-muted); }
    .feature-body { display: none; padding: 1rem; }
    .feature-body.open { display: block; }
    .gallery-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(var(--thumb-min), 1fr));
      gap: 1rem;
    }
    .gallery-card {
      border: 1px solid var(--color-border); border-radius: 0.5rem;
      overflow: hidden; background: var(--color-surface);
    }
    .gallery-card img {
      width: 100%; height: auto; display: block;
      border-bottom: 1px solid var(--color-border);
      cursor: pointer;
    }
    .gallery-card .card-meta {
      padding: 0.5rem 0.75rem; font-size: 0.75rem;
    }
    .gallery-card .card-title {
      font-weight: 600; font-size: 0.8rem; margin-bottom: 0.25rem;
      word-break: break-all;
    }
    .gallery-card .card-tags {
      display: flex; gap: 0.375rem; flex-wrap: wrap;
    }
    .tag {
      font-size: 0.65rem; padding: 0.125rem 0.375rem;
      border-radius: 3px; background: var(--color-border); color: var(--color-text-muted);
    }
    .tag-overflow {
      font-size: 0.65rem; padding: 0.125rem 0.375rem;
      border-radius: 3px; background: #fef3c7; color: #92400e;
      font-weight: 600;
    }
    .card-overflow-sites {
      margin-top: 0.375rem; display: flex; flex-direction: column; gap: 0.125rem;
    }
    .overflow-site {
      font-size: 0.65rem; color: #92400e; font-family: ui-monospace, monospace;
      word-break: break-all; cursor: help;
    }
    .raw-log-btn {
      font-size: 0.6rem; padding: 0 0.3rem; margin-left: 0.3rem;
      border: 1px solid currentColor; border-radius: 3px; background: none;
      color: inherit; cursor: pointer; font-family: inherit; opacity: 0.75;
      vertical-align: 1px;
    }
    .raw-log-btn:hover { opacity: 1; }
    /* Raw log viewer: an overlay rather than an inline expander, because the
       cards are a grid — expanding one in place would reflow the whole row. */
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
      .tag-overflow { background: #78350f; color: #fde68a; }
      .overflow-site { color: #fbbf24; }
    }
    /* Comparison view */
    .compare-row {
      margin-bottom: 1.5rem; border: 1px solid var(--color-border);
      border-radius: 0.75rem; overflow: hidden;
    }
    .compare-row-header {
      padding: 0.5rem 1rem; background: var(--color-surface);
      font-weight: 600; font-size: 0.85rem; border-bottom: 1px solid var(--color-border);
    }
    .compare-row-body {
      display: flex; gap: 0; overflow-x: auto; padding: 0.75rem;
    }
    .compare-cell {
      flex: 0 0 auto; text-align: center; padding: 0 0.5rem;
    }
    .compare-cell img {
      height: 200px; width: auto; max-width: 300px; object-fit: contain;
      border: 1px solid var(--color-border); border-radius: 0.375rem;
      cursor: pointer;
    }
    .compare-cell .cell-label {
      font-size: 0.7rem; color: var(--color-text-muted); margin-top: 0.25rem;
    }
    body.size-s .compare-cell img { height: 140px; max-width: 200px; }
    body.size-l .compare-cell img { height: 300px; max-width: 450px; }
    #comparison-view { display: none; }
    /* Lightbox */
    .lightbox {
      display: none; position: fixed; inset: 0; z-index: 1000;
      background: rgba(0,0,0,0.9); align-items: center; justify-content: center;
      flex-direction: column; overflow: hidden;
    }
    .lightbox.open { display: flex; }
    .lightbox .lb-img-container {
      max-width: 90vw; max-height: 80vh; overflow: auto;
      cursor: default; position: relative;
    }
    .lightbox .lb-img-container.zoomed { cursor: grab; }
    .lightbox .lb-img-container.zoomed:active { cursor: grabbing; }
    .lightbox .lb-img-container img {
      display: block; max-width: 90vw; max-height: 80vh; object-fit: contain;
      border-radius: 0.5rem; box-shadow: 0 4px 24px rgba(0,0,0,0.5);
    }
    .lightbox .lb-img-container.zoomed img {
      max-width: none; max-height: none;
    }
    .lightbox .lb-caption {
      color: #f1f5f9; margin-top: 1rem; font-size: 0.875rem; text-align: center;
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
  </style>
</head>
<body>
  <h1>Golden Gallery Report</h1>
  <p class="subtitle">Version $version &mdash; Generated $timestamp</p>

  <div class="summary">
    <div class="summary-item"><div class="summary-value">${entries.length}</div><div class="summary-label">Total Images</div></div>
    <div class="summary-item"><div class="summary-value">${sortedFeatures.length}</div><div class="summary-label">Features</div></div>
    <div class="summary-item"><div class="summary-value">${sortedLocales.length}</div><div class="summary-label">Locales</div></div>
    <div class="summary-item"><div class="summary-value">${sortedDevices.length}</div><div class="summary-label">Devices</div></div>
    <div class="summary-item"><div class="summary-value" style="color:#f59e0b">${overflowDetails.length}</div><div class="summary-label">Overflow</div></div>
  </div>

  <div class="toolbar">
    <div class="toolbar-group">
      <label>View</label>
      <div class="btn-group" id="view-toggle">
        <button class="active" onclick="setView('feature')">Feature</button>
        <button onclick="setView('compare')">Compare</button>
      </div>
    </div>
    <div class="toolbar-group">
      <label>Size</label>
      <div class="btn-group" id="size-toggle">
        <button onclick="setSize('s')">S</button>
        <button class="active" onclick="setSize('m')">M</button>
        <button onclick="setSize('l')">L</button>
      </div>
    </div>
    <div class="toolbar-group">
      <input type="text" class="search-box" id="searchBox" placeholder="Search state..." oninput="applyFilters()">
    </div>
    <div class="toolbar-group">
      <label><input type="checkbox" id="overflowOnly" onchange="applyFilters()"> Overflow Only</label>
    </div>
  </div>

  <div class="filters">''');

  buffer.writeln(
      '    <div class="filter-group"><h3>Feature</h3><div class="filter-actions"><a onclick="toggleAll(\'feature\',true)">All</a><a onclick="toggleAll(\'feature\',false)">None</a></div>');
  buffer.writeln('      <div class="chip-container">');
  for (final f in sortedFeatures) {
    buffer.writeln(
        '      <label class="filter-chip active"><input type="checkbox" name="feature" value="$f" checked onchange="toggleChip(this)">$f</label>');
  }
  buffer.writeln('      </div></div>');

  buffer.writeln(
      '    <div class="filter-group"><h3>Locale</h3><div class="filter-actions"><a onclick="toggleAll(\'locale\',true)">All</a><a onclick="toggleAll(\'locale\',false)">None</a></div>');
  buffer.writeln('      <div class="chip-container">');
  for (final l in sortedLocales) {
    buffer.writeln(
        '      <label class="filter-chip active"><input type="checkbox" name="locale" value="$l" checked onchange="toggleChip(this)">$l</label>');
  }
  buffer.writeln('      </div></div>');

  buffer.writeln(
      '    <div class="filter-group"><h3>Device</h3><div class="filter-actions"><a onclick="toggleAll(\'device\',true)">All</a><a onclick="toggleAll(\'device\',false)">None</a></div>');
  buffer.writeln('      <div class="chip-container">');
  final standardDevices = sortedDevices
      .where((d) => d.startsWith('phone') || d.startsWith('desktop'))
      .toList();
  final componentDevices = sortedDevices
      .where((d) => !d.startsWith('phone') && !d.startsWith('desktop'))
      .toList();
  for (final d in standardDevices) {
    buffer.writeln(
        '      <label class="filter-chip active"><input type="checkbox" name="device" value="$d" checked onchange="toggleChip(this)">$d</label>');
  }
  if (componentDevices.isNotEmpty) {
    buffer.writeln(
        '      <label class="filter-chip active"><input type="checkbox" name="device" value="_components" checked onchange="toggleChip(this)">Components (${componentDevices.length} sizes)</label>');
  }
  buffer.writeln('      </div></div>');

  buffer.writeln('  </div>');

  // Feature view
  buffer.writeln('  <div id="feature-view">');

  for (final feature in sortedFeatures) {
    final featureEntries = entries.where((e) => e.feature == feature).toList();
    buffer.writeln('  <div class="feature-section" data-feature="$feature">');
    buffer.writeln(
        '    <div class="feature-header" onclick="toggleFeature(this)">');
    buffer.writeln('      <span>$feature</span>');
    buffer.writeln(
        '      <span class="feature-count">${featureEntries.length} images</span>');
    buffer.writeln('    </div>');
    buffer.writeln('    <div class="feature-body">');
    buffer.writeln('      <div class="gallery-grid">');

    for (final entry in featureEntries) {
      final goldenName = _entryGoldenName(entry);
      final sites = overflowDetails[goldenName] ?? const [];
      final hasOverflow = sites.isNotEmpty;
      buffer.writeln(
          '        <div class="gallery-card" data-locale="${entry.locale}" data-device="${entry.device}" data-feature="${entry.feature}" data-state="${entry.state}" data-overflow="$hasOverflow">');
      buffer.writeln(
          '          <img src="${entry.relativePath}" alt="${entry.viewName}-${entry.state}" loading="lazy" onclick="openLightbox(this)">');
      buffer.writeln('          <div class="card-meta">');
      buffer
          .writeln('            <div class="card-title">${entry.state}</div>');
      buffer.writeln('            <div class="card-tags">');
      buffer.writeln('              <span class="tag">${entry.locale}</span>');
      buffer.writeln('              <span class="tag">${entry.device}</span>');
      if (entry.brightness == 'dark') {
        buffer.writeln('              <span class="tag">dark</span>');
      }
      if (hasOverflow) {
        buffer.writeln(
            '              <span class="tag-overflow">OVERFLOW</span>');
      }
      buffer.writeln('            </div>');
      if (hasOverflow) {
        // Name every overflow site on the card itself: the badge alone left the
        // reader to hunt for the culprit in the image (#1197). The full path and
        // raw message go in the tooltip to keep the card narrow.
        buffer.writeln('            <div class="card-overflow-sites">');
        // A site with neither a label nor a log has nothing to show beyond the
        // badge above, so it is skipped rather than rendered as a blank line.
        for (final site
            in sites.where((s) => s.label.isNotEmpty || s.logIndex != null)) {
          final tooltip = _escapeHtml(
              '${site.file ?? ''}${site.line == null ? '' : ':${site.line}'}\n'
                      '${site.message}'
                  .trim());
          // Falls back to a fixed phrase when nothing parsed: the card still
          // needs something to hang the raw log button on, and that case is
          // exactly when the log matters most.
          final text = site.label.isEmpty ? 'location unresolved' : site.label;
          buffer.writeln('              <span class="overflow-site" '
              'title="$tooltip">${_escapeHtml(text)}'
              '${_rawLogButton(site)}</span>');
        }
        buffer.writeln('            </div>');
      }
      buffer.writeln('          </div>');
      buffer.writeln('        </div>');
    }

    buffer.writeln('      </div>');
    buffer.writeln('    </div>');
    buffer.writeln('  </div>');
  }

  buffer.writeln('  </div>');

  // Comparison view (built by JS from embedded data)
  buffer.writeln('  <div id="comparison-view"></div>');

  // Embed entry data as JSON for comparison view. Encoded rather than
  // hand-built: overflow detail carries file paths and Flutter's raw message,
  // which are not guaranteed free of quotes.
  final jsonEntries = entries.map((e) {
    final sites = overflowDetails[_entryGoldenName(e)] ?? const [];
    return jsonEncode({
      'feature': e.feature,
      'state': e.state,
      'device': e.device,
      'locale': e.locale,
      'brightness': e.brightness,
      'path': e.relativePath,
      'overflow': sites.isNotEmpty,
      'overflowSites': sites.map((s) => s.toJson()).toList(),
    });
  }).join(',');

  buffer.writeln('''
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
    const allEntries = [$jsonEntries];
    // One table for the whole report, referenced by index from each site.
    const overflowLogs = ${jsonEncode(overflowReport.logs)};
    let currentView = 'feature';

    // The comparison view builds its markup by concatenation, and overflow
    // detail carries file paths and Flutter's raw message.
    function esc(text) {
      return String(text == null ? '' : text)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;')
        .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    // Raw log viewer.
    //
    // The title travels in a data attribute rather than as an inline call
    // argument: it is generated text that would otherwise need quoting for both
    // HTML and JavaScript at once.
    function renderRawLogButton(site) {
      if (site.logIndex == null) return '';
      return '<button class="raw-log-btn" data-log-index="' + site.logIndex + '" data-log-title="' + esc(site.label || 'Overflow raw log') + '" onclick="openRawLog(this)">raw log</button>';
    }

    function openRawLog(btn) {
      const log = overflowLogs[Number(btn.dataset.logIndex)];
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

    function setView(view) {
      currentView = view;
      document.getElementById('feature-view').style.display = view === 'feature' ? 'block' : 'none';
      document.getElementById('comparison-view').style.display = view === 'compare' ? 'block' : 'none';
      document.querySelectorAll('#view-toggle button').forEach(b => b.classList.remove('active'));
      document.querySelector('#view-toggle button:' + (view === 'feature' ? 'first-child' : 'last-child')).classList.add('active');
      if (view === 'compare') buildComparisonView();
    }

    function setSize(size) {
      document.body.classList.remove('size-s', 'size-m', 'size-l');
      if (size === 's') {
        document.body.classList.add('size-s');
        document.documentElement.style.setProperty('--thumb-min', '150px');
      } else if (size === 'l') {
        document.body.classList.add('size-l');
        document.documentElement.style.setProperty('--thumb-min', '380px');
      } else {
        document.documentElement.style.setProperty('--thumb-min', '200px');
      }
      document.querySelectorAll('#size-toggle button').forEach(b => b.classList.remove('active'));
      const idx = size === 's' ? 0 : size === 'm' ? 1 : 2;
      document.querySelectorAll('#size-toggle button')[idx].classList.add('active');
    }

    function toggleFeature(header) {
      header.nextElementSibling.classList.toggle('open');
    }

    function isStandardDevice(d) {
      return d.startsWith('phone') || d.startsWith('desktop');
    }

    function getActiveFilters() {
      const rawDevices = [...document.querySelectorAll('input[name="device"]:checked')].map(e => e.value);
      const includeComponents = rawDevices.includes('_components');
      const standardDevices = rawDevices.filter(d => d !== '_components');
      return {
        features: [...document.querySelectorAll('input[name="feature"]:checked')].map(e => e.value),
        locales: [...document.querySelectorAll('input[name="locale"]:checked')].map(e => e.value),
        standardDevices,
        includeComponents,
        search: (document.getElementById('searchBox')?.value || '').toLowerCase(),
        overflowOnly: document.getElementById('overflowOnly')?.checked || false,
      };
    }

    function matchDevice(device, filters) {
      if (isStandardDevice(device)) return filters.standardDevices.includes(device);
      return filters.includeComponents;
    }

    function applyFilters() {
      const filters = getActiveFilters();
      const {features, locales, search} = filters;

      // Feature view filtering
      document.querySelectorAll('#feature-view .feature-section').forEach(section => {
        const f = section.dataset.feature;
        if (!features.includes(f)) { section.style.display = 'none'; return; }
        section.style.display = '';
        let visibleCount = 0;
        section.querySelectorAll('.gallery-card').forEach(card => {
          const matchFilter = locales.includes(card.dataset.locale) && matchDevice(card.dataset.device, filters);
          const matchSearch = !search || (card.dataset.state || '').toLowerCase().includes(search) || (card.dataset.feature || '').toLowerCase().includes(search);
          const matchOverflow = !filters.overflowOnly || card.dataset.overflow === 'true';
          const show = matchFilter && matchSearch && matchOverflow;
          card.style.display = show ? '' : 'none';
          if (show) visibleCount++;
        });
        section.querySelector('.feature-count').textContent = visibleCount + ' images';
        if (visibleCount === 0 && (search || filters.overflowOnly)) section.style.display = 'none';
      });

      // Rebuild comparison view if active
      if (currentView === 'compare') buildComparisonView();
    }

    function buildComparisonView() {
      const container = document.getElementById('comparison-view');
      const filters = getActiveFilters();
      const {features, locales, search} = filters;

      const filtered = allEntries.filter(e =>
        features.includes(e.feature) && locales.includes(e.locale) && matchDevice(e.device, filters) &&
        (!search || e.state.toLowerCase().includes(search) || e.feature.toLowerCase().includes(search)) &&
        (!filters.overflowOnly || e.overflow)
      );

      // Group by feature -> state+device
      const groups = new Map();
      for (const e of filtered) {
        const key = e.feature + '|||' + e.state + '|||' + e.device;
        if (!groups.has(key)) groups.set(key, []);
        groups.get(key).push(e);
      }

      let html = '';
      let lastFeature = '';
      for (const [key, items] of groups) {
        const [feature, state, device] = key.split('|||');
        if (feature !== lastFeature) {
          if (lastFeature) html += '</div>';
          html += '<div class="feature-section" style="margin-bottom:1rem;border:1px solid var(--color-border);border-radius:0.75rem;overflow:hidden;">';
          html += '<div class="feature-header" onclick="toggleFeature(this)"><span>' + feature + '</span><span class="feature-count"></span></div>';
          html += '<div class="feature-body open">';
          lastFeature = feature;
        }
        html += '<div class="compare-row"><div class="compare-row-header">' + state + ' <span class="tag">' + device + '</span></div>';
        html += '<div class="compare-row-body">';
        // Sort items by locale
        items.sort((a, b) => a.locale.localeCompare(b.locale));
        for (const item of items) {
          html += '<div class="compare-cell">';
          html += '<img src="' + item.path + '" alt="' + item.state + '-' + item.locale + '" loading="lazy" onclick="openLightbox(this)">';
          html += '<div class="cell-label">' + item.locale + (item.brightness === 'dark' ? ' (dark)' : '') + '</div>';
          // Compare view is where locales are read side by side, so naming the
          // overflow site here shows at a glance that one culprit explains a
          // whole row of tagged locales (#1197).
          for (const site of (item.overflowSites || []).filter(s => s.label || s.logIndex != null)) {
            html += '<div class="overflow-site" title="' + esc(site.message) + '">' + esc(site.label || 'location unresolved') + renderRawLogButton(site) + '</div>';
          }
          html += '</div>';
        }
        html += '</div></div>';
      }
      if (lastFeature) html += '</div></div>';
      container.innerHTML = html;
    }

    // Lightbox
    let lbImages = [];
    let lbIndex = 0;

    function getVisibleImages() {
      const activeView = currentView === 'feature' ? '#feature-view' : '#comparison-view';
      return [...document.querySelectorAll(activeView + ' img[onclick]')].filter(img => {
        let el = img.closest('.gallery-card') || img.closest('.compare-cell');
        while (el) {
          if (el.style && el.style.display === 'none') return false;
          el = el.parentElement;
        }
        return true;
      });
    }

    function openLightbox(img) {
      lbImages = getVisibleImages();
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

    var showLightboxImage = function() {
      const img = lbImages[lbIndex];
      document.getElementById('lb-img').src = img.src;

      let sectionLabel = '';
      let posText = '';

      if (currentView === 'feature') {
        const card = img.closest('.gallery-card');
        const section = card ? card.closest('.feature-section') : null;
        const feature = section ? section.dataset.feature : '';
        const title = card ? card.querySelector('.card-title')?.textContent || '' : '';
        const tags = card ? [...card.querySelectorAll('.tag')].map(t => t.textContent).join(' / ') : '';
        if (section) {
          const sectionImgs = lbImages.filter(i => i.closest('.feature-section') === section);
          const posInSection = sectionImgs.indexOf(img) + 1;
          posText = feature + ' (' + posInSection + '/' + sectionImgs.length + ')';
        }
        sectionLabel = (posText ? posText + ' — ' : '') + title + (tags ? ' — ' + tags : '');
      } else {
        const row = img.closest('.compare-row');
        const section = img.closest('.feature-section');
        const cell = img.closest('.compare-cell');
        const locale = cell ? cell.querySelector('.cell-label')?.textContent || '' : '';
        const state = row ? row.querySelector('.compare-row-header')?.textContent || '' : '';
        const feature = section ? section.querySelector('.feature-header span')?.textContent || '' : '';
        if (section) {
          const sectionImgs = lbImages.filter(i => i.closest('.feature-section') === section);
          const posInSection = sectionImgs.indexOf(img) + 1;
          posText = feature + ' (' + posInSection + '/' + sectionImgs.length + ')';
        }
        sectionLabel = (posText ? posText + ' — ' : '') + state.trim() + ' — ' + locale;
      }

      document.getElementById('lb-caption').textContent = sectionLabel;
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

    function toggleChip(input) {
      const chip = input.closest('.filter-chip');
      chip.classList.toggle('active', input.checked);
      applyFilters();
    }

    function toggleAll(name, checked) {
      document.querySelectorAll('input[name="' + name + '"]').forEach(cb => {
        cb.checked = checked;
        const chip = cb.closest('.filter-chip');
        if (chip) chip.classList.toggle('active', checked);
      });
      applyFilters();
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
        const maxH = window.innerHeight * 0.8;
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

    // Auto-open all sections on load
    document.querySelectorAll('.feature-body').forEach(b => b.classList.add('open'));
  </script>
</body>
</html>''');

  return buffer.toString();
}
