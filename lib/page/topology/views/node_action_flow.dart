import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/admin/views/dialogs/confirm_action_dialog.dart';
import 'package:privacy_gui/page/admin/views/router_restart_actions.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/providers/node_action_notifier.dart';

/// Which node actions [node] offers (#876).
///
/// The router offers both: they are the Administration page's
/// `Device.Reboot()` / `Device.FactoryReset()`, and FWDEV#202 gives its row no
/// node commands. An agent offers what it reports in
/// `X_LINKSYS_SupportedOperations`.
Set<NodeAction> nodeActionsOf(NodeEntity node) => switch (node) {
      MasterNode() => NodeAction.values.toSet(),
      SlaveNode(:final actions) => actions,
    };

/// Confirms, then runs [action] on [node], wherever it was offered: the node
/// detail page's actions card and the topology's node menu (#876).
///
/// The router runs the Administration page's own flow. An agent runs a node
/// command on itself and every agent behind it: one [NodeActionPlan] is built
/// here and the same plan is sent, so the nodes the user agreed to are the
/// nodes that get the command. The confirmation names every node that receives
/// it, farthest first; the nodes behind that cannot run it, which go down
/// without receiving it; and, when a node with no reported parent may be
/// behind this one, that it may go down too.
///
/// [onSent] runs once an agent's command has been accepted. The detail page
/// leaves for the topology there, because the node leaves DataElements while
/// it restarts and empties that page; the topology stays where it is.
Future<void> confirmAndRunNodeAction(
  BuildContext context,
  WidgetRef ref,
  NodeEntity node,
  NodeAction action, {
  VoidCallback? onSent,
}) =>
    switch ((node, action)) {
      (MasterNode(), NodeAction.reboot) => confirmAndRebootRouter(context, ref),
      (MasterNode(), NodeAction.factoryReset) =>
        confirmAndFactoryResetRouter(context, ref),
      (SlaveNode(), _) =>
        _confirmAndRunAgentAction(context, ref, node, action, onSent: onSent),
    };

Future<void> _confirmAndRunAgentAction(
  BuildContext context,
  WidgetRef ref,
  NodeEntity node,
  NodeAction action, {
  VoidCallback? onSent,
}) async {
  final network = ref.read(devicesDataProvider).valueOrNull?.meshNetwork;
  final plan = network?.nodeActionPlan(action, node.deviceId);
  if (plan == null || plan.targets.isEmpty) return;
  final l = loc(context);
  String nameOf(String id) => network?.findNode(id)?.displayName ?? id;
  String namesOf(List<SlaveNode> nodes) =>
      nodes.map((n) => n.displayName).join(', ');
  final names = namesOf(plan.targets);
  final single = plan.targets.length == 1;

  final message = [
    switch ((action, single)) {
      (NodeAction.reboot, true) => l.rebootNodeMessage(names),
      (NodeAction.reboot, false) => l.rebootNodesMessage(names),
      (NodeAction.factoryReset, true) => l.factoryResetNodeMessage(names),
      (NodeAction.factoryReset, false) => l.factoryResetNodesMessage(names),
    },
    if (plan.skipped.isNotEmpty)
      l.nodeActionSkippedNodes(namesOf(plan.skipped)),
    if (plan.mayMissNodes) l.nodeActionMayMissNodes,
  ].join('\n\n');
  final confirmed = await showConfirmActionDialog(
    context,
    title: switch ((action, single)) {
      (NodeAction.reboot, true) => l.rebootUnit,
      (NodeAction.reboot, false) => l.rebootChildTitle,
      (NodeAction.factoryReset, true) => l.resetToFactoryDefault,
      (NodeAction.factoryReset, false) => l.factoryResetChildTitle,
    },
    message: message,
    confirmLabel: switch (action) {
      NodeAction.reboot => l.restart,
      NodeAction.factoryReset => l.reset,
    },
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await doSomethingWithSpinner(
      context,
      ref.read(nodeActionProvider.notifier).run(action, plan),
    );
    if (!context.mounted) return;
    showSuccessSnackBar(
      context,
      switch (action) {
        NodeAction.reboot => l.nodeActionRebootSent,
        NodeAction.factoryReset => l.nodeActionResetSent,
      },
    );
    // Not awaited: the nodes leave DataElements on their own schedule, and the
    // topology picks the result up.
    ref.read(devicesDataProvider.notifier).refetch();
    onSent?.call();
  } on NodeActionFailure catch (e) {
    if (!context.mounted) return;
    final failure = _nodeActionFailureText(context, e, nameOf);
    showFailedSnackBar(
      context,
      e.sentNodeIds.isEmpty
          ? failure
          : l.nodeActionFailedAfterSent(
              failure, e.sentNodeIds.map(nameOf).join(', ')),
    );
  } catch (e) {
    if (context.mounted) {
      showFailedSnackBar(context, localizeServiceError(context, e));
    }
  }
}

/// What to say about the node a [NodeActionFailure] stopped at.
///
/// Two causes get the node's own sentence instead of the app-wide one. A
/// refusal (7022: the agent did not confirm, was unreachable, or does not run
/// the command) is not final, because linksys-mesh-sync resends once after the
/// call returned (FWDEV#202), so it says the node may still act and does not
/// invite an immediate retry, which could reset it twice. A node not found
/// (7016, or no longer listed) has left the network. Any other cause, a lost
/// connection say, keeps its usual message.
String _nodeActionFailureText(BuildContext context, NodeActionFailure e,
    String Function(String id) nameOf) {
  final l = loc(context);
  final node = nameOf(e.failedNodeId);
  return switch (e.cause) {
    UspCompleteFailureError(code: 7022) => l.nodeActionNotConfirmed(node),
    ResourceNotFoundError() => l.nodeActionNodeGone(node),
    final cause =>
      l.nodeActionFailed(node, localizeServiceError(context, cause)),
  };
}
