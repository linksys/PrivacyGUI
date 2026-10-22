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
