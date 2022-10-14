import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension DeviceListService on RouterRepository {
  Future<JnapSuccess> getDevices() async {
    final command = createCommand(JNAPAction.getDevices.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  // Doesn't work ???
  Future<JnapSuccess> getLocalDevice() async {
    final command = createCommand(JNAPAction.getLocalDevice.actionValue);

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> setDeviceProperties(
      {required String deviceId,
      List<Map<String, String>> propertiesToModify = const [],
      List<String> propertiesToRemove = const []}) async {
    final command =
        createCommand(JNAPAction.setDeviceProperties.actionValue, data: {
      'deviceID': deviceId,
      'propertiesToModify': propertiesToModify,
      'propertiesToRemove': propertiesToRemove,
    });

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }
}
