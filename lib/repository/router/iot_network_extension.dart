import 'package:linksys_moab/model/router/guest_radio_settings.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension GuestNetworkService on RouterRepository {
  Future<JnapSuccess> getIoTNetworkSettings() async {
    final command =
    createCommand(JNAPAction.getIoTNetworkSettings.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> setIoTNetworkSettings(bool enable) async {
    final command =
    createCommand(JNAPAction.setIoTNetworkSettings.actionValue, data: {
      'isIoTNetworkEnabled': enable,
    });

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}