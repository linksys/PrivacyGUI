import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/models/troubleshooting_phase.dart';
import 'package:privacy_gui/page/instant_setup/providers/internet_troubleshooting_provider.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_status_service.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../mocks/provider_overrides/mock_common.dart';
import '../mocks/provider_overrides/mock_internet_troubleshooting.dart';

class _MockPnpStatusService extends Mock implements PnpStatusService {}

/// A run the test can end, the way a retry, a modem restart or an ISP save
/// would end it.
class _DrivenTroubleshooting extends FixedInternetTroubleshootingNotifier {
  _DrivenTroubleshooting() : super(const TroubleshootingNoInternet());

  void end(TroubleshootingPhase phase) => state = phase;
}

/// The session `_prepare` filled at login, with the router's serial.
class _LoggedInSession extends Notifier<SessionState>
    implements SessionNotifier {
  final List<String> savedSerials = [];

  @override
  SessionState build() => const SessionState(
        deviceInfo: NodeDeviceInfo(
          modelNumber: 'M60TB',
          firmwareVersion: '2.0.4',
          description: '',
          firmwareDate: '',
          manufacturer: 'Linksys',
          serialNumber: 'SN-TEST',
          hardwareVersion: '1',
        ),
      );

  @override
  Future<void> saveSelectedNetwork(String sn, String networkId) async {
    savedSerials.add(sn);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Troubleshooting with two callers (#1511 P1 AC 3, AC 4), through the
/// production route tree.
///
/// The caller is the `:caller` segment of every troubleshooting URL, and the
/// route layer turns it into the ending the hub hands a finished run to. These
/// cases enter the tree as each caller and check where a run ends and what the
/// hub offers — and that the caller is still there after a cold start on a page
/// inside the tree, which is what a web reload is.
void main() {
  late _DrivenTroubleshooting run;
  late _MockPnpStatusService statusService;
  late _LoggedInSession session;

  setUp(() {
    run = _DrivenTroubleshooting();
    statusService = _MockPnpStatusService();
    session = _LoggedInSession();
    when(() => statusService.acknowledge(any())).thenAnswer((_) async {});
  });

  Future<GoRouter> pumpTree(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Text('APP_ENTRY')),
        GoRoute(path: RoutePath.pnp, builder: (_, __) => const Text('PNP')),
        GoRoute(
          path: RoutePath.uspDashboard,
          builder: (_, __) => const Text('DASHBOARD'),
        ),
        pnpNoInternetRoute,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...commonOverrides(),
        internetTroubleshootingProvider.overrideWith(() => run),
        troubleshootingWanPrefillProvider.overrideWith((ref) => null),
        pnpStatusServiceProvider.overrideWithValue(statusService),
        sessionProvider.overrideWith(() => session),
      ],
      child: MaterialApp.router(
        theme: AppTheme.create(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child ?? const SizedBox.shrink(),
        ),
        routerConfig: router,
      ),
    ));
    await _settle(tester);
    return router;
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  group('entered as the dashboard', () {
    const hub = '/pnpNoInternetConnection/${TroubleshootingCaller.dashboard}';

    testWidgets('a recovered run ends on the dashboard', (tester) async {
      final router = await pumpTree(tester, hub);

      run.end(const TroubleshootingRecovered());
      await _settle(tester);

      expect(location(router), RoutePath.uspDashboard);
      expect(find.text('DASHBOARD'), findsOneWidget);
    });

    testWidgets('a router that cannot be read also hands back to the dashboard',
        (tester) async {
      final router = await pumpTree(tester, hub);

      run.end(const TroubleshootingReadFailure(code: 9998));
      await _settle(tester);

      expect(location(router), RoutePath.uspDashboard);
    });

    testWidgets('the hub never offers the PnP-only bypass', (tester) async {
      await pumpTree(tester, hub);

      expect(find.text('Try again'), findsOneWidget,
          reason: 'the hub itself rendered');
      expect(find.text('Log into router'), findsNothing,
          reason: 'there is no setup to acknowledge, so nothing to continue '
              'into without internet');
    });

    testWidgets('moving within the tree keeps the caller', (tester) async {
      final router = await pumpTree(tester, hub);

      await tester.tap(find.text('Restart your modem'));
      await _settle(tester);

      expect(
          location(router),
          '/pnpNoInternetConnection/${TroubleshootingCaller.dashboard}/'
          '${RoutePath.pnpUnplugModem}');
    });

    testWidgets('a cold start on a page inside the tree keeps the caller',
        (tester) async {
      // A web reload on the modem-restart step: no hub was ever on screen, and
      // the run still ends where the URL says.
      final router = await pumpTree(
        tester,
        '$hub/${RoutePath.pnpUnplugModem}',
      );

      run.end(const TroubleshootingRecovered());
      await _settle(tester);

      expect(location(router), RoutePath.uspDashboard);
    });
  });

  group('entered as PnP', () {
    const hub = '/pnpNoInternetConnection/${TroubleshootingCaller.pnp}';

    testWidgets('a recovered run goes back to PnP\'s entry', (tester) async {
      final router = await pumpTree(tester, hub);

      run.end(const TroubleshootingRecovered());
      await _settle(tester);

      expect(location(router), RoutePath.pnp);
    });

    testWidgets('"Log into router" acknowledges setup and enters the dashboard',
        (tester) async {
      final router = await pumpTree(tester, hub);

      await tester.tap(find.text('Log into router'));
      await _settle(tester);

      verify(() => statusService.acknowledge('SN-TEST')).called(1);
      expect(session.savedSerials, ['SN-TEST']);
      expect(location(router), RoutePath.uspDashboard);
    });
  });

  testWidgets('a caller nobody supplies starts over from the app\'s entry',
      (tester) async {
    final router = await pumpTree(tester, '/pnpNoInternetConnection/nobody');

    expect(location(router), '/');
    expect(find.text('APP_ENTRY'), findsOneWidget);
  });
}

/// Bounded pump: the hub's pages carry looping loaders that never settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
