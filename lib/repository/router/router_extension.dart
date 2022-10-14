import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension RouterService on RouterRepository {
  Future<JnapSuccess> getDHCPClientLeases() async {
    final command = createCommand(JNAPAction.getDHCPClientLeases.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getIPv6Settings() async {
    final command = createCommand(JNAPAction.getIPv6Settings.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getLANSettings() async {
    final command = createCommand(JNAPAction.getLANSettings.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getMACAddressCloneSettings() async {
    final command =
        createCommand(JNAPAction.getMACAddressCloneSettings.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getWANSettings() async {
    final command = createCommand(JNAPAction.getWANSettings.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getWANStatus() async {
    final command = createCommand(JNAPAction.getWANStatus.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

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

  Future<JnapSuccess> getWANDetectionStatus() async {
    final command = createCommand(JNAPAction.getWANDetectionStatus.actionValue, needAuth: true);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
