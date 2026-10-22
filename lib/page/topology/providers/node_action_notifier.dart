import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/operation_guard.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
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

  /// Sends [action] to [deviceId] and to every agent behind it, farthest first,
  /// and returns the nodes it was sent to in that order.
  ///
  /// Farthest first because a node that restarts cuts off everything behind
  /// it, so a command to a node behind it has to be accepted before.
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
  /// Stops at the first failure and throws [NodeActionError], which names the
  /// node that failed and the nodes already sent. Throws
  /// [ResourceNotFoundError] without sending anything when [deviceId] is not
  /// an agent in the current topology.
  Future<List<String>> run(NodeAction action, String deviceId) async {
    ref.read(operationGuardProvider).enforce(DisruptionClass.transientRestart,
        operation: 'node ${action.name}');

    final network = ref.read(devicesDataProvider).valueOrNull?.meshNetwork;
    final targets = network?.nodesBehind(deviceId).nodes ?? const [];
    if (targets.isEmpty) {
      throw ResourceNotFoundError(detail: '$deviceId is not a mesh agent');
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
        throw NodeActionError(
          cause: e,
          failedNodeId: node.deviceId,
          sentNodeIds: List.unmodifiable(sent),
        );
      } on TimeoutException catch (e) {
        logger.e(
            '[USP][NodeAction]: ${action.name} ${node.deviceId} timed '
            'out after ${sent.length} sent',
            error: e);
        throw NodeActionError(
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
/// Not a [ServiceError] subtype: it carries one, [cause], and adds which node
/// it happened on and which nodes had already accepted, which a single error
/// type cannot say. The page localizes [cause] as usual and names the nodes
/// around it.
class NodeActionError implements Exception {
  /// Why the call to [failedNodeId] failed.
  final ServiceError cause;

  /// The node whose call failed. It may still act: a 7022 timeout is not
  /// final, because linksys-mesh-sync resends once after the call returned.
  final String failedNodeId;

  /// The nodes that accepted before it, in the order they were sent.
  final List<String> sentNodeIds;

  const NodeActionError({
    required this.cause,
    required this.failedNodeId,
    required this.sentNodeIds,
  });

  @override
  String toString() => 'NodeActionError($failedNodeId after $sentNodeIds: '
      '$cause)';
}
