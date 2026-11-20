import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/cloud_remote_assistance_info.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/ra_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

final raSessionProvider =
    NotifierProvider<RASessionNotifier, RASession>(() => RASessionNotifier());

class RASessionNotifier extends Notifier<RASession> {
  @override
  RASession build() {
    return const RASession(sessionId: '');
  }

  Future<String> raGenPin() async {
    final prefs = await SharedPreferences.getInstance();
    final networkId = prefs.getString(pSelectedNetworkId) ?? '';
    final cloud = ref.read(cloudRepositoryProvider);
    final sessionId = await cloud
        .raGetSession(networkId: networkId)
        .onError((error, stackTrace) => throw RANoSessionException());
    final pin = await cloud
        .raGenPin(
      sessionId: sessionId,
      networkId: networkId,
    )
        .catchError((error) {
      throw RASessionInProgressException();
    },
            test: (error) =>
                error is ErrorResponse && error.code == 'SESSION_IN_PROGRESS');
    return pin;
  }

  Future raLogout() async {
    // need to delete session
    final prefs = await SharedPreferences.getInstance();
    final networkId = prefs.getString(pSelectedNetworkId) ?? '';
    final cloud = ref.read(cloudRepositoryProvider);
    final sessionId = state.sessionId.isEmpty
        ? await cloud.raGetSession(networkId: networkId)
        : state.sessionId;
    await cloud.deleteSession(sessionId: sessionId);
    state = const RASession(sessionId: '');
  }

  Future<CloudRemoteAssistanceInfo> raGetSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final networkId = prefs.getString(pSelectedNetworkId) ?? '';
    final cloud = ref.read(cloudRepositoryProvider);
    final sessionId = state.sessionId.isEmpty
        ? await cloud.raGetSession(networkId: networkId)
        : state.sessionId;
    state = state.copyWith(sessionId: sessionId);
    return cloud.raGetSessionInfo(networkId: networkId, sessionId: sessionId);
  }

  Stream<CloudRemoteAssistanceInfo> pollSessionInfo() async* {
    late int expireIn;
    do {
      try {
        final info = await raGetSessionInfo();
        expireIn = info.expiredIn ?? 0;
        logger.i('RA Session alive left: ${info.expiredIn}');
        yield info;
        await Future.delayed(const Duration(seconds: 5));
      } catch (e) {
        expireIn = 0;
        rethrow;
      }
    } while (expireIn < 0);
  }
}

class RAException extends Error {}

class RANoSessionException extends RAException {}

class RASessionInProgressException extends RAException {}
