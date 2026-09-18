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

  // How many session reads may fail in a row before the session is reported as
  // gone rather than polled again.
  static const int kMaxConsecutivePollFailures = 3;

  @override
  RemoteClientState build() {
    // Two timers and a stream subscription, all holding `ref`. Without this they
    // outlive the provider on invalidate or container teardown.
    ref.onDispose(() {
      _stopActivePolling();
      _expiredCountdownTimer?.cancel();
      _expiredCountdownTimer = null;
      _sessionInfoStreamSubscription?.cancel();
      _sessionInfoStreamSubscription = null;
    });
    return RemoteClientState();
  }

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
      state = state.copyWith(
          sessionInfo: () => null, pin: () => null, pinSessionId: () => null);
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
    // The PIN has to belong to *this* session. Asking only whether any PIN
    // existed meant one left over from a finished session suppressed createPin
    // for every session that followed - the DUT then sat at INITIATE showing no
    // PIN, and once the session reached PENDING it displayed the stale PIN,
    // which no Guardian can use (#1560).
    final hasPinForThisSession =
        state.pin != null && state.pinSessionId == sessionInfo.id;
    if (needsPin && !hasPinForThisSession) {
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
        // Same rule as pollSessionOnce: no session means no PIN either, or the
        // next session inherits a credential that was never issued for it.
        state = state.copyWith(
            sessionInfo: () => null, pin: () => null, pinSessionId: () => null);
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
    if (sessionId == null) {
      // Silently doing nothing here is how a caller that streams before reading
      // the session looks identical to one whose session simply ended.
      logger.w(
          '[RemoteAssistance]: startSessionInfoStream with no session to stream');
      return;
    }
    _startSessionInfoStream(sessionId, interval: interval);
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
    // Pre-existing leak, fixed here because this is the session teardown and the
    // countdown is part of the session: nothing used to cancel this 1 Hz timer.
    // On the ACTIVE path below, `state = RemoteClientState()` nulls
    // `expiredCountdown`, so the next tick's `??=` re-seeded from the captured
    // sessionInfo and started a fresh countdown for a session that no longer
    // exists - rebuilding the top bar every second, indefinitely.
    _stopExpiredCountdownTimer();
    // The dialog is closing in every path below; clear the flag up front so
    // the early returns do not leave it stuck true.
    state = state.copyWith(isDialogShown: () => false);
    // The PIN dies with the dialog on every path, not only the ACTIVE one that
    // resets state below - otherwise it stays resident and `pinForCurrentSession`
    // is the only thing standing between it and the next session.
    state = state.copyWith(pin: () => null, pinSessionId: () => null);
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

  // Synchronous on purpose. There is nothing to await here, and the re-entrancy
  // guard in [initiateRemoteAssistanceCA] holds only while no await runs before
  // the subscription is assigned - `void` makes that structural instead of an
  // invariant a later edit could break.
  void _startSessionInfoStream(String sessionId,
      {int interval = kPassiveSessionPollIntervalSec}) {
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
        // `state.sessionInfo` is deliberately left alone: a single failed read
        // may be a blip, and clearing it would tear down a live session. The
        // countdown, though, has nothing left feeding it.
        _stopExpiredCountdownTimer();
      },
      // A finished stream has to release the field, or the guard in
      // [initiateRemoteAssistanceCA] treats a dead subscription as a live one
      // and refuses every later session for the rest of the app's life.
      onDone: () {
        _sessionInfoStreamSubscription = null;
        _stopExpiredCountdownTimer();
      },
    );
  }

  // Polls for as long as the cloud still considers the session usable.
  //
  // The loop carries the value it fetched rather than reading `state` back: the
  // listener in [_startSessionInfoStream] writes `state` in a later microtask,
  // not synchronously on `yield`, so `state` here is one iteration behind.
  //
  // The delay comes before the fetch because every caller has just read the
  // session to seed `state`; fetching immediately would only repeat it.
  //
  // A failed read does not end the polling. That is the whole point of #1558:
  // ending on the first blip would leave the session unpolled and the UI still
  // claiming it is live, which is the symptom this fix exists to remove. After
  // [kMaxConsecutivePollFailures] in a row the session is treated as gone and
  // the stream ends, so listeners are not left waiting on a session nobody can
  // reach.
  Stream<GRASessionInfo?> _fetchSessionInfoStream(String sessionId,
      {int interval = kPassiveSessionPollIntervalSec}) async* {
    var sessionInfo = state.sessionInfo;
    var consecutiveFailures = 0;
    while (sessionInfo != null && sessionInfo.isLive) {
      await Future.delayed(Duration(seconds: interval));
      final master = ref.read(deviceManagerProvider).masterDevice;
      try {
        sessionInfo = await ref
            .read(deviceCloudServiceProvider)
            .getSessionInfo(master: master, sessionId: sessionId);
        consecutiveFailures = 0;
        yield sessionInfo;
      } catch (e) {
        consecutiveFailures++;
        logger.w(
            '[RemoteAssistance]: session read failed ($consecutiveFailures/$kMaxConsecutivePollFailures): $e');
        if (consecutiveFailures >= kMaxConsecutivePollFailures) {
          logger.e(
              '[RemoteAssistance]: giving up on session $sessionId; reporting it as gone');
          state = state.copyWith(sessionInfo: () => null);
          return;
        }
      }
    }
  }

  Future<String?> createPin(String sessionId) async {
    final master = ref.read(deviceManagerProvider).masterDevice;
    final pin = await ref
        .read(deviceCloudServiceProvider)
        .createPin(master: master, sessionId: sessionId);
    // Recorded together: a PIN with no session id attached is what let a stale
    // one stand in for a new session's (#1560).
    state = state.copyWith(pin: () => pin, pinSessionId: () => sessionId);
    return pin;
  }

  void _stopExpiredCountdownTimer() {
    _expiredCountdownTimer?.cancel();
    _expiredCountdownTimer = null;
    // The field goes with the timer. Left behind it is a number that has stopped
    // meaning anything but keeps being rendered.
    state = state.copyWith(expiredCountdown: () => null);
  }

  void _startExpiredCountdownTimer(GRASessionInfo sessionInfo) {
    _expiredCountdownTimer?.cancel();
    // Counted from a local rather than read back out of state each tick. Reading
    // state meant any other writer that reset it - and several do - handed the
    // timer a null, which it then re-seeded from this same captured session,
    // restarting a countdown for a session that had already ended.
    var remaining = sessionInfo.remainingSeconds;
    state = state.copyWith(expiredCountdown: () => remaining);
    _expiredCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      state = state.copyWith(expiredCountdown: () => remaining);
      if (remaining < 0) {
        _stopExpiredCountdownTimer();
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
