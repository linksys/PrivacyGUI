import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/devices/_devices.dart';
import 'package:privacy_gui/page/devices/providers/device_filtered_list_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../test_data/dashboard_manager_test_state.dart';
import '../../../../test_data/device_filter_config_test_state.dart';
import '../../../../test_data/device_filtered_list_test_data.dart';
import '../../../../test_data/device_manager_test_state.dart';
import '../../../dashboard/dashboard_home_view_test_mocks.dart';
import '../../../login/localizations/login_local_view_test_mocks.dart';
import '../../devices_view_test_mocks.dart';

@GenerateNiceMocks([
  MockSpec<DeviceFilterConfigNotifier>(),
])
void main() {
  late DeviceFilterConfigNotifier mockDeviceFilterConfigNotifier;
  late DeviceManagerNotifier mockDeviceManagerNotifier;
  late DashboardManagerNotifier mockDashboardManagerNotifier;

  setUp(() {
    mockDeviceFilterConfigNotifier = MockDeviceFilterConfigNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerTestData));
    when(mockDashboardManagerNotifier.build())
        .thenReturn(DashboardManagerState.fromMap(dashboardManagerTestState));
  });

  testLocalizations('Devices view', (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        deviceFilterConfigProvider
            .overrideWith(() => mockDeviceFilterConfigNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        dashboardManagerProvider
            .overrideWith(() => mockDashboardManagerNotifier),
        filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
            .map((e) => DeviceListItem.fromMap(e))
            .toList())
      ],
      locale: locale,
      child: const DashboardDevices(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('Devices view - offline devices', (tester, locale) async {
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState)
            .copyWith(connectionFilter: false));
    final widget = testableSingleRoute(
      overrides: [
        deviceFilterConfigProvider
            .overrideWith(() => mockDeviceFilterConfigNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        dashboardManagerProvider
            .overrideWith(() => mockDashboardManagerNotifier),
        filteredDeviceListProvider.overrideWith((ref) =>
            deviceFilteredOfflineTestData
                .map((e) => DeviceListItem.fromMap(e))
                .toList())
      ],
      locale: locale,
      child: const DashboardDevices(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('Devices view - offline devices edit mode',
      (tester, locale) async {
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState)
            .copyWith(connectionFilter: false));
    final widget = testableSingleRoute(
      overrides: [
        deviceFilterConfigProvider
            .overrideWith(() => mockDeviceFilterConfigNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        dashboardManagerProvider
            .overrideWith(() => mockDashboardManagerNotifier),
        filteredDeviceListProvider.overrideWith((ref) =>
            deviceFilteredOfflineTestData
                .map((e) => DeviceListItem.fromMap(e))
                .toList())
      ],
      locale: locale,
      child: const DashboardDevices(),
    );
    await tester.pumpWidget(widget);
    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
  });
}
