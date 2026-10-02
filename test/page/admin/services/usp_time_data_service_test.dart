import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/admin/services/usp_time_data_service.dart';

import '../../../mocks/test_data/time_settings_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspTimeDataService svc;

  final timeResponse = <String, dynamic>{
    'Device.Time.Enable': true,
    'Device.Time.Status': 'Synchronized',
    'Device.Time.NTPServer1': 'pool.ntp.org',
    'Device.Time.NTPServer2': 'time.google.com',
    'Device.Time.LocalTimeZone': 'CST-8',
    'Device.Time.CurrentLocalTime': '2026-03-23T12:00:00',
  };

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspTimeDataService(mockUsp);
  });

  group('UspTimeDataService — fetch', () {
    test('maps all fields to TimeSettingsUIModel', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => timeResponse);

      final model = await svc.fetch();

      expect(model.enable, isTrue);
      expect(model.status, 'Synchronized');
      expect(model.ntpServer1, 'pool.ntp.org');
      expect(model.ntpServer2, 'time.google.com');
      expect(model.localTimeZone, 'CST-8');
      expect(model.currentLocalTime, '2026-03-23T12:00:00');
      expect(model.isSynchronized, isTrue);
    });

    test('isSynchronized is false when status differs', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                ...timeResponse,
                'Device.Time.Status': 'Unsynchronized',
              });

      final model = await svc.fetch();

      expect(model.isSynchronized, isFalse);
    });

    test('maps USP transport error to NetworkError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error: Request timeout');

      expect(() => svc.fetch(), throwsA(isA<NetworkError>()));
    });

    test('maps USP auth error to UnauthorizedError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Authentication error: Permission denied');

      expect(() => svc.fetch(), throwsA(isA<UnauthorizedError>()));
    });
  });

  // linksys/FWDEV#198. The device's own reading of the current zone.
  group('UspTimeDataService — the device zone ID', () {
    test('carries the zone ID and DST state onto the model', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                ...timeResponse,
                'Device.Time.X_LINKSYS_TimeZoneID': 'PST8',
                'Device.Time.X_LINKSYS_AutoAdjustForDST': '1',
              });

      final model = await svc.fetch();

      expect(model.timeZoneId, 'PST8');
      expect(model.autoAdjustForDst, isTrue);
    });

    test('a firmware without the leaves still loads, with neither set',
        () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => timeResponse);

      final model = await svc.fetch();

      expect(model.timeZoneId, isNull);
      expect(model.autoAdjustForDst, isNull);
      expect(model.status, 'Synchronized');
    });
  });

  // linksys/FWDEV#198. The zone list the dialog offers comes from the device.
  group('UspTimeDataService — fetchZones', () {
    test('returns the device catalogue, in device order', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => TimeSettingsTestData.catalogueResponse());

      final zones = await svc.fetchZones();

      expect(zones.map((z) => z.timeZoneID), ['PST8', 'JST-9-NO-DST']);
      expect(zones.first.utcOffsetMinutes, -480);
      expect(zones.first.observesDST, isTrue);
      expect(zones.last.observesDST, isFalse);
      expect(zones.last.description, '(GMT+09:00) Japan, Korea');
    });

    test('a firmware without the catalogue falls back to the built-in list',
        () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => <String, dynamic>{});

      final zones = await svc.fetchZones();

      expect(zones, hasLength(39));
      expect(zones.first.timeZoneID, 'MHT12-NO-DST');
    });

    test('a fault reading the catalogue falls back, it does not throw',
        () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error: Request timeout');

      final zones = await svc.fetchZones();

      expect(zones, hasLength(39));
    });
  });

  // #1609. `Device.Time.X_LINKSYS_LocalTimeZoneName` is read in its own `Get`
  // because `time_settings.yaml` does not declare it, so it is not on the
  // codegen model.
  group('UspTimeDataService — the zone name', () {
    const zonePath = 'Device.Time.X_LINKSYS_LocalTimeZoneName';

    test('is read and carried onto the model', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => timeResponse);
      when(() => mockUsp.get([zonePath], priority: any(named: 'priority')))
          .thenAnswer((_) async => {zonePath: 'Asia/Taipei'});

      final model = await svc.fetch();

      expect(model.localTimeZoneName, 'Asia/Taipei');
      expect(model.localTimeZone, 'CST-8',
          reason: 'the POSIX string is still carried — the name is additional');
    });

    test('is empty when the device does not carry the leaf', () async {
      // Nothing under that key: a firmware without it, which must still render.
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => timeResponse);

      final model = await svc.fetch();

      expect(model.localTimeZoneName, '');
    });

    test('a fault on the name does not fail the whole page', () async {
      // The name only ever improves the label — `resolveTimezone` falls back to
      // the POSIX string — so it must not be able to take the time card down.
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => timeResponse);
      when(() => mockUsp.get([zonePath], priority: any(named: 'priority')))
          .thenThrow('Get failed: Invalid path');

      final model = await svc.fetch();

      expect(model.localTimeZoneName, '');
      expect(model.status, 'Synchronized');
    });

    test('a non-string value is treated as absent', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => timeResponse);
      when(() => mockUsp.get([zonePath], priority: any(named: 'priority')))
          .thenAnswer((_) async => {zonePath: 0});

      final model = await svc.fetch();

      expect(model.localTimeZoneName, '');
    });
  });
}
