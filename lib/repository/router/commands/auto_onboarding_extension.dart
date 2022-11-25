import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension AutoOnboardingService on RouterRepository {
  Future<JNAPSuccess> getBluetoothAutoOnboardingSettings() async {
    final command =
        createCommand(JNAPAction.getBluetoothAutoOnboardingSettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
  Future<JNAPSuccess> getBlueboothAutoOnboardingStatus() async {
    final command =
    createCommand(JNAPAction.getBlueboothAutoOnboardingStatus.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
  Future<JNAPSuccess> startBlueboothAutoOnboarding() async {
    final command =
    createCommand(JNAPAction.startBlueboothAutoOnboarding.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
