import 'package:linksys_app/core/jnap/command/base_command.dart';

mixin JNAPCommandExecutor<R> {
  Future<R> execute(BaseCommand command);
  void dropCommand(String id);
}
