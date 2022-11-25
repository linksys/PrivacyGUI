import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension NodesNetworkConnectionsService on RouterRepository {
  Future<JNAPSuccess> getNodesWirelessNetworkConnections() async {
    final command = createCommand(
        JNAPAction.getNodesWirelessNetworkConnections.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
