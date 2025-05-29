import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/linksys_device_cloud_service.dart';
import 'package:privacy_gui/core/cloud/model/guidan_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';

final remoteClientProvider =
    NotifierProvider<RemoteClientNotifier, RemoteClientState>(
  () => RemoteClientNotifier(),
);

class RemoteClientNotifier extends Notifier<RemoteClientState> {
  StreamSubscription<GRASessionInfo?>? _sessionInfoStreamSubscription;
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
    return sessionInfo;
  }

  Future<List<GRASessionInfo>> fetchSessions() async {
    final master = ref.read(deviceManagerProvider).masterDevice;
    final sessions =
        await ref.read(deviceCloudServiceProvider).getSessions(master: master);
    state = state.copyWith(sessions: () => sessions);
    return sessions;
  }

  Future<String?> initiateRemoteAssistance() async {
    final sessions = await fetchSessions();
    if (sessions.isEmpty) {
      return null;
    }
    final sessionInfo = await fetchSessionInfo(sessions.first.id);
    if (sessionInfo == null) {
      return null;
    }
    final pin = await createPin(sessionInfo.id);
    if (pin == null) {
      return null;
    }
    // start a stream to fetch session info
    _sessionInfoStreamSubscription?.cancel();
    _sessionInfoStreamSubscription =
        _fetchSessionInfoStream(sessionInfo.id).listen((sessionInfo) {
      state = state.copyWith(sessionInfo: () => sessionInfo);
    });
    return pin;
  }

  Future<void> endRemoteAssistance() async {
    _sessionInfoStreamSubscription?.cancel();
    _sessionInfoStreamSubscription = null;
    state = RemoteClientState();
  }

  // create a stream to fetch session info every 3 seconds
  Stream<GRASessionInfo?> _fetchSessionInfoStream(String sessionId) async* {
    while (state.sessionInfo?.expiredIn != null &&
        state.sessionInfo!.expiredIn < 0) {
      final sessionInfo = await fetchSessionInfo(sessionId);
      yield sessionInfo;
      await Future.delayed(const Duration(seconds: 3));
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
}
