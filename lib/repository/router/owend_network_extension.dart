import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension OwnedNetworkService on RouterRepository {
  Future<JnapSuccess> getOwnedNetworkID() async {
    final command = createCommand(JNAPAction.getOwnedNetworkID.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> setNetworkOwner(
      {required String ownerToken, String? friendlyName}) async {
    final command = createCommand(JNAPAction.setNetworkOwner.actionValue,
        data: friendlyName != null
            ? {
                'ownerSessionToken': ownerToken,
                'friendlyName': friendlyName,
              }
            : {
                'ownerSessionToken': ownerToken,
              });
    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
