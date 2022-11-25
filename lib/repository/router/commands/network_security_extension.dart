import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension NetworkSecurityService on RouterRepository {
  Future<JNAPSuccess> getNetworkSecuritySettings() async {
    final command =
        createCommand(JNAPAction.getNetworkSecuritySettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
