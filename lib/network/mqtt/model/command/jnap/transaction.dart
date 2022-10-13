
import 'package:linksys_moab/network/mqtt/command_spec/impl/jnap_spec.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/network/mqtt/model/command/mqtt_base_command.dart';

class JNAPTransaction extends BaseMqttCommand<JnapResponse> {
  JNAPTransaction({
    required publishTopic,
    required responseTopic,
    required List<Map<String, dynamic>> payload,
    String? auth,
  })  : _publishTopic = publishTopic,
        _responseTopic = responseTopic,
        super(
          spec: JNAPTransactionSpec(
            payload: payload,
            auth: auth,
          )) {
    responseTimeout = const Duration(seconds: 60);
  }



  final String _publishTopic;
  final String _responseTopic;

  @override
  String get responseTopic => _responseTopic;

  @override
  String get publishTopic => _publishTopic;
}