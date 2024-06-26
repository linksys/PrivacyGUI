import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:privacy_gui/page/landing/views/_views.dart';

import '../../../common/test_localization.dart';
import '../../../common/testable_router.dart';
import '../../../common/theme.dart';

void main() {
  group('Home View', () {
    testLocalizations(
      'snapshot - home view',
      (tester, locale) async {
        await tester.pumpWidgetBuilder(testableSingleRoute(
          themeMode: ThemeMode.light,
          overrides: [],
          locale: locale,
          theme: mockLightThemeData,
          darkTheme: mockDarkThemeData,
          child: const HomeView(),
        ));
      },
    );
  });
}
