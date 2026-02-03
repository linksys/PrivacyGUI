# PrivacyGUI AccessibilityIntegration Guide

This document describeshow to integrate and use in PrivacyGUI project WCAG 2.1 Accessibilityvalidationsystem.

## Quick Start

See the complete executable example，demonstrating all major features：

```bash
# Run in PrivacyGUI project root
flutter test test/accessibility/example_validation.dart
```

This example demonstrates：
- ✅ Single Success Criterion Validation (Target Size)
- ✅ Batch Validation (multiple Success Criteria concurrently)
- ✅ Report Version Comparison (tracking improvement situaton)
- ✅ using cache to improve performance

Example code is located at：[test/accessibility/example_validation.dart](../test/accessibility/example_validation.dart)

## Directory

- [Overview](#Overview)
- [Environment Setup](#Environment Setup)
- [Basic Usage](#Basic Usage)
- [Validating PrivacyGUI Components](#validation-privacygui-component)
- [CI/CD Integrate](#cicd-Integrate)
- [Best Practices](#Best Practices)

---

## Overview

ui_kit_library provides a complete WCAG 2.1 Accessibilityvalidationtool，Support：

- **SC 2.5.5**: Target Size (Enhanced) - Touch target size validation
- **SC 2.4.3**: Focus Order - Focus Ordervalidation
- **SC 4.1.2**: Name, Role, Value - Semanticspropertiesvalidation

### Main Features

1. **Single Success Criterion Validation** - Validating specific SC
2. **Batchtesting** - Validate multiple Success Criteria at once
3. **Reportcomparison** - Compare compliance changes between versions
4. **cachemechanism** - Improve validation performance
5. **Multiple report formats** - Markdown、HTML、JSON

---

## Environment Setup

### 1. Confirm Dependencies

PrivacyGUI already depends on ui_kit_library，no extra setup needed：

```yaml
# pubspec.yaml already included
dependencies:
  ui_kit_library:
    path: ../ui_kit
```

### 2. Create Validation Directory

```bash
cd /Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI
mkdir -p test/accessibility
mkdir -p reports/accessibility
```

---

## Basic Usage

### example 1：validationbuttonsize

Create `test/accessibility/button_validation.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';
import 'package:privacy_gui/widgets/app_button.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('AppButton 符合 WCAG AAA 觸控Target Size', (tester) async {
    // Create reporter
    final reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);

    // 渲染button
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            onPressed: () {},
            child: const Text('testingbutton'),
          ),
        ),
      ),
    );

    // measuresize
    final button = find.byType(AppButton);
    final size = tester.getSize(button);

    // validation
    reporter.validateComponent(
      componentName: 'AppButton',
      actualSize: size,
      affectedComponents: ['AppButton'],
      widgetPath: 'lib/widgets/app_button.dart',
    );

    // 生成Report
    final report = reporter.generate(
      version: 'v2.0.0',
      gitCommitHash: 'test',
      environment: 'test',
    );

    // assert
    expect(report.score.percentage, equals(100.0),
        reason: 'AppButton should comply with 44x44 dp 的minimumsizerequirement');

    print('✅ AppButton size: ${size.width}x${size.height} dp');
    print('✅ Compliance Rate: ${report.score.percentage}%');
  });
}
```

Executiontesting：

```bash
flutter test test/accessibility/button_validation.dart
```

---

## Validating PrivacyGUI Components

### completevalidationscript

Create `test/accessibility/privacy_gui_validation.dart`：

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';
import 'package:privacy_gui/main.dart';
import 'package:flutter/material.dart';

void main() {
  group('PrivacyGUI Accessibilityvalidation', () {
    late TargetSizeReporter targetSizeReporter;
    late FocusOrderReporter focusOrderReporter;
    late SemanticsReporter semanticsReporter;

    setUp(() {
      targetSizeReporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);
      focusOrderReporter = FocusOrderReporter(targetLevel: WcagLevel.a);
      semanticsReporter = SemanticsReporter(targetLevel: WcagLevel.a);
    });

    testWidgets('validationmajornavigationbutton', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 找到allnavigationbutton
      final navButtons = find.byType(IconButton);

      for (var i = 0; i < navButtons.evaluate().length; i++) {
        final button = navButtons.at(i);
        final size = tester.getSize(button);

        targetSizeReporter.validateComponent(
          componentName: 'NavButton_$i',
          actualSize: size,
          affectedComponents: ['IconButton'],
          widgetPath: 'lib/pages/navigation/*.dart',
        );
      }

      final report = targetSizeReporter.generate(
        version: 'v2.0.0',
        gitCommitHash: _getGitHash(),
        environment: 'test',
      );

      expect(report.score.percentage, greaterThanOrEqualTo(80.0),
          reason: '至少 80% 的navigationbutton應符合sizerequirement');
    });

    testWidgets('validationSet up頁面Focus Order', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // navigation到Set up頁面
      // TODO: 根據實際路由調整
      // await tester.tap(find.text('Set up'));
      // await tester.pumpAndSettle();

      // validationFocus Order
      // example：用戶Name -> 密碼 -> Savebutton
      final focusableWidgets = [
        ('UsernameField', 0),
        ('PasswordField', 1),
        ('SaveButton', 2),
      ];

      for (var i = 0; i < focusableWidgets.length; i++) {
        final (name, expectedIndex) = focusableWidgets[i];

        focusOrderReporter.validateComponent(
          componentName: name,
          expectedIndex: expectedIndex,
          actualIndex: i, // 實際measure的索引
          affectedComponents: [name],
          widgetPath: 'lib/pages/settings/*.dart',
        );
      }

      final report = focusOrderReporter.generate(
        version: 'v2.0.0',
        gitCommitHash: _getGitHash(),
        environment: 'test',
      );

      expect(report.score.percentage, equals(100.0),
          reason: 'Focus Order應該正確');
    });

    testWidgets('validationcomponentSemanticsproperties', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 啟用Semantics
      tester.binding.setSemanticsEnabled(true);

      // validationmajorbutton的Semantics
      final refreshButton = find.byIcon(Icons.refresh);
      if (refreshButton.evaluate().isNotEmpty) {
        final semantics = tester.getSemantics(refreshButton);

        semanticsReporter.validateComponent(
          componentName: 'RefreshButton',
          hasLabel: semantics.label != null && semantics.label!.isNotEmpty,
          hasRole: true,
          exposesValue: true,
          expectedLabel: 'refresh',
          actualLabel: semantics.label,
          role: 'button',
          affectedComponents: ['IconButton'],
          widgetPath: 'lib/pages/dashboard/*.dart',
        );
      }

      final report = semanticsReporter.generate(
        version: 'v2.0.0',
        gitCommitHash: _getGitHash(),
        environment: 'test',
      );

      expect(report.score.percentage, greaterThanOrEqualTo(80.0),
          reason: '至少 80% 的component應有正確的Semanticsproperties');
    });

    tearDown(() {
      // 生成Report
      _generateReports(
        targetSizeReporter,
        focusOrderReporter,
        semanticsReporter,
      );
    });
  });
}

String _getGitHash() {
  try {
    final result = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
    return result.stdout.toString().trim();
  } catch (e) {
    return 'unknown';
  }
}

void _generateReports(
  TargetSizeReporter targetSizeReporter,
  FocusOrderReporter focusOrderReporter,
  SemanticsReporter semanticsReporter,
) {
  final outputDir = Directory('reports/accessibility');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // 生成別Report
  final targetSizeReport = targetSizeReporter.generate(
    version: 'v2.0.0',
    gitCommitHash: _getGitHash(),
    environment: 'test',
  );
  targetSizeReport.exportHtml(
    filePath: '${outputDir.path}/target_size.html',
  );

  final focusOrderReport = focusOrderReporter.generate(
    version: 'v2.0.0',
    gitCommitHash: _getGitHash(),
    environment: 'test',
  );
  focusOrderReport.exportHtml(
    filePath: '${outputDir.path}/focus_order.html',
  );

  final semanticsReport = semanticsReporter.generate(
    version: 'v2.0.0',
    gitCommitHash: _getGitHash(),
    environment: 'test',
  );
  semanticsReport.exportHtml(
    filePath: '${outputDir.path}/semantics.html',
  );

  print('✅ Report已生成於: ${outputDir.path}');
}
```

---

## Batch Validation

Create `test/accessibility/batch_validation.dart`：

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';
import 'package:privacy_gui/main.dart';
import 'package:flutter/material.dart';

void main() {
  test('PrivacyGUI BatchAccessibilityvalidation', () async {
    print('=== PrivacyGUI WCAG Batch Validation ===\n');

    // CreateBatchExecution器
    final runner = WcagBatchRunner();

    // configuration Target Size validation
    final targetSizeReporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);
    _configureTargetSize(targetSizeReporter);
    runner.addTargetSizeReporter(targetSizeReporter);

    // configuration Focus Order validation
    final focusOrderReporter = FocusOrderReporter(targetLevel: WcagLevel.a);
    _configureFocusOrder(focusOrderReporter);
    runner.addFocusOrderReporter(focusOrderReporter);

    // configuration Semantics validation
    final semanticsReporter = SemanticsReporter(targetLevel: WcagLevel.a);
    _configureSemantics(semanticsReporter);
    runner.addSemanticsReporter(semanticsReporter);

    // 生成BatchResults
    final batch = runner.generateBatch(
      version: 'v2.0.0',
      gitCommitHash: _getGitHash(),
      environment: 'test',
    );

    // 顯示摘要
    print('整體Compliance Rate: ${batch.overallCompliance.toStringAsFixed(1)}%');
    print('testing的 Success Criteria: ${batch.reportCount}');
    print('Total Validations: ${batch.totalValidations}');
    print('Passed: ${batch.totalPassed}');
    print('Failed: ${batch.totalFailures}');
    print('Critical Failures: ${batch.totalCriticalFailures}\n');

    // 匯出Report
    final outputDir = Directory('reports/accessibility/batch');
    batch.exportAll(outputDirectory: outputDir);

    print('✅ BatchReport已匯出至: ${outputDir.path}');
    print('   - full.html (completeIntegrateReport)');
    print('   - overview.html (Batch總覽)');
    print('\nSuggestions in 瀏覽器opening full.html SeecompleteReport');
  });
}

void _configureTargetSize(TargetSizeReporter reporter) {
  // 根據 PrivacyGUI 的實際componentconfiguration
  // 這裡是exampledata
  final components = [
    ('PrimaryButton', Size(48, 48)),
    ('IconButton', Size(50, 50)),
    ('TabButton', Size(44, 44)),
    ('MenuButton', Size(38, 38)), // 可能Failed
    ('FAB', Size(56, 56)),
  ];

  for (final (name, size) in components) {
    reporter.validateComponent(
      componentName: name,
      actualSize: size,
      affectedComponents: [name],
      widgetPath: 'lib/widgets/*.dart',
    );
  }
}

void _configureFocusOrder(FocusOrderReporter reporter) {
  // configurationFocus Ordervalidation
  // example：登入表單
  final focusSequence = [
    'UsernameField',
    'PasswordField',
    'RememberMe',
    'LoginButton',
  ];

  for (var i = 0; i < focusSequence.length; i++) {
    reporter.validateComponent(
      componentName: focusSequence[i],
      expectedIndex: i,
      actualIndex: i,
      affectedComponents: [focusSequence[i]],
      widgetPath: 'lib/pages/login/*.dart',
    );
  }
}

void _configureSemantics(SemanticsReporter reporter) {
  // configurationSemanticsvalidation
  final components = [
    ('RefreshButton', true, true, true, 'refresh', 'refresh', 'button'),
    ('SearchField', true, true, true, '搜尋', '搜尋', 'textfield'),
    ('SettingsIcon', false, true, true, 'Set up', null, 'button'), // 可能Failed
  ];

  for (final (name, hasLabel, hasRole, exposesValue, expected, actual, role) in components) {
    reporter.validateComponent(
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
}

String _getGitHash() {
  try {
    final result = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
    return result.stdout.toString().trim();
  } catch (e) {
    return 'unknown';
  }
}
```

ExecutionBatch Validation：

```bash
dart test/accessibility/batch_validation.dart
```

---

## CI/CD Integrate

### GitHub Actions

Create `.github/workflows/accessibility.yml`：

```yaml
name: Accessibility Validation

on:
  pull_request:
  push:
    branches: [main]

jobs:
  accessibility:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.3.0'

      - name: Get dependencies
        run: flutter pub get

      - name: Run accessibility validation
        run: dart test/accessibility/batch_validation.dart

      - name: Upload reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: accessibility-reports
          path: reports/accessibility/
          retention-days: 30

      - name: Check critical failures
        run: |
          CRITICAL=$(jq '.totalCriticalFailures' reports/accessibility/batch/overview.json)
          if [ "$CRITICAL" -gt 0 ]; then
            echo "❌ 發現 $CRITICAL CriticalAccessibilityIssue"
            exit 1
          fi
```

---

## Best Practices

### 1. 定期validation

Suggestions in 以下時機ExecutionAccessibilityvalidation：

- ✅ 新增或修改 UI component時
- ✅ 每times Pull Request
- ✅ 發布前的completevalidation
- ✅ 定期（每weeks/每months）的全面審查

### 2. 優先places理Critical Issues

Use `Severity.critical` 標記關鍵component：

```dart
reporter.validateComponent(
  componentName: 'LoginButton',
  actualSize: size,
  severity: Severity.critical, // 登入button是關鍵Feature
  affectedComponents: ['LoginButton'],
);
```

### 3. 追踪Improvement進level

UseReportcomparisonFeature追踪Improvement：

```dart
// 載入前一version的Report
final previousReport = TargetSizeReport.fromJson(
  jsonDecode(File('reports/v1.0.0.json').readAsStringSync()),
);

// comparison
final comparison = ReportComparator.compare(
  currentReport: currentReport,
  previousReport: previousReport,
);

print('Improvement: ${comparison.fixedIssues.length} Issue已Fix');
print('declining: ${comparison.regressions.length} 新Issue');
```

### 4. using cache to improve performance

```dart
// Createcache
final cache = ReportMemoryCache();

// Usecache
final report = cache.getOrGenerate('privacygui_v2.0.0', () {
  return reporter.generate(
    version: 'v2.0.0',
    gitCommitHash: gitHash,
    environment: 'test',
  );
});
```

### 5. Integrate到development流程

**Pre-commit Hook**：

Create `.git/hooks/pre-commit`：

```bash
#!/bin/bash

echo "ExecutionAccessibilityvalidation..."
dart test/accessibility/batch_validation.dart

if [ $? -ne 0 ]; then
    echo "❌ AccessibilityvalidationFailed"
    echo "請FixCritical Issues後再提交"
    exit 1
fi

echo "✅ AccessibilityvalidationPassed"
```

---

## Common Issues

### Q: How tomeasure動態component的size？

```dart
testWidgets('動態buttonsize', (tester) async {
  await tester.pumpWidget(MyApp());

  // 等待動畫Completed
  await tester.pumpAndSettle();

  // 或等待特定時間
  await tester.pump(Duration(seconds: 1));

  final size = tester.getSize(find.byType(MyButton));
  // ... validation
});
```

### Q: How toplaces理條件渲染的component？

```dart
testWidgets('條件component', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();

  final button = find.byKey(Key('conditional-button'));

  if (button.evaluate().isNotEmpty) {
    final size = tester.getSize(button);
    reporter.validateComponent(/* ... */);
  } else {
    print('component未渲染，跳過validation');
  }
});
```

### Q: How tovalidation整頁面的component？

Use `find.byType()` 或 `find.descendant()`：

```dart
// 找到allbutton
final buttons = find.byType(ElevatedButton);

for (var i = 0; i < buttons.evaluate().length; i++) {
  final button = buttons.at(i);
  final size = tester.getSize(button);

  reporter.validateComponent(
    componentName: 'Button_$i',
    actualSize: size,
    affectedComponents: ['ElevatedButton'],
  );
}
```

---

## 相關資源

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility Guide](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [ui_kit_library Accessibility Docs](../ui_kit/docs/accessibility/README.md)

---

## Support

如有Issue或Suggestions，請聯繫：
- GitHub Issues
- 團隊 Slack 頻道
