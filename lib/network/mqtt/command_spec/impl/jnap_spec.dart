import 'dart:convert';

import 'package:linksys_moab/network/mqtt/command_spec/command_spec.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';

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
