import 'package:linksys_moab/model/router/guest_radio_settings.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension GuestNetworkService on RouterRepository {
  Future<JnapSuccess> getGuestNetworkClients() async {
    final command =
        createCommand(JNAPAction.getGuestNetworkClients.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getGuestNetworkSettings() async {
    final command =
        createCommand(JNAPAction.getGuestNetworkSettings.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getGuestRadioSettings() async {
    final command =
    createCommand(JNAPAction.getGuestRadioSettings.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> setGuestRadioSettings(bool enable, List<GuestRadioInfo> radios) async {
    final command =
    createCommand(JNAPAction.setGuestRadioSettings.actionValue, data: {
      'isGuestNetworkEnabled': enable,
      'radios': radios.map((e) => e.toJson()).toList(),
    });

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
