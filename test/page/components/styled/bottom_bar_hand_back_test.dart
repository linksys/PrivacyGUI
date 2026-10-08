import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_rule_view.dart';
import 'package:privacy_gui/page/components/settings_view/editable_card_list_edit_view.dart';
import 'package:privacy_gui/page/components/widgets/write_guard.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/views/select_device_view.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/static_routing_rule_notifier_mocks.dart';
import '../../../test_data/_index.dart';

const _readOnly = AccessPolicy(canWrite: false);

/// The bottom bar's positive button, found by the identifier the shared page
/// view stamps on it rather than by its label, which differs per page.
final _positive = find.byWidgetPredicate((w) =>
    (w is AppFilledButton || w is AppFilledButtonWithLoading) &&
    (w as dynamic).identifier == 'now-page-bottom-button-positive');

// #1637: a bar that writes is guarded in read-only mode. These bars only hand a
// value back to the page that opened them - a rule editor, a picker - and that
// page's own Save is the write. Guarding them would leave a read-only user no
// way to open and close an editor without the app calling it a refusal.
void main() {
  mockDependencyRegister();

  Future<void> pumpReadOnly(WidgetTester tester, Widget page,
      {List<Override> overrides = const [], bool settle = true}) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        accessPolicyProvider.overrideWithValue(_readOnly),
        ...overrides,
      ],
      child: page,
    ));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  void expectUnguarded() {
    expect(_positive, findsOneWidget, reason: 'precondition: the bar is up');
    expect(find.ancestor(of: _positive, matching: find.byType(WriteGuard)),
        findsNothing);
    expect(find.byTooltip('This feature is unavailable in remote mode'),
        findsNothing);
  }

  group('a rule editor', () {
    testWidgets('single port forwarding', (tester) async {
      final list = MockSinglePortForwardingListNotifier();
      when(list.build()).thenReturn(SinglePortForwardingListState.fromMap(
          singlePortForwardingEmptyListTestState));
      await pumpReadOnly(tester, const SinglePortForwardingRuleView(),
          overrides: [
            singlePortForwardingListProvider.overrideWith(() => list),
          ]);
      expectUnguarded();
    });

    testWidgets('port range forwarding', (tester) async {
      final list = MockPortRangeForwardingListNotifier();
      when(list.build()).thenReturn(PortRangeForwardingListState.fromMap(
          portRangeForwardingEmptyListTestState));
      await pumpReadOnly(tester, const PortRangeForwardingRuleView(),
          overrides: [
            portRangeForwardingListProvider.overrideWith(() => list),
          ]);
      expectUnguarded();
    });

    testWidgets('port range triggering', (tester) async {
      final list = MockPortRangeTriggeringListNotifier();
      when(list.build()).thenReturn(PortRangeTriggeringListState.fromMap(
          portRangeTriggerEmptyListTestState));
      await pumpReadOnly(tester, const PortRangeTriggeringRuleView(),
          overrides: [
            portRangeTriggeringListProvider.overrideWith(() => list),
          ]);
      expectUnguarded();
    });

    testWidgets('IPv6 port service', (tester) async {
      final rule = MockIpv6PortServiceRuleNotifier();
      when(rule.build()).thenReturn(const Ipv6PortServiceRuleState());
      when(rule.isRuleValid()).thenReturn(true);
      await pumpReadOnly(
          tester,
          Ipv6PortServiceRuleView(args: {
            'items':
                Ipv6PortServiceListState.fromMap(ipv6PortServiceListTestState)
                    .rules
          }),
          overrides: [
            ipv6PortServiceRuleProvider.overrideWith(() => rule),
          ]);
      expectUnguarded();
    });

    testWidgets('static routing', (tester) async {
      final routing = MockStaticRoutingNotifier();
      final state = StaticRoutingState.fromMap(staticRoutingState1);
      when(routing.build()).thenReturn(state);
      final rule = MockStaticRoutingRuleNotifier();
      when(rule.build()).thenReturn(const StaticRoutingRuleState(
          routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
      await pumpReadOnly(
          tester, StaticRoutingRuleView(args: {'items': state.setting.entries}),
          overrides: [
            staticRoutingProvider.overrideWith(() => routing),
            staticRoutingRuleProvider.overrideWith(() => rule),
          ]);
      expectUnguarded();
    });
  });

  group('a DHCP reservation editor', () {
    for (final viewType in ['add', 'edit']) {
      testWidgets(viewType, (tester) async {
        await pumpReadOnly(
            tester,
            DHCPReservationsEditView(args: {
              'viewType': viewType,
              'routerIp': '192.168.1.1',
              'subnetMask': '255.255.255.0',
            }));
        expectUnguarded();
      });
    }
  });

  testWidgets('an editable card list editor', (tester) async {
    await pumpReadOnly(
        tester,
        EditableCardListEditView(args: {
          'title': 'Edit',
          'data': 'value',
          'builder': (BuildContext context, dynamic data) => Text('$data'),
          'validator': (dynamic data) => true,
        }));
    expectUnguarded();
  });

  group('the MAC filtered device list', () {
    late MockInstantPrivacyNotifier privacy;
    late MockDeviceListNotifier deviceList;

    setUp(() {
      privacy = MockInstantPrivacyNotifier();
      when(privacy.build())
          .thenReturn(InstantPrivacyState.fromMap(instantPrivacyDenyTestState));
      deviceList = MockDeviceListNotifier();
      when(deviceList.build())
          .thenReturn(DeviceListState.fromMap(deviceListTestState));
    });

    List<Override> overrides() => [
          instantPrivacyProvider.overrideWith(() => privacy),
          deviceListProvider.overrideWith(() => deviceList),
        ];

    testWidgets('Done', (tester) async {
      await pumpReadOnly(tester, const FilteredDevicesView(),
          overrides: overrides());
      expectUnguarded();
    });

    // Remove only edits the list on the page; the page's caller saves it.
    testWidgets('Remove, while editing', (tester) async {
      await pumpReadOnly(tester, const FilteredDevicesView(),
          overrides: overrides());
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Remove'), findsOneWidget,
          reason: 'precondition: the editing bar is up');
      expectUnguarded();
    });
  });

  testWidgets('a device picker', (tester) async {
    final privacy = MockInstantPrivacyNotifier();
    when(privacy.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyDenyTestState));
    final deviceList = MockDeviceListNotifier();
    when(deviceList.build())
        .thenReturn(DeviceListState.fromMap(deviceListTestState));
    await pumpReadOnly(
        tester,
        SelectDeviceView(args: {
          'type': 'mac',
          'selected': InstantPrivacyState.fromMap(instantPrivacyDenyTestState)
              .settings
              .denyMacAddresses,
        }),
        overrides: [
          instantPrivacyProvider.overrideWith(() => privacy),
          deviceListProvider.overrideWith(() => deviceList),
        ]);
    expectUnguarded();
  });

  // Test again only resets the finished result to start screen; running a
  // test is its own guarded step.
  testWidgets('a finished speed test', (tester) async {
    final healthCheck = MockHealthCheckProvider();
    when(healthCheck.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckStateSuccessUltra));
    // The result page animates for good, so it never settles.
    await pumpReadOnly(tester, const SpeedTestView(),
        settle: false,
        overrides: [
          healthCheckProvider.overrideWith(() => healthCheck),
        ]);
    expectUnguarded();

    await tester.tap(_positive);
    await tester.pump();
    verify(healthCheck.resetState()).called(1);
  });
}
