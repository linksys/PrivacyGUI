// Unit tests for InstantPrivacyNotifier's reads after a poll (#1834).
//
// The notifier reads its status when polling signals a completed poll
// (pollCompletedProvider), instead of being called by polling. The router is a
// MockRouterRepository, so what the notifier sends is observable.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

import '../../../common/di.dart';
import '../../../mocks/router_repository_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  mockDependencyRegister();

  late MockRouterRepository repo;
  late ProviderContainer container;
  late List<JNAPAction> sends;

  /// What the router answers to getMACFilterSettings.
  late Future<JNAPSuccess> Function() macFilterSettings;

  JNAPSuccess macFilter(String mode) => JNAPSuccess(result: 'OK', output: {
        'macFilterMode': mode,
        'maxMACAddresses': 32,
        'macAddresses': const <String>[],
      });

  int reads() =>
      sends.where((action) => action == JNAPAction.getMACFilterSettings).length;

  setUp(() {
    initBetterActions();
    sends = [];
    macFilterSettings = () async => macFilter('Disabled');
    repo = MockRouterRepository();
    when(repo.send(
      any,
      data: anyNamed('data'),
      extraHeaders: anyNamed('extraHeaders'),
      auth: anyNamed('auth'),
      type: anyNamed('type'),
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((invocation) {
      final action = invocation.positionalArguments.first as JNAPAction;
      sends.add(action);
      if (action == JNAPAction.getMACFilterSettings) return macFilterSettings();
      // getLocalDevice: answering with an error keeps the device list out of
      // these tests; the notifier then knows no MAC address of its own.
      return Future.error(const JNAPError(result: '_ErrorUnknownAction'));
    });
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  /// Builds the notifier, as a screen that shows it does, and lets its own
  /// first read finish.
  Future<void> build() async {
    container.read(instantPrivacyProvider);
    await pumpEventQueue();
  }

  test('a completed poll reads the status', () async {
    await build();
    final before = reads();
    macFilterSettings = () async => macFilter('Allow');

    container.read(pollCompletedProvider.notifier).state++;
    await pumpEventQueue();

    expect(reads(), before + 1);
    expect(container.read(instantPrivacyProvider).status.mode,
        MacFilterMode.allow);
  });

  test('a failed read after a poll stays with Instant Privacy', () async {
    // An error that escaped the listener would fail this test as an uncaught
    // error, and in the app it would never reach polling either way.
    await build();
    macFilterSettings =
        () async => throw const JNAPError(result: '_ErrorUnexpected');

    container.read(pollCompletedProvider.notifier).state++;
    await pumpEventQueue();

    expect(container.read(instantPrivacyProvider).status.mode,
        MacFilterMode.disabled,
        reason: 'the status it had');
  });
}
