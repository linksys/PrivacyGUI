/// PrivacyGUI Widget Accessibility Tests
///
/// 這個測試文件驗證 PrivacyGUI 使用的 UI Kit 元件是否符合 WCAG 2.1 標準
///
/// How to run:
/// ```bash
/// flutter test test/accessibility/widget_accessibility_test.dart
/// ```
///
/// Generate report：
/// - reports/accessibility/widget_validation/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  group('PrivacyGUI UI Kit Widget Accessibility Validation', () {
    late TargetSizeReporter targetSizeReporter;
    late SemanticsReporter semanticsReporter;
    late ThemeData testTheme;

    setUp(() {
      targetSizeReporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);
      semanticsReporter = SemanticsReporter(targetLevel: WcagLevel.a);

      // Create theme using PrivacyGUI's ThemeJsonConfig
      final themeConfig = ThemeJsonConfig.defaultConfig();
      testTheme = themeConfig.createLightTheme();
    });

    /// Helper function to wrap widgets with theme
    Widget wrapWithTheme(Widget child) {
      return MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    group('AppButton - Target Size & Semantics', () {
      testWidgets('primary button should meet AAA target size (44x44 dp)',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          wrapWithTheme(
            AppButton.primary(
              label: 'Save',
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act
        final buttonFinder = find.byType(AppButton);
        final buttonSize = tester.getSize(buttonFinder);

        // Assert
        targetSizeReporter.validateComponent(
          componentName: 'AppButton.primary',
          actualSize: buttonSize,
          affectedComponents: ['AppButton'],
          widgetPath:
              'ui_kit_library/lib/src/molecules/buttons/app_button.dart',
          severity: Severity.critical,
        );

        expect(
          buttonSize.width >= 44 && buttonSize.height >= 44,
          isTrue,
          reason:
              'Button size ${buttonSize.width}x${buttonSize.height} should be at least 44x44 dp',
        );
      });

      testWidgets('primaryOutline button should meet AAA target size',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          wrapWithTheme(
            AppButton.primaryOutline(
              label: 'Cancel',
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act
        final buttonFinder = find.byType(AppButton);
        final buttonSize = tester.getSize(buttonFinder);

        // Assert
        targetSizeReporter.validateComponent(
          componentName: 'AppButton.primaryOutline',
          actualSize: buttonSize,
          affectedComponents: ['AppButton'],
          widgetPath:
              'ui_kit_library/lib/src/molecules/buttons/app_button.dart',
        );
      });

      testWidgets('text button should meet AAA target size', (tester) async {
        // Arrange
        await tester.pumpWidget(
          wrapWithTheme(
            AppButton.text(
              label: 'Skip',
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act
        final buttonFinder = find.byType(AppButton);
        final buttonSize = tester.getSize(buttonFinder);

        // Assert
        targetSizeReporter.validateComponent(
          componentName: 'AppButton.text',
          actualSize: buttonSize,
          affectedComponents: ['AppButton'],
          widgetPath:
              'ui_kit_library/lib/src/molecules/buttons/app_button.dart',
        );
      });

      testWidgets('button with semantics label should be properly labeled',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          wrapWithTheme(
            AppButton.primary(
              label: 'Submit',
              semanticLabel: 'Submit registration form',
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Validate semantics
        semanticsReporter.validateComponent(
          componentName: 'AppButton.with_semantics',
          hasLabel: true,
          hasRole: true,
          exposesValue: true,
          expectedLabel: 'Submit registration form',
          actualLabel: 'Submit registration form',
          role: 'button',
          affectedComponents: ['AppButton'],
          widgetPath:
              'ui_kit_library/lib/src/molecules/buttons/app_button.dart',
        );
      });
    });

    group('AppIconButton - Target Size', () {
      testWidgets('icon button should meet AAA target size', (tester) async {
        // Arrange
        await tester.pumpWidget(
          wrapWithTheme(
            AppIconButton(
              icon: const Icon(Icons.settings),
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act
        final buttonFinder = find.byType(AppIconButton);
        final buttonSize = tester.getSize(buttonFinder);

        // Assert
        targetSizeReporter.validateComponent(
          componentName: 'AppIconButton',
          actualSize: buttonSize,
          affectedComponents: ['AppIconButton'],
          widgetPath:
              'ui_kit_library/lib/src/molecules/buttons/app_icon_button.dart',
          severity: Severity.high,
        );

        expect(
          buttonSize.width >= 44 && buttonSize.height >= 44,
          isTrue,
          reason:
              'Icon button size ${buttonSize.width}x${buttonSize.height} should be at least 44x44 dp',
        );
      });

      testWidgets('icon button should have proper semantics', (tester) async {
        // Arrange
        await tester.pumpWidget(
          wrapWithTheme(
            AppIconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        semanticsReporter.validateComponent(
          componentName: 'AppIconButton.with_semantics',
          hasLabel: true,
          hasRole: true,
          exposesValue: true,
          expectedLabel: 'Settings',
          actualLabel: 'Settings',
          role: 'button',
          affectedComponents: ['AppIconButton'],
          widgetPath:
              'ui_kit_library/lib/src/molecules/buttons/app_icon_button.dart',
        );
      });
    });

    group('AppSwitch - Target Size', () {
      testWidgets('switch toggle should meet AAA target size', (tester) async {
        // Arrange
        await tester.pumpWidget(
          wrapWithTheme(
            AppSwitch(
              value: false,
              onChanged: (value) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act
        final switchFinder = find.byType(AppSwitch);
        final switchSize = tester.getSize(switchFinder);

        // Assert
        targetSizeReporter.validateComponent(
          componentName: 'AppSwitch',
          actualSize: switchSize,
          affectedComponents: ['AppSwitch'],
          widgetPath:
              'ui_kit_library/lib/src/molecules/toggles/app_switch.dart',
          severity: Severity.critical,
        );

        expect(
          switchSize.width >= 44 && switchSize.height >= 44,
          isTrue,
          reason:
              'Switch size ${switchSize.width}x${switchSize.height} should be at least 44x44 dp',
        );
      });
    });

    group('AppCheckbox - Target Size', () {
      testWidgets('checkbox should meet AAA target size', (tester) async {
        // Arrange
        await tester.pumpWidget(
          wrapWithTheme(
            AppCheckbox(
              value: false,
              onChanged: (value) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act
        final checkboxFinder = find.byType(AppCheckbox);
        final checkboxSize = tester.getSize(checkboxFinder);

        // Assert
        targetSizeReporter.validateComponent(
          componentName: 'AppCheckbox',
          actualSize: checkboxSize,
          affectedComponents: ['AppCheckbox'],
          widgetPath:
              'ui_kit_library/lib/src/molecules/selection/app_checkbox.dart',
          severity: Severity.high,
        );

        expect(
          checkboxSize.width >= 44 && checkboxSize.height >= 44,
          isTrue,
          reason:
              'Checkbox size ${checkboxSize.width}x${checkboxSize.height} should be at least 44x44 dp',
        );
      });
    });

    group('AppCard - Target Size', () {
      testWidgets('tappable card should meet minimum height', (tester) async {
        // Arrange
        await tester.pumpWidget(
          wrapWithTheme(
            AppCard(
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: AppText('Network Settings'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act
        final cardFinder = find.byType(AppCard);
        final cardSize = tester.getSize(cardFinder);

        // Assert
        targetSizeReporter.validateComponent(
          componentName: 'AppCard.tappable',
          actualSize: cardSize,
          affectedComponents: ['AppCard'],
          widgetPath: 'ui_kit_library/lib/src/molecules/cards/app_card.dart',
        );

        expect(
          cardSize.height >= 44,
          isTrue,
          reason:
              'Tappable card height ${cardSize.height} should be at least 44 dp',
        );
      });
    });

    // Generate consolidated report after all tests
    tearDownAll(() {
      // Create output directory
      final outputDir = Directory('reports/accessibility/widget_validation');
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }

      // Generate Target Size report
      final targetSizeReport = targetSizeReporter.generate(
        version: 'v2.0.0',
        gitCommitHash: _getGitHash(),
        environment: 'widget_test',
      );

      File('${outputDir.path}/target_size.html')
          .writeAsStringSync(targetSizeReport.toHtml());
      File('${outputDir.path}/target_size.md')
          .writeAsStringSync(targetSizeReport.toMarkdown());

      // Generate Semantics report
      final semanticsReport = semanticsReporter.generate(
        version: 'v2.0.0',
        gitCommitHash: _getGitHash(),
        environment: 'widget_test',
      );

      File('${outputDir.path}/semantics.html')
          .writeAsStringSync(semanticsReport.toHtml());
      File('${outputDir.path}/semantics.md')
          .writeAsStringSync(semanticsReport.toMarkdown());

      // Generate batch report
      final batchRunner = WcagBatchRunner()
        ..addTargetSizeReporter(targetSizeReporter)
        ..addSemanticsReporter(semanticsReporter);

      final batch = batchRunner.generateBatch(
        version: 'v2.0.0',
        gitCommitHash: _getGitHash(),
        environment: 'widget_test',
      );

      final batchDir = Directory('${outputDir.path}/batch');
      batch.exportAll(outputDirectory: batchDir);

      // Print summary
      print('\n╔════════════════════════════════════════════════════════╗');
      print('║  PrivacyGUI UI Kit Accessibility Validation Complete   ║');
      print('╚════════════════════════════════════════════════════════╝');
      print(
          '\n📊 Overall Compliance: ${batch.overallCompliance.toStringAsFixed(1)}% ${batch.statusEmoji}');
      print('   Total Validations: ${batch.totalValidations}');
      print('   ✅ Passed: ${batch.totalPassed}');
      print('   ❌ Failed: ${batch.totalFailures}');
      print('   🔴 Critical: ${batch.totalCriticalFailures}');
      print('\n📁 Reports saved to: ${outputDir.path}/');
      print('   ⭐ Full Report: ${batchDir.path}/full.html');
    });
  });
}

/// Get Git commit hash
String _getGitHash() {
  try {
    final result = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
    return result.stdout.toString().trim();
  } catch (e) {
    return 'unknown';
  }
}
