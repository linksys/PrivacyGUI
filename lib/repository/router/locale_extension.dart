import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension LocaleService on RouterRepository {
  Future<JnapSuccess> getLocalTime() async {
    final command = createCommand(JNAPAction.getLocalTime.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getTimeSettings() async {
    final command = createCommand(JNAPAction.getTimeSettings.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getLocale() async {
    final command = createCommand(JNAPAction.getLocale.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> setLocale(String locale) async {
    final command = createCommand(JNAPAction.setLocale.actionValue, data: {
      'locale': locale,
    });

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> setTimeSettings(
      String timezoneId, bool autoAdjustForDST) async {
    final command =
        createCommand(JNAPAction.setTimeSettings.actionValue, data: {
      'timeZoneID': timezoneId,
      'autoAdjustForDST': autoAdjustForDST,
    });

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
