import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension FirewallService on RouterRepository {
  Future<JnapSuccess> getPortRangeForwardingRules() async {
    final command =
        createCommand(JNAPAction.getPortRangeForwardingRules.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getPortRangeTriggeringRules() async {
    final command =
        createCommand(JNAPAction.getPortRangeTriggeringRules.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getSinglePortForwardingRules() async {
    final command =
        createCommand(JNAPAction.getSinglePortForwardingRules.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
