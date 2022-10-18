import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension GuestNetworkService on RouterRepository {
  Future<JnapSuccess> getGuestNetworkClients() async {
    final command =
        createCommand(JNAPAction.getGuestNetworkClients.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getGuestNetworkSettings() async {
    final command =
        createCommand(JNAPAction.getGuestNetworkSettings.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
