import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/components/layouts/root_container.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/router_repository_mocks.dart';

const _needsRouterAi =
    'Router AI paths: run with --dart-define=enable_router_ai=true';

class _RecordingAiSessionService implements AiSessionService {
  _RecordingAiSessionService({this.result = true});

  final bool result;
  final List<String> bootstraps = [];
  int logouts = 0;

  @override
  Future<bool> bootstrap(String adminPassword) async {
    bootstraps.add(adminPassword);
    return result;
  }

  @override
  Future<void> logout() async {
    logouts++;
  }

  @override
  void close() {}
}

void stubLogin(MockRouterRepository router, String result) {
  when(router.send(
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
  )).thenAnswer((_) async => JNAPSuccess(result: result));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // These exercise the AI paths in AuthNotifier, which exist only in a
  // Router AI build. Run with --dart-define=enable_router_ai=true.
  group('Router AI build', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
    });

    test('successful router login bootstraps the AI cookie once', () async {
      final router = MockRouterRepository();
      final aiSession = _RecordingAiSessionService();
      stubLogin(router, jnapResultOk);
      final container = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router),
        aiSessionServiceProvider.overrideWithValue(aiSession),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      await container
          .read(authProvider.notifier)
          .localLogin('CandidateSecret!');

      expect(aiSession.bootstraps, ['CandidateSecret!']);
      expect(container.read(authProvider).value?.loginType, LoginType.local);
    });

    test('AI bootstrap outage does not invalidate a successful router login',
        () async {
      final router = MockRouterRepository();
      final aiSession = _RecordingAiSessionService(result: false);
      stubLogin(router, jnapResultOk);
      final container = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router),
        aiSessionServiceProvider.overrideWithValue(aiSession),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      await container
          .read(authProvider.notifier)
          .localLogin('CandidateSecret!');

      expect(container.read(authProvider).hasError, isFalse);
      expect(container.read(authProvider).value?.loginType, LoginType.local);
    });

    test('UI idle logout revokes the AI session through the shared logout path',
        () async {
      final router = MockRouterRepository();
      final aiSession = _RecordingAiSessionService();
      stubLogin(router, jnapResultOk);
      final container = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router),
        aiSessionServiceProvider.overrideWithValue(aiSession),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      await container
          .read(authProvider.notifier)
          .localLogin('CandidateSecret!');
      await container.read(idleLogoutProvider)();

      expect(aiSession.logouts, 1);
      expect(container.read(authProvider).value?.loginType, LoginType.none);
      expect(
          container.read(uiIdleDurationProvider), const Duration(minutes: 15));
    });

    // init() runs at startup (app.dart) and on every router redirect
    // (router_provider.dart _authCheck). Only the first may touch the AI
    // session, or each navigation re-posts the admin password.
    test('repeated init() with a saved login bootstraps the AI session once',
        () async {
      FlutterSecureStorage.setMockInitialValues(
          {pLocalPassword: 'CandidateSecret!'});
      final router = MockRouterRepository();
      final aiSession = _RecordingAiSessionService();
      stubLogin(router, jnapResultOk);
      final container = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router),
        aiSessionServiceProvider.overrideWithValue(aiSession),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      final auth = container.read(authProvider.notifier);
      // Startup and the first redirect race; later redirects follow.
      await Future.wait([auth.init(), auth.init()]);
      await auth.init();
      await auth.init();

      expect(aiSession.bootstraps, ['CandidateSecret!']);
      expect(aiSession.logouts, 0);
      expect(container.read(authProvider).value?.loginType, LoginType.local);
    });

    test(
        'repeated init() without a saved login revokes a stale AI session once',
        () async {
      final router = MockRouterRepository();
      final aiSession = _RecordingAiSessionService();
      stubLogin(router, jnapResultOk);
      final container = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router),
        aiSessionServiceProvider.overrideWithValue(aiSession),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      final auth = container.read(authProvider.notifier);
      await Future.wait([auth.init(), auth.init()]);
      await auth.init();

      expect(aiSession.logouts, 1);
      expect(aiSession.bootstraps, isEmpty);
    });

    // Logout clears AuthState before it deletes the stored password, so a
    // router re-check can run in that gap. It must not start a new AI
    // session, and the logout must still win.
    for (final order in ['init started first', 'logout started first']) {
      test(
          'logout racing a router re-check never restarts the AI session '
          '($order)', () async {
        final router = MockRouterRepository();
        final aiSession = _RecordingAiSessionService();
        stubLogin(router, jnapResultOk);
        final container = ProviderContainer(overrides: [
          routerRepositoryProvider.overrideWithValue(router),
          aiSessionServiceProvider.overrideWithValue(aiSession),
        ]);
        addTearDown(container.dispose);

        await container.read(authProvider.future);
        final auth = container.read(authProvider.notifier);
        await auth.init(); // app startup, before any login
        await auth.localLogin('CandidateSecret!');
        expect(aiSession.bootstraps, ['CandidateSecret!']);

        final racing = order == 'init started first'
            ? [auth.init(), auth.logout()]
            : [auth.logout(), auth.init()];
        await Future.wait(racing);

        expect(aiSession.bootstraps, ['CandidateSecret!'],
            reason: 'no AI bootstrap after logout');
        expect(aiSession.logouts, greaterThanOrEqualTo(1));
        expect(await const FlutterSecureStorage().read(key: pLocalPassword),
            isNull);
        expect(container.read(authProvider).value?.loginType, LoginType.none);
      });
    }
  }, skip: BuildConfig.enableRouterAi ? false : _needsRouterAi);
}
