import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/admin/models/network_action_models.dart';

void main() {
  group('NetworkActionStatus.fromValue', () {
    test('reads each value the definition names', () {
      expect(NetworkActionStatus.fromValue(''), NetworkActionStatus.idle);
      expect(NetworkActionStatus.fromValue('Running'),
          NetworkActionStatus.running);
      expect(NetworkActionStatus.fromValue('Completed'),
          NetworkActionStatus.completed);
      expect(
          NetworkActionStatus.fromValue('Failed'), NetworkActionStatus.failed);
    });

    // Not `running`: the press holds back only on `Running`, so a value left
    // behind by a finished action must not read as one still going.
    test('reads anything else as unknown, case included', () {
      for (final value in ['Stopped', 'running', 'Busy', ' Running']) {
        expect(
            NetworkActionStatus.fromValue(value), NetworkActionStatus.unknown,
            reason: value);
      }
    });
  });
}
