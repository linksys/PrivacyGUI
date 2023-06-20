import 'package:linksys_moab/core/jnap/actions/better_action.dart';
import 'package:linksys_moab/core/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/core/jnap/result/jnap_result.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';

extension OwnedNetworkService on RouterRepository {
  Future<JNAPSuccess> getOwnedNetworkID() async {
    final command = await createCommand(
        JNAPAction.getOwnedNetworkID.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> setNetworkOwner(
      {required String ownerToken, String? friendlyName}) async {
    final command = await createCommand(JNAPAction.setNetworkOwner.actionValue,
        needAuth: true,
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
