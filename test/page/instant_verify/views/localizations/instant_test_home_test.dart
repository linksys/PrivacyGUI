import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart'
    as preview;
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';

import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import 'instant_test_loc_app.dart';

// Instant-Test results page (home) screenshots.
// Instant-Test strings are hardcoded English: every locale renders English.

void main() {
  mockDependencyRegister();

  testLocalizations('Instant-Test home - checking', (tester, locale) async {
    await tester.pumpWidget(instantTestLocApp(
      locale: locale,
      pivot: fixedState(const InstantVerifyPivotState(
        phase: PivotLoadPhase.jnapLoaded,
        browserTestStep: 'speed:download',
        wanStatus: {'wanStatus': 'Connected'},
        gatewayPing: GatewayPingResult(reachable: true, latencyMs: 2),
        dnsCheck: DnsCheckResult(resolved: true, latencyMs: 12),
      )),
    ));
    // Checks are still running: their spinner never settles.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Checking your connection'), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test home - all clear', (tester, locale) async {
    await tester.pumpWidget(instantTestLocApp(
      locale: locale,
      pivot: fixedState(const InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        wanStatus: {
          'wanStatus': 'Connected',
          'wanConnection': {'ipAddress': '192.168.50.105'}
        },
        deviceInfo: {'modelNumber': 'MX6200', 'firmwareVersion': '1.0.10'},
        routerHealth: {'uptimeInSeconds': 86400},
        gatewayPing: GatewayPingResult(reachable: true, latencyMs: 2),
        dnsCheck: DnsCheckResult(resolved: true, latencyMs: 15),
        speedTest: SpeedTestResult(
            downloadMbps: 100, uploadMbps: 50, latencyMs: 12, jitterMs: 3),
        verdict: Verdict(findings: [], checksRun: 8),
        verdictIsPreliminary: false,
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.text("We didn't detect any issues"), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test home - router busy', (tester, locale) async {
    await tester.pumpWidget(instantTestLocApp(locale: locale));
    await tester.pumpAndSettle();
    expect(find.text('Your router is very busy'), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test home - router busy - dark',
      (tester, locale) async {
    await tester.pumpWidget(
        instantTestLocApp(locale: locale, themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(find.text('Your router is very busy'), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test home - more things we found',
      (tester, locale) async {
    await tester.pumpWidget(instantTestLocApp(locale: locale));
    await tester.pumpAndSettle();
    await tapTextContaining(tester, 'more things we found');
    expect(find.textContaining('Hide '), findsOneWidget);
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test home - no internet', (tester, locale) async {
    await tester.pumpWidget(instantTestLocApp(
      locale: locale,
      // Preview scenario A: the router's internet (WAN) is down.
      pivot: () => preview.MockInstantVerifyPivotNotifier(overviewScenario: 0),
    ));
    await tester.pumpAndSettle();
  }, screens: instantTestScreens);

  testLocalizations('Instant-Test home - check could not finish',
      (tester, locale) async {
    await tester.pumpWidget(instantTestLocApp(
      locale: locale,
      pivot: fixedState(const InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'error',
        errorMessage: 'Simulated check failure',
      )),
    ));
    await tester.pumpAndSettle();
  }, screens: instantTestScreens);
}
