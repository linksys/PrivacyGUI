import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/usp_auth_ready_provider.dart';

class MockUspClient extends Mock implements UspClient {}

class _AuthNotifier extends AsyncNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  _AuthNotifier(this._loginType);

  final LoginType _loginType;

  @override
  Future<AuthState> build() async => AuthState(loginType: _loginType);
}

void main() {
  late MockUspClient mockUsp;

  setUp(() {
    mockUsp = MockUspClient();
  });

  ProviderContainer createContainer({
    required LoginType loginType,
    UspClient? usp,
  }) {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _AuthNotifier(loginType)),
        uspClientProvider.overrideWithValue(usp),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<bool> readReady(ProviderContainer container) async {
    // authProvider.build is async — let it settle before reading.
    await container.read(authProvider.future);
    return container.read(uspAuthReadyProvider);
  }

  group('uspAuthReadyProvider', () {
    test('RA session is ready even when usp.isAuthenticated is false (#1119)',
        () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      final container =
          createContainer(loginType: LoginType.remote, usp: mockUsp);

      expect(await readReady(container), isTrue);
    });

    test('local login with authenticated client is ready', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      final container =
          createContainer(loginType: LoginType.local, usp: mockUsp);

      expect(await readReady(container), isTrue);
    });

    test('logged out with unauthenticated client is not ready', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      final container =
          createContainer(loginType: LoginType.none, usp: mockUsp);

      expect(await readReady(container), isFalse);
    });

    test('null client, non-RA is not ready', () async {
      final container = createContainer(loginType: LoginType.local, usp: null);

      expect(await readReady(container), isFalse);
    });

    test('null client, RA is still ready (authToken bypass)', () async {
      final container = createContainer(loginType: LoginType.remote, usp: null);

      expect(await readReady(container), isTrue);
    });
  });
}
