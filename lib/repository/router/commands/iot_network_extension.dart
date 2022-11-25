import 'package:linksys_moab/model/router/guest_radio_settings.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';


extension IoTNetworkService on RouterRepository {
  @Deprecated('Moab')
  Future<JNAPSuccess> getIoTNetworkSettings() async {
    final command =
    createCommand(JNAPAction.getIoTNetworkSettings.actionValue);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  @Deprecated('Moab')
  Future<JNAPSuccess> setIoTNetworkSettings(bool enable) async {
    final command =
    createCommand(JNAPAction.setIoTNetworkSettings.actionValue, data: {
      'isIoTNetworkEnabled': enable,
    });

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}