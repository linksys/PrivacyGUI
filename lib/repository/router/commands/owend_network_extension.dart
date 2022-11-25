import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension OwnedNetworkService on RouterRepository {

  Future<JNAPSuccess> getOwnedNetworkID() async {
    final command = createCommand(JNAPAction.getOwnedNetworkID.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setNetworkOwner(
      {required String ownerToken, String? friendlyName}) async {
    final command = createCommand(JNAPAction.setNetworkOwner.actionValue, needAuth: true,
        data: friendlyName != null
            ? {
                'ownerSessionToken': ownerToken,
                'friendlyName': friendlyName,
              }
            : {
                'ownerSessionToken': ownerToken,
              });
    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  @Deprecated('Moab')
  Future<JNAPSuccess> getCloudIds() async {
    final command = createCommand(JNAPAction.getCloudIds.actionValue, needAuth: true);
    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  @Deprecated('Moab')
  Future<JNAPSuccess> setCloudIds(String accountId, String groupId) async {
    final command = createCommand(
      JNAPAction.setCloudIds.actionValue, needAuth: true,
      data: {
        'accountID': accountId,
        'groupID': groupId,
      },
    );
    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
