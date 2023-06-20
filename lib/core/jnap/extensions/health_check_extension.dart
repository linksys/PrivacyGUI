import 'package:linksys_moab/core/jnap/actions/better_action.dart';
import 'package:linksys_moab/core/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/core/jnap/result/jnap_result.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';

extension HealthCheckService on RouterRepository {
  Future<JNAPSuccess> getHealthCheckResults() async {
    final command = await createCommand(
        JNAPAction.getHealthCheckResults.actionValue,
        needAuth: true,
        data: {'includeModuleResults': true});

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getSupportedHealthCheckModules() async {
    final command = await createCommand(
        JNAPAction.getSupportedHealthCheckModules.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  // TODO: #REFACTOR : Support other type health check
  Future<JNAPSuccess> runHealthCheck() async {
    final command = await createCommand(JNAPAction.runHealthCheck.actionValue,
        needAuth: true, data: {'runHealthCheckModule': 'SpeedTest'});

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getHealthCheckStatus() async {
    final command = await createCommand(
        JNAPAction.getHealthCheckStatus.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
