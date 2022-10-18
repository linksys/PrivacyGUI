import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension SmartModeExtension on RouterRepository {
  Future<JnapSuccess> getDeviceMode() async {
    final command = createCommand(JNAPAction.getDeviceMode.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
  Future<JnapSuccess> getSupportedDeviceMode() async {
    final command = createCommand(JNAPAction.getSupportedDeviceMode.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
  Future<JnapSuccess> setDeviceMode(String mode) async {
    final command = createCommand(JNAPAction.setDeviceMode.actionValue, data: {'mode': mode});

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
