import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:moab_poc/network/model/command/mqtt_base_command.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../util/logger.dart';

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

  MqttClientWrap(this._endpoint, this._port, this._clientId);

  Future<void> connect() async {
    // Create the client
    _client = MqttServerClient.withPort(_endpoint, _clientId, _port)
      ..secure = true // Set secure
      ..keepAlivePeriod = 20 // Set Keep-Alive
      ..setProtocolV311() // Set the protocol to V3.1.1 for AWS IoT Core, if you fail to do this you will receive a connect ack with the response code
      // ..logging(on: true); // logging if you wish
      ..onBadCertificate = _onBadCertificate;

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
      await _client.connect();
    } on Exception catch (e) {
      logger.i('MQTT client exception - $e');
      _client.disconnect();
    }

    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      // Print incoming messages from another client on this topic
      _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
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
      });

      /// If needed you can listen for published messages that have completed the publishing
      /// handshake which is Qos dependant. Any message received on this stream has completed its
      /// publishing handshake with the broker unless the message is a Qos 1 message and manual
      /// acknowledge has been set on the client, in which case the user must manually acknowledge the
      /// received publish message on completion of any business logic processing.
      _client.published!.listen((MqttPublishMessage message) {
        final pt =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);
        final id = BaseMqttCommand.extractUUID(pt);
        logger.i(
            'MQTT:: Published notification:: id is <$id>, topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}, message $pt');
        if ((id ?? '').isNotEmpty) {
          final command = _commandMap[id];
          if (command?.topic == message.variableHeader!.topicName) {
            command?.completePuback();
          }
        }
      });
    }
  }

  Future<void> disconnect() async {
    _client.disconnect();
  }

  void subscribe(String topic) {
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void unSubscribe(String topic) {
    _client.unsubscribe(topic);
  }

  bool isTopicSubscribe(String topic) {
    return _client.getSubscriptionsStatus(topic) ==
        MqttSubscriptionStatus.active;
  }

  Future send(BaseMqttCommand command) async {
    final message = json.encode(command.data);
    final topic = command.topic;
    final qos = command.qos;
    final msgId = command.uuid;
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
    final localCa = String.fromCharCodes(caCert!).trim();
    return x509.pem.trim() == localCa &&
        _certExpirationCheck(x509.startValidity, x509.endValidity);
  }

  bool _certExpirationCheck(DateTime start, DateTime end) {
    final nowDate = DateTime.now();
    return nowDate.isAfter(start) && nowDate.isBefore(end);
  }
}