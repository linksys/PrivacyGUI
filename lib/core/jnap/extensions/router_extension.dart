import 'package:linksys_app/core/jnap/models/wan_settings.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/jnap_command_queue.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

extension RouterService on RouterRepository {
  Future<JNAPSuccess> getDHCPClientLeases() async {
    final command = await createCommand(
        JNAPAction.getDHCPClientLeases.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getIPv6Settings() async {
    final command = await createCommand(JNAPAction.getIPv6Settings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getLANSettings() async {
    final command = await createCommand(JNAPAction.getLANSettings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getMACAddressCloneSettings() async {
    final command = await createCommand(
        JNAPAction.getMACAddressCloneSettings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getWANSettings() async {
    final command = await createCommand(JNAPAction.getWANSettings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> setWANSettings(RouterWANSettings newWANSettings) async {
    final command = await createCommand(JNAPAction.setWANSettings.actionValue,
        needAuth: true, data: newWANSettings.toJson());

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getWANStatus() async {
    final command = await createCommand(JNAPAction.getWANStatus.actionValue);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getWANDetectionStatus() async {
    final command = await createCommand(
        JNAPAction.getWANDetectionStatus.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> renewDHCPWANLease() async {
    final command = await createCommand(
        JNAPAction.renewDHCPWANLease.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> renewDHCPIPv6WANLease() async {
    final command = await createCommand(
        JNAPAction.renewDHCPIPv6WANLease.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> setMACAddressCloneSettings() async {
    final command = await createCommand(
        JNAPAction.setMACAddressCloneSettings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
