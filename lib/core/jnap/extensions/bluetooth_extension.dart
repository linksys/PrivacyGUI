import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/jnap_command_queue.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

extension BluetoothService on RouterRepository {
  Future<JNAPSuccess> btGetScanUnconfiguredResult() async {
    final command = await createCommand(
        JNAPAction.btGetScanUnconfiguredResult.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> btRequestScanUnconfigured({int duration = 20}) async {
    final command = await createCommand(
        JNAPAction.btRequestScanUnconfigured.actionValue,
        needAuth: true,
        data: {'duration': duration});

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
