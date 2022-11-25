import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension QosService on RouterRepository {
  Future<JNAPSuccess> getQoSSettings() async {
    final command = createCommand(JNAPAction.getQoSSettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
