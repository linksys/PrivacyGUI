import 'package:linksys_app/core/jnap/actions/better_action.dart';

class JNAPTransactionBuilder {
  final List<MapEntry<JNAPAction, Map<String, dynamic>>> _commands;
  final bool auth;

  JNAPTransactionBuilder({
    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = const [],
    this.auth = false,
  }) : _commands = commands;

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
