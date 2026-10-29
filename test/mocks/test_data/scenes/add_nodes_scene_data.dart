/// Composed scenes for `add_nodes_view` (#879): whole [AddNodesState]s, ready to
/// hand to `addNodesOverrides`.
///
/// The names say which phase each one is, so a test reads as the state it pumps.
/// MAC addresses are made up.
library;

import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_state.dart';

/// Onboarded, and in DataElements once [_onboardedKey] is joined.
const _onboardedNode = AddNodesNodeUIModel(
  bleMacAddress: 'AA:BB:CC:00:00:01',
  status: OnboardingNodeStatus.onboarded,
  modelNumber: 'M60',
  rssi: -40,
  alMacAddress: 'aa:bb:cc:00:00:02',
);

/// [_onboardedNode]'s AL MAC as `meshNodeMacKey` writes it.
const _onboardedKey = 'AABBCC000002';

/// A node the session gave up on that is not in DataElements yet.
const _lateNode = AddNodesNodeUIModel(
  bleMacAddress: 'AA:BB:CC:00:00:03',
  status: OnboardingNodeStatus.failedWps,
  modelNumber: 'M60',
  rssi: -68,
  alMacAddress: 'aa:bb:cc:00:00:04',
);

/// The controller could not reach this one over BLE.
const _unreachedNode = AddNodesNodeUIModel(
  bleMacAddress: 'AA:BB:CC:00:00:05',
  status: OnboardingNodeStatus.failedConnect,
  rssi: -82,
);

/// The session ended before reaching this one.
const _queuedNode = AddNodesNodeUIModel(
  bleMacAddress: 'AA:BB:CC:00:00:07',
  status: OnboardingNodeStatus.pending,
  rssi: -75,
);

/// Being onboarded right now.
const _onboardingNode = AddNodesNodeUIModel(
  bleMacAddress: 'AA:BB:CC:00:00:09',
  status: OnboardingNodeStatus.onboarding,
  modelNumber: 'M60',
  rssi: -51,
  alMacAddress: 'aa:bb:cc:00:00:0a',
);

/// Before a session: the guidance and Start.
const addNodesReadyState = AddNodesState(phase: AddNodesPhase.ready);

/// The router is looking for nodes and has found none yet.
const addNodesSearchingState = AddNodesState(phase: AddNodesPhase.searching);

/// The router is onboarding one node with another queued behind it: the node
/// list a session in progress shows, under the spinner and above Cancel.
const addNodesOnboardingState = AddNodesState(
  phase: AddNodesPhase.onboarding,
  nodes: [_onboardingNode, _queuedNode],
);

/// The session is over, one node is in and one is still awaited.
const addNodesJoiningState = AddNodesState(
  phase: AddNodesPhase.joining,
  nodes: [_onboardedNode, _lateNode],
  joinedNodeKeys: {_onboardedKey},
  sessionResult: OnboardingSessionResult.partial,
);

/// Someone else's session is running.
const addNodesBusyState = AddNodesState(phase: AddNodesPhase.busy);

/// The session found nothing in range.
const addNodesNoNodesFoundState = AddNodesState(
  phase: AddNodesPhase.noNodesFound,
  sessionResult: OnboardingSessionResult.noDevicesFound,
);

/// Every node joined.
const addNodesJoinedState = AddNodesState(
  phase: AddNodesPhase.joined,
  nodes: [_onboardedNode],
  joinedNodeKeys: {_onboardedKey},
  sessionResult: OnboardingSessionResult.success,
);

/// One node joined and three did not, one of each other outcome: the widest
/// state the page has — a node list with a row of every outcome but joining,
/// the failure's three-step checklist, and two buttons.
const addNodesPartialState = AddNodesState(
  phase: AddNodesPhase.partial,
  nodes: [_onboardedNode, _lateNode, _unreachedNode, _queuedNode],
  joinedNodeKeys: {_onboardedKey},
  sessionResult: OnboardingSessionResult.partial,
);

/// No node joined, though the session onboarded one.
const addNodesFailedWaitingState = AddNodesState(
  phase: AddNodesPhase.failed,
  nodes: [_lateNode],
  sessionResult: OnboardingSessionResult.timedOut,
);
