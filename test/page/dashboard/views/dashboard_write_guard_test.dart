import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/views/components/port_and_speed.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/_index.dart';

const _readOnly = AccessPolicy(canWrite: false);
const _guardTooltip = 'This feature is unavailable in remote mode';

/// A first poll that has come back, so the dashboard cards leave their loading
/// tiles.
class _ReadyPolling extends PollingNotifier {
  @override
  CoreTransactionData build() =>
      const CoreTransactionData(lastUpdate: 0, isReady: true, data: {});
}

class _FakePrivacy extends InstantPrivacyNotifier {
  @override
  InstantPrivacyState build() =>
      InstantPrivacyState.fromMap(instantPrivacyTestState);
}

/// Counts saves instead of making them.
class _CountingNodeLight extends NodeLightSettingsNotifier {
  int saves = 0;

  @override
  NodeLightSettings build() => NodeLightSettings(isNightModeEnable: false);

  @override
  Future<NodeLightSettings> save() async {
    saves++;
    return state;
  }
}

class _FakeTopology extends InstantTopologyNotifier {
  @override
  InstantTopologyState build() => TopologyTestData().testTopology1SlaveState;
}

class _FakeDashboardHome extends DashboardHomeNotifier {
  @override
  DashboardHomeState build() => const DashboardHomeState();
}

class _FakeDashboardManager extends DashboardManagerNotifier {
  @override
  DashboardManagerState build() => const DashboardManagerState();
}

Finder _switch(String semanticLabel) => find.byWidgetPredicate(
    (w) => w is AppSwitch && w.semanticLabel == semanticLabel);

void main() {
  mockDependencyRegister();

  Future<void> pump(WidgetTester tester, Widget child,
      {AccessPolicy policy = AccessPolicy.full,
      List<Override> overrides = const []}) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        pollingProvider.overrideWith(_ReadyPolling.new),
        accessPolicyProvider.overrideWithValue(policy),
        ...overrides,
      ],
      child: Scaffold(body: child),
      // A blocked switch leaves the tap to the tile or card under it, which
      // opens that feature's page - navigation, not a write.
      extraRoutes: [
        for (final name in [
          RouteNamed.menuInstantPrivacy,
          RouteNamed.menuIncredibleWiFi,
        ])
          LinksysRoute(
            name: name,
            path: '/$name',
            builder: (context, state) => const SizedBox.shrink(),
          ),
      ],
    ));
    await tester.pumpAndSettle();
  }

  // #1637: both quick panel switches write to the router - Instant-Privacy
  // after its confirm dialog, night mode straight away - so both are blocked
  // in read-only mode.
  group('quick panel', () {
    late _CountingNodeLight nodeLight;
    final privacySwitch = _switch('quick instant privacy switch');
    final nightModeSwitch = _switch('quick night mode switch');
    final privacyDialog = find.text('Turn on Instant-Privacy?');

    setUp(() {
      nodeLight = _CountingNodeLight();
      // Night mode shows only on a cognitive mesh router (the test topology's
      // LN16) that supports LED modes.
      when(serviceHelper.isSupportLedMode()).thenReturn(true);
    });

    Future<void> pumpPanel(WidgetTester tester,
            {AccessPolicy policy = AccessPolicy.full}) =>
        pump(tester, const DashboardQuickPanel(), policy: policy, overrides: [
          instantPrivacyProvider.overrideWith(_FakePrivacy.new),
          nodeLightSettingsProvider.overrideWith(() => nodeLight),
          instantTopologyProvider.overrideWith(_FakeTopology.new),
        ]);

    testWidgets('read-only mode blocks the switches', (tester) async {
      await pumpPanel(tester, policy: _readOnly);
      expect(find.byTooltip(_guardTooltip), findsNWidgets(2));

      await tester.tap(nightModeSwitch, warnIfMissed: false);
      await tester.pumpAndSettle();
      // Last, as the tile under it opens the Instant-Privacy page.
      await tester.tap(privacySwitch, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(nodeLight.saves, 0);
      expect(privacyDialog, findsNothing);
    });

    testWidgets('the switches work with full access', (tester) async {
      await pumpPanel(tester);
      expect(find.byTooltip(_guardTooltip), findsNothing);

      await tester.tap(nightModeSwitch);
      // The save runs under a spinner dialog that closes about 100 ms in.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      await tester.tap(privacySwitch);
      await tester.pumpAndSettle();

      expect(nodeLight.saves, 1);
      expect(privacyDialog, findsOneWidget);
    });
  });

  // #1637: the WiFi card's switch turns a network on or off after a confirm
  // dialog, so it is blocked in read-only mode.
  group('WiFi card', () {
    // The guest network: a main band that is on would also warn about the
    // guest band, which reads the rest of the dashboard.
    const guest = DashboardWiFiItem(
      ssid: 'Guest',
      password: 'password',
      radios: ['RADIO_2.4GHz'],
      isGuest: true,
      isEnabled: false,
      numOfConnectedDevices: 0,
    );
    final confirmDialog = find.text("You're updating WiFi settings");

    Future<void> pumpCard(WidgetTester tester,
            {AccessPolicy policy = AccessPolicy.full}) =>
        pump(
          tester,
          const SizedBox(
            width: 400,
            height: 176,
            child: WiFiCard(item: guest, index: 0, canBeDisabled: true),
          ),
          policy: policy,
        );

    testWidgets('read-only mode blocks the switch', (tester) async {
      await pumpCard(tester, policy: _readOnly);
      expect(find.byTooltip(_guardTooltip), findsOneWidget);

      await tester.tap(_switch('guest'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(confirmDialog, findsNothing);
    });

    testWidgets('the switch works with full access', (tester) async {
      await pumpCard(tester);
      expect(find.byTooltip(_guardTooltip), findsNothing);

      await tester.tap(_switch('guest'));
      await tester.pumpAndSettle();

      expect(confirmDialog, findsOneWidget);
    });
  });

  // #1637: the external speed test cannot work over a remote session, so it is
  // blocked on any remote login - even one with full access - not only in
  // read-only mode.
  group('external speed test', () {
    const browser = MethodChannel('com.pichillilorenzo/flutter_inappbrowser');
    late List<String> opened;

    setUp(() => opened = []);

    Future<void> pumpTile(WidgetTester tester, {required bool remote}) async {
      // Its buttons open the test in the in-app browser; record the URL
      // instead.
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(browser, (call) async {
        if (call.method == 'open') {
          final request = (call.arguments as Map)['urlRequest'] as Map;
          opened.add(request['url'] as String);
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(browser, null));
      // No LAN ports and no health check: the tile is the external test.
      await pump(tester, const DashboardHomePortAndSpeed(), overrides: [
        dashboardHomeProvider.overrideWith(_FakeDashboardHome.new),
        dashboardManagerProvider.overrideWith(_FakeDashboardManager.new),
        internetStatusProvider.overrideWith((ref) => InternetStatus.online),
        isRemoteLoginProvider.overrideWithValue(remote),
      ]);
    }

    testWidgets('is blocked on a remote login with full access',
        (tester) async {
      await pumpTile(tester, remote: true);
      expect(find.byTooltip(_guardTooltip), findsOneWidget);

      await tester.tap(find.text('CloudFlare'), warnIfMissed: false);
      await tester.pump();

      expect(opened, isEmpty);
    });

    testWidgets('opens on a local login', (tester) async {
      await pumpTile(tester, remote: false);
      expect(find.byTooltip(_guardTooltip), findsNothing);

      await tester.tap(find.text('CloudFlare'));
      await tester.pump();

      expect(opened, ['https://speed.cloudflare.com/']);
    });
  });
}
