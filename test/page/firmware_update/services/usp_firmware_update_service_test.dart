import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';

import '../../../mocks/test_data/firmware_update_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspFirmwareUpdateService service;

  setUpAll(() {
    registerFallbackValue(<String>[]);
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    mockUsp = MockUspClient();
    service = UspFirmwareUpdateService(mockUsp);
  });

  group('fetchAllBanks', () {
    test('returns both banks from dual-bank response', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => FirmwareUpdateTestData.dualBankResponse());

      final banks = await service.fetchAllBanks();

      expect(banks, hasLength(2));
      expect(banks[0].instance, 1);
      expect(banks[0].isActive, isTrue);
      expect(banks[1].instance, 2);
      expect(banks[1].isActive, isFalse);
      expect(banks[1].available, isTrue);
    });

    test('maps USP error to ServiceError', () {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Request timeout');

      expect(() => service.fetchAllBanks(), throwsA(isA<NetworkError>()));
    });
  });

  group('fetchActiveBank', () {
    test('returns the bank whose status is Active', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => FirmwareUpdateTestData.dualBankResponse());

      final active = await service.fetchActiveBank();

      expect(active.instance, 1);
      expect(active.status, 'Active');
    });

    test('throws when no active bank found', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => <String, dynamic>{
            'Device.DeviceInfo.FirmwareImage.1.Name': 'Bank1',
            'Device.DeviceInfo.FirmwareImage.1.Version': '1.0.0',
            'Device.DeviceInfo.FirmwareImage.1.Status': 'Available',
            'Device.DeviceInfo.FirmwareImage.1.Available': true,
          });

      expect(
        () => service.fetchActiveBank(),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });
  });

  group('fetchAvailableBank', () {
    test('returns bank that is available and not active', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => FirmwareUpdateTestData.dualBankResponse());

      final available = await service.fetchAvailableBank();

      expect(available.instance, 2);
      expect(available.isActive, isFalse);
      expect(available.available, isTrue);
    });

    test('throws when only the active bank exists', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => FirmwareUpdateTestData.singleBankResponse());

      expect(
        () => service.fetchAvailableBank(),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });
  });

  group('triggerLocalDownload', () {
    test('invokes FirmwareImage.{i}.Download() with file:// URL', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{'success': true});

      await service.triggerLocalDownload(targetInstance: 2);

      final captured = verify(
        () => mockUsp.operate(captureAny(), args: captureAny(named: 'args')),
      ).captured;
      expect(captured[0], 'Device.DeviceInfo.FirmwareImage.2.Download()');
      final args = captured[1] as Map<String, String>;
      expect(args['URL'], 'file:///tmp/obuspa/firmware.img');
      expect(args['AutoActivate'], 'true');
    });

    test('passes AutoActivate=false when requested', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{'success': true});

      await service.triggerLocalDownload(
        targetInstance: 2,
        autoActivate: false,
      );

      final captured = verify(
        () => mockUsp.operate(any(), args: captureAny(named: 'args')),
      ).captured;
      expect((captured.first as Map<String, String>)['AutoActivate'], 'false');
    });

    test('maps USP error to ServiceError', () {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenThrow('Operate failed: Authentication error: Permission denied');

      expect(
        () => service.triggerLocalDownload(targetInstance: 2),
        throwsA(isA<UnauthorizedError>()),
      );
    });
  });

  group('pollStatus', () {
    test('returns the status field of the matching instance', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => FirmwareUpdateTestData.dualBankResponse());

      final status = await service.pollStatus(2);

      expect(status, 'Available');
    });

    test('throws when instance not found', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => FirmwareUpdateTestData.singleBankResponse());

      expect(
        () => service.pollStatus(99),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });
  });

  group('verifyAfterReboot', () {
    test('returns true when expected version is now Active', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => FirmwareUpdateTestData.postFlashResponse(
                newVersion: '1.0.17.26050100',
              ));

      final ok = await service.verifyAfterReboot(
        expectedVersion: '1.0.17.26050100',
        expectedActiveInstance: 2,
      );

      expect(ok, isTrue);
    });

    test('returns false when active version differs', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => FirmwareUpdateTestData.postFlashResponse(
                newVersion: '1.0.17.26050100',
              ));

      final ok = await service.verifyAfterReboot(
        expectedVersion: '1.0.99.99999999',
        expectedActiveInstance: 2,
      );

      expect(ok, isFalse);
    });

    test('throws when expected active instance is not Active', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => FirmwareUpdateTestData.dualBankResponse());

      expect(
        () => service.verifyAfterReboot(
          expectedVersion: '1.0.16.26013014',
          expectedActiveInstance: 2,
        ),
        throwsA(
          isA<UspCompleteFailureError>().having(
            (e) => e.summary,
            'summary',
            contains('did not boot the new image'),
          ),
        ),
      );
    });

    test('passes when same-version reflash flips banks', () async {
      // dev/QA scenario: same firmware version flashed onto bank 2 to validate
      // boot path. Active instance flips even though `Version` is unchanged.
      when(() => mockUsp.get(any())).thenAnswer((_) async =>
          FirmwareUpdateTestData.postFlashResponse(
              newVersion: '1.0.16.26013014', oldVersion: '1.0.16.26013014'));

      final ok = await service.verifyAfterReboot(
        expectedVersion: '1.0.16.26013014',
        expectedActiveInstance: 2,
      );

      expect(ok, isTrue);
    });

    test('throws when expected instance is missing entirely', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => FirmwareUpdateTestData.singleBankResponse());

      expect(
        () => service.verifyAfterReboot(
          expectedVersion: '1.0.17.0',
          expectedActiveInstance: 99,
        ),
        throwsA(
          isA<UspCompleteFailureError>().having(
            (e) => e.summary,
            'summary',
            contains('not present after reboot'),
          ),
        ),
      );
    });

    test('throws when more than one bank reports Active', () async {
      // Inconsistent transition state — two banks both `Active` is never
      // a legitimate steady state on M60TB.
      when(() => mockUsp.get(any())).thenAnswer((_) async => <String, dynamic>{
            'Device.DeviceInfo.FirmwareImage.1.Name': 'Bank1',
            'Device.DeviceInfo.FirmwareImage.1.Version': '1.0.16',
            'Device.DeviceInfo.FirmwareImage.1.Status': 'Active',
            'Device.DeviceInfo.FirmwareImage.1.Available': true,
            'Device.DeviceInfo.FirmwareImage.2.Name': 'Bank2',
            'Device.DeviceInfo.FirmwareImage.2.Version': '1.0.17',
            'Device.DeviceInfo.FirmwareImage.2.Status': 'Active',
            'Device.DeviceInfo.FirmwareImage.2.Available': true,
          });

      expect(
        () => service.verifyAfterReboot(
          expectedVersion: '1.0.17',
          expectedActiveInstance: 2,
        ),
        throwsA(
          isA<UspCompleteFailureError>().having(
            (e) => e.summary,
            'summary',
            contains('Inconsistent firmware state'),
          ),
        ),
      );
    });
  });
}
