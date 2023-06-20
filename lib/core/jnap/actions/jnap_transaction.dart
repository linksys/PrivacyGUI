
import 'package:linksys_moab/core/jnap/actions/better_action.dart';

class JNAPTransactionBuilder {
  final Map<JNAPAction, Map<String, dynamic>> _commands;
  final bool auth;

  JNAPTransactionBuilder({
    Map<JNAPAction, Map<String, dynamic>> commands = const {},
    this.auth = false,
  }) : _commands = commands;

  factory JNAPTransactionBuilder.coreTransactions() {
    return JNAPTransactionBuilder(
      commands: {
        JNAPAction.getDeviceInfo: {},
        JNAPAction.getWANStatus: {},
        JNAPAction.getNodesWirelessNetworkConnections: {},
        JNAPAction.getRadioInfo: {},
        JNAPAction.getGuestRadioSettings: {},
        JNAPAction.getDevices: {},
        JNAPAction.getHealthCheckResults: {'includeModuleResults': true},
        JNAPAction.getSupportedHealthCheckModules: {},
      },
      auth: true,
    );
  }

  Map<JNAPAction, Map<String, dynamic>> get commands => _commands;

  JNAPTransactionBuilder add(JNAPAction action,
      {Map<String, dynamic> data = const {}}) {
    _commands[action] = data;
    return this;
  }

  JNAPTransactionBuilder addAll(
      Map<JNAPAction, Map<String, dynamic>> commands) {
    _commands.addAll(commands);
    return this;
  }

  JNAPTransactionBuilder remove(JNAPAction action) {
    if (_commands.containsKey(action)) {
      _commands.remove(action);
    }
    return this;
  }
}
