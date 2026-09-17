import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/session/services/session_service.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

// =============================================================================
// Where the router's identity is read (#1582).
//
// Remote Assistance needs three values to reach Guardian: the serial number, the
// router's base MAC, and the **cloud's device UUID**. Only the serial comes from
// the `system_info` codegen definition. The other two are read here, in one
// extra Get alongside `SystemInfo.fetch`:
//
//   Device.DeviceInfo.X_LINKSYS_BaseMACAddress
//   Device.LocalAgent.EndpointID          → `uuid::<UUID>`, prefix stripped
//
// Two properties this file exists to hold:
//
//  * **The UUID's prefix must come off and the value must stay upper case.**
//    Measured against Guardian on 2026-09-17: the token endpoint answers 403 for
//    the same UUID in lower case, and 403 for a wrong MAC. A value that looks
//    nearly right fails in a way that surfaces as "Remote Assistance does
//    nothing", which is the bug this ticket is fixing.
//  * **The read is best-effort and must never break login.** A firmware that
//    answers neither leaf still has to produce device info; Remote Assistance
//    then reports itself unavailable instead of the whole session failing.
// =============================================================================

class _MockUspClient extends Mock implements UspClient {}

const _kBaseMac = 'Device.DeviceInfo.X_LINKSYS_BaseMACAddress';
const _kEndpointId = 'Device.LocalAgent.EndpointID';

Map<String, dynamic> _systemInfoResponse() => {
      'Device.DeviceInfo.Manufacturer': 'Linksys',
      'Device.DeviceInfo.ModelName': 'M60TB',
      'Device.DeviceInfo.SerialNumber': '67A10M24F00066',
      'Device.DeviceInfo.HardwareVersion': '1',
      'Device.DeviceInfo.SoftwareVersion': '2.0.1',
      'Device.DeviceInfo.UpTime': '864000',
      'Device.DeviceInfo.MemoryStatus.Total': '1',
      'Device.DeviceInfo.MemoryStatus.Free': '1',
      'Device.DeviceInfo.ProcessStatus.CPUUsage': '1',
      'Device.DeviceInfo.ActiveFirmwareImage': 'fw1',
      'Device.DeviceInfo.BootFirmwareImage': 'fw1',
    };

void main() {
  late _MockUspClient usp;
  late SessionService service;

  /// Stubs `get` by *what was asked for* rather than by call order, so the
  /// identity read and the SystemInfo read cannot be confused if either moves.
  void stubGet({Map<String, dynamic>? identity, Object? identityThrows}) {
    when(() => usp.get(any())).thenAnswer((invocation) async {
      final paths = invocation.positionalArguments.first as List<String>;
      if (paths.contains(_kEndpointId) || paths.contains(_kBaseMac)) {
        if (identityThrows != null) throw identityThrows;
        return identity ?? const {};
      }
      return _systemInfoResponse();
    });
  }

  setUp(() {
    usp = _MockUspClient();
    when(() => usp.isAuthenticated).thenReturn(true);
    service = SessionService(usp);
  });

  group('fetchDeviceInfoAndInitializeServices — router identity', () {
    test('reads the base MAC and the UUID, stripping the uuid:: prefix',
        () async {
      stubGet(identity: {
        _kBaseMac: '74:12:13:21:55:02',
        _kEndpointId: 'uuid::3E68DD2F-CF4F-4E47-A99B-741213215502',
      });

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.serialNumber, '67A10M24F00066');
      expect(info.baseMacAddress, '74:12:13:21:55:02');
      expect(info.deviceUuid, '3E68DD2F-CF4F-4E47-A99B-741213215502');
    });

    test('upper-cases both — Guardian answers 403 for a lower-case UUID',
        () async {
      stubGet(identity: {
        _kBaseMac: '74:12:13:21:55:0a',
        _kEndpointId: 'uuid::3e68dd2f-cf4f-4e47-a99b-741213215502',
      });

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.baseMacAddress, '74:12:13:21:55:0A');
      expect(info.deviceUuid, '3E68DD2F-CF4F-4E47-A99B-741213215502');
    });

    test('takes the EndpointID as-is when it carries no prefix', () async {
      stubGet(identity: {
        _kEndpointId: '3E68DD2F-CF4F-4E47-A99B-741213215502',
      });

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.deviceUuid, '3E68DD2F-CF4F-4E47-A99B-741213215502');
    });

    test('empty answers become null, not empty strings', () async {
      stubGet(identity: {_kBaseMac: '', _kEndpointId: 'uuid::'});

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.baseMacAddress, isNull);
      expect(info.deviceUuid, isNull);
    });

    test('a firmware that answers neither leaf still logs in', () async {
      stubGet(identity: const {});

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.serialNumber, '67A10M24F00066');
      expect(info.baseMacAddress, isNull);
      expect(info.deviceUuid, isNull);
    });

    test('a throwing identity read does not fail the login', () async {
      stubGet(identityThrows: Exception('Path is invalid'));

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.serialNumber, '67A10M24F00066');
      expect(info.deviceUuid, isNull);
    });
  });
}
