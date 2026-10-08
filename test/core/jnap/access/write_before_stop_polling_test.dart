import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_provider.dart';

import '../../../common/di.dart';

/// Records whether polling was stopped, and touches nothing else.
class _RecordingPolling extends PollingNotifier {
  int stops = 0;

  @override
  FutureOr<CoreTransactionData> build() =>
      const CoreTransactionData(lastUpdate: 0, isReady: false, data: {});

  @override
  stopPolling() => stops++;
}

void main() {
  mockDependencyRegister();

  late _RecordingPolling polling;

  ProviderContainer readOnly() {
    polling = _RecordingPolling();
    final container = ProviderContainer(overrides: [
      accessPolicyProvider
          .overrideWithValue(const AccessPolicy(canWrite: false)),
      pollingProvider.overrideWith(() => polling),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  // #1637: save() stopped polling and then sent the write. A refusal that came
  // after the stop skipped the restart chained onto the send, leaving the
  // dashboard frozen on its last poll. The refusal now comes first.
  test('a refused power table change leaves polling running', () async {
    final container = readOnly();

    await expectLater(
        container
            .read(powerTableProvider.notifier)
            .save(PowerTableCountries.values.first),
        throwsA(isA<ReadOnlyAccessException>()));

    expect(polling.stops, 0);
  });
}
