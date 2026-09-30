// Baseline for the dashboard quick panel's switches in the default build.
//
// Both switches here save the moment they are flipped - there is no Save button
// behind them - so a read-only build has to disable them one by one. These tests
// pin that in the default build each switch is live and each still reaches its
// save, so that change cannot quietly disable them for a local user.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_device_list_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/node_light_settings_notifier_mocks.dart';
import '../../../mocks/polling_notifier_mocks.dart';
import '../../../test_data/_index.dart';

void main() {
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;
  late MockNodeLightSettingsNotifier mockNodeLightSettingsNotifier;
  late MockInstantTopologyNotifier mockTopologyNotifier;
  late MockPollingNotifier mockPollingNotifier;

  mockDependencyRegister();
  final ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    mockNodeLightSettingsNotifier = MockNodeLightSettingsNotifier();
    mockTopologyNotifier = MockInstantTopologyNotifier();
    mockPollingNotifier = MockPollingNotifier();
    initBetterActions();

    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockInstantPrivacyNotifier.save()).thenAnswer(
        (_) async => InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockNodeLightSettingsNotifier.build())
        .thenReturn(NodeLightSettings(isNightModeEnable: false));
    when(mockNodeLightSettingsNotifier.save())
        .thenAnswer((_) async => NodeLightSettings.night());
    // An LN16 master, which is a cognitive mesh router - the night mode switch
    // only appears for those.
    when(mockTopologyNotifier.build())
        .thenReturn(TopologyTestData().testTopology1SlaveState);
    when(mockPollingNotifier.build()).thenReturn(
        const CoreTransactionData(lastUpdate: 0, isReady: true, data: {}));
    when(mockServiceHelper.isSupportLedMode()).thenReturn(true);
  });

  tearDown(() => reset(mockServiceHelper));

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(testableSingleRoute(
      overrides: [
        instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
        nodeLightSettingsProvider
            .overrideWith(() => mockNodeLightSettingsNotifier),
        instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        pollingProvider.overrideWith(() => mockPollingNotifier),
        instantPrivacyDeviceListProvider.overrideWith((ref) => []),
      ],
      child: const DashboardQuickPanel(),
    ));
    await tester.pumpAndSettle();
  }

  List<AppSwitch> switches(WidgetTester tester) => tester
      .widgetList<AppSwitch>(find.descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(AppSwitch)))
      .toList();

  testResponsiveWidgets('both switches are live', (tester) async {
    await pump(tester);

    final all = switches(tester);
    expect(all, hasLength(2));
    expect(all.every((s) => s.onChanged != null), isTrue);
  }, variants: responsiveDesktopVariants);

  testResponsiveWidgets('instant privacy asks first, then saves',
      (tester) async {
    await pump(tester);

    switches(tester)[0].onChanged!(true);
    await tester.pumpAndSettle();
    verifyNever(mockInstantPrivacyNotifier.save());

    await tester.tap(find.text('Turn On'));
    await tester.pumpAndSettle();
    verify(mockInstantPrivacyNotifier.setEnable(true)).called(1);
    verify(mockInstantPrivacyNotifier.save()).called(1);
  }, variants: responsiveDesktopVariants);

  testResponsiveWidgets('cancelling instant privacy saves nothing',
      (tester) async {
    await pump(tester);

    switches(tester)[0].onChanged!(true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(mockInstantPrivacyNotifier.save());
  }, variants: responsiveDesktopVariants);

  testResponsiveWidgets('night mode saves as soon as it is flipped',
      (tester) async {
    await pump(tester);

    switches(tester)[1].onChanged!(true);
    await tester.pumpAndSettle();
    verify(mockNodeLightSettingsNotifier.setSettings(any)).called(1);
    verify(mockNodeLightSettingsNotifier.save()).called(1);
  }, variants: responsiveDesktopVariants);

  testResponsiveWidgets('night mode is not offered without LED mode support',
      (tester) async {
    when(mockServiceHelper.isSupportLedMode()).thenReturn(false);
    await pump(tester);

    expect(switches(tester), hasLength(1));
  }, variants: responsiveDesktopVariants);
}
