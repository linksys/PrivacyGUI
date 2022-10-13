import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/transaction.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension TransactionCommands on RouterRepository {
  Future<JnapSuccess> configureRouter({
    required String adminPassword,
    required String passwordHint,
    required List<SimpleWiFiSettings> settings,
  }) async {
    final transaction = JNAPTransaction(
      publishTopic: mqttLocalPublishTopic,
      responseTopic: mqttLocalResponseTopic,
      payload: [
        {
          'action': JNAPAction.coreSetAdminPassword.actionValue,
          'request': {
            'adminPassword': 'admin',
            // TODO #REFACTOR currently don't modify the password
            'passwordHint': passwordHint,
          }
        },
        // TODO #REFACTOR check device mode first
        {
          'action': JNAPAction.setDeviceMode.actionValue,
          'request': {'mode': 'Master'}
        },
        {
          'action': JNAPAction.setUnsecuredWiFiWarning.actionValue,
          'request': {'enabled': false}
        },
        {
          'action': JNAPAction.setSimpleWiFiSettings.actionValue,
          'request': {'simpleWiFiSettings': settings}
        },
      ],
    );
    final result = await transaction.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
