import 'package:linksys_moab/model/router/wan_settings.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension RouterService on RouterRepository {
  Future<JNAPSuccess> getDHCPClientLeases() async {
    final command = createCommand(JNAPAction.getDHCPClientLeases.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getIPv6Settings() async {
    final command = createCommand(JNAPAction.getIPv6Settings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getLANSettings() async {
    final command = createCommand(JNAPAction.getLANSettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getMACAddressCloneSettings() async {
    final command =
        createCommand(JNAPAction.getMACAddressCloneSettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getWANSettings() async {
    final command = createCommand(JNAPAction.getWANSettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setWANSettings(RouterWANSettings newWANSettings) async {
    final command = createCommand(JNAPAction.setWANSettings.actionValue, needAuth: true,
        data: newWANSettings.toJson());

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getWANStatus() async {
    final command = createCommand(JNAPAction.getWANStatus.actionValue);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getWANDetectionStatus() async {
    final command = createCommand(JNAPAction.getWANDetectionStatus.actionValue,
        needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
  Future<JNAPSuccess> renewDHCPWANLease() async {
    final command = createCommand(JNAPAction.renewDHCPWANLease.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
  Future<JNAPSuccess> renewDHCPIPv6WANLease() async {
    final command = createCommand(JNAPAction.renewDHCPIPv6WANLease.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setMACAddressCloneSettings() async {
    final command =
    createCommand(JNAPAction.setMACAddressCloneSettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
