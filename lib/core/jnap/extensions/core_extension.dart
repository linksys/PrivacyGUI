import 'dart:convert';

import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/core/jnap/actions/better_action.dart';
import 'package:linksys_moab/core/jnap/command/http_base_command.dart';
import 'package:linksys_moab/core/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/core/jnap/result/jnap_result.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';

extension CoreService on RouterRepository {
  Future<JNAPSuccess> checkAdminPassword(String password) async {
    final command = await createCommand(
      JNAPAction.checkAdminPassword.actionValue,
      data: {
        'adminPassword': password,
      },
    );
    if (command is JNAPHttpCommand) {
      command.spec.extraHeader['X-JNAP-Authorization'] =
          'Basic ${base64Encode('admin:$password'.codeUnits)}';
    }
    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> createAdminPassword(String password, String hint) async {
    final command =
        await createCommand(JNAPAction.coreSetAdminPassword.actionValue, data: {
      'adminPassword': password,
      'passwordHint': hint,
    });
    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getAdminPasswordAuthStatus() async {
    final command =
        await createCommand(JNAPAction.getAdminPasswordAuthStatus.actionValue);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getAdminPasswordHint() async {
    final command =
        await createCommand(JNAPAction.getAdminPasswordHint.actionValue);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getDataUploadUserConsent() async {
    final command = await createCommand(
        JNAPAction.getDataUploadUserConsent.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getDeviceInfo() async {
    final command = await createCommand(JNAPAction.getDeviceInfo.actionValue,
        needAuth: true);

    // final result = await command.publish();
    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> isAdminPasswordDefault() async {
    final command =
        await createCommand(JNAPAction.isAdminPasswordDefault.actionValue);

    // final result = await command.publish();
    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> isServiceSupported(JNAPService service) async {
    final command = await createCommand(
        JNAPAction.isServiceSupported.actionValue,
        data: {'serviceName': service.value.replaceAll(kJNAPActionBase, '')});

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> reboot() async {
    final command =
        await createCommand(JNAPAction.reboot.actionValue, needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getUnsecuredWiFiWarning() async {
    final command = await createCommand(
      JNAPAction.getUnsecuredWiFiWarning.actionValue,
    );

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> setUnsecuredWiFiWarning(bool enabled) async {
    final command = await createCommand(
        JNAPAction.setUnsecuredWiFiWarning.actionValue,
        data: {'enabled': enabled});

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
