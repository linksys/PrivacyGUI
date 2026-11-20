// PnP's admin password check against CheckAdminPassword3.
//
// On core7 firmware `pnpCheckAdminPassword` resolves to CheckAdminPassword3
// (better_action.dart). linksys/JNAP's core.hsl gives it its own results: a
// wrong password is ErrorInvalidAdminPassword, carrying attemptsRemaining and
// delayTimeRemaining, where CheckAdminPassword2 answers _ErrorUnauthorized.
// PnP's callers, the post-save candidate loop among them, recognise a wrong
// password only as ExceptionInvalidAdminPassword, so checkAdminPassword has to
// raise that whichever action the firmware runs.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';

import '../../../mocks/router_repository_mocks.dart';

void main() {
  late MockRouterRepository router;
  late ProviderContainer container;

  setUp(() {
    router = MockRouterRepository();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router),
    ]);
  });

  tearDown(() => container.dispose());

  void answerPasswordCheck(JNAPError error) {
    when(router.send(
      JNAPAction.pnpCheckAdminPassword,
      data: anyNamed('data'),
      extraHeaders: anyNamed('extraHeaders'),
      auth: anyNamed('auth'),
      type: anyNamed('type'),
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((_) async => throw error);
  }

  test('a wrong password on CheckAdminPassword3 is an invalid admin password',
      () async {
    // The shape JNAPError.fromJson gives the router's answer: the output's
    // attempt and delay counters arrive JSON-encoded in `error`.
    answerPasswordCheck(const JNAPError(
      result: errorInvalidAdminPassword,
      error: '{"attemptsRemaining":4,"delayTimeRemaining":5}',
    ));

    await expectLater(
      container.read(pnpProvider.notifier).checkAdminPassword('a-wrong-guess'),
      throwsA(isA<ExceptionInvalidAdminPassword>()),
    );
  });
}
