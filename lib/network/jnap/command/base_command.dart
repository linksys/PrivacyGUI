import 'package:linksys_moab/network/jnap/jnap_command_executor_mixin.dart';
import 'package:linksys_moab/network/jnap/spec/jnap_spec.dart';

abstract class BaseCommand<R> {
  BaseCommand({required this.spec});
  final JNAPCommandSpec spec;

  Future<R> publish(JNAPCommandExecutor executor);
}