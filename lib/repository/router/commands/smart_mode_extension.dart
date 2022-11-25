import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension SmartModeExtension on RouterRepository {
  Future<JNAPSuccess> getDeviceMode() async {
    final command = createCommand(JNAPAction.getDeviceMode.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
  Future<JNAPSuccess> getSupportedDeviceMode() async {
    final command = createCommand(JNAPAction.getSupportedDeviceMode.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
  Future<JNAPSuccess> setDeviceMode(String mode) async {
    final command = createCommand(JNAPAction.setDeviceMode.actionValue, data: {'mode': mode}, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
