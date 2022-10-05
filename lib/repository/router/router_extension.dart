import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension SetupService on RouterRepository {

  Stream<JnapResult> testGetWANDetectionStatus({
    int retryDelayInSec = 5,
    int maxRetry = 10,
    bool Function()? condition,
  }) {
    final command = createCommand(JNAPAction.getWANDetectionStatus.actionValue);
    return command
        .publishWithRetry(mqttClient!,
            retryDelayInSec: retryDelayInSec, maxRetry: maxRetry, condition: condition)
        .map((event) => handleJnapResult(event.body));
  }

  Future<JnapSuccess> getWANStatus() async {
    final command = createCommand(JNAPAction.getWANStatus.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getWANDetectionStatus() async {
    final command = createCommand(JNAPAction.getWANDetectionStatus.actionValue, needAuth: true);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

}
