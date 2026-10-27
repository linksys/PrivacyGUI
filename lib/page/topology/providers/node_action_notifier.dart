import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/operation_guard.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/topology/services/usp_node_action_service.dart';

final nodeActionProvider =
    NotifierProvider<NodeActionNotifier, void>(NodeActionNotifier.new);

/// Reboots or factory-resets one mesh agent and the agents behind it (#876).
///
/// The controller is not handled here: its row refuses a node command (7002),
/// and its reboot and reset are `Device.Reboot()` / `Device.FactoryReset()`,
/// which the Administration page owns and which already take every child with
/// them (FWDEV#202).
class NodeActionNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Sends [action] to every node [plan] targets, in its order (farthest
  /// first), and returns the nodes it was sent to.
  ///
  /// The plan is the one the user confirmed ([MeshNetwork.nodeActionPlan]),
  /// not one rebuilt here: a topology refreshed between the dialog and the
  /// tap must not change which nodes go down. Farthest first because a node
  /// that restarts cuts off everything behind it.
  ///
  /// Both actions are `transientRestart`, so every mode allows them, Remote
  /// Assistance included (decided 2026-10-20). A node's factory reset leaves
  /// the controller's admin credential alone, so the session survives it,
  /// unlike the controller's own factory reset (`credentialLoss`).
  ///
  /// Each call takes the mutation lock on its own. One call can take the
  /// firmware's 25 s and the lock times out at 30 s, so one lock around the
  /// whole sequence would time out at the second node.
  ///
  /// Stops at the first failure and throws [NodeActionFailure], which names
  /// the node that failed and the nodes already sent. Throws
  /// [ResourceNotFoundError] without sending anything when the plan has no
  /// target.
  Future<List<String>> run(NodeAction action, NodeActionPlan plan) async {
    ref.read(operationGuardProvider).enforce(DisruptionClass.transientRestart,
        operation: 'node ${action.name}');

    final targets = plan.targets;
    if (targets.isEmpty) {
      throw const ResourceNotFoundError(detail: 'no mesh agent to send to');
    }

    final UspNodeActionService svc = ref.read(uspNodeActionServiceProvider);
    final lock = ref.read(uspMutationLockProvider);
    final sent = <String>[];
    for (final node in targets) {
      try {
        await lock.withLock(() => svc.run(action, node.deviceId));
      } on ServiceError catch (e) {
        logger.e(
            '[USP][NodeAction]: ${action.name} ${node.deviceId} failed '
            'after ${sent.length} sent',
            error: e);
        throw NodeActionFailure(
          cause: e,
          failedNodeId: node.deviceId,
          sentNodeIds: List.unmodifiable(sent),
        );
      } on TimeoutException catch (e) {
        logger.e(
            '[USP][NodeAction]: ${action.name} ${node.deviceId} timed '
            'out after ${sent.length} sent',
            error: e);
        throw NodeActionFailure(
          cause: TimeoutError(detail: e.message),
          failedNodeId: node.deviceId,
          sentNodeIds: List.unmodifiable(sent),
        );
      }
      sent.add(node.deviceId);
    }
    return sent;
  }
}

/// A node action that stopped partway (#876).
///
/// Not a [ServiceError] subtype, so named `…Failure` (constitution §3.3.5
/// keeps `…Error` for those), as `FirmwareValidationFailure` is: it carries
/// one, [cause], and adds which node it happened on and which nodes had
/// already accepted, which a single error type cannot say. The page localizes
/// [cause] as usual and names the nodes around it.
class NodeActionFailure implements Exception {
  /// Why the call to [failedNodeId] failed.
  final ServiceError cause;

  /// The node whose call failed. It may still act: a 7022 or a timeout is
  /// not final, because linksys-mesh-sync sends the command once more within
  /// 20 s, and a command that reached the agent runs even if its confirm is
  /// lost.
  final String failedNodeId;

  /// The nodes that accepted before it, in the order they were sent.
  final List<String> sentNodeIds;

  const NodeActionFailure({
    required this.cause,
    required this.failedNodeId,
    required this.sentNodeIds,
  });

  @override
  String toString() => 'NodeActionFailure($failedNodeId after $sentNodeIds: '
      '$cause)';
}
