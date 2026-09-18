import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/session/services/session_service.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

// =============================================================================
// Where the router's identity is read (#1582, corrected by #1592).
//
// Remote Assistance needs three values to reach Guardian: the serial number, the
// router's base MAC, and the **cloud's device UUID**. Two of them are
// `Device.DeviceInfo.*` leaves and so come back from `SystemInfo.fetch` for free:
//
//   Device.DeviceInfo.SerialNumber
//   Device.DeviceInfo.X_LINKSYS_BaseMACAddress   (since #1572 added it)
//
// Only the UUID needs its own Get, because `Device.LocalAgent.` is outside the
// `system_info` definition:
//
//   Device.LocalAgent.EndpointID          → `uuid::<UUID>`, prefix stripped
//
// Three properties this file exists to hold:
//
//  * **The UUID's prefix must come off and the value must stay upper case.**
//    Measured against Guardian on 2026-09-17: the token endpoint answers 403 for
//    the same UUID in lower case, and 403 for a wrong MAC. A value that looks
//    nearly right fails in a way that surfaces as "Remote Assistance does
//    nothing", which is the bug this ticket is fixing.
//  * **The read is best-effort and must never break login.** A firmware that
//    answers neither leaf still has to produce device info; Remote Assistance
//    then reports itself unavailable instead of the whole session failing.
//  * **The UUID read asks for exactly one path.** #1592: the base MAC joined the
//    `system_info` definition, appeared in *both* path lists, and every consumer
//    that told the two reads apart by their paths — this file's own stub included
//    — silently started answering the wrong one. Only discriminate on a path that
//    one read owns.
// =============================================================================

class _MockUspClient extends Mock implements UspClient {}

const _kBaseMac = 'Device.DeviceInfo.X_LINKSYS_BaseMACAddress';
const _kEndpointId = 'Device.LocalAgent.EndpointID';

/// [baseMac] omitted means the firmware does not serve the leaf — the key is
/// absent rather than empty, which is what `SystemInfo.fromResponse` keys off.
Map<String, dynamic> _systemInfoResponse({String? baseMac}) => {
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
      if (baseMac != null) _kBaseMac: baseMac,
    };

void main() {
  late _MockUspClient usp;
  late SessionService service;

  /// Every path list the mock was asked for, in call order, so a test can assert
  /// what was requested and not only what came back.
  late List<List<String>> requested;

  /// Stubs `get` by *what was asked for* rather than by call order, so the UUID
  /// read and the SystemInfo read cannot be confused if either moves.
  ///
  /// The discriminator is `_kEndpointId` **alone**, and that is the whole lesson of
  /// #1592: `_kBaseMac` used to be here too, and once #1572 added that leaf to the
  /// `system_info` definition it appeared in *both* path lists, so this stub sent
  /// `SystemInfo.fetch` the UUID response and every test in this file went red on a
  /// tree where nothing was actually broken. Only ever discriminate on a path that
  /// one read owns.
  void stubGet({
    String? baseMac,
    String? endpointId,
    Object? uuidReadThrows,
  }) {
    when(() => usp.get(any())).thenAnswer((invocation) async {
      final paths = invocation.positionalArguments.first as List<String>;
      requested.add(paths);
      if (paths.contains(_kEndpointId)) {
        if (uuidReadThrows != null) throw uuidReadThrows;
        return endpointId == null ? const {} : {_kEndpointId: endpointId};
      }
      return _systemInfoResponse(baseMac: baseMac);
    });
  }

  setUp(() {
    usp = _MockUspClient();
    requested = [];
    when(() => usp.isAuthenticated).thenReturn(true);
    service = SessionService(usp);
  });

  group('fetchDeviceInfoAndInitializeServices — router identity', () {
    test('reads the base MAC off SystemInfo and the UUID from its own leaf',
        () async {
      stubGet(
        baseMac: '74:12:13:21:55:02',
        endpointId: 'uuid::3E68DD2F-CF4F-4E47-A99B-741213215502',
      );

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.serialNumber, '67A10M24F00066');
      expect(info.baseMacAddress, '74:12:13:21:55:02');
      expect(info.deviceUuid, '3E68DD2F-CF4F-4E47-A99B-741213215502');
    });

    test('upper-cases both — Guardian answers 403 for a lower-case UUID',
        () async {
      stubGet(
        baseMac: '74:12:13:21:55:0a',
        endpointId: 'uuid::3e68dd2f-cf4f-4e47-a99b-741213215502',
      );

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.baseMacAddress, '74:12:13:21:55:0A');
      expect(info.deviceUuid, '3E68DD2F-CF4F-4E47-A99B-741213215502');
    });

    test('takes the EndpointID as-is when it carries no prefix', () async {
      stubGet(endpointId: '3E68DD2F-CF4F-4E47-A99B-741213215502');

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.deviceUuid, '3E68DD2F-CF4F-4E47-A99B-741213215502');
    });

    test('empty answers become null, not empty strings', () async {
      stubGet(baseMac: '', endpointId: 'uuid::');

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.baseMacAddress, isNull);
      expect(info.deviceUuid, isNull);
    });

    test('a firmware that serves neither leaf still logs in', () async {
      stubGet();

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.serialNumber, '67A10M24F00066');
      expect(info.baseMacAddress, isNull);
      expect(info.deviceUuid, isNull);
    });

    test('a throwing UUID read does not fail the login', () async {
      stubGet(
        baseMac: '74:12:13:21:55:02',
        uuidReadThrows: Exception('Path is invalid'),
      );

      final info = await service.fetchDeviceInfoAndInitializeServices();

      expect(info.serialNumber, '67A10M24F00066');
      expect(info.deviceUuid, isNull);
      // The MAC survives a failed UUID read: it rides the SystemInfo response, so
      // the two values no longer fail together.
      expect(info.baseMacAddress, '74:12:13:21:55:02');
    });

    // The regression #1592 was: `SystemInfo.fetch`'s path list grew the base-MAC
    // leaf, and everything that told the two reads apart by their paths broke. The
    // request shape is therefore an assertion, not an implementation detail.
    test('asks for exactly one path in the UUID read, and never the base MAC',
        () async {
      stubGet(
        baseMac: '74:12:13:21:55:02',
        endpointId: 'uuid::3E68DD2F-CF4F-4E47-A99B-741213215502',
      );

      await service.fetchDeviceInfoAndInitializeServices();

      final uuidReads =
          requested.where((paths) => paths.contains(_kEndpointId)).toList();
      expect(uuidReads, hasLength(1));
      expect(uuidReads.single, [_kEndpointId]);

      // And the base MAC is never asked for on its own — it only ever arrives as
      // part of the SystemInfo read, which is the point of the fix.
      expect(
        requested.where((paths) => paths.contains(_kBaseMac)),
        everyElement(contains('Device.DeviceInfo.SerialNumber')),
      );
    });
  });
}
