import 'package:linksys_moab/core/jnap/actions/better_action.dart';
import 'package:linksys_moab/core/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/core/jnap/result/jnap_result.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';

extension MotionSensingService on RouterRepository {
  Future<JNAPSuccess> getActiveMotionSensingBots() async {
    final command = await createCommand(
        JNAPAction.getActiveMotionSensingBots.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getMotionSensingSettings() async {
    final command = await createCommand(
        JNAPAction.getMotionSensingSettings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
