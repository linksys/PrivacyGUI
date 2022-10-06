import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension CoreService on RouterRepository {
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

  Future<JnapSuccess> createAdminPassword(String password, String hint) async {
    final command =
    createCommand(JNAPAction.coreSetAdminPassword.actionValue, data: {
      'adminPassword': 'admin', // TODO currently don't modify the password
      'passwordHint': hint,
    });
    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getAdminPasswordAuthStatus() async {
    final command =
    createCommand(JNAPAction.getAdminPasswordAuthStatus.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getAdminPasswordHint() async {
    final command = createCommand(JNAPAction.getAdminPasswordHint.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getDataUploadUserConsent() async {
    final command =
        createCommand(JNAPAction.getDataUploadUserConsent.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getDeviceInfo() async {
    final command = createCommand(JNAPAction.getDeviceInfo.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> isAdminPasswordDefault() async {
    final command =
    createCommand(JNAPAction.isAdminPasswordDefault.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> reboot() async {
    final command = createCommand(JNAPAction.reboot.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
