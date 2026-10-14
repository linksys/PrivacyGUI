import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import '../../../mocks/test_data/auto_ipoe_test_data.dart';

void main() {
  const apply = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
  test('acceptance and stale success cannot prove current connectivity', () {
    expect(
        AutoIPoETestData.snapshot(requestId: AutoIPoETestData.id)
            .outcomeFor(apply),
        AutoIPoEOutcome.pending);
    expect(
        AutoIPoETestData.snapshot(
                requestId: 'older', exitCode: 0, verified: true)
            .outcomeFor(apply),
        AutoIPoEOutcome.pending);
  });
  test('completed Apply requires exit zero and verified structured result', () {
    expect(
        AutoIPoETestData.snapshot(
                requestId: AutoIPoETestData.id, exitCode: 0, verified: true)
            .outcomeFor(apply),
        AutoIPoEOutcome.succeeded);
    expect(
        AutoIPoETestData.snapshot(requestId: AutoIPoETestData.id, exitCode: 0)
            .outcomeFor(apply),
        AutoIPoEOutcome.failed);
    expect(
        AutoIPoETestData.snapshot(
                requestId: AutoIPoETestData.id, exitCode: 1, phase: 'failed')
            .outcomeFor(apply),
        AutoIPoEOutcome.failed);
  });
  test('busy and scheduled provider retry remain distinct', () {
    expect(
        AutoIPoETestData.snapshot(
                requestId: AutoIPoETestData.id, exitCode: 75, phase: 'busy')
            .outcomeFor(apply),
        AutoIPoEOutcome.busy);
    expect(
        AutoIPoETestData.snapshot(
                requestId: AutoIPoETestData.id,
                exitCode: 0,
                phase: 'retry_scheduled')
            .outcomeFor(apply),
        AutoIPoEOutcome.retryScheduled);
  });
  test('Reset checks its own operation without claiming connectivity', () {
    const reset = AutoIPoESubmission(AutoIPoETestData.id, reset: true);
    expect(
        AutoIPoETestData.snapshot(
                requestId: AutoIPoETestData.id, exitCode: 0, reset: true)
            .outcomeFor(reset),
        AutoIPoEOutcome.succeeded);
    expect(
        AutoIPoETestData.snapshot(
                requestId: AutoIPoETestData.id, exitCode: 0, verified: true)
            .outcomeFor(reset),
        AutoIPoEOutcome.failed);
  });

  test('matching request with different operation ID remains unresolved', () {
    final current = AutoIPoETestData.snapshot(
        requestId: AutoIPoETestData.id, exitCode: 0, verified: true);
    expect(
        current
            .withRuntime(current.runtime, operationId: 'other')
            .outcomeFor(apply),
        AutoIPoEOutcome.pending);
  });
  test('Reset requires the native cleanup completion marker', () {
    const reset = AutoIPoESubmission(AutoIPoETestData.id, reset: true);
    final current = AutoIPoETestData.snapshot(
        requestId: AutoIPoETestData.id, exitCode: 0, reset: true);
    expect(
        current
            .withRuntime(current.runtime.copyWith(lastResult: 'Pending'))
            .outcomeFor(reset),
        AutoIPoEOutcome.failed);
  });
}
