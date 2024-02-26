import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:linksys_app/page/login/views/_views.dart';

import '../../../common/testable_widget.dart';
import '../../test_localization.dart';

void main() {
  setUpAll(() async {});
  tearDownAll(() async {});

  testLocalizations('Cloud Password View', (tester, locale) async {
    await tester.pumpWidgetBuilder(testableRouterWidget(
      themeMode: ThemeMode.light,
      overrides: [],
      locale: locale,
      child: const CloudLoginPasswordView(
        args: {'username': 'awesome@linksys.com'},
      ),
    ));
  });
}
