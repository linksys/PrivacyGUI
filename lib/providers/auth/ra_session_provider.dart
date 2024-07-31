import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/cloud_remote_assistance_info.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/ra_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

final raSessionProvider =
    NotifierProvider<RASessionNotifier, RASession>(() => RASessionNotifier());

class RASessionNotifier extends Notifier<RASession> {
  StreamSubscription? _sessionIdSubscription;

  @override
  RASession build() {
    return const RASession(sessionId: '', token: '');
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

  Future raLogin({
    required String username,
    required String password,
    required String serialNumber,
  }) async {
    final cloud = ref.read(cloudRepositoryProvider);
    final raData = await cloud.raLogin(
      username: username,
      password: password,
      serialNumber: serialNumber,
    );
    logger.d('Ra cloud login: $raData');
    final (email, mobile) =
        await cloud.raGetInfo(sessionId: raData.$1, token: raData.$2);
    state = state.copyWith(
      sessionId: raData.$1,
      token: raData.$2,
      email: email,
      mobile: mobile,
      serialNumber: serialNumber,
    );
  }

  Future raSendPin({required String method}) {
    final cloud = ref.read(cloudRepositoryProvider);
    return cloud.sendRAPin(
        sessionId: state.sessionId, token: state.token, method: method);
  }

  Future<({String networkId, String token, String serialNumber})> raPinVerify(
      {required String pin}) {
    final cloud = ref.read(cloudRepositoryProvider);
    return cloud
        .pinVerify(sessionId: state.sessionId, token: state.token, pin: pin)
        .then((value) => (
              networkId: value.networkId,
              token: value.token,
              serialNumber: state.serialNumber
            ));
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
    prefs.remove(pRAMode);
    state = const RASession(sessionId: '', token: '');
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

  // For RA agent side
  void startMonitorSession() {
    _sessionIdSubscription?.cancel();
    _sessionIdSubscription =
        pollSessionInfo().listen((event) {}, onError: (error) {
      logger.i('RA Session expired');
      ref.read(authProvider.notifier).logout();
    }, cancelOnError: true);
  }

  void stopMonitorSession() {
    _sessionIdSubscription?.cancel();
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
