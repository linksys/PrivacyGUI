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

  // linksys/FWDEV#198. The zone and its daylight-savings setting are saved
  // together by one operate, and the firmware reports the outcome in the output
  // argument `Result` rather than as a fault.
  group('UspAdminService — updateTimezone', () {
    const command = 'Device.Time.X_LINKSYS_SetTimeSettings()';

    test('saves the zone and DST through SetTimeSettings', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => {'Result': 'OK'});

      await service.updateTimezone(
        zone: (id: 'PST8', autoAdjustForDst: true),
      );

      final captured = verify(() =>
              mockUsp.operate(captureAny(), args: captureAny(named: 'args')))
          .captured;
      expect(captured[0], command);
      expect(captured[1], {'TimeZoneID': 'PST8', 'AutoAdjustForDST': 'true'});
      verifyNever(() => mockUsp.set(any()));
    });

    test('an NTP-only change writes NTP and never calls SetTimeSettings',
        () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await service.updateTimezone(ntpServer1: 'time.cloudflare.com');

      final written = verify(() => mockUsp.set(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(written['Device.Time.NTPServer1'], 'time.cloudflare.com');
      verifyNever(() => mockUsp.operate(any(), args: any(named: 'args')));
    });

    test('a zone and NTP change writes both', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => {'Result': 'OK'});
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await service.updateTimezone(
        zone: (id: 'SGT-8-NO-DST', autoAdjustForDst: false),
        ntpServer1: 'time.cloudflare.com',
      );

      verify(() => mockUsp.operate('Device.Time.X_LINKSYS_SetTimeSettings()',
          args: {'TimeZoneID': 'SGT-8-NO-DST', 'AutoAdjustForDST': 'false'}));
      final written = verify(() => mockUsp.set(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(written['Device.Time.NTPServer1'], 'time.cloudflare.com');
    });

    test('a rejected zone writes no NTP server either', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => {'Result': 'ErrorUnknownTimeZone'});
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await expectLater(
        service.updateTimezone(
          zone: (id: 'NOPE', autoAdjustForDst: false),
          ntpServer1: 'time.cloudflare.com',
        ),
        throwsA(isA<InvalidInputError>()),
      );
      verifyNever(() => mockUsp.set(any()));
    });

    // The operate itself always succeeds; a rejected zone only shows in
    // `Result`, so a caller that checks nothing else records it as saved.
    for (final rejected in [
      'ErrorUnknownTimeZone',
      'ErrorTimeZoneDoesNotObserveDST',
      'ErrorInvalidInput',
    ]) {
      test('Result=$rejected is a failure, not a save', () async {
        when(() => mockUsp.operate(any(), args: any(named: 'args')))
            .thenAnswer((_) async => {'Result': rejected});

        await expectLater(
          service.updateTimezone(zone: (id: 'JST-9', autoAdjustForDst: false)),
          throwsA(isA<InvalidInputError>()
              .having((e) => e.detail, 'detail', contains(rejected))),
        );
      });
    }
  });

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
