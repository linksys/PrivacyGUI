/// WCAG Intelligence Analysis Engine Demo
///
/// This demo showcases the Phase 3 Intelligence Analysis Engine capabilities:
/// 1. Pattern Detection - Identifies systemic issues, bad smells, regressions
/// 2. Priority Calculation - Ranks insights by severity and impact
/// 3. Fix Suggestions - Generates actionable recommendations with code examples
/// 4. Health Score - Calculates overall accessibility health
/// 5. Multi-Report Analysis - Combines insights across multiple Success Criteria
///
/// Run this demo with:
/// ```bash
/// flutter test lib/demo/wcag_analysis_demo.dart
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';

void main() {
  group('WCAG Intelligence Analysis Engine Demo', () {
    test('Demo 1: Basic Analysis - Single Report', () {
      print('\n' + '=' * 80);
      print('DEMO 1: Basic Analysis - Single Report');
      print('=' * 80);

      // Step 1: Create reporter and collect validation results
      final reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);

      // Simulate validation results from UI components
      reporter.validateComponent(
        componentName: 'LoginButton',
        actualSize: const Size(32, 32), // Too small for AAA
        affectedComponents: ['LoginButton'],
        severity: Severity.critical, // Critical because it's a primary action
      );

      reporter.validateComponent(
        componentName: 'CancelButton',
        actualSize: const Size(38, 38), // Still too small
        affectedComponents: ['CancelButton'],
        severity: Severity.high,
      );

      reporter.validateComponent(
        componentName: 'HelpButton',
        actualSize: const Size(48, 48), // Compliant
        affectedComponents: ['HelpButton'],
      );

      // Step 2: Generate WCAG report
      final report = reporter.generate(
        version: 'v2.0.0',
        gitCommitHash: 'abc123',
        environment: 'Demo',
      );

      print('\n📊 Report Generated:');
      print('   Total Components: ${report.score.total}');
      print('   Failed: ${report.score.failed}');
      print('   Passed: ${report.score.passed}');
      print('   Compliance: ${report.score.percentage.toStringAsFixed(1)}%');

      // Step 3: Analyze with Intelligence Engine
      final engine = WcagAnalysisEngine();
      final result = engine.analyze(report);

      print('\n🔍 Analysis Results:');
      print(
          '   Health Score: ${(result.healthScore * 100).toStringAsFixed(1)}%');
      print('   Total Insights: ${result.insights.length}');
      print('   Critical Insights: ${result.criticalInsights.length}');
      print(
          '   Estimated Effort: ${result.estimatedEffort?.toStringAsFixed(1)} hours');
      print(
          '   Expected Improvement: +${(result.expectedImprovement! * 100).toStringAsFixed(1)}%');

      // Step 4: Display insights with recommendations
      print('\n💡 Insights & Recommendations:');
      for (var i = 0; i < result.insights.length; i++) {
        final insight = result.insights[i];
        print('\n   ${i + 1}. ${insight.severity.emoji} ${insight.title}');
        print('      Severity: ${insight.severity.name.toUpperCase()}');
        print(
            '      Confidence: ${(insight.confidence * 100).toStringAsFixed(0)}%');
        print('      Affected: ${insight.affectedComponents.join(", ")}');
        print('      Description: ${insight.description}');

        if (insight.actions.isNotEmpty) {
          print('\n      📋 Action Steps:');
          for (final action in insight.actions) {
            print('         ${action.step}. ${action.description}');
            if (action.codeExample != null) {
              print('            Code Example:');
              final lines = action.codeExample!.split('\n');
              for (final line in lines.take(3)) {
                print('            $line');
              }
              if (lines.length > 3) print('            ...');
            }
          }
        }
      }

      // Step 5: Generate summary
      print('\n' + '-' * 80);
      print('SUMMARY');
      print('-' * 80);
      print(engine.generateSummary(result));

      expect(result.insights.isNotEmpty, isTrue,
          reason: 'Should detect accessibility issues');
      expect(result.healthScore, lessThan(1.0),
          reason: 'Health score should reflect failures');
    });

    test('Demo 2: Regression Detection', () {
      print('\n' + '=' * 80);
      print('DEMO 2: Regression Detection');
      print('=' * 80);

      final engine = WcagAnalysisEngine();

      // Version 1.0: Everything passes
      print('\n📦 Version 1.0 (Baseline)');
      final reporter1 = TargetSizeReporter(targetLevel: WcagLevel.aaa);
      reporter1.validateComponent(
        componentName: 'LoginButton',
        actualSize: const Size(48, 48), // Compliant
        affectedComponents: ['LoginButton'],
      );
      final report1 = reporter1.generate(
        version: 'v1.0.0',
        gitCommitHash: 'baseline123',
        environment: 'Demo',
      );
      final result1 = engine.analyze(report1);
      print(
          '   Health Score: ${(result1.healthScore * 100).toStringAsFixed(1)}%');
      print('   Failures: ${report1.score.failed}');

      // Version 2.0: Regression introduced
      print('\n📦 Version 2.0 (Regression!)');
      final reporter2 = TargetSizeReporter(targetLevel: WcagLevel.aaa);
      reporter2.validateComponent(
        componentName: 'LoginButton',
        actualSize: const Size(36, 36), // Now fails!
        affectedComponents: ['LoginButton'],
        severity: Severity.critical,
      );
      final report2 = reporter2.generate(
        version: 'v2.0.0',
        gitCommitHash: 'newcode456',
        environment: 'Demo',
      );

      // Analyze with previous report to detect regressions
      final result2 = engine.analyze(report2, previousReport: report1);

      print(
          '   Health Score: ${(result2.healthScore * 100).toStringAsFixed(1)}% ⚠️');
      print('   Failures: ${report2.score.failed}');
      print('   Regressions Detected: ${result2.regressions.length}');

      if (result2.regressions.isNotEmpty) {
        print('\n🚨 REGRESSION ALERT!');
        for (final regression in result2.regressions) {
          print('   ${regression.severity.emoji} ${regression.title}');
          print('   Components: ${regression.affectedComponents.join(", ")}');
          print('   Previously: Passing → Now: Failing');
        }
      }

      expect(result2.regressions.isNotEmpty, isTrue,
          reason: 'Should detect regression');
    });

    test('Demo 3: Systemic Issues Detection', () {
      print('\n' + '=' * 80);
      print('DEMO 3: Systemic Issues Detection');
      print('=' * 80);

      // Simulate multiple instances of the same component failing
      final reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);

      print('\n📋 Validating AppButton across multiple themes...');
      final themes = ['Light', 'Dark', 'HighContrast', 'Pixel', 'Custom'];
      for (final theme in themes) {
        reporter.validateComponent(
          componentName: 'AppButton',
          actualSize: const Size(32, 32), // Consistently too small
          affectedComponents: ['AppButton'],
          severity: Severity.critical,
        );
        print('   ❌ AppButton in $theme theme: 32x32 dp (fails AAA)');
      }

      final report = reporter.generate(
        version: 'v2.0.0',
        gitCommitHash: 'abc123',
        environment: 'Demo',
      );

      final engine = WcagAnalysisEngine();
      final result = engine.analyze(report);

      print('\n🔍 Analysis Results:');
      print('   Total Failures: ${report.score.failed}');
      print('   Systemic Issues: ${result.systemicIssues.length}');

      if (result.systemicIssues.isNotEmpty) {
        print('\n⚠️ SYSTEMIC ISSUE DETECTED!');
        final systemic = result.systemicIssues.first;
        print('   Title: ${systemic.title}');
        print('   Severity: ${systemic.severity.name.toUpperCase()}');
        print('   Failure Count: ${systemic.failureCount}');
        print(
            '   Confidence: ${(systemic.confidence * 100).toStringAsFixed(0)}%');
        print('\n   💡 Root Cause:');
        print(
            '   The AppButton component has a fundamental design issue affecting');
        print(
            '   ALL themes. Fix the base component instead of patching each theme.');
      }

      expect(result.systemicIssues.isNotEmpty, isTrue,
          reason: 'Should detect systemic issue with 5+ failures');
    });

    test('Demo 4: Multi-Report Analysis', () {
      print('\n' + '=' * 80);
      print('DEMO 4: Multi-Report Analysis (Multiple Success Criteria)');
      print('=' * 80);

      final engine = WcagAnalysisEngine();

      // Report 1: Target Size (SC 2.5.5)
      print('\n📊 Report 1: Target Size (SC 2.5.5 - AAA)');
      final tsReporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);
      tsReporter.validateComponent(
        componentName: 'SubmitButton',
        actualSize: const Size(36, 36),
        affectedComponents: ['SubmitButton'],
        severity: Severity.high,
      );
      final tsReport = tsReporter.generate(
        version: 'v2.0.0',
        gitCommitHash: 'abc123',
        environment: 'Demo',
      );
      print('   Compliance: ${tsReport.score.percentage.toStringAsFixed(1)}%');

      // Report 2: Semantics (SC 4.1.2)
      print('\n📊 Report 2: Semantics (SC 4.1.2 - A)');
      final semReporter = SemanticsReporter(targetLevel: WcagLevel.a);
      semReporter.validateComponent(
        componentName: 'IconButton',
        hasLabel: false, // Missing semantic label
        hasRole: true,
        exposesValue: true,
        affectedComponents: ['IconButton'],
        severity: Severity.critical,
      );
      final semReport = semReporter.generate(
        version: 'v2.0.0',
        gitCommitHash: 'abc123',
        environment: 'Demo',
      );
      print('   Compliance: ${semReport.score.percentage.toStringAsFixed(1)}%');

      // Analyze multiple reports together
      print('\n🔄 Analyzing Multiple Reports...');
      final result = engine.analyzeMultiple([tsReport, semReport]);

      print('\n📈 Combined Analysis:');
      print('   Reports Analyzed: ${result.metadata['reportCount']}');
      print('   Success Criteria: ${result.metadata['successCriteria']}');
      print(
          '   Overall Health: ${(result.healthScore * 100).toStringAsFixed(1)}%');
      print('   Total Insights: ${result.insights.length}');
      print('   Critical: ${result.criticalInsights.length}');
      print('   High: ${result.highInsights.length}');
      print(
          '   Total Estimated Effort: ${result.estimatedEffort?.toStringAsFixed(1)} hours');

      print('\n💡 Prioritized Insights:');
      for (var i = 0; i < result.insights.length; i++) {
        final insight = result.insights[i];
        print('   ${i + 1}. ${insight.severity.emoji} ${insight.title}');
        print('      SC: ${insight.successCriteria.join(", ")}');
        print('      Components: ${insight.affectedComponents.join(", ")}');
      }

      expect(result.insights.length, greaterThanOrEqualTo(2),
          reason: 'Should combine insights from both reports');
    });

    test('Demo 5: Priority-Based Fix Workflow', () {
      print('\n' + '=' * 80);
      print('DEMO 5: Priority-Based Fix Workflow');
      print('=' * 80);

      final reporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);

      // Add various components with different severities
      reporter.validateComponent(
        componentName: 'PrimaryButton',
        actualSize: const Size(20, 20), // Very small
        affectedComponents: ['PrimaryButton'],
        severity: Severity.critical,
      );

      reporter.validateComponent(
        componentName: 'SecondaryButton',
        actualSize: const Size(38, 38), // Slightly small
        affectedComponents: ['SecondaryButton'],
        severity: Severity.medium,
      );

      reporter.validateComponent(
        componentName: 'TertiaryButton',
        actualSize: const Size(42, 42), // Close to compliant
        affectedComponents: ['TertiaryButton'],
        severity: Severity.low,
      );

      final report = reporter.generate(
        version: 'v2.0.0',
        gitCommitHash: 'abc123',
        environment: 'Demo',
      );

      final engine = WcagAnalysisEngine();
      final result = engine.analyze(report);

      print('\n📋 Recommended Fix Order (by priority):');
      print(
          '   Health Score: ${(result.healthScore * 100).toStringAsFixed(1)}%');
      print(
          '   Expected Improvement: +${(result.expectedImprovement! * 100).toStringAsFixed(1)}%');
      print(
          '   Total Effort: ${result.estimatedEffort?.toStringAsFixed(1)} hours\n');

      for (var i = 0; i < result.insights.length; i++) {
        final insight = result.insights[i];
        print(
            '   Priority ${i + 1}: ${insight.severity.emoji} ${insight.affectedComponents.first}');
        print('   Severity: ${insight.severity.name.toUpperCase()}');
        print(
            '   Estimated Time: ${result.estimatedEffort! / result.insights.length ~/ 1} hours');

        if (insight.actions.isNotEmpty) {
          final firstAction = insight.actions.first;
          print('   Quick Fix: ${firstAction.description}');
        }
        print('');
      }

      print('   💡 Tip: Fix critical issues first for maximum impact!');

      expect(result.insights.first.severity, equals(InsightSeverity.critical),
          reason: 'Critical issues should be prioritized first');
    });
  });
}
