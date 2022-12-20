import 'dart:convert';

import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/command/http_base_command.dart';
import 'package:linksys_moab/network/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension CoreService on RouterRepository {
  Future<JNAPSuccess> checkAdminPassword(String password) async {
    final command = createCommand(
      JNAPAction.checkAdminPassword.actionValue,
      data: {
        'adminPassword': password,
      },
    );
    if (command is JNAPHttpCommand) {
      command.spec.extraHeader['X-JNAP-Authorization'] = 'Basic ${base64Encode('admin:$password'.codeUnits)}';
    }
    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> createAdminPassword(String password, String hint) async {
    final command =
        createCommand(JNAPAction.coreSetAdminPassword.actionValue, data: {
      'adminPassword': password,
      'passwordHint': hint,
    });
    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getAdminPasswordAuthStatus() async {
    final command =
        createCommand(JNAPAction.getAdminPasswordAuthStatus.actionValue);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getAdminPasswordHint() async {
    final command = createCommand(JNAPAction.getAdminPasswordHint.actionValue);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getDataUploadUserConsent() async {
    final command = createCommand(
        JNAPAction.getDataUploadUserConsent.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getDeviceInfo() async {
    final command =
        createCommand(JNAPAction.getDeviceInfo.actionValue, needAuth: true);

    // final result = await command.publish();
    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> isAdminPasswordDefault() async {
    final command =
        createCommand(JNAPAction.isAdminPasswordDefault.actionValue);

    // final result = await command.publish();
    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> isServiceSupported(JNAPService service) async {
    final command = createCommand(JNAPAction.isServiceSupported.actionValue,
        data: {'serviceName': service.value.replaceAll(kJNAPActionBase, '')});

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> reboot() async {
    final command =
        createCommand(JNAPAction.reboot.actionValue, needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getUnsecuredWiFiWarning() async {
    final command = createCommand(
      JNAPAction.getUnsecuredWiFiWarning.actionValue,
    );

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setUnsecuredWiFiWarning(bool enabled) async {
    final command = createCommand(
        JNAPAction.setUnsecuredWiFiWarning.actionValue,
        data: {'enabled': enabled});

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }
}
