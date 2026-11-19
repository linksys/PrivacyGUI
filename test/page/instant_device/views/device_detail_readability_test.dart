import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import '../../../layout_gate/fully_shown.dart';
import '../../../mocks/_index.dart';
import '../../../test_data/device_details_test_state.dart';
import '../../../test_data/local_network_settings_state.dart';

// Constitution 3.4. A device's IPs, MAC and SSID are useless when cut. Each
// is as long as it gets (an SSID takes up to 32 characters), and the IP is
// reserved, so its row's button is "Release Reserved IP", the longer of its
// two labels in every locale.
const _ipv4 = '192.168.123.234';
const _ipv6 = 'fd00:abcd:1234:5678:9abc:def0:1234:5678';
const _mac = '8C:3B:AD:FE:EE:DD';
const _ssid = 'Linksys-Home-Network-5GHz-Guest1';

void main() {
  late MockExternalDeviceDetailNotifier mockExternalDeviceDetailNotifier;
  late MockLocalNetworkSettingsNotifier mockLocalNetworkSettingsNotifier;

  mockDependencyRegister();

  setUp(() {
    mockExternalDeviceDetailNotifier = MockExternalDeviceDetailNotifier();
    mockLocalNetworkSettingsNotifier = MockLocalNetworkSettingsNotifier();
    final state = ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);
    when(mockExternalDeviceDetailNotifier.build()).thenReturn(state.copyWith(
        item: state.item.copyWith(
      ipv4Address: _ipv4,
      ipv6Address: _ipv6,
      macAddress: _mac,
      ssid: _ssid,
    )));
    final settings =
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);
    when(mockLocalNetworkSettingsNotifier.build())
        .thenReturn(settings.copyWith(dhcpReservationList: [
      ...settings.dhcpReservationList,
      const DHCPReservation(
          macAddress: _mac, ipAddress: _ipv4, description: 'Laptop'),
    ]));
  });

  testFullyShown(
    'device detail',
    values: {
      'IPv4 address': find.text(_ipv4),
      'IPv6 address': find.text(_ipv6),
      'MAC address': find.text(_mac),
      'SSID': find.textContaining(_ssid),
    },
    pump: (tester, locale) => tester.pumpWidget(testableSingleRoute(
      locale: locale,
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      child: const DeviceDetailView(),
    )),
  );
}
