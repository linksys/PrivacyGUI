import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/generated/system_info.g.dart';

// =============================================================================
// The two identity fields #1582 adds to NodeDeviceInfo: the router's base MAC
// and the cloud's device UUID.
//
// Both are values Remote Assistance sends to Guardian, and **neither is in the
// `system_info` codegen definition** — that definition covers `Device.DeviceInfo.*`
// only, and the UUID lives under `Device.LocalAgent.`. They are read separately;
// see `session_service_test.dart`. This file pins the model half: the fields
// exist, survive copyWith, and are part of equality (an Equatable `props` that
// omits them would make a session with a UUID compare equal to one without).
// =============================================================================

void main() {
  const systemInfo = SystemInfo(
    manufacturer: 'Linksys',
    modelName: 'M60TB',
    serialNumber: '67A10M24F00066',
    hardwareVersion: '1',
    softwareVersion: '2.0.1',
    uptime: 864000,
    totalMemory: 1,
    freeMemory: 1,
    cpuUsage: 1,
    activeFirmwareImage: 'fw1',
    bootFirmwareImage: 'fw1',
  );

  const mac = '74:12:13:21:55:02';
  const uuid = '3E68DD2F-CF4F-4E47-A99B-741213215502';

  group('NodeDeviceInfo identity fields', () {
    test('fromUsp leaves both null — SystemInfo does not carry them', () {
      final info = NodeDeviceInfo.fromUsp(systemInfo);

      expect(info.serialNumber, '67A10M24F00066');
      expect(info.baseMacAddress, isNull);
      expect(info.deviceUuid, isNull);
    });

    test('copyWith carries both', () {
      final info = NodeDeviceInfo.fromUsp(systemInfo)
          .copyWith(baseMacAddress: mac, deviceUuid: uuid);

      expect(info.baseMacAddress, mac);
      expect(info.deviceUuid, uuid);
    });

    test('both are part of equality', () {
      final without = NodeDeviceInfo.fromUsp(systemInfo);

      expect(without.copyWith(baseMacAddress: mac), isNot(without));
      expect(without.copyWith(deviceUuid: uuid), isNot(without));
    });

    test('toJson carries both', () {
      final json = NodeDeviceInfo.fromUsp(systemInfo)
          .copyWith(baseMacAddress: mac, deviceUuid: uuid)
          .toJson();

      expect(json['baseMacAddress'], mac);
      expect(json['deviceUuid'], uuid);
    });
  });
}
