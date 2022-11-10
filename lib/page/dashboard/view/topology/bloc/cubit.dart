import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/page/dashboard/view/topology/bloc/state.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_node.dart';
import 'package:linksys_moab/repository/router/device_list_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/utils.dart';

class TopologyCubit extends Cubit<TopologyState> {
  TopologyCubit(RouterRepository repository)
      : _repository = repository,
        super(TopologyState(rootNode: TopologyNode()));

  final RouterRepository _repository;

  Future fetchTopologyData() async {
    // TODO: In order to get signal strength, more requests needed
    final results = await _repository.getDevices();
    final getDevicesOutput = results.output;
    var devices = List.from(getDevicesOutput['devices'])
        .map((e) => RouterDevice.fromJson(e))
        .toList();

    final masterDeviceID = devices.firstWhereOrNull((device) {
          return device.isAuthority || device.nodeType == 'Master';
        })?.deviceID ??
        '';

    final nodeDevices = devices
        .where((device) => device.isAuthority || device.nodeType != null);

    Map<String, TopologyNode> nodeMap = {}; // {DeviceID : NodeObject}

    for (final device in nodeDevices) {
      String deviceID = device.deviceID;
      String location = Utils.getDeviceLocation(device);
      bool isMaster = deviceID == masterDeviceID;
      bool isOnline = device.connections.isNotEmpty;
      bool isWiredConnection = Utils.checkIfWiredConnection(device);
      int signalStrength = 0; //TODO: Find a way to get node signal data

      nodeMap[deviceID] = TopologyNode(
        deviceID: deviceID,
        location: location,
        isMaster: isMaster,
        isOnline: isOnline,
        isWiredConnection: isWiredConnection,
        signalStrength: signalStrength,
        connectedDeviceCount: 0, // Will get this later
        children: [], // Will get this later
      );
    }

    final masterNode = nodeMap[masterDeviceID]!;

    for (final device in nodeDevices) {
      var node = nodeMap[device.deviceID]!;
      // Master will not be child of any node else
      if (!node.isMaster) {
        final parentDeviceID = device.connections.firstOrNull?.parentDeviceID;
        if (parentDeviceID != null) {
          var parentNode = nodeMap[parentDeviceID];
          if (parentNode != null) {
            parentNode.children.add(node);
          } else {
            // Should not be ture - parentDeviceID should always be valid if it exists
            masterNode.children.add(node);
          }
        } else {
          // If parentDeviceID doesn't exist, the current node will be the child of Master
          masterNode.children.add(node);
        }
      }
    }

    final externalDevices = devices
        .whereNot((device) => device.isAuthority || device.nodeType != null);

    for (final device in externalDevices) {
      // Make sure the external device is online
      if (device.connections.isNotEmpty) {
        final parentDeviceID = device.connections.firstOrNull?.parentDeviceID;
        if (parentDeviceID != null) {
          var parentNode = nodeMap[parentDeviceID];
          if (parentNode != null) {
            parentNode.connectedDeviceCount++;
          } else {
            // Should not be ture - parentDeviceID should always be valid if it exists
            masterNode.connectedDeviceCount++;
          }
        } else {
          // If parentDeviceID doesn't exist, the external device will be counted under the Master
          masterNode.connectedDeviceCount++;
        }
      }
    }

    emit(state.copyWith(rootNode: masterNode));
  }
}
