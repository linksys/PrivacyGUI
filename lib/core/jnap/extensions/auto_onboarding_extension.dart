import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/jnap_command_queue.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

extension AutoOnboardingService on RouterRepository {
  Future<JNAPSuccess> getBluetoothAutoOnboardingSettings() async {
    final command = await createCommand(
        JNAPAction.getBluetoothAutoOnboardingSettings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getBlueboothAutoOnboardingStatus() async {
    final command = await createCommand(
        JNAPAction.getBlueboothAutoOnboardingStatus.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> startBlueboothAutoOnboarding() async {
    final command = await createCommand(
        JNAPAction.startBlueboothAutoOnboarding.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
