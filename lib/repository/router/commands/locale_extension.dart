import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension LocaleService on RouterRepository {
  Future<JNAPSuccess> getLocalTime() async {
    final command = createCommand(JNAPAction.getLocalTime.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getTimeSettings() async {
    final command = createCommand(JNAPAction.getTimeSettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getLocale() async {
    final command = createCommand(JNAPAction.getLocale.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setLocale(String locale) async {
    final command = createCommand(JNAPAction.setLocale.actionValue, needAuth: true, data: {
      'locale': locale,
    });

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setTimeSettings(
      String timezoneId, bool autoAdjustForDST) async {
    final command =
        createCommand(JNAPAction.setTimeSettings.actionValue, needAuth: true, data: {
      'timeZoneID': timezoneId,
      'autoAdjustForDST': autoAdjustForDST,
    });

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
