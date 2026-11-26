import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/services/batch_tally.dart';

import '../../../mocks/test_data/usp_add_refusal_test_data.dart';
import '../../../mocks/test_data/usp_envelope_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

/// [BatchTally] decides what a batch save tells its page: nothing failed, the
/// save wrote nothing (keep the edit for a retry), or it wrote part of itself
/// (read the router again). The service tests reach it through each page's
/// batch; these pin the rule itself.
void main() {
  const ok = UspSuccess<dynamic>([]);
  UspErrorDetail refusal(String path, String message) => UspErrorDetail(
      requestedPath: path, errorCode: 7012, errorMessage: message);

  // Since #1666 `UspClient` throws a write the router never answered. A batch
  // reads its steps from envelopes, so that throw is turned back into the
  // failed step it was before — or a page whose first step landed would keep
  // its edits as if nothing had been written.
  group('writeOrUnanswered (#1666)', () {
    test('an answered write is returned as it came', () async {
      final answered = {
        'success': true,
        'result': {'data': <String, dynamic>{}},
      };
      expect(await writeOrUnanswered(() async => answered), same(answered));
    });

    test(
        'a write the router never answered becomes the failed step it was '
        "before, with the client's own text", () async {
      final raw = await writeOrUnanswered(
          () async => throw UspEnvelopeTestData.unansweredWrite('Delete'));

      final parsed = UspResultParser.parseDeleteResult(raw);
      expect(parsed, isA<UspFailure<dynamic>>());
      final failure = (parsed as UspFailure<dynamic>).errors.single;
      expect(failure.errorCode, 9999);
      expect(failure.errorMessage, startsWith('Transport error: '));
      expect(failure.errorMessage, contains('Failed to fetch'));
    });

    test(
        'beside a step that landed, it makes the save a partial failure, so '
        'the page reads the router again', () async {
      final tally = BatchTally('[T]')..record('Delete', ok);
      tally.record(
          'Update',
          UspResultParser.parseSetResult(await writeOrUnanswered(
              () async => throw UspEnvelopeTestData.unansweredWrite('Set'))));

      expect(tally.throwIfAnyFailed, throwsA(isA<UspPartialFailureError>()));
    });

    test('a 401 is recorded the same way, as it was before', () async {
      final raw = await writeOrUnanswered(() async =>
          throw UspEnvelopeTestData.unansweredWrite('Set',
              errorMessage: 'Transport error: HTTP error: HTTP 401'));

      expect(UspResultParser.parseSetResult(raw), isA<UspFailure<dynamic>>());
    });

    test('a ServiceError, a refusal and a bug propagate unchanged', () async {
      await expectLater(
          writeOrUnanswered(() async => throw const InvalidInputError()),
          throwsA(isA<InvalidInputError>()));

      const refused = 'Set failed: Protocol error: refused (code: 7005)';
      await expectLater(
          writeOrUnanswered(() async => throw refused), throwsA(refused));

      final bug = StateError('a bug, not a lost request');
      await expectLater(
          writeOrUnanswered(() async => throw bug), throwsA(same(bug)));
    });
  });

  test('every step succeeded: nothing is thrown', () {
    final tally = BatchTally('[T]')
      ..record('Delete', ok)
      ..record('Update', ok);

    expect(tally.throwIfAnyFailed, returnsNormally);
  });

  test(
      'every step failed: a complete failure, carrying every refusal in step '
      'order, so the page keeps the edit', () {
    final first = refusal('Device.X.1.A', 'ErrorRulesOverlap: first');
    final second = refusal('Device.X.2.B', 'ErrorTooManyRules: second');
    final tally = BatchTally('[T]')
      ..record('Update', UspFailure<dynamic>([first]))
      ..record('Add', UspFailure<dynamic>([second]));

    expect(
      tally.throwIfAnyFailed,
      throwsA(isA<UspCompleteFailureError>()
          .having((e) => e.failures, 'failures', [first, second]).having(
              (e) => e.summary,
              'summary',
              '[T] batch: ErrorRulesOverlap: first')),
    );
  });

  test(
      'one step failed beside one that landed: a partial failure, so the page '
      'reads the router again', () {
    final tally = BatchTally('[T]')
      ..record('Delete', ok)
      ..record('Add', UspFailure<dynamic>([refusal('Device.X.', 'refused')]));

    expect(tally.throwIfAnyFailed, throwsA(isA<UspPartialFailureError>()));
  });

  test('a step that partly landed is a partial failure on its own', () {
    final tally = BatchTally('[T]')
      ..record(
          'Update',
          UspPartialSuccess<dynamic>(
              const [], [refusal('Device.X.1.A', 'refused')]));

    expect(tally.throwIfAnyFailed, throwsA(isA<UspPartialFailureError>()));
  });

  test('a step that answered success but cannot go on counts as failed', () {
    final tally = BatchTally('[T]')
      ..recordMissing('Add parent', 'no instance path in the Add result');

    expect(
      tally.throwIfAnyFailed,
      throwsA(isA<UspCompleteFailureError>().having((e) => e.summary, 'summary',
          '[T] batch: no instance path in the Add result')),
    );
  });

  group('recordAdd', () {
    late MockUspClient usp;

    setUpAll(() => registerFallbackValue(<String>[]));

    setUp(() {
      usp = MockUspClient();
      when(() => usp.delete(any()))
          .thenAnswer((_) async => UspAddRefusalTestData.accepted);
    });

    test('a clean Add is recorded as landed, and returns its row', () async {
      const row = 'Device.NAT.PortTrigger.3.';
      final tally = BatchTally('[T]');

      final result = await tally.recordAdd(usp, 'Add', {
        'success': true,
        'result': {
          'data': {
            'instances': [row]
          }
        },
      });

      expect(result, isA<UspSuccess<List<String>>>());
      expect(tally.throwIfAnyFailed, returnsNormally);
      verifyNever(() => usp.delete(any()));
    });

    test(
        'a refused Add has its row deleted and is recorded as a step that '
        'wrote nothing', () async {
      const row = 'Device.NAT.PortTrigger.26.';
      final tally = BatchTally('[T]')..record('Delete', ok);

      final result = await tally.recordAdd(usp, 'Add',
          UspAddRefusalTestData.refusedAdd(instances: [row], refusedRow: row));

      verify(() => usp.delete([row])).called(1);
      expect(result, isA<UspFailure<List<String>>>());
      // The Delete landed and the Add wrote nothing: partial overall.
      expect(tally.throwIfAnyFailed, throwsA(isA<UspPartialFailureError>()));
    });
  });
}
