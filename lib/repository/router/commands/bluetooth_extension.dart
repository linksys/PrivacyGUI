import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension BluetoothService on RouterRepository {
  Future<JNAPSuccess> btGetScanUnconfiguredResult() async {
    final command =
        createCommand(JNAPAction.btGetScanUnconfiguredResult.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> btRequestScanUnconfigured({int duration = 20}) async {
    final command = createCommand(
        JNAPAction.btRequestScanUnconfigured.actionValue, needAuth: true,
        data: {'duration': duration});

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
