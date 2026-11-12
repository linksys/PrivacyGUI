import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service.dart';
import 'package:privacy_gui/core/ai_session/router_ai_loader.dart';
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

    // A logout during the FIRST init() of a launch (for example onError →
    // logout() when the stored password is rejected) must not let that init()
    // bootstrap the stored password after the AI logout.
    for (final order in ['init started first', 'logout started first']) {
      test(
          'logout during the first init() of a launch never bootstraps the '
          'stored password ($order)', () async {
        FlutterSecureStorage.setMockInitialValues(
            {pLocalPassword: 'StaleSecret!'});
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
        final racing = order == 'init started first'
            ? [auth.init(), auth.logout()]
            : [auth.logout(), auth.init()];
        await Future.wait(racing);

        expect(aiSession.bootstraps, isEmpty,
            reason: 'no AI bootstrap after logout');
        expect(aiSession.logouts, greaterThanOrEqualTo(1));
        expect(await const FlutterSecureStorage().read(key: pLocalPassword),
            isNull);
        expect(container.read(authProvider).value?.loginType, LoginType.none);
      });
    }
  }, skip: BuildConfig.enableRouterAi ? false : _needsRouterAi);

  // The widget (chat bubble, sidebar, manual-login card) must never be on the
  // login screen. It is shown only after the router login AND the AI session
  // bootstrap have both succeeded.
  group('Router AI widget is shown only after login', () {
    late int widgetLoads;
    late MockRouterRepository router;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      widgetLoads = 0;
      router = MockRouterRepository();
      stubLogin(router, jnapResultOk);
    });

    ProviderContainer containerWith(AiSessionService aiSession) {
      final container = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router),
        aiSessionServiceProvider.overrideWithValue(aiSession),
        routerAiLoaderProvider.overrideWithValue(() {
          widgetLoads++;
          return true;
        }),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('startup on the login screen never shows the widget', () async {
      final container = containerWith(_RecordingAiSessionService());

      await container.read(authProvider.future);
      final auth = container.read(authProvider.notifier);
      await Future.wait([auth.init(), auth.init()]);
      await auth.init();
      await pumpEventQueue();

      expect(widgetLoads, 0);
    });

    test('a rejected router password never shows the widget', () async {
      stubLogin(router, errorInvalidAdminPassword);
      final aiSession = _RecordingAiSessionService();
      final container = containerWith(aiSession);

      await container.read(authProvider.future);
      await container.read(authProvider.notifier).init();
      await container.read(authProvider.notifier).localLogin('WrongSecret!');
      await pumpEventQueue();

      expect(aiSession.bootstraps, isEmpty);
      expect(widgetLoads, 0);
    });

    test('a successful login shows the widget once the AI session is up',
        () async {
      final container = containerWith(_RecordingAiSessionService());

      await container.read(authProvider.future);
      await container.read(authProvider.notifier).init();
      expect(widgetLoads, 0);
      await container
          .read(authProvider.notifier)
          .localLogin('CandidateSecret!');
      await pumpEventQueue();

      expect(widgetLoads, 1);
    });

    test('an AI bootstrap outage after login does not show the widget',
        () async {
      final container =
          containerWith(_RecordingAiSessionService(result: false));

      await container.read(authProvider.future);
      await container
          .read(authProvider.notifier)
          .localLogin('CandidateSecret!');
      await pumpEventQueue();

      expect(container.read(authProvider).value?.loginType, LoginType.local);
      expect(widgetLoads, 0);
    });

    test('a restored login shows the widget after its bootstrap', () async {
      FlutterSecureStorage.setMockInitialValues(
          {pLocalPassword: 'CandidateSecret!'});
      final container = containerWith(_RecordingAiSessionService());

      await container.read(authProvider.future);
      final auth = container.read(authProvider.notifier);
      await Future.wait([auth.init(), auth.init()]);
      await auth.init();
      await pumpEventQueue();

      expect(widgetLoads, 1);
    });

    test('a logout while the bootstrap is in flight never shows the widget',
        () async {
      final aiSession = _HeldAiSessionService();
      final container = containerWith(aiSession);

      await container.read(authProvider.future);
      final auth = container.read(authProvider.notifier);
      await auth.localLogin('CandidateSecret!');
      expect(aiSession.held, isNotNull);

      await auth.logout();
      aiSession.held!.complete(true); // late success after the logout
      await pumpEventQueue();

      expect(container.read(authProvider).value?.loginType, LoginType.none);
      expect(widgetLoads, 0);
    });

    test('logging in again in the same tab shows the widget again', () async {
      final container = containerWith(_RecordingAiSessionService());

      await container.read(authProvider.future);
      final auth = container.read(authProvider.notifier);
      await auth.localLogin('CandidateSecret!');
      await pumpEventQueue();
      await auth.logout();
      await pumpEventQueue();
      expect(widgetLoads, 1, reason: 'logout itself must not show it');

      await auth.localLogin('CandidateSecret!');
      await pumpEventQueue();
      expect(widgetLoads, 2);
    });
  }, skip: BuildConfig.enableRouterAi ? false : _needsRouterAi);
}

/// A bootstrap the test answers by hand, to land a response after a logout.
/// Unlike the real service, a logout does not cancel it.
class _HeldAiSessionService implements AiSessionService {
  Completer<bool>? held;

  @override
  Future<bool> bootstrap(String adminPassword) {
    held = Completer<bool>();
    return held!.future;
  }

  @override
  Future<void> logout() async {}

  @override
  void close() {}
}
