import 'package:linksys_moab/model/router/port_range_forwarding_rule.dart';
import 'package:linksys_moab/model/router/port_range_triggering_rule.dart';
import 'package:linksys_moab/model/router/single_port_forwarding_rule.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

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

  Future<JnapSuccess> setPortRangeForwardingRules(
      List<PortRangeForwardingRule> rules) async {
    final command = createCommand(
        JNAPAction.setPortRangeForwardingRules.actionValue,
        data: {'rules': rules.map((e) => e.toJson()).toList()});

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> setPortRangeTriggeringRules(
      List<PortRangeTriggeringRule> rules) async {
    final command = createCommand(
        JNAPAction.setPortRangeTriggeringRules.actionValue,
        data: {'rules': rules.map((e) => e.toJson()).toList()});

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> setSinglePortForwardingRules(
      List<SinglePortForwardingRule> rules) async {
    final command = createCommand(
        JNAPAction.setSinglePortForwardingRules.actionValue,
        data: {'rules': rules.map((e) => e.toJson()).toList()});
    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
