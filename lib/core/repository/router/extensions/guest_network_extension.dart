import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/guest_radio_settings.dart';
import 'package:linksys_app/core/jnap/jnap_command_queue.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

extension GuestNetworkService on RouterRepository {
  Future<JNAPSuccess> getGuestNetworkClients() async {
    final command = await createCommand(
        JNAPAction.getGuestNetworkClients.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getGuestNetworkSettings() async {
    final command = await createCommand(
        JNAPAction.getGuestNetworkSettings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> getGuestRadioSettings() async {
    final command = await createCommand(
        JNAPAction.getGuestRadioSettings.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> setGuestRadioSettings(
      bool enable, List<GuestRadioInfo> radios) async {
    final command = await createCommand(
        JNAPAction.setGuestRadioSettings.actionValue,
        needAuth: true,
        data: {
          'isGuestNetworkEnabled': enable,
          'radios': radios.map((e) => e.toJson()).toList(),
        });

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
