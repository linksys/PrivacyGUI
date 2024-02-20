import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:linksys_app/page/landing/view/_view.dart';

import '../../../common/testable_widget.dart';

import '../../test_localization.dart';

void main() {
  group('Home View', () {
    testLocalizations(
      'snapshot - home view',
      (tester, locale) async {
        await tester.pumpWidgetBuilder(testableWidget(
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
