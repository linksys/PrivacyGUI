import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension CoreService on RouterRepository {
  // Core service
  Future<JnapSuccess> isAdminPasswordDefault() async {
    final command =
        createCommand(JNAPAction.isAdminPasswordDefault.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> isAdminPasswordSetByUser() async {
    final command =
        createCommand(JNAPAction.isAdminPasswordSetByUser.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getDeviceInfo() async {
    final command =
    createCommand(JNAPAction.getDeviceInfo.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getAdminPasswordHint() async {
    final command =
        createCommand(JNAPAction.getAdminPasswordHint.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> checkAdminPassword(String password) async {
    final command = createCommand(
      JNAPAction.checkAdminPassword.actionValue,
      data: {
        'adminPassword': password,
      },
    );
    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  // TODO
  Future<JnapSuccess> createPassword(String password, String hint) async {
    final command =
        createCommand(JNAPAction.coreSetAdminPassword.actionValue, data: {
      'adminPassword': password,
      'passwordHint': hint,
    });
    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
