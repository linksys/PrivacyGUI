import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension SetupService on RouterRepository {

  Future<JnapSuccess> isAdminPasswordSetByUser() async {
    final command =
        createCommand(JNAPAction.isAdminPasswordSetByUser.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

}
