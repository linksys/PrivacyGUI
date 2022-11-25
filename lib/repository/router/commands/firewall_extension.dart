import 'package:linksys_moab/model/router/port_range_forwarding_rule.dart';
import 'package:linksys_moab/model/router/port_range_triggering_rule.dart';
import 'package:linksys_moab/model/router/single_port_forwarding_rule.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

extension FirewallService on RouterRepository {
  Future<JNAPSuccess> getPortRangeForwardingRules() async {
    final command =
        createCommand(JNAPAction.getPortRangeForwardingRules.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getPortRangeTriggeringRules() async {
    final command =
        createCommand(JNAPAction.getPortRangeTriggeringRules.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getSinglePortForwardingRules() async {
    final command =
        createCommand(JNAPAction.getSinglePortForwardingRules.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setPortRangeForwardingRules(
      List<PortRangeForwardingRule> rules) async {
    final command = createCommand(
        JNAPAction.setPortRangeForwardingRules.actionValue, needAuth: true,
        data: {'rules': rules.map((e) => e.toJson()).toList()});

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setPortRangeTriggeringRules(
      List<PortRangeTriggeringRule> rules) async {
    final command = createCommand(
        JNAPAction.setPortRangeTriggeringRules.actionValue, needAuth: true,
        data: {'rules': rules.map((e) => e.toJson()).toList()});

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setSinglePortForwardingRules(
      List<SinglePortForwardingRule> rules) async {
    final command = createCommand(
        JNAPAction.setSinglePortForwardingRules.actionValue, needAuth: true,
        data: {'rules': rules.map((e) => e.toJson()).toList()});
    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
