import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension MacFilterService on RouterRepository {
  Future<JNAPSuccess> getMACFilterSettings() async {
    final command = await createCommand(
        JNAPAction.getMACFilterSettings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
