import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:linksys_moab/network/mqtt/model/command/jnap/side_effects.dart';
import 'package:linksys_moab/network/mqtt/model/command/mqtt_base_command.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../util/logger.dart';

typedef OnMessageReceived = Function(String tpoic, String payload);
typedef OnMessageExpired = Function();

class MqttClientWrap {
  final String _endpoint;
  final int _port;
  final String _clientId;
  Int8List? caCert;
  Int8List? cert;
  Int8List? keyCert;

  // Message Map
  final Map<String, BaseMqttCommand> _commandMap = {};

  // Callbacks
  ConnectCallback? connectCallback;
  DisconnectCallback? disconnectCallback;
  OnMessageReceived? messageReceivedCallback;
  SubscribeCallback? subscribeCallback;
  UnsubscribeCallback? unsubscribeCallback;

  late MqttServerClient _client;

  final StreamController<MqttCommand> _commandStreamController = StreamController(sync: true);
  StreamSubscription? _subscription;

  MqttClientWrap(this._endpoint, this._port, this._clientId);

  Future<void> connect({String? username, String? password, bool secure = true}) async {
    // Create the client
    _client = MqttServerClient.withPort(_endpoint, _clientId, _port)
      ..keepAlivePeriod = 20 // Set Keep-Alive
      ..setProtocolV311() // Set the protocol to V3.1.1 for AWS IoT Core, if you fail to do this you will receive a connect ack with the response code
      ..logging(on: true) // logging if you wish
      ..onBadCertificate = _onBadCertificate;

    _client.secure = secure;
    if (secure) {
      // Set the security context as you need, note this is the standard Dart SecurityContext class.
      // If this is incorrect the TLS handshake will abort and a Handshake exception will be raised,
      // no connect ack message will be received and the broker will disconnect.
      // For AWS IoT Core, we need to set the AWS Root CA, device cert & device private key
      // Note that for Flutter users the parameters above can be set in byte format rather than file paths
      final context = SecurityContext(withTrustedRoots: true);
      // final context = SecurityContext.defaultContext;

      if (caCert != null) {
        context.setClientAuthoritiesBytes(caCert!);
        context.setTrustedCertificatesBytes(caCert!);
      }
      if (cert != null) {
        context.useCertificateChainBytes(cert!);
      }
      if (keyCert != null) {
        context.usePrivateKeyBytes(keyCert!);
      }
      _client.securityContext = context;
    }
    // Setup the connection Message
    final connMess =
        MqttConnectMessage().withClientIdentifier(_clientId).startClean();
    _client.connectionMessage = connMess;
    _client.onConnected = connectCallback;
    _client.onDisconnected = disconnectCallback;
    _client.onSubscribed = subscribeCallback;
    _client.onUnsubscribed = unsubscribeCallback;

    // Connect the client
    try {
      logger.i('MQTT client connecting to endpoint: $_endpoint');
      await _client.connect(username, password);
    } on Exception catch (e) {
      logger.i('MQTT client exception - $e');
      _client.disconnect();
    }

    logger.i('MQTT client status: ${_client.connectionStatus!.state}');
    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      // Print incoming messages from another client on this topic
      _client.updates!.listen(_handleReceiveMessage);

      /// If needed you can listen for published messages that have completed the publishing
      /// handshake which is Qos dependant. Any message received on this stream has completed its
      /// publishing handshake with the broker unless the message is a Qos 1 message and manual
      /// acknowledge has been set on the client, in which case the user must manually acknowledge the
      /// received publish message on completion of any business logic processing.
      _client.published!.listen(_handlePublishMessage);

      // TODO
      /// command queue w/ subscription
      ///
      _subscription?.cancel();
      _subscription = _commandStreamController.stream.listen((command) async {
        if (command is WiFiInterruptCommand) {
          // wait for MQTT connect back
          int maxRetry = 30;
          int delay = 10;
          int retry = 0;
          Timer timer = Timer.periodic(Duration(seconds: delay), (timer) async {
            await connect(username: 'linksys', password: 'admin');
            if (_client.connectionStatus!.state == MqttConnectionState.connected) {
              // connected
              timer.cancel();
              // check connected router is our target
            }
          });
          //
        } else {
          send(command);
        }
      });
    }
  }

  _handleReceiveMessage(List<MqttReceivedMessage<MqttMessage>> c) {
    final recMess = c[0].payload as MqttPublishMessage;
    final pt =
    MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    final id = BaseMqttCommand.extractUUID(pt);
    logger.i(
        'MQTT:: onReceived: message id is <$id>, topic is <${c[0].topic}>, payload is <-- $pt -->');

    if ((id ?? '').isNotEmpty) {
      final command = _commandMap[id];
      command?.completeResponse(pt);
    }
    messageReceivedCallback?.call(c[0].topic, pt);
  }

  _handlePublishMessage(MqttPublishMessage message) {
    final pt =
    MqttPublishPayload.bytesToStringAsString(message.payload.message);
    final id = BaseMqttCommand.extractUUID(pt);
    logger.i(
        'MQTT:: Published notification:: id is <$id>, topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}, message $pt');
    if ((id ?? '').isNotEmpty) {
      final command = _commandMap[id];
      if (command?.publishTopic == message.variableHeader!.topicName) {
        command?.completePuback();
      }
    }
  }

  Future<void> disconnect() async {
    _client.disconnect();
  }

  MqttConnectionState? get connectionState => _client.connectionStatus?.state;

  Subscription? subscribe(String topic) {
    return _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void unSubscribe(String topic) {
    _client.unsubscribe(topic);
  }

  bool isTopicSubscribe(String topic) {
    return _client.getSubscriptionsStatus(topic) ==
        MqttSubscriptionStatus.active;
  }

  Future send(BaseMqttCommand command) async {
    final message = command.data;
    final topic = command.publishTopic;
    final qos = command.qos;
    final msgId = command.spec.uuid;
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, qos, builder.payload!);
    logger.i(
        'MQTT:: send: id: $msgId, topic: $topic, message: $message wait for PUBACK');
    _commandMap[msgId] = command;
  }

  void dropCommand(String id) {
    if (_commandMap.containsKey(id)) {
      _commandMap.remove(id);
      logger.i('MQTT:: drop command $id: command size: ${_commandMap.length}');
    }
  }

  bool _onBadCertificate(dynamic cert) {
    X509Certificate x509 = cert;
    logger.i("cert: ${x509.startValidity}, ${x509.endValidity}");
    logger.i('cert info: ${x509.issuer}');
    logger.i('cert info: ${x509.subject}');
    return true;
    // final localCa = String.fromCharCodes(caCert!).trim();
    // return x509.pem.trim() == localCa &&
    //     _certExpirationCheck(x509.startValidity, x509.endValidity);
  }

  bool _certExpirationCheck(DateTime start, DateTime end) {
    final nowDate = DateTime.now();
    return nowDate.isAfter(start) && nowDate.isBefore(end);
  }
}
