// The read-only allowlist, pinned action by action.
//
// A read-only build refuses every JNAP action this policy does not allow. The
// policy is fail-closed - an action nobody classified is refused - so the risk
// it carries is the opposite one: a read the app depends on being refused, and
// a page quietly failing to load. Every action is therefore listed here, and a
// newly added action fails this test until someone decides which side it is on.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/read_only_policy.dart';

void main() {
  // Irregular names that are still allowed: reads, auth probes, diagnostics by
  // product decision, and the router emailing its own sysinfo (not a settings
  // change).
  const allowedIrregular = {
    JNAPAction.btGetScanUnconfiguredResult,
    JNAPAction.btRequestScanUnconfigured,
    JNAPAction.pnpCheckAdminPassword,
    JNAPAction.startPing,
    JNAPAction.stopPing,
    JNAPAction.startTracroute,
    JNAPAction.stopTracroute,
    JNAPAction.runHealthCheck,
    JNAPAction.stopHealthCheck,
    JNAPAction.startBlinkNodeLed,
    JNAPAction.stopBlinkNodeLed,
    JNAPAction.startBlinkingNodeLed,
    JNAPAction.stopBlinkingNodeLed,
    JNAPAction.testVPNConnection,
    JNAPAction.refreshSlaveBackhaulData,
    JNAPAction.sendSysinfoEmail,
  };

  // Irregular names that change the router, refused.
  const refusedIrregular = {
    JNAPAction.transaction,
    JNAPAction.startBlueboothAutoOnboarding,
    JNAPAction.coreSetAdminPassword,
    JNAPAction.pnpSetAdminPassword,
    JNAPAction.reboot,
    JNAPAction.reboot2,
    JNAPAction.factoryReset,
    JNAPAction.factoryReset2,
    JNAPAction.deleteDevice,
    JNAPAction.execSysCommand,
    JNAPAction.restorePreviousFirmware,
    JNAPAction.updateFirmwareNow,
    JNAPAction.nodesUpdateFirmwareNow,
    JNAPAction.clearHealthCheckHistory,
    JNAPAction.releaseDHCPWANLease,
    JNAPAction.releaseDHCPIPv6WANLease,
    JNAPAction.renewDHCPWANLease,
    JNAPAction.renewDHCPIPv6WANLease,
    JNAPAction.applyAutoIPoE,
    JNAPAction.resetAutoIPoE,
    JNAPAction.setupSetAdminPassword,
    JNAPAction.verifyRouterResetCode,
    JNAPAction.clientDeauth,
    JNAPAction.startAutoChannelSelection,
  };

  bool isRegularRead(JNAPAction a) =>
      RegExp(r'^(get|is|check)[A-Z]').hasMatch(a.name);
  bool isRegularWrite(JNAPAction a) => RegExp(r'^set[A-Z]').hasMatch(a.name);

  test('every action is classified exactly once', () {
    final unclassified = JNAPAction.values.where((a) =>
        !isRegularRead(a) &&
        !isRegularWrite(a) &&
        !allowedIrregular.contains(a) &&
        !refusedIrregular.contains(a));
    expect(unclassified, isEmpty,
        reason: 'New irregular actions must be sorted into allowed or refused');
    expect(allowedIrregular.intersection(refusedIrregular), isEmpty);
  });

  group('allowed', () {
    for (final action in JNAPAction.values
        .where((a) => isRegularRead(a) || allowedIrregular.contains(a))) {
      test(action.name, () {
        expect(isAllowedInReadOnly(action, const {}), isTrue);
      });
    }
  });

  group('refused', () {
    for (final action in JNAPAction.values
        .where((a) => isRegularWrite(a) || refusedIrregular.contains(a))) {
      test(action.name, () {
        expect(isAllowedInReadOnly(action, const {}), isFalse);
      });
    }
  });

  group('firmware check', () {
    // The dashboard sends this on every visit to ask whether an update exists.
    // It shares its action with the real install, so only the payload tells
    // them apart.
    for (final action in [
      JNAPAction.updateFirmwareNow,
      JNAPAction.nodesUpdateFirmwareNow,
    ]) {
      test('${action.name} with onlyCheck is allowed', () {
        expect(isAllowedInReadOnly(action, {'onlyCheck': true}), isTrue);
      });

      test('${action.name} installing is refused', () {
        expect(isAllowedInReadOnly(action, {'onlyCheck': false}), isFalse);
        expect(isAllowedInReadOnly(action, const {}), isFalse);
      });
    }
  });
}
