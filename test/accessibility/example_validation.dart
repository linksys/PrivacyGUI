/// PrivacyGUI Accessibility Validation Example
///
/// This script demonstrates how to use the WCAG validation system in PrivacyGUI project
///
/// How to run:
/// ```bash
/// flutter test test/accessibility/example_validation.dart
/// ```
///
/// Note: This example requires Flutter testing environment because it uses Flutter Size type.
/// Actual validation should be performed in widget tests, using WidgetTester to measure actual component size.

import 'dart:io';
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';
import 'package:flutter/material.dart';

void main() {
  print('╔════════════════════════════════════════════════════════╗');
  print('║     PrivacyGUI WCAG 可訪問性驗證範例                    ║');
  print('╚════════════════════════════════════════════════════════╝\n');

  // Demo 1: Single Success Criterion Validation
  print('【Demo 1】Target Size (SC 2.5.5) 驗證\n');
  demoTargetSizeValidation();

  print('\n' + '=' * 60 + '\n');

  // Demo 2: Batch Validation
  print('【Demo 2】批量驗證（多個 Success Criteria）\n');
  demoBatchValidation();

  print('\n' + '=' * 60 + '\n');

  // Demo 3: Report Comparison
  print('【Demo 3】報告版本比較\n');
  demoReportComparison();

  print('\n' + '=' * 60 + '\n');

  // Demo 4: Cache Usage
  print('【Demo 4】使用快取提升效能\n');
  demoCaching();

  print('\n╔════════════════════════════════════════════════════════╗');
  print('║  驗證Completed！請查看 reports/accessibility/ 目錄的報告     ║');
  print('╚════════════════════════════════════════════════════════╝');
}

/// Demo 1: Target Size 驗證
void demoTargetSizeValidation() {
  print('1️⃣  Creating TargetSizeReporter...');
  final reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);

  print('2️⃣  Validating PrivacyGUI component sizes...\n');

  // Mock validating common components in PrivacyGUI
  final components = [
    (
      'Dashboard_RefreshButton',
      Size(48, 48),
      'lib/pages/dashboard/widgets/refresh_button.dart'
    ),
    (
      'Navigation_MenuButton',
      Size(50, 50),
      'lib/widgets/navigation/menu_button.dart'
    ),
    (
      'Settings_SaveButton',
      Size(48, 48),
      'lib/pages/settings/widgets/save_button.dart'
    ),
    (
      'Device_ConnectButton',
      Size(46, 46),
      'lib/pages/devices/widgets/connect_button.dart'
    ),
    (
      'Toolbar_IconButton',
      Size(44, 44),
      'lib/widgets/toolbar/icon_button.dart'
    ),
    (
      'Quick_ActionButton',
      Size(40, 40),
      'lib/pages/dashboard/widgets/quick_action.dart'
    ), // This will fail
  ];

  for (final (name, size, path) in components) {
    reporter.validateComponent(
      componentName: name,
      actualSize: size,
      affectedComponents: [name],
      widgetPath: path,
      severity: name.contains('Quick') ? Severity.medium : Severity.high,
    );

    final status = size.width >= 44 && size.height >= 44 ? '✅' : '❌';
    print('   $status $name: ${size.width}x${size.height} dp');
  }

  print('\n3️⃣  Generate report...');
  final report = reporter.generate(
    version: 'v2.0.0',
    gitCommitHash: _getGitHash(),
    environment: 'demo',
  );

  print('\n📊 Validation Results:');
  print('   Compliance Rate: ${report.score.percentage.toStringAsFixed(1)}%');
  print('   Passed: ${report.score.passed}/${report.score.total}');
  print('   Failed: ${report.score.failed}');

  if (report.criticalFailures.isNotEmpty) {
    print('   🔴 Critical Failures: ${report.criticalFailures.length}');
  }

  // Export report
  final outputDir = Directory('reports/accessibility/example');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  File('${outputDir.path}/target_size.html').writeAsStringSync(report.toHtml());
  File('${outputDir.path}/target_size.md')
      .writeAsStringSync(report.toMarkdown());

  print('\n✅ Report exported:');
  print('   - ${outputDir.path}/target_size.html');
  print('   - ${outputDir.path}/target_size.md');
}

/// Demo 2: Batch Validation
void demoBatchValidation() {
  print('1️⃣  Creating WcagBatchRunner...');
  final runner = WcagBatchRunner();

  print('2️⃣  Configuring Success Criteria...\n');

  // Target Size (SC 2.5.5)
  print('   📏 Configuring Target Size validation...');
  final targetSizeReporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);
  final targetSizeComponents = [
    ('AppButton', Size(48, 48)),
    ('IconButton', Size(50, 50)),
    ('TabButton', Size(44, 44)),
    ('FAB', Size(56, 56)),
    ('SmallButton', Size(38, 38)), // Failed
  ];

  for (final (name, size) in targetSizeComponents) {
    targetSizeReporter.validateComponent(
      componentName: name,
      actualSize: size,
      affectedComponents: [name],
      widgetPath: 'lib/widgets/*.dart',
    );
  }
  runner.addTargetSizeReporter(targetSizeReporter);
  print('      ✓ Added ${targetSizeComponents.length} component validations');

  // Focus Order (SC 2.4.3)
  print('   🎯 Configuring Focus Order validation...');
  final focusOrderReporter = FocusOrderReporter(targetLevel: WcagLevel.a);
  final focusSequence = [
    ('LoginForm_Username', 0, 0),
    ('LoginForm_Password', 1, 1),
    ('LoginForm_RememberMe', 2, 2),
    ('LoginForm_LoginButton', 3, 3),
    ('SettingsForm_Name', 0, 0),
    ('SettingsForm_Email', 1, 1),
    ('SettingsForm_SaveButton', 2, 3), // 順序Error
  ];

  for (final (name, expected, actual) in focusSequence) {
    focusOrderReporter.validateComponent(
      componentName: name,
      expectedIndex: expected,
      actualIndex: actual,
      affectedComponents: [name],
      widgetPath: 'lib/pages/*.dart',
    );
  }
  runner.addFocusOrderReporter(focusOrderReporter);
  print('      ✓ Added ${focusSequence.length} component validations');

  // Semantics (SC 4.1.2)
  print('   🏷️  Configuring Semantics validation...');
  final semanticsReporter = SemanticsReporter(targetLevel: WcagLevel.a);
  final semanticComponents = [
    ('RefreshButton', true, true, true, 'Refresh', 'Refresh', 'button'),
    ('SearchField', true, true, true, 'Search', 'Search', 'textfield'),
    (
      'NotificationBadge',
      true,
      true,
      true,
      '3 notifications',
      '3 notifications',
      'status'
    ),
    (
      'SettingsIcon',
      false,
      true,
      true,
      'Settings',
      null,
      'button'
    ), // Missing label
    ('DeviceStatus', true, true, true, 'Connected', 'Connected', 'status'),
  ];

  for (final (name, hasLabel, hasRole, exposesValue, expected, actual, role)
      in semanticComponents) {
    semanticsReporter.validateComponent(
      componentName: name,
      hasLabel: hasLabel,
      hasRole: hasRole,
      exposesValue: exposesValue,
      expectedLabel: expected,
      actualLabel: actual,
      role: role,
      affectedComponents: [name],
      widgetPath: 'lib/widgets/*.dart',
    );
  }
  runner.addSemanticsReporter(semanticsReporter);
  print('      ✓ Added ${semanticComponents.length} component validations');

  print('\n3️⃣  Generating batch results...');
  final batch = runner.generateBatch(
    version: 'v2.0.0',
    gitCommitHash: _getGitHash(),
    environment: 'demo',
  );

  print('\n📊 批量Validation Results:');
  print(
      '   整體Compliance Rate: ${batch.overallCompliance.toStringAsFixed(1)}% ${batch.statusEmoji}');
  print('   測試的 Success Criteria: ${batch.reportCount}');
  print('   Total Validations: ${batch.totalValidations}');
  print('   ✅ Passed: ${batch.totalPassed}');
  print('   ❌ Failed: ${batch.totalFailures}');
  print('   🔴 Critical Failures: ${batch.totalCriticalFailures}');

  print('\n   各 Success Criterion 詳情:');
  for (final report in batch.reports) {
    final emoji = report.score.statusEmoji;
    final percentage = report.score.percentage.toStringAsFixed(1);
    print('   $emoji ${report.successCriterion} - $percentage%');
  }

  // Export report
  final outputDir = Directory('reports/accessibility/example/batch');
  batch.exportAll(outputDirectory: outputDir);

  print('\n✅ 批量Report exported:');
  print('   - ${outputDir.path}/full.html (⭐ 完整整合報告)');
  print('   - ${outputDir.path}/overview.html (批量總覽)');
  print('   - ${outputDir.path}/sc_*.html (個別 SC 報告)');
}

/// Demo 3: Report Comparison
void demoReportComparison() {
  print('1️⃣  建立兩個版本的報告...\n');

  // 版本 1.0.0 的報告
  print('   📋 版本 1.0.0 的驗證...');
  final reporter1 = TargetSizeReporter(targetLevel: WcagLevel.aaa);
  final v1Components = [
    ('AppButton', Size(48, 48)),
    ('IconButton', Size(42, 42)), // 太小
    ('TabButton', Size(40, 40)), // 太小
    ('FAB', Size(56, 56)),
  ];

  for (final (name, size) in v1Components) {
    reporter1.validateComponent(
      componentName: name,
      actualSize: size,
      affectedComponents: [name],
    );
  }

  final report1 = reporter1.generate(
    version: 'v1.0.0',
    gitCommitHash: 'abc123',
    environment: 'demo',
  );
  print(
      '      Compliance Rate: ${report1.score.percentage.toStringAsFixed(1)}%');

  // 版本 2.0.0 的報告（改進後）
  print('   📋 版本 2.0.0 的驗證（已改進）...');
  final reporter2 = TargetSizeReporter(targetLevel: WcagLevel.aaa);
  final v2Components = [
    ('AppButton', Size(48, 48)),
    ('IconButton', Size(50, 50)), // 已修復 ✅
    ('TabButton', Size(44, 44)), // 已修復 ✅
    ('FAB', Size(56, 56)),
  ];

  for (final (name, size) in v2Components) {
    reporter2.validateComponent(
      componentName: name,
      actualSize: size,
      affectedComponents: [name],
    );
  }

  final report2 = reporter2.generate(
    version: 'v2.0.0',
    gitCommitHash: _getGitHash(),
    environment: 'demo',
  );
  print(
      '      Compliance Rate: ${report2.score.percentage.toStringAsFixed(1)}%');

  // 比較報告
  print('\n2️⃣  比較兩個版本...');
  final comparison = ReportComparator.compare(
    currentReport: report2,
    previousReport: report1,
  );

  print('\n📊 比較結果:');
  print('   版本變化: ${report1.metadata.version} → ${report2.metadata.version}');
  print(
      '   Compliance Rate變化: ${comparison.complianceChange > 0 ? '+' : ''}${comparison.complianceChange.toStringAsFixed(1)}%');
  print(
      '   ${comparison.direction.emoji} ${comparison.direction == TrendDirection.improving ? '改善中' : comparison.direction == TrendDirection.declining ? '退步' : '穩定'}');

  if (comparison.fixedIssues.isNotEmpty) {
    print('\n   ✅ 已修復的問題 (${comparison.fixedIssues.length}):');
    for (final issue in comparison.fixedIssues) {
      print('      • ${issue.componentName}');
    }
  }

  if (comparison.regressions.isNotEmpty) {
    print('\n   ⚠️  新增的問題 (${comparison.regressions.length}):');
    for (final regression in comparison.regressions) {
      print('      • ${regression.componentName}');
    }
  }

  // 匯出比較報告
  final outputDir = Directory('reports/accessibility/example');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  File('${outputDir.path}/comparison.html')
      .writeAsStringSync(comparison.toHtml());

  print('\n✅ 比較Report exported:');
  print('   - ${outputDir.path}/comparison.html');
}

/// Demo 4: Cache Usage
void demoCaching() {
  print('1️⃣  建立快取...');
  final cache = ReportMemoryCache(defaultTtl: const Duration(minutes: 15));

  print('2️⃣  第一次驗證（Generate report）...');
  final stopwatch1 = Stopwatch()..start();

  final report1 = cache.getOrGenerate('privacygui_v2.0.0', () {
    print('   🔄 生成新報告...');
    final reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);

    // 模擬多個元件驗證
    for (var i = 0; i < 10; i++) {
      reporter.validateComponent(
        componentName: 'Component_$i',
        actualSize: Size(48, 48),
        affectedComponents: ['Component_$i'],
      );
    }

    return reporter.generate(
      version: 'v2.0.0',
      gitCommitHash: _getGitHash(),
      environment: 'demo',
    );
  });

  stopwatch1.stop();
  print('   ⏱️  耗時: ${stopwatch1.elapsedMilliseconds}ms');

  print('\n3️⃣  第二次驗證（使用快取）...');
  final stopwatch2 = Stopwatch()..start();

  final report2 = cache.getOrGenerate('privacygui_v2.0.0', () {
    print('   🔄 生成新報告...');
    // 這段不會執行，因為已有快取
    return report1;
  });

  stopwatch2.stop();
  print('   ⚡ 耗時: ${stopwatch2.elapsedMilliseconds}ms');
  print(
      '   ${stopwatch2.elapsedMilliseconds < stopwatch1.elapsedMilliseconds ? '✅ 快取加速！' : ''}');
  print('   ${identical(report1, report2) ? '✅ 返回相同實例 (快取命中)' : ''}');

  print('\n📊 快取統計:');
  final stats = cache.stats;
  print('   總條目: ${stats.totalEntries}');
  print('   有效條目: ${stats.activeEntries}');
  print('   過期條目: ${stats.expiredEntries}');
  print('   命中率: ${(stats.hitRate * 100).toStringAsFixed(1)}%');

  print('\n💡 Tip: 在 CI/CD 環境中，快取可以顯著提升驗證速度');
}

/// 取得 Git commit hash
String _getGitHash() {
  try {
    final result = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
    return result.stdout.toString().trim();
  } catch (e) {
    return 'demo123';
  }
}
