import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension CoreService on RouterRepository {
  // Core service
  Future<JnapSuccess> isAdminPasswordDefault() async {
    final command =
        createCommand('http://linksys.com/jnap/core/IsPasswordAdminDefault');

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> isAdminPasswordSetByUser() async {
    final command =
        createCommand('http://linksys.com/jnap/core/IsAdminPasswordSetByUser');

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getDeviceInfo() async {
    final command =
    createCommand('http://linksys.com/jnap/core/GetDeviceInfo');

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getAdminPasswordInfo() async {
    final command =
        createCommand('http://linksys.com/jnap/core/GetAdminPasswordHint');

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> checkAdminPassword(String password) async {
    final command = createCommand(
      'http://linksys.com/jnap/core/CheckAdminPassword2',
      data: {
        'adminPassword': password,
      },
    );
    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> createPassword(String password, String hint) async {
    final command =
        createCommand('http://linksys.com/jnap/core/CheckAdminPassword', data: {
      'adminPassword': password,
      'passwordHint': hint,
    });
    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
