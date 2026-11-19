import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import '../../../layout_gate/fully_shown.dart';
import '../../../mocks/_index.dart';
import '../../../test_data/device_filter_config_test_state.dart';
import '../../../test_data/device_filtered_list_test_data.dart';
import '../../../test_data/device_manager_test_state.dart';
import '../../../test_data/node_details_data.dart';
import '../../../test_data/wifi_list_test_state.dart';

// Constitution 3.4. A node's IPs, MAC, serial number and firmware version
// are useless when cut. Each is as long as it gets.
const _wanIp = '203.120.234.255';
const _lanIp = '192.168.123.234';
const _firmware = '1.1.19.215371';
const _serial = '58U10M2AB12345';
const _mac = '8C:3B:AD:FE:EE:DD';

void main() {
  late MockNodeDetailNotifier mockNodeDetailNotifier;
  late MockFirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late MockDeviceFilterConfigNotifier mockDeviceFilterConfigNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;
  late MockWifiListNotifier mockWifiListNotifier;

  mockDependencyRegister();

  setUp(() {
    mockNodeDetailNotifier = MockNodeDetailNotifier();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    mockDeviceFilterConfigNotifier = MockDeviceFilterConfigNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockWifiListNotifier = MockWifiListNotifier();
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    when(mockWifiListNotifier.build())
        .thenReturn(WiFiState.fromMap(wifiListTestState));
    when(mockDeviceManagerNotifier.getBandConnectedBy(any))
        .thenReturn('2.4GHz');
    when(mockNodeDetailNotifier.build()).thenReturn(
        NodeDetailState.fromMap(nodeDetailsCherry7TestState).copyWith(
      wanIpAddress: _wanIp,
      lanIpAddress: _lanIp,
      firmwareVersion: _firmware,
      serialNumber: _serial,
      macAddress: _mac,
    ));
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
  });

  testFullyShown(
    'node detail',
    values: {
      'WAN IP address': find.text(_wanIp),
      'LAN IP address': find.text(_lanIp),
      'firmware version': find.text(_firmware),
      'serial number': find.text(_serial),
      'MAC address': find.text(_mac),
    },
    pump: (tester, locale) => tester.pumpWidget(testableSingleRoute(
      locale: locale,
      overrides: [
        nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        deviceFilterConfigProvider
            .overrideWith(() => mockDeviceFilterConfigNotifier),
        wifiListProvider.overrideWith(() => mockWifiListNotifier),
        filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
            .map((e) => DeviceListItem.fromMap(e))
            .toList()),
      ],
      child: const NodeDetailView(),
    )),
  );
}
