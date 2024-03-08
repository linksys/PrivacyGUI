import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:linksys_app/page/login/views/_views.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import '../../../common/testable_widget.dart';
import '../../../common/test_localization.dart';

void main() {
  testLocalizations('Cloud Account View', (tester, locale) async {
    await tester.pumpWidgetBuilder(testableRouteWidget(
      themeMode: ThemeMode.light,
      overrides: [],
      locale: locale,
      child: const CloudLoginAccountView(),
    ));
  });

  testLocalizations('Cloud Account View with invalid format',
      (tester, locale) async {
    await tester.pumpWidgetBuilder(testableRouteWidget(
      themeMode: ThemeMode.light,
      overrides: [],
      locale: locale,
      child: const CloudLoginAccountView(),
    ));

    final cloudAccountViewFinder = find.byType(CloudLoginAccountView);
    final textFieldFinder = find
        .descendant(
            of: cloudAccountViewFinder, matching: find.byType(AppTextField))
        .last;
    await tester.enterText(textFieldFinder, 'abc');
    await tester.pump();

    final nextButtonFinder = find.byType(AppFilledButton).last;
    await tester.tap(nextButtonFinder);
    await tester.pump();
  });
}
