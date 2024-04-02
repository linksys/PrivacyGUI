import 'package:linksys_app/core/jnap/actions/better_action.dart';

class JNAPTransactionBuilder {
  final List<MapEntry<JNAPAction, Map<String, dynamic>>> _commands;
  final bool auth;

  JNAPTransactionBuilder({
    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = const [],
    this.auth = false,
  }) : _commands = commands;

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
