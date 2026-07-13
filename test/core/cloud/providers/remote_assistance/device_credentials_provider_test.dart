import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/device_credentials_provider.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

// =============================================================================
// deviceCredentialsProvider — verifies the Hosts DeviceID (UUID) is used for
// Remote Assistance / Guardian API calls, NOT the master's MAC address.
// =============================================================================

void main() {
  const deviceInfo = NodeDeviceInfo(
    modelNumber: 'M60TB',
    firmwareVersion: '1.0.16',
    description: '',
    firmwareDate: '',
    manufacturer: 'Linksys',
    serialNumber: 'SN-12345',
    hardwareVersion: '1',
  );

  const masterMac = 'AA:BB:CC:DD:EE:FF';
  const hostsUuid = 'uuid-hosts-9876';

  DevicesData devicesDataWith({
    String? hostsDeviceId,
    String deviceId = masterMac,
  }) {
    return DevicesData(
      meshNetwork: MeshNetwork(
        master: MasterNode(
          deviceId: deviceId,
          model: 'M60TB',
          hostsDeviceId: hostsDeviceId,
        ),
      ),
    );
  }

  ProviderContainer createContainer({
    required DevicesData? devices,
    NodeDeviceInfo? session = deviceInfo,
  }) {
    return ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => _FakeSessionNotifier(session)),
        devicesDataProvider.overrideWith(() => _FakeDevicesNotifier(devices)),
      ],
    );
  }

  /// Ensures [devicesDataProvider] has resolved (its AsyncNotifier is async,
  /// so a synchronous read would otherwise see AsyncLoading → valueOrNull null).
  Future<void> settleDevices(ProviderContainer container) async {
    try {
      await container.read(devicesDataProvider.future);
    } catch (_) {
      // Unavailable case: build throws → AsyncError → valueOrNull null.
    }
  }

  group('deviceCredentialsProvider', () {
    test('uses Hosts DeviceID (UUID) as deviceUUID, not the MAC', () async {
      final container = createContainer(
        devices: devicesDataWith(hostsDeviceId: hostsUuid),
      );
      addTearDown(container.dispose);
      await settleDevices(container);

      final creds = container.read(deviceCredentialsProvider);

      expect(creds, isNotNull);
      expect(creds!.deviceUUID, hostsUuid);
      // MAC is still carried separately.
      expect(creds.macAddress, masterMac);
      expect(creds.serialNumber, 'SN-12345');
      // deviceUUID must NOT fall back to the MAC address (the regression).
      expect(creds.deviceUUID, isNot(masterMac));
    });

    test('returns null when master has no Hosts DeviceID', () async {
      final container = createContainer(
        devices: devicesDataWith(hostsDeviceId: null),
      );
      addTearDown(container.dispose);
      await settleDevices(container);

      expect(container.read(deviceCredentialsProvider), isNull);
    });

    test('returns null when Hosts DeviceID is empty', () async {
      final container = createContainer(
        devices: devicesDataWith(hostsDeviceId: ''),
      );
      addTearDown(container.dispose);
      await settleDevices(container);

      expect(container.read(deviceCredentialsProvider), isNull);
    });

    test('returns null when devices data is unavailable', () async {
      final container = createContainer(devices: null);
      addTearDown(container.dispose);
      await settleDevices(container);

      expect(container.read(deviceCredentialsProvider), isNull);
    });

    test('returns null when session deviceInfo is unavailable', () async {
      final container = createContainer(
        devices: devicesDataWith(hostsDeviceId: hostsUuid),
        session: null,
      );
      addTearDown(container.dispose);
      await settleDevices(container);

      expect(container.read(deviceCredentialsProvider), isNull);
    });
  });
}

// =============================================================================
// Fakes
// =============================================================================

class _FakeSessionNotifier extends Notifier<SessionState>
    implements SessionNotifier {
  final NodeDeviceInfo? _deviceInfo;
  _FakeSessionNotifier(this._deviceInfo);

  @override
  SessionState build() => SessionState(deviceInfo: _deviceInfo);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDevicesNotifier extends AsyncNotifier<DevicesData>
    implements DevicesDataNotifier {
  final DevicesData? _data;
  _FakeDevicesNotifier(this._data);

  @override
  Future<DevicesData> build() async {
    final data = _data;
    if (data == null) {
      // Simulate "not loaded" — valueOrNull resolves to null via AsyncError.
      throw StateError('no devices data');
    }
    return data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
