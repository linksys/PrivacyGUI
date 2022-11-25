import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension HealthCheckService on RouterRepository {
  Future<JNAPSuccess> getHealthCheckResults() async {
    final command = createCommand(JNAPAction.getHealthCheckResults.actionValue, needAuth: true,
        data: {'includeModuleResults': true});

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getSupportedHealthCheckModules() async {
    final command =
        createCommand(JNAPAction.getSupportedHealthCheckModules.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  // TODO: #REFACTOR : Support other type health check
  Future<JNAPSuccess> runHealthCheck() async {
    final command = createCommand(JNAPAction.runHealthCheck.actionValue, needAuth: true,
        data: {'runHealthCheckModule': 'SpeedTest'});

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getHealthCheckStatus() async {
    final command = createCommand(JNAPAction.getHealthCheckStatus.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
