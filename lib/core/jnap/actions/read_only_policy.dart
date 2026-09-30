import 'package:privacy_gui/core/jnap/actions/better_action.dart';

// Which JNAP actions a read-only build may still send.
//
// Fail-closed: an action is refused unless it is listed here or named like a
// read. A newly added action is therefore refused until someone classifies it,
// which read_only_policy_test enforces.

final _readPrefix = RegExp(r'^(get|is|check)[A-Z]');

// Named like a write but do not change the router's configuration: reads, auth
// probes, diagnostics (allowed by product decision), and the router emailing its
// own sysinfo.
const _allowedIrregular = {
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

// The dashboard asks whether an update exists on every visit, and that check
// shares its action with the install. Only the payload tells them apart.
const _firmwareCheckActions = {
  JNAPAction.updateFirmwareNow,
  JNAPAction.nodesUpdateFirmwareNow,
};

bool isAllowedInReadOnly(JNAPAction action, Map<String, dynamic> data) {
  if (_readPrefix.hasMatch(action.name)) return true;
  if (_allowedIrregular.contains(action)) return true;
  if (_firmwareCheckActions.contains(action) && data['onlyCheck'] == true) {
    return true;
  }
  return false;
}
