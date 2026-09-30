// Manual firmware upload in a read-only build.
//
// The upload is the one router write that does not go through RouterRepository:
// it builds its own client and posts a multipart file. The transport guard
// cannot see it, so it carries its own refusal. What is pinned is that the
// refusal comes before anything with a side effect - in particular before
// polling is stopped, which nothing would restart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/providers/read_only/read_only_mode_provider.dart';

import '../../../common/di.dart';
import '../../../mocks/polling_notifier_mocks.dart';

void main() {
  mockDependencyRegister();

  test('a read-only build refuses the upload without touching polling',
      () async {
    final polling = MockPollingNotifier();
    final container = ProviderContainer(overrides: [
      readOnlyModeProvider.overrideWithValue(true),
      pollingProvider.overrideWith(() => polling),
    ]);
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(firmwareUpdateProvider.notifier)
          .manualFirmwareUpdate('fw.img', [0, 1, 2]),
      throwsA(isA<ManualFirmwareUpdateException>()
          .having((e) => e.result, 'result', 'ReadOnly')),
    );
    verifyNever(polling.stopPolling());
  });
}
