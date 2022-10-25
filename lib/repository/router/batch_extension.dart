import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension BatchCommands on RouterRepository {
  Future<Map<String, JnapSuccess>> fetchIsConfigured() async {
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

  Future<Map<String, JnapSuccess>> pollingData() async {
    return batchCommands([
      //TODO: We need to check if the certain actions and services are available before adding them into the list
      CommandWrap(
        action: JNAPAction.getDeviceInfo.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getWANStatus.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getNodesWirelessNetworkConnections.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getRadioInfo.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getDevices.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getHealthCheckResults.actionValue,
        needAuth: false,
        data: {'includeModuleResults': true},
      ),
      CommandWrap(
        action: JNAPAction.getSupportedHealthCheckModules.actionValue,
        needAuth: false,
      ),
    ]);
  }
}
