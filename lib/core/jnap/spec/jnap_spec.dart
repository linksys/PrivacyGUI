import 'dart:convert';

import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

import 'command_spec.dart';

/// Decodes a JSON string, converting FormatException to JNAPError.
///
/// When JNAP is disabled on the router, HTTP responses return HTML instead
/// of JSON. This helper ensures the FormatException from json.decode flows
/// through the normal JNAPError handling pipeline rather than being uncaught.
Map<String, dynamic> _decodeJson(String raw) {
  try {
    return json.decode(raw) as Map<String, dynamic>;
  } on FormatException {
    throw const JNAPError(
      result: '_ErrorJNAPUnavailable',
      error: 'JNAP endpoint returned non-JSON response',
    );
  }
}

abstract class JNAPSpec<R> extends CommandSpec<R> {
  JNAPSpec({
    required this.action,
    this.extraHeader = const {},
  });

  final String action;
  final Map<String, String> extraHeader;
}

abstract class JNAPCommandSpec<R> extends JNAPSpec<R> {
  JNAPCommandSpec({
    required super.action,
    this.data = const {},
    super.extraHeader = const {},
  });

  final Map<String, dynamic> data;
}

class HttpTransactionSpec extends JNAPSpec<JNAPResult> {
  final List<Map<String, dynamic>> _payload;

  HttpTransactionSpec({
    required List<Map<String, dynamic>> payload,
    super.extraHeader = const {},
  })  : _payload = payload,
        super(action: JNAPAction.transaction.actionValue);

  @override
  String payload() {
    return json.encode(_payload);
  }

  @override
  JNAPResult response(String raw) {
    return JNAPResult.fromJson(_decodeJson(raw));
  }
}

class HttpJNAPSpec extends JNAPCommandSpec<JNAPResult> {
  HttpJNAPSpec({required super.action, super.data, super.extraHeader});

  @override
  JNAPResult response(String raw) {
    return JNAPResult.fromJson(_decodeJson(raw));
  }

  @override
  String payload() {
    return json.encode(data);
  }
}

class BTJNAPSpec extends JNAPCommandSpec<JNAPResult> {
  static const _host = "Host:www.linksyssmartwifi.com";
  static const _baseAction = "X-JNAP-Action:";
  static const _contentType = "Content-Type:application/json; charset=utf-8";
  static const _auth = "X-JNAP-Authorization:Basic YWRtaW46YWRtaW4=";

  BTJNAPSpec({required super.action, super.data})
      : super(extraHeader: const {});

  @override
  String payload() {
    return '$_host\n$_baseAction$action\n$_auth\n$_contentType\n${jsonEncode(data)}\n';
  }

  @override
  JNAPResult response(String raw) {
    return JNAPResult.fromJson(json.decode(raw));
  }

  int get encodedLength => payload().codeUnits.length;
}
