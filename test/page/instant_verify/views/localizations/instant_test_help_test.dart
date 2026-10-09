import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart'
    as preview;
import 'package:privacy_gui/page/instant_verify/views/answer_row.dart';
import 'package:privacy_gui/page/instant_verify/views/help/help_page.dart';

import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import 'instant_test_loc_app.dart';

// Instant-Test help flow screenshots, one page per flow as its route
// (`help?flow=N`) opens it, over the preview's default data (router busy,
// four devices including the weak-signal "Office-Printer").
// Instant-Test strings are hardcoded English: every locale renders English.

/// The device the device flows pick (weak 2.4 GHz signal in the preview).
const _device = 'Office-Printer';

void main() {
  mockDependencyRegister();

  Future<void> open(WidgetTester tester, Locale locale, int flow,
      {preview.PreviewProbeScenario probes =
          preview.PreviewProbeScenario.healthy,
      ThemeMode themeMode = ThemeMode.system}) async {
    await tester.pumpWidget(instantTestLocApp(
      locale: locale,
      location: helpFlow(flow),
      service: preview.MockBrowserDiagnosticService(scenario: probes),
      themeMode: themeMode,
    ));
    await tester.pumpAndSettle();
    expect(find.text(InstantTestHelpView.title(flow)), findsOneWidget);
  }

  /// The collapsed answer rows a device flow shows once answered.
  void expectAnswered() {
    expect(
        find.byWidgetPredicate((w) => w is AnswerRow && w.label == 'Device'),
        findsOneWidget);
    expect(
        find.byWidgetPredicate((w) => w is AnswerRow && w.label == 'Problem'),
        findsOneWidget);
  }

  testLocalizations('Instant-Test help - internet check - healthy',
      (tester, locale) async {
    await open(tester, locale, 1);
    expect(find.text('Your router can reach the internet'), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test help - internet check - healthy - dark',
      (tester, locale) async {
    await open(tester, locale, 1, themeMode: ThemeMode.dark);
    expect(find.text('Your router can reach the internet'), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test help - internet check - no internet',
      (tester, locale) async {
    await open(tester, locale, 1,
        probes: preview.PreviewProbeScenario.internetDown);
    expect(find.text("Your router can't reach the internet"), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test help - speed - start',
      (tester, locale) async {
    await open(tester, locale, 2);
    expect(find.text('Check my speed'), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test help - speed - result',
      (tester, locale) async {
    await open(tester, locale, 2);
    await tapText(tester, 'Check my speed');
    expect(find.text('Everything in my home is slow'), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test help - device - picker',
      (tester, locale) async {
    await open(tester, locale, 3);
    expect(find.text(_device), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test help - device - answered',
      (tester, locale) async {
    await open(tester, locale, 3);
    await tapText(tester, _device);
    expectAnswered();
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test help - one device slow',
      (tester, locale) async {
    await open(tester, locale, 31);
    await tapText(tester, _device);
    expectAnswered();
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test help - keeps dropping',
      (tester, locale) async {
    await open(tester, locale, 32);
    await tapText(tester, _device);
    expectAnswered();
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test help - coverage', (tester, locale) async {
    await open(tester, locale, 4);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test help - connection drops - answered',
      (tester, locale) async {
    await open(tester, locale, 5);
    await tapText(tester, 'A few times a day');
    await tapText(tester, 'Specific devices');
    expect(find.text('Choose the affected device'), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test help - two routers', (tester, locale) async {
    await open(tester, locale, 6);
  }, screens: instantTestScreens);
}
