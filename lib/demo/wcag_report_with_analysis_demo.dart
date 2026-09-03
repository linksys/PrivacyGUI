/// WCAG Report with Integrated Intelligence Analysis Demo
///
/// Demonstrates how to use the built-in AI analysis feature of the report
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Deep `src/` import for the same measured reason as `wcag_analysis_demo.dart`:
// the WCAG analysis API is not exported from either public entry point at
// ui_kit v3.1.0. See that file's note before "fixing" this one.
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';

void main() {
  group('WCAG Report with Integrated Analysis', () {
    test('Demo: Use report.analyze() to directly analyze the report', () {
      print('\n' + '=' * 80);
      print('DEMO: Built-in AI analysis feature of the report');
      print('=' * 80);

      // Step 1: Create and Generate report (Standard Process)
      print('\n📊 Step 1: Generate standard WCAG report');
      final reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);

      reporter.validateComponent(
        componentName: 'LoginButton',
        actualSize: const Size(32, 32),
        severity: Severity.critical,
      );

      reporter.validateComponent(
        componentName: 'CancelButton',
        actualSize: const Size(38, 38),
        severity: Severity.high,
      );

      reporter.validateComponent(
        componentName: 'HelpIcon',
        actualSize: const Size(48, 48), // Passed
      );

      final report = reporter.generate(
        version: 'v2.0.0',
        gitCommitHash: 'abc123',
        environment: 'Demo',
      );

      print('   ✓ Report generated');
      print('   Total: ${report.score.total}');
      print('   Failed: ${report.score.failed}');
      print('   Compliance: ${report.score.percentage.toStringAsFixed(1)}%');

      // Step 2: Use the built-in analyze() method (New Feature!)
      print('\n🔍 Step 2: Use report.analyze() for automated analysis');
      final analysis = report.analyze();

      print('   ✓ Analysis Completed!');
      print(
          '   Health Score: ${(analysis.healthScore * 100).toStringAsFixed(1)}%');
      print('   Insights: ${analysis.insights.length}');
      print('   Critical: ${analysis.criticalInsights.length}');

      // Step 3: View Insights and Suggestions
      print('\n💡 Step 3: Automatically generated Insights and Suggestions');
      for (var i = 0; i < analysis.insights.length; i++) {
        final insight = analysis.insights[i];
        print(
            '\n   Insight ${i + 1}: ${insight.severity.emoji} ${insight.title}');
        print('   Severity: ${insight.severity.name.toUpperCase()}');
        print('   Affected: ${insight.affectedComponents.join(", ")}');

        if (insight.actions.isNotEmpty) {
          print('   Actions:');
          for (final action in insight.actions.take(2)) {
            print('     ${action.step}. ${action.description}');
          }
        }
      }

      // Verification Results
      expect(analysis.insights.isNotEmpty, isTrue);
      expect(analysis.healthScore, lessThan(1.0));

      print('\n✅ Completed:Report + AI analysis integrated!');
    });

    test('Demo: Use report.analyzeAndSummarize() to get a quick summary', () {
      print('\n' + '=' * 80);
      print('DEMO: Quick Summary Feature');
      print('=' * 80);

      // Create Report
      final reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);

      for (var i = 0; i < 3; i++) {
        reporter.validateComponent(
          componentName: 'Button$i',
          actualSize: const Size(32, 32),
          severity: Severity.critical,
        );
      }

      final report = reporter.generate(
        version: 'v2.0.0',
        gitCommitHash: 'abc123',
        environment: 'Demo',
      );

      // Get complete summary in one line!
      print('\n📝 Use report.analyzeAndSummarize() to get a quick summary:\n');
      final summary = report.analyzeAndSummarize();
      print(summary);

      expect(summary, contains('WCAG Analysis Summary'));
      expect(summary, contains('Health Score'));

      print(
          '\n✅ Completed:Get complete analysis summary with one line of code!');
    });

    test('Demo: Regression Detection - Pass in previousReport', () {
      print('\n' + '=' * 80);
      print('DEMO: Regression Detection (Using previousReport parameter)');
      print('=' * 80);

      // Version 1: All Passed
      print('\n📦 Version 1.0 - Baseline');
      final reporter1 = TargetSizeReporter(targetLevel: WcagLevel.aaa);
      reporter1.validateComponent(
        componentName: 'MainButton',
        actualSize: const Size(48, 48), // Passed
      );
      final report1 = reporter1.generate(
        version: 'v1.0.0',
        gitCommitHash: 'baseline',
        environment: 'Demo',
      );
      print('   Compliance: ${report1.score.percentage.toStringAsFixed(1)}%');

      // Version 2: Introduce Regression
      print('\n📦 Version 2.0 - With Regression');
      final reporter2 = TargetSizeReporter(targetLevel: WcagLevel.aaa);
      reporter2.validateComponent(
        componentName: 'MainButton',
        actualSize: const Size(36, 36), // Now Failed!
        severity: Severity.critical,
      );
      final report2 = reporter2.generate(
        version: 'v2.0.0',
        gitCommitHash: 'newcode',
        environment: 'Demo',
      );
      print('   Compliance: ${report2.score.percentage.toStringAsFixed(1)}%');

      // Detect regression using previousReport parameter
      print('\n🔍 Analyze and detect regression:');
      final analysis = report2.analyze(previousReport: report1);

      print('   Regressions Detected: ${analysis.regressions.length}');

      if (analysis.regressions.isNotEmpty) {
        print('\n🚨 REGRESSION ALERT!');
        for (final regression in analysis.regressions) {
          print('   ${regression.severity.emoji} ${regression.title}');
          print('   Components: ${regression.affectedComponents.join(", ")}');
        }
      }

      expect(analysis.regressions.isNotEmpty, isTrue);

      print('\n✅ Completed:Automatically detected regression!');
    });

    test('Demo: Comparison - Old Method vs New Integrated Method', () {
      print('\n' + '=' * 80);
      print('DEMO: Old Method vs New Integrated Method Comparison');
      print('=' * 80);

      final reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);
      reporter.validateComponent(
        componentName: 'TestButton',
        actualSize: const Size(32, 32),
        severity: Severity.high,
      );

      final report = reporter.generate(
        version: 'v2.0.0',
        gitCommitHash: 'abc123',
        environment: 'Demo',
      );

      print('\n❌ Old Method (Requires 3 steps):');
      print('   1. Generate report');
      print('   2. Create Analysis Engine');
      print('   3. Manually call engine.analyze()');
      print('\n   Code:');
      print('   ```dart');
      print('   final report = reporter.generate(...);');
      print('   final engine = WcagAnalysisEngine();');
      print('   final analysis = engine.analyze(report);');
      print('   ```');

      print('\n✅ New Method (Requires only 1 step):');
      print('   1. Directly call report.analyze()');
      print('\n   Code:');
      print('   ```dart');
      print('   final report = reporter.generate(...);');
      print('   final analysis = report.analyze();  // It\'s that simple!');
      print('   ```');

      // Both methods yield the same result
      final engine = WcagAnalysisEngine();
      final oldWayResult = engine.analyze(report);
      final newWayResult = report.analyze();

      print('\n📊 Result Comparison:');
      print(
          '   Old Method Health Score: ${(oldWayResult.healthScore * 100).toStringAsFixed(1)}%');
      print(
          '   New Method Health Score: ${(newWayResult.healthScore * 100).toStringAsFixed(1)}%');
      print('   Old Method Insights: ${oldWayResult.insights.length}');
      print('   New Method Insights: ${newWayResult.insights.length}');

      expect(oldWayResult.healthScore, equals(newWayResult.healthScore));
      expect(
          oldWayResult.insights.length, equals(newWayResult.insights.length));

      print(
          '\n✅ Completed:Both methods yield the same result, but the new method is more concise!');
    });

    test('Demo: Real-world Application - CI/CD Integration Example', () {
      print('\n' + '=' * 80);
      print('DEMO: Real-world Application - CI/CD Integration Example');
      print('=' * 80);

      print(
          '\n💼 Use Case: Automatically check accessibility in CI pipeline\n');

      // Simulate CI Environment
      final reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);

      // Validate all buttons
      reporter.validateComponent(
        componentName: 'SubmitButton',
        actualSize: const Size(24, 24), // Critical Failures
        severity: Severity.critical,
      );

      reporter.validateComponent(
        componentName: 'NormalButton',
        actualSize: const Size(48, 48), // Passed
      );

      // Generate report and analyze
      final report = reporter.generate(
        version: 'v2.0.0',
        gitCommitHash: 'abc123',
        environment: 'CI',
      );

      final analysis = report.analyze();

      print('📋 CI Check Results:');
      print('   Compliance: ${report.score.percentage.toStringAsFixed(1)}%');
      print(
          '   Health Score: ${(analysis.healthScore * 100).toStringAsFixed(1)}%');
      print('   Critical Issues: ${analysis.criticalInsights.length}');

      // CI Decision Logic
      final shouldFail =
          analysis.criticalInsights.isNotEmpty || analysis.healthScore < 0.8;

      if (shouldFail) {
        print('\n❌ CI CHECK FAILED!');
        print(
            '   Reason: ${analysis.criticalInsights.length} critical accessibility issues found');
        print('\n   Issues:');
        for (final insight in analysis.criticalInsights) {
          print('   • ${insight.title}');
          print('     Affected: ${insight.affectedComponents.join(", ")}');
        }
      } else {
        print('\n✅ CI CHECK PASSED!');
        print('   No critical accessibility issues found');
      }

      print('\n💡 Suggestion:Add this logic to your CI pipeline!');

      expect(shouldFail, isTrue); // This example should fail
    });
  });
}
