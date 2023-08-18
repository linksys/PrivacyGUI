import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/actions/jnap_transaction.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

extension BatchCommands on RouterRepository {
  Future<Map<JNAPAction, JNAPResult>> fetchIsConfigured() async {
    return transaction(
      JNAPTransactionBuilder(commands: {
        JNAPAction.isAdminPasswordSetByUser: {},
        JNAPAction.isAdminPasswordDefault: {},
      }, auth: true),
    ).then((successWrap) => successWrap.data);
  }

  Future<Map<JNAPAction, JNAPResult>> fetchIpDetails() async {
    return transaction(
      JNAPTransactionBuilder(commands: {
        JNAPAction.getDevices: {},
        JNAPAction.getWANStatus: {},
      }, auth: true),
    ).then((successWrap) => successWrap.data);
  }

  Future<Map<JNAPAction, JNAPResult>> fetchInternetSettings() async {
    return transaction(
      JNAPTransactionBuilder(commands: {
        JNAPAction.getIPv6Settings: {},
        JNAPAction.getWANSettings: {},
        JNAPAction.getWANStatus: {},
        JNAPAction.getMACAddressCloneSettings: {},
      }, auth: true),
    ).then((successWrap) => successWrap.data);
  }

  Future<Map<JNAPAction, JNAPResult>> fetchNodeDetails() async {
    return transaction(
      JNAPTransactionBuilder(commands: {
        JNAPAction.getWANStatus: {},
        JNAPAction.getDevices: {},
        JNAPAction.getFirmwareUpdateStatus: {},
      }, auth: true),
    ).then((successWrap) => successWrap.data);
  }

  Future<Map<JNAPAction, JNAPResult>> fetchDeviceList() async {
    return transaction(JNAPTransactionBuilder(
      commands: {
        JNAPAction.getNetworkConnections: {},
        JNAPAction.getDevices: {},
      },
      auth: true,
    )).then((successWrap) => successWrap.data);
  }

  Future<Map<JNAPAction, JNAPResult>> deleteDevices(
      List<String> deviceIdList) async {
    return transaction(
      JNAPTransactionBuilder(
        commands: Map.fromEntries(
          deviceIdList
              .map(
                (e) => MapEntry(
                  JNAPAction.deleteDevice,
                  {'deviceID': e},
                ),
              )
              .toList(),
        ),
        auth: true,
      ),
    ).then((successWrap) => successWrap.data);
  }

  Future<Map<JNAPAction, JNAPResult>> fetchAllRadioInfo() {
    return transaction(
      JNAPTransactionBuilder(commands: {
        JNAPAction.getRadioInfo: {},
        JNAPAction.getGuestRadioSettings: {},
      }, auth: true),
    ).then((successWrap) => successWrap.data);
  }
}
