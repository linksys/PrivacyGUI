import 'package:linksys_moab/core/jnap/actions/better_action.dart';
import 'package:linksys_moab/core/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/core/jnap/result/jnap_result.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';

extension DeviceListService on RouterRepository {
  Future<JNAPSuccess> getDevices() async {
    final command =
        await createCommand(JNAPAction.getDevices.actionValue, needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  // Doesn't work ???
  Future<JNAPSuccess> getLocalDevice() async {
    final command = await createCommand(JNAPAction.getLocalDevice.actionValue,
        needAuth: true);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }

  Future<JNAPSuccess> setDeviceProperties(
      {required String deviceId,
      List<Map<String, String>> propertiesToModify = const [],
      List<String> propertiesToRemove = const []}) async {
    final command = await createCommand(
        JNAPAction.setDeviceProperties.actionValue,
        needAuth: true,
        data: {
          'deviceID': deviceId,
          'propertiesToModify': propertiesToModify,
          'propertiesToRemove': propertiesToRemove,
        });

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result) as JNAPSuccess;
  }
}
