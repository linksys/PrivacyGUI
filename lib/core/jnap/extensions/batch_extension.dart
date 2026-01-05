import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

extension BatchCommands on RouterRepository {
  Future<List<MapEntry<JNAPAction, JNAPResult>>> fetchIsConfigured() async {
    return transaction(
      JNAPTransactionBuilder(commands: [
        const MapEntry(JNAPAction.isAdminPasswordSetByUser, {}),
        const MapEntry(JNAPAction.isAdminPasswordDefault, {}),
      ], auth: true),
      fetchRemote: true,
    ).then((successWrap) => successWrap.data);
  }

  Future<List<MapEntry<JNAPAction, JNAPResult>>> fetchIpDetails() async {
    return transaction(
      JNAPTransactionBuilder(commands: [
        const MapEntry(JNAPAction.getDevices, {}),
        const MapEntry(JNAPAction.getWANStatus, {}),
      ], auth: true),
    ).then((successWrap) => successWrap.data);
  }

  /*
  Future<Map<JNAPAction, JNAPResult>> fetchDeviceList() async {
    return transaction(JNAPTransactionBuilder(
      commands: {
        JNAPAction.getNetworkConnections: {},
        JNAPAction.getDevices: {},
      },
      auth: true,
    )).then((successWrap) => successWrap.data);
  }
  */

  Future<List<MapEntry<JNAPAction, JNAPResult>>> deleteDevices(
    List<String> deviceIds,
  ) async {
    return transaction(
      JNAPTransactionBuilder(
        commands: deviceIds
            .map((e) => MapEntry(JNAPAction.deleteDevice, {'deviceID': e}))
            .toList(),
        auth: true,
      ),
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    ).then(
      (successWrap) => successWrap.data,
    );
  }

  Future<List<MapEntry<JNAPAction, JNAPResult>>> fetchAllRadioInfo() {
    return transaction(
      JNAPTransactionBuilder(commands: [
        const MapEntry(JNAPAction.getRadioInfo, {}),
        const MapEntry(JNAPAction.getGuestRadioSettings, {}),
      ], auth: true),
    ).then((successWrap) => successWrap.data);
  }

  Future<List<MapEntry<JNAPAction, JNAPResult>>> fetchCreateTicketDeviceInfo(
      {bool fetchRemote = false}) async {
    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = [
      // Internet settings
      const MapEntry(JNAPAction.getIPv6Settings, {}),
      const MapEntry(JNAPAction.getWANSettings, {}),
      const MapEntry(JNAPAction.getWANStatus, {}),
      const MapEntry(JNAPAction.getMACAddressCloneSettings, {}),
      // LAN settings
      const MapEntry(JNAPAction.getLANSettings, {}),
      // Wifi settings
      const MapEntry(JNAPAction.getRadioInfo, {}),
      const MapEntry(JNAPAction.getGuestRadioSettings, {}),
      // Device info
      const MapEntry(JNAPAction.getDevices, {}),
      // Firmware updates info
      const MapEntry(JNAPAction.getFirmwareUpdateSettings, {}),
    ];
    if (serviceHelper.isSupportNodeFirmwareUpdate()) {
      commands.add(
        const MapEntry(JNAPAction.getNodesFirmwareUpdateStatus, {}),
      );
    } else {
      commands.add(
        const MapEntry(JNAPAction.getFirmwareUpdateStatus, {}),
      );
    }
    return transaction(
      fetchRemote: fetchRemote,
      JNAPTransactionBuilder(commands: commands, auth: true),
    ).then((successWrap) => successWrap.data);
  }
}
