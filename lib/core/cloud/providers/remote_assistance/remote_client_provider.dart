import 'dart:async';

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
  
  @override
  RemoteClientState build() => RemoteClientState();

  Future<GRASessionInfo?> fetchSessionInfo(
    String sessionId,
  ) async {
    final master = ref.read(deviceManagerProvider).masterDevice;

    final sessionInfo = await ref
        .read(deviceCloudServiceProvider)
        .getSessionInfo(master: master, sessionId: sessionId);
    state = state.copyWith(sessionInfo: () => sessionInfo);
    _startExpiredCountdownTimer(sessionInfo);
    return sessionInfo;
  }

  Future<List<GRASessionInfo>> fetchSessions() async {
    final master = ref.read(deviceManagerProvider).masterDevice;
    final sessions =
        await ref.read(deviceCloudServiceProvider).getSessions(master: master);
    state = state.copyWith(sessions: () => sessions);
    return sessions;
  }

  Future<void> initiateRemoteAssistance() async {
    logger.i('[RemoteAssistance]: initiateRemoteAssistance');
    final sessions = await fetchSessions();
    if (sessions.isEmpty) {
      state = RemoteClientState();
      return;
    }
    logger.i('[RemoteAssistance]: sessions: ${sessions.first.id}');
    final sessionInfo = await fetchSessionInfo(sessions.first.id);
    if (sessionInfo == null) {
      state = RemoteClientState();
      return;
    }

    if (sessionInfo.status == GRASessionStatus.initiate ||
        (sessionInfo.status == GRASessionStatus.pending && state.pin == null)) {
      logger.i(
          '[RemoteAssistance]: createPin - ${sessionInfo.id}, ${sessionInfo.status}');
      await createPin(sessionInfo.id);
    }
    // start a stream to fetch session info
    _startSessionInfoStream(sessionInfo.id);
  }

  Future<void> initiateRemoteAssistanceCA() async {
    // if the stream is already started, do nothing
    if (_sessionInfoStreamSubscription != null) {
      return;
    }
    logger.i('[RemoteAssistance]: initiateRemoteAssistanceCA');
    final sessions = await fetchSessions();
    if (sessions.isEmpty) {
      state = RemoteClientState();
      return;
    }
    logger.i('[RemoteAssistance]: sessions: ${sessions.first.id}');
    final sessionInfo = await fetchSessionInfo(sessions.first.id);
    if (sessionInfo == null) {
      state = RemoteClientState();
      return;
    }
    // start a stream to fetch session info
    _startSessionInfoStream(sessionInfo.id, interval: 60);
  }

  Future<void> endRemoteAssistance() async {
    _sessionInfoStreamSubscription?.cancel();
    _sessionInfoStreamSubscription = null;
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
      {int interval = 3}) async {
    _sessionInfoStreamSubscription?.cancel();
    _sessionInfoStreamSubscription =
        _fetchSessionInfoStream(sessionId, interval: interval)
            .listen((sessionInfo) {
      state = state.copyWith(sessionInfo: () => sessionInfo);
    });
  }

  // create a stream to fetch session info every 3 seconds
  Stream<GRASessionInfo?> _fetchSessionInfoStream(String sessionId,
      {int interval = 3}) async* {
    while (state.sessionInfo?.expiredIn != null &&
        state.sessionInfo!.expiredIn < 0) {
      final sessionInfo = await fetchSessionInfo(sessionId);
      yield sessionInfo;
      await Future.delayed(Duration(seconds: interval));
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
    _expiredCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      var expiredCountdown = state.expiredCountdown;
      expiredCountdown ??= sessionInfo.expiredIn * -1;
      expiredCountdown--;
      state = state.copyWith(expiredCountdown: () => expiredCountdown);
      if (expiredCountdown < 0) {
        timer.cancel();
        _expiredCountdownTimer = null;
      }
    });
  }
}
