import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension BatchCommands on RouterRepository {
  Future<List<JnapSuccess>> fetchIsConfigured() async {
    return batchCommands([
      CommandWrap(
        action: JNAPAction.isAdminPasswordSetByUser.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.isAdminPasswordDefault.actionValue,
        needAuth: false,
      ),
    ]);
  }
}
