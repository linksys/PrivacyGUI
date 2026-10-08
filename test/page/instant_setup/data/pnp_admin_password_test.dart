// Tests for the PnP save path's admin-password decision.
//
// The save transaction may skip PnpSetAdminPassword to avoid overwriting a
// password a first-boot hook already imported. That decision reads the router's
// own answer, and the router can fail to answer at exactly the wrong moment:
// the query fires while the local network is about to be reconfigured, which is
// when JNAP calls are least reliable. If an unanswerable query counted as
// "already set", an unconfigured router would finish PnP as Master with its
// admin password still at the factory default, and the post-save verification
// would be skipped too, so nothing downstream would notice.
//
// Two things are pinned here: the decision falls the safe way on an unknown
// answer, and the routing-facing isRouterPasswordSet() keeps its opposite
// fallback, because guessing "not set" there would bounce a configured router
// back into PnP.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';

import '../../../mocks/router_repository_mocks.dart';

JNAPTransactionSuccessWrap _passwordAnswer({
  required bool isDefault,
  required bool setByUser,
}) =>
    JNAPTransactionSuccessWrap(result: 'OK', data: [
      MapEntry(
        JNAPAction.isAdminPasswordDefault,
        JNAPSuccess(
            result: 'OK', output: {'isAdminPasswordDefault': isDefault}),
      ),
      MapEntry(
        JNAPAction.isAdminPasswordSetByUser,
        JNAPSuccess(
            result: 'OK', output: {'isAdminPasswordSetByUser': setByUser}),
      ),
    ]);

void main() {
  group('shouldPreserveExistingAdminPassword', () {
    test('does not preserve when the router could not be asked', () {
      // The whole point: null is not "yes".
      expect(
        shouldPreserveExistingAdminPassword(
          isRouterUnconfigured: true,
          routerPasswordSet: null,
        ),
        isFalse,
      );
    });

    test('preserves only when the router says a password is set', () {
      expect(
        shouldPreserveExistingAdminPassword(
          isRouterUnconfigured: true,
          routerPasswordSet: true,
        ),
        isTrue,
      );
      expect(
        shouldPreserveExistingAdminPassword(
          isRouterUnconfigured: true,
          routerPasswordSet: false,
        ),
        isFalse,
      );
    });

    test('never preserves for an already-configured router', () {
      // A configured router takes the acknowledgement command instead, so this
      // flag has no business being true regardless of the password answer.
      for (final answer in [true, false, null]) {
        expect(
          shouldPreserveExistingAdminPassword(
            isRouterUnconfigured: false,
            routerPasswordSet: answer,
          ),
          isFalse,
          reason: 'routerPasswordSet: $answer',
        );
      }
    });
  });

  group('isRouterPasswordSet', () {
    late MockRouterRepository mockRepo;
    late ProviderContainer container;
    late PnpNotifier notifier;

    setUp(() {
      mockRepo = MockRouterRepository();
      container = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      notifier = container.read(pnpProvider.notifier) as PnpNotifier;
    });

    tearDown(() {
      container.dispose();
    });

    void whenTransaction(Future<JNAPTransactionSuccessWrap> Function() answer) {
      when(mockRepo.transaction(
        any,
        fetchRemote: anyNamed('fetchRemote'),
        cacheLevel: anyNamed('cacheLevel'),
        timeoutMs: anyNamed('timeoutMs'),
        retries: anyNamed('retries'),
        sideEffectOverrides: anyNamed('sideEffectOverrides'),
      )).thenAnswer((_) => answer());
    }

    test(
        'reports set when the query fails, so routing does not bounce a '
        'configured router into PnP', () async {
      whenTransaction(
          () => Future.error(const JNAPError(result: 'ErrorTimeout')));

      await expectLater(notifier.isRouterPasswordSet(), completion(isTrue));
    });

    test('reports the router answer when the query succeeds', () async {
      whenTransaction(
          () async => _passwordAnswer(isDefault: true, setByUser: false));
      await expectLater(notifier.isRouterPasswordSet(), completion(isFalse));

      whenTransaction(
          () async => _passwordAnswer(isDefault: false, setByUser: false));
      await expectLater(notifier.isRouterPasswordSet(), completion(isTrue));

      whenTransaction(
          () async => _passwordAnswer(isDefault: true, setByUser: true));
      await expectLater(notifier.isRouterPasswordSet(), completion(isTrue));
    });
  });
}
