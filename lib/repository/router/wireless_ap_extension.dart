import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension WirelessApService on RouterRepository {
  Future<JnapSuccess> getRadioInfo() async {
    final command = createCommand(JNAPAction.getRadioInfo.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getWPSServerSessionStatus() async {
    final command =
        createCommand(JNAPAction.getWPSServerSessionStatus.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
