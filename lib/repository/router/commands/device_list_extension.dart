import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension DeviceListService on RouterRepository {
  Future<JNAPSuccess> getDevices() async {
    final command = createCommand(JNAPAction.getDevices.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  // Doesn't work ???
  Future<JNAPSuccess> getLocalDevice() async {
    final command = createCommand(JNAPAction.getLocalDevice.actionValue, needAuth: true);

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> setDeviceProperties(
      {required String deviceId,
      List<Map<String, String>> propertiesToModify = const [],
      List<String> propertiesToRemove = const []}) async {
    final command =
        createCommand(JNAPAction.setDeviceProperties.actionValue, needAuth: true, data: {
      'deviceID': deviceId,
      'propertiesToModify': propertiesToModify,
      'propertiesToRemove': propertiesToRemove,
    });

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }
}
