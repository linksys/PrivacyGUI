/// Composed scenes for `add_nodes_view` (#879): whole [AddNodesState]s, ready to
/// hand to `addNodesOverrides`.
///
/// The names say which phase each one is, so a test reads as the state it pumps.
/// MAC addresses are made up.
library;

import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_state.dart';

const _onboardedNode = AddNodesNodeUIModel(
  bleMacAddress: 'AA:BB:CC:00:00:01',
  status: OnboardingNodeStatus.onboarded,
  modelNumber: 'M60',
  rssi: -40,
  alMacAddress: 'aa:bb:cc:00:00:02',
);

/// A node the session gave up on that is not in DataElements yet.
const _lateNode = AddNodesNodeUIModel(
  bleMacAddress: 'AA:BB:CC:00:00:03',
  status: OnboardingNodeStatus.failedWps,
  modelNumber: 'M60',
  rssi: -68,
  alMacAddress: 'aa:bb:cc:00:00:04',
);

/// Before a session: the guidance and Start.
const addNodesReadyState = AddNodesState(phase: AddNodesPhase.ready);

/// The router is looking for nodes.
const addNodesSearchingState = AddNodesState(phase: AddNodesPhase.searching);

/// Someone else's session is running.
const addNodesBusyState = AddNodesState(phase: AddNodesPhase.busy);

/// The session found nothing in range.
const addNodesNoNodesFoundState = AddNodesState(
  phase: AddNodesPhase.noNodesFound,
  sessionResult: OnboardingSessionResult.noDevicesFound,
);

/// One node joined, one is still on its way: the widest state the page has —
/// the node list with both kinds of row, and the move-them-into-place note.
const addNodesJoinedState = AddNodesState(
  phase: AddNodesPhase.joined,
  nodes: [_onboardedNode, _lateNode],
  joinedNodeKeys: {'AABBCC000002'},
  sessionResult: OnboardingSessionResult.partial,
);

/// No node appeared within the wait, though the session onboarded one.
const addNodesFailedWaitingState = AddNodesState(
  phase: AddNodesPhase.failed,
  nodes: [_lateNode],
  sessionResult: OnboardingSessionResult.timedOut,
);
