import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension HealthCheckService on RouterRepository {
  Future<JnapSuccess> getHealthCheckResults() async {
    final command = createCommand(JNAPAction.getHealthCheckResults.actionValue,
        data: {'includeModuleResults': true});

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getSupportedHealthCheckModules() async {
    final command =
        createCommand(JNAPAction.getSupportedHealthCheckModules.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  // TODO: #REFACTOR : Support other type health check
  Future<JnapSuccess> runHealthCheck() async {
    final command = createCommand(JNAPAction.runHealthCheck.actionValue,
        data: {'runHealthCheckModule': 'SpeedTest'});

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getHealthCheckStatus() async {
    final command = createCommand(JNAPAction.getHealthCheckStatus.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
