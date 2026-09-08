import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:mockito/mockito.dart';

import '../../../common/_index.dart';
import '../../../common/di.dart';
import '../../../mocks/device_filter_config_notifier_mocks.dart';
import '../../../mocks/device_manager_notifier_mocks.dart';
import '../../../mocks/firmware_update_notifier_mocks.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../mocks/wifi_list_notifier_mocks.dart';
import '../../../test_data/device_filter_config_test_state.dart';
import '../../../test_data/device_filtered_list_test_data.dart';
import '../../../test_data/device_manager_test_state.dart';
import '../../../test_data/node_details_data.dart';
import '../../../test_data/wifi_list_test_state.dart';
import '../../../mocks/node_detail_notifier_mocks.dart';

void main() {
  late NodeDetailNotifier mockNodeDetailNotifier;
  late FirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late DeviceFilterConfigNotifier mockDeviceFilterConfigNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;
  late WifiListNotifier mockWifiListNotifier;
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockNodeDetailNotifier = MockNodeDetailNotifier();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    mockDeviceFilterConfigNotifier = MockDeviceFilterConfigNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockWifiListNotifier = MockWifiListNotifier();
    // when(mockNodeDetailNotifier.isSupportLedBlinking()).thenReturn(true);
    // when(mockNodeDetailNotifier.isSupportLedMode()).thenReturn(true);
    initBetterActions();
  });

  /// NodeDetailView.initState drives deviceFilterConfigProvider.initFilter,
  /// which reads deviceManagerProvider and wifiListProvider. Without these the
  /// real WifiListNotifier builds from an empty dashboardManagerProvider and
  /// dies on `wifiItems.first`, taking the whole test down before any
  /// assertion runs. Same override set as the localizations sibling test.
  List<Override> nodeDetailOverrides() => [
        nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        deviceFilterConfigProvider
            .overrideWith(() => mockDeviceFilterConfigNotifier),
        wifiListProvider.overrideWith(() => mockWifiListNotifier),
        filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
            .map((e) => DeviceListItem.fromMap(e))
            .toList()),
      ];

  void stubNodeDetailState() {
    when(mockNodeDetailNotifier.build())
        .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    when(mockWifiListNotifier.build())
        .thenReturn(WiFiState.fromMap(wifiListTestState));
    when(mockDeviceManagerNotifier.getBandConnectedBy(any))
        .thenReturn('2.4GHz');
  }

  testResponsiveWidgets('Test node details view with mobile layout',
      (tester) async {
    stubNodeDetailState();
    final widget = testableSingleRoute(
        themeMode: ThemeMode.dark,
        overrides: nodeDetailOverrides(),
        child: const NodeDetailView());
    await tester.pumpWidget(widget);

    final nameFinder = find.text('Router123');
    expect(nameFinder, findsNWidgets(2));
  }, variants: responsiveMobileVariants);
  testResponsiveWidgets('Test node details view with desktop layout',
      (tester) async {
    stubNodeDetailState();
    final widget = testableSingleRoute(
        themeMode: ThemeMode.dark,
        overrides: nodeDetailOverrides(),
        child: const NodeDetailView());
    await tester.pumpWidget(widget);

    BuildContext context = tester.element(find.byType(NodeDetailView));
    final nameFinder = find.text('Router123');
    expect(nameFinder, findsNWidgets(2));

    // fakeNodeDetailsState1 is an MBE70, whose icon class routerMbe7000 is
    // folded into routerMx6200 by _iconMapping. getRouterImage defaults to
    // xl = true, so the view resolves the devices_xl asset, not devices.
    final routerImageFinder =
        find.image(CustomTheme.of(context).images.devices_xl.routerMx6200);
    expect(routerImageFinder, findsOneWidget);
  }, variants: responsiveDesktopVariants);
}
