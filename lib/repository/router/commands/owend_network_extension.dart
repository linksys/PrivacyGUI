import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension OwnedNetworkService on RouterRepository {

  Future<JNAPSuccess> getOwnedNetworkID() async {
    final command = createCommand(JNAPAction.getOwnedNetworkID.actionValue, needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
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
    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
