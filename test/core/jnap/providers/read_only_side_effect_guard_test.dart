// Providers that act before their write must refuse before acting.
//
// The transport refuses a write when it is sent, but two providers change app
// state first: firmware update marks itself updating and power table stops
// polling. A refused send leaves both stuck, and nothing undoes either. So each
// asks the transport up front and refuses before touching anything - whichever
// widget called it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/providers/read_only/read_only_mode_provider.dart';

import '../../../common/di.dart';
import '../../../mocks/polling_notifier_mocks.dart';

void main() {
  mockDependencyRegister();

  late MockPollingNotifier polling;
  late ProviderContainer container;

  setUp(() {
    initBetterActions();
    polling = MockPollingNotifier();
    container = ProviderContainer(overrides: [
      readOnlyModeProvider.overrideWithValue(true),
      pollingProvider.overrideWith(() => polling),
    ]);
  });

  tearDown(() => container.dispose());

  final refusal = throwsA(
      isA<JNAPError>().having((e) => e.result, 'result', errorReadOnlyMode));

  test('firmware update refuses before marking itself updating', () async {
    final notifier = container.read(firmwareUpdateProvider.notifier);

    await expectLater(notifier.updateFirmware(), refusal);
    expect(container.read(firmwareUpdateProvider).isUpdating, isFalse);
  });

  test('power table refuses before stopping polling', () async {
    final notifier = container.read(powerTableProvider.notifier);

    await expectLater(notifier.save(PowerTableCountries.values.first), refusal);
    verifyNever(polling.stopPolling());
  });
}
