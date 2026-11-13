import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/errors/usp_refusal_reason.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/services/refused_add_service.dart';

import '../../../mocks/test_data/usp_add_refusal_test_data.dart';
import '../../../mocks/test_data/usp_envelope_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient usp;

  setUpAll(() => registerFallbackValue(<String>[]));

  setUp(() {
    usp = MockUspClient();
    when(() => usp.delete(any()))
        .thenAnswer((_) async => UspAddRefusalTestData.accepted);
  });

  Future<UspAddResult> run(Map<String, dynamic> raw) =>
      parseAddRemovingRefusedRows(usp, raw, tag: '[T]');

  group('parseAddRemovingRefusedRows', () {
    test('a clean Add is returned as parsed, and nothing is deleted', () async {
      final result = await run({
        'success': true,
        'result': {
          'data': {
            'instances': ['Device.NAT.PortTrigger.26.']
          }
        },
      });

      expect(result, isA<UspSuccess<List<String>>>());
      verifyNever(() => usp.delete(any()));
    });

    test(
        'every created row refused: each is deleted, and the Add reads as a '
        'complete failure that wrote nothing', () async {
      const row = 'Device.NAT.PortTrigger.26.';
      final result = await run(
          UspAddRefusalTestData.refusedAdd(instances: [row], refusedRow: row));

      verify(() => usp.delete([row])).called(1);
      expect(result, isA<UspFailure<List<String>>>());
      final failures = (result as UspFailure).errors;
      expect(failures.map((f) => f.requestedPath),
          containsAll(['${row}Enable', '${row}Port']));
      expect(
          failures
              .firstWhere((f) => f.requestedPath == '${row}Port')
              .errorMessage,
          startsWith('ErrorTooManyRules'));
    });

    test(
        'only the refused row of a batch is deleted, and the Add stays a '
        'partial success', () async {
      const good = 'Device.Routing.Router.1.IPv4Forwarding.30.';
      const bad = 'Device.Routing.Router.1.IPv4Forwarding.31.';
      final result = await run(UspAddRefusalTestData.refusedAdd(
          instances: [good, bad], refusedRow: bad));

      verify(() => usp.delete([bad])).called(1);
      verifyNever(() => usp.delete([good]));
      expect(result, isA<UspPartialSuccess<List<String>>>());
    });

    test(
        'a table path (0.14.0 falls back to it when the agent names no '
        'instance) is never deleted: the Add stays partial', () async {
      const table = 'Device.NAT.PortTrigger.';
      final result = await run(UspAddRefusalTestData.refusedAdd(
          instances: [table], refusedRow: table));

      verifyNever(() => usp.delete(any()));
      expect(result, isA<UspPartialSuccess<List<String>>>());
    });

    test(
        'beside a table path, a refused instance row of the same Add is still '
        'deleted, and the Add stays partial', () async {
      const table = 'Device.Firewall.Chain.1.Rule.';
      const row = 'Device.Firewall.Chain.1.Rule.49.';
      final result = await run(UspAddRefusalTestData.refusedAdd(
          instances: [table, row], refusedRow: row, refusedParam: 'Target'));

      verify(() => usp.delete([row])).called(1);
      verifyNever(() => usp.delete([table]));
      expect(result, isA<UspPartialSuccess<List<String>>>());
    });

    test('several refused rows are deleted highest number first', () async {
      const a = 'Device.Firewall.Chain.1.Rule.9.';
      const b = 'Device.Firewall.Chain.1.Rule.10.';
      // Listed lowest last, so reversing the list would get it wrong.
      final raw =
          UspAddRefusalTestData.refusedAdd(instances: [b, a], refusedRow: a);
      (raw['result']['errors'] as List).add({
        'kind': 'parameter',
        'path': '${b}Target',
        'errorCode': 7005,
        'errorMessage': 'ErrorRulesOverlap: x',
      });
      final calls = <String>[];
      when(() => usp.delete(any())).thenAnswer((inv) async {
        calls.add((inv.positionalArguments.first as List<String>).single);
        return UspAddRefusalTestData.accepted;
      });

      final result = await run(raw);

      // The router renumbers the rows after a delete, so the higher one goes
      // first.
      expect(calls, [b, a]);
      expect(result, isA<UspFailure<List<String>>>());
    });

    test(
        'a refused row the delete could not remove keeps the Add a partial '
        'success, so the page reads the router again', () async {
      const row = 'Device.NAT.PortTrigger.26.';
      when(() => usp.delete(any()))
          .thenAnswer((_) async => UspEnvelopeTestData.pathErrors(
                {row: (code: 7027, message: 'Object not found')},
                success: false,
              ));

      final result = await run(
          UspAddRefusalTestData.refusedAdd(instances: [row], refusedRow: row));

      expect(result, isA<UspPartialSuccess<List<String>>>());
    });

    test(
        'an Add refused as a whole (usp-client 0.15.0) created nothing: no row '
        'is deleted, and it is a complete failure carrying the reason',
        () async {
      // The `{i}` key names a template, not a row, and there are no instances
      // to match it against anyway (#1787).
      final result = await run(UspAddRefusalTestData.refusedAsAWhole());

      verifyNever(() => usp.delete(any()));
      expect(result, isA<UspFailure<List<String>>>());
      final failure = (result as UspFailure).errors.single;
      expect(failure.requestedPath, 'Device.NAT.PortTrigger.{i}.Port');
      expect(failure.errorCode, 7005);
      expect(failure.refusalReason, UspRefusalReason.tooManyRules);
    });

    test(
        'an Add refused as a whole that names no parameter is keyed by the '
        'table, which is never deleted', () async {
      final result = await run(UspAddRefusalTestData.refusedAsAWhole(
          errorCode: 7004, refusedParam: null, message: 'Request denied'));

      verifyNever(() => usp.delete(any()));
      expect(result, isA<UspFailure<List<String>>>());
      expect((result as UspFailure).errors.single.requestedPath,
          'Device.NAT.PortTrigger.');
    });

    test('a delete that throws is the same: the row may still be there',
        () async {
      const row = 'Device.NAT.PortTrigger.26.';
      when(() => usp.delete(any()))
          .thenThrow('Delete failed: Transport error: Request timeout');

      final result = await run(
          UspAddRefusalTestData.refusedAdd(instances: [row], refusedRow: row));

      expect(result, isA<UspPartialSuccess<List<String>>>());
    });
  });
}
