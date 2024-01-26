import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/jnap_command_queue.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

extension WirelessApService on RouterRepository {
  Future<JNAPSuccess> getRadioInfo() async {
    final command = await createCommand(JNAPAction.getRadioInfo.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getWPSServerSessionStatus() async {
    final command = await createCommand(
        JNAPAction.getWPSServerSessionStatus.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
