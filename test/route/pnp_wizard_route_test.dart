import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_wifi_draft_provider.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_guest_step_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_wifi_step_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_your_network_step_view.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../mocks/provider_overrides/mock_add_nodes.dart';
import '../mocks/provider_overrides/mock_common.dart';
import '../mocks/provider_overrides/mock_pnp.dart';
import '../mocks/test_data/scenes/pnp_scene_data.dart';
import '../util/app_test_fonts.dart';

/// A flow the test moves, which enters the steps the way the wizard does.
class _DrivenPnp extends FixedPnpNotifier {
  _DrivenPnp() : super(const PnpState(phase: AdminCheckingInternet()));

  void moveTo(PnpPhase phase) => state = state.copyWith(phase: phase);
}

class _MockPnpService extends Mock implements PnpService {}

/// Signed in unless told otherwise, and records the logout.
class _Auth extends AuthNotifier {
  _Auth({this.signedIn = true});

  final bool signedIn;
  int logouts = 0;
  EndCause? cause;

  @override
  Future<AuthState> build() async => signedIn
      ? const AuthState(loginType: LoginType.local)
      : AuthState.empty();

  @override
  Future<void> logout({EndCause cause = EndCause.sessionLost}) async {
    logouts++;
    this.cause = cause;
    state = AsyncData(AuthState.empty());
  }
}

/// The PnP wizard as routes under the production `pnpShellRoute` (#1511 P4):
/// its back policy, `/pnp/pnpConfig`'s exit guard, and the stepper the shell
/// keeps on screen across the steps.
void main() {
  setUpAll(() async => loadAppFonts());

  late _DrivenPnp pnp;
  late _Auth auth;
  late GoRouter router;

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The app at [initial] with a fresh flow.
  Future<void> pumpApp(
    WidgetTester tester, {
    String initial = '/pnp',
    bool signedIn = true,
  }) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    pnp = _DrivenPnp();
    auth = _Auth(signedIn: signedIn);
    router = GoRouter(
      navigatorKey: routerKey,
      initialLocation: initial,
      routes: [
        pnpShellRoute,
        GoRoute(
          path: RoutePath.localLoginPassword,
          builder: (_, __) => const Text('LOGIN'),
        ),
        GoRoute(
          path: RoutePath.uspDashboard,
          builder: (_, __) => const Text('DASHBOARD'),
        ),
        GoRoute(
          name: RouteNamed.pnpNoInternetConnection,
          path: RoutePath.pnpNoInternetConnection,
          builder: (_, __) => const Text('TROUBLESHOOTING'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...commonOverrides(),
        authProvider.overrideWith(() => auth),
        routerProvider.overrideWithValue(router),
        pnpProvider.overrideWith(() => pnp),
        appModeProfileProvider.overrideWithValue(const LocalModeProfile()),
        deviceCapabilitiesProvider.overrideWithValue(
            DeviceCapabilities(const {DeviceCapability.bleOnboarding})),
        ...addNodesOverrides(const AddNodesState()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.create(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await settle(tester);
  }

  /// The flow reads [pnpUnifiedRouter] and enters its steps, as the wizard
  /// does once its read comes back; the shell opens the first.
  Future<void> enterWizard(WidgetTester tester) async {
    pnp.setDemoWizard(pnpUnifiedRouter);
    await settle(tester);
    expect(location(), '/pnp/pnpConfig/wifi');
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

  Finder byId(String id) =>
      find.byWidgetPredicate((w) => w is AppButton && w.identifier == id,
          description: 'AppButton#$id');

  group('moving between steps', () {
    testWidgets('Next and Back follow the plan, and the URL names the step',
        (tester) async {
      await pumpApp(tester);
      await enterWizard(tester);
      expect(find.byType(PnpWifiStepView), findsOneWidget);

      await tester.tap(byId('pnp-step-next'));
      await settle(tester);
      expect(location(), '/pnp/pnpConfig/guest');
      expect(find.byType(PnpGuestStepView), findsOneWidget);

      await tester.tap(byId('pnp-step-next'));
      await settle(tester);
      expect(location(), '/pnp/pnpConfig/network');
      expect(byId('pnp-step-save'), findsOneWidget,
          reason: 'Your Network holds Save until #1511 P5');

      await tester.tap(byId('pnp-step-back'));
      await settle(tester);
      expect(location(), '/pnp/pnpConfig/guest');
    });

    testWidgets('the stepper is one widget across the steps (AC 3)',
        (tester) async {
      // Drawn by the shell, so moving between steps does not rebuild it: its
      // State survives, which is what lets its segments animate.
      await pumpApp(tester);
      await enterWizard(tester);
      final first = tester.state(find.byType(AppStepper));

      router.go('/pnp/pnpConfig/guest');
      await settle(tester);
      router.go('/pnp/pnpConfig/network');
      await settle(tester);

      expect(tester.state(find.byType(AppStepper)), same(first));
      expect(tester.widget<AppStepper>(find.byType(AppStepper)).currentStep, 2);
    });

    testWidgets('an edit survives leaving its step and coming back',
        (tester) async {
      await pumpApp(tester);
      await enterWizard(tester);
      container(tester)
          .read(pnpMainWifiDraftProvider.notifier)
          .setSsid('Typed on step 1');

      router.go('/pnp/pnpConfig/guest');
      await settle(tester);
      router.go('/pnp/pnpConfig/wifi');
      await settle(tester);

      expect(
          find.widgetWithText(AppTextField, 'Typed on step 1'), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets(
        'the stepper and the step stay while saving, and a failed save '
        'comes back to the step where Save was pressed (AC 4)', (tester) async {
      await pumpApp(tester);
      await enterWizard(tester);
      router.go('/pnp/pnpConfig/network');
      await settle(tester);

      pnp.moveTo(const WizardSaving());
      await settle(tester);
      expect(find.byType(AppStepper), findsOneWidget, reason: 'D4');
      expect(find.byType(PnpYourNetworkStepView, skipOffstage: false),
          findsOneWidget,
          reason: 'the step stays mounted under the saving screen');

      pnp.moveTo(const WizardConfiguring(saveError: UnexpectedError()));
      await settle(tester);
      expect(location(), '/pnp/pnpConfig/network');
      expect(find.byType(PnpYourNetworkStepView), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'the failure is said, once (#1000)');
    });

    testWidgets('Back while saving stays on the step that saves',
        (tester) async {
      await pumpApp(tester);
      await enterWizard(tester);
      router.go('/pnp/pnpConfig/network');
      await settle(tester);
      pnp.moveTo(const WizardSaving());
      await settle(tester);

      router.go('/pnp/pnpConfig/wifi');
      await settle(tester);

      expect(location(), '/pnp/pnpConfig/network');
    });

    for (final phase in const <PnpPhase>[
      WizardSaving(),
      WizardSaved(),
      WizardTestingReconnect(attemptCount: 1, maxAttempts: 5),
      WizardCheckingFirmware(),
      WizardUpdatingFirmware(version: '1.0.17'),
    ]) {
      testWidgets('${phase.runtimeType}: the wizard cannot be left',
          (tester) async {
        await pumpApp(tester);
        await enterWizard(tester);
        router.go('/pnp/pnpConfig/network');
        await settle(tester);
        pnp.moveTo(phase);
        await settle(tester);

        router.go(RoutePath.uspDashboard);
        await settle(tester);

        expect(location(), '/pnp/pnpConfig/network');
        expect(find.text('DASHBOARD'), findsNothing);
      });
    }

    testWidgets('the completion screen\'s Done leaves without asking',
        (tester) async {
      await pumpApp(tester);
      await enterWizard(tester);
      router.go('/pnp/pnpConfig/network');
      await settle(tester);
      pnp.moveTo(const WizardWifiReady(ssid: 'Home', password: 'pass1234'));
      await settle(tester);
      expect(find.byType(AppStepper), findsNothing, reason: 'D4');

      await tester.tap(find.widgetWithText(AppButton, 'Done'));
      await settle(tester);

      expect(location(), RoutePath.uspDashboard);
    });
  });

  group('leaving add nodes reads the nodes again (#1734)', () {
    const network = '/pnp/pnpConfig/network';

    // The page on top. A push leaves the route list's URI at the step under it
    // (go_router 17.5.0, `optionURLReflectsImperativeAPIs` off).
    String top() =>
        router.routerDelegate.currentConfiguration.last.matchedLocation;

    /// Your Network, with the add-nodes page opened from its button.
    Future<void> openAddNodes(WidgetTester tester) async {
      await pumpApp(tester);
      await enterWizard(tester);
      router.go(network);
      await settle(tester);
      await tester.tap(byId(kPnpAddNodesIdentifier));
      await settle(tester);
      expect(top(), '$network/${RoutePath.pnpAddNodes}');
      expect(pnp.meshRefreshes, 0, reason: 'not before the page is left');
    }

    testWidgets('when Done pops it', (tester) async {
      await openAddNodes(tester);

      router.pop();
      await settle(tester);

      expect(top(), network);
      expect(pnp.meshRefreshes, 1);
    });

    testWidgets('when the browser goes back to the step', (tester) async {
      // On web, Done is the browser's Back, as is the browser's own button: the
      // step's URL comes in as a new route list, which drops the pushed page
      // without completing its push future (go_router 17.5.0,
      // `setNewRoutePath`). A re-read waiting on that future never ran (PR
      // #1817's review, W1).
      await openAddNodes(tester);

      router.go(network);
      await settle(tester);

      expect(top(), network);
      expect(pnp.meshRefreshes, 1);
    });
  });

  group('leaving from the first step: log out (#1511 P4)', () {
    testWidgets('asks, and Cancel stays on the step with the edit',
        (tester) async {
      await pumpApp(tester);
      await enterWizard(tester);
      container(tester)
          .read(pnpMainWifiDraftProvider.notifier)
          .setSsid('Typed, not saved');

      router.go(RoutePath.pnp); // what Back from the first step asks for
      await settle(tester);
      expect(byId('pnp-leave-setup-log-out'), findsOneWidget);

      await tester.tap(byId('pnp-leave-setup-cancel'));
      await settle(tester);

      expect(location(), '/pnp/pnpConfig/wifi');
      expect(
          container(tester).read(pnpMainWifiDraftProvider.notifier).isDirty(),
          isTrue);
      expect(auth.logouts, 0);
    });

    testWidgets('asks even when the session is already gone', (tester) async {
      // Found in a real browser on the demo build, whose auth reads signed
      // out: Back from the first step went straight to the entry, which only
      // shows a spinner for a flow past its checks. Signed in or not, leaving
      // the setup goes through the prompt and ends on the login page.
      await pumpApp(tester, signedIn: false);
      await enterWizard(tester);

      router.go(RoutePath.pnp);
      await settle(tester);

      expect(byId('pnp-leave-setup-log-out'), findsOneWidget);
      expect(location(), isNot(RoutePath.pnp));

      await tester.tap(byId('pnp-leave-setup-log-out'));
      await settle(tester);
      expect(location(), RoutePath.localLoginPassword);
    });

    testWidgets(
        'Log out reverts the drafts, signs out and lands on the login page',
        (tester) async {
      await pumpApp(tester);
      await enterWizard(tester);
      final c = container(tester);
      // Held by the test so the draft can be read after the wizard is gone.
      c.listen(pnpMainWifiDraftProvider, (_, __) {});
      c.read(pnpMainWifiDraftProvider.notifier).setSsid('Typed, not saved');

      router.go(RoutePath.pnp);
      await settle(tester);
      await tester.tap(byId('pnp-leave-setup-log-out'));
      await settle(tester);

      expect(auth.logouts, 1);
      expect(auth.cause, EndCause.userRequested);
      expect(location(), RoutePath.localLoginPassword);
      expect(c.read(pnpMainWifiDraftProvider).current, pnpUnifiedRouter.main,
          reason: 'the flow-level guard reverted what was typed');
    });
  });

  testWidgets('a reload on a step, with no flow running, goes to the entry',
      (tester) async {
    // Nothing would restart the flow on a step: it would wait on a spinner.
    await pumpApp(tester, initial: '/pnp/pnpConfig/guest');

    expect(location(), RoutePath.pnp);
  });

  testWidgets(
      'the real flow under the real shell: going in from outside starts it '
      'once, from the entry', (tester) async {
    // #1511 P3's reviewer pin, with nothing stubbed between the router and
    // `PnpNotifier`: the shell's redirect runs before the shell exists, and
    // whatever reads the flow first creates it. Only the entry may start the
    // flow, so the router is asked exactly once — a side effect in `build()`,
    // or a redirect that created a throwaway flow which then started, would
    // make it twice.
    final service = _MockPnpService();
    final never = Completer<FactoryDefaultCheckResult>();
    when(() => service.checkFactoryDefault()).thenAnswer((_) => never.future);
    router = GoRouter(
      navigatorKey: routerKey,
      initialLocation: '/outside',
      routes: [
        GoRoute(path: '/outside', builder: (_, __) => const Text('OUTSIDE')),
        pnpShellRoute,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...commonOverrides(),
        pnpServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp.router(
        theme: AppTheme.create(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await settle(tester);

    router.go(RoutePath.pnp);
    await settle(tester);

    expect(location(), RoutePath.pnp);
    verify(() => service.checkFactoryDefault()).called(1);
    expect(container(tester).read(pnpProvider).phase,
        isA<AdminCheckingInternet>());
  });
}
