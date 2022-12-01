import 'dart:convert';

import 'package:linksys_moab/network/jnap/result/jnap_result.dart';

import 'command_spec.dart';

abstract class JNAPCommandSpec<R> extends CommandSpec<R> {
  JNAPCommandSpec({
    required this.action,
    this.data = const {},
    this.extraHeader = const {},
  });

  final String action;
  final Map<String, dynamic> data;
  final Map<String, String> extraHeader;
}

class HttpJNAPSpec extends JNAPCommandSpec<JNAPResult> {
  HttpJNAPSpec(
      {required super.action, super.data, super.extraHeader});

  @override
  JNAPResult response(String raw) {
    return JNAPResult.fromJson(json.decode(raw));
  }

  @override
  String payload() {
    return json.encode(data);
  }
}

class BTJNAPSpec extends JNAPCommandSpec<JNAPResult> {
  static const _host = "Host:www.linksyssmartwifi.com";
  static const _baseAction = "X-JNAP-Action:http://linksys.com/jnap";
  static const _contentType = "Content-Type:application/json; charset=utf-8";
  static const _auth = "X-JNAP-Authorization:Basic YWRtaW46YWRtaW4=";
  BTJNAPSpec({required super.action, super.data}): super(extraHeader: const {});

  @override
  String payload() {
    return '$_host\n$_baseAction$action\n$_auth\n$_contentType\n${jsonEncode(data)}\n';
  }

  @override
  JNAPResult response(String raw) {
    return JNAPResult.fromJson(json.decode(raw));
  }
}
