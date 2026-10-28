import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_node_identity.dart';
import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';

/// Where the add-nodes flow is.
enum AddNodesPhase {
  /// Reading the router's onboarding session before anything is offered.
  checking,

  /// The read on entry failed; [AddNodesState.error] says why.
  loadFailed,

  /// Nothing is running and a session can start.
  ready,

  /// A session started elsewhere is running — the pairing button, or another
  /// client. This flow cannot start one until it ends.
  busy,

  /// The router cannot run a session right now.
  unavailable,

  /// `Start()` has been sent and not yet answered.
  starting,

  /// The router is looking for nodes over BLE.
  searching,

  /// The router is handing a node the backhaul credential.
  onboarding,

  /// The session is over and named nodes that should join; waiting for the
  /// controller to list them in DataElements.
  joining,

  /// Every node of this session is a mesh node now.
  joined,

  /// Some nodes of this session joined and some did not (#1738).
  partial,

  /// The session found no unconfigured node in range.
  noNodesFound,

  /// The session ended without a node joining, or this flow could not follow
  /// it. [AddNodesState.error] is set when the cause was a failed request.
  failed,

  /// The user stopped the session.
  cancelled,
}

/// The add-nodes flow's state.
class AddNodesState extends Equatable {
  final AddNodesPhase phase;

  /// The nodes of this flow's session, as the router last reported them.
  final List<AddNodesNodeUIModel> nodes;

  /// The AL MACs of the nodes in [nodes] that DataElements lists with a backhaul
  /// link, normalized by `meshNodeMacKey`.
  final Set<String> joinedNodeKeys;

  /// The session's own outcome once it ended. Kept on [AddNodesPhase.failed]
  /// so the page can tell "the nodes did not finish in time" from "something on
  /// the router failed".
  final OnboardingSessionResult? sessionResult;

  /// Why the flow failed, when the cause was a request rather than the session.
  final ServiceError? error;

  /// BLE MACs of the nodes this flow stopped mid-onboarding at its session limit
  /// (#1738). Kept apart from [nodes] because the router keeps writing those
  /// rows after `Stop()`, and the app's verdict on these is already given.
  final Set<String> interruptedNodes;

  const AddNodesState({
    this.phase = AddNodesPhase.checking,
    this.nodes = const [],
    this.joinedNodeKeys = const {},
    this.sessionResult,
    this.error,
    this.interruptedNodes = const {},
  });

  /// Where the flow is, for telling a node's outcome from its router status.
  AddNodesStage get stage => switch (phase) {
        AddNodesPhase.starting ||
        AddNodesPhase.searching ||
        AddNodesPhase.onboarding =>
          AddNodesStage.running,
        AddNodesPhase.joining => AddNodesStage.awaiting,
        _ => AddNodesStage.settled,
      };

  /// What the page says about [node] now. See [outcomeOf].
  AddNodesNodeOutcome outcomeFor(AddNodesNodeUIModel node) => outcomeOf(
        node,
        stage: stage,
        isJoined: (alMac) => joinedNodeKeys.contains(meshNodeMacKey(alMac)),
        interrupted: interruptedNodes,
      );

  /// Whether the page is showing a session in progress: `Start()` sent and not
  /// answered, or the session searching or onboarding. What the page offers
  /// Cancel on.
  ///
  /// Not whether the running session is this flow's to stop. During
  /// [AddNodesPhase.starting] that is not known yet — `Start()` can answer
  /// `Busy` — so the notifier decides every `Stop()` by what `Start()` answered,
  /// not by this.
  bool get isRunning =>
      phase == AddNodesPhase.starting ||
      phase == AddNodesPhase.searching ||
      phase == AddNodesPhase.onboarding;

  /// Whether the user can start a session from here: on entry, or again after a
  /// session that left a node out — found none, failed, some joined and some
  /// did not (#1738), or was stopped.
  bool get canStart =>
      phase == AddNodesPhase.ready ||
      phase == AddNodesPhase.noNodesFound ||
      phase == AddNodesPhase.failed ||
      phase == AddNodesPhase.partial ||
      phase == AddNodesPhase.cancelled;

  AddNodesState copyWith({
    AddNodesPhase? phase,
    List<AddNodesNodeUIModel>? nodes,
    Set<String>? joinedNodeKeys,
    OnboardingSessionResult? sessionResult,
    bool clearSessionResult = false,
    ServiceError? error,
    bool clearError = false,
    Set<String>? interruptedNodes,
  }) =>
      AddNodesState(
        phase: phase ?? this.phase,
        nodes: nodes ?? this.nodes,
        joinedNodeKeys: joinedNodeKeys ?? this.joinedNodeKeys,
        sessionResult:
            clearSessionResult ? null : (sessionResult ?? this.sessionResult),
        error: clearError ? null : (error ?? this.error),
        interruptedNodes: interruptedNodes ?? this.interruptedNodes,
      );

  @override
  List<Object?> get props =>
      [phase, nodes, joinedNodeKeys, sessionResult, error, interruptedNodes];
}
