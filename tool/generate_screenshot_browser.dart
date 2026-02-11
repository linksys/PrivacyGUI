import 'dart:convert';
import 'dart:io';

/// Generates an interactive HTML browser for screenshot test outputs.
///
/// Usage: dart run tool/generate_screenshot_browser.dart [options]
///
/// Options:
///   --output, -o     Output HTML path (default: snapshots/screenshot_browser.html)
///   --locales, -l    Comma-separated list of locales to include (default: all)
///   --devices, -d    Comma-separated list of devices to include (default: all)
///   --page-size, -p  Number of items per page (default: 50)
///   --thumbnails     Generate thumbnails (requires ImageMagick)
///
/// Examples:
///   dart run tool/generate_screenshot_browser.dart
///   dart run tool/generate_screenshot_browser.dart -l en,ja,zh-TW -d Device480w,Device1280w
///   dart run tool/generate_screenshot_browser.dart --page-size 30
void main(List<String> args) async {
  final config = parseArgs(args);

  final snapshotsDir = Directory('snapshots');
  if (!snapshotsDir.existsSync()) {
    stderr.writeln('Error: snapshots directory not found');
    exit(1);
  }

  stdout.writeln('Scanning snapshots directory...');
  var screenshots = await scanScreenshots(snapshotsDir);
  stdout.writeln('Found ${screenshots.length} total screenshots');

  // Apply locale/device filters
  if (config.locales.isNotEmpty) {
    screenshots =
        screenshots.where((s) => config.locales.contains(s['locale'])).toList();
    stdout.writeln(
        'Filtered to ${screenshots.length} screenshots (locales: ${config.locales.join(', ')})');
  }

  if (config.devices.isNotEmpty) {
    screenshots =
        screenshots.where((s) => config.devices.contains(s['device'])).toList();
    stdout.writeln(
        'Filtered to ${screenshots.length} screenshots (devices: ${config.devices.join(', ')})');
  }

  // Extract unique values for filters
  final locales = screenshots.map((s) => s['locale'] as String).toSet().toList()
    ..sort();
  final devices = screenshots.map((s) => s['device'] as String).toSet().toList()
    ..sort();
  final groups = screenshots.map((s) => s['group'] as String).toSet().toList()
    ..sort();

  stdout.writeln('Locales: ${locales.length}');
  stdout.writeln('Device types: ${devices.length}');
  stdout.writeln('Feature groups: ${groups.length}');

  // Generate thumbnails if requested
  if (config.generateThumbnails) {
    await generateThumbnails(snapshotsDir, screenshots);
  }

  final html = generateHtml(
    screenshots,
    locales,
    devices,
    groups,
    pageSize: config.pageSize,
    hasThumbnails: config.generateThumbnails,
  );

  final outputFile = File(config.outputPath);
  await outputFile.writeAsString(html);
  stdout.writeln('Generated: ${config.outputPath}');

  // Print size statistics
  final htmlSize = outputFile.lengthSync();
  stdout.writeln('HTML size: ${(htmlSize / 1024).toStringAsFixed(1)} KB');

  // Estimate total image size
  var totalImageSize = 0;
  for (final s in screenshots) {
    final file = File('${snapshotsDir.path}/${s['path']}');
    if (file.existsSync()) {
      totalImageSize += file.lengthSync();
    }
  }
  stdout.writeln(
      'Total image size: ${(totalImageSize / 1024 / 1024).toStringAsFixed(1)} MB');
}

class Config {
  final String outputPath;
  final List<String> locales;
  final List<String> devices;
  final int pageSize;
  final bool generateThumbnails;

  Config({
    required this.outputPath,
    required this.locales,
    required this.devices,
    required this.pageSize,
    required this.generateThumbnails,
  });
}

Config parseArgs(List<String> args) {
  String outputPath = 'snapshots/screenshot_browser.html';
  List<String> locales = [];
  List<String> devices = [];
  int pageSize = 50;
  bool generateThumbnails = false;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--output':
      case '-o':
        outputPath = args[++i];
        break;
      case '--locales':
      case '-l':
        locales = args[++i].split(',').map((s) => s.trim()).toList();
        break;
      case '--devices':
      case '-d':
        devices = args[++i].split(',').map((s) => s.trim()).toList();
        break;
      case '--page-size':
      case '-p':
        pageSize = int.parse(args[++i]);
        break;
      case '--thumbnails':
        generateThumbnails = true;
        break;
    }
  }

  return Config(
    outputPath: outputPath,
    locales: locales,
    devices: devices,
    pageSize: pageSize,
    generateThumbnails: generateThumbnails,
  );
}

Future<List<Map<String, dynamic>>> scanScreenshots(Directory dir) async {
  final screenshots = <Map<String, dynamic>>[];

  // First try to load from JSON report if available
  final jsonFiles = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json') && f.path.contains('test-reports'));

  final jsonData = <Map<String, dynamic>>[];
  for (final jsonFile in jsonFiles) {
    try {
      final content = await jsonFile.readAsString();
      final List<dynamic> data = jsonDecode(content);
      jsonData.addAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      stderr.writeln('Warning: Could not parse ${jsonFile.path}: $e');
    }
  }

  if (jsonData.isNotEmpty) {
    for (final item in jsonData) {
      final filePath = item['filePath'] as String?;
      if (filePath == null) continue;

      final fullPath = '${dir.path}/$filePath';
      if (!File(fullPath).existsSync()) continue;

      final tsName = item['tsName'] as String? ?? _extractName(filePath);
      screenshots.add({
        'path': filePath,
        'locale': item['locale'] ?? _extractLocale(filePath),
        'device': item['deviceType'] ?? _extractDevice(filePath),
        'group': _extractScreenId(tsName),
        'name': tsName,
        'result': item['result'] ?? 'unknown',
        'testFile': item['testCaseFilePath'] ?? '',
      });
    }
  }

  // Also scan directories for any screenshots not in JSON
  await for (final entity in dir.list(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.png')) continue;
    if (entity.path.contains('/thumbnails/')) continue;

    final relativePath = entity.path.replaceFirst('${dir.path}/', '');

    // Skip if already in JSON data
    if (screenshots.any((s) => s['path'] == relativePath)) continue;

    // Parse path structure: locale/device/filename.png or just filename.png
    final parts = relativePath.split('/');

    String locale = 'root';
    String device = 'default';
    String name = parts.last.replaceAll('.png', '');

    if (parts.length >= 3) {
      locale = parts[0];
      device = parts[1];
      name = _extractName(parts.last);
    } else if (parts.length == 2) {
      locale = parts[0];
      name = _extractName(parts.last);
    }

    screenshots.add({
      'path': relativePath,
      'locale': locale,
      'device': device,
      'group': _extractScreenId(name),
      'name': name,
      'result': 'unknown',
      'testFile': '',
    });
  }

  return screenshots;
}

String _extractLocale(String path) {
  final match = RegExp(r'-([a-z]{2}(?:-[A-Z]{2})?)\.png$').firstMatch(path);
  return match?.group(1) ?? 'unknown';
}

String _extractDevice(String path) {
  final match = RegExp(r'Device\d+w').firstMatch(path);
  return match?.group(0) ?? 'default';
}

String _extractName(String filename) {
  return filename
      .replaceAll('.png', '')
      .replaceAll(RegExp(r'-Device\d+w.*$'), '')
      .trim();
}

/// Extracts screen ID from filename or tsName for grouping.
///
/// Groups screenshots by screen/feature area for easier browsing.
String _extractScreenId(String name) {
  // Pattern 1: Uppercase prefix with dash/underscore (e.g., PNPS-STEP1_WIFI_01)
  final prefixMatch = RegExp(r'^([A-Z]+-[A-Z0-9_]+)').firstMatch(name);
  if (prefixMatch != null) {
    final prefix = prefixMatch.group(1)!;
    // Extract main screen ID: PNPS-STEP1_WIFI_01 → PNPS
    return prefix.split('-').first;
  }

  // Pattern 2: Simple uppercase abbreviation (DDNS, DMZ, VPN)
  final abbrevMatch = RegExp(r'^([A-Z]{2,})(?:\s|-)').firstMatch(name);
  if (abbrevMatch != null) {
    return abbrevMatch.group(1)!;
  }

  // Pattern 3: "xxx view - ..." or "xxx view ..." pattern
  final viewMatch = RegExp(r'^(.+?)\s+view(?:\s+-|\s|$)', caseSensitive: false)
      .firstMatch(name);
  if (viewMatch != null) {
    return '${viewMatch.group(1)} View';
  }

  // Pattern 4: "dashboard xxx view - ..." pattern
  if (name.startsWith('dashboard ')) {
    final parts = name.split(' ');
    if (parts.length >= 3) {
      return 'Dashboard ${_capitalize(parts[1])}';
    }
    return 'Dashboard';
  }

  // Pattern 5: "instant xxx view - ..." pattern
  if (name.startsWith('instant ')) {
    final parts = name.split(' ');
    if (parts.length >= 3) {
      return 'Instant ${_capitalize(parts[1])}';
    }
    return 'Instant';
  }

  // Pattern 6: "local xxx view - ..." pattern
  if (name.startsWith('local ')) {
    final parts = name.split(' ');
    if (parts.length >= 3) {
      return 'Local ${_capitalize(parts[1])}';
    }
    return 'Local';
  }

  // Pattern 7: "node xxx view - ..." pattern
  if (name.startsWith('node ')) {
    return 'Node Detail';
  }

  // Pattern 8: "login xxx view - ..." pattern
  if (name.startsWith('login ')) {
    return 'Login';
  }

  // Pattern 9: "device xxx view - ..." pattern
  if (name.startsWith('device ')) {
    return 'Device Detail';
  }

  // Pattern 10: Test case patterns - group by test type
  if (name.startsWith('Verify ') ||
      name.startsWith('It should') ||
      name.startsWith('should ') ||
      name.startsWith('WHEN ')) {
    // Try to extract feature from test name
    if (name.contains('speed test') || name.contains('Speedtest'))
      return 'Speed Test';
    if (name.contains('WiFi') || name.contains('wifi') || name.contains('SSID'))
      return 'WiFi';
    if (name.contains('MAC')) return 'MAC Filtering';
    if (name.contains('VPN')) return 'VPN';
    if (name.contains('firmware') || name.contains('Firmware'))
      return 'Firmware';
    if (name.contains('PPPoE') || name.contains('DHCP') || name.contains('ISP'))
      return 'Internet Settings';
    if (name.contains('static route')) return 'Static Routing';
    if (name.contains('banner') || name.contains('install'))
      return 'Install Prompt';
    if (name.contains('password') ||
        name.contains('login') ||
        name.contains('admin')) return 'Authentication';
    if (name.contains('modem') || name.contains('router'))
      return 'Setup Wizard';
    if (name.contains('node')) return 'Node';
    if (name.contains('channel') || name.contains('security mode'))
      return 'WiFi Advanced';
    return 'Verification Tests';
  }

  // Pattern 11: "status: xxx" pattern
  if (name.startsWith('status:')) {
    return 'PNP Status';
  }

  // Pattern 12: Port forwarding related
  if (name.contains('port forwarding') || name.contains('Port forwarding')) {
    return 'Port Forwarding';
  }
  if (name.contains('port triggerring') || name.contains('Port triggerring')) {
    return 'Port Triggering';
  }

  // Pattern 13: Other specific patterns
  if (name.contains('Snack bar')) return 'Snack Bar';
  if (name.contains('Dialog')) return 'Dialogs';
  if (name.contains('General Settings')) return 'General Settings';
  if (name.contains('Manual firmware')) return 'Firmware';

  // Default: take first meaningful word(s)
  final words = name.split(' ');
  if (words.isNotEmpty) {
    return _capitalize(words.first);
  }

  return 'Other';
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}

Future<void> generateThumbnails(
    Directory snapshotsDir, List<Map<String, dynamic>> screenshots) async {
  final thumbDir = Directory('${snapshotsDir.path}/thumbnails');
  if (!thumbDir.existsSync()) {
    thumbDir.createSync(recursive: true);
  }

  stdout.writeln('Generating thumbnails...');

  for (var i = 0; i < screenshots.length; i++) {
    final s = screenshots[i];
    final sourcePath = '${snapshotsDir.path}/${s['path']}';
    final thumbPath =
        '${thumbDir.path}/${s['path']}'.replaceAll('.png', '_thumb.jpg');

    final thumbFile = File(thumbPath);
    if (thumbFile.existsSync()) continue;

    // Create directory structure
    final thumbParent = thumbFile.parent;
    if (!thumbParent.existsSync()) {
      thumbParent.createSync(recursive: true);
    }

    // Use ImageMagick to create thumbnail
    final result = await Process.run('convert', [
      sourcePath,
      '-resize',
      '300x',
      '-quality',
      '80',
      thumbPath,
    ]);

    if (result.exitCode != 0) {
      stderr.writeln('Warning: Failed to create thumbnail for ${s['path']}');
    }

    if ((i + 1) % 100 == 0) {
      stdout.writeln('Generated ${i + 1}/${screenshots.length} thumbnails');
    }
  }

  stdout.writeln('Thumbnails complete');
}

String generateHtml(List<Map<String, dynamic>> screenshots,
    List<String> locales, List<String> devices, List<String> groups,
    {int pageSize = 50, bool hasThumbnails = false}) {
  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Screenshot Browser - PrivacyGUI</title>
  <style>
    :root {
      --primary: #2563eb;
      --primary-hover: #1d4ed8;
      --success: #16a34a;
      --error: #dc2626;
      --bg: #f8fafc;
      --card-bg: #ffffff;
      --border: #e2e8f0;
      --text: #1e293b;
      --text-muted: #64748b;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: var(--bg);
      color: var(--text);
      line-height: 1.5;
    }

    .header {
      background: var(--card-bg);
      border-bottom: 1px solid var(--border);
      padding: 1rem 2rem;
      position: sticky;
      top: 0;
      z-index: 100;
    }

    .header h1 {
      font-size: 1.5rem;
      margin-bottom: 1rem;
    }

    .filters {
      display: flex;
      flex-wrap: wrap;
      gap: 1rem;
      align-items: center;
    }

    .filter-group {
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
    }

    .filter-group label {
      font-size: 0.75rem;
      font-weight: 600;
      text-transform: uppercase;
      color: var(--text-muted);
    }

    select, input[type="text"] {
      padding: 0.5rem 1rem;
      border: 1px solid var(--border);
      border-radius: 0.375rem;
      font-size: 0.875rem;
      min-width: 150px;
    }

    input[type="text"] { min-width: 250px; }

    .stats {
      margin-left: auto;
      font-size: 0.875rem;
      color: var(--text-muted);
    }

    .view-toggle {
      display: flex;
      gap: 0.5rem;
    }

    .view-toggle button, .pagination button {
      padding: 0.5rem 1rem;
      border: 1px solid var(--border);
      background: var(--card-bg);
      cursor: pointer;
      font-size: 0.875rem;
      border-radius: 0.375rem;
    }

    .view-toggle button.active, .pagination button.active {
      background: var(--primary);
      color: white;
      border-color: var(--primary);
    }

    .view-toggle button:hover:not(.active), .pagination button:hover:not(.active):not(:disabled) {
      background: #f1f5f9;
    }

    .pagination button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    .main { padding: 2rem; }

    .pagination {
      display: flex;
      justify-content: center;
      gap: 0.5rem;
      margin-bottom: 1.5rem;
      flex-wrap: wrap;
    }

    .pagination-info {
      display: flex;
      align-items: center;
      font-size: 0.875rem;
      color: var(--text-muted);
      margin: 0 1rem;
    }

    .gallery {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 1.5rem;
    }

    .card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 0.5rem;
      overflow: hidden;
      transition: box-shadow 0.2s;
      cursor: pointer;
    }

    .card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }

    .card-image {
      aspect-ratio: 16/10;
      overflow: hidden;
      background: #f1f5f9;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .card-image img {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }

    .card-info { padding: 1rem; }

    .card-info h3 {
      font-size: 0.875rem;
      margin-bottom: 0.5rem;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .card-meta {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
    }

    .tag {
      font-size: 0.7rem;
      padding: 0.125rem 0.5rem;
      background: #f1f5f9;
      border-radius: 0.25rem;
      color: var(--text-muted);
    }

    .tag.locale { background: #dbeafe; color: #1e40af; }
    .tag.device { background: #dcfce7; color: #166534; }
    .tag.success { background: #dcfce7; color: var(--success); }
    .tag.failed { background: #fee2e2; color: var(--error); }

    .compare-container { display: none; }
    .compare-container.active { display: block; }

    .compare-controls {
      background: var(--card-bg);
      padding: 1rem;
      border-radius: 0.5rem;
      margin-bottom: 1.5rem;
      display: flex;
      gap: 1rem;
      align-items: flex-end;
    }

    .compare-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
      gap: 1rem;
    }

    .compare-item {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 0.5rem;
      overflow: hidden;
    }

    .compare-item-header {
      padding: 0.75rem 1rem;
      background: #f8fafc;
      border-bottom: 1px solid var(--border);
      font-weight: 600;
    }

    .compare-item img { width: 100%; display: block; }

    .lightbox {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(0,0,0,0.9);
      z-index: 1000;
      justify-content: center;
      align-items: center;
      flex-direction: column;
      padding: 2rem;
    }

    .lightbox.active { display: flex; }

    .lightbox-close {
      position: absolute;
      top: 1rem;
      right: 1rem;
      background: white;
      border: none;
      width: 40px;
      height: 40px;
      border-radius: 50%;
      cursor: pointer;
      font-size: 1.5rem;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .lightbox img {
      max-width: 90vw;
      max-height: 80vh;
      object-fit: contain;
    }

    .lightbox-info {
      color: white;
      margin-top: 1rem;
      text-align: center;
    }

    .lightbox-nav {
      position: absolute;
      top: 50%;
      transform: translateY(-50%);
      background: white;
      border: none;
      width: 50px;
      height: 50px;
      border-radius: 50%;
      cursor: pointer;
      font-size: 1.5rem;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .lightbox-nav.prev { left: 1rem; }
    .lightbox-nav.next { right: 1rem; }

    .gallery-container.hidden, .compare-container.hidden { display: none; }
    .gallery-container.active { display: block; }

    .no-results {
      text-align: center;
      padding: 4rem;
      color: var(--text-muted);
    }

    .shortcuts-help {
      position: fixed;
      bottom: 1rem;
      right: 1rem;
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 0.5rem;
      padding: 0.75rem 1rem;
      font-size: 0.75rem;
      color: var(--text-muted);
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .shortcuts-help kbd {
      background: #f1f5f9;
      padding: 0.125rem 0.375rem;
      border-radius: 0.25rem;
      font-family: monospace;
    }

    .loading {
      display: flex;
      justify-content: center;
      padding: 2rem;
      color: var(--text-muted);
    }
  </style>
</head>
<body>
  <header class="header">
    <h1>Screenshot Browser - PrivacyGUI</h1>
    <div class="filters">
      <div class="filter-group">
        <label>Locale</label>
        <select id="filter-locale">
          <option value="">All Locales</option>
        </select>
      </div>
      <div class="filter-group">
        <label>Device</label>
        <select id="filter-device">
          <option value="">All Devices</option>
        </select>
      </div>
      <div class="filter-group">
        <label>Group</label>
        <select id="filter-group">
          <option value="">All Groups</option>
        </select>
      </div>
      <div class="filter-group">
        <label>Search</label>
        <input type="text" id="search" placeholder="Search by name...">
      </div>
      <div class="stats">
        <span id="count">0</span> screenshots
      </div>
    </div>
  </header>

  <main class="main">
    <div class="gallery-container active" id="gallery-container">
      <div class="pagination" id="pagination"></div>
      <div class="gallery" id="gallery"></div>
      <div class="no-results" id="no-results" style="display:none">
        No screenshots match your filters
      </div>
    </div>

  </main>

  <div class="lightbox" id="lightbox">
    <button class="lightbox-close" id="lightbox-close">&times;</button>
    <button class="lightbox-nav prev" id="lightbox-prev">&lt;</button>
    <button class="lightbox-nav next" id="lightbox-next">&gt;</button>
    <img id="lightbox-img" src="" alt="">
    <div class="lightbox-info" id="lightbox-info"></div>
  </div>

  <div class="shortcuts-help">
    <kbd>Esc</kbd> Close &nbsp;
    <kbd>&larr;</kbd><kbd>&rarr;</kbd> Navigate &nbsp;
    <kbd>/</kbd> Search
  </div>

  <script>
    const screenshots = ${jsonEncode(screenshots)};
    const locales = ${jsonEncode(locales)};
    const devices = ${jsonEncode(devices)};
    const groups = ${jsonEncode(groups)};
    const PAGE_SIZE = $pageSize;
    const HAS_THUMBNAILS = $hasThumbnails;

    let filteredScreenshots = [...screenshots];
    let currentPage = 1;
    let currentIndex = 0;

    // Populate filters
    function populateFilters() {
      const localeSelect = document.getElementById('filter-locale');
      const deviceSelect = document.getElementById('filter-device');
      const groupSelect = document.getElementById('filter-group');
      locales.forEach(l => {
        localeSelect.innerHTML += `<option value="\${l}">\${l}</option>`;
      });

      devices.forEach(d => {
        deviceSelect.innerHTML += `<option value="\${d}">\${d}</option>`;
      });

      groups.forEach(g => {
        groupSelect.innerHTML += `<option value="\${g}">\${g}</option>`;
      });
    }

    // Filter screenshots
    function applyFilters() {
      const locale = document.getElementById('filter-locale').value;
      const device = document.getElementById('filter-device').value;
      const group = document.getElementById('filter-group').value;
      const search = document.getElementById('search').value.toLowerCase();

      filteredScreenshots = screenshots.filter(s => {
        if (locale && s.locale !== locale) return false;
        if (device && s.device !== device) return false;
        if (group && s.group !== group) return false;
        if (search && !s.name.toLowerCase().includes(search)) return false;
        return true;
      });

      currentPage = 1;
      renderGallery();
    }

    // Pagination
    function getTotalPages() {
      return Math.ceil(filteredScreenshots.length / PAGE_SIZE);
    }

    function getPageItems() {
      const start = (currentPage - 1) * PAGE_SIZE;
      return filteredScreenshots.slice(start, start + PAGE_SIZE);
    }

    function renderPagination() {
      const pagination = document.getElementById('pagination');
      const totalPages = getTotalPages();

      if (totalPages <= 1) {
        pagination.innerHTML = '';
        return;
      }

      let html = `
        <button onclick="goToPage(1)" \${currentPage === 1 ? 'disabled' : ''}>First</button>
        <button onclick="goToPage(currentPage - 1)" \${currentPage === 1 ? 'disabled' : ''}>Prev</button>
      `;

      // Show page numbers
      const startPage = Math.max(1, currentPage - 2);
      const endPage = Math.min(totalPages, currentPage + 2);

      for (let i = startPage; i <= endPage; i++) {
        html += `<button onclick="goToPage(\${i})" class="\${i === currentPage ? 'active' : ''}">\${i}</button>`;
      }

      html += `
        <span class="pagination-info">Page \${currentPage} of \${totalPages}</span>
        <button onclick="goToPage(currentPage + 1)" \${currentPage === totalPages ? 'disabled' : ''}>Next</button>
        <button onclick="goToPage(\${totalPages})" \${currentPage === totalPages ? 'disabled' : ''}>Last</button>
      `;

      pagination.innerHTML = html;
    }

    function goToPage(page) {
      currentPage = page;
      renderGallery();
      window.scrollTo(0, 0);
    }

    // Render gallery
    function renderGallery() {
      const gallery = document.getElementById('gallery');
      const noResults = document.getElementById('no-results');
      const count = document.getElementById('count');

      count.textContent = filteredScreenshots.length;
      renderPagination();

      if (filteredScreenshots.length === 0) {
        gallery.innerHTML = '';
        noResults.style.display = 'block';
        return;
      }

      noResults.style.display = 'none';

      const pageItems = getPageItems();
      const globalOffset = (currentPage - 1) * PAGE_SIZE;

      gallery.innerHTML = pageItems.map((s, i) => {
        const thumbPath = HAS_THUMBNAILS
          ? 'thumbnails/' + s.path.replace('.png', '_thumb.jpg')
          : s.path;
        return `
          <div class="card" data-index="\${globalOffset + i}" onclick="openLightbox(\${globalOffset + i})">
            <div class="card-image">
              <img src="\${thumbPath}" alt="\${s.name}" loading="lazy">
            </div>
            <div class="card-info">
              <h3 title="\${s.name}">\${s.name}</h3>
              <div class="card-meta">
                <span class="tag locale">\${s.locale}</span>
                <span class="tag device">\${s.device}</span>
              </div>
            </div>
          </div>
        `;
      }).join('');
    }

    // Lightbox
    function openLightbox(index) {
      currentIndex = index;
      updateLightbox();
      document.getElementById('lightbox').classList.add('active');
    }

    function closeLightbox() {
      document.getElementById('lightbox').classList.remove('active');
    }

    function updateLightbox() {
      const s = filteredScreenshots[currentIndex];
      document.getElementById('lightbox-img').src = s.path;  // Always use full image
      document.getElementById('lightbox-info').innerHTML = `
        <strong>\${s.name}</strong><br>
        \${s.locale} | \${s.device} | \${s.group}
      `;
    }

    function navigateLightbox(delta) {
      currentIndex = (currentIndex + delta + filteredScreenshots.length) % filteredScreenshots.length;
      updateLightbox();
    }

    // Event listeners
    document.getElementById('filter-locale').addEventListener('change', applyFilters);
    document.getElementById('filter-device').addEventListener('change', applyFilters);
    document.getElementById('filter-group').addEventListener('change', applyFilters);
    document.getElementById('search').addEventListener('input', applyFilters);

    document.getElementById('lightbox-close').addEventListener('click', closeLightbox);
    document.getElementById('lightbox-prev').addEventListener('click', () => navigateLightbox(-1));
    document.getElementById('lightbox-next').addEventListener('click', () => navigateLightbox(1));
    document.getElementById('lightbox').addEventListener('click', (e) => {
      if (e.target.id === 'lightbox') closeLightbox();
    });

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      if (document.getElementById('lightbox').classList.contains('active')) {
        if (e.key === 'Escape') closeLightbox();
        if (e.key === 'ArrowLeft') navigateLightbox(-1);
        if (e.key === 'ArrowRight') navigateLightbox(1);
      }
      if (e.key === '/' && document.activeElement.tagName !== 'INPUT') {
        e.preventDefault();
        document.getElementById('search').focus();
      }
    });

    // Initialize
    populateFilters();
    applyFilters();
  </script>
</body>
</html>
''';
}
