import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/actions/jnap_transaction.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

extension BatchCommands on RouterRepository {
  Future<List<MapEntry<JNAPAction, JNAPResult>>> fetchIsConfigured() async {
    return transaction(
      JNAPTransactionBuilder(commands: [
        const MapEntry(JNAPAction.isAdminPasswordSetByUser, {}),
        const MapEntry(JNAPAction.isAdminPasswordDefault, {}),
      ], auth: true),
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

  Future<List<MapEntry<JNAPAction, JNAPResult>>> fetchInternetSettings() async {
    return transaction(
      JNAPTransactionBuilder(commands: [
        const MapEntry(JNAPAction.getIPv6Settings, {}),
        const MapEntry(JNAPAction.getWANSettings, {}),
        const MapEntry(JNAPAction.getWANStatus, {}),
        const MapEntry(JNAPAction.getMACAddressCloneSettings, {}),
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
}
