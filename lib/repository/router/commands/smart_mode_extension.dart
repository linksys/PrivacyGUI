import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension SmartModeExtension on RouterRepository {
  Future<JNAPSuccess> getDeviceMode() async {
    final command = await createCommand(JNAPAction.getDeviceMode.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getSupportedDeviceMode() async {
    final command = await createCommand(
        JNAPAction.getSupportedDeviceMode.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setDeviceMode(String mode) async {
    final command = await createCommand(JNAPAction.setDeviceMode.actionValue,
        data: {'mode': mode}, needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }
}
