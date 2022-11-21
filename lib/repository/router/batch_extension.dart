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

  Future<Map<String, JnapSuccess>> fetchIpDetails() async {
    return batchCommands([
      CommandWrap(
        action: JNAPAction.getDevices.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getWANStatus.actionValue,
        needAuth: false,
      ),
    ]);
  }

  Future<Map<String, JnapSuccess>> fetchInternetSettings() async {
    return batchCommands([
      CommandWrap(
        action: JNAPAction.getIPv6Settings.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getWANSettings.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getWANStatus.actionValue,
        needAuth: false,
      ),
    ]);
  }

  Future<Map<String, JnapSuccess>> fetchNodeDetails() async {
    return batchCommands([
      CommandWrap(
        action: JNAPAction.getWANStatus.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getDevices.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getFirmwareUpdateStatus.actionValue,
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

  Future<Map<String, JnapSuccess>> fetchDeviceList() async {
    return batchCommands([
      CommandWrap(
        action: JNAPAction.getNetworkConnections.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getDevices.actionValue,
        needAuth: false,
      ),
    ]);
  }

  Future<Map<String, JnapSuccess>> deleteDevices(List<String> deviceIdList) async {
    List<CommandWrap> commands = [];
    for (String deviceId in deviceIdList) {
      commands.add(CommandWrap(
        action: JNAPAction.deleteDevice.actionValue,
        needAuth: false,
        data: {'deviceID': deviceId},
      ));
    }
    return batchCommands(commands);
  }
}
