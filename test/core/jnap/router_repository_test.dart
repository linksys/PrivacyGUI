import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

// Test helper to create AuthNotifier with specific state
class TestAuthNotifier extends AuthNotifier {
  final AsyncValue<AuthState> testState;

  TestAuthNotifier(this.testState);

  @override
  Future<AuthState> build() async {
    state = testState;
    return testState.when(
      data: (data) => data,
      loading: () => AuthState.empty(),
      error: (_, __) => AuthState.empty(),
    );
  }
}

void main() {
  // Initialize JNAP action map before all tests
  setUpAll(() {
    initBetterActions();
  });

  group('RouterRepository - Remote Read-Only Mode Defensive Checks', () {
    test(
        'send() throws UnexpectedError when calling SET action in remote mode',
        () async {
      // Arrange: Create container with remote login state
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(
                const AsyncValue.data(
                  AuthState(loginType: LoginType.remote),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(routerRepositoryProvider);

      // Act & Assert: Attempt to call SET operation should throw immediately
      try {
        await repository.send(JNAPAction.setWANSettings);
        fail('Expected UnexpectedError to be thrown');
      } on UnexpectedError catch (e) {
        // Success - the defensive check caught it
        expect(
          e.message,
          'SET operations are not allowed in remote read-only mode',
        );
      } catch (e) {
        fail('Expected UnexpectedError but got: ${e.runtimeType}: $e');
      }
    });

    test('send() throws UnexpectedError for various SET operations in remote mode',
        () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(
                const AsyncValue.data(
                  AuthState(loginType: LoginType.remote),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(routerRepositoryProvider);

      // Act & Assert: Test multiple SET operations
      final setActions = [
        JNAPAction.setWANSettings,
        JNAPAction.setRadioSettings,
        JNAPAction.setGuestNetworkSettings,
        JNAPAction.setDMZSettings,
        JNAPAction.setFirewallSettings,
        JNAPAction.setDeviceProperties,
      ];

      for (final action in setActions) {
        try {
          await repository.send(action);
          fail('Expected UnexpectedError for ${action.name}');
        } on UnexpectedError catch (e) {
          // Success
          expect(e.message, contains('remote read-only'));
        } catch (e) {
          fail('Expected UnexpectedError for ${action.name} but got: ${e.runtimeType}');
        }
      }
    });

    test('send() does not throw for GET operations in remote mode', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(
                const AsyncValue.data(
                  AuthState(loginType: LoginType.remote),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(routerRepositoryProvider);

      // Act & Assert: GET operations should NOT throw our defensive error
      // They will fail later due to lack of network/bindings, but that's expected
      try {
        await repository.send(JNAPAction.getWANSettings);
        fail('Expected error due to missing network, but got success');
      } on UnexpectedError catch (e) {
        if (e.message?.contains('remote read-only') ?? false) {
          fail('GET operation should not be blocked by defensive check');
        }
        // Other UnexpectedErrors are OK (missing network, etc)
      } catch (e) {
        // Expected: Will fail due to missing network/SharedPreferences/etc
        // But NOT because of our remote read-only check
        expect(e, isNot(isA<UnexpectedError>()));
      }
    });

    test('send() allows SET operations in local mode', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(
                const AsyncValue.data(
                  AuthState(loginType: LoginType.local),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(routerRepositoryProvider);

      // Act & Assert: SET operations in local mode should NOT throw our defensive error
      try {
        await repository.send(JNAPAction.setWANSettings);
        fail('Expected error due to missing network, but got success');
      } on UnexpectedError catch (e) {
        if (e.message?.contains('remote read-only') ?? false) {
          fail('SET operation in local mode should not be blocked');
        }
        // Other UnexpectedErrors are OK
      } catch (e) {
        // Expected: Will fail due to missing network/SharedPreferences/etc
        // But NOT because of our remote read-only check
        expect(e, isNot(isA<UnexpectedError>().having(
          (e) => e.message,
          'message',
          contains('remote read-only'),
        )));
      }
    });

    test('send() allows non-SET operations in remote mode', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(
                const AsyncValue.data(
                  AuthState(loginType: LoginType.remote),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(routerRepositoryProvider);

      // Act & Assert: Non-SET operations should NOT throw our defensive error
      try {
        await repository.send(JNAPAction.reboot);
        fail('Expected error due to missing network, but got success');
      } on UnexpectedError catch (e) {
        if (e.message?.contains('remote read-only') ?? false) {
          fail('Non-SET operation should not be blocked');
        }
      } catch (e) {
        // Expected: Will fail due to missing network/SharedPreferences/etc
      }
    });

    test(
        'transaction() throws UnexpectedError when transaction contains SET operation in remote mode',
        () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(
                const AsyncValue.data(
                  AuthState(loginType: LoginType.remote),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(routerRepositoryProvider);
      final builder = JNAPTransactionBuilder(commands: [
        MapEntry(JNAPAction.getWANSettings, {}),
        MapEntry(JNAPAction.setWANSettings, {'test': 'data'}),
      ]);

      // Act & Assert
      try {
        await repository.transaction(builder);
        fail('Expected UnexpectedError to be thrown');
      } on UnexpectedError catch (e) {
        expect(
          e.message,
          'SET operations are not allowed in remote read-only mode',
        );
      } catch (e) {
        fail('Expected UnexpectedError but got: ${e.runtimeType}: $e');
      }
    });

    test(
        'transaction() throws UnexpectedError even if SET operation is not the first command',
        () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(
                const AsyncValue.data(
                  AuthState(loginType: LoginType.remote),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(routerRepositoryProvider);
      final builder = JNAPTransactionBuilder(commands: [
        MapEntry(JNAPAction.getDeviceInfo, {}),
        MapEntry(JNAPAction.getWANSettings, {}),
        MapEntry(JNAPAction.setRadioSettings, {'test': 'data'}),
      ]);

      // Act & Assert
      try {
        await repository.transaction(builder);
        fail('Expected UnexpectedError to be thrown');
      } on UnexpectedError catch (e) {
        expect(e.message, contains('remote read-only'));
      } catch (e) {
        fail('Expected UnexpectedError but got: ${e.runtimeType}');
      }
    });

    test('transaction() allows only GET operations in remote mode', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(
                const AsyncValue.data(
                  AuthState(loginType: LoginType.remote),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(routerRepositoryProvider);
      final builder = JNAPTransactionBuilder(commands: [
        MapEntry(JNAPAction.getWANSettings, {}),
        MapEntry(JNAPAction.getDeviceInfo, {}),
        MapEntry(JNAPAction.getRadioInfo, {}),
      ]);

      // Act & Assert: Should NOT throw our defensive error
      try {
        await repository.transaction(builder);
        fail('Expected error due to missing network, but got success');
      } on UnexpectedError catch (e) {
        if (e.message?.contains('remote read-only') ?? false) {
          fail('GET-only transaction should not be blocked');
        }
      } catch (e) {
        // Expected: Will fail due to missing network/SharedPreferences/etc
      }
    });

    test('transaction() allows SET operations in local mode', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(
                const AsyncValue.data(
                  AuthState(loginType: LoginType.local),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(routerRepositoryProvider);
      final builder = JNAPTransactionBuilder(commands: [
        MapEntry(JNAPAction.getWANSettings, {}),
        MapEntry(JNAPAction.setWANSettings, {'test': 'data'}),
        MapEntry(JNAPAction.setRadioSettings, {'test': 'data'}),
      ]);

      // Act & Assert: Should NOT throw our defensive error in local mode
      try {
        await repository.transaction(builder);
        fail('Expected error due to missing network, but got success');
      } on UnexpectedError catch (e) {
        if (e.message?.contains('remote read-only') ?? false) {
          fail('SET operations in local mode should not be blocked');
        }
      } catch (e) {
        // Expected: Will fail due to missing network/SharedPreferences/etc
        expect(e, isNot(isA<UnexpectedError>().having(
          (e) => e.message,
          'message',
          contains('remote read-only'),
        )));
      }
    });
  });
}
