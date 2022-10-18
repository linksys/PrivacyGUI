import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension NetworkConnectionsService on RouterRepository {
  Future<JnapSuccess> getNetworkConnections() async {
    final command = createCommand(JNAPAction.getNetworkConnections.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
