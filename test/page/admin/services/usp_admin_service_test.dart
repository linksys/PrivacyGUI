import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
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
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await service.updatePassword(
        instancePath: 'Device.Users.User.2.',
        newPassword: 'newSecret123',
      );

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      expect(captured, hasLength(1));
      final params = captured.first as Map<String, dynamic>;
      expect(params['Device.Users.User.2.Password'], 'newSecret123');
    });

    test('throws UspCompleteFailureError on SET failure', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {
                'Device.Users.User.2.Password': {
                  'errorCode': 7004,
                  'errorMessage': 'Parameter not writable',
                },
              },
            },
          });

      expect(
        () => service.updatePassword(
          instancePath: 'Device.Users.User.2.',
          newPassword: 'newSecret123',
        ),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });
  });

  // buildTimeSettingsUIModel — moved to UspTimeDataService

  group('UspAdminService — error handling', () {
    test('fetchAdmin maps USP error to ServiceError', () {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Request timeout');

      expect(() => service.fetchAdmin(), throwsA(isA<NetworkError>()));
    });

    test('updatePassword maps USP error to ServiceError', () {
      when(() => mockUsp.set(any()))
          .thenThrow('Set failed: Authentication error: Permission denied');

      expect(
        () => service.updatePassword(
          instancePath: 'Device.Users.User.1.',
          newPassword: 'test',
        ),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('reboot maps USP error to ServiceError', () {
      when(() => mockUsp.operate(any()))
          .thenThrow('Operate failed: Transport error: Connection refused');

      expect(() => service.reboot(), throwsA(isA<ConnectivityError>()));
    });

    test('factoryReset maps USP error to ServiceError', () {
      when(() => mockUsp.operate(any()))
          .thenThrow('Operate failed: Authentication error: Session expired');

      expect(() => service.factoryReset(),
          throwsA(isA<SessionTokenExpiredError>()));
    });
  });
}
