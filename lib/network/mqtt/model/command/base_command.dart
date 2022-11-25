import 'package:linksys_moab/network/base_client.dart';
import 'package:linksys_moab/network/mqtt/command_spec/impl/jnap_spec.dart';

abstract class BaseCommand<R> {
  BaseCommand({required this.spec});
  final JNAPCommandSpec spec;

  Future<R> publish(JNAPCommandExecutor executor);
}