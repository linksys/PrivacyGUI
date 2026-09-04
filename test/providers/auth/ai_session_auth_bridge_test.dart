import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../mocks/router_repository_mocks.dart';

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

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
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
    await container.read(authProvider.notifier).localLogin('CandidateSecret!');

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
    await container.read(authProvider.notifier).localLogin('CandidateSecret!');

    expect(container.read(authProvider).hasError, isFalse);
    expect(container.read(authProvider).value?.loginType, LoginType.local);
  });
}
