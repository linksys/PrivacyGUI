import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension ParentalControlService on RouterRepository {
  Future<JNAPSuccess> getParentalControlSettings() async {
    final command =
        createCommand(JNAPAction.getParentalControlSettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
