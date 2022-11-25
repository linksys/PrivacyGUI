import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension WirelessApService on RouterRepository {
  Future<JNAPSuccess> getRadioInfo() async {
    final command = createCommand(JNAPAction.getRadioInfo.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getWPSServerSessionStatus() async {
    final command =
        createCommand(JNAPAction.getWPSServerSessionStatus.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setRadioSettings(
      List<NewRadioSettings> radioSettings) async {
    final command = createCommand(JNAPAction.setRadioSettings.actionValue, needAuth: true,
        data: {'radios': radioSettings.map((e) => e.toJson()).toList()});

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
