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

  Future<JnapSuccess> resetAdminPassword(
      String resetCode, String password, String hint) async {
    final command =
        createCommand(JNAPAction.setupSetAdminPassword.actionValue, data: {
      'resetCode': resetCode,
      'adminPassword': password,
      'passwordHint': hint,
    });

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> verifyRouterResetCode(String resetCode) async {
    final command =
        createCommand(JNAPAction.verifyRouterResetCode.actionValue, data: {
      'resetCode': resetCode,
    });

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
