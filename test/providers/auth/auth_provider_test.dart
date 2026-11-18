import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/auth/auth_exception.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/jnap_service_supported_mocks.dart';

import '../../common/cloud_boundary.dart';
import '../../common/di.dart';
import '../../common/recording_polling.dart';
import '../../common/router_boundary.dart';

// The login as the app keeps it: the router's admin password, and the Guardian
// session a support agent logs in with. The account login (cloudLogin), its
// token refresh, raLogin and the AppRaMode branch of logout are deletion
// candidates (#1849): nothing has set AppRaMode since the PIN login pages were
// removed (bde0e5555).

String _token({
  String accessToken = 'agent-token',
  int expiresIn = 3600,
  String? refreshToken,
}) =>
    jsonEncode({
      'access_token': accessToken,
      'token_type': 'Bearer',
      'expires_in': expiresIn,
      if (refreshToken != null) 'refresh_token': refreshToken,
    });

String _now({Duration ago = Duration.zero}) =>
    '${DateTime.now().subtract(ago).millisecondsSinceEpoch}';

final _guardianSession = GRASessionInfo.fromMap(const {
  'id': 'G1',
  'serialNumber': 'SN-MASTER',
  'modelNumber': 'MX6200',
  'status': 'ACTIVE',
  'expiredIn': -600,
  'createdAt': 1722240538000,
  'statusChangedAt': 1722240574000,
  'currentTime': 1722240580739,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  mockDependencyRegister();

  late RouterBoundary router;
  late CloudBoundary cloud;
  late RecordingPolling polling;
  late ProviderContainer container;

  AuthNotifier notifier() => container.read(authProvider.notifier);
  AsyncValue<AuthState> auth() => container.read(authProvider);
  Future<String?> stored(String key) =>
      const FlutterSecureStorage().read(key: key);

  /// The extra headers of the one [action] the router received.
  Map<String, String> headersOf(JNAPAction action) => verify(router.repo.send(
        action,
        data: anyNamed('data'),
        extraHeaders: captureAnyNamed('extraHeaders'),
        auth: anyNamed('auth'),
        type: anyNamed('type'),
        fetchRemote: anyNamed('fetchRemote'),
        cacheLevel: anyNamed('cacheLevel'),
        timeoutMs: anyNamed('timeoutMs'),
        retries: anyNamed('retries'),
        sideEffectOverrides: anyNamed('sideEffectOverrides'),
      )).captured.single as Map<String, String>;

  void start({
    Map<String, String> secure = const {},
    Map<String, Object> prefs = const {},
  }) {
    FlutterSecureStorage.setMockInitialValues(Map.of(secure));
    SharedPreferences.setMockInitialValues(Map.of(prefs));
    router = RouterBoundary()
      ..holds(JNAPAction.checkAdminPassword, const {})
      ..holds(JNAPAction.pnpCheckAdminPassword, const {});
    cloud = CloudBoundary();
    polling = RecordingPolling();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      cloudRepositoryProvider
          .overrideWithValue(LinksysCloudRepository(httpClient: cloud)),
      pollingProvider.overrideWith(() => polling),
    ]);
  }

  setUp(start);

  tearDown(() {
    container.dispose();
    // AuthNotifier's constructor installs a handler on the shared client.
    LinksysHttpClient.onError = null;
  });

  group('localLogin', () {
    test('checks the admin password with it as Basic auth, and keeps it',
        () async {
      await notifier().localLogin('Linksys123!');

      expect(router.payloadsOf(JNAPAction.checkAdminPassword).single,
          {'adminPassword': 'Linksys123!'});
      expect(headersOf(JNAPAction.checkAdminPassword),
          {'X-JNAP-Authorization': 'Basic YWRtaW46TGlua3N5czEyMyE='});
      expect(auth().value?.loginType, LoginType.local);
      expect(auth().value?.localPassword, 'Linksys123!');
      expect(await stored(pLocalPassword), 'Linksys123!');
    });

    test('checks it in the body alone during setup', () async {
      await notifier().localLogin('Linksys123!', pnp: true);

      expect(router.actions, [JNAPAction.pnpCheckAdminPassword]);
      expect(headersOf(JNAPAction.pnpCheckAdminPassword), isEmpty);
      expect(auth().value?.loginType, LoginType.local);
    });

    test('keeps a refused password as the login error', () async {
      router.refuses(JNAPAction.checkAdminPassword);

      await notifier().localLogin('wrong');

      expect(auth().hasError, isTrue);
      expect(auth().error, isA<JNAPError>());
      expect(await stored(pLocalPassword), isNull);
    });

    test('throws a refused password when the caller handles it', () async {
      router.refuses(JNAPAction.checkAdminPassword);

      await expectLater(notifier().localLogin('wrong', guardError: false),
          throwsA(isA<JNAPError>()));
      expect(await stored(pLocalPassword), isNull);
    });
  });

  group('cloudLoginAuth', () {
    test('keeps the Guardian session as a remote login', () async {
      await notifier().cloudLoginAuth(
          token: 'agent-token', sn: 'SN-MASTER', sessionInfo: _guardianSession);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pCurrentSN), 'SN-MASTER');
      expect(prefs.getString(pGRASessionId), 'G1');
      final token = jsonDecode((await stored(pSessionToken))!) as Map;
      expect(token['access_token'], 'agent-token');
      expect(token['token_type'], 'Bearer');
      expect(await stored(pSessionTokenTs), isNotNull);
      expect(auth().value?.loginType, LoginType.remote);
      expect(auth().value?.sessionToken?.accessToken, 'agent-token');
    });
  });

  group('testSessionAuthentication', () {
    const session = '/cloud/v1/guardians/remote-assistances/sessions/G1';

    test('reads the Guardian session the token opens', () async {
      cloud.answers('GET', session, json: _guardianSession.toMap());

      final info = await notifier()
          .testSessionAuthentication(token: 'agent-token', session: 'G1');

      expect(info?.serialNumber, 'SN-MASTER');
      expect(cloud.requests.single.header('X-Linksys-Token'), 'agent-token');
    });

    test('reports a session the cloud does not know', () async {
      // Not INVALID_SESSION_TOKEN: the client's error handler answers that one
      // with a logout, which auth_http_error_test covers.
      cloud.answersError('GET', session, 'SESSION_NOT_FOUND');

      await expectLater(
          notifier().testSessionAuthentication(token: 'bad', session: 'G1'),
          throwsA(isA<ErrorResponse>()));
    });
  });

  group('checkSessionToken', () {
    test('returns a session token still within its time', () async {
      start(secure: {pSessionToken: _token(), pSessionTokenTs: _now()});

      final token = await notifier().checkSessionToken();

      expect(token?.accessToken, 'agent-token');
    });

    test('finds none when none is stored', () async {
      await expectLater(notifier().checkSessionToken(),
          throwsA(isA<NoSessionTokenFoundException>()));
    });

    test('says an expired token is over when it cannot be refreshed', () async {
      start(secure: {
        pSessionToken: _token(expiresIn: 60),
        pSessionTokenTs: _now(ago: const Duration(minutes: 2)),
      });

      await expectLater(notifier().checkSessionToken(),
          throwsA(isA<SessionTokenExpiredException>()));
    });

    // A token that carries a refresh token comes only from the account login,
    // a deletion candidate (#1849), so its refresh path is not tested here.

    test('handleSessionTokenError settles anything but a refresh as no token',
        () async {
      expect(
          await notifier().handleSessionTokenError(
              NoSessionTokenFoundException(), StackTrace.empty),
          isNull);
      expect(
          await notifier().handleSessionTokenError(
              SessionTokenExpiredException(), StackTrace.empty),
          isNull);
    });
  });

  group('init, at startup', () {
    test('restores a local login from the stored admin password', () async {
      start(secure: {pLocalPassword: 'Linksys123!'});

      final restored = await notifier().init();

      expect(restored?.loginType, LoginType.local);
      expect(restored?.localPassword, 'Linksys123!');
    });

    test('restores a remote login from a session token within its time',
        () async {
      start(secure: {pSessionToken: _token(), pSessionTokenTs: _now()});

      final restored = await notifier().init();

      expect(restored?.loginType, LoginType.remote);
      expect(restored?.sessionToken?.accessToken, 'agent-token');
    });

    test('falls back to the local login when the session token is over',
        () async {
      start(secure: {
        pSessionToken: _token(expiresIn: 60),
        pSessionTokenTs: _now(ago: const Duration(minutes: 2)),
        pLocalPassword: 'Linksys123!',
      });

      final restored = await notifier().init();

      expect(restored?.loginType, LoginType.local);
    });

    test('restores no login when nothing is stored', () async {
      final restored = await notifier().init();

      expect(restored?.loginType, LoginType.none);
      expect(auth().hasError, isFalse);
    });
  });

  group('logout', () {
    test('forgets the login and stops polling', () async {
      start(secure: {
        pLocalPassword: 'Linksys123!',
        pSessionToken: _token(),
        pSessionTokenTs: _now(),
        pUsername: 'owner@example.com',
        pUserPassword: 'cloud-pass',
        pLinksysToken: 'device-token',
        pLinksysTokenSN: 'SN-MASTER',
        pLinksysTokenTs: _now(),
      }, prefs: {
        pSelectedNetworkId: 'N1',
        pCurrentSN: 'SN-MASTER',
        pGRASessionId: 'G1',
        pDeviceToken: 'push-token',
      });
      container.read(selectedNetworkIdProvider.notifier).state = 'N1';

      await notifier().logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pSelectedNetworkId), isNull);
      expect(prefs.getString(pCurrentSN), isNull);
      expect(prefs.getString(pGRASessionId), isNull);
      expect(prefs.getString(pDeviceToken), isNull);
      for (final key in [
        pLocalPassword,
        pSessionToken,
        pSessionTokenTs,
        pUsername,
        pUserPassword,
        pLinksysToken,
        pLinksysTokenSN,
        pLinksysTokenTs,
      ]) {
        expect(await stored(key), isNull, reason: key);
      }
      expect(auth().value?.loginType, LoginType.none);
      expect(polling.stopped, 1);
      expect(container.read(selectedNetworkIdProvider), isNull);
    });
  });

  group('the error handler on the cloud client', () {
    // Installed by the notifier's constructor; SESSION_EXPIRED is covered by
    // auth_http_error_test.
    Future<void> cloudSays(Object error) async {
      notifier();
      LinksysHttpClient.onError!(error);
      await pumpEventQueue();
    }

    test('logs out on an invalid session token once none is stored', () async {
      start(secure: {pLocalPassword: 'Linksys123!'});

      await cloudSays(const ErrorResponse(
          status: 401,
          code: 'INVALID_SESSION_TOKEN',
          errorMessage: 'Invalid session token: agent-token'));

      expect(await stored(pLocalPassword), isNull);
      expect(polling.stopped, 1);
    });

    test('logs out when the stored token is the one turned down', () async {
      start(secure: {pSessionToken: _token(), pSessionTokenTs: _now()});

      await cloudSays(const ErrorResponse(
          status: 401,
          code: 'INVALID_SESSION_TOKEN',
          errorMessage: 'Invalid session token: agent-token'));

      expect(await stored(pSessionToken), isNull);
    });

    test('keeps a stored token other than the one turned down', () async {
      start(secure: {pSessionToken: _token(), pSessionTokenTs: _now()});

      await cloudSays(const ErrorResponse(
          status: 401,
          code: 'INVALID_SESSION_TOKEN',
          errorMessage: 'Invalid session token: an-older-token'));

      expect(await stored(pSessionToken), isNotNull);
      expect(polling.stopped, 0);
    });

    test('keeps a stored token when the message names no token', () async {
      start(secure: {pSessionToken: _token(), pSessionTokenTs: _now()});

      await cloudSays(const ErrorResponse(
          status: 401,
          code: 'INVALID_SESSION_TOKEN',
          errorMessage: 'Invalid session token'));

      expect(await stored(pSessionToken), isNotNull);
      expect(polling.stopped, 0);
    });

    test('logs out when the router turns down a login with no token', () async {
      start(secure: {pLocalPassword: 'Linksys123!'});

      await cloudSays(const JNAPError(result: '_ErrorUnauthorized'));

      expect(await stored(pLocalPassword), isNull);
    });

    test('ignores other errors', () async {
      start(secure: {pLocalPassword: 'Linksys123!'});

      await cloudSays(const JNAPError(result: 'ErrorUnknown'));
      await cloudSays(const ErrorResponse(status: 400, code: 'BAD_REQUEST'));

      expect(await stored(pLocalPassword), 'Linksys123!');
    });
  });

  group('router reads', () {
    test('getPasswordHint keeps the hint the router holds', () async {
      router.holds(JNAPAction.getAdminPasswordHint, {'passwordHint': 'pet'});
      await container.read(authProvider.future);

      await notifier().getPasswordHint();

      expect(auth().value?.localPasswordHint, 'pet');
    });

    test('getAdminPasswordAuthStatus asks a router that reports it', () async {
      final services = serviceHelper as MockServiceHelper;
      addTearDown(() => reset(services));
      when(services.isSupportAdminPasswordAuthStatus(any)).thenReturn(true);
      router.holds(
          JNAPAction.getAdminPasswordAuthStatus, {'remainingErrorAttempts': 4});

      expect(await notifier().getAdminPasswordAuthStatus(const ['x']),
          {'remainingErrorAttempts': 4});
    });

    test('getAdminPasswordAuthStatus asks nothing of a router that does not',
        () async {
      final services = serviceHelper as MockServiceHelper;
      addTearDown(() => reset(services));
      when(services.isSupportAdminPasswordAuthStatus(any)).thenReturn(false);

      expect(await notifier().getAdminPasswordAuthStatus(const ['x']), isNull);
      expect(router.actions, isEmpty);
    });

    test('getDeviceInfo reads the device info', () async {
      router.holds(JNAPAction.getDeviceInfo, const {});

      await notifier().getDeviceInfo();

      expect(router.actions, [JNAPAction.getDeviceInfo]);
    });
  });

  group('AuthState', () {
    test('reads a login written out as JSON', () {
      final state = AuthState.fromJson({
        'username': 'u',
        'localPassword': 'Linksys123!',
        'localPasswordHint': 'pet',
        'sessionToken': _token(),
        'loginType': 'remote',
      });

      expect(state.loginType, LoginType.remote);
      expect(state.localPasswordHint, 'pet');
      expect(state.sessionToken?.accessToken, 'agent-token');
    });

    test('reads an unknown login type as none', () {
      expect(AuthState.fromJson(const {'loginType': 'otp'}).loginType,
          LoginType.none);
    });

    test('isCloudLogin is true for a remote login only', () async {
      await notifier().localLogin('Linksys123!');
      expect(notifier().isCloudLogin(), isFalse);

      await notifier().cloudLoginAuth(
          token: 'agent-token', sn: 'SN-MASTER', sessionInfo: _guardianSession);
      expect(notifier().isCloudLogin(), isTrue);
    });
  });
}
