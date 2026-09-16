import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
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

  group('triggerOtaDownload', () {
    test('invokes FirmwareImage.{i}.Download() with https:// URL', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{'success': true});

      await service.triggerOtaDownload(
        targetInstance: 2,
        firmwareUrl: 'https://download.linksys.com/updates/firmware.img',
      );

      final captured = verify(
        () => mockUsp.operate(captureAny(), args: captureAny(named: 'args')),
      ).captured;
      expect(captured[0], 'Device.DeviceInfo.FirmwareImage.2.Download()');
      final args = captured[1] as Map<String, String>;
      expect(args['URL'], 'https://download.linksys.com/updates/firmware.img');
      expect(args['AutoActivate'], 'true');
    });

    test('passes AutoActivate=false when requested', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{'success': true});

      await service.triggerOtaDownload(
        targetInstance: 2,
        firmwareUrl: 'https://example.com/fw.img',
        autoActivate: false,
      );

      final captured = verify(
        () => mockUsp.operate(any(), args: captureAny(named: 'args')),
      ).captured;
      expect((captured.first as Map<String, String>)['AutoActivate'], 'false');
    });

    test('maps USP error to ServiceError', () {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenThrow('Operate failed: Transport error: Request timeout');

      expect(
        () => service.triggerOtaDownload(
          targetInstance: 2,
          firmwareUrl: 'https://example.com/fw.img',
        ),
        throwsA(isA<NetworkError>()),
      );
    });
  });

  group('requestOtaCheck', () {
    test('sends AutoActivate=false and no URL at all', () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args'))).thenAnswer(
          (_) async =>
              <String, dynamic>{'commandKey': 'check-1', 'Status': ''});

      final key = await service.requestOtaCheck(otaInstance: 3);

      expect(key, 'check-1');
      final captured = verify(
        () => mockUsp.operate(captureAny(), args: captureAny(named: 'args')),
      ).captured;
      expect(captured[0], 'Device.DeviceInfo.FirmwareImage.3.Download()');
      final args = captured[1] as Map<String, String>;
      // Not "URL is empty" — absent. The virtual ota instance ignores the
      // parameter, and sending an empty one is a value the firmware has never
      // been asked to interpret.
      expect(args.containsKey('URL'), isFalse);
      expect(args['AutoActivate'], 'false');
      expect(args, hasLength(1));
    });

    test('throws when the response carries no commandKey', () {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{'Status': 'Requested'});

      // The whole of the dispatch signal. An operate for a command that does
      // not exist still answers success, so a missing key is the only thing
      // that distinguishes "asked" from "did not ask" — and it must not reach
      // the caller as a check that found nothing.
      expect(
        () => service.requestOtaCheck(otaInstance: 3),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('throws when the commandKey is present but empty', () {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{'commandKey': ''});

      expect(
        () => service.requestOtaCheck(otaInstance: 3),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('maps USP error to ServiceError', () {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenThrow('Operate failed: Transport error: Request timeout');

      expect(
        () => service.requestOtaCheck(otaInstance: 3),
        throwsA(isA<NetworkError>()),
      );
    });
  });

  group('requestOtaInstall', () {
    test('is requestOtaCheck with AutoActivate flipped, and still no URL',
        () async {
      when(() => mockUsp.operate(any(), args: any(named: 'args'))).thenAnswer(
          (_) async =>
              <String, dynamic>{'commandKey': 'install-1', 'Status': ''});

      final key = await service.requestOtaInstall(otaInstance: 3);

      expect(key, 'install-1');
      final captured = verify(
        () => mockUsp.operate(captureAny(), args: captureAny(named: 'args')),
      ).captured;
      expect(captured[0], 'Device.DeviceInfo.FirmwareImage.3.Download()');
      final args = captured[1] as Map<String, String>;
      // The URL stays absent for the install too. The ota instance ignores it
      // either way — the router resolves the OTA server itself — so requiring
      // one, as `triggerOtaDownload` does, would mean inventing a value.
      expect(args.containsKey('URL'), isFalse);
      expect(args['AutoActivate'], 'true');
      expect(args, hasLength(1));
    });

    test('sends none of the keep-config inputs', () async {
      // Decided 2026-09-14: `X_LINKSYS_KeepConfig` / `X_LINKSYS_KeepOpConf` /
      // `X_LINKSYS_ConfigScope` are never passed, so the router applies its own
      // default. Pinned here because "we did not decide" and "we decided to let
      // the router decide" look identical in the diff.
      when(() => mockUsp.operate(any(), args: any(named: 'args'))).thenAnswer(
          (_) async => <String, dynamic>{'commandKey': 'install-1'});

      await service.requestOtaInstall(otaInstance: 3);

      final args = verify(
        () => mockUsp.operate(any(), args: captureAny(named: 'args')),
      ).captured.first as Map<String, String>;
      expect(args.keys, ['AutoActivate']);
    });

    test('throws when the response carries no commandKey', () {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{'Status': 'Requested'});

      // Same reasoning as the check, with more at stake: without the key there
      // is nothing to match an `OperationComplete` against, so a refused flash
      // would be indistinguishable from one still running and the page would
      // sit on a progress bar for its whole ceiling.
      expect(
        () => service.requestOtaInstall(otaInstance: 3),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('throws when the commandKey is present but empty', () {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => <String, dynamic>{'commandKey': ''});

      expect(
        () => service.requestOtaInstall(otaInstance: 3),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('maps USP error to ServiceError', () {
      when(() => mockUsp.operate(any(), args: any(named: 'args')))
          .thenThrow('Operate failed: Transport error: Request timeout');

      expect(
        () => service.requestOtaInstall(otaInstance: 3),
        throwsA(isA<NetworkError>()),
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

  group('mapAutoUpdateStatus', () {
    // The `fwup_state` domain is 0/1/3/4/5 — five values, not six. (`2` is a mode
    // of `update_firmware_now`, not a state.) All five are now measured on real
    // hardware, and `5` is the one that moved: it is the reboot, not a failure.
    // `FirmwareAutoUpdateStatus.rebooting` carries the four sources.
    const cases = {
      '0': FirmwareAutoUpdateStatus.idle,
      '1': FirmwareAutoUpdateStatus.checking,
      '3': FirmwareAutoUpdateStatus.downloading,
      '4': FirmwareAutoUpdateStatus.installing,
      '5': FirmwareAutoUpdateStatus.rebooting,
    };

    cases.forEach((raw, expected) {
      test('fwup_state "$raw" maps to ${expected.name}', () {
        final model = UspFirmwareUpdateService.mapAutoUpdateStatus(
          FirmwareUpdateTestData.autoUpdate(fwupState: raw),
        );

        expect(model.status, expected);
        expect(model.rawState, raw);
      });
    });

    test('an undefined value maps to unknown, does not throw, is not idle', () {
      // The arm that matters: a firmware that grows a sixth state must show as
      // unknown, because reporting idle would tell the user nothing is running
      // while the router is mid-flash.
      final model = UspFirmwareUpdateService.mapAutoUpdateStatus(
        FirmwareUpdateTestData.autoUpdate(fwupState: '7'),
      );

      expect(model.status, FirmwareAutoUpdateStatus.unknown);
      expect(model.status, isNot(FirmwareAutoUpdateStatus.idle));
    });

    test('an empty fwup_state maps to unknown', () {
      // codegen substitutes '' for an absent value, so "the router did not
      // answer" arrives here as an empty string, not as null.
      final model = UspFirmwareUpdateService.mapAutoUpdateStatus(
        FirmwareUpdateTestData.autoUpdate(fwupState: ''),
      );

      expect(model.status, FirmwareAutoUpdateStatus.unknown);
      expect(model.rawState, '');
    });

    test('the raw fwup_state is retrievable from every state', () {
      // Keeping the raw value is what lets a later split read a difference off data
      // we already hold — and it is what made this mapping's own defect legible:
      // the number reached the failure card, which is how `5` was traced back to
      // the reboot instead of a flash failure.
      final model = UspFirmwareUpdateService.mapAutoUpdateStatus(
        FirmwareUpdateTestData.autoUpdate(fwupState: '5', fwupProgress: '42'),
      );

      expect(model.status, FirmwareAutoUpdateStatus.rebooting);
      expect(model.rawState, '5');
    });

    test('progress parses, and a non-numeric progress falls back to 0', () {
      expect(
        UspFirmwareUpdateService.mapAutoUpdateStatus(
          FirmwareUpdateTestData.autoUpdate(fwupState: '3', fwupProgress: '57'),
        ).progress,
        57,
      );
      expect(
        UspFirmwareUpdateService.mapAutoUpdateStatus(
          FirmwareUpdateTestData.autoUpdate(fwupState: '3', fwupProgress: ''),
        ).progress,
        0,
        reason: 'an unreadable progress must not take the status down with it',
      );
    });

    test('progress is carried verbatim, including 100 while idle', () {
      // Measured: `fwup_progress` rests at 100 after a check that found nothing
      // (and at 0 after a different mode). The model must not reinterpret that
      // as "finished" — deciding what it means is the caller's job, and the
      // status is what says whether anything is running.
      final model = UspFirmwareUpdateService.mapAutoUpdateStatus(
        FirmwareUpdateTestData.autoUpdate(fwupState: '0', fwupProgress: '100'),
      );

      expect(model.status, FirmwareAutoUpdateStatus.idle);
      expect(model.progress, 100);
      expect(model.isBusy, isFalse);
    });

    test('isBusy covers exactly the three working states', () {
      String rawOf(FirmwareAutoUpdateStatus s) => switch (s) {
            FirmwareAutoUpdateStatus.idle => '0',
            FirmwareAutoUpdateStatus.checking => '1',
            FirmwareAutoUpdateStatus.downloading => '3',
            FirmwareAutoUpdateStatus.installing => '4',
            FirmwareAutoUpdateStatus.rebooting => '5',
            FirmwareAutoUpdateStatus.unknown => '7',
          };

      final busy = FirmwareAutoUpdateStatus.values
          .where((s) => UspFirmwareUpdateService.mapAutoUpdateStatus(
                FirmwareUpdateTestData.autoUpdate(fwupState: rawOf(s)),
              ).isBusy)
          .toSet();

      expect(busy, {
        FirmwareAutoUpdateStatus.checking,
        FirmwareAutoUpdateStatus.downloading,
        FirmwareAutoUpdateStatus.installing,
      });
    });
  });

  group('auto-update policy — read', () {
    // The whole documented domain of `autoupdate_flags`, one case each. All three
    // are readable; only two of them are ever written (see the write group).
    const cases = {
      '0': FirmwareAutoUpdatePolicy.off,
      '1': FirmwareAutoUpdatePolicy.notifyOnly,
      '2': FirmwareAutoUpdatePolicy.autoInstall,
    };

    cases.forEach((raw, expected) {
      test('autoupdate_flags "$raw" maps to ${expected.name}', () {
        final model = UspFirmwareUpdateService.mapAutoUpdateStatus(
          FirmwareUpdateTestData.autoUpdate(autoupdateFlags: raw),
        );

        expect(model.policy, expected);
        expect(model.rawFlags, raw);
      });
    });

    test('an undefined flag value maps to unknown and is not off', () {
      // Same shape as the `fwup_state` arm above and for the same reason: reading
      // an unrecognised value as `off` would tell the user the router never checks
      // when it may well be checking.
      final model = UspFirmwareUpdateService.mapAutoUpdateStatus(
        FirmwareUpdateTestData.autoUpdate(autoupdateFlags: '9'),
      );

      expect(model.policy, FirmwareAutoUpdatePolicy.unknown);
      expect(model.policy, isNot(FirmwareAutoUpdatePolicy.off));
      expect(model.rawFlags, '9',
          reason: 'the raw value has to survive the gap in this enum');
    });

    test('checksForUpdates is the numeric comparison, not the enum', () {
      // REQ-C3 is `flags > 0`. An unrecognised *positive* value is a router that
      // is checking, so the banner condition must hold for it even though the
      // policy is unknown — otherwise a firmware that grows a value hides an
      // update the router has already found.
      bool checks(String raw) => UspFirmwareUpdateService.mapAutoUpdateStatus(
            FirmwareUpdateTestData.autoUpdate(autoupdateFlags: raw),
          ).checksForUpdates;

      expect(checks('0'), isFalse);
      expect(checks('1'), isTrue);
      expect(checks('2'), isTrue);
      expect(checks('9'), isTrue);
      expect(checks(''), isFalse,
          reason: 'an unreadable flag is not a claim that the router checks');
    });

    test('fetchAutoUpdate parses a router reading end to end', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async =>
          FirmwareUpdateTestData.autoUpdateResponse(
              autoupdateFlags: '1', fwupState: '3', fwupProgress: '42'));

      final model = await service.fetchAutoUpdate();

      expect(model.policy, FirmwareAutoUpdatePolicy.notifyOnly);
      expect(model.status, FirmwareAutoUpdateStatus.downloading);
      expect(model.progress, 42);
    });

    test('fetchAutoUpdate maps a USP error to ServiceError', () {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Request timeout');

      expect(() => service.fetchAutoUpdate(), throwsA(isA<NetworkError>()));
    });
  });

  group('auto-update policy — write', () {
    setUp(() {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });
    });

    test('writes autoupdate_flags and nothing else (REQ-C2)', () async {
      // The one assertion this whole package turns on. `FirmwareAutoUpdate.update()`
      // also accepts `fwupPeriodicCheck` and `updateFirmwareNow`; scheduling is
      // decided against and the second flash entry point is not ours, so a Set
      // carrying either would be a promise this app cannot keep.
      await service.setAutoUpdatePolicy(FirmwareAutoUpdatePolicy.autoInstall);

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      final params = captured.single as Map<String, dynamic>;
      expect(params, {
        'Device.X_LINKSYS_UCI.linksys.fwup.autoupdate_flags': '2',
      });
    });

    test('the switch off position writes 1, never 0', () async {
      // Austin's ruling (2026-09-14): off means "do not install by yourself", not
      // "stop looking". A `0` would take the dashboard banner down with it, since a
      // router that never checks never reports an available image.
      await service.setAutoUpdatePolicy(FirmwareAutoUpdatePolicy.notifyOnly);

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      final params = captured.single as Map<String, dynamic>;
      expect(params.values.single, '1');
      expect(params.values.single, isNot('0'));
    });

    test('off is writable by the service even though the UI never asks for it',
        () async {
      // The enum value exists because a router can *be* at 0. Keeping the service
      // able to send it is what makes "the UI never writes 0" a property of the
      // call sites — pinned in the card's own test — rather than of this layer,
      // which has no business knowing which switch position a caller is in.
      await service.setAutoUpdatePolicy(FirmwareAutoUpdatePolicy.off);

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      expect((captured.single as Map<String, dynamic>).values.single, '0');
    });

    test('unknown is refused before it reaches the router', () async {
      // `unknown.rawValue` is the empty string. Sent, it would either clear the
      // parameter or be rejected by the router — both worse than failing here.
      await expectLater(
        service.setAutoUpdatePolicy(FirmwareAutoUpdatePolicy.unknown),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(() => mockUsp.set(any()));
    });

    test('a rejected Set becomes a ServiceError', () {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {
                'Device.X_LINKSYS_UCI.linksys.fwup.autoupdate_flags': {
                  'errorCode': 7004,
                  'errorMessage': 'Parameter not writable',
                },
              },
            },
          });

      expect(
        () => service.setAutoUpdatePolicy(FirmwareAutoUpdatePolicy.autoInstall),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('a transport failure maps to ServiceError', () {
      when(() => mockUsp.set(any()))
          .thenThrow('Set failed: Authentication error: Permission denied');

      expect(
        () => service.setAutoUpdatePolicy(FirmwareAutoUpdatePolicy.notifyOnly),
        throwsA(isA<UnauthorizedError>()),
      );
    });
  });
}
