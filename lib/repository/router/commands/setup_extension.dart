import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension SetupService on RouterRepository {

  Future<JNAPSuccess> isAdminPasswordSetByUser() async {
    final command =
        createCommand(JNAPAction.isAdminPasswordSetByUser.actionValue);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> resetAdminPassword(
      String resetCode, String password, String hint) async {
    final command =
        createCommand(JNAPAction.setupSetAdminPassword.actionValue, data: {
      'resetCode': resetCode,
      'adminPassword': password,
      'passwordHint': hint,
    });

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> verifyRouterResetCode(String resetCode) async {
    final command =
        createCommand(JNAPAction.verifyRouterResetCode.actionValue, data: {
      'resetCode': resetCode,
    });

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  ///
  /// Value -
  /// NoPortConnected -	There are no physical ethernet ports connected.
  /// NoWANConnection -	An ethernet port is connected, but no WAN connection was detected.
  /// NoInternetConnection -	A WAN connection was detected, but no internet connection.
  /// InternetConnected -	There is an active internet connection.
  ///
  Future<JNAPSuccess> getInternetConnectionStatus() async {
    final command =
    createCommand(JNAPAction.getInternetConnectionStatus.actionValue);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setSimpleWiFiSettings({required SimpleWiFiSettings settings}) async {
    final command =
    createCommand(JNAPAction.setSimpleWiFiSettings.actionValue, data: settings.toJson());

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
