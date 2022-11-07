import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/connectivity/state.dart';
import 'package:linksys_moab/bloc/mixin/stream_mixin.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/constants/pref_key.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_config.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/network/mqtt/mqtt_client_wrap.dart';
import 'package:linksys_moab/repository/security_context_loader_mixin.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';
import 'package:logger/logger.dart';
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

typedef MqttConnectionCallback = void Function(bool isConnected);

class RouterRepository with StateStreamListener {
  RouterRepository() {
    CloudEnvironmentManager().register(this);
  }

  MqttClientWrap? _mqttClient;

  MqttClientWrap? get mqttClient => _mqttClient;

  MqttConnectType _connectType = MqttConnectType.none;
  MqttConnectType get connectType => _connectType;

  final String clientId = Utils.generateMqttClintId();

  String? _brokerUrl;
  String? _localBrokerUrl;
  String? localPassword;
  List<String> topics = [];

  String? _groupId;
  String? _networkId;

  LoginFrom _loginType = LoginFrom.none;
  RouterType _routerType = RouterType.others;

  final List<MqttConnectionCallback> _callbacks = [];



  void addMqttConnectionCallback(MqttConnectionCallback callback) {
    if (_callbacks.contains(callback)) {
      return;
    }
    _callbacks.add(callback);
  }

  void removeMqttConnectionCallback(MqttConnectionCallback callback) {
    if (_callbacks.contains(callback)) {
      _callbacks.remove(callback);
    }
  }

  Future<bool> downloadRemoteCert() async {
    final _client = MoabHttpClient(timeoutMs: 10000);
    var cert = '';
    final ret = await _client.get(Uri.parse(awsIoTRootCA)).then((response) {
      cert = response.body;
      return response.statusCode == HttpStatus.ok;
    }).onError((error, stackTrace) => false);
    if (!ret) {
      return false;
    }
    final pref = await SharedPreferences.getInstance();
    await pref.setString(moabPrefRemoteCaCert, cert);
    return true;
  }

  // TODO #WORKAROUND cert download issue
  Future<bool> testLocalCert({String? gatewayIp}) async {
    if ((_localBrokerUrl?.isEmpty ?? true) && (gatewayIp?.isEmpty ?? true)) {
      return false;
    }
    const credentials = 'admin:admin';
    String cert = '';
    final _client = MoabHttpClient(timeoutMs: 1000, retries: 1);
    var ret = await _client.get(
        Uri.parse('http://${gatewayIp ?? _localBrokerUrl}/cert.cgi'),
        headers: {
          'Authorization': 'Basic ${Utils.stringBase64Encode(credentials)}',
        }).then((response) {
      cert = response.body;
      return response.statusCode == HttpStatus.ok &&
          response.body.contains('BEGIN CERTIFICATE');
    }).onError((error, stackTrace) => false);
    logger.d('test local cert 1st: $ret');
    // try with 52000 port if false
    if (!ret) {
      ret = await _client.get(
          Uri.parse('http://${gatewayIp ?? _localBrokerUrl}:52000/cert.cgi'),
          headers: {
            'Authorization': 'Basic ${Utils.stringBase64Encode(credentials)}',
          }).then((response) {
        cert = response.body;
        return response.statusCode == HttpStatus.ok &&
            response.body.contains('BEGIN CERTIFICATE');
      }).onError((error, stackTrace) => false);
      logger.d('test local cert 2nd: $ret');
      if (!ret) {
        return false;
      }
    }

    final pref = await SharedPreferences.getInstance();
    await pref.setString(moabPrefLocalCert, cert);
    return true;
  }

  Future<bool> downloadLocalCert({String? gatewayIp}) async {
    // final caCert = await rootBundle.loadString('assets/keys/server.pem');
    // final pref = await SharedPreferences.getInstance();
    // await pref.setString(moabPrefLocalCert, caCert);
    // return true;
    if (_localBrokerUrl?.isEmpty ?? true) {
      return false;
    }
    const credentials = 'admin:admin';
    final _client = MoabHttpClient(timeoutMs: 1000);
    final response = await _client.get(
        Uri.parse('http://${gatewayIp ?? _localBrokerUrl}/cert.cgi'),
        headers: {
          'Authorization': 'Basic ${Utils.stringBase64Encode(credentials)}',
        });
    if (response.statusCode != HttpStatus.ok) {
      return false;
    }
    final pref = await SharedPreferences.getInstance();
    await pref.setString(moabPrefLocalCert, response.body);
    return true;
  }

  Future<bool> connectToBroker() async {
    if (_loginType == LoginFrom.remote) {
      return _routerType == RouterType.managedMoab
          ? connectToLocalWithCloudCert()
          : connectToRemote();
    } else if (_loginType == LoginFrom.local) {
      return connectToLocalWithPassword();
    } else {
      return false;
    }
  }

  Future<bool> connectToRemote() async {
    _brokerUrl = CloudEnvironmentManager().currentConfig?.transport.mqttBroker;
    int port = CloudEnvironmentManager().currentConfig?.transport.port ?? 8883;
    final pref = await SharedPreferences.getInstance();
    const storage = FlutterSecureStorage();
    String cert = pref.getString(moabPrefRemoteCaCert) ?? '';
    String publicKey = pref.getString(moabPrefCloudPublicKey) ?? '';
    String privateKey = await storage.read(key: moabPrefCloudPrivateKey) ?? '';
    String accountId = pref.getString(moabPrefCloudAccountId) ?? '';
    if (accountId.isEmpty) {
      // TODO #ERRORHANDLING No account information
      return false;
    }
    if (cert.isEmpty) {
      await downloadRemoteCert();
      cert = pref.getString(moabPrefRemoteCaCert) ?? '';
    }
    logger.d('ca root: $cert');

    if (_mqttClient?.connectionState == MqttConnectionState.connected) {
      await _mqttClient?.disconnect();
    }

    _mqttClient = MqttClientWrap(_brokerUrl ?? '', port, 'AC:$accountId');
    _initCallbacks();
    _mqttClient?.caCert = Int8List.fromList(cert.codeUnits);
    _mqttClient?.cert = Int8List.fromList(publicKey.codeUnits);
    _mqttClient?.keyCert = Int8List.fromList(privateKey.codeUnits);
    await _mqttClient?.connect();
    logger.d('MQTT connection status: ${_mqttClient?.connectionState}');
    if (_mqttClient?.connectionState == MqttConnectionState.connected) {
      _groupId = pref.getString(moabPrefCloudDefaultGroupId) ?? '';
      _networkId = pref.getString(moabPrefSelectedNetworkId) ?? '';
      topics.clear();
      topics.addAll([
        mqttRemoteResponseTopic
            .replaceFirst(varMqttGroupId, _groupId!)
            .replaceFirst(varMqttNetworkId, _networkId!)
      ]);
      for (var topic in topics) {
        final sub = _mqttClient?.subscribe(topic);
        logger.d('Subscribe Topic: ${sub?.topic}');
      }
      _connectType = MqttConnectType.remote;
      return true;
    } else {
      _connectType = MqttConnectType.none;
      return false;
    }
  }

  Future<bool> connectToLocalWithCloudCert({String? gatewayIp}) async {
    logger.d('connectToLocalWithCloudCert: $_loginType');

    if (_loginType != LoginFrom.remote) {
      return false;
    }
    logger.d('connectToLocalWithCloudCert');
    final pref = await SharedPreferences.getInstance();
    const storage = FlutterSecureStorage();
    String cert = pref.getString(moabPrefLocalCert) ?? '';
    String publicKey = pref.getString(moabPrefCloudPublicKey) ?? '';
    String privateKey = await storage.read(key: moabPrefCloudPrivateKey) ?? '';
    if (cert.isEmpty) {
      await testLocalCert();
      cert = pref.getString(moabPrefLocalCert) ?? '';
    }
    if (_mqttClient?.connectionState == MqttConnectionState.connected) {
      await _mqttClient?.disconnect();
    }
    _mqttClient =
        MqttClientWrap(gatewayIp ?? _localBrokerUrl ?? '', 8333, clientId);
    _initCallbacks();
    _mqttClient?.caCert = Int8List.fromList(cert.codeUnits);
    _mqttClient?.cert = Int8List.fromList(publicKey.codeUnits);
    _mqttClient?.keyCert = Int8List.fromList(privateKey.codeUnits);
    await _mqttClient?.connect();
    if (_mqttClient?.connectionState == MqttConnectionState.connected) {
      topics.clear();
      topics.addAll([mqttLocalResponseTopic]);
      for (var topic in topics) {
        final sub = _mqttClient?.subscribe(topic);
        logger.d('Subscribe Topic: ${sub?.topic}');
      }
      _connectType = MqttConnectType.local;
      return true;
    } else {
      _connectType = MqttConnectType.none;
      return false;
    }
  }

  Future<bool> connectToLocalWithPassword() async {
    final pref = await SharedPreferences.getInstance();
    String cert = pref.getString(moabPrefLocalCert) ?? '';
    if (cert.isEmpty) {
      logger.d('connectToLocalWithPassword: cert is empty');
      await testLocalCert();
      cert = pref.getString(moabPrefLocalCert) ?? '';
    }
    if (_mqttClient?.connectionState == MqttConnectionState.connected) {
      await _mqttClient?.disconnect();
    }
    final clientId = Utils.generateMqttClintId().substring(0, 23);
    _mqttClient = MqttClientWrap(_localBrokerUrl ?? '', 8833, clientId);
    _initCallbacks();
    _mqttClient?.caCert = Int8List.fromList(cert.codeUnits);
    await _mqttClient?.connect(username: 'linksys', password: 'admin');
    if (_mqttClient?.connectionState == MqttConnectionState.connected) {
      topics.clear();
      topics.addAll([mqttLocalResponseTopic]);
      for (var topic in topics) {
        final sub = _mqttClient?.subscribe(topic);
        logger.d('Subscribe Topic: ${sub?.topic}');
      }
      _connectType = MqttConnectType.local;
      return true;
    } else {
      _connectType = MqttConnectType.none;
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
    if (_connectType == MqttConnectType.local) {
      return JnapCommand.local(
        action: action,
        auth: needAuth
            ? 'Basic ${Utils.stringBase64Encode(localPassword!)}'
            : null,
        data: data,
      );
    } else if (_connectType == MqttConnectType.remote) {
      return JnapCommand.remote(
          gid: _groupId!, nid: _networkId!, action: action, data: data);
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
    } else if (event is CloudConfig) {
      _onRegionChanged(event);
    }
  }

  _handleConnectivityChanged(ConnectivityState state) async {
    logger.d('Router repository:: handleConnectivityChanged: $state');
    if (_routerType != state.connectivityInfo.routerType ||
        _localBrokerUrl != state.connectivityInfo.gatewayIp) {
      _localBrokerUrl = state.connectivityInfo.gatewayIp;
      _routerType = state.connectivityInfo.routerType;
      connectToBroker();
    }
  }

  _handleAuthChanged(AuthState state) async {
    logger.d(
        'Router repository:: _handleAuthChanged: $state, ${state.runtimeType}');
    final pref = await SharedPreferences.getInstance();
    if (state is AuthCloudLoginState) {
      _loginType = LoginFrom.remote;
      _brokerUrl =
          CloudEnvironmentManager().currentConfig?.transport.mqttBroker;
      // connectToBroker();
    } else if (state is AuthLocalLoginState) {
      _loginType = LoginFrom.local;
      localPassword = pref.getString(moabPrefLocalPassword);
      // connectToLocalWithPassword();
    } else if (state is AuthUnAuthorizedState) {
      _loginType = LoginFrom.none;
      _connectType = MqttConnectType.none;
      // remove all information
      localPassword = 'admin';
      disconnect();
    }
  }

  _onRegionChanged(CloudConfig config) async {
    if (_brokerUrl == config.transport.mqttBroker) {
      return;
    }
    // reconnect again
    await connectToBroker();
  }

  _setConnectType(MqttConnectType type) {
    _connectType = type;
  }

  _initCallbacks() {
    _mqttClient?.disconnectCallback = () {
      for (var callback in _callbacks) {
        callback.call(false);
      }
    };
    _mqttClient?.connectCallback = () {
      for (var callback in _callbacks) {
        callback.call(true);
      }
    };
  }
}
