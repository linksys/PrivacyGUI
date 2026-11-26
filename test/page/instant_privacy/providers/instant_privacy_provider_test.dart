// Unit tests for InstantPrivacyNotifier's reads after a poll (#1834).
//
// The notifier reads its status when polling signals a completed poll
// (pollCompletedProvider), instead of being called by polling. The router is a
// RouterBoundary, so what the notifier sends is observable.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

import '../../../common/di.dart';
import '../../../common/router_boundary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  mockDependencyRegister();

  late RouterBoundary router;
  late ProviderContainer container;

  Map<String, dynamic> macFilter(String mode) => {
        'macFilterMode': mode,
        'maxMACAddresses': 32,
        'macAddresses': const <String>[],
      };

  int reads() => router.actions
      .where((action) => action == JNAPAction.getMACFilterSettings)
      .length;

  setUp(() {
    initBetterActions();
    router = RouterBoundary()
      ..holds(JNAPAction.getMACFilterSettings, macFilter('Disabled'))
      // Refused, so the device list stays out of these tests: the notifier
      // then knows no MAC address of its own.
      ..refuses(JNAPAction.getLocalDevice);
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
  });

  tearDown(() => container.dispose());

  /// Builds the notifier, as a screen that shows it does, and lets its own
  /// first read finish.
  Future<void> buildNotifier() async {
    container.read(instantPrivacyProvider);
    await pumpEventQueue();
  }

  test('a completed poll reads the status', () async {
    await buildNotifier();
    final before = reads();
    router.holds(JNAPAction.getMACFilterSettings, macFilter('Allow'));

    container.read(pollCompletedProvider.notifier).state++;
    await pumpEventQueue();

    expect(reads(), before + 1);
    expect(container.read(instantPrivacyProvider).status.mode,
        MacFilterMode.allow);
  });

  test('a failed read after a poll stays with Instant Privacy', () async {
    // An error that escaped the listener would fail this test as an uncaught
    // error, and in the app it would never reach polling either way.
    await buildNotifier();
    router.refuses(JNAPAction.getMACFilterSettings, result: '_ErrorUnexpected');

    container.read(pollCompletedProvider.notifier).state++;
    await pumpEventQueue();

    expect(container.read(instantPrivacyProvider).status.mode,
        MacFilterMode.disabled,
        reason: 'the status it had');
  });
}
