# PrivacyGUI Accessibility Testing Guide

This guide describes how to create and execute WCAG 2.1 accessibility tests in the PrivacyGUI project.

## 📋 Table of Contents

- [Overview](#overview)
- [Environment Setup](#environment-setup)
- [Execution Example](#execution-example)
- [Creating Actual Component Tests](#creating-actual-component-tests)
- [CI/CD Integration](#cicd-integration)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

The PrivacyGUI project integrates the WCAG 2.1 accessibility verification system from `ui_kit_library`. This system supports:

- ✅ **SC 2.5.5**: Target Size (Enhanced) - Touch target size verification
- ✅ **SC 2.4.3**: Focus Order - Focus order verification
- ✅ **SC 4.1.2**: Name, Role, Value - Semantic property verification

---

## Environment Setup

### 1. Dependencies

`ui_kit_library` is already included in `pubspec.yaml`:

```yaml
dependencies:
  ui_kit_library:
    git:
      url: https://github.com/your-org/ui_kit_library.git
      ref: main
```

### 2. Test Dependencies

Ensure you have the dependencies required for testing:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
```

---

## Execution Example

### View Full Example

A complete demonstration example is provided:

```bash
# Execute demonstration example
flutter test test/accessibility/example_validation.dart
```

This example demonstrates:
- Single Success Criterion verification
- Batch verification (multiple SCs)
- Report version comparison
- Performance improvement using cache

### View Generated Reports

After execution, reports are saved in:
```
reports/accessibility/example/
├── target_size.html          # Target Size HTML report
├── target_size.md            # Target Size Markdown report
├── comparison.html           # Version comparison report
└── batch/
    ├── full.html             # ⭐ Full integrated report
    ├── overview.html         # Batch overview
    └── sc_*.html             # Detailed reports for each SC
```

Open `reports/accessibility/example/batch/full.html` in a browser to view the complete visualized report.

---

## Creating Actual Component Tests

### Basic Test Structure

Create a new test file `test/accessibility/my_widget_test.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';

void main() {
  group('My Widget Accessibility Tests', () {
    late TargetSizeReporter targetSizeReporter;

    setUp(() {
      targetSizeReporter = TargetSizeReporter(targetLevel: WcagLevel.aaa);
    });

    testWidgets('button should meet AAA target size', (tester) async {
      // 1. Arrange - Set up test environment
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YourButton(
              onTap: () {},
              text: 'Test Button',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Act - Measure component size
      final buttonFinder = find.byType(YourButton);
      final buttonSize = tester.getSize(buttonFinder);

      // 3. Assert - Verify WCAG compliance
      targetSizeReporter.validateComponent(
        componentName: 'YourButton',
        actualSize: buttonSize,
        affectedComponents: ['YourButton'],
        widgetPath: 'lib/widgets/your_button.dart',
        severity: Severity.critical,
      );

      expect(
        buttonSize.width >= 44 && buttonSize.height >= 44,
        isTrue,
        reason: 'Button should be at least 44x44 dp',
      );
    });

    // Generate report
    tearDownAll(() {
      final outputDir = Directory('reports/accessibility/my_widgets');
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }

      final report = targetSizeReporter.generate(
        version: 'v2.0.0',
        gitCommitHash: 'test',
        environment: 'test',
      );

      File('${outputDir.path}/report.html')
          .writeAsStringSync(report.toHtml());
    });
  });
}
```

### Target Size Test Example

Test interactive components such as buttons, cards, and switches:

```dart
testWidgets('AppSwitchTriggerTile switch meets target size', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppSwitchTriggerTile(
          value: false,
          title: const Text('Feature Toggle'),
          onChanged: (value) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Measure Switch component
  final switchFinder = find.byType(Switch);
  final switchSize = tester.getSize(switchFinder);

  targetSizeReporter.validateComponent(
    componentName: 'AppSwitchTriggerTile.switch',
    actualSize: switchSize,
    affectedComponents: ['AppSwitchTriggerTile'],
    widgetPath: 'lib/page/components/composed/app_switch_trigger_tile.dart',
    severity: Severity.critical,
  );

  expect(switchSize.width >= 44 && switchSize.height >= 44, isTrue);
});
```

### Semantics Test Example

Verify screen reader accessibility:

```dart
testWidgets('button has proper semantics', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Semantics(
          label: 'Save your changes',
          button: true,
          child: YourButton(
            onTap: () {},
            text: 'Save',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final semanticsReporter = SemanticsReporter(targetLevel: WcagLevel.a);

  semanticsReporter.validateComponent(
    componentName: 'YourButton',
    hasLabel: true,
    hasRole: true,
    exposesValue: true,
    expectedLabel: 'Save your changes',
    actualLabel: 'Save your changes',
    role: 'button',
    affectedComponents: ['YourButton'],
    widgetPath: 'lib/widgets/your_button.dart',
  );
});
```

### Focus Order Test Example

Verify keyboard navigation order:

```dart
testWidgets('form has correct focus order', (tester) async {
  final usernameNode = FocusNode();
  final passwordNode = FocusNode();
  final submitNode = FocusNode();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextField(focusNode: usernameNode),
            TextField(focusNode: passwordNode),
            ElevatedButton(
              focusNode: submitNode,
              onPressed: () {},
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    ),
  );

  final focusOrderReporter = FocusOrderReporter(targetLevel: WcagLevel.a);

  focusOrderReporter.validateComponent(
    componentName: 'UsernameField',
    expectedIndex: 0,
    actualIndex: 0,
    affectedComponents: ['LoginForm'],
    widgetPath: 'lib/pages/login/login_form.dart',
  );

  focusOrderReporter.validateComponent(
    componentName: 'PasswordField',
    expectedIndex: 1,
    actualIndex: 1,
    affectedComponents: ['LoginForm'],
    widgetPath: 'lib/pages/login/login_form.dart',
  );

  focusOrderReporter.validateComponent(
    componentName: 'SubmitButton',
    expectedIndex: 2,
    actualIndex: 2,
    affectedComponents: ['LoginForm'],
    widgetPath: 'lib/pages/login/login_form.dart',
  );
});
```

---

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/accessibility.yml`:

```yaml
name: Accessibility Tests

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]

jobs:
  accessibility:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run accessibility tests
        run: flutter test test/accessibility/

      - name: Upload reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: accessibility-reports
          path: reports/accessibility/

      - name: Comment PR with results
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('reports/accessibility/widget_validation/target_size.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.name,
              body: `## Accessibility Test Results\n\n${report}`
            });
```

### Set Compliance Thresholds

Enforce a minimum compliance rate in CI:

```bash
#!/bin/bash
# scripts/check_accessibility_compliance.sh

MIN_COMPLIANCE=90.0

# Execute tests
flutter test test/accessibility/widget_accessibility_test.dart

# Parse report (simplified example)
COMPLIANCE=$(grep "Overall Compliance:" reports/accessibility/widget_validation/batch/overview.md | awk '{print $3}' | tr -d '%')

if (( $(echo "$COMPLIANCE < $MIN_COMPLIANCE" | bc -l) )); then
  echo "❌ Accessibility compliance $COMPLIANCE% is below minimum $MIN_COMPLIANCE%"
  exit 1
else
  echo "✅ Accessibility compliance $COMPLIANCE% meets minimum requirement"
  exit 0
fi
```

---

## Best Practices

### 1. Test Organization

```
test/accessibility/
├── example_validation.dart           # Full demonstration example
├── components/
│   ├── button_accessibility_test.dart
│   ├── card_accessibility_test.dart
│   └── form_accessibility_test.dart
├── pages/
│   ├── dashboard_accessibility_test.dart
│   └── settings_accessibility_test.dart
└── helpers/
    └── test_helpers.dart              # Shared test utilities
```

### 2. Test Priority

**Critical (Must Test)**:
- Primary buttons (Save, Submit, Delete)
- Navigation elements
- Form input controls
- Switches and checkboxes

**High (Should Test)**:
- Secondary buttons
- Cards and list items
- Icon buttons

**Medium (Recommended Test)**:
- Decorative elements
- Status indicators

### 3. Test Frequency

- **Each PR**: Run tests for critical components.
- **Daily Build**: Run full accessibility test suite.
- **Before Release**: Generate full reports and conduct manual review.

### 4. Version Tracking

Keep historical reports to track improvements:

```bash
# Save reports with version numbers
VERSION=$(git describe --tags --always)
cp -r reports/accessibility reports/accessibility_${VERSION}
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Theme Error

```
Error: AppDesignTheme operation requested with a context that does not include an AppDesignTheme
```

**Solution**: Ensure the correct theme is included in the test:

```dart
await tester.pumpWidget(
  MaterialApp(
    theme: ThemeData.light().copyWith(
      extensions: [
        AppDesignTheme.light(),
      ],
    ),
    home: Scaffold(body: yourWidget),
  ),
);
```

#### Issue 2: Incorrect Component Size

**Solution**: Ensure the component is fully rendered:

```dart
await tester.pumpWidget(yourWidget);
await tester.pumpAndSettle();  // Wait for all animations to complete
```

#### Issue 3: Semantics Not Detected

**Solution**: Ensure the component is wrapped in a Semantics widget:

```dart
Semantics(
  label: 'Button label',
  button: true,
  child: YourButton(...),
)
```

---

## Related Resources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [UI Kit Library Accessibility Documentation](/Users/austin.chang/flutter-workspaces/ui_kit/docs/accessibility/)
- [Full Demonstration Example](../test/accessibility/example_validation.dart)
- [Integration Guide](./ACCESSIBILITY_INTEGRATION.md)

---

## Support

If you have questions or need assistance:

1. Refer to [Troubleshooting Guide](/Users/austin.chang/flutter-workspaces/ui_kit/docs/accessibility/TROUBLESHOOTING.md)
2. Refer to [Integration Guide](./ACCESSIBILITY_INTEGRATION.md)
3. Contact the development team

---

**Last Updated**: 2026-01-27
**Version**: v2.0.0
