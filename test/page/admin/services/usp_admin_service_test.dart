import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/admin/models/network_action_models.dart';
import 'package:privacy_gui/page/admin/services/usp_admin_service.dart';

import '../../../mocks/test_data/usp_envelope_test_data.dart';

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

  // usp-codegen 0.18 returns every Users.User row, including one with every
  // value blank, which 0.17 dropped (#1654).
  group('UspAdminService — fetchAdmin with a blank user row', () {
    test('the fallback skips a blank row in front of the real user', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.Users.User.3.Username': '',
            'Device.Users.User.3.Password': '',
            'Device.Users.User.3.Enable': false,
            'Device.Users.User.5.Username': 'operator',
            'Device.Users.User.5.Password': 'pass',
            'Device.Users.User.5.Enable': true,
          });

      final result = await service.fetchAdmin();

      expect(result.instancePath, 'Device.Users.User.5.',
          reason: 'a password change must never land on the blank row');
    });

    test('a table of only blank rows has no user, as before', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.Users.User.3.Username': '',
            'Device.Users.User.3.Password': '',
            'Device.Users.User.3.Enable': false,
          });

      await expectLater(service.fetchAdmin(), throwsA(isA<ServiceError>()));
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
      when(() => mockUsp.set(any()))
          .thenAnswer((_) async => UspEnvelopeTestData.parameterErrors(
                {
                  'Device.Users.User.2.Password': (
                    code: 7004,
                    message: 'Parameter not writable',
                  ),
                },
                success: false,
              ));

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
      when(() => mockUsp.get(any(), fresh: any(named: 'fresh')))
          .thenAnswer((_) async => {});
      when(() => mockUsp.operate(any()))
          .thenThrow('Operate failed: Transport error: Connection refused');

      expect(() => service.reboot(), throwsA(isA<ConnectivityError>()));
    });

    test('factoryReset maps USP error to ServiceError', () {
      when(() => mockUsp.get(any(), fresh: any(named: 'fresh')))
          .thenAnswer((_) async => {});
      when(() => mockUsp.operate(any()))
          .thenThrow('Operate failed: Authentication error: Session expired');

      expect(() => service.factoryReset(),
          throwsA(isA<SessionTokenExpiredError>()));
    });
  });

  // #1777 (Architecture#195). Which command goes out is read from the router
  // right before the call: the network status leaf exists exactly where the
  // whole-network commands do.
  group('reboot and factoryReset — which command', () {
    const statusPath =
        'Device.WiFi.DataElements.Network.X_LINKSYS_NetworkActionStatus';
    const rebootAll = 'Device.WiFi.DataElements.Network.X_LINKSYS_RebootAll()';
    const factoryResetAll =
        'Device.WiFi.DataElements.Network.X_LINKSYS_FactoryResetAll()';

    void routerAnswers(Map<String, dynamic> status) =>
        when(() => mockUsp.get(any(), fresh: any(named: 'fresh')))
            .thenAnswer((_) async => status);

    void operateAnswers(Map<String, dynamic> output) =>
        when(() => mockUsp.operate(any())).thenAnswer((_) async => output);

    test('without the status leaf, reboot sends Device.Reboot()', () async {
      routerAnswers({});
      operateAnswers({});

      expect(await service.reboot(), RouterRestartStart.router);

      verify(() => mockUsp.operate('Device.Reboot()')).called(1);
      verifyNever(() => mockUsp.operate(rebootAll));
    });

    test('without the status leaf, factoryReset sends Device.FactoryReset()',
        () async {
      routerAnswers({});
      operateAnswers({});

      expect(await service.factoryReset(), RouterRestartStart.router);

      verify(() => mockUsp.operate('Device.FactoryReset()')).called(1);
      verifyNever(() => mockUsp.operate(factoryResetAll));
    });

    // The leaf reads "" until a whole-network action runs, which is what a
    // router reads at almost any moment someone presses Reboot. Presence is the
    // test; a non-empty rule would send Device.Reboot() and restart only the
    // controller.
    test('with the status leaf reading "", reboot sends RebootAll', () async {
      routerAnswers({statusPath: ''});
      operateAnswers({'Status': 'Started'});

      expect(await service.reboot(), RouterRestartStart.network);

      verify(() => mockUsp.operate(rebootAll)).called(1);
      verifyNever(() => mockUsp.operate('Device.Reboot()'));
    });

    test('with the status leaf, factoryReset sends FactoryResetAll', () async {
      routerAnswers({statusPath: ''});
      operateAnswers({'Status': 'Started'});

      expect(await service.factoryReset(), RouterRestartStart.network);

      verify(() => mockUsp.operate(factoryResetAll)).called(1);
      verifyNever(() => mockUsp.operate('Device.FactoryReset()'));
    });

    test('reads the status leaf fresh, past the cache', () async {
      routerAnswers({});
      operateAnswers({});

      await service.reboot();

      verify(() => mockUsp.get([statusPath], fresh: true)).called(1);
    });

    test('a failed status read sends nothing', () async {
      when(() => mockUsp.get(any(), fresh: any(named: 'fresh')))
          .thenThrow('Get failed: Transport error: Request timeout');

      await expectLater(service.reboot(), throwsA(isA<NetworkError>()));

      verifyNever(() => mockUsp.operate(any()));
    });

    test('a status reading Running sends nothing: one is already running',
        () async {
      routerAnswers({statusPath: 'Running'});

      expect(await service.factoryReset(), RouterRestartStart.alreadyRunning);

      verifyNever(() => mockUsp.operate(any()));
    });

    // Another client can start one between the read and the call.
    test('a 7002 refusal is a whole-network action already running', () async {
      routerAnswers({statusPath: ''});
      when(() => mockUsp.operate(any())).thenThrow('Operate failed: '
          'Operation error: $rebootAll refused: Busy (code: 7002)');

      expect(await service.reboot(), RouterRestartStart.alreadyRunning);
    });

    test('a Busy status is a whole-network action already running', () async {
      routerAnswers({statusPath: 'Completed'});
      operateAnswers({'Status': 'Busy'});

      expect(await service.factoryReset(), RouterRestartStart.alreadyRunning);
    });

    test('a reply with no Status is taken as started', () async {
      routerAnswers({statusPath: ''});
      operateAnswers({'commandKey': 'k1'});

      expect(await service.reboot(), RouterRestartStart.network);
    });

    // Waiting on a reply that is not a start would only time out after the
    // whole limit, with the user watching a spinner.
    for (final reply in ['Failed', 'Error_Other']) {
      test('a $reply Status throws when the leaf does not read Running',
          () async {
        routerAnswers({statusPath: ''});
        operateAnswers({'Status': reply});

        await expectLater(
            service.reboot(), throwsA(isA<UspCompleteFailureError>()));
      });
    }

    // An agent answering in its own words may have started anyway; calling
    // that a failure would leave the network restarting outside recovery.
    test('an unknown Status with the leaf now Running is a start', () async {
      final reads = [
        {statusPath: ''},
        {statusPath: 'Running'},
      ];
      when(() => mockUsp.get(any(), fresh: any(named: 'fresh')))
          .thenAnswer((_) async => reads.removeAt(0));
      operateAnswers({'Status': 'Success'});

      expect(await service.reboot(), RouterRestartStart.network);
    });

    // A value left behind by a finished action must not lock the buttons
    // until the router restarts; a running one is still refused as busy.
    test('a value it does not know does not stop the press', () async {
      routerAnswers({statusPath: 'Cancelled'});
      operateAnswers({'Status': 'Started'});

      expect(await service.reboot(), RouterRestartStart.network);

      verify(() => mockUsp.operate(rebootAll)).called(1);
    });

    test('any other refusal of the whole-network command throws', () async {
      routerAnswers({statusPath: ''});
      when(() => mockUsp.operate(any())).thenThrow('Operate failed: '
          'Operation error: $rebootAll refused: Internal error (code: 7003)');

      await expectLater(
        service.reboot(),
        throwsA(
            isA<UspCompleteFailureError>().having((e) => e.code, 'code', 7003)),
      );
    });

    // 7002 means "already running" only for the whole-network pair. On the
    // router-only path it is an ordinary refusal and is reported as one.
    test('a 7002 from Device.Reboot() throws', () async {
      routerAnswers({});
      when(() => mockUsp.operate(any())).thenThrow('Operate failed: '
          'Operation error: Device.Reboot() refused: (code: 7002)');

      await expectLater(
          service.reboot(), throwsA(isA<UspCompleteFailureError>()));
    });
  });

  group('readNetworkActionStatus', () {
    const statusPath =
        'Device.WiFi.DataElements.Network.X_LINKSYS_NetworkActionStatus';

    Future<NetworkActionStatus?> reading(Map<String, dynamic> response) {
      when(() => mockUsp.get(any(), fresh: any(named: 'fresh')))
          .thenAnswer((_) async => response);
      return service.readNetworkActionStatus();
    }

    test('is null when the router does not have the leaf', () async {
      expect(await reading({}), isNull);
    });

    test('reads each value the definition names', () async {
      expect(await reading({statusPath: ''}), NetworkActionStatus.idle);
      expect(
          await reading({statusPath: 'Running'}), NetworkActionStatus.running);
      expect(await reading({statusPath: 'Completed'}),
          NetworkActionStatus.completed);
      expect(await reading({statusPath: 'Failed'}), NetworkActionStatus.failed);
    });

    test('reads a value the definition does not name as unknown', () async {
      expect(
          await reading({statusPath: 'Paused'}), NetworkActionStatus.unknown);
    });
  });
}
