import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/connectivity/state.dart';
import 'package:linksys_moab/bloc/mixin/stream_mixin.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/constants/pref_key.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/network/mqtt/mqtt_client_wrap.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MqttConnectType {
  none,
  local,
  remote,
}

class CommandWrap {
  CommandWrap({
    required this.action,
    required this.needAuth,
    this.data = const {},
  });

  final String action;
  final bool needAuth;
  Map<String, dynamic> data;
}

class RouterRepository with StateStreamListener {
  RouterRepository();

  MqttClientWrap? _mqttClient;

  MqttClientWrap? get mqttClient => _mqttClient;

  MqttConnectType connectType = MqttConnectType.none;

  String? _brokerUrl;
  String? localPassword;
  List<String> topics = [];

  Future<bool> downloadCert() async {
    // final caCert = await rootBundle.loadString('assets/keys/server.pem');
    // final pref = await SharedPreferences.getInstance();
    // await pref.setString(moabPrefLocalCert, caCert);
    // return true;
    const credentials = 'admin:admin';
    final _client = MoabHttpClient(timeoutMs: 1000);
    final response = await _client.get(Uri.parse('http://$_brokerUrl/cert.cgi'), headers: {
      'Authorization': 'Basic ${Utils.stringBase64Encode(credentials)}',
    });
    if (response.statusCode != HttpStatus.ok) {
      return false;
    }
    final pref = await SharedPreferences.getInstance();
    await pref.setString(moabPrefLocalCert, response.body);
    return true;
  }

  connectToRemote() async {
    // TODO
    connectType = MqttConnectType.remote;
  }

  Future<bool> connectToLocal() async {
    final pref = await SharedPreferences.getInstance();
    String cert = pref.getString(moabPrefLocalCert) ?? '';
    if (cert.isEmpty) {
      await downloadCert();
      cert = pref.getString(moabPrefLocalCert) ?? '';
    }
    if (_mqttClient?.connectionState == MqttConnectionState.connected) {
      await _mqttClient?.disconnect();
    }
    _mqttClient =
        MqttClientWrap(_brokerUrl ?? '', 8833, Utils.generateMqttClintId());
    _mqttClient?.caCert = Int8List.fromList(cert.codeUnits);
    await _mqttClient?.connect(username: 'linksys', password: 'admin');
    if (_mqttClient?.connectionState == MqttConnectionState.connected) {
      topics.addAll([mqttLocalResponseTopic]);
      for (var topic in topics) {
        _mqttClient?.subscribe(topic);
      }
      connectType = MqttConnectType.local;
      return true;
    } else {
      connectType = MqttConnectType.none;
      return false;
    }
  }

  disconnect() async {
    for (var topic in topics) {
      _mqttClient?.unSubscribe(topic);
    }
    _mqttClient?.disconnect();
  }

  JnapCommand createCommand(String action,
      {Map<String, dynamic> data = const {}, bool needAuth = false}) {
    if (connectType == MqttConnectType.local) {
      return JnapCommand.local(
        action: action,
        auth: needAuth
            ? 'Basic ${Utils.stringBase64Encode(localPassword!)}'
            : null,
        data: data,
      );
    } else if (connectType == MqttConnectType.remote) {
      return JnapCommand.remote(gid: 'gid', nid: 'nid', action: action);
    } else {
      //
      throw Exception();
    }
  }

  JnapSuccess handleJnapResult(JnapResult result) {
    if (result is JnapSuccess) {
      return result;
    } else {
      throw (result as JnapError);
    }
  }

  Future<List<JnapSuccess>> batchCommands(List<CommandWrap> commands) async {
    return Future.wait(
      commands.map(
        (e) => createCommand(e.action, needAuth: e.needAuth, data: e.data)
            .publish(mqttClient!)
            .then(
              (value) => handleJnapResult(value.body),
            ),
      ),
    );
  }

  @override
  consume(event) {
    if (event is ConnectivityState) {
      _handleConnectivityChanged(event);
    } else if (event is AuthState) {
      _handleAuthChanged(event);
    }
  }

  _handleConnectivityChanged(ConnectivityState state) async {
    logger.d('Router repository:: handleConnectivityChanged: $state');
    _brokerUrl = state.connectivityInfo.gatewayIp;
  }

  _handleAuthChanged(AuthState state) async {
    logger.d('Router repository:: _handleAuthChanged: $state, ${state.runtimeType}');
    final pref = await SharedPreferences.getInstance();
    if (state is AuthCloudLoginState) {
      // get cloud certs and etc...
      _brokerUrl =
          CloudEnvironmentManager().currentConfig?.transport.mqttBroker;
      connectToRemote();
    } else if (state is AuthLocalLoginState) {
      // get local password and cert, etc...
      localPassword = pref.getString(moabPrefLocalPassword);
      connectToLocal();
    } else if (state is AuthUnAuthorizedState) {
      connectType = MqttConnectType.none;
      // remove all information
      localPassword = 'admin';
      disconnect();
    }
  }
}
