import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';
import 'package:privacy_gui/page/instant_verify/models/wan_ip_comparison.dart';

Verdict verdict(WanIpComparison comparison,
        {bool connected = true, String type = 'DHCP', bool dns = true}) =>
    VerdictEngine.compute(
      gatewayReachable: true,
      wanConnected: connected,
      wanIpAddress: comparison.currentAddress,
      wanIpComparison: comparison,
      wanType: type,
      dnsWorking: dns,
      downloadMbps: 100,
      latencyMs: 20,
      firmwareUpdateAvailable: false,
      firmwareVersion: null,
      uptimeSeconds: 3600,
      deviceScores: const [],
      clients: const [],
      meshNodes: const [],
      planSpeedMbps: null,
    );

const changed = WanIpComparison(
  status: WanIpStatus.changed,
  currentAddress: '198.51.100.20',
  referenceAddress: '198.51.100.10',
);

void main() {
  test('changed dynamic address gives context without declaring an outage', () {
    final result = verdict(changed);
    final finding = result.findings.single;
    expect(finding.priority, VerdictPriority.info);
    expect(finding.explanation, contains('198.51.100.10'));
    expect(finding.explanation, contains('198.51.100.20'));
    expect(finding.explanation, contains('static IP'));
    expect(finding.explanation, contains('allowlisting'));
    expect(finding.explanation, contains('does not confirm an outage'));
    expect(finding.explanation, contains('public IP may be different'));
    expect(finding.actionKey, isNull);
    expect(
        result.checks
            .singleWhere((c) => c.label == 'ISP address change')
            .status,
        VerdictCheckStatus.notice);
  });

  test('changed static address is a warning', () {
    expect(verdict(changed, type: 'Static').primaryFinding!.priority,
        VerdictPriority.warning);
  });

  test('DNS failure still outranks the address-change notice', () {
    final result = verdict(changed, dns: false);
    expect(result.primaryFinding!.priority, VerdictPriority.critical);
    expect(
        result.findings
            .any((f) => f.headline == 'Your internet address has changed'),
        isTrue);
  });

  test('unchanged address passes the comparison without a finding', () {
    final result = verdict(const WanIpComparison(
      status: WanIpStatus.unchanged,
      currentAddress: '198.51.100.10',
      referenceAddress: '198.51.100.10',
    ));
    expect(result.isAllClear, isTrue);
    expect(
        result.checks
            .singleWhere((c) => c.label == 'ISP address change')
            .status,
        VerdictCheckStatus.pass);
  });

  for (final status in [
    WanIpStatus.firstObservation,
    WanIpStatus.unavailable
  ]) {
    test('$status is not counted as a passed comparison', () {
      final result = verdict(WanIpComparison(
        status: status,
        currentAddress: '198.51.100.10',
        referenceAddress:
            status == WanIpStatus.firstObservation ? '198.51.100.10' : null,
      ));
      expect(
          result.checks.where((c) => c.label == 'ISP address change'), isEmpty);
      expect(result.findings, isEmpty);
    });
  }

  test('disconnected WAN does not report an address change', () {
    final result = verdict(changed, connected: false);
    expect(result.primaryFinding!.headline, 'No internet connection detected');
    expect(
        result.findings
            .where((f) => f.headline.contains('address has changed')),
        isEmpty);
  });
}
