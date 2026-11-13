import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_probe_settings.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_write.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_probe_draft_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_setting_steps_provider.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_status_service.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_guest_step_view.dart';
import 'package:privacy_gui/page/instant_setup/views/probe/pnp_probe_step_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../mocks/provider_overrides/mock_common.dart';
import '../../mocks/provider_overrides/mock_pnp.dart';
import '../../mocks/test_data/scenes/pnp_scene_data.dart';
import '../../util/app_test_fonts.dart';

class _DrivenPnp extends FixedPnpNotifier {
  _DrivenPnp() : super(const PnpState(phase: AdminCheckingInternet()));

  void moveTo(PnpPhase phase) => state = state.copyWith(phase: phase);
}

class _MockPnpService extends Mock implements PnpService {}

class _MockStatusService extends Mock implements PnpStatusService {}

class _MockUspClient extends Mock implements UspClient {}

class _NoSession extends Notifier<SessionState> implements SessionNotifier {
  @override
  SessionState build() => const SessionState();

  @override
  Future<void> saveSelectedNetwork(String sn, String networkId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWrite extends Fake implements PnpWifiWrite {}

/// **#1511 P6 — the acceptance probe.** A third setting step, `probe`, added
/// the way Night Mode will be: its view, its draft, its save contribution, one
/// entry in each step list and its inclusion condition. Nothing in the shell,
/// the stepper, Save placement, the back policy, the dirty guard or the phase
/// machine was edited for it; these cases show that they take it anyway.
///
/// Test-only and never shipped: the router read (`PnpService.fetchWizardData`)
/// never fills `PnpWizardData.probe`, so no real router gets the step. Removed
/// by the commit after the one that adds it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
    registerFallbackValue(_FakeWrite());
  });

  /// [pnpUnifiedRouter], reporting the probe's switch off.
  final withProbe = PnpWizardData(
    main: pnpUnifiedRouter.main,
    guest: pnpUnifiedRouter.guest,
    probe: const PnpProbeSettings(enabled: false),
  );

  test('the plan takes it from the step list, and Save moves onto it', () {
    final plan = buildPnpFlowPlan(withProbe);

    expect(plan.stepIds, ['wifi', 'guest', 'probe', 'network']);
    expect(plan.saveStepId, 'probe');
    expect(buildPnpFlowPlan(pnpUnifiedRouter).stepIds,
        ['wifi', 'guest', 'network'],
        reason: 'its inclusion condition: no probe on the router, no step');
  });

  group('through the production shell', () {
    late _DrivenPnp pnp;
    late GoRouter router;

    String location() => router.routerDelegate.currentConfiguration.uri.path;

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Finder byId(String id) =>
        find.byWidgetPredicate((w) => w is AppButton && w.identifier == id);

    ProviderContainer container(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

    Future<void> enterWizard(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      pnp = _DrivenPnp();
      router = GoRouter(
        navigatorKey: routerKey,
        initialLocation: RoutePath.pnp,
        routes: [pnpShellRoute],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...commonOverrides(),
          routerProvider.overrideWithValue(router),
          pnpProvider.overrideWith(() => pnp),
          appModeProfileProvider.overrideWithValue(const LocalModeProfile()),
          deviceCapabilitiesProvider.overrideWithValue(
              DeviceCapabilities(const {DeviceCapability.bleOnboarding})),
        ],
        child: MaterialApp.router(
          theme: AppTheme.create(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await settle(tester);
      pnp.setDemoWizard(withProbe);
      await settle(tester);
    }

    testWidgets(
        'it has a route, a stepper segment and its place in Next and Back; '
        'the step before it ends in Next now, and it holds Save',
        (tester) async {
      await enterWizard(tester);

      final stepper = tester.widget<AppStepper>(find.byType(AppStepper));
      expect(stepper.steps.map((s) => s.id),
          ['wifi', 'guest', 'probe', 'network']);

      await tester.tap(byId('pnp-step-next'));
      await settle(tester);
      expect(find.byType(PnpGuestStepView), findsOneWidget);
      expect(byId('pnp-step-save'), findsNothing);

      await tester.tap(byId('pnp-step-next'));
      await settle(tester);
      expect(location(), '/pnp/pnpConfig/probe');
      expect(find.byType(PnpProbeStepView), findsOneWidget);
      expect(byId('pnp-step-save'), findsOneWidget);
      expect(tester.widget<AppStepper>(find.byType(AppStepper)).currentStep, 2);

      await tester.tap(byId('pnp-step-back'));
      await settle(tester);
      expect(location(), '/pnp/pnpConfig/guest');
    });

    testWidgets(
        'the back policy keeps the user on it while saving, and off it once '
        'the save has landed', (tester) async {
      await enterWizard(tester);
      router.go('/pnp/pnpConfig/probe');
      await settle(tester);

      pnp.moveTo(const WizardSaving());
      await settle(tester);
      router.go('/pnp/pnpConfig/wifi');
      await settle(tester);
      expect(location(), '/pnp/pnpConfig/probe');

      pnp.moveTo(const WizardYourNetwork(
          ready: WizardWifiReady(ssid: 'Home', password: 'pass1234')));
      await settle(tester);
      expect(location(), '/pnp/pnpConfig/network');
      router.go('/pnp/pnpConfig/probe');
      await settle(tester);
      expect(location(), '/pnp/pnpConfig/network');
    });

    testWidgets('the flow-level dirty guard covers its draft', (tester) async {
      await enterWizard(tester);
      final c = container(tester);
      final drafts = c.read(pnpWizardDraftsProvider);
      expect(drafts.isDirty(), isFalse);

      c.read(pnpProbeDraftProvider.notifier).setEnabled(true);
      expect(c.read(pnpWizardDraftsProvider).isDirty(), isTrue);

      c.read(pnpWizardDraftsProvider).revert();
      expect(c.read(pnpProbeDraftProvider).current.enabled, isFalse);
    });
  });

  test('its contribution goes out with the save', () async {
    final service = _MockPnpService();
    final status = _MockStatusService();
    when(() => service.checkFactoryDefault()).thenAnswer((_) async =>
        const FactoryDefaultCheckResult(serialNumber: 'SN', modelName: 'M'));
    when(() => service.checkInternetConnected()).thenAnswer((_) async => true);
    when(() => service.fetchWizardData()).thenAnswer((_) async => withProbe);
    when(() => service.fetchMeshTopology())
        .thenAnswer((_) async => MeshTopologyInfo.empty);
    when(() => service.saveWifi(any()))
        .thenAnswer((_) async => PnpWifiWriteOutcome.confirmed);
    when(() => status.acknowledge(any())).thenAnswer((_) async {});
    final container = ProviderContainer(overrides: [
      pnpServiceProvider.overrideWithValue(service),
      pnpStatusServiceProvider.overrideWithValue(status),
      uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      sessionProvider.overrideWith(() => _NoSession()),
    ]);
    addTearDown(container.dispose);
    container.listen(pnpProvider, (_, __) {});
    final flow = container.read(pnpProvider.notifier);
    await flow.startPostLoginFlow();

    container.read(pnpProbeDraftProvider.notifier).setEnabled(true);
    await flow.saveChanges();

    final write = verify(() => service.saveWifi(captureAny())).captured.single
        as PnpWifiWrite;
    expect(
        write.probe,
        const Preservable(
          original: PnpProbeSettings(enabled: false),
          current: PnpProbeSettings(enabled: true),
        ));
    expect(container.read(pnpProvider).phase, isA<WizardYourNetwork>());
    expect(container.read(pnpProbeDraftProvider.notifier).isDirty(), isFalse,
        reason: 'marked saved with the others');
  });

  test('the service writes it in the Wi-Fi SET', () async {
    final usp = _MockUspClient();
    when(() => usp.set(any(), allowPartial: any(named: 'allowPartial')))
        .thenAnswer((_) async => {
              'success': true,
              'result': {'data': <String, dynamic>{}}
            });
    final main = pnpUnifiedRouter.main;

    await PnpService(usp).saveWifi(PnpWifiWrite(
      main: Preservable(original: main, current: main),
      probe: const Preservable(
        original: PnpProbeSettings(enabled: false),
        current: PnpProbeSettings(enabled: true),
      ),
    ));

    expect(
        verify(() => usp.set(captureAny(), allowPartial: true)).captured.single,
        {'Device.X_LINKSYS_PnpProbe.Enable': true});
  });
}
