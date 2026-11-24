import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/admin/models/network_action_models.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_state.dart';
import 'package:privacy_gui/page/admin/views/router_restart_actions.dart';
import 'package:privacy_gui/page/admin/views/usp_admin_view.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_admin.dart';
import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/devices_test_data.dart';

/// The router's own Reboot / Factory Reset: the confirmation, from the
/// Administration page (#876), and the wait that follows (#1777).
///
/// Both act on the whole network, so the copy says so when the router has
/// nodes, keeps the single-router copy when it has none, and says so too when
/// the devices are not read yet: an unknown mesh is not treated as no mesh on a
/// destructive action.
///
/// The wait depends on how the router took the command. `Device.Reboot()` goes
/// down soon after its reply, so the countdown starts there. A whole-network
/// command replies at once and the controller goes last, so the probe is held
/// until the network status says when.
void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (call) async => call.method == 'getAll'
          ? <String, dynamic>{
              'appName': 'PrivacyGUI',
              'packageName': 'com.linksys.privacygui',
              'version': '0.0.0',
              'buildNumber': '0',
            }
          : null,
    );
  });

  Future<void> openAdmin(WidgetTester tester, Override devices) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...adminPageOverrides(),
        devices,
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            LinksysRoute(
              path: '/',
              name: 'admin_host',
              builder: (context, state) => const UspAdminView(),
            ),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// The devices as the dashboard leaves them: read once, kept for the
  /// session (an L1 provider). The Administration page itself does not read
  /// them.
  Future<void> readDevices(WidgetTester tester) async {
    final container =
        ProviderScope.containerOf(tester.element(find.byType(UspAdminView)));
    await container.read(devicesDataProvider.future);
    await tester.pump();
  }

  Future<void> tapButton(WidgetTester tester, String identifier) async {
    await tester.tap(find.byWidgetPredicate(
        (w) => w is AppButton && w.identifier == identifier));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Override devicesOf(MeshNetwork network) => devicesDataProvider.overrideWith(
      () => FixedDevicesDataNotifierForTopology(
          DevicesData(meshNetwork: network)));

  final singleRouter = MeshNetwork(master: DevicesTestData.createMaster());
  final withNode = MeshNetwork(
    master: DevicesTestData.createMaster(),
    slaves: [DevicesTestData.createWifiSlave()],
  );

  group('Administration - the router\'s confirmation (#876)', () {
    testWidgets('a single router keeps the single-router copy', (tester) async {
      await openAdmin(tester, devicesOf(singleRouter));
      await readDevices(tester);

      await tapButton(tester, 'admin-reboot');

      expect(find.text('Reboot Router'), findsOneWidget);
      expect(find.textContaining('The router will restart.'), findsOneWidget);
    });

    testWidgets('a router with nodes says the whole mesh goes', (tester) async {
      await openAdmin(tester, devicesOf(withNode));
      await readDevices(tester);

      await tapButton(tester, 'admin-factory-reset');

      expect(find.text('Reset Parent and all its child/s to Factory Default'),
          findsOneWidget);
    });

    // The Administration page needs no devices to offer its buttons, so they
    // can be pressed before the devices are read.
    testWidgets('devices not read yet: the whole mesh copy, not the single one',
        (tester) async {
      await openAdmin(
          tester, devicesDataProvider.overrideWith(_LoadingDevicesData.new));

      await tapButton(tester, 'admin-reboot');

      expect(find.text('Reboot Parent and all its child/s'), findsOneWidget);
      expect(find.text('Reboot Router'), findsNothing);
    });
  });

  group('the wait for the router (#1777)', () {
    /// One button per flow, without the Administration page around them: the
    /// page overrides the admin notifier itself, and these tests script it.
    Future<void> openHost(
      WidgetTester tester, {
      required _ScriptedAdminNotifier admin,
      required _ScriptedConnection connection,
    }) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...commonOverrides(),
          devicesOf(singleRouter),
          uspAdminProvider.overrideWith(() => admin),
          appConnectionStateProvider.overrideWith(() => connection),
        ],
        // A router, because the confirmation closes itself with `context.pop`.
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) => Column(children: [
                      AppButton.primary(
                        label: 'Reboot',
                        identifier: 'host-reboot',
                        onTap: () => confirmAndRebootRouter(context, ref),
                      ),
                      AppButton.primary(
                        label: 'Factory Reset',
                        identifier: 'host-factory-reset',
                        onTap: () => confirmAndFactoryResetRouter(context, ref),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
      await tester.pump();
    }

    /// Presses [identifier], confirms, and lets the flow run for [seconds] —
    /// past the scripted wait, and short of a snack bar's 4 s on screen.
    Future<void> runFlow(WidgetTester tester, String identifier,
        {int seconds = 3}) async {
      await tapButton(tester, identifier);
      await tapButton(tester, 'admin-confirm-action-confirm');
      for (var i = 0; i < seconds; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    }

    testWidgets(
        'Device.Reboot(): the countdown starts at the reply, with no network '
        'status read', (tester) async {
      final admin = _ScriptedAdminNotifier(RouterRestartStart.router);
      final connection = _ScriptedConnection(waits: false);
      await openHost(tester, admin: admin, connection: connection);

      await runFlow(tester, 'host-reboot');

      expect(admin.calls, ['reboot']);
      expect(
          connection.entered.single.trigger, RecoveryTrigger.operationalReboot);
      expect(connection.entered.single.cooldown, const Duration(seconds: 60));
      expect(connection.calls, isEmpty);
    });

    testWidgets(
        'RebootAll: the probe is held until the controller goes, then counts '
        'down from there', (tester) async {
      final admin = _ScriptedAdminNotifier(RouterRestartStart.network,
          outcome: NetworkActionOutcome.controllerGoingDown);
      final connection = _ScriptedConnection();
      await openHost(tester, admin: admin, connection: connection);

      await runFlow(tester, 'host-reboot');

      expect(admin.calls, ['reboot', 'awaitNetworkAction']);
      expect(connection.entered.single.cooldown,
          UspAdminNotifier.networkActionLimit + const Duration(seconds: 60),
          reason: 'entered at the reply, with the cooldown as a ceiling');
      expect(connection.calls, ['restartCooldown 60s']);
      expect(find.text('Router reboot complete'), findsOneWidget);
    });

    testWidgets(
        'RebootAll: a status that cannot be read counts down from there too',
        (tester) async {
      final admin = _ScriptedAdminNotifier(RouterRestartStart.network,
          outcome: NetworkActionOutcome.unreachable);
      final connection = _ScriptedConnection();
      await openHost(tester, admin: admin, connection: connection);

      await runFlow(tester, 'host-reboot');

      expect(connection.calls, ['restartCooldown 60s']);
    });

    // The controller is still up, so the wait ends as a recovered one, not
    // through the probe: a factory reset's probe reads a router that answers
    // as one that was reset, and ends the session (pinned in
    // app_connection_state_provider_test.dart, `leaveWaiting`).
    for (final (identifier, label) in [
      ('host-reboot', 'RebootAll'),
      ('host-factory-reset', 'FactoryResetAll'),
    ]) {
      testWidgets(
          '$label: Failed leaves recovery with the session, and says the '
          'router refused', (tester) async {
        final admin = _ScriptedAdminNotifier(RouterRestartStart.network,
            outcome: NetworkActionOutcome.failed);
        final connection = _ScriptedConnection();
        await openHost(tester, admin: admin, connection: connection);

        await runFlow(tester, identifier);

        expect(connection.calls, ['leaveWaiting']);
        expect(find.textContaining('The router refused this command'),
            findsOneWidget);
        expect(find.text('Router reboot complete'), findsNothing);
      });
    }

    testWidgets(
        'RebootAll: not settled by the limit leaves recovery and claims '
        'nothing', (tester) async {
      final admin = _ScriptedAdminNotifier(RouterRestartStart.network,
          outcome: NetworkActionOutcome.timedOut);
      final connection = _ScriptedConnection();
      await openHost(tester, admin: admin, connection: connection);

      await runFlow(tester, 'host-reboot');

      expect(connection.calls, ['leaveWaiting']);
      expect(find.text('Router reboot complete'), findsNothing);
      expect(
          find.textContaining('The router refused this command'), findsNothing);
    });

    // Not settled is not "will not go down". Back in an ordinary session, a
    // reset that lands later would leave the natural recovery retrying a
    // credential the reset wiped, for good; the ceiling's health-only probe
    // ends the wait instead.
    testWidgets(
        'FactoryResetAll: not settled by the limit stays waiting for the '
        'ceiling', (tester) async {
      final admin = _ScriptedAdminNotifier(RouterRestartStart.network,
          outcome: NetworkActionOutcome.timedOut);
      final connection = _ScriptedConnection();
      await openHost(tester, admin: admin, connection: connection);

      await runFlow(tester, 'host-factory-reset');

      expect(connection.calls, isEmpty);
      expect(connection.current, AppConnectionState.waitingForRecovery);
    });

    testWidgets(
        'FactoryResetAll: the same hold, with the reset\'s cooldown and a '
        'health-only probe', (tester) async {
      final admin = _ScriptedAdminNotifier(RouterRestartStart.network,
          outcome: NetworkActionOutcome.controllerGoingDown);
      final connection = _ScriptedConnection();
      await openHost(tester, admin: admin, connection: connection);

      await runFlow(tester, 'host-factory-reset');

      expect(admin.calls, ['factoryReset', 'awaitNetworkAction']);
      final entered = connection.entered.single;
      expect(entered.trigger, RecoveryTrigger.operationalFactoryReset);
      expect(entered.cooldown,
          UspAdminNotifier.networkActionLimit + const Duration(seconds: 90));
      expect(entered.healthOnly, isTrue);
      expect(connection.calls, ['restartCooldown 90s']);
    });

    testWidgets(
        'a whole-network action already running says so, and waits for '
        'nothing', (tester) async {
      final admin = _ScriptedAdminNotifier(RouterRestartStart.alreadyRunning);
      final connection = _ScriptedConnection();
      await openHost(tester, admin: admin, connection: connection);

      await runFlow(tester, 'host-reboot');

      expect(admin.calls, ['reboot']);
      expect(connection.entered, isEmpty);
      expect(
          find.text('Your network is already restarting or resetting. '
              'Wait for it to finish.'),
          findsOneWidget);
    });
  });
}

/// A devices read that never returns.
class _LoadingDevicesData extends DevicesDataNotifier {
  @override
  Future<DevicesData> build() => Completer<DevicesData>().future;
}

/// Answers the restart with [start] and the wait with [outcome], and records
/// which of the two the flow asked for. Never finishes loading: the flow reads
/// none of its state.
class _ScriptedAdminNotifier extends UspAdminNotifier {
  _ScriptedAdminNotifier(this.start,
      {this.outcome = NetworkActionOutcome.controllerGoingDown});

  final RouterRestartStart start;
  final NetworkActionOutcome outcome;
  final calls = <String>[];

  @override
  Future<UspAdminState> build() => Completer<UspAdminState>().future;

  @override
  Future<RouterRestartStart> reboot() async {
    calls.add('reboot');
    return start;
  }

  @override
  Future<RouterRestartStart> factoryReset() async {
    calls.add('factoryReset');
    return start;
  }

  @override
  Future<NetworkActionOutcome> awaitNetworkAction() async {
    calls.add('awaitNetworkAction');
    // At least one poll interval, as on a router.
    await Future<void>.delayed(UspAdminNotifier.networkActionPollInterval);
    return outcome;
  }
}

/// Records what the flow asks of recovery. With [waits] it enters the waiting
/// state, and the first call that ends the hold stands in for the router
/// coming back; without, it declines, so `showRecoveryDialog` shows nothing
/// and nothing has to end it.
class _ScriptedConnection extends AppConnectionStateNotifier {
  _ScriptedConnection({this.waits = true});

  final bool waits;
  final entered = <RecoveryContext>[];
  final calls = <String>[];

  AppConnectionState get current => state;

  @override
  AppConnectionState build() => AppConnectionState.authenticated;

  @override
  bool enterWaiting({required RecoveryContext context}) {
    entered.add(context);
    if (!waits) return false;
    state = AppConnectionState.waitingForRecovery;
    return true;
  }

  @override
  void restartCooldown(Duration cooldown) {
    calls.add('restartCooldown ${cooldown.inSeconds}s');
    state = AppConnectionState.authenticated;
  }

  // Recorded rather than left to the real notifier, so a flow that starts
  // probing where it should not shows up in [calls].
  @override
  void startProbingNow() {
    calls.add('startProbingNow');
    state = AppConnectionState.authenticated;
  }

  @override
  void leaveWaiting() {
    calls.add('leaveWaiting');
    state = AppConnectionState.authenticated;
  }
}
