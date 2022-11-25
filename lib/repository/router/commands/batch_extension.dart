import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension BatchCommands on RouterRepository {
  Future<Map<String, JNAPSuccess>> fetchIsConfigured() async {
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

  Future<Map<String, JNAPSuccess>> fetchIpDetails() async {
    return batchCommands([
      CommandWrap(
        action: JNAPAction.getDevices.actionValue,
        needAuth: true,
      ),
      CommandWrap(
        action: JNAPAction.getWANStatus.actionValue,
        needAuth: true,
      ),
    ]);
  }

  Future<Map<String, JNAPSuccess>> fetchInternetSettings() async {
    return batchCommands([
      CommandWrap(
        action: JNAPAction.getIPv6Settings.actionValue,
        needAuth: true,
      ),
      CommandWrap(
        action: JNAPAction.getWANSettings.actionValue,
        needAuth: true,
      ),
      CommandWrap(
        action: JNAPAction.getWANStatus.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getMACAddressCloneSettings.actionValue,
        needAuth: true,
      ),
    ]);
  }

  Future<Map<String, JNAPSuccess>> fetchNodeDetails() async {
    return batchCommands([
      CommandWrap(
        action: JNAPAction.getWANStatus.actionValue,
        needAuth: false,
      ),
      CommandWrap(
        action: JNAPAction.getDevices.actionValue,
        needAuth: true,
      ),
      CommandWrap(
        action: JNAPAction.getFirmwareUpdateStatus.actionValue,
        needAuth: true,
      ),
    ]);
  }

  Future<Map<String, JNAPSuccess>> pollingData() async {
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
        needAuth: true,
      ),
      CommandWrap(
        action: JNAPAction.getRadioInfo.actionValue,
        needAuth: true,
      ),
      CommandWrap(
        action: JNAPAction.getGuestRadioSettings.actionValue,
        needAuth: true,
      ),
      CommandWrap(
        action: JNAPAction.getDevices.actionValue,
        needAuth: true,
      ),
      CommandWrap(
        action: JNAPAction.getHealthCheckResults.actionValue,
        needAuth: true,
        data: {'includeModuleResults': true},
      ),
      CommandWrap(
        action: JNAPAction.getSupportedHealthCheckModules.actionValue,
        needAuth: true,
      ),
    ]);
  }

  Future<Map<String, JNAPSuccess>> fetchDeviceList() async {
    return batchCommands([
      CommandWrap(
        action: JNAPAction.getNetworkConnections.actionValue,
        needAuth: true,
      ),
      CommandWrap(
        action: JNAPAction.getDevices.actionValue,
        needAuth: true,
      ),
    ]);
  }

  Future<Map<String, JNAPSuccess>> deleteDevices(
      List<String> deviceIdList) async {
    List<CommandWrap> commands = [];
    for (String deviceId in deviceIdList) {
      commands.add(CommandWrap(
        action: JNAPAction.deleteDevice.actionValue,
        needAuth: true,
        data: {'deviceID': deviceId},
      ));
    }
    return batchCommands(commands);
  }

  Future<Map<String, JNAPSuccess>> fetchAllRadioInfo() async {
    return batchCommands([
      CommandWrap(
        action: JNAPAction.getRadioInfo.actionValue,
        needAuth: true,
      ),
      CommandWrap(
        action: JNAPAction.getGuestRadioSettings.actionValue,
        needAuth: true,
      ),
    ]);
  }
}
