// The dashboard shell's banners must reach the semantics tree under the real
// ShellRoute (linksys/PrivacyGUI#1844).
//
// `UspDashboardShell` paints `SseConnectionBanner` and, on the local surface,
// `RemoteAssistanceBanner` in one `Column` before `widget.child` — the
// `ShellRoute`'s nested `Navigator`. Every page under it is a `ModalRoute`, whose
// `ModalBarrier` is a `BlockSemantics`: it drops the semantics of everything
// painted before it in the same semantics container. So the banners were on
// screen ("Disconnected" and its Reconnect button, the Remote Assistance PIN) but
// not in the semantics tree, and a screen reader could neither announce nor reach
// them. The PnP shell had the same defect (#1841, fixed by #1843).
//
// The test is the shape of the app: the real `UspDashboardShell` as the builder
// of a real go_router `ShellRoute`. A plain-widget child would not reproduce the
// bug, so none is used here.
//
// Faked, and only these: the SSE manager and its state stream (the banner's
// input), the connection state, SSE bootstrap and dashboard readiness (each
// reaches the router), the theme JSON load, the remote-assistance client (it
// polls the cloud) and the mascot's random-speech timer (it never stops, so the
// test could not end). Everything the shell lays out is real.
//
// Deliberately untagged: `run_tests.sh` excludes `golden||loc||ui`, and this is
// a regression guard a PR must not merge past.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/usp/models/sse_connection_state.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/mascot/mascot_providers.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/page/shell/usp_dashboard_shell.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/theme_config_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../core/usp/mocks.dart';
import '../../mocks/provider_overrides/mock_common.dart';

class _FixedConnectionState extends AppConnectionStateNotifier {
  @override
  AppConnectionState build() => AppConnectionState.authenticated;
}

class _FixedRemoteClient extends RemoteClientNotifier {
  _FixedRemoteClient(this._seed);
  final RemoteClientState _seed;

  @override
  RemoteClientState build() => _seed;
}

/// The mascot's coordinator with its random-speech timer left out.
class _SilentMascotCoordinator extends MascotCoordinatorNotifier {
  @override
  void build() {}
}

class _MockConnection extends Mock implements SseConnectionManager {}

/// A Remote Assistance session waiting for the agent: the one state in which
/// `RemoteAssistanceBanner` draws anything.
const _pendingSession = RemoteClientState(
  sessionInfo: GRASessionInfo(
    id: 'session-1844',
    serialNumber: 'SN1844',
    modelNumber: 'M1844',
    status: GRASessionStatus.pending,
    expiredIn: 300,
    createdAt: 0,
    statusChangedAt: 0,
    currentTime: 0,
  ),
  pin: '184418',
  expiredCountdown: 300,
);

final _theme = ThemeJsonConfig.defaultConfig().createLightTheme();

void main() {
  const pageAnchor = 'shell-1844-page';

  late MockSseManager manager;
  late StreamController<SseConnectionState> sse;

  setUp(() {
    // The Show Mascot switch writes through `AppSettingsNotifier.update`, which
    // persists before it sets state.
    SharedPreferences.setMockInitialValues({});
    manager = MockSseManager();
    final connection = _MockConnection();
    when(() => manager.tryReconnect()).thenAnswer((_) async => true);
    when(() => manager.connection).thenReturn(connection);
    when(() => connection.lastDisconnectCause)
        .thenReturn(SseDisconnectCause.none);
    sse = StreamController<SseConnectionState>.broadcast();
  });
  tearDown(() => sse.close());

  /// Pumps `UspDashboardShell` exactly as `uspDashboardRoute` does — as the
  /// builder of a `ShellRoute` — with one page under it, and returns the
  /// container so a test can flip a setting the way the app does.
  Future<ProviderContainer> pumpShell(
    WidgetTester tester, {
    RemoteClientState remoteClient = const RemoteClientState(),
  }) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const AppModeProfile profile = LocalModeProfile();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Also registers the GetIt theme singletons `buildStudioThemeData`
        // reads outside the widget tree.
        ...commonOverrides(),
        appModeProfileProvider.overrideWithValue(profile),
        sseManagerProvider.overrideWithValue(manager),
        sseConnectionStateProvider.overrideWith((ref) => sse.stream),
        appConnectionStateProvider.overrideWith(_FixedConnectionState.new),
        sseBootstrapProvider.overrideWith((ref) {}),
        // Ready from the first frame: the mascot is mounted only once the
        // dashboard is.
        dashboardDomainReadyProvider.overrideWith((ref) {}),
        themeConfigProvider
            .overrideWith((ref) => ThemeJsonConfig.defaultConfig()),
        remoteClientProvider
            .overrideWith(() => _FixedRemoteClient(remoteClient)),
        mascotCoordinatorProvider.overrideWith(_SilentMascotCoordinator.new),
      ],
      child: MaterialApp.router(
        theme: _theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation: '/dashboard',
          routes: [
            ShellRoute(
              // A key of its own, as `uspShellNavigatorKey` is to the app's.
              navigatorKey: GlobalKey<NavigatorState>(),
              builder: (context, state, child) =>
                  UspDashboardShell(child: child),
              routes: [
                LinksysRoute(
                  path: '/dashboard',
                  name: 'shell_1844_page',
                  builder: (context, state) => Semantics(
                    identifier: pageAnchor,
                    child: const Text('PAGE BODY'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
    await tester.pump();
    return ProviderScope.containerOf(
        tester.element(find.byType(UspDashboardShell)));
  }

  /// Pumps frames rather than settling: the mascot's idle bob never ends.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> showDisconnected(WidgetTester tester) async {
    sse.add(SseConnectionState.disconnected);
    await pumpFrames(tester);
  }

  void expectSseBannerInSemantics() {
    // Premise: the banner is painted. Without this a missing node could mean
    // the banner simply was not built.
    expect(find.text('Disconnected'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Disconnected')), findsOneWidget,
        reason: 'the SSE banner\'s text must be in the semantics tree (#1844: '
            'the page route\'s ModalBarrier must not block it)');
    expect(find.bySemanticsLabel(RegExp('Reconnect')), findsOneWidget,
        reason: 'the SSE banner\'s Reconnect button must be reachable');
  }

  void expectPageInSemantics() {
    // The fix must not hide the page: its own semantics stay in the tree (an
    // ExcludeSemantics over the routed child would pass the banner checks and
    // fail this one).
    expect(find.text('PAGE BODY'), findsOneWidget);
    expect(find.bySemanticsIdentifier(pageAnchor), findsOneWidget,
        reason: 'the routed page\'s own semantics must still be present');
  }

  testWidgets(
      'the SSE banner and its Reconnect button are in the semantics '
      'tree', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester);
    await showDisconnected(tester);

    expectSseBannerInSemantics();
    expectPageInSemantics();
    handle.dispose();
  });

  testWidgets('the Remote Assistance banner is in the semantics tree',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester, remoteClient: _pendingSession);
    await pumpFrames(tester);

    expect(find.text('184418'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('184418')), findsOneWidget,
        reason: 'the PIN must be in the semantics tree (#1844)');
    expect(find.bySemanticsLabel(RegExp('Remote Assistance')), findsOneWidget,
        reason: 'the banner\'s title must be in the semantics tree (#1844)');
    expectPageInSemantics();
    handle.dispose();
  });

  // Flipping Show Mascot changes the shell's tree, and the boundary #1844 adds
  // sits right above the `ShellRoute`'s Navigator, so both banners and the page
  // must come through every flip.
  //
  // What this does not catch: the crash in the shell's mascot comment. It does
  // not reproduce in a widget test — the pre-a875d6cd6 shape, `MascotOverlay`
  // wrapping the content and coming and going with the switch, throws nothing
  // here — so that check is made on the running app. A wrapper of that shape
  // does still fail this test: it remounts the banner, which loses the state it
  // was showing. A `Semantics` boundary made conditional on the switch passes it.
  testWidgets('flipping Show Mascot keeps the banner and the page',
      (tester) async {
    final handle = tester.ensureSemantics();
    final container = await pumpShell(tester);
    await showDisconnected(tester);
    final settings = container.read(appSettingsProvider.notifier);

    // Premise: the mascot is up, so the flips below change the tree.
    expect(find.byType(MascotOverlay), findsOneWidget);

    for (final show in [false, true, false, true]) {
      settings.update(container.read(appSettingsProvider).copyWith(
            showMascot: show,
          ));
      await pumpFrames(tester);

      expect(tester.takeException(), isNull,
          reason: 'Show Mascot -> $show must not throw');
      expect(find.byType(MascotOverlay), show ? findsOneWidget : findsNothing);
      expectSseBannerInSemantics();
      expectPageInSemantics();
    }
    handle.dispose();
  });
}
