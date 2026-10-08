import 'package:collection/collection.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

/// Actions that only read router state: every `get`, `is` and `check` action.
///
/// Reads are the ones picked out, not writes, so an action with any other verb -
/// including one added later that nobody thought to classify - is treated as a
/// write and blocked in read-only mode rather than let through. `transaction` is
/// not in here either: a transaction is judged by the commands it carries.
final Set<JNAPAction> jnapReadActions = {
  for (final action in JNAPAction.values)
    if (_isReadByName(action)) action,
};

/// Actions that make the router do something without changing its settings:
/// run a test, blink a node so it can be found, refresh what it reports, or
/// email its own sysinfo.
///
/// Allowed in read-only mode, so a remote helper can still diagnose. Speed test
/// is kept out of remote mode by the UI, not by this gate.
const Set<JNAPAction> jnapDiagnosticActions = {
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
  JNAPAction.sendSysinfoEmail,
  JNAPAction.refreshSlaveBackhaulData,
  JNAPAction.refreshNodesWirelessNetworkConnections,
  JNAPAction.btRequestScanUnconfigured,
};

/// The two firmware actions both check for and install an update; which one
/// they do is decided by `onlyCheck` in the request, not by the action.
const Set<JNAPAction> _firmwareUpdateActions = {
  JNAPAction.updateFirmwareNow,
  JNAPAction.nodesUpdateFirmwareNow,
};

bool _isReadByName(JNAPAction action) =>
    RegExp(r'^(get|is|check|pnpCheck|btGet)[A-Z]').hasMatch(action.name);

/// Whether sending [action] with [data] would change the router.
bool isJNAPWrite(JNAPAction action, {Map<String, dynamic> data = const {}}) {
  if (_firmwareUpdateActions.contains(action)) {
    return data['onlyCheck'] != true;
  }
  return !jnapReadActions.contains(action) &&
      !jnapDiagnosticActions.contains(action);
}

/// The first command in a transaction that would change the router, or null
/// when it only reads.
JNAPAction? firstJNAPTransactionWrite(
        Iterable<MapEntry<JNAPAction, Map<String, dynamic>>> commands) =>
    commands
        .where((entry) => isJNAPWrite(entry.key, data: entry.value))
        .firstOrNull
        ?.key;
