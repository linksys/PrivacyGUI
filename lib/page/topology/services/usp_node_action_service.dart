import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/data_elements_network_operations.g.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';

final uspNodeActionServiceProvider = Provider<UspNodeActionService>(
  (ref) => UspNodeActionService(ref.read(uspClientProvider)!),
);

/// Runs a command on one mesh agent (FWDEV#202, #876).
///
/// One node per call. Which nodes, in which order, and the mutation lock around
/// each call belong to the caller: a node command reaches only the node that
/// receives it, and one call can take the firmware's whole 25 s.
class UspNodeActionService {
  final UspClient _usp;

  UspNodeActionService(this._usp);

  static const _devices = 'Device.WiFi.DataElements.Network.Device.';

  /// Sends [action] to the agent whose AL MAC is [alMac].
  ///
  /// The `Device.{i}` row is looked up by `ID` on a fresh read right before the
  /// call, as FWDEV#202 asks: instance numbers change when a node leaves or
  /// joins, and a stale one would send the command to a different node. A node
  /// no longer listed throws [ResourceNotFoundError] without sending anything.
  ///
  /// Returning means the agent accepted; it restarts a few seconds later.
  Future<void> run(NodeAction action, String alMac) async {
    try {
      final instance = await _instanceOf(alMac);
      if (instance == null) {
        throw ResourceNotFoundError(detail: '$alMac is not in DataElements');
      }
      switch (action) {
        case NodeAction.reboot:
          await DataElementsNetworkOperations.nodeReboot(_usp, instance);
        case NodeAction.factoryReset:
          await DataElementsNetworkOperations.nodeFactoryReset(_usp, instance);
      }
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  Future<int?> _instanceOf(String alMac) async {
    final ids = await _usp.get(['$_devices*.ID'], fresh: true);
    final wanted = alMac.toUpperCase();
    for (final entry in ids.entries) {
      if (entry.value?.toString().toUpperCase() != wanted) continue;
      final match = RegExp(r'\.Device\.(\d+)\.ID$').firstMatch(entry.key);
      if (match != null) return int.parse(match.group(1)!);
    }
    return null;
  }
}
