import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/spec/jnap_spec.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';

abstract class BaseBTCommand<R, S extends JNAPCommandSpec>
    extends BaseCommand<R, S> {
  BaseBTCommand(
      {required super.spec,
      required super.executor,
      super.fetchRemote,
      super.cacheLevel});

  String _data = '';

  String get data => _data;
}

class JNAPBTCommand extends BaseBTCommand<JNAPResult, BTJNAPSpec> {
  JNAPBTCommand({
    required super.executor,
    required String action,
    super.fetchRemote,
    super.cacheLevel,
    Map<String, dynamic> data = const {},
  }) : super(
            spec: BTJNAPSpec(
          action: action,
          data: data,
        ));

  @override
  Future<JNAPResult> publish() async {
    _data = spec.payload();
    final result = await executor.execute(this);
    return result;
  }
}
