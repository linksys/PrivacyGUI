import 'dart:io';
import 'dart:typed_data';

import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/mqtt/mqtt_client_wrap.dart';
import 'package:linksys_moab/repository/authenticate/local_auth_repository.dart';
import 'package:linksys_moab/repository/model/dummy_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouterAuthRepository extends LocalAuthRepository
    with ConnectivityListener {
  RouterAuthRepository(MoabHttpClient httpClient)
      : _httpclient = httpClient {
    start();
  }

  final MoabHttpClient _httpclient;
  MqttClientWrap? _mqttClient;
  String? _gatewayIp;


  @override
  Future<DummyModel> createPassword(String password, String hint) {
    // TODO: implement createPassword
    throw UnimplementedError();
  }

  @override
  Future<bool> downloadCert() async {
    const credentials = 'admin:admin';
    final _client = MoabHttpClient(timeoutMs: 1000);
    final response = await _client.get(Uri.parse('http://$_gatewayIp/cert.cgi'), headers: {
      'Authorization': 'Basic ${Utils.stringBase64Encode(credentials)}',
    });
    if (response.statusCode != HttpStatus.ok) {
      return false;
    }
    final pref = await SharedPreferences.getInstance();
    await pref.setString(moabPrefLocalCert, response.body);
    return true;
  }

  @override
  Future<DummyModel> getAdminPasswordInfo() {
    return Future.value({'hasAdminPassword': true, 'hint': 'admin'});
  }

  @override
  Future<DummyModel> getCloudAccount() {
    // TODO: implement getCloudAccount
    throw UnimplementedError();
  }

  @override
  Future<DummyModel> getMaskedEmail() {
    // TODO: implement getMaskedEmail
    throw UnimplementedError();
  }

  @override
  Future<bool> localLogin(String password) async {
    final pref = await SharedPreferences.getInstance();
    final cert = pref.getString(moabPrefLocalCert) ?? '';
    _mqttClient = MqttClientWrap(_gatewayIp ?? '', 8833, Utils.generateMqttClintId());
    _mqttClient?.caCert = Int8List.fromList(cert.codeUnits);
    await _mqttClient?.connect(username: 'linksys', password: password);
    return _mqttClient?.connectionState == MqttConnectionState.connected;
  }

  @override
  Future<DummyModel> resetPassword() {
    // TODO: implement resetPassword
    throw UnimplementedError();
  }

  @override
  Future<DummyModel> verifyRecoveryKey(String key) {
    // TODO: implement verifyRecoveryKey
    throw UnimplementedError();
  }

  @override
  Future onConnectivityChanged(ConnectivityInfo info) async {
    _gatewayIp = info.gatewayIp;
  }
}
