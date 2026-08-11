import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import '../../../common/di.dart';
import '../../../mocks/pnp_notifier_mocks.dart' as Mock;
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/pnp_admin_view.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_waiting_view.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/device_info_test_data.dart';

/// A stub destination for `RouteNamed.localLoginPassword` so redirect-to-login
/// paths can navigate inside the single-route test harness (which otherwise
/// only knows the '/' route and throws "unknown route name").
LinksysRoute _loginStubRoute() => LinksysRoute(
      name: RouteNamed.localLoginPassword,
      path: RoutePath.localLoginPassword,
      config: const LinksysRouteConfig(noNaviRail: true),
      builder: (context, state) => const SizedBox.shrink(key: Key('loginStub')),
    );

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
  });

  testLocalizations('Instant Setup - PnP: Checking unconfigured router',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 2));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testLocalizations('Instant Setup - PnP: Router is unconfigured',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
        isUnconfigured: true,
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(PnpAdminView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerLn12, context);
      await tester.pumpAndSettle();
    });
  });

  testLocalizations('Instant Setup - PnP: Checking internet connection',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkInternetConnection()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 2));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testLocalizations('Instant Setup - PnP: Internet is connected',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkInternetConnection()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Instant Setup - PnP: Password input required',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
        isUnconfigured: false,
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testLocalizations('Instant Setup - PnP: Tap Where is it',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
        isUnconfigured: false,
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [
          pnpProvider.overrideWith(() => mockPnpNotifier),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final btnFinder = find.byType(TextButton);
    await tester.tap(btnFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant Setup - PnP: Auto Master running',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAdminPassword(any)).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAutoMasterStatus()).thenAnswer((_) async {
      return AutoMasterStatus.running;
    });
    when(mockPnpNotifier.pollAutoMasterStatus()).thenAnswer((_) {
      return Stream.fromFuture(Future.delayed(
          const Duration(seconds: 5), () => AutoMasterStatus.running));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Instant Setup - PnP: Auto Master connection error',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAdminPassword(any)).thenAnswer((_) async {});
    when(mockPnpNotifier.checkAutoMasterStatus()).thenAnswer((_) async {
      return AutoMasterStatus.running;
    });
    // Return null 3 times to trigger connection error
    when(mockPnpNotifier.pollAutoMasterStatus()).thenAnswer((_) {
      return Stream.fromIterable([null, null, null]);
    });

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  // ---------------------------------------------------------------------------
  // `_doLogin` (manual "tap Login") Auto Master gate — A/B/C.
  //
  // Regression lock for the reported "WiFi form filled twice" symptom. After
  // the first-401 fix bails out of the auto-login poll to avoid a lockout, the
  // user re-logs in by tapping Login. Before the gate, `_doLogin` dropped them
  // straight into the config/WiFi form even while Auto Master was still
  // `running`, then the pre-save check bounced them back — filling the form
  // twice. `_doLogin` now runs the same `_checkAutoMasterStatus()` gate as the
  // auto-login and default-password paths.
  //
  // These tests mount a CONFIGURED router (isUnconfigured: false + a router-
  // configured throw) so `_mainView` renders `_routerPasswordView` with the
  // password field + Login button, and `isLoggedIn()` is false by default so
  // the initState auto-login chain stops before navigating — leaving the manual
  // login path as the thing under test.
  // ---------------------------------------------------------------------------

  // A `pnpConfig` destination so the "enter config once" path can navigate
  // inside the single-route harness without throwing "unknown route name".
  // Navigation is by NAME; the path just needs to be a valid absolute top-level
  // route. RoutePath.pnpConfig itself is relative ('pnpConfig', a sub-route of
  // pnp), which is illegal at the top level — so use an explicit '/' path here.
  LinksysRoute pnpConfigStubRoute() => LinksysRoute(
        name: RouteNamed.pnpConfig,
        path: '/${RoutePath.pnpConfig}',
        config: const LinksysRouteConfig(noNaviRail: true),
        builder: (context, state) =>
            const SizedBox.shrink(key: Key('pnpConfigStub')),
      );

  // Common notifier stubs to reach `_routerPasswordView` on a configured
  // router; individual tests layer the Auto Master behavior on top.
  void stubConfiguredRouter() {
    when(mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(
          jsonDecode(testDeviceInfo)['output'],
        ),
        isUnconfigured: false,
      ),
    );
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });
    when(mockPnpNotifier.checkAdminPassword(any)).thenAnswer((_) async {});
    when(mockPnpNotifier.checkInternetConnection()).thenAnswer((_) async {});
  }

  // Gives the responsive layout room so `_mainView`'s card/image column doesn't
  // overflow the default 800x600 test surface.
  void useLargeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  // Types the password and taps the Login button to drive `_doLogin`.
  // The router-password view has exactly one AppFilledButton (Login); the
  // "Where is it" affordance is an AppTextButton. Matching by type keeps this
  // locale-independent (the label is "Log in"/"Anmelden"/… per locale).
  Future<void> tapLogin(WidgetTester tester) async {
    await tester.enterText(find.byType(AppPasswordField), 'Password!!!');
    await tester.pump();
    await tester.tap(find.byType(AppFilledButton));
  }

  // These are pure flow/checkpoint regression tests (they assert on route stubs
  // and the waiting view, not pixels), so they use plain `testWidgets` rather
  // than `testLocalizations` — no golden image is meaningful here, matching the
  // sibling pnp_auto_master_flow_test.dart.

  // A: Auto Master still `running` when the user taps Login → the flow must
  // STOP on the waiting view and NOT enter config. This is the direct
  // regression lock for the "WiFi form filled twice" symptom. The poll stream
  // stays open (never emits, never closes) so the flow parks on the waiting
  // view without a pending timer.
  testWidgets(
      'Instant Setup - PnP: Tap Login while Auto Master running stays on waiting view',
      (tester) async {
    useLargeScreen(tester);
    stubConfiguredRouter();
    when(mockPnpNotifier.checkAutoMasterStatus())
        .thenAnswer((_) async => AutoMasterStatus.running);
    final pollController = StreamController<AutoMasterStatus?>();
    addTearDown(pollController.close);
    when(mockPnpNotifier.pollAutoMasterStatus())
        .thenAnswer((_) => pollController.stream);

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
        extraRoutes: [pnpConfigStubRoute()],
      ),
    );
    // Let initState settle onto the password view, then drive `_doLogin`.
    await tester.pump(const Duration(seconds: 1));
    await tapLogin(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PnpAutoMasterWaitingView), findsOneWidget);
    // Must NOT have entered config while Auto Master is still running.
    expect(find.byKey(const Key('pnpConfigStub')), findsNothing);
  });

  // B: Auto Master `failed` (found another Master, credential NOT rotated) →
  // `_checkAutoMasterStatus` returns normally, so `_doLogin` proceeds into
  // config exactly once.
  testWidgets(
      'Instant Setup - PnP: Tap Login with Auto Master failed enters config',
      (tester) async {
    useLargeScreen(tester);
    stubConfiguredRouter();
    when(mockPnpNotifier.checkAutoMasterStatus())
        .thenAnswer((_) async => AutoMasterStatus.running);
    when(mockPnpNotifier.pollAutoMasterStatus())
        .thenAnswer((_) => Stream.value(AutoMasterStatus.failed));

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
        extraRoutes: [pnpConfigStubRoute()],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tapLogin(tester);
    // The full `_doLogin` chain here spans BOTH clocks: mock futures / the poll
    // stream resolve on real microtasks (advanced by `runAsync`), while the 1s
    // internet-connected view uses a fake timer (advanced by `pump(Duration)`).
    // Step both, then settle the route transition.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pnpConfigStub')), findsOneWidget);
  });

  // B': Auto Master resolves to `complete` (make-Master finished → credential
  // rotated) → `_checkAutoMasterStatus` throws ExceptionInterruptAndExit and
  // `_doLogin` must send the user to re-login, NOT into config with a stale
  // session. Without the ExceptionInterruptAndExit handler this fell through to
  // the catch-all and showed a bogus error on the password screen.
  testWidgets(
      'Instant Setup - PnP: Tap Login with Auto Master complete redirects to login',
      (tester) async {
    useLargeScreen(tester);
    stubConfiguredRouter();
    when(mockPnpNotifier.checkAutoMasterStatus())
        .thenAnswer((_) async => AutoMasterStatus.running);
    when(mockPnpNotifier.pollAutoMasterStatus())
        .thenAnswer((_) => Stream.value(AutoMasterStatus.complete));

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
        extraRoutes: [_loginStubRoute(), pnpConfigStubRoute()],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tapLogin(tester);
    // Drive the real event loop so the poll `await for` runs to `complete`
    // (throwing ExceptionInterruptAndExit) and the redirect resolves.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginStub')), findsOneWidget);
    expect(find.byKey(const Key('pnpConfigStub')), findsNothing);
  });

  // C: the `checkAutoMasterStatus()` gate cannot determine the status (null) —
  // the router is unreachable, or its firmware still requires auth for
  // GetAutoMasterStatus and answers 401 to the unauthed read. There is nothing
  // to wait for, so the gate must not block: `_doLogin` proceeds into config.
  // If Auto Master then does rotate the credential, PnP's own second pass (the
  // pre-save check) is what recovers.
  testWidgets(
      'Instant Setup - PnP: Tap Login with Auto Master status unavailable enters config',
      (tester) async {
    useLargeScreen(tester);
    stubConfiguredRouter();
    when(mockPnpNotifier.checkAutoMasterStatus()).thenAnswer((_) async => null);

    await tester.pumpWidget(
      testableSingleRoute(
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
        extraRoutes: [_loginStubRoute(), pnpConfigStubRoute()],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tapLogin(tester);
    // Same two-clock dance as B: mock futures resolve on real microtasks
    // (runAsync), the 1s internet-connected view on the fake timer (pump).
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pnpConfigStub')), findsOneWidget);
    // Never polled: null is not `running`, so there was nothing to wait on.
    verifyNever(mockPnpNotifier.pollAutoMasterStatus());
  });
}
