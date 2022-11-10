import 'package:linksys_moab/bloc/add_nodes/state.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/transaction.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/repository/router/smart_mode_extension.dart';

extension TransactionCommands on RouterRepository {
  Future<JnapSuccess> configureDeviceProperties({
    required List<NodeProperties> deviceProperties,
  }) async {
    final payload = deviceProperties
        .map((e) => JNAPTransaction.wrapCommandPayload(
                action: JNAPAction.setDeviceProperties,
                data: {
                  'deviceID': e.deviceId,
                  'propertiesToModify': e.buildPropertiesToModify(),
                  'propertiesToRemove': [],
                }))
        .toList();
    final transaction = JNAPTransaction(
      publishTopic: mqttLocalPublishTopic,
      responseTopic: mqttLocalResponseTopic,
      payload: payload,
    );
    final result = await transaction.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> configureRouter({
    required String adminPassword,
    required String passwordHint,
    required List<SimpleWiFiSettings> settings,
  }) async {
    final deviceMode = (await getDeviceMode()).output['mode'] ?? 'Unconfigured';
    var payload = [
      JNAPTransaction.wrapCommandPayload(
          action: JNAPAction.coreSetAdminPassword,
          data: {
            'adminPassword': 'admin',
            // TODO #REFACTOR currently don't modify the password
            'passwordHint': passwordHint,
          }),
      JNAPTransaction.wrapCommandPayload(
          action: JNAPAction.setDeviceMode, data: {'mode': 'Master'}),
      JNAPTransaction.wrapCommandPayload(
          action: JNAPAction.setUnsecuredWiFiWarning, data: {'enabled': false}),
      JNAPTransaction.wrapCommandPayload(
          action: JNAPAction.setSimpleWiFiSettings,
          data: {'simpleWiFiSettings': settings}),
    ];
    if (deviceMode == 'Master') {
      payload.removeWhere((element) =>
          element['action'] == JNAPAction.setDeviceMode.actionValue);
    }
    if (adminPassword.isEmpty) {
      payload.removeWhere((element) =>
      element['action'] == JNAPAction.coreSetAdminPassword.actionValue);
    }
    final transaction = JNAPTransaction(
      publishTopic: mqttLocalPublishTopic,
      responseTopic: mqttLocalResponseTopic,
      payload: payload,
    );
    final result = await transaction.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
