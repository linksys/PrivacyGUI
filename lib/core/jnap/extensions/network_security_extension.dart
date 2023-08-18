import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/jnap_command_queue.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

extension NetworkSecurityService on RouterRepository {
  Future<JNAPSuccess> getNetworkSecuritySettings() async {
    final command = await createCommand(
        JNAPAction.getNetworkSecuritySettings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
