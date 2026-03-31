import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/device_detail_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared test data
  // ---------------------------------------------------------------------------

  const wifiDevice = DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    hostName: 'iPhone',
    isActive: true,
    isWifi: true,
    signalStrength: -55,
  );

  const ethernetDevice = DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    hostName: 'Desktop',
    isActive: true,
    isWifi: false,
  );

  const reservation = DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    enable: true,
  );

  const devicesData = DevicesData(
    deviceModels: [wifiDevice, ethernetDevice],
  );

  const dhcpData = DhcpData(
    clientModels: [],
    reservationModels: [reservation],
  );

  ProviderContainer createContainer({
    DevicesData? devices,
    DhcpData? dhcp,
  }) {
    return ProviderContainer(
      overrides: [
        devicesDataProvider.overrideWith(() => _FakeDevicesNotifier(devices)),
        dhcpDataProvider.overrideWith(() => _FakeDhcpNotifier(dhcp)),
      ],
    );
  }

  group('DeviceDetailProvider', () {
    // -----------------------------------------------------------------------
    // Basic lookup
    // -----------------------------------------------------------------------

    test('returns device and reservation by MAC', () async {
      final container = createContainer(
        devices: devicesData,
        dhcp: dhcpData,
      );
      await container.read(devicesDataProvider.future);
      await container.read(dhcpDataProvider.future);

      final detail =
          container.read(uspDeviceDetailProvider('AA:BB:CC:DD:EE:01'));

      expect(detail.device, wifiDevice);
      expect(detail.reservation, reservation);
      expect(detail.hasReservation, isTrue);
      container.dispose();
    });

    test('returns device without reservation when no match', () async {
      final container = createContainer(
        devices: devicesData,
        dhcp: dhcpData,
      );
      await container.read(devicesDataProvider.future);
      await container.read(dhcpDataProvider.future);

      final detail =
          container.read(uspDeviceDetailProvider('AA:BB:CC:DD:EE:02'));

      expect(detail.device, ethernetDevice);
      expect(detail.reservation, isNull);
      expect(detail.hasReservation, isFalse);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Case-insensitive matching
    // -----------------------------------------------------------------------

    test('MAC lookup is case-insensitive', () async {
      final container = createContainer(
        devices: devicesData,
        dhcp: dhcpData,
      );
      await container.read(devicesDataProvider.future);
      await container.read(dhcpDataProvider.future);

      final detail =
          container.read(uspDeviceDetailProvider('aa:bb:cc:dd:ee:01'));

      expect(detail.device, wifiDevice);
      expect(detail.reservation, reservation);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Edge cases
    // -----------------------------------------------------------------------

    test('returns empty state when devices data is null', () {
      final container = createContainer(devices: null, dhcp: null);

      final detail =
          container.read(uspDeviceDetailProvider('AA:BB:CC:DD:EE:01'));

      expect(detail.device, isNull);
      expect(detail.reservation, isNull);
      container.dispose();
    });

    test('returns null device for unknown MAC', () async {
      final container = createContainer(
        devices: devicesData,
        dhcp: dhcpData,
      );
      await container.read(devicesDataProvider.future);

      final detail =
          container.read(uspDeviceDetailProvider('FF:FF:FF:FF:FF:FF'));

      expect(detail.device, isNull);
      container.dispose();
    });

    test('returns device when DHCP data is unavailable', () async {
      final container = createContainer(
        devices: devicesData,
        dhcp: null,
      );
      await container.read(devicesDataProvider.future);

      final detail =
          container.read(uspDeviceDetailProvider('AA:BB:CC:DD:EE:01'));

      expect(detail.device, wifiDevice);
      expect(detail.reservation, isNull);
      container.dispose();
    });
  });
}

// ---------------------------------------------------------------------------
// Fake notifiers
// ---------------------------------------------------------------------------

class _FakeDevicesNotifier extends AsyncNotifier<DevicesData>
    implements DevicesDataNotifier {
  final DevicesData? _data;
  _FakeDevicesNotifier(this._data);

  @override
  Future<DevicesData> build() async => _data ?? const DevicesData();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDhcpNotifier extends AsyncNotifier<DhcpData>
    implements DhcpDataNotifier {
  final DhcpData? _data;
  _FakeDhcpNotifier(this._data);

  @override
  Future<DhcpData> build() async =>
      _data ?? const DhcpData(clientModels: [], reservationModels: []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
