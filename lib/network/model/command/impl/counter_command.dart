import 'dart:convert';

import 'package:moab_poc/util/logger.dart';

import '../mqtt_base_command.dart';

class CounterCommand extends MqttCommand {
  @override
  String get responseTopic => 'immediately/response';

  @override
  String get topic => 'immediately';

  @override
  Duration get responseTimeout => const Duration(seconds: 5);

  @override
  Map<String, dynamic> createResponse(String payload) {
    logger.d('CounterCommand: create response');
    return json.decode(payload) as Map<String, dynamic>;
  }
}

class CounterDelay5Command extends CounterCommand {
  @override
  String get responseTopic => 'delay/5s/response';
  @override
  String get topic => 'delay/5s';
}

class CounterDelay10Command extends CounterCommand {
  @override
  String get responseTopic => 'delay/10s/response';
  @override
  String get topic => 'delay/10s';
}