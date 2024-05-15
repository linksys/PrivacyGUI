import 'package:privacy_gui/core/jnap/command/base_command.dart';

mixin JNAPCommandExecutor<R> {
  int _timeoutMs = 10000;
  int _retries = 1;
  int get timeoutMs => _timeoutMs;
  int get retries => _retries;

  set timeoutMs(int ms) {
    _timeoutMs = ms;
  }

  set retries(int times) {
    _retries = times;
  }

  Future<R> execute(BaseCommand command);
  void dropCommand(String id);
}
