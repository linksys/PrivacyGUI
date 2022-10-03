
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/connectivity/state.dart';
import 'package:linksys_moab/bloc/mixin/stream_mixin.dart';
import 'package:linksys_moab/constants/pref_key.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/network/mqtt/mqtt_client_wrap.dart';
import 'package:linksys_moab/repository/model/dummy_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';


class RouterRepository with StateStreamListener{

  RouterRepository();

  MqttClientWrap? _mqttClient;
  String? _gatewayIp;

  Future<bool> downloadCert() async {
    final caCert = await rootBundle.loadString('assets/keys/server.pem');
    final pref = await SharedPreferences.getInstance();
    await pref.setString(moabPrefLocalCert, caCert);
    return true;
    // const credentials = 'admin:admin';
    // final _client = MoabHttpClient(timeoutMs: 1000);
    // final response = await _client.get(Uri.parse('http://$_gatewayIp/cert.cgi'), headers: {
    //   'Authorization': 'Basic ${Utils.stringBase64Encode(credentials)}',
    // });
    // if (response.statusCode != HttpStatus.ok) {
    //   return false;
    // }
    // final pref = await SharedPreferences.getInstance();
    // await pref.setString(moabPrefLocalCert, response.body);
    // return true;
  }

  Future<bool> localLogin(String password) async {
    final pref = await SharedPreferences.getInstance();
    final cert = pref.getString(moabPrefLocalCert) ?? '';
    logger.d('local login: $cert');
    _mqttClient = MqttClientWrap(_gatewayIp ?? '', 8833, Utils.generateMqttClintId());
    _mqttClient?.caCert = Int8List.fromList(cert.codeUnits);
    await _mqttClient?.connect(username: 'linksys', password: password);
    return _mqttClient?.connectionState == MqttConnectionState.connected;
  }

  Future<DummyModel> getAdminPasswordInfo() async {
    if (_mqttClient == null) {
      await localLogin('admin');
    }
    const credentials = 'admin:admin';
    final command = JnapCommand.local(action: 'http://linksys.com/jnap/core/GetAdminPasswordHint', auth: 'Basic ${Utils.stringBase64Encode(credentials)}');
    final subscription = _mqttClient?.subscribe(command.responseTopic);
    logger.d('subscribe topic: $subscription');

    final result = await command.publish(_mqttClient!);
    return _handleJnapResult(result.body);
  }
  Future<DummyModel> createPassword(String password, String hint) {
    // TODO: implement createPassword
    throw UnimplementedError();
  }

  // TODO return generic type
  DummyModel _handleJnapResult(JnapResult result) {
    if (result is JnapSuccess) {
      return result.output;
    } else {
      throw (result as JnapError);
    }
  }

  @override
  consume(event) {
    if (event is ConnectivityState) {
      _handleConnectivityChanged(event);
    } else if (event is AuthState) {
      _handleAuthChanged(event);
    }
  }

  _handleConnectivityChanged(ConnectivityState state) {
    logger.d('Router repository:: handleConnectivityChanged: $state');
    _gatewayIp = state.connectivityInfo.gatewayIp;
  }

  _handleAuthChanged(AuthState state) {
    logger.d('Router repository:: _handleAuthChanged: $state');
    if (state is CloudLogin) {
      // get cloud certs and etc...
    } else if (state is LocalLogin) {
      // get local password and cert, etc...
    }
  }
}