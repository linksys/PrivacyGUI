import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// The real notifier, whose constructor installs the HTTP error handler under
/// test, with only its starting login fixed.
class _Auth extends AuthNotifier {
  _Auth(this.loginType);
  final LoginType loginType;

  @override
  Future<AuthState> build() async => AuthState(loginType: loginType);
}

/// Records whether the session was marked ended, and touches nothing else.
class _RecordingRemoteClient extends RemoteClientNotifier {
  int expiries = 0;

  @override
  RemoteClientState build() => const RemoteClientState();

  @override
  void markSessionExpired() => expiries++;
}

void main() {
  late _RecordingRemoteClient remoteClient;

  Future<void> loginAs(LoginType loginType) async {
    remoteClient = _RecordingRemoteClient();
    final container = ProviderContainer(overrides: [
      authProvider.overrideWith(() => _Auth(loginType)),
      remoteClientProvider.overrideWith(() => remoteClient),
    ]);
    addTearDown(container.dispose);
    // Building the notifier is what installs LinksysHttpClient.onError.
    await container.read(authProvider.future);
  }

  /// The handler is fire-and-forget (`void`), as the HTTP client calls it;
  /// let whatever it started run out before looking.
  Future<void> cloudRefuses(Object error) async {
    LinksysHttpClient.onError!(error);
    await pumpEventQueue();
  }

  ErrorResponse sessionExpired() => ErrorResponse.fromJson(400, {
        'code': 'SESSION_EXPIRED',
        'errorMessage': 'Remote Assistance session has expired',
        'parameters': [],
      });

  tearDown(() => LinksysHttpClient.onError = null);

  // #1637: once a session has ended the cloud refuses every call made through
  // it with SESSION_EXPIRED. That is the earliest sign the session is over.
  group('SESSION_EXPIRED from the cloud', () {
    test('ends the session on a remote login', () async {
      await loginAs(LoginType.remote);

      await cloudRefuses(sessionExpired());

      expect(remoteClient.expiries, 1);
    });

    // remoteClientProvider is shared with the client's own session; a local
    // login has no Guardian session for this to end.
    test('is ignored on a local login', () async {
      await loginAs(LoginType.local);

      await cloudRefuses(sessionExpired());

      expect(remoteClient.expiries, 0);
    });

    test('is ignored with nobody logged in', () async {
      await loginAs(LoginType.none);

      await cloudRefuses(sessionExpired());

      expect(remoteClient.expiries, 0);
    });

    test('is passed on every time, leaving the bursts to the session',
        () async {
      await loginAs(LoginType.remote);

      await cloudRefuses(sessionExpired());
      await cloudRefuses(sessionExpired());

      expect(remoteClient.expiries, 2,
          reason: 'markSessionExpired is what makes a burst harmless');
    });
  });

  group('other errors leave the session alone', () {
    test('a different cloud error', () async {
      await loginAs(LoginType.remote);

      await cloudRefuses(
          const ErrorResponse(status: 1000, code: 'REQUEST_TIMEOUT'));

      expect(remoteClient.expiries, 0);
    });

    test('a router result that happens to read SESSION_EXPIRED', () async {
      await loginAs(LoginType.remote);

      await cloudRefuses(const JNAPError(result: 'SESSION_EXPIRED'));

      expect(remoteClient.expiries, 0,
          reason: 'only the cloud can end a remote session');
    });
  });
}
