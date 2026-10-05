import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';

import '../../../common/di.dart';

/// Polling that has produced nothing yet; the firmware notifier only reads it.
class _IdlePolling extends PollingNotifier {
  @override
  FutureOr<CoreTransactionData> build() =>
      const CoreTransactionData(lastUpdate: 0, isReady: false, data: {});
}

void main() {
  mockDependencyRegister();

  ProviderContainer readOnlyContainer() {
    final container = ProviderContainer(overrides: [
      accessPolicyProvider
          .overrideWithValue(const AccessPolicy(canWrite: false)),
      pollingProvider.overrideWith(_IdlePolling.new),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  // #1637: both refusals happen before any state is touched. `updateFirmware`
  // used to mark itself updating first, and nothing cleared that once the send
  // was refused, leaving the page on its updating spinner for good.
  test('an update is refused without being marked in progress', () async {
    final container = readOnlyContainer();
    final notifier = container.read(firmwareUpdateProvider.notifier);

    await expectLater(
        notifier.updateFirmware(), throwsA(isA<ReadOnlyAccessException>()));

    expect(container.read(firmwareUpdateProvider).isUpdating, isFalse);
  });

  // The upload goes to the router's local address directly rather than through
  // RouterRepository, so the gate there never sees it.
  test('a manual upload is refused before anything is sent', () async {
    final container = readOnlyContainer();
    final notifier = container.read(firmwareUpdateProvider.notifier);

    await expectLater(notifier.manualFirmwareUpdate('fw.img', const [1, 2, 3]),
        throwsA(isA<ReadOnlyAccessException>()));
    expect(container.read(readOnlyRefusalProvider), 1,
        reason: 'a refusal is reported like any other, so the user is told');
  });
}
