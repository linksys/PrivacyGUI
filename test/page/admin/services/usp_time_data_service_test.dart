import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/admin/services/usp_time_data_service.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late MockUspService mockUsp;
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
    mockUsp = MockUspService();
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
}
