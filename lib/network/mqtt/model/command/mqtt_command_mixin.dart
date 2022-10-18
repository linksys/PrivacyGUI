import 'dart:async';

import 'package:linksys_moab/network/mqtt/exception.dart';

mixin CommandCompleter {
  final Completer<String> _responseCompleter = Completer();
  final Completer _pubackCompleter = Completer();

  Future<dynamic> waitForPuback(Duration duration) =>
      _pubackCompleter.future.timeout(duration, onTimeout: () {
        throw MqttTimeoutException('MQTT PUBACK timeout!');
      });
  Future<dynamic> waitForResponse(Duration duration) =>
      _responseCompleter.future.timeout(duration, onTimeout: () {
        throw MqttTimeoutException('MQTT response timeout!');
      });

  void completeResponse(String response) {
    _responseCompleter.complete(response);
  }

  void completePuback() {
    _pubackCompleter.complete();
  }
}