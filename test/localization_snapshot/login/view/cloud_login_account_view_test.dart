import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:linksys_app/page/login/view/_view.dart';

import '../../../common/testable_widget.dart';
import '../../test_localization.dart';

void main() {
  testLocalizations('test cloud login account view input something',
      (tester, locale) async {
    await tester.pumpWidgetBuilder(testableWidget(
      themeMode: ThemeMode.light,
      overrides: [],
      locale: locale,
      theme: mockLightThemeData,
      darkTheme: mockDarkThemeData,
      child: const CloudLoginAccountView(),
    ));
  });
}
