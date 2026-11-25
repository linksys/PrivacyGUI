import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';

import '../../../common/recording_polling.dart';
import '../../../mocks/router_repository_mocks.dart';
import '../../../test_data/device_info_test_data.dart';

class _LocalAuth extends AuthNotifier {
  @override
  Future<AuthState> build() =>
      Future.value(const AuthState(loginType: LoginType.local));
}

void main() {
  late MockRouterRepository repo;
  late ProviderContainer container;

  setUp(() {
    initBetterActions();
    repo = MockRouterRepository();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(repo),
      authProvider.overrideWith(() => _LocalAuth()),
      pollingProvider.overrideWith(() => RecordingPolling()),
    ]);
  });

  tearDown(() {
    container.dispose();
    initBetterActions();
  });

  group('checkDeviceInfo', () {
    // Every caller builds the action table from what checkDeviceInfo reads,
    // so it builds the table itself (#1923 P2).
    test('builds the action table from the device info it reads', () async {
      final output = Map<String, dynamic>.from(
          (jsonDecode(testDeviceInfo) as Map)['output'] as Map);
      when(repo.send(
        JNAPAction.getDeviceInfo,
        data: anyNamed('data'),
        extraHeaders: anyNamed('extraHeaders'),
        auth: anyNamed('auth'),
        type: anyNamed('type'),
        fetchRemote: anyNamed('fetchRemote'),
        cacheLevel: anyNamed('cacheLevel'),
        timeoutMs: anyNamed('timeoutMs'),
        retries: anyNamed('retries'),
        sideEffectOverrides: anyNamed('sideEffectOverrides'),
      )).thenAnswer((_) async => JNAPSuccess(result: 'OK', output: output));

      final info = await container
          .read(dashboardManagerProvider.notifier)
          .checkDeviceInfo(null);

      expect(info.serialNumber, output['serialNumber']);
      expect(routerServices, Set<String>.from(output['services'] as List));
      expect(JNAPAction.getWANSettings.actionValue,
          'http://linksys.com/jnap/router/GetWANSettings5');
    });
  });
}
