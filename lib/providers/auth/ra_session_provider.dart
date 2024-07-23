import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/ra_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

final raSessionProvider =
    NotifierProvider<RASessionNotifier, RASession>(() => RASessionNotifier());

class RASessionNotifier extends Notifier<RASession> {
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
    final pin = await cloud.raGenPin(
      sessionId: sessionId,
      networkId: networkId,
    );
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
}

class RAException extends Error {}

class RANoSessionException extends RAException {}
