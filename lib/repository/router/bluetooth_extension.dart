import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension BluetoothService on RouterRepository {
  Future<JnapSuccess> btGetScanUnconfiguredResult() async {
    final command =
        createCommand(JNAPAction.btGetScanUnconfiguredResult.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> btRequestScanUnconfigured({int duration = 20}) async {
    final command = createCommand(
        JNAPAction.btRequestScanUnconfigured.actionValue,
        data: {'duration': duration});

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
