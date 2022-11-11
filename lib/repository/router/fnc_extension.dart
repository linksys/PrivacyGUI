import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension BluetoothService on RouterRepository {
  Future<JnapSuccess> requestFOSContainer(
      String uri, String method, String? data) async {
    final command = createCommand(JNAPAction.requestFOSContainer.actionValue,
        data: {
          'uri': uri,
          'method': method,
          'data': data,
        }..removeWhere((key, value) => value == null));

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getRequestFOSContainer(
      String uri, {String? data}) async {
    return requestFOSContainer(uri, "GET", data);
  }

  Future<JnapSuccess> postRequestFOSContainer(
      String uri, {String? data}) async {
    return requestFOSContainer(uri, "POST", data);
  }
}
