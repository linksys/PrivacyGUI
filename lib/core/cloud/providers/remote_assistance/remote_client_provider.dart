import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/linksys_device_cloud_service.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';

final remoteClientProvider =
    NotifierProvider<RemoteClientNotifier, RemoteClientState>(
  () => RemoteClientNotifier(),
);

class RemoteClientNotifier extends Notifier<RemoteClientState> {
  StreamSubscription<GRASessionInfo?>? _sessionInfoStreamSubscription;
  Timer? _expiredCountdownTimer;
  Timer? _activePollTimer;
  bool _activePolling = false;
  bool _initiatingCA = false;

  static const int kActivePollIntervalSec = 5;
  static const int kActiveSessionPollIntervalSec = 60;

  // Cadence for the passive (client-side) session info stream. Was an
  // unexplained default of 3 on the private method; named here so the two
  // stream cadences sit next to each other.
  static const int kPassiveSessionPollIntervalSec = 3;

  @override
  RemoteClientState build() => RemoteClientState();

  @visibleForTesting
  bool get isActivePolling => _activePolling;

  @visibleForTesting
  int nextPollInterval(GRASessionStatus? status) =>
      status == GRASessionStatus.active
          ? kActiveSessionPollIntervalSec
          : kActivePollIntervalSec;

  @visibleForTesting
  Future<GRASessionInfo?> pollSessionOnce() async {
    final sessions = await fetchSessions();
    if (sessions.isEmpty) {
      state = state.copyWith(sessionInfo: () => null, pin: () => null);
      return null;
    }
    final sessionInfo = await fetchSessionInfo(sessions.first.id);
    if (sessionInfo == null) {
      return null;
    }
    // Request a PIN as soon as a session exists and has none yet. The server
    // advances the session from INITIATE to PENDING once the PIN is created,
    // so requesting only on PENDING would stall a session stuck at INITIATE.
    final needsPin = sessionInfo.status == GRASessionStatus.initiate ||
        sessionInfo.status == GRASessionStatus.pending;
    if (needsPin && state.pin == null) {
      logger.i(
          '[RemoteAssistance]: createPin - ${sessionInfo.id}, ${sessionInfo.status}');
      await createPin(sessionInfo.id);
    }
    return sessionInfo;
  }

  Future<GRASessionInfo?> fetchSessionInfo(
    String sessionId, {
    bool startCountdown = false,
  }) async {
    final master = ref.read(deviceManagerProvider).masterDevice;

    final sessionInfo = await ref
        .read(deviceCloudServiceProvider)
        .getSessionInfo(master: master, sessionId: sessionId);
    state = state.copyWith(sessionInfo: () => sessionInfo);
    if (startCountdown) {
      _startExpiredCountdownTimer(sessionInfo);
    }
    return sessionInfo;
  }

  Future<List<GRASessionInfo>> fetchSessions() async {
    final master = ref.read(deviceManagerProvider).masterDevice;
    final sessions =
        await ref.read(deviceCloudServiceProvider).getSessions(master: master);
    state = state.copyWith(sessions: () => sessions);
    return sessions;
  }

  Future<GRASessionStatus?> checkActiveSession() async {
    logger.i('[RemoteAssistance]: checkActiveSession');
    try {
      final sessions = await fetchSessions();
      if (sessions.isEmpty) {
        state = state.copyWith(sessionInfo: () => null);
        return null;
      }
      final master = ref.read(deviceManagerProvider).masterDevice;
      final sessionInfo = await ref
          .read(deviceCloudServiceProvider)
          .getSessionInfo(master: master, sessionId: sessions.first.id);
      state = state.copyWith(sessionInfo: () => sessionInfo);
      return sessionInfo.status;
    } catch (e) {
      logger.e('[RemoteAssistance]: checkActiveSession error: $e');
      return null;
    }
  }

  void startSessionInfoStream({int interval = kPassiveSessionPollIntervalSec}) {
    final sessionId = state.sessionInfo?.id;
    if (sessionId != null) {
      _startSessionInfoStream(sessionId, interval: interval);
    }
  }

  Future<void> initiateRemoteAssistance() async {
    logger.i('[RemoteAssistance]: initiateRemoteAssistance');
    // Run one poll immediately so the dialog can leave the loading state,
    // then keep polling until the dialog is closed.
    try {
      await pollSessionOnce();
    } catch (e) {
      logger.e('[RemoteAssistance]: initial poll failed: $e');
    }
    _startActivePolling();
  }

  Future<void> initiateRemoteAssistanceCA() async {
    // The subscription check alone cannot guard this: it is only assigned two
    // awaits later, so concurrent callers all get past it. TopBar.build() calls
    // this on every rebuild, and the CG#209 log shows five calls slipping
    // through within 1.2 s that way. [_initiatingCA] is set before the first
    // await, so it closes that window.
    if (_initiatingCA || _sessionInfoStreamSubscription != null) {
      return;
    }
    _initiatingCA = true;
    try {
      logger.i('[RemoteAssistance]: initiateRemoteAssistanceCA');
      final sessions = await fetchSessions();
      if (sessions.isEmpty) {
        state = RemoteClientState();
        return;
      }
      logger.i('[RemoteAssistance]: sessions: ${sessions.first.id}');
      final sessionInfo =
          await fetchSessionInfo(sessions.first.id, startCountdown: true);
      if (sessionInfo == null) {
        state = RemoteClientState();
        return;
      }
      // start a stream to fetch session info
      _startSessionInfoStream(sessionInfo.id,
          interval: kActiveSessionPollIntervalSec);
    } finally {
      _initiatingCA = false;
    }
  }

  /// Marks whether a remote assistance dialog is currently shown so the
  /// dashboard does not auto-open a second (passive) dialog over an existing
  /// one.
  void setDialogShown(bool shown) {
    state = state.copyWith(isDialogShown: () => shown);
  }

  Future<void> endRemoteAssistance() async {
    _stopActivePolling();
    _sessionInfoStreamSubscription?.cancel();
    _sessionInfoStreamSubscription = null;
    // The dialog is closing in every path below; clear the flag up front so
    // the early returns do not leave it stuck true.
    state = state.copyWith(isDialogShown: () => false);
    final sessionId = state.sessionInfo?.id;
    if (sessionId == null) {
      return;
    }
    // end the session if it is active
    if (state.sessionInfo?.status != GRASessionStatus.active) {
      return;
    }

    final serialNumber = state.sessionInfo?.serialNumber;
    final master = ref.read(deviceManagerProvider).masterDevice;
    await ref.read(deviceCloudServiceProvider).deleteSession(
        master: master,
        sessionId: sessionId,
        serialNumber: serialNumber ?? master.unit.serialNumber);
    state = RemoteClientState();
  }

  // start a stream to fetch session info
  Future<void> _startSessionInfoStream(String sessionId,
      {int interval = kPassiveSessionPollIntervalSec}) async {
    _sessionInfoStreamSubscription?.cancel();
    _sessionInfoStreamSubscription =
        _fetchSessionInfoStream(sessionId, interval: interval).listen(
      (sessionInfo) {
        state = state.copyWith(sessionInfo: () => sessionInfo);
      },
      // Without this, a `getSessionInfo` that fails - a 404 once the session is
      // deleted, most obviously - escapes as an unhandled async error and the
      // subscription dies with no trace in the log.
      onError: (Object e) {
        logger.e('[RemoteAssistance]: session info stream error: $e');
        _sessionInfoStreamSubscription = null;
      },
      // A finished stream has to release the field, or the guard in
      // [initiateRemoteAssistanceCA] treats a dead subscription as a live one
      // and refuses every later session for the rest of the app's life.
      onDone: () {
        _sessionInfoStreamSubscription = null;
      },
    );
  }

  // Polls while the session is still alive. Two things this deliberately does
  // not do:
  //
  // It does not key on the sign of `expiredIn`. That field is seconds
  // *remaining* against the session's TTL, so it is positive for the whole life
  // of a session - the previous `< 0` condition was never true and the body
  // never ran (#1558).
  //
  // It does not read `state` back to decide whether to continue. The listener
  // in [_startSessionInfoStream] writes `state` in a later microtask, not
  // synchronously on `yield`, so reading it here would test the previous
  // iteration's value. The loop carries the value it fetched instead.
  //
  // The delay comes before the fetch on purpose: every caller has just read the
  // session to seed `state`, so fetching immediately would only repeat it.
  Stream<GRASessionInfo?> _fetchSessionInfoStream(String sessionId,
      {int interval = kPassiveSessionPollIntervalSec}) async* {
    var sessionInfo = state.sessionInfo;
    while (sessionInfo != null &&
        sessionInfo.status != GRASessionStatus.invalid &&
        sessionInfo.expiredIn > 0) {
      await Future.delayed(Duration(seconds: interval));
      final master = ref.read(deviceManagerProvider).masterDevice;
      sessionInfo = await ref
          .read(deviceCloudServiceProvider)
          .getSessionInfo(master: master, sessionId: sessionId);
      yield sessionInfo;
    }
  }

  Future<String?> createPin(String sessionId) async {
    final master = ref.read(deviceManagerProvider).masterDevice;
    final pin = await ref
        .read(deviceCloudServiceProvider)
        .createPin(master: master, sessionId: sessionId);
    state = state.copyWith(pin: () => pin);
    return pin;
  }

  void _startExpiredCountdownTimer(GRASessionInfo sessionInfo) {
    _expiredCountdownTimer?.cancel();
    _expiredCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      var expiredCountdown = state.expiredCountdown;
      // `expiredIn` is seconds remaining, so it is already the countdown's
      // starting value. The `.abs()` this replaces came from the inverted sign
      // assumption in #1558 and would have turned an expired session's negative
      // remainder into time still to run.
      expiredCountdown ??=
          sessionInfo.expiredIn > 0 ? sessionInfo.expiredIn : 0;
      expiredCountdown--;
      state = state.copyWith(expiredCountdown: () => expiredCountdown);
      if (expiredCountdown < 0) {
        timer.cancel();
        _expiredCountdownTimer = null;
      }
    });
  }

  void _startActivePolling() {
    _stopActivePolling();
    _activePolling = true;
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    if (!_activePolling) {
      return;
    }
    final interval = nextPollInterval(state.sessionInfo?.status);
    _activePollTimer = Timer(Duration(seconds: interval), () async {
      if (!_activePolling) {
        return;
      }
      try {
        await pollSessionOnce();
      } catch (e) {
        logger.e('[RemoteAssistance]: poll failed: $e');
      }
      _scheduleNextPoll();
    });
  }

  void _stopActivePolling() {
    _activePolling = false;
    _activePollTimer?.cancel();
    _activePollTimer = null;
  }
}
