import 'dart:io';

import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/network/base_client.dart';
import 'package:linksys_moab/network/mqtt/command_spec/impl/jnap_spec.dart';
import 'package:linksys_moab/network/mqtt/model/command/base_command.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';

abstract class BaseHttpCommand<R> extends BaseCommand<R> {
  BaseHttpCommand({required this.url, required super.spec});

  final String url;

  String _data = '';

  String get data => _data;

  Map<String, String> _header = {};

  Map<String, String> get header => _header;

  R createResponse(String payload) => spec.response(payload);
}

class JNAPHttpCommand<JNAPResult> extends BaseHttpCommand {
  JNAPHttpCommand({
    required super.url,
    required String action,
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeader = const {},
  }) : super(
            spec: HttpJNAPSpec(
          action: action,
          data: data,
          extraHeader: extraHeader,
        ));

  @override
  Future<JNAPResult> publish(JNAPCommandExecutor executor) async {
    _data = spec.payload();
    _header = {
      keyMqttHeaderAction: spec.action,
      HttpHeaders.contentTypeHeader: ContentType.json.value,
      HttpHeaders.acceptEncodingHeader: '*/*',
      ...spec.extraHeader
    }..removeWhere((key, value) => value.isEmpty);
    final result = await executor.execute(this);
    return createResponse(result.body);
  }
}
