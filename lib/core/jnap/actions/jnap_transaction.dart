import 'package:linksys_app/core/jnap/actions/better_action.dart';

class JNAPTransactionBuilder {
  final List<MapEntry<JNAPAction, Map<String, dynamic>>> _commands;
  final bool auth;

  JNAPTransactionBuilder({
    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = const [],
    this.auth = false,
  }) : _commands = commands;

  factory JNAPTransactionBuilder.firstCoreTransactions() {
    return JNAPTransactionBuilder(
      commands: [
        const MapEntry(JNAPAction.getDeviceInfo, {}),
        const MapEntry(JNAPAction.getWANStatus, {}),
      ],
    );
  }

  factory JNAPTransactionBuilder.secondCoreTransactions() {
    return JNAPTransactionBuilder(
      commands: [
        const MapEntry(JNAPAction.getNodesWirelessNetworkConnections, {}),
        const MapEntry(JNAPAction.getNetworkConnections, {}),
        const MapEntry(JNAPAction.getRadioInfo, {}),
        const MapEntry(JNAPAction.getGuestRadioSettings, {}),
        const MapEntry(JNAPAction.getDevices, {}),
        const MapEntry(JNAPAction.getFirmwareUpdateStatus, {}),
        const MapEntry(
            JNAPAction.getHealthCheckResults, {'includeModuleResults': true}),
        const MapEntry(JNAPAction.getSupportedHealthCheckModules, {}),
        const MapEntry(JNAPAction.getBackhaulInfo, {}),
      ],
      auth: true,
    );
  }

  factory JNAPTransactionBuilder.coreTransactions() {
    return JNAPTransactionBuilder(
      commands: [
        const MapEntry(JNAPAction.getDeviceInfo, {}),
        const MapEntry(JNAPAction.getWANStatus, {}),
        const MapEntry(JNAPAction.getNodesWirelessNetworkConnections, {}),
        const MapEntry(JNAPAction.getNetworkConnections, {}),
        const MapEntry(JNAPAction.getRadioInfo, {}),
        const MapEntry(JNAPAction.getGuestRadioSettings, {}),
        const MapEntry(JNAPAction.getDevices, {}),
        const MapEntry(JNAPAction.getFirmwareUpdateStatus, {}),
        const MapEntry(
            JNAPAction.getHealthCheckResults, {'includeModuleResults': true}),
        const MapEntry(JNAPAction.getSupportedHealthCheckModules, {}),
        const MapEntry(JNAPAction.getBackhaulInfo, {}),

        // ===========================

        // const MapEntry(JNAPAction.getOwnedNetworkID, {}),
        // const MapEntry(JNAPAction.getGuestNetworkSettings, {}),
        // const MapEntry(JNAPAction.getLANSettings, {}),
        // const MapEntry(JNAPAction.getIPv6Settings, {}),
        // const MapEntry(JNAPAction.getDHCPClientLeases, {}),
        // const MapEntry(JNAPAction.getWPSServerSessionStatus, {}),
        // const MapEntry(JNAPAction.getWANSettings, {}),
        // const MapEntry(JNAPAction.getSinglePortForwardingRules, {}),
        // const MapEntry(JNAPAction.getPortRangeForwardingRules, {}),
        // const MapEntry(JNAPAction.getPortRangeTriggeringRules, {}),
        // const MapEntry(JNAPAction.getGuestNetworkClients, {}),
        // const MapEntry(JNAPAction.getTimeSettings, {}),
        // const MapEntry(JNAPAction.getLocalTime, {}),
        // const MapEntry(JNAPAction.getMACAddressCloneSettings, {}),
      ],
      auth: true,
    );
  }

  List<MapEntry<JNAPAction, Map<String, dynamic>>> get commands => _commands;

  JNAPTransactionBuilder add(JNAPAction action,
      {Map<String, dynamic> data = const {}}) {
    _commands.add(MapEntry(action, data));
    return this;
  }

  JNAPTransactionBuilder addAll(
      List<MapEntry<JNAPAction, Map<String, dynamic>>> commands) {
    _commands.addAll(commands);
    return this;
  }

  JNAPTransactionBuilder remove(JNAPAction action) {
    if (_commands.any((x) => x.key == action)) {
      _commands.removeWhere((element) => element.key == action);
    }
    return this;
  }
}
