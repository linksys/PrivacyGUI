import 'dart:io';

import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/network/jnap/spec/jnap_spec.dart';
import 'package:linksys_moab/network/jnap/command/base_command.dart';

abstract class BaseHttpCommand<R, S extends JNAPSpec> extends BaseCommand<R, S> {
  BaseHttpCommand({required this.url, required super.spec, required super.executor});

  final String url;

  String _data = '';

  String get data => _data;

  Map<String, String> _header = {};

  Map<String, String> get header => _header;

  R createResponse(String payload) => spec.response(payload);
}

class JNAPHttpCommand extends BaseHttpCommand<JNAPResult, HttpJNAPSpec> {
  JNAPHttpCommand({
    required super.url,
    required super.executor,
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
  Future<JNAPResult> publish() async {
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

class TransactionHttpCommand extends BaseHttpCommand<JNAPResult, HttpTransactionSpec> {
  TransactionHttpCommand({
    required super.url,
    required super.executor,
    required List<Map<String, dynamic>> payload,
    Map<String, String> extraHeader = const {},
  }) : super(
      spec: HttpTransactionSpec(
        extraHeader: extraHeader, payload: payload,
      ));

  @override
  Future<JNAPResult> publish() async {
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
