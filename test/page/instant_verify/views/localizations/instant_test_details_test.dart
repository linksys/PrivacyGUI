import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import 'instant_test_loc_app.dart';

// Instant-Test Device details and Network details screenshots, as their routes
// open them, over the preview's default data: four devices (one with a weak
// 2.4 GHz signal) and a three-node mesh whose Bedroom node has a weak link.
// Instant-Test strings are hardcoded English: every locale renders English.

void main() {
  mockDependencyRegister();

  Future<void> open(WidgetTester tester, Locale locale, String page,
      {ThemeMode themeMode = ThemeMode.system}) async {
    await tester.pumpWidget(instantTestLocApp(
      locale: locale,
      location: '$instantTestHome/$page',
      themeMode: themeMode,
    ));
    await tester.pumpAndSettle();
  }

  testLocalizations('Instant-Test details - devices', (tester, locale) async {
    await open(tester, locale, 'devices');
    expect(find.text('Device details'), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test details - device expanded',
      (tester, locale) async {
    await open(tester, locale, 'devices');
    await tapText(tester, 'Office-Printer');
    expect(find.text('Troubleshoot this device'), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test details - network weak node',
      (tester, locale) async {
    await open(tester, locale, 'network');
    expect(find.text('Network details'), findsOneWidget);
    expect(find.textContaining('Bedroom'), findsWidgets);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test details - network weak node - dark',
      (tester, locale) async {
    await open(tester, locale, 'network', themeMode: ThemeMode.dark);
    expect(find.text('Network details'), findsOneWidget);
  }, screens: instantTestScreens);
}
