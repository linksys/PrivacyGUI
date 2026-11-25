import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_admin/providers/router_password_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/router_password_state.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../../common/router_boundary.dart';

/// A local login with [_currentPassword], as the app holds it after login.
class _LoggedIn extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthState(
        loginType: LoginType.local,
        localPassword: _currentPassword,
      );
}

const _currentPassword = 'Current-Pass1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RouterBoundary router;
  late ProviderContainer container;

  RouterPasswordNotifier notifier() =>
      container.read(routerPasswordProvider.notifier);
  RouterPasswordState page() => container.read(routerPasswordProvider);

  /// The router's answers to `IsAdminPasswordSetByUser` and
  /// `IsAdminPasswordDefault`.
  void routerPassword({required bool setByUser, required bool isDefault}) {
    router
      ..holds(JNAPAction.isAdminPasswordSetByUser,
          {'isAdminPasswordSetByUser': setByUser})
      ..holds(JNAPAction.isAdminPasswordDefault,
          {'isAdminPasswordDefault': isDefault});
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(
        {pLocalPassword: _currentPassword});
    router = RouterBoundary()
      ..holds(JNAPAction.getAdminPasswordHint, {'passwordHint': 'pet name'})
      ..holds(JNAPAction.coreSetAdminPassword, {})
      ..holds(JNAPAction.checkAdminPassword, {});
    routerPassword(setByUser: true, isDefault: false);
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      authProvider.overrideWith(_LoggedIn.new),
    ]);
    await container.read(authProvider.future);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('reads a password the user set, with its hint', () async {
      await notifier().fetch();

      expect(page().isSetByUser, isTrue);
      expect(page().isDefault, isFalse);
      expect(page().hint, 'pet name');
      expect(page().adminPassword, _currentPassword);
    });

    test('asks for no hint when the user never set a password', () async {
      routerPassword(setByUser: false, isDefault: true);

      await notifier().fetch();

      expect(page().isSetByUser, isFalse);
      expect(page().isDefault, isTrue);
      expect(page().hint, '');
      expect(router.actions, isNot(contains(JNAPAction.getAdminPasswordHint)));
    });

    test('shows no hint when the router will not give one', () async {
      router.refuses(JNAPAction.getAdminPasswordHint);

      await notifier().fetch();

      expect(page().hint, '');
      expect(page().isSetByUser, isTrue);
    });

    test('shows an empty password when none is stored', () async {
      FlutterSecureStorage.setMockInitialValues({});

      await notifier().fetch();

      expect(page().adminPassword, '');
    });
  });

  group('setAdminPasswordWithCredentials', () {
    setUp(() => notifier().fetch());

    test('writes the new password and hint, then logs in with it', () async {
      await notifier().setAdminPasswordWithCredentials('New-Pass1!', 'my cat');

      expect(router.payloadsOf(JNAPAction.coreSetAdminPassword).single, {
        'adminPassword': 'New-Pass1!',
        'passwordHint': 'my cat',
      });
      expect(router.payloadsOf(JNAPAction.checkAdminPassword).single,
          {'adminPassword': 'New-Pass1!'});
      expect(container.read(authProvider).value?.localPassword, 'New-Pass1!');
    });

    test('keeps the hint it read when it is given none', () async {
      await notifier().setAdminPasswordWithCredentials('New-Pass1!');

      expect(
          router
              .payloadsOf(JNAPAction.coreSetAdminPassword)
              .single['passwordHint'],
          'pet name');
    });

    test('writes the password of the current login when it is given none',
        () async {
      await notifier().setAdminPasswordWithCredentials(null, 'my cat');

      expect(router.payloadsOf(JNAPAction.coreSetAdminPassword).single, {
        'adminPassword': _currentPassword,
        'passwordHint': 'my cat',
      });
    });

    test('reads the settings back from the router after the save', () async {
      router.holds(JNAPAction.getAdminPasswordHint, {'passwordHint': 'my cat'});

      await notifier().setAdminPasswordWithCredentials('New-Pass1!', 'my cat');

      expect(page().hint, 'my cat');
      expect(page().adminPassword, 'New-Pass1!');
    });

    test('a refused password throws and logs in with nothing', () async {
      router.refuses(JNAPAction.coreSetAdminPassword,
          result: 'ErrorInvalidPassword');

      await expectLater(
          notifier().setAdminPasswordWithCredentials('short', 'my cat'),
          throwsA(isA<JNAPError>()
              .having((e) => e.result, 'result', 'ErrorInvalidPassword')));

      expect(router.actions, isNot(contains(JNAPAction.checkAdminPassword)));
      expect(page().adminPassword, _currentPassword);
      expect(
          container.read(authProvider).value?.localPassword, _currentPassword);
    });
  });

  group('setAdminPasswordWithResetCode', () {
    test('writes the password and hint with the recovery code', () async {
      await notifier()
          .setAdminPasswordWithResetCode('New-Pass1!', 'my cat', '12345');

      expect(router.payloadsOf(JNAPAction.setupSetAdminPassword).single, {
        'adminPassword': 'New-Pass1!',
        'passwordHint': 'my cat',
        'resetCode': '12345',
      });
    });

    test('a refused code throws', () async {
      router.refuses(JNAPAction.setupSetAdminPassword,
          result: 'ErrorInvalidResetCode');

      await expectLater(
          notifier().setAdminPasswordWithResetCode('New-Pass1!', '', '00000'),
          throwsA(isA<JNAPError>()));
    });
  });

  group('checkRecoveryCode', () {
    /// The router's answer to a wrong code: JNAPError carries its output
    /// JSON-encoded in `error`.
    JNAPError wrongCode(int attemptsRemaining) => JNAPError(
          result: errorInvalidResetCode,
          error: jsonEncode({'attemptsRemaining': attemptsRemaining}),
        );

    test('accepts the code the router accepts', () async {
      router.holds(JNAPAction.verifyRouterResetCode, {});

      expect(await notifier().checkRecoveryCode('12345'), isTrue);
      expect(router.payloadsOf(JNAPAction.verifyRouterResetCode).single,
          {'resetCode': '12345'});
      expect(page().remainingErrorAttempts, isNull);
    });

    test('counts the attempts left after a wrong code', () async {
      router.holdsInTurn(JNAPAction.verifyRouterResetCode, [wrongCode(2)]);

      expect(await notifier().checkRecoveryCode('00000'), isFalse);
      expect(page().remainingErrorAttempts, 2);
    });

    test('shows no attempts left once the router locks the code', () async {
      router.refuses(JNAPAction.verifyRouterResetCode,
          result: errorConsecutiveInvalidResetCodeEntered);

      expect(await notifier().checkRecoveryCode('00000'), isFalse);
      expect(page().remainingErrorAttempts, 0);
    });

    test('rejects the code without a count when the router gives none',
        () async {
      // A wrong code with no output: JNAPError puts the result code in
      // `error`, which is not JSON.
      router.refuses(JNAPAction.verifyRouterResetCode,
          result: errorInvalidResetCode);

      expect(await notifier().checkRecoveryCode('00000'), isFalse);
      expect(page().remainingErrorAttempts, isNull);
    });

    test('rejects the code on any other error, counting nothing', () async {
      router.refuses(JNAPAction.verifyRouterResetCode);

      expect(await notifier().checkRecoveryCode('00000'), isFalse);
      expect(page().remainingErrorAttempts, isNull);
    });

    test('a right code after a wrong one clears the count', () async {
      router.holdsInTurn(JNAPAction.verifyRouterResetCode,
          [wrongCode(4), <String, dynamic>{}]);

      await notifier().checkRecoveryCode('00000');
      expect(page().remainingErrorAttempts, 4);

      expect(await notifier().checkRecoveryCode('12345'), isTrue);
      expect(page().remainingErrorAttempts, isNull);
    });
  });
}
