import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';

/// `GetFirmwareUpdateStatus` output as JSON text, while an update the router
/// found installs, after an earlier one failed.
const _installingText = '''
{
  "lastSuccessfulCheckTime": "2026-11-24T02:00:00Z",
  "availableUpdate": {
    "firmwareVersion": "1.1.13.202617",
    "firmwareDate": "2026-11-01T00:00:00Z",
    "description": "Security fixes"
  },
  "pendingOperation": {"operation": "Installing", "progressPercent": 40},
  "lastOperationFailure": "CheckFailed"
}
''';

/// The same router once it is up to date.
const _upToDateText = '{"lastSuccessfulCheckTime": "2026-11-25T02:00:00Z"}';

void main() {
  group('FirmwareUpdateStatus', () {
    test('reads the update, the install under way and the last failure', () {
      final status = FirmwareUpdateStatus.fromJson(_installingText);

      expect(status.lastSuccessfulCheckTime, '2026-11-24T02:00:00Z');
      expect(status.availableUpdate?.firmwareVersion, '1.1.13.202617');
      expect(status.availableUpdate?.description, 'Security fixes');
      expect(status.pendingOperation?.operation, 'Installing');
      expect(status.pendingOperation?.progressPercent, 40);
      expect(status.lastOperationFailure, 'CheckFailed');
    });

    test('reads a router that is up to date', () {
      final status = FirmwareUpdateStatus.fromJson(_upToDateText);

      expect(status.availableUpdate, isNull);
      expect(status.pendingOperation, isNull);
      expect(status.lastOperationFailure, isNull);
      expect(status.toMap(), {
        'lastSuccessfulCheckTime': '2026-11-25T02:00:00Z',
        'availableUpdate': null,
        'pendingOperation': null,
        'lastOperationFailure': null,
      });
    });

    test('survives a trip through JSON text', () {
      final status = FirmwareUpdateStatus.fromJson(_installingText);

      expect(FirmwareUpdateStatus.fromJson(status.toJson()), status);
      expect(status, isNot(FirmwareUpdateStatus.fromJson(_upToDateText)));
    });

    test('copyWith can clear what the install leaves behind', () {
      final status = FirmwareUpdateStatus.fromJson(_installingText);

      final done = status.copyWith(
        lastSuccessfulCheckTime: '2026-11-24T02:30:00Z',
        pendingOperation: () => null,
        lastOperationFailure: () => null,
      );

      expect(done.pendingOperation, isNull);
      expect(done.lastOperationFailure, isNull);
      expect(done.availableUpdate, status.availableUpdate);
      expect(done.lastSuccessfulCheckTime, '2026-11-24T02:30:00Z');
      expect(
          status.copyWith(availableUpdate: () => null).availableUpdate, isNull);
    });
  });

  group('the parts of a status', () {
    final status = FirmwareUpdateStatus.fromJson(_installingText);

    test('an available update', () {
      final update = status.availableUpdate!;

      expect(FirmwareUpdateData.fromJson(update.toJson()), update);
      expect(
          FirmwareUpdateData.fromMap(const {
            'firmwareVersion': '1.1.13.202617',
            'firmwareDate': '2026-11-01T00:00:00Z',
          }).description,
          isNull);
      final newer = update.copyWith(firmwareVersion: '1.1.14.203000');
      expect(update.copyWith(), update);
      expect(update.copyWith(firmwareVersion: '1.1.14.203000'), isNot(update));
      expect(newer.firmwareVersion, '1.1.14.203000');
      expect(newer.firmwareDate, update.firmwareDate);
    });

    test('an operation under way', () {
      final operation = status.pendingOperation!;

      expect(operation.toMap(),
          {'operation': 'Installing', 'progressPercent': 40});
      expect(FirmwareUpdateOperationStatus.fromJson(operation.toJson()),
          operation);
      final further = operation.copyWith(progressPercent: 80);
      expect(operation.copyWith(), operation);
      expect(operation.copyWith(progressPercent: 80), isNot(operation));
      expect((further.operation, further.progressPercent), ('Installing', 80));
    });
  });
}
