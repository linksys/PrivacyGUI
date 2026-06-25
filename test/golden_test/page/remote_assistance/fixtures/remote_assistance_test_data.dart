import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';

/// Initiate state - no session, waiting for CA to create one.
const initiateState = RemoteClientState(
  sessionInfo: GRASessionInfo(
    id: '',
    serialNumber: 'TEST-SN-12345',
    modelNumber: '',
    status: GRASessionStatus.initiate,
    expiredIn: 0,
    createdAt: 0,
    statusChangedAt: 0,
    currentTime: 0,
  ),
);

/// Pending state - PIN generated, waiting for CA to verify.
const pendingState = RemoteClientState(
  sessionInfo: GRASessionInfo(
    id: 'session-123',
    serialNumber: 'TEST-SN-12345',
    modelNumber: 'LN16-EU',
    status: GRASessionStatus.pending,
    expiredIn: 3600,
    createdAt: 1700000000,
    statusChangedAt: 1700000100,
    currentTime: 1700000200,
  ),
  pin: '123456',
  expiredCountdown: 3544,
);

/// Pending state without PIN - still generating.
const pendingNoPinState = RemoteClientState(
  sessionInfo: GRASessionInfo(
    id: 'session-123',
    serialNumber: 'TEST-SN-12345',
    modelNumber: 'LN16-EU',
    status: GRASessionStatus.pending,
    expiredIn: 3600,
    createdAt: 1700000000,
    statusChangedAt: 1700000100,
    currentTime: 1700000200,
  ),
  pin: null,
  expiredCountdown: 3544,
);

/// Active state - CA connected, session in progress.
const activeState = RemoteClientState(
  sessionInfo: GRASessionInfo(
    id: 'session-123',
    serialNumber: 'TEST-SN-12345',
    modelNumber: 'LN16-EU',
    status: GRASessionStatus.active,
    expiredIn: 1800,
    createdAt: 1700000000,
    statusChangedAt: 1700000100,
    currentTime: 1700000200,
  ),
  pin: '123456',
  expiredCountdown: 1744,
);

/// Invalid state - session expired or terminated.
const invalidState = RemoteClientState(
  sessionInfo: GRASessionInfo(
    id: 'session-123',
    serialNumber: 'TEST-SN-12345',
    modelNumber: 'LN16-EU',
    status: GRASessionStatus.invalid,
    expiredIn: 0,
    createdAt: 1700000000,
    statusChangedAt: 1700000100,
    currentTime: 1700000200,
  ),
);

/// Pending state with urgent countdown (< 5 min).
const pendingUrgentState = RemoteClientState(
  sessionInfo: GRASessionInfo(
    id: 'session-123',
    serialNumber: 'TEST-SN-12345',
    modelNumber: 'LN16-EU',
    status: GRASessionStatus.pending,
    expiredIn: 3600,
    createdAt: 1700000000,
    statusChangedAt: 1700000100,
    currentTime: 1700000200,
  ),
  pin: '123456',
  expiredCountdown: 180, // 3 minutes - urgent
);
