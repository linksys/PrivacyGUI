import 'package:linksys_moab/model/router/guest_radio_settings.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension GuestNetworkService on RouterRepository {
  Future<JNAPSuccess> getGuestNetworkClients() async {
    final command =
        createCommand(JNAPAction.getGuestNetworkClients.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getGuestNetworkSettings() async {
    final command =
        createCommand(JNAPAction.getGuestNetworkSettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getGuestRadioSettings() async {
    final command =
    createCommand(JNAPAction.getGuestRadioSettings.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setGuestRadioSettings(bool enable, List<GuestRadioInfo> radios) async {
    final command =
    createCommand(JNAPAction.setGuestRadioSettings.actionValue, needAuth: true, data: {
      'isGuestNetworkEnabled': enable,
      'radios': radios.map((e) => e.toJson()).toList(),
    });

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
