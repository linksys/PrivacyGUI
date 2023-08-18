import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/jnap_command_queue.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

extension LocaleService on RouterRepository {
  Future<JNAPSuccess> getLocalTime() async {
    final command = await createCommand(JNAPAction.getLocalTime.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getTimeSettings() async {
    final command = await createCommand(JNAPAction.getTimeSettings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getLocale() async {
    final command =
        await createCommand(JNAPAction.getLocale.actionValue, needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> setLocale(String locale) async {
    final command = await createCommand(JNAPAction.setLocale.actionValue,
        needAuth: true,
        data: {
          'locale': locale,
        });

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> setTimeSettings(
      String timezoneId, bool autoAdjustForDST) async {
    final command = await createCommand(JNAPAction.setTimeSettings.actionValue,
        needAuth: true,
        data: {
          'timeZoneID': timezoneId,
          'autoAdjustForDST': autoAdjustForDST,
        });

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
