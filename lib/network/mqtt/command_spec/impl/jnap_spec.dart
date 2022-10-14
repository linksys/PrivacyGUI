import 'dart:convert';

import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/network/mqtt/command_spec/command_spec.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';

abstract class JnapCommandSpec<R> extends CommandSpec<R> {

  JnapCommandSpec({required this.action, this.auth, this.data = const {}});

  final String action;
  final String? auth;
  final Map<String, dynamic> data;

  @override
  String payload() {
    var header = {keyMqttHeaderAction: action, keyMqttHeaderId: uuid,};
    if (auth != null) {
      header[keyMqttHeaderAuthorization] = auth!;
    }
    return json.encode({
      keyMqttHeader: header,
      keyMqttBody: data,
    });
  }
}

class BasicJnapSpec extends JnapCommandSpec<JnapResponse> {
  BasicJnapSpec({required super.action, super.auth, super.data});

  @override
  JnapResponse response(String raw) {
    return JnapResponse.fromJson(json.decode(raw));
  }

}

class JNAPTransactionSpec extends CommandSpec<JnapResponse> {

  final List<Map<String, dynamic>> _payload;
  final String? auth;
  
  JNAPTransactionSpec({required List<Map<String, dynamic>> payload, this.auth}): _payload = payload;

  @override
  String payload() {
    var header = {keyMqttHeaderAction: 'http://linksys.com/jnap/core/Transaction', keyMqttHeaderId: uuid,};
    if (auth != null) {
      header[keyMqttHeaderAuthorization] = auth!;
    }
    return json.encode({
      keyMqttHeader: header,
      keyMqttBody: _payload,
    });
  }

  @override
  JnapResponse response(String raw) {
    return JnapResponse.fromJson(json.decode(raw));
  }

}