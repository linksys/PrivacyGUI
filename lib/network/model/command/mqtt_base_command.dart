import 'dart:convert';

import 'package:moab_poc/network/model/exception.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:uuid/uuid.dart';

import '../../../util/logger.dart';
import '../../mqtt_client_wrap.dart';
import 'mqtt_command_mixin.dart';

abstract class BaseMqttCommand<D, R> with CommandCompleter {
  static const Uuid _uuid = Uuid();

  BaseMqttCommand({String? id}) : uuid = id ?? _uuid.v1();

  final String uuid;

  final qos = MqttQos.atLeastOnce;

  String get topic;

  String get responseTopic;

  late final D _data;

  D get data => _data;

  R createResponse(String payload);

  Future<R> publish(MqttClientWrap client, D data) async {
    try {
      _data = data;
      await client.send(this);
      await waitForPuback(const Duration(seconds: 1));
      final payload = await waitForResponse(const Duration(seconds: 5));
      logger.i('MQTT Command:: response!');
      return createResponse(payload);
    } on MqttTimeoutException catch(e) {
      logger.e('MQTT timeout! $e');
      rethrow;
    } catch (e) {
      logger.d('Unhandled exception: $e}');
      rethrow;
    } finally {
      client.dropCommand(uuid);
    }
  }

  static String? extractUUID(String payload) {
    try {
      final jsonData = json.decode(payload) as Map<String, dynamic>;
      return jsonData['id'] as String?;
    } catch (e) {
      logger.d('extract uuid failed!');
      return null;
    }
  }
}

typedef MqttCommand = BaseMqttCommand<Map<String, dynamic>, Map<String, dynamic>>;
