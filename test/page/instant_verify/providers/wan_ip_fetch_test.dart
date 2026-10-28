import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_verify/models/wan_ip_comparison.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/services/wan_ip_history.dart';
import '../../../mocks/router_repository_mocks.dart';

class _Browser extends BrowserDiagnosticService {
  @override
  Future<GatewayPingResult> pingGateway() async =>
      const GatewayPingResult(reachable: true);
  @override
  Future<DnsCheckResult> checkDns() async =>
      const DnsCheckResult(resolved: true);
  @override
  Future<SpeedTestResult> runInternetSpeedTest(
          {void Function(String)? onStep}) async =>
      const SpeedTestResult(
          downloadMbps: 100, uploadMbps: 40, latencyMs: 10, jitterMs: 1);
}

void main() {
  test(
      'real automatic fetch compares WAN IP and keeps the warning until acknowledgement',
      () async {
    final storage = <String, String>{};
    final history = WanIpHistory(
        read: (key) => storage[key],
        write: (key, value) => storage[key] = value);
    history.observe(
        routerMac: 'AA:BB:CC:DD:EE:01',
        currentAddress: '198.51.100.10',
        connected: true);
    final repo = MockRouterRepository();
    final actions = <JNAPAction>[];
    when(repo.send(any,
            data: anyNamed('data'),
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            auth: anyNamed('auth')))
        .thenAnswer((call) async {
      final action = call.positionalArguments.first as JNAPAction;
      actions.add(action);
      final output = switch (action) {
        JNAPAction.getWANStatus => <String, dynamic>{
            'wanStatus': 'Connected',
            'detectedWANType': 'Static',
            'wanConnection': {'ipAddress': '198.51.100.20'}
          },
        JNAPAction.getDeviceInfo => <String, dynamic>{
            'macAddress': 'AA:BB:CC:DD:EE:01'
          },
        JNAPAction.getSystemStats => <String, dynamic>{'uptimeSeconds': 3600},
        _ => <String, dynamic>{},
      };
      return JNAPSuccess(result: 'OK', output: output);
    });
    final container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(repo),
      browserDiagnosticServiceProvider.overrideWithValue(_Browser()),
      wanIpHistoryProvider.overrideWithValue(history),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(instantVerifyPivotProvider.notifier);
    for (var run = 0; run < 2; run++) {
      await notifier.fetch();
      final state = container.read(instantVerifyPivotProvider);
      expect(state.errorMessage, isNull);
      expect(state.phase, PivotLoadPhase.complete);
      expect(state.wanIpComparison.status, WanIpStatus.changed);
      expect(
          state.verdict!.findings
              .any((f) => f.headline == 'Your internet address has changed'),
          isTrue);
    }
    expect(notifier.useCurrentWanIpAsReference(), isTrue);
    expect(container.read(instantVerifyPivotProvider).wanIpComparison.status,
        WanIpStatus.unchanged);
    expect(
        container
            .read(instantVerifyPivotProvider)
            .verdict!
            .findings
            .where((f) => f.headline == 'Your internet address has changed'),
        isEmpty);
    // Detection and acknowledgement never send a router configuration command.
    expect(actions.every((a) => a.name.startsWith('get')), isTrue);
  });
}
