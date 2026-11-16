import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service.dart';
import 'package:privacy_gui/core/ai_session/router_ai_loader.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/components/layouts/root_container.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/router_repository_mocks.dart';

/// Records every call so a default build can prove it never reaches the AI
/// session boundary, even when a live service is injected.
class _RecordingAiSessionService implements AiSessionService {
  final List<String> bootstraps = [];
  int logouts = 0;

  @override
  Future<bool> bootstrap(String adminPassword) async {
    bootstraps.add(adminPassword);
    return true;
  }

  @override
  Future<void> logout() async {
    logouts++;
  }

  @override
  void close() {}
}

void _stubRouterOk(MockRouterRepository router) {
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
  )).thenAnswer((_) async => JNAPSuccess(result: jnapResultOk));
}

ProviderContainer _container(_RecordingAiSessionService aiSession) {
  final router = MockRouterRepository();
  _stubRouterOk(router);
  final container = ProviderContainer(overrides: [
    routerRepositoryProvider.overrideWithValue(router),
    aiSessionServiceProvider.overrideWithValue(aiSession),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A default (production) build: --dart-define=enable_router_ai is not set.
  group('default build without Router AI', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
    });

    test('the flag defaults to off', () {
      expect(BuildConfig.enableRouterAi, isFalse);
    });

    test('the AI session service is the disabled no-op', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(aiSessionServiceProvider);
      expect(service, isA<DisabledAiSessionService>());
      expect(await service.bootstrap('CandidateSecret!'), isFalse);
    });

    test('the widget bundle is never added to the page', () {
      expect(loadRouterAiBundle(), isFalse);
    });

    test('local login never sends the password to the AI boundary', () async {
      final aiSession = _RecordingAiSessionService();
      final container = _container(aiSession);

      await container.read(authProvider.future);
      await container
          .read(authProvider.notifier)
          .localLogin('CandidateSecret!');

      expect(container.read(authProvider).value?.loginType, LoginType.local);
      expect(aiSession.bootstraps, isEmpty);
      expect(aiSession.logouts, 0);
    });

    test('startup with and without a restored login makes no AI call',
        () async {
      for (final restored in [false, true]) {
        FlutterSecureStorage.setMockInitialValues(
            restored ? {pLocalPassword: 'CandidateSecret!'} : {});
        final aiSession = _RecordingAiSessionService();
        final container = _container(aiSession);

        await container.read(authProvider.future);
        await container.read(authProvider.notifier).init();

        expect(aiSession.bootstraps, isEmpty, reason: 'restored=$restored');
        expect(aiSession.logouts, 0, reason: 'restored=$restored');
      }
    });

    test('logout and idle logout make no AI call and still log out', () async {
      final aiSession = _RecordingAiSessionService();
      final container = _container(aiSession);

      await container.read(authProvider.future);
      await container
          .read(authProvider.notifier)
          .localLogin('CandidateSecret!');
      await container.read(authProvider.notifier).logout();
      expect(container.read(authProvider).value?.loginType, LoginType.none);

      await container
          .read(authProvider.notifier)
          .localLogin('CandidateSecret!');
      await container.read(idleLogoutProvider)();
      expect(container.read(authProvider).value?.loginType, LoginType.none);

      expect(aiSession.bootstraps, isEmpty);
      expect(aiSession.logouts, 0);
    });
  }, skip: BuildConfig.enableRouterAi ? 'default-build checks' : false);
}
