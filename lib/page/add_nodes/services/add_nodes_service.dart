import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/ble_onboarding.g.dart';
import 'package:privacy_gui/generated/ble_onboarding_operations.g.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_backhaul_link.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_node_identity.dart';
import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final addNodesServiceProvider = Provider<AddNodesService>((ref) {
  final usp = ref.read(uspClientProvider);
  if (usp == null) {
    throw const ServiceNotInitializedError(detail: 'USP service not available');
  }
  return AddNodesService(usp);
});

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Adds nodes to the mesh over BLE: `Device.X_LINKSYS_BLEOnboarding.`
/// (linksys/FWDEV#164), and DataElements to see a node actually join.
///
/// Every command is a synchronous Operate on the controller. Its verdict is the
/// `Result` output, never a USP fault: a fault from a synchronous bbfdm operate
/// reaches the client as a success with empty output (dm_reflector.c), so a
/// response with no `Result` at all is a failure, not a success.
///
/// Stateless. The session lives on the router; the notifier polls it.
class AddNodesService {
  final UspClient _usp;

  AddNodesService(this._usp);

  static const _tag = '[USP][AddNodes]';

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  /// Starts onboarding every unconfigured node in range, strongest first — the
  /// same operation as the controller's pairing button.
  ///
  /// Without a MAC list on purpose: an *empty* list is a different request
  /// (onboard none), and the firmware tells the two apart by whether the
  /// `MACAddresses` argument is present at all.
  ///
  /// A refusal is returned, not thrown — it is an answer the page shows. Throws
  /// [ServiceError] when the router could not be asked, or answered with no
  /// verdict or one outside the documented set (`Error`, `InvalidInput`).
  ///
  /// Sent with the client's usual 401 retry. A retry follows a request the
  /// bridge refused before the router ran it, so it is the first real `Start()`,
  /// not a second one — and if the first had run, the second would answer
  /// [OnboardingStartResult.busy] rather than start another session.
  Future<OnboardingStartResult> start() async {
    final Map<String, dynamic> output;
    try {
      output = await BleOnboardingOperations.start(_usp);
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    final result = output['Result']?.toString();
    switch (result) {
      case 'Started':
        return OnboardingStartResult.started;
      case 'Busy':
        return OnboardingStartResult.busy;
      case 'UnsupportedRole':
        return OnboardingStartResult.unsupportedRole;
      case 'BackendUnavailable':
        return OnboardingStartResult.backendUnavailable;
    }
    // `Error` (the handler failed or ran past 8 s), `InvalidInput` (which a
    // request with no MAC list cannot earn) and no `Result` at all. The detail is
    // logged rather than carried: UnexpectedError surfaces `detail` to the user.
    logger.w('$_tag Start() answered ${result ?? 'no Result'}');
    throw const UnexpectedError();
  }

  /// Stops the running session. Idempotent: the router answers `Success` also
  /// when nothing was running.
  ///
  /// Throws [ServiceError] when the router could not be asked or did not answer
  /// `Success`.
  Future<void> stop() async {
    final Map<String, dynamic> output;
    try {
      output = await BleOnboardingOperations.stop(_usp);
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    final result = output['Result']?.toString();
    if (result == 'Success') return;
    logger.w('$_tag Stop() answered ${result ?? 'no Result'}');
    throw const UnexpectedError();
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Reads the onboarding session and the nodes it found.
  ///
  /// Throws [ServiceError] when the read fails — including
  /// [ResourceNotFoundError] on firmware without the object, which the
  /// `bleOnboarding` capability normally keeps the page from reaching.
  Future<OnboardingSessionUIModel> fetchSession() async {
    try {
      final onboarding = await BleOnboarding.fetch(_usp);
      return OnboardingSessionUIModel(
        status: _sessionStatus(onboarding.status),
        result: _sessionResult(onboarding.result),
        session: onboarding.session,
        devicesFound: onboarding.devicesFound,
        devicesOnboarded: onboarding.devicesOnboarded,
        devicesFailed: onboarding.devicesFailed,
        nodes: [for (final device in onboarding.devices) _node(device)],
      );
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Which of [alMacAddresses] DataElements lists as a node with its parent
  /// set, keyed the way [meshNodeMacKey] normalizes a MAC.
  ///
  /// "Joined" is two facts, and the session's own verdict is neither. A
  /// `Success` means the node associated on the backhaul AP; it is a mesh node
  /// once the controller lists it as `Network.Device.{i}` — which can lag the
  /// session's end by seconds or minutes. And a node just listed reads
  /// `LinkType` `None` with an empty parent for its first seconds, until the
  /// controller's next Topology Response (under 30 s after a BLE onboard on
  /// 2.0.3.26100921); built then, it would have no place in the tree. So a node
  /// counts once it is listed *and* has a backhaul link, by
  /// [hasMeshBackhaulLink] — the rule the topology itself places nodes by, so
  /// "joined" here and "drawn as a node" there cannot disagree.
  ///
  /// Throws [ServiceError] when the read fails.
  Future<Set<String>> fetchJoinedNodes(Iterable<String> alMacAddresses) async {
    final wanted = meshNodeMacSet(alMacAddresses);
    if (wanted.isEmpty) return const {};
    try {
      final network = await DataElementsNetwork.fetch(_usp);
      return {
        for (final node in network.items)
          if (wanted.contains(meshNodeMacKey(node.id)) &&
              hasMeshBackhaulLink(node))
            meshNodeMacKey(node.id),
      };
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Codegen → UI model
  // ---------------------------------------------------------------------------

  AddNodesNodeUIModel _node(BleOnboardingDevice device) => AddNodesNodeUIModel(
        bleMacAddress: device.bleMacAddress,
        modelNumber: _nonBlank(device.modelNumber),
        status: _nodeStatus(device.status),
        // The reflector writes 0 for a node it has no RSSI for, and 0 dBm would
        // read as the strongest signal possible.
        rssi: (device.rssi == null || device.rssi == 0) ? null : device.rssi,
        alMacAddress: nonUnsetMac(device.alMacAddress),
      );

  static String? _nonBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// The reflector maps every raw state to one of these and defaults to `Idle`,
  /// so an unknown spelling here means a firmware this mapping predates — read
  /// as idle, the state that offers nothing.
  static OnboardingSessionStatus _sessionStatus(String raw) => switch (raw) {
        'Scanning' => OnboardingSessionStatus.scanning,
        'Onboarding' => OnboardingSessionStatus.onboarding,
        'Complete' => OnboardingSessionStatus.complete,
        _ => OnboardingSessionStatus.idle,
      };

  static OnboardingSessionResult _sessionResult(String raw) => switch (raw) {
        'None' => OnboardingSessionResult.none,
        'Started' => OnboardingSessionResult.started,
        'Success' => OnboardingSessionResult.success,
        'Partial' => OnboardingSessionResult.partial,
        'Failed' => OnboardingSessionResult.failed,
        'TimedOut' => OnboardingSessionResult.timedOut,
        'NoDevicesFound' => OnboardingSessionResult.noDevicesFound,
        'TargetNotFound' => OnboardingSessionResult.targetNotFound,
        'NoTargetRequested' => OnboardingSessionResult.noTargetRequested,
        'Cancelled' => OnboardingSessionResult.cancelled,
        'Scanned' => OnboardingSessionResult.scanned,
        'Busy' => OnboardingSessionResult.busy,
        'UnsupportedRole' => OnboardingSessionResult.unsupportedRole,
        'BackendUnavailable' => OnboardingSessionResult.backendUnavailable,
        _ => OnboardingSessionResult.error,
      };

  static OnboardingNodeStatus _nodeStatus(String raw) => switch (raw) {
        'Pending' => OnboardingNodeStatus.pending,
        'NotTargeted' => OnboardingNodeStatus.notTargeted,
        'Connecting' => OnboardingNodeStatus.connecting,
        'Onboarding' => OnboardingNodeStatus.onboarding,
        'Onboarded' => OnboardingNodeStatus.onboarded,
        'FailedConnect' => OnboardingNodeStatus.failedConnect,
        'FailedRegistrar' => OnboardingNodeStatus.failedRegistrar,
        'FailedWPS' => OnboardingNodeStatus.failedWps,
        'LostConnection' => OnboardingNodeStatus.lostConnection,
        'Cancelled' => OnboardingNodeStatus.cancelled,
        _ => OnboardingNodeStatus.unknown,
      };
}
