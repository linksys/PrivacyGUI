import 'package:privacy_gui/core/jnap/command/base_command.dart';

mixin JNAPCommandExecutor<R> {
  int _timeoutMs = 10000;
  int get timeoutMs => _timeoutMs;
  set timeoutMs(int ms) {
    _timeoutMs = ms;
  }

  Future<R> execute(BaseCommand command);
  void dropCommand(String id);
}
