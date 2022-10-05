import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension MacFilterService on RouterRepository {
  Future<JnapSuccess> getActiveMotionSensingBots() async {
    final command =
        createCommand(JNAPAction.getActiveMotionSensingBots.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getMotionSensingSettings() async {
    final command =
        createCommand(JNAPAction.getMotionSensingSettings.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
