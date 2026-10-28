import 'package:equatable/equatable.dart';

/// What the router answered to a `Start()` request.
///
/// The verdict on the *request*, read from the Operate response's `Result`
/// output — not the outcome of the session it may have started, which is
/// [OnboardingSessionResult]. A request the firmware refused is an answer, so it
/// is a value here rather than a `ServiceError`: the page shows each one
/// differently, and none of them means the router could not be reached.
enum OnboardingStartResult {
  /// A session began. Its progress is read from the onboarding status.
  started,

  /// Another session is running — the pairing button, or a second client. The
  /// request was not queued.
  busy,

  /// This router cannot start one: it is an agent that has already joined a
  /// mesh, or its management mode has no registrar.
  unsupportedRole,

  /// The onboarding daemon is not running here, for example because Bluetooth
  /// is not ready.
  backendUnavailable,
}

/// Where the router's onboarding session is (`Device.X_LINKSYS_BLEOnboarding.Status`).
enum OnboardingSessionStatus {
  /// No session is running. Also what the router reads when it cannot run one;
  /// [OnboardingSessionResult] tells the two apart.
  idle,

  /// Looking for nodes over BLE.
  scanning,

  /// Connected to a node and handing it the backhaul credential.
  onboarding,

  /// The session ended. Its outcome is [OnboardingSessionResult].
  complete,
}

/// The outcome of the last session (`Device.X_LINKSYS_BLEOnboarding.Result`).
///
/// Meaningful as a session outcome only once the status is
/// [OnboardingSessionStatus.complete]: while a session runs it reads
/// [started], and a refused request elsewhere can write [busy] over it.
enum OnboardingSessionResult {
  /// Nothing has run since the router booted.
  none,

  /// A session was accepted and has not finished.
  started,

  /// Every node the session tried joined the backhaul.
  success,

  /// Some joined and some did not. The ones that joined are working and must
  /// not be onboarded again.
  partial,

  /// None joined, and at least one failed for a reason on the controller's side
  /// or on the link (BLE connect, or the controller's own WPS registrar).
  failed,

  /// None joined, and every failure was a node that did not finish WPS in time.
  timedOut,

  /// No unconfigured node was found in range.
  noDevicesFound,

  /// None of the requested nodes was in range.
  targetNotFound,

  /// The request named no node, so the session did nothing.
  noTargetRequested,

  /// The session was stopped.
  cancelled,

  /// A scan-only session finished.
  scanned,

  /// A second request was refused while a session ran.
  busy,

  /// This router cannot run a session.
  unsupportedRole,

  /// The onboarding daemon is not running here.
  backendUnavailable,

  /// The firmware reported a value outside its documented set.
  error,
}

/// Where one node in the session is (`Device.X_LINKSYS_BLEOnboarding.Device.{i}.Status`).
enum OnboardingNodeStatus {
  pending,
  notTargeted,
  connecting,
  onboarding,
  onboarded,
  failedConnect,
  failedRegistrar,
  failedWps,
  lostConnection,
  cancelled,
  unknown,
}

/// One node the router found during an onboarding session.
class AddNodesNodeUIModel extends Equatable {
  /// The node's BLE address, the row's key.
  final String bleMacAddress;

  /// The model the node reported, or null before the controller has connected to
  /// it over BLE.
  final String? modelNumber;

  final OnboardingNodeStatus status;

  /// BLE signal in dBm, or null when the router has none for it.
  final int? rssi;

  /// The node's IEEE 1905 AL MAC, equal to its future DataElements
  /// `Device.{i}.ID`, or null before the controller has connected to it.
  final String? alMacAddress;

  const AddNodesNodeUIModel({
    required this.bleMacAddress,
    required this.status,
    this.modelNumber,
    this.rssi,
    this.alMacAddress,
  });

  /// Whether this node reached the backhaul in this session.
  bool get isOnboarded => status == OnboardingNodeStatus.onboarded;

  /// Whether the session gave up waiting for this node while the node may still
  /// join: it was told to onboard and either did not finish WPS in time or lost
  /// its BLE link. The firmware corrects such a node to onboarded when it joins
  /// late, and the node can appear in DataElements before that correction does.
  bool get mayStillJoin =>
      status == OnboardingNodeStatus.failedWps ||
      status == OnboardingNodeStatus.lostConnection;

  @override
  List<Object?> get props =>
      [bleMacAddress, modelNumber, status, rssi, alMacAddress];
}

/// Where the flow is, for telling a node's status from its outcome (#1738).
enum AddNodesStage {
  /// The session is running on the router: a node may still move on its own.
  running,

  /// The session has ended and the flow is waiting for its nodes to show in
  /// DataElements.
  awaiting,

  /// Nothing more is waited for: the outcome is final.
  settled,
}

/// What the page says about one node (#1738).
///
/// Four, because the customer's next step differs for each: wait, nothing, try
/// again after the troubleshooting, or simply try again. "Not online yet" used
/// to cover the first three.
enum AddNodesNodeOutcome {
  /// A mesh node: in DataElements with a backhaul link.
  added,

  /// Still being worked on, by the router or by the wait for DataElements.
  joining,

  /// Tried and did not join.
  failed,

  /// The session ended before reaching it.
  notTried,
}

/// The outcome the page shows for [node] at [stage] (#1738).
///
/// [joinedKeys] are the AL MACs DataElements has listed with a backhaul link,
/// normalized by `meshNodeMacKey`; [isJoined] answers for one node, so this
/// stays free of the key format. [interrupted] are BLE MACs of nodes the flow
/// stopped mid-onboarding at its session limit: the app sent `Stop()` for
/// them, so they are failed whatever the router reads next.
///
/// The one place every status maps to an outcome, so the node list, the choice
/// of result screen and their tests all read the same rule.
AddNodesNodeOutcome outcomeOf(
  AddNodesNodeUIModel node, {
  required AddNodesStage stage,
  required bool Function(String alMac) isJoined,
  Set<String> interrupted = const {},
}) {
  final alMac = node.alMacAddress;
  if (alMac != null && isJoined(alMac)) return AddNodesNodeOutcome.added;
  if (interrupted.contains(node.bleMacAddress)) {
    return AddNodesNodeOutcome.failed;
  }

  switch (node.status) {
    case OnboardingNodeStatus.pending:
    case OnboardingNodeStatus.cancelled:
      // Never reached. While running, it is queued, which is the same answer.
      return AddNodesNodeOutcome.notTried;
    case OnboardingNodeStatus.notTargeted:
      // Outside a MAC list; the flow sends none, so it should never be seen.
      return AddNodesNodeOutcome.notTried;
    case OnboardingNodeStatus.connecting:
    case OnboardingNodeStatus.onboarding:
      return stage == AddNodesStage.running
          ? AddNodesNodeOutcome.joining
          : AddNodesNodeOutcome.failed;
    case OnboardingNodeStatus.onboarded:
      // An onboarded node with no AL MAC cannot be looked up, so the session's
      // word is all there is: taken, as before #1738.
      if (alMac == null) return AddNodesNodeOutcome.added;
      return stage == AddNodesStage.settled
          ? AddNodesNodeOutcome.failed
          : AddNodesNodeOutcome.joining;
    case OnboardingNodeStatus.failedWps:
    case OnboardingNodeStatus.lostConnection:
      // The firmware corrects these upward when the node joins late, so they
      // are joining until the wait is over — and after the session only one
      // with an AL MAC can be looked for at all.
      return switch (stage) {
        AddNodesStage.running => AddNodesNodeOutcome.joining,
        AddNodesStage.awaiting => alMac == null
            ? AddNodesNodeOutcome.failed
            : AddNodesNodeOutcome.joining,
        AddNodesStage.settled => AddNodesNodeOutcome.failed,
      };
    case OnboardingNodeStatus.failedConnect:
    case OnboardingNodeStatus.failedRegistrar:
    case OnboardingNodeStatus.unknown:
      return AddNodesNodeOutcome.failed;
  }
}

/// The router's onboarding session, as one read of
/// `Device.X_LINKSYS_BLEOnboarding.`.
class OnboardingSessionUIModel extends Equatable {
  final OnboardingSessionStatus status;
  final OnboardingSessionResult result;

  /// Changes whenever the router accepts a new session, so a reader can tell its
  /// own session from an earlier or a later one. 0 before the first session
  /// since boot.
  final int session;

  final int devicesFound;
  final int devicesOnboarded;
  final int devicesFailed;

  /// The nodes the session's scan found, in the router's order.
  final List<AddNodesNodeUIModel> nodes;

  const OnboardingSessionUIModel({
    required this.status,
    required this.result,
    required this.session,
    this.devicesFound = 0,
    this.devicesOnboarded = 0,
    this.devicesFailed = 0,
    this.nodes = const [],
  });

  /// Whether a session is running right now, started by anyone.
  bool get isRunning =>
      status == OnboardingSessionStatus.scanning ||
      status == OnboardingSessionStatus.onboarding;

  /// Whether this router cannot run a session at all right now. The status
  /// reads idle then too, so the result is what says so.
  bool get isUnavailable =>
      !isRunning &&
      (result == OnboardingSessionResult.backendUnavailable ||
          result == OnboardingSessionResult.unsupportedRole);

  @override
  List<Object?> get props => [
        status,
        result,
        session,
        devicesFound,
        devicesOnboarded,
        devicesFailed,
        nodes,
      ];
}
