import 'dart:io';

import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/network/jnap/jnap_command_executor_mixin.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/network/jnap/spec/jnap_spec.dart';
import 'package:linksys_moab/network/jnap/command/base_command.dart';

abstract class BaseBTCommand<R, S extends JNAPCommandSpec> extends BaseCommand<R, S> {
  BaseBTCommand({required super.spec});

  String _data = '';

  String get data => _data;

  R createResponse(String payload) => spec.response(payload);
}

class JNAPBTCommand extends BaseBTCommand<JNAPResult, BTJNAPSpec> {
  JNAPBTCommand({
    required String action,
    Map<String, dynamic> data = const {},
  }) : super(
            spec: BTJNAPSpec(
          action: action,
          data: data,
        ));

  @override
  Future<JNAPResult> publish(JNAPCommandExecutor executor) async {
    _data = spec.payload();
    final result = await executor.execute(this);
    return result;
  }
}
