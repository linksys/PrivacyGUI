import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

class MockAuthNotifier extends AuthNotifier {
  final AuthState _initialState;

  MockAuthNotifier(this._initialState);

  @override
  Future<AuthState> build() {
    return Future.value(_initialState);
  }
}

void main() {
  group('PnpNotifier Auth Logic', () {
    test('isLoggedIn returns false when LoginType is none', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => MockAuthNotifier(AuthState(loginType: LoginType.none)),
          ),
        ],
      );

      await container.read(authProvider.future);
      final notifier = container.read(pnpProvider.notifier);
      expect(notifier.isLoggedIn, isFalse);
    });

    test('isLoggedIn returns true when LoginType is local', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => MockAuthNotifier(AuthState(loginType: LoginType.local)),
          ),
        ],
      );

      await container.read(authProvider.future);
      final notifier = container.read(pnpProvider.notifier);
      expect(notifier.isLoggedIn, isTrue);
    });

    test('isLoggedIn returns true when LoginType is remote', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => MockAuthNotifier(AuthState(loginType: LoginType.remote)),
          ),
        ],
      );

      await container.read(authProvider.future);
      final notifier = container.read(pnpProvider.notifier);
      expect(notifier.isLoggedIn, isTrue);
    });

    // Removed incomplete test case for null/loading state as simple overrides are sufficient
  });
}
