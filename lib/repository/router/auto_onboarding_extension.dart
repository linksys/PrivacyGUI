import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension AutoOnboardingService on RouterRepository {
  Future<JnapSuccess> getBluetoothAutoOnboardingSettings() async {
    final command =
        createCommand(JNAPAction.getBluetoothAutoOnboardingSettings.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
  Future<JnapSuccess> getBlueboothAutoOnboardingStatus() async {
    final command =
    createCommand(JNAPAction.getBlueboothAutoOnboardingStatus.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
  Future<JnapSuccess> startBlueboothAutoOnboarding() async {
    final command =
    createCommand(JNAPAction.startBlueboothAutoOnboarding.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
