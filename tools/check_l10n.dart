#!/usr/bin/env dart

/// L10n health check tool for PrivacyGUI.
///
/// Detects:
/// 1. Duplicate keys (same key twice in one ARB file)
/// 2. Duplicate values (different keys with identical values)
/// 3. Unused keys (ARB has but Dart doesn't use)
/// 4. Orphan keys (other locales have but app_en.arb doesn't)
/// 5. Missing translations (app_en.arb has but other locales don't)
/// 6. Hardcoded strings (strings in Dart that should use loc())
///
/// Usage:
///   dart run tools/check_l10n.dart [options]
///
/// Options:
///   --only=<check>    Run only specific check (duplicate-keys, duplicate-values,
///                     unused-keys, orphan-keys, missing-translations, hardcoded-strings)
///   --output=<file>   Write markdown report to file (default: l10n-report.md)
///   --stdout          Output to stdout instead of file
///   --brief           Truncate findings at 20 items (default: show all)
///   --help            Show this help
library;

import 'dart:convert';
import 'dart:io';

// =============================================================================
// Configuration
// =============================================================================

const String arbDir = 'lib/l10n';
const String templateFile = 'app_en.arb';
const String dartSourceDir = 'lib';

// False-positive suppressions for the unused-keys check ONLY.
//
// This list is NOT a place to park keys you don't want to deal with. A key
// belongs here if and only if BOTH hold:
//   1. It IS used in Dart code (flutter analyze would error otherwise), and
//   2. The usage is a cross-line call — `loc(context)` on one line and
//      `.keyName(...)` on the next — which the single-line usage regex below
//      cannot detect, so it is wrongly reported as unused.
//
// A key that is genuinely unreferenced must be DELETED from the ARB files,
// not added here. Each entry notes the file that contains the real usage.
const Set<String> allowedUnusedKeys = {
  'copyRight', // bottom_bar.dart
  'addedWidgetNamed', // usp_layout_settings_panel.dart
  'nOnlineOfTotal', // usp_network_topology_card.dart
  'nRadios', // usp_wifi_status_card.dart
};

// =============================================================================
// Main
// =============================================================================

void main(List<String> args) {
  final options = _parseArgs(args);

  if (options['help'] == true) {
    _printUsage();
    exit(0);
  }

  final report = StringBuffer();
  var totalIssues = 0;

  report.writeln('# L10n Health Check Report');
  report.writeln();
  report.writeln('Generated: ${DateTime.now().toIso8601String()}');
  report.writeln();

  final checks = <String, CheckResult Function()>{
    'duplicate-keys': _checkDuplicateKeys,
    'duplicate-values': _checkDuplicateValues,
    'unused-keys': _checkUnusedKeys,
    'orphan-keys': _checkOrphanKeys,
    'missing-translations': _checkMissingTranslations,
    'hardcoded-strings': _checkHardcodedStrings,
  };

  final onlyCheck = options['only'] as String?;
  final brief = options['brief'] == true;
  final toStdout = options['stdout'] == true;

  for (final entry in checks.entries) {
    if (onlyCheck != null && entry.key != onlyCheck) continue;

    final result = entry.value();
    totalIssues += result.issueCount;

    report.writeln('## ${result.title}');
    report.writeln();

    if (result.issueCount == 0) {
      report.writeln('✅ No issues found.');
    } else {
      // For hardcoded-strings, the count is embedded in details after scope table
      if (entry.key != 'hardcoded-strings') {
        report.writeln('❌ Found **${result.issueCount}** issue(s).');
        report.writeln();
      }

      if (!brief || result.issueCount <= 20) {
        report.writeln(result.details);
      } else {
        // Show first 15 lines and summary
        final lines = result.details.split('\n');
        final preview = lines.take(15).join('\n');
        report.writeln(preview);
        if (lines.length > 15) {
          report.writeln('');
          report.writeln(
              '... and ${lines.length - 15} more (remove --brief to see all)');
        }
      }
    }
    report.writeln();
  }

  // Summary
  report.writeln('---');
  report.writeln();
  report.writeln('## Summary');
  report.writeln();
  if (totalIssues == 0) {
    report.writeln('✅ All checks passed!');
  } else {
    report.writeln('❌ Total issues: **$totalIssues**');
  }

  // Output: default to file, --stdout for console
  if (toStdout) {
    print(report);
  } else {
    final outputFile = options['output'] as String? ?? 'l10n-report.md';
    File(outputFile).writeAsStringSync(report.toString());
    print('Report written to: $outputFile');
  }

  exit(totalIssues > 0 ? 1 : 0);
}

// =============================================================================
// Check: Duplicate Keys
// =============================================================================

CheckResult _checkDuplicateKeys() {
  final issues = <String>[];

  for (final file in _getArbFiles()) {
    final content = File(file).readAsStringSync();
    final duplicates = _findDuplicateKeysInJson(content);

    if (duplicates.isNotEmpty) {
      issues.add('### ${_basename(file)}');
      issues.add('');
      var idx = 0;
      for (final dup in duplicates) {
        idx++;
        issues.add('$idx. Key: `${dup.key}` (${dup.count} occurrences)');
        for (var i = 0; i < dup.lines.length; i++) {
          final valuePreview = dup.values[i].length > 60
              ? '${dup.values[i].substring(0, 60)}...'
              : dup.values[i];
          final isActive = i == dup.lines.length - 1;
          final marker = isActive ? '✅ ACTIVE' : '❌ dead';
          issues.add('    - Line ${dup.lines[i]}: `"$valuePreview"` — $marker');
        }
      }
      issues.add('');
    }
  }

  final totalDuplicates =
      issues.where((l) => RegExp(r'^\d+\. Key:').hasMatch(l)).length;

  return CheckResult(
    title: '[Duplicate Keys]',
    issueCount: totalDuplicates,
    details: issues.join('\n'),
  );
}

class _DuplicateKey {
  final String key;
  final int count;
  final List<int> lines;
  final List<String> values;
  _DuplicateKey(this.key, this.count, this.lines, this.values);
}

List<_DuplicateKey> _findDuplicateKeysInJson(String content) {
  // Only match top-level keys (exactly 2 spaces of indentation in ARB files)
  final keyPattern =
      RegExp(r'^  "([^"]+)"\s*:\s*"(.*)"\s*,?\s*$', multiLine: true);
  final keyData = <String, List<(int, String)>>{};

  var lineNum = 0;
  for (final line in content.split('\n')) {
    lineNum++;
    final match = keyPattern.firstMatch(line);
    if (match != null) {
      final key = match.group(1)!;
      final value = match.group(2)!;
      keyData.putIfAbsent(key, () => []).add((lineNum, value));
    }
  }

  return keyData.entries
      .where((e) => e.value.length > 1)
      .map((e) => _DuplicateKey(
            e.key,
            e.value.length,
            e.value.map((v) => v.$1).toList(),
            e.value.map((v) => v.$2).toList(),
          ))
      .toList();
}

// =============================================================================
// Check: Duplicate Values
// =============================================================================

CheckResult _checkDuplicateValues() {
  final issues = <String>[];
  var totalDuplicates = 0;

  for (final file in _getArbFiles()) {
    final json = _loadArb(file);

    // Group keys by value (excluding @metadata keys)
    final valueToKeys = <String, List<String>>{};
    for (final entry in json.entries) {
      if (entry.key.startsWith('@')) continue;
      if (entry.value is! String) continue;

      final value = entry.value as String;
      valueToKeys.putIfAbsent(value, () => []).add(entry.key);
    }

    // Find duplicates (exact match only)
    final duplicates = valueToKeys.entries
        .where((e) => e.value.length > 1)
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (duplicates.isNotEmpty) {
      issues.add('### ${_basename(file)}');
      issues.add('');
      var idx = 0;
      for (final dup in duplicates) {
        idx++;
        final keys = dup.value.map((k) => '`$k`').join(', ');
        final value =
            dup.key.length > 60 ? '${dup.key.substring(0, 60)}...' : dup.key;
        issues.add('$idx. Value: "$value"');
        issues.add('    - Keys: $keys');
      }
      issues.add('');
      totalDuplicates += duplicates.length;
    }
  }

  return CheckResult(
    title: '[Duplicate Values]',
    issueCount: totalDuplicates,
    details: issues.join('\n'),
  );
}

// =============================================================================
// Check: Unused Keys
// =============================================================================

CheckResult _checkUnusedKeys() {
  final enFile = '$arbDir/$templateFile';
  final arbKeys =
      _loadArb(enFile).keys.where((k) => !k.startsWith('@')).toSet();

  // Find all l10n key usages in Dart files
  final usedKeys = <String>{};
  final dartFiles = _getDartFiles(dartSourceDir);

  // Patterns to match l10n key usage:
  // 1. loc(context).keyName or loc(ctx).keyName
  // 2. getAppLocalizations(context).keyName
  // 3. Variable pattern: final l = loc(context); ... l.keyName
  final directLocPattern = RegExp(r'loc\([^)]+\)\.(\w+)');
  final getAppLocPattern = RegExp(r'getAppLocalizations\([^)]+\)\.(\w+)');

  // Pattern to detect variable assignment: final/var l = loc(...) or getAppLocalizations(...)
  final varAssignPattern = RegExp(
    r'(?:final|var|const)\s+(\w+)\s*=\s*(?:loc|getAppLocalizations)\s*\(',
  );

  for (final file in dartFiles) {
    final content = File(file).readAsStringSync();

    // Pattern 1: Direct loc(context).keyName
    for (final match in directLocPattern.allMatches(content)) {
      usedKeys.add(match.group(1)!);
    }

    // Pattern 2: getAppLocalizations(context).keyName
    for (final match in getAppLocPattern.allMatches(content)) {
      usedKeys.add(match.group(1)!);
    }

    // Pattern 3: Variable-based access (e.g., final l = loc(context); l.keyName)
    // First find all variable names assigned to loc() or getAppLocalizations()
    final locVarNames = <String>{};
    for (final match in varAssignPattern.allMatches(content)) {
      locVarNames.add(match.group(1)!);
    }

    // Then find all usages of those variables: varName.keyName
    for (final varName in locVarNames) {
      final varUsagePattern = RegExp('$varName\\.(\\w+)');
      for (final match in varUsagePattern.allMatches(content)) {
        usedKeys.add(match.group(1)!);
      }
    }
  }

  // Find unused (in ARB but not in Dart)
  final unused = arbKeys.difference(usedKeys).difference(allowedUnusedKeys);
  final sortedUnused = unused.toList()..sort();

  final issues = <String>[];
  var idx = 0;
  for (final k in sortedUnused) {
    idx++;
    issues.add('$idx. `$k`');
  }

  return CheckResult(
    title: '[Unused Keys] (in app_en.arb but not referenced in Dart)',
    issueCount: unused.length,
    details: issues.join('\n'),
  );
}

// =============================================================================
// Check: Orphan Keys
// =============================================================================

CheckResult _checkOrphanKeys() {
  final enFile = '$arbDir/$templateFile';
  final enKeys = _loadArb(enFile).keys.where((k) => !k.startsWith('@')).toSet();

  final issues = <String>[];

  for (final file in _getArbFiles()) {
    if (file.endsWith(templateFile)) continue;

    final localeKeys =
        _loadArb(file).keys.where((k) => !k.startsWith('@')).toSet();

    final orphans = localeKeys.difference(enKeys);
    if (orphans.isNotEmpty) {
      final locale = _basename(file);
      issues.add('### $locale (${orphans.length} orphan keys)');
      issues.add('');
      var idx = 0;
      for (final key in orphans.toList()..sort()) {
        idx++;
        issues.add('$idx. `$key`');
      }
      issues.add('');
    }
  }

  final totalOrphans =
      issues.where((l) => RegExp(r'^\d+\.').hasMatch(l)).length;

  return CheckResult(
    title: '[Orphan Keys] (in locale files but not in app_en.arb)',
    issueCount: totalOrphans,
    details: issues.join('\n'),
  );
}

// =============================================================================
// Check: Missing Translations
// =============================================================================

CheckResult _checkMissingTranslations() {
  final enFile = '$arbDir/$templateFile';
  final enKeys = _loadArb(enFile).keys.where((k) => !k.startsWith('@')).toSet();

  final localeMissing = <String, int>{};

  for (final file in _getArbFiles()) {
    if (file.endsWith(templateFile)) continue;

    final localeKeys =
        _loadArb(file).keys.where((k) => !k.startsWith('@')).toSet();

    final missing = enKeys.difference(localeKeys);
    if (missing.isNotEmpty) {
      final locale =
          _basename(file).replaceAll('app_', '').replaceAll('.arb', '');
      localeMissing[locale] = missing.length;
    }
  }

  // Sort by missing count descending
  final sorted = localeMissing.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final issues = <String>[];
  issues.add('| Locale | Missing Keys |');
  issues.add('|--------|-------------|');
  for (final entry in sorted) {
    issues.add('| ${entry.key} | ${entry.value} |');
  }

  final totalMissing = localeMissing.values.fold(0, (a, b) => a + b);

  return CheckResult(
    title: '[Missing Translations] (in app_en.arb but not in locale files)',
    issueCount: totalMissing,
    details: issues.join('\n'),
  );
}

// =============================================================================
// Check: Hardcoded Strings
// =============================================================================

// Directories to scan for hardcoded strings (UI-facing code only)
// Included:
//   - lib/page/       All page UIs
//   - lib/components/ Shared UI components
//   - lib/util/       Some UI helpers (snackbar, QR code, etc.)
// Excluded:
//   - lib/core/       Low-level APIs, no UI
//   - lib/generated/  Codegen output
//   - lib/providers/  State management, no UI
//   - lib/route/      Route definitions
//   - lib/framework/  Infrastructure
//   - lib/theme/      Theme config
//   - lib/ai/         No hardcoded strings
//   - lib/demo/       Dev-only, no translation needed
const List<String> _hardcodedScanDirs = [
  'lib/page',
  'lib/components',
  'lib/util',
];

// Patterns to ignore (technical strings, not user-facing)
final _ignorePatterns = [
  RegExp(r'^https?://'), // URLs
  RegExp(r'^wss?://'), // WebSocket URLs
  RegExp(r'^assets/'), // Asset paths
  RegExp(r'^packages/'), // Package paths
  RegExp(r'^\[.*\]$'), // Log tags like [USP]
  RegExp(r'^[\d.]+$'), // Pure numbers
  RegExp(r'^[a-z]{2}(_[A-Z]{2})?$'), // Locale codes: en, zh_TW
  RegExp(r'\be\.g\.', caseSensitive: false), // Example hints: "e.g. ..."
  RegExp(r'\bAA:BB:CC', caseSensitive: false), // Placeholder MAC example
  RegExp(r'\bAKIA'), // AWS key example token
  RegExp(r'^\d+\.\d+\.\d+\.\d+'), // IP-address example literals
  RegExp(r'^[0-9a-fA-F]{0,4}:[0-9a-fA-F:]*:'), // IPv6 example literals
  RegExp(r'\\u[0-9a-fA-F]{4}'), // Unicode escape like •
  RegExp(r'^\w+\.\w+$'), // File names: foo.dart
  RegExp(r'^/[\w/]+$'), // Route paths: /settings/wifi
  RegExp(r'^[A-Z][a-z]+\.[A-Z]'), // Enum-like: RouteNamed.xxx
  RegExp(r'^\s*$'), // Whitespace only
  RegExp(r'^[^a-zA-Z]*$'), // No letters (symbols, numbers only)
];

// Minimum length for strings to be considered
const int _minStringLength = 2;

// File patterns to skip
final _skipFilePatterns = [
  RegExp(r'\.g\.dart$'), // Generated files
  RegExp(r'\.freezed\.dart$'), // Freezed generated
  RegExp(r'_test\.dart$'), // Test files
  RegExp(r'/generated/'), // Generated directory
  RegExp(r'/l10n/'), // Localization directory
  // USP Console: a developer-only diagnostics page gated behind kDebugMode /
  // GlobalConfig.feature.enableTestConsole — never shown to end users, so its
  // strings are intentionally not localized (same rationale as lib/demo/).
  RegExp(r'/test_console/'),
];

CheckResult _checkHardcodedStrings() {
  final issues = <String>[];
  final fileFindings = <String, List<_HardcodedString>>{};

  // Add scan scope table to report
  issues.add('**Scan scope:**');
  issues.add('');
  issues.add('| Directory | Included | Reason |');
  issues.add('|-----------|----------|--------|');
  issues.add('| `lib/page/` | ✅ | All page UIs |');
  issues.add('| `lib/components/` | ✅ | Shared UI components |');
  issues.add('| `lib/util/` | ✅ | UI helpers (snackbar, QR code) |');
  issues.add('| `lib/core/` | ❌ | Low-level APIs |');
  issues.add('| `lib/generated/` | ❌ | Codegen output |');
  issues.add('| `lib/providers/` | ❌ | State management, no UI |');
  issues.add('| `lib/route/` | ❌ | Route definitions |');
  issues.add('| `lib/framework/` | ❌ | Infrastructure |');
  issues.add('| `lib/theme/` | ❌ | Theme config |');
  issues.add('| `lib/ai/` | ❌ | No hardcoded strings |');
  issues.add('| `lib/demo/` | ❌ | Dev-only, no translation needed |');
  issues.add(
      '| `lib/page/test_console/` | ❌ | USP Console — dev-only (debug/flag gated) |');
  issues.add('');

  // Placeholder for issue count - will be replaced after scanning
  final issueCountIndex = issues.length;
  issues.add(''); // placeholder

  // Reviewer note: this list is a starting point, not a to-do list.
  issues.add('> **Note for reviewers:** Each entry below is a real hardcoded '
      'string, but not all of them should be translated. The list mixes:');
  issues.add('>');
  issues.add('> - **User-facing copy** that genuinely needs `loc()` '
      '(e.g. "View all", "No devices online", dialog/notification text).');
  issues.add('> - **Technical terms / acronyms** that are conventionally kept '
      'in English (e.g. WAN, LAN, DNS, DHCP, MTU, IPv6, TCP/UDP, Mbps, DST).');
  issues.add('>');
  issues.add('> Deciding which is which is a **developer/product call** — the '
      'tool only flags candidates and deliberately stays conservative '
      '(near-zero false positives), so a few cross-line cases may be missed '
      'and should be caught by manual review.');
  issues.add('');

  for (final dir in _hardcodedScanDirs) {
    final dirPath = Directory(dir);
    if (!dirPath.existsSync()) continue;

    for (final file in _getDartFiles(dir)) {
      // Skip excluded file patterns
      if (_skipFilePatterns.any((p) => p.hasMatch(file))) continue;

      final findings = _findHardcodedStrings(file);
      if (findings.isNotEmpty) {
        fileFindings[file] = findings;
      }
    }
  }

  // Sort by file path
  final sortedFiles = fileFindings.keys.toList()..sort();

  for (final file in sortedFiles) {
    final findings = fileFindings[file]!;
    final relativePath = file.replaceFirst(RegExp(r'^lib/'), '');
    issues.add('### $relativePath');
    issues.add('');
    var idx = 0;
    for (final f in findings) {
      idx++;
      final preview =
          f.value.length > 50 ? '${f.value.substring(0, 50)}...' : f.value;
      issues.add('$idx. Line ${f.line}: `"$preview"`');
    }
    issues.add('');
  }

  final totalFindings =
      fileFindings.values.fold<int>(0, (sum, list) => sum + list.length);

  // Replace placeholder with actual issue count
  issues[issueCountIndex] = totalFindings > 0
      ? '❌ Found **$totalFindings** issue(s).\n'
      : '✅ No issues found.\n';

  return CheckResult(
    title: '[Hardcoded Strings] (in lib/page/, lib/components/, lib/util/)',
    issueCount: totalFindings,
    details: issues.join('\n'),
  );
}

class _HardcodedString {
  final int line;
  final String value;
  _HardcodedString(this.line, this.value);
}

List<_HardcodedString> _findHardcodedStrings(String filePath) {
  final content = File(filePath).readAsStringSync();
  final lines = content.split('\n');
  final findings = <_HardcodedString>[];

  // DESIGN: precision over recall. This detector must produce (near-)zero
  // false positives so the report stays trustworthy. We therefore only match
  // high-confidence, SAME-LINE display contexts. Strings split across lines by
  // `dart format` (e.g. `AppText.bodySmall(\n  'Online',\n)`) are deliberately
  // NOT chased — cross-line look-ahead reliably mis-fires on const data tables
  // and multi-line Semantics labels. Those few misses are expected to be
  // caught by human review instead.

  // Pattern to match string literals in UI contexts
  // Match: Text('...'), AppText.xxx('...'), title: '...', label: '...', etc.
  final uiContextPattern = RegExp(
    r'''(?:Text|AppText\.\w+)\s*\(\s*['"]([^'"]+)['"]''',
  );

  // Match named parameters commonly used for user-facing text.
  // Only names that are (verified) UI-text-only — NOT generic data fields like
  // `name`/`status`/`description` which also appear in models/const tables.
  // Exclude: semanticLabel, identifier (accessibility/testing, not user-visible)
  final namedParamPattern = RegExp(
    r'''(?:title|hintText|errorText|helperText|detailLabel|message|tooltip)\s*:\s*['"]([^'"]+)['"]''',
  );

  // Match label: but exclude semanticLabel and Semantics context
  // Only match if the string contains spaces or looks like user text
  final labelPattern = RegExp(
    r'''(?<!semantic)label\s*:\s*['"]([^'"]+)['"]''',
  );

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineNum = i + 1;
    final trimmed = line.trimLeft();

    // Skip comment lines
    if (trimmed.startsWith('//')) continue;

    // Skip lines that already use loc()
    if (line.contains('loc(')) continue;

    // Skip Semantics labels (accessibility, not user-visible text).
    // The `label:`/`identifier:` may sit a few lines below the `Semantics(`
    // opener after `dart format`, so look back a small window too.
    if (line.contains('Semantics(') || line.contains('identifier:')) continue;
    var inSemantics = false;
    for (var b = i - 1; b >= 0 && b >= i - 4; b--) {
      final bl = lines[b];
      if (bl.contains('Semantics(') || bl.contains('identifier:')) {
        inSemantics = true;
        break;
      }
      // a closing/child boundary means we're no longer in the opener's args
      if (bl.contains('child:') || RegExp(r'^\s*\)').hasMatch(bl)) break;
    }
    if (inSemantics) continue;

    void addIfReportable(String value) {
      if (findings.any((f) => f.line == lineNum && f.value == value)) return;
      if (_shouldReport(value)) {
        findings.add(_HardcodedString(lineNum, value));
      }
    }

    // NOTE: strings stored in a plain variable before rendering
    // (e.g. `final label = cond ? 'View all' : 'View details'`) are NOT
    // detected — the patterns below only match the Text()/AppText()/named-param
    // forms. This is a deliberate known recall gap (precision over recall);
    // such cases are expected to be caught by manual review of the running app.

    // Check Text/AppText widgets (same-line)
    for (final match in uiContextPattern.allMatches(line)) {
      addIfReportable(match.group(1)!);
    }

    // Check named parameters (same-line)
    for (final match in namedParamPattern.allMatches(line)) {
      addIfReportable(match.group(1)!);
    }

    // Check label: (same-line; not semanticLabel:)
    for (final match in labelPattern.allMatches(line)) {
      final value = match.group(1)!;
      if (!value.contains(' ') && RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
        continue;
      }
      addIfReportable(value);
    }
  }

  return findings;
}

bool _shouldReport(String value) {
  // Too short
  if (value.length < _minStringLength) return false;

  // Pure interpolation with no translatable static text, e.g. '$e', '$count',
  // '${foo.bar}'. Strip Dart interpolations and any leftover punctuation; if
  // nothing alphabetic remains, there is nothing to translate.
  final withoutInterp = value.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
  if (!RegExp(r'[a-zA-Z]').hasMatch(withoutInterp)) return false;

  // Matches ignore pattern
  if (_ignorePatterns.any((p) => p.hasMatch(value))) return false;

  // Looks like a code identifier (camelCase or snake_case without spaces)
  if (!value.contains(' ') &&
      (value.contains('_') || RegExp(r'^[a-z]+[A-Z]').hasMatch(value))) {
    return false;
  }

  return true;
}

// =============================================================================
// Utilities
// =============================================================================

class CheckResult {
  final String title;
  final int issueCount;
  final String details;
  CheckResult(
      {required this.title, required this.issueCount, required this.details});
}

Map<String, dynamic> _loadArb(String path) {
  final content = File(path).readAsStringSync();
  return jsonDecode(content) as Map<String, dynamic>;
}

List<String> _getArbFiles() {
  return Directory(arbDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .map((f) => f.path)
      .toList()
    ..sort();
}

List<String> _getDartFiles(String dir) {
  final files = <String>[];
  for (final entity in Directory(dir).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity.path);
    }
  }
  return files;
}

String _basename(String path) => path.split('/').last;

Map<String, dynamic> _parseArgs(List<String> args) {
  final options = <String, dynamic>{};

  for (final arg in args) {
    if (arg == '--help' || arg == '-h') {
      options['help'] = true;
    } else if (arg == '--stdout') {
      options['stdout'] = true;
    } else if (arg == '--brief') {
      options['brief'] = true;
    } else if (arg.startsWith('--only=')) {
      options['only'] = arg.substring(7);
    } else if (arg.startsWith('--output=')) {
      options['output'] = arg.substring(9);
    }
  }

  return options;
}

void _printUsage() {
  print('''
L10n Health Check Tool

Usage:
  dart run tools/check_l10n.dart [options]

Options:
  --only=<check>    Run only specific check:
                    - duplicate-keys
                    - duplicate-values
                    - unused-keys
                    - orphan-keys
                    - missing-translations
                    - hardcoded-strings
  --output=<file>   Write markdown report to file (default: l10n-report.md)
  --stdout          Output to stdout instead of file
  --brief           Truncate findings at 20 items (default: show all)
  --help, -h        Show this help

Examples:
  dart run tools/check_l10n.dart                     # Full report to l10n-report.md
  dart run tools/check_l10n.dart --stdout --brief    # Quick summary to console
  dart run tools/check_l10n.dart --only=orphan-keys  # Single check to file
''');
}
