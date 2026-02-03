/// 無障礙測試模式對比範例
///
/// 展示三種不同的測試模式：
/// 1. 嚴謹模式（Strict Mode）- 當前使用
/// 2. 寬鬆模式（Lenient Mode）- 只記錄
/// 3. 混合模式（Hybrid Mode）- 根據Severity決定

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  group('模式對比：無障礙測試', () {
    late TargetSizeReporter reporter;

    setUp(() {
      reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);
    });

    // ═══════════════════════════════════════════════════════════
    // 模式 1：嚴謹模式（Strict Mode）- 當前 widget_accessibility_test.dart 使用的方式
    // ═══════════════════════════════════════════════════════════
    group('模式 1: 嚴謹模式（當前使用）', () {
      testWidgets('如果元件不符合標準，測試會立即Failed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                width: 32, // 故意Settings太小
                height: 32,
                color: Colors.blue,
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(Container).first);

        // Step 1: 記錄到報告
        reporter.validateComponent(
          componentName: 'SmallContainer',
          actualSize: size,
          severity: Severity.critical,
        );

        // Step 2: 強制測試Failed ⭐
        expect(
          size.width >= 44 && size.height >= 44,
          isTrue,
          reason: 'Size ${size.width}x${size.height} should be at least 44x44',
        );

        // ❌ 如果元件是 32×32，測試會在這裡Failed！
        // 控制台會顯示紅色Error訊息
      });

      testWidgets('如果元件符合標準，測試正常Passed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                width: 48, // 符合 AAA 標準
                height: 48,
                color: Colors.blue,
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(Container).first);

        reporter.validateComponent(
          componentName: 'GoodContainer',
          actualSize: size,
        );

        expect(size.width >= 44 && size.height >= 44, isTrue);
        // ✅ 測試Passed
      });
    });

    // ═══════════════════════════════════════════════════════════
    // 模式 2：寬鬆模式（Lenient Mode）- 只記錄，不讓測試Failed
    // ═══════════════════════════════════════════════════════════
    group('模式 2: 寬鬆模式（只記錄）', () {
      testWidgets('即使元件不符合標準，測試也會繼續執行', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                width: 32, // 太小
                height: 32,
                color: Colors.blue,
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(Container).first);

        // 只記錄到報告，沒有 expect()
        reporter.validateComponent(
          componentName: 'SmallContainer',
          actualSize: size,
          severity: Severity.medium,
        );

        // ✅ 測試繼續執行，不會Failed
        // ❌ 但報告中會記錄此元件未Passed

        print('✅ 測試Passed了，但元件尺寸 ${size.width}x${size.height} 不符合標準');
        print('   這會記錄在報告中');
      });

      testWidgets('可以測試多個元件，全部記錄', (tester) async {
        // 測試多個尺寸
        for (final testSize in [20.0, 30.0, 40.0, 50.0]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Container(
                  width: testSize,
                  height: testSize,
                  color: Colors.blue,
                ),
              ),
            ),
          );

          final size = tester.getSize(find.byType(Container).first);

          // 全部記錄，不管是否Passed
          reporter.validateComponent(
            componentName: 'Container_${testSize}dp',
            actualSize: size,
          );

          // ✅ 全部測試都會執行完畢
        }

        print('✅ 所有 4 個尺寸都測試Completed');
        print('   20×20: 未Passed');
        print('   30×30: 未Passed');
        print('   40×40: 未Passed');
        print('   50×50: Passed');
        print('   報告中會顯示詳細結果');
      });
    });

    // ═══════════════════════════════════════════════════════════
    // 模式 3：混合模式（Hybrid Mode）- 根據Severity決定
    // ═══════════════════════════════════════════════════════════
    group('模式 3: 混合模式（智能判斷）', () {
      testWidgets('Critical 問題會讓測試Failed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                width: 32,
                height: 32,
                color: Colors.blue,
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(Container).first);
        const severity = Severity.critical;

        reporter.validateComponent(
          componentName: 'CriticalButton',
          actualSize: size,
          severity: severity,
        );

        // 只對 critical 問題強制Failed
        if (severity == Severity.critical) {
          expect(
            size.width >= 44 && size.height >= 44,
            isTrue,
            reason: 'Critical component must meet AAA standards',
          );
          // ❌ 如果是 32×32，測試會Failed
        }
      });

      testWidgets('Medium/Low 問題只記錄，不讓測試Failed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                width: 32,
                height: 32,
                color: Colors.blue,
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(Container).first);
        const severity = Severity.medium;

        reporter.validateComponent(
          componentName: 'SecondaryButton',
          actualSize: size,
          severity: severity,
        );

        // 中等嚴重度：只記錄
        if (severity == Severity.critical) {
          expect(size.width >= 44, isTrue);
        } else {
          // ✅ 不執行 expect，測試繼續
          print('⚠️ Medium severity: recorded but not failing test');
        }
      });

      testWidgets('根據環境變數決定模式（CI vs Local）', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                width: 32,
                height: 32,
                color: Colors.blue,
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(Container).first);
        const isCI = false; // 模擬本地開發環境

        reporter.validateComponent(
          componentName: 'FlexibleButton',
          actualSize: size,
        );

        // CI 環境：嚴格模式
        // Local 環境：寬鬆模式
        if (isCI) {
          expect(size.width >= 44, isTrue);
        } else {
          // ✅ 本地開發時只記錄
          print('🏠 Local mode: recording only, test continues');
        }
      });
    });

    // ═══════════════════════════════════════════════════════════
    // 模式 4：AI analysis驅動模式 - 使用分析結果決定測試結果
    // ═══════════════════════════════════════════════════════════
    group('模式 4: AI analysis驅動模式', () {
      testWidgets('根據AI analysis結果決定是否Failed測試', (tester) async {
        // 測試多個元件
        final testCases = [
          ('PrimaryButton', 32.0), // 太小
          ('SecondaryButton', 40.0), // 接近標準
          ('TertiaryButton', 48.0), // 符合標準
        ];

        for (final (name, size) in testCases) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Container(
                  width: size,
                  height: size,
                  color: Colors.blue,
                ),
              ),
            ),
          );

          final actualSize = tester.getSize(find.byType(Container).first);

          reporter.validateComponent(
            componentName: name,
            actualSize: actualSize,
            severity: size < 40 ? Severity.critical : Severity.low,
          );
        }

        // Generate report並分析
        final report = reporter.generate(
          version: 'v2.0.0',
          gitCommitHash: 'test',
          environment: 'test',
        );

        final analysis = report.analyze();

        // 根據分析結果決定測試結果
        print('📊 Analysis Results:');
        print(
            '   Health Score: ${(analysis.healthScore * 100).toStringAsFixed(1)}%');
        print('   Critical Insights: ${analysis.criticalInsights.length}');
        print('   Total Insights: ${analysis.insights.length}');

        // 決策邏輯
        if (analysis.criticalInsights.isNotEmpty) {
          print('\n❌ Test should fail:');
          for (final insight in analysis.criticalInsights) {
            print('   • ${insight.title}');
          }

          // 只在有 critical insights 時讓測試Failed
          fail(
              'Found ${analysis.criticalInsights.length} critical accessibility issues');
        } else if (analysis.healthScore < 0.8) {
          print('\n⚠️  Warning: Health score below 80%');
          print('   Test passes but consider fixing issues');
          // ✅ 測試Passed，但發出Warning
        } else {
          print('\n✅ All accessibility checks passed!');
          // ✅ 測試Passed
        }
      });
    });

    // 生成最終報告
    tearDownAll(() {
      final report = reporter.generate(
        version: 'v2.0.0',
        gitCommitHash: 'test',
        environment: 'demo',
      );

      print('\n' + '═' * 60);
      print('📊 最終報告統計：');
      print('═' * 60);
      print('Total Validations: ${report.score.total}');
      print('Passed: ${report.score.passed}');
      print('Failed: ${report.score.failed}');
      print('Compliance Rate: ${report.score.percentage.toStringAsFixed(1)}%');
      print('═' * 60);

      // AI analysis
      final analysis = report.analyze();
      print('\n🧠 AI analysis：');
      print(
          'Health Score: ${(analysis.healthScore * 100).toStringAsFixed(1)}%');
      print('Critical Issues: ${analysis.criticalInsights.length}');
      print('總洞察: ${analysis.insights.length}');
      print('工作量: ${analysis.estimatedEffort?.toStringAsFixed(1) ?? 'N/A'} 小時');
      print('═' * 60);
    });
  });
}

/// 輔助：比較三種模式的差異
void compareTestModes() {
  print('''
╔═══════════════════════════════════════════════════════════════════╗
║                    無障礙測試模式對比                                ║
╚═══════════════════════════════════════════════════════════════════╝

┌─────────────────┬────────────┬──────────┬────────────────────┐
│ 特性            │ 嚴謹模式    │ 寬鬆模式  │ 混合模式            │
├─────────────────┼────────────┼──────────┼────────────────────┤
│ 使用 expect()   │ ✅ 是      │ ❌ 否    │ ⚡ 條件式          │
│ 測試會Failed      │ ✅ 是      │ ❌ 否    │ ⚡ 有時候          │
│ 記錄到報告      │ ✅ 是      │ ✅ 是    │ ✅ 是              │
│ 適用場景        │ CI/CD     │ 初期評估  │ 生產環境            │
│ 優點            │ 強制標準    │ 完整報告  │ 靈活彈性            │
│ 缺點            │ 可能中斷    │ 不強制    │ 需要設計決策邏輯    │
└─────────────────┴────────────┴──────────┴────────────────────┘

當前 widget_accessibility_test.dart 使用：✅ 嚴謹模式

Suggestion：
• CI/CD 環境：使用嚴謹模式或混合模式
• 本地開發：使用寬鬆模式或混合模式
• 初期評估：使用寬鬆模式生成完整報告
• 持續改善：使用AI analysis驅動模式
  ''');
}
