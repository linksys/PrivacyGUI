import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/jnap_write_classifier.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

/// Named like neither a read nor a `set`, and still not a write: a diagnostic,
/// or a probe that reads.
const _irregularReads = {
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
  JNAPAction.refreshNodesWirelessNetworkConnections,
  JNAPAction.sendSysinfoEmail,
};

/// Named like neither, and a write.
const _irregularWrites = {
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

bool _namedLikeARead(JNAPAction a) =>
    RegExp(r'^(get|is|check)[A-Z]').hasMatch(a.name);
bool _namedLikeASet(JNAPAction a) => RegExp(r'^set[A-Z]').hasMatch(a.name);

void main() {
  // Every action, not a sample. The gate is fail-closed, so the risk it carries
  // is a read the app depends on being refused and a page quietly failing to
  // load; a new action fails here until someone decides which side it is on.
  test('every action is classified exactly once', () {
    final unclassified = JNAPAction.values.where((a) =>
        !_namedLikeARead(a) &&
        !_namedLikeASet(a) &&
        !_irregularReads.contains(a) &&
        !_irregularWrites.contains(a));
    expect(unclassified, isEmpty,
        reason: 'sort a new irregular action into a read or a write');
    expect(_irregularReads.intersection(_irregularWrites), isEmpty);
  });

  group('is not a write', () {
    for (final action in JNAPAction.values
        .where((a) => _namedLikeARead(a) || _irregularReads.contains(a))) {
      test(action.name, () => expect(isJNAPWrite(action), isFalse));
    }
  });

  group('is a write', () {
    for (final action in JNAPAction.values
        .where((a) => _namedLikeASet(a) || _irregularWrites.contains(a))) {
      test(action.name, () => expect(isJNAPWrite(action), isTrue));
    }
  });

  group('a firmware update action', () {
    for (final action in [
      JNAPAction.updateFirmwareNow,
      JNAPAction.nodesUpdateFirmwareNow,
    ]) {
      test('${action.name} that only checks is a read', () {
        expect(isJNAPWrite(action, data: {'onlyCheck': true}), isFalse);
      });

      test('${action.name} that updates is a write', () {
        expect(isJNAPWrite(action, data: {'onlyCheck': false}), isTrue);
        expect(isJNAPWrite(action), isTrue,
            reason: 'no onlyCheck means the router installs the update');
      });
    }
  });

  test('a transaction is judged by what it carries, not by itself', () {
    expect(jnapReadActions.contains(JNAPAction.transaction), isFalse);
    expect(
        firstJNAPTransactionWrite([
          const MapEntry(JNAPAction.getDeviceInfo, <String, dynamic>{}),
          const MapEntry(JNAPAction.getWANSettings, <String, dynamic>{}),
        ]),
        isNull);
    expect(
        firstJNAPTransactionWrite([
          const MapEntry(JNAPAction.getDeviceInfo, <String, dynamic>{}),
          const MapEntry(JNAPAction.setWANSettings, <String, dynamic>{}),
          const MapEntry(JNAPAction.setLANSettings, <String, dynamic>{}),
        ]),
        JNAPAction.setWANSettings,
        reason: 'one write makes the whole transaction a write');
  });
}
