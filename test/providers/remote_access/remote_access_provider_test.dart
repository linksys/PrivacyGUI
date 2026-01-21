import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';

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
  group('remoteAccessProvider', () {
    test('returns isRemoteReadOnly true when loginType is remote', () {
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

      // Act
      final state = container.read(remoteAccessProvider);

      // Assert
      expect(state.isRemoteReadOnly, true);
    });

    test('returns isRemoteReadOnly false when loginType is local', () {
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

      // Act
      final state = container.read(remoteAccessProvider);

      // Assert
      expect(state.isRemoteReadOnly, false);
    });

    test('returns isRemoteReadOnly false when loginType is none', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(
                const AsyncValue.data(
                  AuthState(loginType: LoginType.none),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final state = container.read(remoteAccessProvider);

      // Assert
      expect(state.isRemoteReadOnly, false);
    });

    test('returns isRemoteReadOnly true when forceCommandType is remote', () {
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

      // Act
      final state = container.read(remoteAccessProvider);

      // Assert
      // If BuildConfig.forceCommandType is ForceCommand.remote, this should be true
      // Otherwise, it should be false (based on loginType.local)
      expect(
        state.isRemoteReadOnly,
        BuildConfig.forceCommandType == ForceCommand.remote,
      );
    });

    test('handles authProvider loading state gracefully', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
              () => TestAuthNotifier(const AsyncValue.loading())),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final state = container.read(remoteAccessProvider);

      // Assert
      // Should default to false when auth is loading
      expect(state.isRemoteReadOnly, false);
    });

    test('handles authProvider error state gracefully', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(AsyncValue.error(
                Exception('Auth error'),
                StackTrace.current,
              ))),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final state = container.read(remoteAccessProvider);

      // Assert
      // Should default to false when auth has error
      expect(state.isRemoteReadOnly, false);
    });
  });
}
