import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../mocks/router_repository_mocks.dart';

Future<void> drain() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final action in ['login', 'restore', 'logout', 'late-login']) {
    test('controlled HTTP delay: $action', () async {
      FlutterSecureStorage.setMockInitialValues(
          action == 'restore' ? {pLocalPassword: 'ReviewFixtureOnly'} : {});
      SharedPreferences.setMockInitialValues({});
      final response = Completer<http.Response>();
      var shouldHold = action != 'logout';
      var requests = 0;
      final service = HttpAiSessionService(
        baseUri: Uri.parse('https://router.invalid/'),
        clientFactory: () => MockClient((request) async {
          final sentAction = jsonDecode(request.body)['action'];
          if (shouldHold &&
              sentAction == (action == 'logout' ? 'logout' : 'login')) {
            requests++;
            return response.future;
          }
          return http.Response('{}', 200);
        }),
      );
      final router = MockRouterRepository();
      when(router.send(any,
              data: anyNamed('data'),
              extraHeaders: anyNamed('extraHeaders'),
              auth: anyNamed('auth'),
              type: anyNamed('type'),
              fetchRemote: anyNamed('fetchRemote'),
              cacheLevel: anyNamed('cacheLevel'),
              timeoutMs: anyNamed('timeoutMs'),
              retries: anyNamed('retries'),
              sideEffectOverrides: anyNamed('sideEffectOverrides')))
          .thenAnswer((_) async => JNAPSuccess(result: jnapResultOk));
      final container = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router),
        aiSessionServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);
      await container.read(authProvider.future);
      final auth = container.read(authProvider.notifier);
      if (action == 'logout') {
        await auth.localLogin('ReviewFixtureOnly');
        shouldHold = true;
      }
      var finished = false;
      final pending = (action == 'logout'
              ? auth.logout()
              : action == 'restore'
                  ? auth.init()
                  : auth.localLogin('ReviewFixtureOnly'))
          .then((_) {
        finished = true;
      });
      await drain();
      expect(requests, 1, reason: 'The real AI HTTP boundary must be reached');
      final before = {
        'action': action,
        'held_http_requests': requests,
        'finished_before_release': finished,
        'login_type': container.read(authProvider).value?.loginType.toString(),
        'stored_credential_present':
            await const FlutterSecureStorage().read(key: pLocalPassword) !=
                null,
      };
      if (action == 'late-login') {
        await auth.logout();
        before['after_logout'] =
            container.read(authProvider).value?.loginType.toString();
      }
      response.complete(http.Response('{}', 200));
      await pending;
      await drain();
      before['after_release'] =
          container.read(authProvider).value?.loginType.toString();
      if (action == 'late-login') {
        expect(container.read(authProvider).value?.loginType, LoginType.none,
            reason:
                'A stale login completion must not restore authenticated UI after logout');
      } else {
        expect(finished && before['finished_before_release'] == true, isTrue,
            reason:
                'Optional AI response must not gate native authentication completion');
      }
      if (action == 'logout') {
        expect(before['login_type'], 'LoginType.none');
        expect(before['stored_credential_present'], isFalse);
      }
    });
  }
}
