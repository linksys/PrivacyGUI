
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/device_list_card.dart';

import '../../../../common/config.dart';
import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/dashboard_manager_notifier_mocks.dart';
import '../../../../mocks/device_manager_notifier_mocks.dart';
import '../../../../mocks/wifi_bundle_settings_notifier_mocks.dart';
import '../../../../test_data/_index.dart';
import '../../../../mocks/device_filter_config_notifier_mocks.dart';
import '../../../../test_data/wifi_bundle_test_state.dart';

void main() {
  late DeviceFilterConfigNotifier mockDeviceFilterConfigNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;
  late MockWifiBundleNotifier mockWifiBundleNotifier;
  late MockDashboardManagerNotifier mockDashboardManagerNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockDeviceFilterConfigNotifier = MockDeviceFilterConfigNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockWifiBundleNotifier = MockWifiBundleNotifier();
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();

    final settings = WifiBundleSettings.fromMap(wifiBundleTestState['settings'] as Map<String, dynamic>);
    final status = WifiBundleStatus.fromMap(wifiBundleTestState['status'] as Map<String, dynamic>);
    final wifiInitialState = WifiBundleState(
      settings: Preservable(original: settings, current: settings),
      status: status,
    );
    when(mockWifiBundleNotifier.build()).thenReturn(wifiInitialState);

    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    when(mockServiceHelper.isSupportClientDeauth()).thenReturn(true);
    when(mockDashboardManagerNotifier.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerChrry7TestState));

    when(mockDeviceManagerNotifier.getBandConnectedBy(any))
        .thenReturn('2.4GHz');
  });

  Widget testableWidget(Locale locale, {List<Override>? overrides}) {
    return testableSingleRoute(
      overrides: overrides ??
          [
            deviceFilterConfigProvider
                .overrideWith(() => mockDeviceFilterConfigNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            filteredDeviceListProvider.overrideWith((ref) =>
                deviceFilteredTestData
                    .map((e) => DeviceListItem.fromMap(e))
                    .toList()),
            wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
          ],
      locale: locale,
      child: const InstantDeviceView(),
    );
  }

  testLocalizations('Instant device view - default', (tester, locale) async {
    await tester.pumpWidget(testableWidget(locale));
  });

  testLocalizations('Instant device view - 1 device', (tester, locale) async {
    final widget = testableWidget(locale, overrides: [
      deviceFilterConfigProvider
          .overrideWith(() => mockDeviceFilterConfigNotifier),
      deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
      filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
          .map((e) => DeviceListItem.fromMap(e))
          .take(1)
          .toList()),
      wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
      dashboardManagerProvider.overrideWith(() => mockDashboardManagerNotifier),
    ]);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant device view - no device', (tester, locale) async {
    final widget = testableWidget(locale, overrides: [
      deviceFilterConfigProvider
          .overrideWith(() => mockDeviceFilterConfigNotifier),
      deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
      filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
          .map((e) => DeviceListItem.fromMap(e))
          .take(0)
          .toList()),
      wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
      dashboardManagerProvider.overrideWith(() => mockDashboardManagerNotifier),
    ]);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant device view - filter with unknown node',
      (tester, locale) async {
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState)
            .copyWith(showOrphanNodes: true));
    await tester.pumpWidget(testableWidget(locale));
  }, screens: responsiveDesktopScreens);

  testLocalizations('Instant device view - filter with unknown node',
      (tester, locale) async {
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState)
            .copyWith(showOrphanNodes: true));
    await tester.pumpWidget(testableWidget(locale));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LinksysIcons.filter));
    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant device view - offline devices',
      (tester, locale) async {
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState)
            .copyWith(connectionFilter: false));
    final widget = testableWidget(locale, overrides: [
      deviceFilterConfigProvider
          .overrideWith(() => mockDeviceFilterConfigNotifier),
      deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
      filteredDeviceListProvider.overrideWith((ref) =>
          deviceFilteredOfflineTestData
              .map((e) => DeviceListItem.fromMap(e))
              .toList()),
      wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
      dashboardManagerProvider.overrideWith(() => mockDashboardManagerNotifier),
    ]);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final deviceCheckboxFinder = find.descendant(
        of: find.byType(AppDeviceListCard), matching: find.byType(AppCheckbox));
    await tester.tap(deviceCheckboxFinder.first);
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'Instant device view - offline devices - delete confirm modal',
      (tester, locale) async {
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState)
            .copyWith(connectionFilter: false));
    final widget = testableWidget(locale, overrides: [
      deviceFilterConfigProvider
          .overrideWith(() => mockDeviceFilterConfigNotifier),
      deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
      filteredDeviceListProvider.overrideWith((ref) =>
          deviceFilteredOfflineTestData
              .map((e) => DeviceListItem.fromMap(e))
              .toList()),
      wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
      dashboardManagerProvider.overrideWith(() => mockDashboardManagerNotifier),
    ]);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final deviceCheckboxFinder = find.descendant(
        of: find.byType(AppDeviceListCard), matching: find.byType(AppCheckbox));
    await tester.tap(deviceCheckboxFinder.first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppFilledButton).last);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant device view - deauth confirm modal',
      (tester, locale) async {
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
    final widget = testableWidget(locale);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final deviceCheckboxFinder = find.descendant(
        of: find.byType(AppDeviceListCard),
        matching: find.byIcon(LinksysIcons.bidirectional));
    await tester.tap(deviceCheckboxFinder.first);
    await tester.pumpAndSettle();
  });
}
