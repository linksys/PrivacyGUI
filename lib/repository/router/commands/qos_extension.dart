import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension QosService on RouterRepository {
  Future<JNAPSuccess> getQoSSettings() async {
    final command = createCommand(JNAPAction.getQoSSettings.actionValue, needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
