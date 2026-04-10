import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/page/admin/services/usp_admin_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspAdminService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspAdminService(mockUsp);
  });

  group('UspAdminService — fetchAdmin', () {
    test('returns admin user when found by username', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.Users.User.1.Username': 'guest',
            'Device.Users.User.1.Password': 'pass1',
            'Device.Users.User.1.Enable': true,
            'Device.Users.User.2.Username': 'admin',
            'Device.Users.User.2.Password': 'pass2',
            'Device.Users.User.2.Enable': true,
          });

      final result = await service.fetchAdmin();

      expect(result.username, 'admin');
      expect(result.instancePath, 'Device.Users.User.2.');
      expect(result.enable, isTrue);
    });

    test('falls back to first user when no admin user exists', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.Users.User.1.Username': 'operator',
            'Device.Users.User.1.Password': 'pass',
            'Device.Users.User.1.Enable': true,
          });

      final result = await service.fetchAdmin();

      expect(result.username, 'operator');
      expect(result.instancePath, 'Device.Users.User.1.');
    });
  });

  group('UspAdminService — updatePassword', () {
    test('calls AdminUsers.update with correct params', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {});

      await service.updatePassword(
        instancePath: 'Device.Users.User.2.',
        newPassword: 'newSecret123',
      );

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      expect(captured, hasLength(1));
      final params = captured.first as Map<String, dynamic>;
      expect(params['Device.Users.User.2.Password'], 'newSecret123');
    });
  });

  group('UspAdminService — buildTimeSettingsUIModel', () {
    test('maps all TimeSettings fields to UIModel', () {
      final ts = TimeSettings(
        enable: true,
        status: 'Synchronized',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: 'time.google.com',
        localTimeZone: 'CST-8',
        currentLocalTime: '2026-03-23T10:30:00Z',
      );

      final model = service.buildTimeSettingsUIModel(ts);

      expect(model.enable, isTrue);
      expect(model.status, 'Synchronized');
      expect(model.ntpServer1, 'pool.ntp.org');
      expect(model.ntpServer2, 'time.google.com');
      expect(model.localTimeZone, 'CST-8');
      expect(model.currentLocalTime, '2026-03-23T10:30:00Z');
      expect(model.isSynchronized, isTrue);
    });

    test('isSynchronized is false when status is not Synchronized', () {
      final ts = TimeSettings(
        enable: true,
        status: 'Unsynchronized',
        ntpServer1: '',
        ntpServer2: '',
        localTimeZone: '',
        currentLocalTime: '',
      );

      final model = service.buildTimeSettingsUIModel(ts);

      expect(model.isSynchronized, isFalse);
    });
  });
}
