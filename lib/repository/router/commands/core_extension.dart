import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

extension CoreService on RouterRepository {
  Future<JNAPSuccess> checkAdminPassword(String password) async {
    final command = createCommand(
      JNAPAction.checkAdminPassword.actionValue,
      data: {
        'adminPassword': password,
      },
    );
    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> createAdminPassword(String password, String hint) async {
    final command =
    createCommand(JNAPAction.coreSetAdminPassword.actionValue, data: {
      'adminPassword': 'admin',
      'passwordHint': hint,
    });
    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getAdminPasswordAuthStatus() async {
    final command =
    createCommand(JNAPAction.getAdminPasswordAuthStatus.actionValue);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getAdminPasswordHint() async {
    final command = createCommand(JNAPAction.getAdminPasswordHint.actionValue);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getDataUploadUserConsent() async {
    final command =
        createCommand(JNAPAction.getDataUploadUserConsent.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getDeviceInfo() async {
    final command = createCommand(JNAPAction.getDeviceInfo.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> isAdminPasswordDefault() async {
    final command =
    createCommand(JNAPAction.isAdminPasswordDefault.actionValue);

    try {
      final result = await command.publish(executor!);
      return handleJNAPResult(result);
    } catch (e) {
      logger.e('JNAP call error', e);
      rethrow;
    }
  }

  Future<JNAPSuccess> reboot() async {
    final command = createCommand(JNAPAction.reboot.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getUnsecuredWiFiWarning() async {
    final command = createCommand(JNAPAction.getUnsecuredWiFiWarning.actionValue,);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
  Future<JNAPSuccess> setUnsecuredWiFiWarning(bool enabled) async {
    final command = createCommand(JNAPAction.setUnsecuredWiFiWarning.actionValue, data: {'enabled': enabled});

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
