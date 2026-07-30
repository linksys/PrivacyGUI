import 'dart:io';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import '../dashboard/dashboard_card_probe.dart';
import '../overflow_probe.dart';

/// The status classification of an overflow incident for recommendations.
enum OverflowStatus {
  /// Card is already at max screen column width and cannot expand further (requires UI refactor).
  screenLimit,

  /// Card content still overflows even when expanded to recommended grid size (internal layout refactor needed).
  internalOverflow,

  /// Card overflow is resolved cleanly by grid column/row expansion.
  gridExpand,

  /// Card fits cleanly without overflow.
  ok,
}

/// Structured record of a card layout overflow incident for report generation.
class OverflowReportItem {
  final String cardId;
  final double screenWidth;
  final double cardWidth;
  final double cardHeight;
  final int columnSpan;
  final int rowSpan;
  final String widthLabel;
  final int tabIndex;
  final int tabCount;
  final String localeTag;
  final List<OverflowIncident> incidents;
  final bool isAllowed;
  final int recCols;
  final int recRows;
  final double recWidth;
  final double recHeight;
  final bool isWidthExpandable;
  final bool isAdjustedClean;
  final List<OverflowIncident> adjustedIncidents;

  OverflowReportItem({
    required this.cardId,
    required this.screenWidth,
    required this.cardWidth,
    required this.cardHeight,
    required this.columnSpan,
    required this.rowSpan,
    required this.widthLabel,
    required this.tabIndex,
    required this.tabCount,
    required this.localeTag,
    required this.incidents,
    required this.isAllowed,
    required this.recCols,
    required this.recRows,
    required this.recWidth,
    required this.recHeight,
    required this.isWidthExpandable,
    required this.isAdjustedClean,
    required this.adjustedIncidents,
  });

  /// Single Source of Truth (SSoT) for recommendation status classification.
  OverflowStatus get status {
    if (!isWidthExpandable) return OverflowStatus.screenLimit;
    if (!isAdjustedClean) return OverflowStatus.internalOverflow;
    if (recCols > columnSpan || recRows > rowSpan) {
      return OverflowStatus.gridExpand;
    }
    return OverflowStatus.ok;
  }

  String get screenKey => screenWidth.toStringAsFixed(0);
  String get widthKey => cardWidth.toStringAsFixed(0);
  String get gridSpanKey => '${columnSpan}x$rowSpan';
  String get recGridSpanKey => '${recCols}x$recRows';
  String get tabSuffix => tabCount > 1 ? '_t$tabIndex' : '';
  String get relativePngPath =>
      'png/$cardId/screen${screenKey}_card${widthKey}_${gridSpanKey}${tabSuffix}_$localeTag.png';
  String get relativeAdjustedPngPath =>
      'png/adjust/$cardId/screen${screenKey}_card${widthKey}_${gridSpanKey}${tabSuffix}_${localeTag}_adjusted.png';
}

/// Simple, pragmatic report generator for dashboard layout overflow sweeps.
class DashboardOverflowReportGenerator {
  /// Generates both Markdown and HTML visual reports in [baseDir].
  static Future<void> generateAll(
    List<OverflowReportItem> items, {
    required String baseDir,
  }) async {
    await generateMarkdown(items, '$baseDir/overflow_report.md');
    await generateHtml(items, '$baseDir/overflow_report.html');
  }

  /// Generates the Markdown summary report.
  static Future<void> generateMarkdown(
    List<OverflowReportItem> items,
    String outputPath,
  ) async {
    final file = File(outputPath);
    await file.parent.create(recursive: true);

    if (items.isEmpty) {
      await file.writeAsString(
        'No layout overflow incidents detected. All card layouts are clean.\n',
      );
      return;
    }

    final sb = StringBuffer();
    for (final item in items) {
      final tabLabel = item.tabCount > 1 ? ' | tab: ${item.tabIndex}' : '';
      final detail = item.incidents.map((i) => i.toString()).join(', ');

      final String recStr = switch (item.status) {
        OverflowStatus.screenLimit =>
          '⚠️ Screen Limit (${item.columnSpan} Cols Full)',
        OverflowStatus.internalOverflow =>
          '⚠️ Internal Overflow (at ${item.recGridSpanKey})',
        OverflowStatus.gridExpand =>
          'Grid Expand to ${item.recGridSpanKey} (${item.recWidth.toInt()}px × ${item.recHeight.toInt()}px)',
        OverflowStatus.ok => 'Grid Size OK',
      };

      sb.writeln(
        '* `${item.cardId}` (screen: ${item.screenKey}px | card: ${item.widthKey}px | span: ${item.gridSpanKey}$tabLabel | locale: `${item.localeTag}`): $detail ⇒ $recStr',
      );
    }

    await file.writeAsString(sb.toString());
    // ignore: avoid_print
    print('[MD REPORT SUCCESS] Written to $outputPath');
  }

  /// Generates the interactive HTML visual report.
  static Future<void> generateHtml(
    List<OverflowReportItem> items,
    String outputPath,
  ) async {
    final file = File(outputPath);
    await file.parent.create(recursive: true);

    final totalCards = UspWidgetSpecs.all.length;
    final overflowingCards = items.map((i) => i.cardId).toSet();
    final minScreen = minScreenFilter;

    final allLocales = items.map((i) => i.localeTag).toSet().toList()..sort();
    final allCardIds = overflowingCards.toList()..sort();

    final sb = StringBuffer();
    sb.writeln('<!DOCTYPE html>');
    sb.writeln('<html lang="en">');
    sb.writeln('<head>');
    sb.writeln('<meta charset="UTF-8">');
    sb.writeln('<title>Dashboard Layout Overflow Visual Report</title>');
    sb.writeln('<style>');
    sb.writeln(
        'body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 2rem; background: #f8fafc; color: #1e293b; }');
    sb.writeln('h1 { color: #0f172a; margin-bottom: 0.5rem; }');
    sb.writeln(
        '.meta-info { font-size: 0.9rem; color: #64748b; margin-bottom: 1.5rem; }');
    sb.writeln(
        '.summary-card { background: #fff; padding: 1.5rem; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 1.5rem; }');
    sb.writeln(
        '.summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-top: 1rem; }');
    sb.writeln(
        '.stat-box { background: #f1f5f9; padding: 1rem; border-radius: 8px; text-align: center; }');
    sb.writeln(
        '.stat-number { font-size: 1.8rem; font-weight: 700; color: #2563eb; }');
    sb.writeln(
        '.stat-label { font-size: 0.85rem; color: #64748b; margin-top: 0.25rem; }');
    sb.writeln(
        '.filter-card { background: #fff; padding: 1rem 1.5rem; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 1.5rem; display: flex; flex-wrap: wrap; gap: 1rem; align-items: center; justify-content: space-between; }');
    sb.writeln(
        '.filter-group { display: flex; align-items: center; gap: 0.75rem; flex-wrap: wrap; }');
    sb.writeln(
        '.filter-label { font-size: 0.85rem; font-weight: 600; color: #475569; }');
    sb.writeln(
        '.filter-select, .filter-input { padding: 0.4rem 0.75rem; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 0.85rem; background: #fff; color: #334155; }');
    sb.writeln(
        '.action-btn { background: #f1f5f9; border: 1px solid #cbd5e1; padding: 0.4rem 0.8rem; border-radius: 6px; font-size: 0.85rem; font-weight: 500; cursor: pointer; transition: background 0.15s; }');
    sb.writeln('.action-btn:hover { background: #e2e8f0; }');
    sb.writeln(
        'table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }');
    sb.writeln(
        'th { background: #f8fafc; text-align: left; padding: 0.85rem 1rem; font-size: 0.85rem; font-weight: 600; color: #475569; border-bottom: 2px solid #e2e8f0; }');
    sb.writeln(
        'td { padding: 0.85rem 1rem; border-bottom: 1px solid #f1f5f9; font-size: 0.9rem; vertical-align: middle; }');
    sb.writeln(
        '.card-header-row { background: #e2e8f0; cursor: pointer; user-select: none; }');
    sb.writeln('.card-header-row:hover { background: #cbd5e1; }');
    sb.writeln(
        '.card-header-content { display: flex; align-items: center; justify-content: space-between; font-weight: 600; color: #0f172a; font-size: 0.95rem; }');
    sb.writeln(
        '.card-count-badge { background: #fee2e2; color: #991b1b; padding: 2px 8px; border-radius: 12px; font-size: 0.8rem; font-weight: 600; }');
    sb.writeln(
        '.code-tag { font-family: monospace; background: #f1f5f9; padding: 0.2rem 0.4rem; border-radius: 4px; font-size: 0.85rem; }');
    sb.writeln(
        '.overflow-badge { color: #dc2626; font-weight: 600; font-family: monospace; font-size: 0.85rem; }');
    sb.writeln(
        '.rec-badge { font-family: monospace; font-size: 0.82rem; padding: 0.2rem 0.4rem; border-radius: 4px; display: inline-block; margin: 2px 0; }');
    sb.writeln(
        '.rec-grid { background: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd; font-weight: 600; }');
    sb.writeln(
        '.refactor-badge { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; font-weight: 700; }');
    sb.writeln(
        '.ok-badge { color: #16a34a; font-family: monospace; font-size: 0.85rem; }');
    sb.writeln(
        '.sub-note { font-size: 0.78rem; color: #64748b; margin-top: 2px; }');
    sb.writeln(
        '.log-btn { background: #f1f5f9; border: 1px solid #cbd5e1; border-radius: 4px; padding: 2px 6px; font-size: 0.78rem; color: #2563eb; cursor: pointer; font-weight: 500; margin-top: 4px; transition: background 0.15s; display: inline-block; }');
    sb.writeln('.log-btn:hover { background: #e2e8f0; }');
    sb.writeln(
        '.img-thumb { width: 120px; height: auto; border-radius: 6px; border: 1px solid #e2e8f0; box-shadow: 0 1px 2px rgba(0,0,0,0.05); transition: transform 0.2s; cursor: pointer; }');
    sb.writeln('.img-thumb:hover { transform: scale(1.05); }');
    sb.writeln(
        '.modal-overlay { display: none; position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: rgba(15, 23, 42, 0.75); backdrop-filter: blur(4px); z-index: 1000; align-items: center; justify-content: center; }');
    sb.writeln('.modal-overlay.active { display: flex; }');
    sb.writeln(
        '.modal-card { background: #0f172a; color: #f8fafc; border-radius: 12px; width: 85%; max-width: 850px; max-height: 85vh; display: flex; flex-direction: column; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.5); overflow: hidden; text-align: left; }');
    sb.writeln(
        '.img-modal-card { background: #0f172a; color: #f8fafc; border-radius: 12px; width: 90%; max-width: 1000px; max-height: 90vh; display: flex; flex-direction: column; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.5); overflow: hidden; }');
    sb.writeln(
        '.modal-header { padding: 1rem 1.25rem; background: #1e293b; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #334155; }');
    sb.writeln(
        '.modal-title { font-weight: 600; font-size: 0.95rem; color: #f8fafc; font-family: monospace; }');
    sb.writeln('.modal-actions { display: flex; gap: 8px; align-items: center; }');
    sb.writeln(
        '.modal-copy-btn { background: #2563eb; color: #fff; border: none; border-radius: 6px; padding: 4px 10px; font-size: 0.8rem; cursor: pointer; font-weight: 500; }');
    sb.writeln('.modal-copy-btn:hover { background: #1d4ed8; }');
    sb.writeln(
        '.modal-close-btn { background: transparent; border: none; color: #94a3b8; font-size: 1.2rem; cursor: pointer; line-height: 1; }');
    sb.writeln('.modal-close-btn:hover { color: #f8fafc; }');
    sb.writeln(
        '.modal-body { padding: 1.25rem; overflow-y: auto; font-family: monospace; font-size: 0.8rem; line-height: 1.5; white-space: pre-wrap; word-break: break-all; color: #e2e8f0; }');
    sb.writeln(
        '.img-modal-body { padding: 1.5rem; overflow-y: auto; display: flex; gap: 1.5rem; justify-content: center; align-items: flex-start; background: #090d16; }');
    sb.writeln(
        '.img-compare-box { text-align: center; flex: 1; max-width: 500px; }');
    sb.writeln(
        '.img-compare-title { font-size: 0.85rem; font-weight: 600; margin-bottom: 0.75rem; font-family: monospace; }');
    sb.writeln(
        '.img-preview { max-width: 100%; height: auto; border-radius: 8px; border: 1px solid #334155; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3); }');
    sb.writeln('</style>');
    sb.writeln('<script>');
    sb.writeln(
        'function openLogModal(elementId, cardId, locale) { const rawLog = document.getElementById(elementId).value; document.getElementById("modalTitle").innerText = "📄 Raw Error Log — " + cardId + " (" + locale + ")"; document.getElementById("modalBody").innerText = rawLog; document.getElementById("modalOverlay").classList.add("active"); }');
    sb.writeln(
        'function openImgModal(cardId, locale, origUrl, adjUrl) { document.getElementById("imgModalTitle").innerText = "🖼️ Visual Comparison — " + cardId + " (" + locale + ")"; document.getElementById("imgOrig").src = origUrl; document.getElementById("imgAdj").src = adjUrl; document.getElementById("imgModalOverlay").classList.add("active"); }');
    sb.writeln(
        'function closeModal() { document.getElementById("modalOverlay").classList.remove("active"); document.getElementById("imgModalOverlay").classList.remove("active"); }');
    sb.writeln(
        'function copyModalLog() { const text = document.getElementById("modalBody").innerText; navigator.clipboard.writeText(text).then(() => { const btn = document.getElementById("copyBtn"); btn.innerText = "✅ Copied!"; setTimeout(() => { btn.innerText = "📋 Copy Log"; }, 2000); }); }');
    sb.writeln(
        'function toggleCardGroup(groupId) { const rows = document.querySelectorAll(".group-" + groupId); const icon = document.getElementById("icon-" + groupId); let isCollapsed = false; rows.forEach(r => { if (r.style.display === "none") { r.style.display = ""; } else { r.style.display = "none"; isCollapsed = true; } }); icon.innerText = isCollapsed ? "▶ Expand" : "▼ Collapse"; }');
    sb.writeln(
        'function expandAllGroups() { document.querySelectorAll(".card-header-row").forEach(h => { const gid = h.getAttribute("data-group"); document.querySelectorAll(".group-" + gid).forEach(r => r.style.display = ""); const icon = document.getElementById("icon-" + gid); if(icon) icon.innerText = "▼ Collapse"; }); }');
    sb.writeln(
        'function collapseAllGroups() { document.querySelectorAll(".card-header-row").forEach(h => { const gid = h.getAttribute("data-group"); document.querySelectorAll(".group-" + gid).forEach(r => r.style.display = "none"); const icon = document.getElementById("icon-" + gid); if(icon) icon.innerText = "▶ Expand"; }); }');
    sb.writeln(
        'function applyFilters() { const cardVal = document.getElementById("filterCard").value; const localeVal = document.getElementById("filterLocale").value; const statusVal = document.getElementById("filterStatus").value; const searchVal = document.getElementById("filterSearch").value.toLowerCase(); document.querySelectorAll(".data-row").forEach(row => { const card = row.getAttribute("data-card"); const locale = row.getAttribute("data-locale"); const status = row.getAttribute("data-status"); const text = row.innerText.toLowerCase(); const matchCard = (cardVal === "all" || card === cardVal); const matchLocale = (localeVal === "all" || locale === localeVal); const matchStatus = (statusVal === "all" || status === statusVal); const matchSearch = (!searchVal || text.includes(searchVal)); if (matchCard && matchLocale && matchStatus && matchSearch) { row.style.display = ""; } else { row.style.display = "none"; } }); }');
    sb.writeln(
        'document.addEventListener("keydown", (e) => { if (e.key === "Escape") closeModal(); });');
    sb.writeln('</script>');
    sb.writeln('</head>');
    sb.writeln('<body>');
    sb.writeln('<h1>📊 Dashboard Layout Overflow Visual Report</h1>');
    sb.writeln(
        '<div class="meta-info">Generated at: ${DateTime.now().toString().split('.').first} | Minimum Screen Filter (MIN_SCREEN): ${minScreen > 0 ? '${minScreen.toStringAsFixed(0)}px' : 'All Sizes (No Filter)'}</div>');

    final testedCardsCount = allCardIds.length;

    sb.writeln('<div class="summary-card">');
    sb.writeln('<h2>📈 Executive Summary</h2>');
    sb.writeln('<div class="summary-grid">');
    sb.writeln(
        '<div class="stat-box"><div class="stat-number">$testedCardsCount <span style="font-size:0.9rem;font-weight:400;color:#64748b;">/ $totalCards</span></div><div class="stat-label">Tested Dashboard Cards</div></div>');
    sb.writeln(
        '<div class="stat-box"><div class="stat-number">${overflowingCards.length}</div><div class="stat-label">Cards with Overflows</div></div>');
    sb.writeln(
        '<div class="stat-box"><div class="stat-number">${items.length}</div><div class="stat-label">Total Overflow Cases</div></div>');
    sb.writeln('</div>');
    sb.writeln('</div>');

    if (items.isNotEmpty) {
      // Filter controls bar
      sb.writeln('<div class="filter-card">');
      sb.writeln('<div class="filter-group">');
      sb.writeln('<span class="filter-label">🎴 Card:</span>');
      sb.writeln(
          '<select id="filterCard" class="filter-select" onchange="applyFilters()">');
      sb.writeln('<option value="all">All Cards (${allCardIds.length})</option>');
      for (final c in allCardIds) {
        sb.writeln('<option value="$c">$c</option>');
      }
      sb.writeln('</select>');

      sb.writeln('<span class="filter-label">🌐 Locale:</span>');
      sb.writeln(
          '<select id="filterLocale" class="filter-select" onchange="applyFilters()">');
      sb.writeln(
          '<option value="all">All Locales (${allLocales.length})</option>');
      for (final loc in allLocales) {
        sb.writeln('<option value="$loc">$loc</option>');
      }
      sb.writeln('</select>');

      sb.writeln('<span class="filter-label">🏷️ Status:</span>');
      sb.writeln(
          '<select id="filterStatus" class="filter-select" onchange="applyFilters()">');
      sb.writeln('<option value="all">All Statuses</option>');
      sb.writeln('<option value="screen_limit">⚠️ Screen Limit</option>');
      sb.writeln(
          '<option value="internal_overflow">⚠️ Internal Overflow</option>');
      sb.writeln('<option value="grid_expand">🟢 Grid Expand</option>');
      sb.writeln('</select>');

      sb.writeln(
          '<input type="text" id="filterSearch" class="filter-input" placeholder="🔍 Search..." onkeyup="applyFilters()" />');
      sb.writeln('</div>');

      sb.writeln('<div class="filter-group">');
      sb.writeln(
          '<button class="action-btn" onclick="expandAllGroups()">📂 Expand All</button>');
      sb.writeln(
          '<button class="action-btn" onclick="collapseAllGroups()">📁 Collapse All</button>');
      sb.writeln('</div>');
      sb.writeln('</div>');
    }

    if (items.isEmpty) {
      sb.writeln(
          '<div class="summary-card"><h3 style="color:#16a34a;">✅ No layout overflow incidents detected. All card layouts are clean.</h3></div>');
    } else {
      sb.writeln('<table>');
      sb.writeln(
          '<thead><tr><th>Card ID</th><th>📱 Screen Width</th><th>📦 Current Size</th><th>💡 Grid Recommendation & Status</th><th>Tab</th><th>Locale</th><th>Overflow Details</th><th>🔴 Overflow PNG</th><th>🟢 Recommended PNG (Adjusted)</th></tr></thead>');
      sb.writeln('<tbody>');

      // Group items by cardId
      final Map<String, List<OverflowReportItem>> grouped = {};
      for (final item in items) {
        grouped.putIfAbsent(item.cardId, () => []).add(item);
      }

      var itemIndex = 0;
      grouped.forEach((cardId, cardItems) {
        final groupSlug = cardId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        sb.writeln(
            '<tr class="card-header-row" data-group="$groupSlug" onclick="toggleCardGroup(\'$groupSlug\')">');
        sb.writeln('<td colspan="9">');
        sb.writeln('<div class="card-header-content">');
        sb.writeln('<span>🎴 Card: <code>$cardId</code></span>');
        sb.writeln(
            '<div><span class="card-count-badge">🔴 ${cardItems.length} Cases</span> <span id="icon-$groupSlug" style="font-size:0.8rem;color:#64748b;margin-left:8px;">▼ Collapse</span></div>');
        sb.writeln('</div>');
        sb.writeln('</td>');
        sb.writeln('</tr>');

        for (final item in cardItems) {
          itemIndex++;
          final logId = 'rawlog_$itemIndex';
          final tabLabel =
              item.tabCount > 1 ? 'Tab ${item.tabIndex}' : 'Single Tab';
          final detailBadges = item.incidents
              .map((i) => '<span class="overflow-badge">${i.toString()}</span>')
              .join('<br>');

          final rawLogConcat =
              _escapeHtml(item.incidents.map((i) => i.fullLog).join('\n---\n'));
          final hiddenTextarea =
              '<textarea id="$logId" style="display:none;">$rawLogConcat</textarea>';

          final logBtn =
              '<button class="log-btn" onclick="openLogModal(\'$logId\', \'${item.cardId}\', \'${item.localeTag}\')">🔍 Raw Log</button>$hiddenTextarea';
          final detailCell = '$detailBadges<br>$logBtn';

          final (String statusCode, String recHtml) = switch (item.status) {
            OverflowStatus.screenLimit => (
                'screen_limit',
                '<span class="rec-badge refactor-badge">⚠️ Screen Limit</span><br><span class="sub-note">${item.columnSpan} Cols (Full)</span>'
              ),
            OverflowStatus.internalOverflow => (
                'internal_overflow',
                '<span class="rec-badge refactor-badge">⚠️ Internal Overflow</span><br><span class="sub-note">Still overflows at ${item.recGridSpanKey}</span>'
              ),
            OverflowStatus.gridExpand => (
                'grid_expand',
                '<span class="rec-badge rec-grid">🟢 Grid Expand: ${item.recGridSpanKey}</span><br><span class="sub-note">${item.recWidth.toInt()}px × ${item.recHeight.toInt()}px</span>'
              ),
            OverflowStatus.ok => (
                'ok',
                '<span class="ok-badge">Grid Size OK</span>'
              ),
          };

          final imgOrig =
              '<img src="${item.relativePngPath}" class="img-thumb" alt="overflow screenshot" onclick="openImgModal(\'${item.cardId}\', \'${item.localeTag}\', \'${item.relativePngPath}\', \'${item.relativeAdjustedPngPath}\')">';
          final imgAdjusted =
              '<img src="${item.relativeAdjustedPngPath}" class="img-thumb" alt="adjusted screenshot" onclick="openImgModal(\'${item.cardId}\', \'${item.localeTag}\', \'${item.relativePngPath}\', \'${item.relativeAdjustedPngPath}\')">';

          sb.writeln(
              '<tr class="data-row group-$groupSlug" data-card="${item.cardId}" data-locale="${item.localeTag}" data-status="$statusCode">');
          sb.writeln('<td><span class="code-tag">${item.cardId}</span></td>');
          sb.writeln(
              '<td><span class="code-tag">${item.screenKey}px</span></td>');
          sb.writeln(
              '<td><span class="code-tag">${item.widthKey}px (${item.gridSpanKey})</span></td>');
          sb.writeln('<td>$recHtml</td>');
          sb.writeln('<td>$tabLabel</td>');
          sb.writeln(
              '<td><span class="code-tag">${item.localeTag}</span></td>');
          sb.writeln('<td>$detailCell</td>');
          sb.writeln('<td>$imgOrig</td>');
          sb.writeln('<td>$imgAdjusted</td>');
          sb.writeln('</tr>');
        }
      });

      sb.writeln('</tbody>');
      sb.writeln('</table>');
    }

    // Raw Log Modal Dialog Structure
    sb.writeln(
        '<div id="modalOverlay" class="modal-overlay" onclick="if(event.target===this)closeModal()">');
    sb.writeln('<div class="modal-card">');
    sb.writeln('<div class="modal-header">');
    sb.writeln('<div id="modalTitle" class="modal-title">📄 Raw Error Log</div>');
    sb.writeln('<div class="modal-actions">');
    sb.writeln(
        '<button id="copyBtn" class="modal-copy-btn" onclick="copyModalLog()">📋 Copy Log</button>');
    sb.writeln(
        '<button class="modal-close-btn" onclick="closeModal()">✕</button>');
    sb.writeln('</div>');
    sb.writeln('</div>');
    sb.writeln('<div id="modalBody" class="modal-body"></div>');
    sb.writeln('</div>');
    sb.writeln('</div>');

    // Image Lightbox Modal Dialog Structure
    sb.writeln(
        '<div id="imgModalOverlay" class="modal-overlay" onclick="if(event.target===this)closeModal()">');
    sb.writeln('<div class="img-modal-card">');
    sb.writeln('<div class="modal-header">');
    sb.writeln(
        '<div id="imgModalTitle" class="modal-title">🖼️ Visual Comparison</div>');
    sb.writeln(
        '<button class="modal-close-btn" onclick="closeModal()">✕</button>');
    sb.writeln('</div>');
    sb.writeln('<div class="img-modal-body">');
    sb.writeln('<div class="img-compare-box">');
    sb.writeln(
        '<div class="img-compare-title" style="color:#ef4444;">🔴 Original Overflow</div>');
    sb.writeln('<img id="imgOrig" class="img-preview" src="" alt="original">');
    sb.writeln('</div>');
    sb.writeln('<div class="img-compare-box">');
    sb.writeln(
        '<div class="img-compare-title" style="color:#38bdf8;">🟢 Recommended Grid Preview</div>');
    sb.writeln('<img id="imgAdj" class="img-preview" src="" alt="adjusted">');
    sb.writeln('</div>');
    sb.writeln('</div>');
    sb.writeln('</div>');
    sb.writeln('</div>');

    sb.writeln('</body>');
    sb.writeln('</html>');

    await file.writeAsString(sb.toString());
    // ignore: avoid_print
    print('[HTML REPORT SUCCESS] Written to $outputPath');
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
