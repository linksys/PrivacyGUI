import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension BluetoothService on RouterRepository {
  Future<JNAPSuccess> btGetScanUnconfiguredResult() async {
    final command = await createCommand(
        JNAPAction.btGetScanUnconfiguredResult.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> btRequestScanUnconfigured({int duration = 20}) async {
    final command = await createCommand(
        JNAPAction.btRequestScanUnconfigured.actionValue,
        needAuth: true,
        data: {'duration': duration});

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }
}
