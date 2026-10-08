import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_page.dart';
import 'package:privacy_gui/page/instant_verify/views/overview_tab.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart';
import '../../../common/di.dart';
import '../../../common/testable_widget.dart';

class FeedbackNotifier extends InstantVerifyPivotNotifier {
  @override
  InstantVerifyPivotState build() =>
      const InstantVerifyPivotState(phase: PivotLoadPhase.loading);
  @override
  Future<void> fetch({bool forceSpeedTest = false}) async {}
  void show(InstantVerifyPivotState value) => state = value;
}

void main() {
  mockDependencyRegister();
  testWidgets(
      'checks are visible immediately and replaced by the terminal result',
      (tester) async {
    final notifier = FeedbackNotifier();
    await tester.pumpWidget(testableWidget(
        overrides: [instantVerifyPivotProvider.overrideWith(() => notifier)],
        child: const OverviewTab()));
    await tester.pump();
    expect(find.text('Checking your connection'), findsOneWidget);
    expect(find.text('Your devices'), findsOneWidget);
    expect(find.text('View test progress'), findsNothing);
    notifier.show(const InstantVerifyPivotState(
        phase: PivotLoadPhase.jnapLoaded,
        browserTestStep: 'speed:download',
        deviceInfo: {'modelNumber': 'M60'},
        wanStatus: {'wanStatus': 'Connected'},
        gatewayPing: GatewayPingResult(reachable: true),
        dnsCheck: DnsCheckResult(resolved: true)));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('Website access: Passed')),
        findsOneWidget);
    expect(find.text('Testing download speed…'), findsOneWidget);
    notifier.show(const InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        verdictIsPreliminary: false,
        verdict: Verdict(findings: [], checksRun: 8)));
    await tester.pumpAndSettle();
    expect(find.text('Checking your connection'), findsNothing);
    expect(find.text("We didn't detect any issues"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
      'load failure stops progress and offers a retry without an all-clear',
      (tester) async {
    final notifier = FeedbackNotifier();
    await tester.pumpWidget(testableWidget(
        overrides: [instantVerifyPivotProvider.overrideWith(() => notifier)],
        child: const OverviewTab()));
    notifier.show(const InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'error',
        errorMessage: 'Connection unavailable'));
    await tester.pumpAndSettle();
    expect(find.text("We couldn't finish checking your connection"),
        findsOneWidget);
    expect(find.text("We didn't detect any issues"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Run Again'), findsOneWidget);
    expect(find.text('No internet connection detected.'), findsNothing);
  });

  testWidgets('home removes the device and network shortcuts', (tester) async {
    final notifier = FeedbackNotifier();
    await tester.pumpWidget(testableWidget(
        overrides: [instantVerifyPivotProvider.overrideWith(() => notifier)],
        child: const InstantTestPage()));
    await tester.pump();
    expect(find.text('View devices'), findsNothing);
    expect(find.text('View network'), findsNothing);
    expect(find.text('One device is slow'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Checking your connection')).dy,
        lessThan(tester.getTopLeft(find.text('What needs help?')).dy));
  });

  testWidgets('router home is reachable from a direct workflow URL',
      (tester) async {
    final router = GoRouter(initialLocation: '/instant?instant=3', routes: [
      GoRoute(
          path: '/instant',
          builder: (_, __) => const Scaffold(body: InstantTestPage())),
      GoRoute(
          path: RoutePath.dashboardHome,
          name: RouteNamed.dashboardHome,
          builder: (_, __) =>
              const Scaffold(body: Text('Router home destination'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(testableWidget(
        overrides: [
          instantVerifyPivotProvider.overrideWith(FeedbackNotifier.new),
          browserDiagnosticServiceProvider
              .overrideWithValue(MockBrowserDiagnosticService())
        ],
        child: Router(
            routerDelegate: router.routerDelegate,
            routeInformationParser: router.routeInformationParser,
            routeInformationProvider: router.routeInformationProvider)));
    await tester.pump();
    await tester.tap(find.text('Back to router home'));
    await tester.pumpAndSettle();
    expect(find.text('Router home destination'), findsOneWidget);
  });
}
