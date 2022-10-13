import 'package:equatable/equatable.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/network/mqtt/command_spec/impl/jnap_spec.dart';
import 'package:linksys_moab/network/mqtt/model/command/mqtt_base_command.dart';

class JnapCommand extends BaseMqttCommand<JnapResponse> {
  JnapCommand({
    required publishTopic,
    required responseTopic,
    required String action,
    String? auth,
    required Map<String, dynamic> data,
  })  : _publishTopic = publishTopic,
        _responseTopic = responseTopic,
        super(
            spec: BasicJnapSpec(
          action: action,
          auth: auth,
          data: data,
        ));

  factory JnapCommand.local({
    required String action,
    String? auth,
    Map<String, dynamic> data = const {},
  }) {
    return JnapCommand(
      action: action,
      auth: auth,
      data: data,
      publishTopic: mqttLocalPublishTopic,
      responseTopic: mqttLocalResponseTopic,
    );
  }

  factory JnapCommand.remote({
    required String gid,
    required String nid,
    required String action,
    Map<String, dynamic> data = const {},
  }) {
    return JnapCommand(
      action: action,
      data: data,
      publishTopic: mqttRemotePublishTopic
          .replaceFirst(varMqttGroupId, gid)
          .replaceFirst(varMqttNetworkId, nid),
      responseTopic: mqttRemoteResponseTopic
          .replaceFirst(varMqttGroupId, gid)
          .replaceFirst(varMqttNetworkId, nid),
    );
  }

  final String _publishTopic;
  final String _responseTopic;

  @override
  String get responseTopic => _responseTopic;

  @override
  String get publishTopic => _publishTopic;
}

class JnapResponse extends Equatable {
  const JnapResponse({
    required this.header,
    required this.body,
  });

  factory JnapResponse.fromJson(Map<String, dynamic> json) {
    return JnapResponse(
      header: JnapHeader.fromJson(json[keyMqttHeader]),
      body: JnapResult.fromJson(json[keyMqttBody]),
    );
  }

  final JnapHeader header;
  final JnapResult body;

  Map<String, dynamic> toJson() {
    return {
      keyMqttHeader: header.toJson(),
      keyMqttBody: header.toJson(),
    };
  }

  @override
  List<Object?> get props => [header, body];
}

class JnapHeader extends Equatable {
  const JnapHeader({
    required this.action,
    required this.id,
  });

  factory JnapHeader.fromJson(Map<String, dynamic> json) {
    return JnapHeader(
      action: json[keyMqttHeaderAction],
      id: json[keyMqttHeaderId],
    );
  }

  final String action;
  final String id;

  Map<String, dynamic> toJson() {
    return {
      keyMqttHeaderAction: action,
      keyMqttHeaderId: id,
    };
  }

  @override
  List<Object?> get props => [action, id];
}

abstract class JnapResult extends Equatable {
  const JnapResult({required this.result});

  final String result;

  Map<String, dynamic> toJson() {
    return {
      keyJnapResult: result,
    };
  }

  factory JnapResult.fromJson(Map<String, dynamic> json) {
    if (json[keyJnapResult] == jnapResultOk) {
      return JnapSuccess.fromJson(json);
    } else {
      return JnapError.fromJson(json);
    }
  }

  @override
  List<Object?> get props => [result];
}

class JnapSuccess extends JnapResult {
  const JnapSuccess({
    required super.result,
    this.output = const {},
  });

  factory JnapSuccess.fromJson(Map<String, dynamic> json) {
    return json.containsKey(keyJnapResponses)
        ? JNAPTransactionSuccess.fromJson(json)
        : JnapSuccess(
            result: json[keyJnapResult],
            output: json[keyJnapOutput] ?? {},
          );
  }

  final Map<String, dynamic> output;

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll({
        keyJnapOutput: output,
      });
  }

  @override
  List<Object?> get props => super.props..add(output);
}

class JNAPTransactionSuccess extends JnapSuccess {
  const JNAPTransactionSuccess(
      {required super.result, required this.responses,});

  factory JNAPTransactionSuccess.fromJson(Map<String, dynamic> json) {
    return JNAPTransactionSuccess(
      result: json[keyJnapResult],
      responses: List.from(json[keyJnapResponses]).map((e) => JnapResult.fromJson(e)).toList(),
    );
  }

  final List<JnapResult> responses;

  @override
  Map<String, dynamic> toJson() {
    return {
      keyJnapResult: result,
      keyJnapResponses: output,
    };
  }
}

// TODO check Authenticate error
class JnapError extends JnapResult {
  const JnapError({
    required super.result,
    this.error,
  });

  factory JnapError.fromJson(Map<String, dynamic> json) {
    return JnapError(
      result: json[keyJnapResult],
      error: json[keyJnapError],
    );
  }

  final String? error;

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll({
        keyJnapError: error,
      });
  }

  @override
  List<Object?> get props => super.props..add(error);
}
