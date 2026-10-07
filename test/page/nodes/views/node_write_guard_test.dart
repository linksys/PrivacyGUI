import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/nodes/views/add_nodes_view.dart';
import 'package:privacy_gui/page/nodes/views/blink_node_light_widget.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/add_nodes_notifier_mocks.dart';
import '../../../mocks/device_filter_config_notifier_mocks.dart';
import '../../../mocks/device_manager_notifier_mocks.dart';
import '../../../mocks/firmware_update_notifier_mocks.dart';
import '../../../mocks/node_detail_notifier_mocks.dart';
import '../../../mocks/wifi_list_notifier_mocks.dart';
import '../../../test_data/device_filter_config_test_state.dart';
import '../../../test_data/device_filtered_list_test_data.dart';
import '../../../test_data/device_manager_test_state.dart';
import '../../../test_data/node_details_data.dart';
import '../../../test_data/wifi_list_test_state.dart';

const _readOnly = AccessPolicy(canWrite: false);

void main() {
  mockDependencyRegister();

  late MockNodeDetailNotifier nodeDetail;

  setUp(() {
    initBetterActions();
    nodeDetail = MockNodeDetailNotifier();
    when(nodeDetail.build())
        .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
  });

  Future<void> pump(WidgetTester tester, Widget child,
      {required List<Override> overrides,
      AccessPolicy policy = AccessPolicy.full,
      LinksysRouteConfig? config}) async {
    // Tall enough that the node light card, below the details, is on screen.
    await tester.setScreenSize(device1440w.copyWith(height: 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      config: config,
      overrides: [
        ...overrides,
        accessPolicyProvider.overrideWithValue(policy),
      ],
      child: child,
    ));
    await tester.pumpAndSettle();
  }

  group('node detail', () {
    setUp(() {
      // The node light card shows only for a master cognitive mesh router
      // (nodeDetailsCherry7TestState is an LN16) that supports LED mode.
      when(serviceHelper.isSupportLedMode()).thenReturn(true);
    });

    /// NodeDetailView.initState drives deviceFilterConfigProvider.initFilter,
    /// which reads deviceManagerProvider and wifiListProvider. Same override
    /// set as node_detail_view_test.dart.
    List<Override> overrides() {
      final firmware = MockFirmwareUpdateNotifier();
      final filterConfig = MockDeviceFilterConfigNotifier();
      final deviceManager = MockDeviceManagerNotifier();
      final wifiList = MockWifiListNotifier();
      when(firmware.build()).thenReturn(FirmwareUpdateState.empty());
      when(filterConfig.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      when(deviceManager.build()).thenReturn(
          DeviceManagerState.fromMap(deviceManagerCherry7TestState));
      when(deviceManager.getBandConnectedBy(any)).thenReturn('2.4GHz');
      when(wifiList.build()).thenReturn(WiFiState.fromMap(wifiListTestState));
      return [
        nodeDetailProvider.overrideWith(() => nodeDetail),
        firmwareUpdateProvider.overrideWith(() => firmware),
        deviceManagerProvider.overrideWith(() => deviceManager),
        deviceFilterConfigProvider.overrideWith(() => filterConfig),
        wifiListProvider.overrideWith(() => wifiList),
        filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
            .map((e) => DeviceListItem.fromMap(e))
            .toList()),
      ];
    }

    Future<void> pumpDetail(WidgetTester tester,
            {AccessPolicy policy = AccessPolicy.full}) =>
        pump(tester, const NodeDetailView(),
            overrides: overrides(), policy: policy);

    Future<void> tapEdit(WidgetTester tester) async {
      await tester.tap(find.byIcon(LinksysIcons.edit), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    Future<void> tapNodeLight(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('nodeLightSettings')),
          warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    // #1637: renaming a node saves its new location to the router, so the edit
    // button is blocked before it opens the name dialog.
    testWidgets('the name edit does not open in read-only mode',
        (tester) async {
      await pumpDetail(tester, policy: _readOnly);

      await tapEdit(tester);

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('the name edit opens with full access', (tester) async {
      await pumpDetail(tester);

      await tapEdit(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.bySemanticsLabel('node name'), findsWidgets);
    });

    // #1637: the node light card opens the LED night mode dialog, whose save
    // writes the setting to the router. The card is blocked before it opens.
    testWidgets('node light does not open in read-only mode', (tester) async {
      await pumpDetail(tester, policy: _readOnly);
      expect(find.byKey(const ValueKey('nodeLightSettings')), findsOneWidget);

      await tapNodeLight(tester);

      expect(find.text('Night mode (8PM - 8AM)'), findsNothing);
    });

    testWidgets('node light opens with full access', (tester) async {
      await pumpDetail(tester);

      await tapNodeLight(tester);

      expect(find.text('Night mode (8PM - 8AM)'), findsOneWidget);
    });
  });

  // #1637: blinking sends startBlinkNodeLed to the router. The widget lives in
  // the name dialog, which read-only mode already keeps shut, so it is pumped
  // on its own here to check its own guard.
  group('blink node light', () {
    Future<void> pumpBlink(WidgetTester tester,
            {AccessPolicy policy = AccessPolicy.full}) =>
        pump(
          tester,
          // One second of blinking, so the countdown ends inside the test.
          const Scaffold(body: BlinkNodeLightWidget(max: 1)),
          overrides: [nodeDetailProvider.overrideWith(() => nodeDetail)],
          policy: policy,
        );

    Future<void> tapBlink(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('blinkNodeButton')),
          warnIfMissed: false);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    testWidgets('does not start in read-only mode', (tester) async {
      await pumpBlink(tester, policy: _readOnly);

      await tapBlink(tester);

      verifyNever(nodeDetail.toggleBlinkNode(false));
    });

    testWidgets('starts with full access', (tester) async {
      await pumpBlink(tester);

      await tapBlink(tester);

      verify(nodeDetail.toggleBlinkNode(false)).called(1);
    });
  });

  // #1637: both "Try again" on the results and "Next" on the intro start
  // auto onboarding, which turns on the router's Smart Connect pairing.
  group('add nodes', () {
    late MockAddNodesNotifier addNodes;

    Future<void> pumpAddNodes(WidgetTester tester, AddNodesState state,
        {AccessPolicy policy = AccessPolicy.full}) {
      addNodes = MockAddNodesNotifier();
      when(addNodes.build()).thenReturn(state);
      return pump(
        tester,
        const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        overrides: [addNodesProvider.overrideWith(() => addNodes)],
        policy: policy,
      );
    }

    const intro = AddNodesState();
    const noNodesFound = AddNodesState(onboardingProceed: true, addedNodes: []);

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.tap(find.text(text), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets('next is blocked in read-only mode', (tester) async {
      await pumpAddNodes(tester, intro, policy: _readOnly);

      await tapText(tester, 'Next');

      verifyNever(addNodes.startAutoOnboarding());
    });

    testWidgets('next starts onboarding with full access', (tester) async {
      await pumpAddNodes(tester, intro);

      await tapText(tester, 'Next');

      verify(addNodes.startAutoOnboarding()).called(1);
    });

    testWidgets('try again is blocked in read-only mode', (tester) async {
      await pumpAddNodes(tester, noNodesFound, policy: _readOnly);

      await tapText(tester, 'Try again');

      verifyNever(addNodes.startAutoOnboarding());
    });

    testWidgets('try again starts onboarding with full access', (tester) async {
      await pumpAddNodes(tester, noNodesFound);

      await tapText(tester, 'Try again');

      verify(addNodes.startAutoOnboarding()).called(1);
    });
  });
}
