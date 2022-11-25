import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension MotionSensingService on RouterRepository {
  Future<JNAPSuccess> getActiveMotionSensingBots() async {
    final command =
        createCommand(JNAPAction.getActiveMotionSensingBots.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getMotionSensingSettings() async {
    final command =
        createCommand(JNAPAction.getMotionSensingSettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
