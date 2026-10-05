import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/jnap_write_classifier.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

void main() {
  group('isJNAPWrite', () {
    test('reads are not writes', () {
      expect(isJNAPWrite(JNAPAction.getDeviceInfo), isFalse);
      expect(isJNAPWrite(JNAPAction.isAdminPasswordDefault), isFalse);
      expect(isJNAPWrite(JNAPAction.checkAdminPassword), isFalse);
      expect(isJNAPWrite(JNAPAction.btGetScanUnconfiguredResult), isFalse);
    });

    test('anything that changes the router is a write', () {
      expect(isJNAPWrite(JNAPAction.setWANSettings), isTrue);
      expect(isJNAPWrite(JNAPAction.reboot), isTrue);
      expect(isJNAPWrite(JNAPAction.factoryReset2), isTrue);
      expect(isJNAPWrite(JNAPAction.deleteDevice), isTrue);
      expect(isJNAPWrite(JNAPAction.clientDeauth), isTrue);
      expect(isJNAPWrite(JNAPAction.applyAutoIPoE), isTrue);
    });

    // Diagnostics start and stop work on the router but change no setting. They
    // stay allowed; speed test is already unavailable remotely through the UI.
    test('diagnostics are not writes', () {
      for (final action in [
        JNAPAction.startPing,
        JNAPAction.stopPing,
        JNAPAction.startTracroute,
        JNAPAction.stopTracroute,
        JNAPAction.runHealthCheck,
        JNAPAction.stopHealthCheck,
      ]) {
        expect(isJNAPWrite(action), isFalse, reason: action.name);
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

    // Reads are picked out by verb, so an action with any other verb is a write
    // by default. These are the ones whose verb reads like neither.
    test('an action with an unfamiliar verb is a write', () {
      expect(isJNAPWrite(JNAPAction.refreshSlaveBackhaulData), isTrue);
      expect(isJNAPWrite(JNAPAction.verifyRouterResetCode), isTrue);
      expect(isJNAPWrite(JNAPAction.btRequestScanUnconfigured), isTrue);
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
  });
}
