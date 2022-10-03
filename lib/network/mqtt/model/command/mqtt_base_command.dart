import 'dart:convert';

import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/network/mqtt/command_spec/command_spec.dart';
import 'package:linksys_moab/network/mqtt/exception.dart';
import 'package:linksys_moab/network/mqtt/mqtt_client_wrap.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_command_mixin.dart';

abstract class BaseMqttCommand<R> with CommandCompleter {

  BaseMqttCommand({required this.spec});

  final CommandSpec<R> spec;

  final qos = MqttQos.atLeastOnce;

  String get publishTopic;

  String get responseTopic;

  Duration pubackTimeout = const Duration(seconds: 1);

  Duration responseTimeout = const Duration(seconds: 30);

  String _data = '';
  String get data => _data;

  R createResponse(String payload) => spec.response(payload);

  Future<R> publish(MqttClientWrap client) async {
    try {
      _data = spec.payload();
      await client.send(this);
      await waitForPuback(pubackTimeout);
      final payload = await waitForResponse(responseTimeout);
      logger.i('MQTT Command:: response!');
      return createResponse(payload);
    } on MqttTimeoutException catch(e) {
      logger.e('MQTT timeout! ${e.message}');
      rethrow;
    } catch (e) {
      logger.d('Unhandled exception: $e}');
      rethrow;
    } finally {
      client.dropCommand(spec.uuid);
    }
  }

  // TODO
  static String? extractUUID(String payload) {
    try {
      final jsonData = json.decode(payload) as Map<String, dynamic>;
      return jsonData[keyMqttHeader][keyMqttHeaderId] as String?;
    } catch (e) {
      logger.d('extract uuid failed!');
      return null;
    }
  }
}

typedef MqttCommand = BaseMqttCommand<Map<String, dynamic>>;
