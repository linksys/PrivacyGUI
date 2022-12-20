import 'better_action.dart';

class JNAPTransactionBuilder {
  final Map<JNAPAction, Map<String, dynamic>> _commands = {};
  final bool auth;

  JNAPTransactionBuilder({this.auth = false});

  Map<JNAPAction, Map<String, dynamic>> get commands => _commands;

  JNAPTransactionBuilder add(JNAPAction action,
      {Map<String, dynamic> data = const {}}) {
    _commands[action] = data;
    return this;
  }

  JNAPTransactionBuilder addAll(Map<JNAPAction, Map<String, dynamic>> commands) {
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
