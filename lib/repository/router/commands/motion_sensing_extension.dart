import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension MotionSensingService on RouterRepository {
  Future<JNAPSuccess> getActiveMotionSensingBots() async {
    final command =
        createCommand(JNAPAction.getActiveMotionSensingBots.actionValue, needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getMotionSensingSettings() async {
    final command =
        createCommand(JNAPAction.getMotionSensingSettings.actionValue, needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
