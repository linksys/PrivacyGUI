import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/page/dashboard/view/topology/bloc/state.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_node.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/icons/icon_rules.dart';

class TopologyCubit extends Cubit<TopologyState> {
  TopologyCubit(RouterRepository repository)
      : _repository = repository,
        super(TopologyState(rootNode: TopologyNode()));

  final RouterRepository _repository;

  Future fetchTopologyData({String? selectedId}) async {
    final Map<String, Map<String, dynamic>> wirelessSignalMap = {};
    List<RouterDevice> devices = [];
    final results = await _repository.fetchDeviceList();
    if (results.containsKey(JNAPAction.getNetworkConnections.actionValue)) {
      final networkConnections =
          results[JNAPAction.getNetworkConnections.actionValue]!
              .output['connections'];
      for (final connection in networkConnections) {
        if (connection['wireless'] != null) {
          Map<String, dynamic> map = {
            'signalDecibels': connection['wireless']['signalDecibels'],
            'connection': connection['wireless']['band'],
          };
          wirelessSignalMap[connection['macAddress']] = map;
        }
      }
    }
    if (results.containsKey(JNAPAction.getDevices.actionValue)) {
      devices = List.from(
              results[JNAPAction.getDevices.actionValue]!.output['devices'])
          .map((e) => RouterDevice.fromJson(e))
          .toList();
    }
    emit(state.copyWith(
        rootNode: selectedId == null
            ? _buildRouterTopology(devices, wirelessSignalMap)
            : _buildDeviceChain(selectedId, devices, wirelessSignalMap)));
  }

  TopologyNode _buildRouterTopology(
    List<RouterDevice> devices,
    Map<String, Map<String, dynamic>> wirelessSignalMap,
  ) {
    final masterDeviceID = devices.firstWhereOrNull((device) {
          return device.isAuthority || device.nodeType == 'Master';
        })?.deviceID ??
        '';

    final nodeDevices = devices
        .where((device) => device.isAuthority || device.nodeType != null);

    Map<String, TopologyNode> nodeMap = {}; // {DeviceID : NodeObject}

    for (final device in nodeDevices) {
      final deviceConnection = device.connections.first;
      final macAddress = deviceConnection.macAddress;
      String deviceID = device.deviceID;
      nodeMap[deviceID] =
          _createTopologyNode(device, wirelessSignalMap[macAddress] ?? {});
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
    return masterNode;
  }

  TopologyNode _createTopologyNode(
    RouterDevice device,
    Map<String, dynamic> connectionData,
  ) {
    String deviceID = device.deviceID;
    String location = Utils.getDeviceLocation(device);
    bool isMaster = device.isAuthority || device.nodeType == 'Master';
    bool isOnline = device.connections.isNotEmpty;
    bool isWiredConnection = Utils.checkIfWiredConnection(device);
    int signalStrength = connectionData['signalDecibels'] ?? 0;

    bool isNode = device.isAuthority || device.nodeType != null;

    return TopologyNode(
      deviceID: deviceID,
      location: location,
      isMaster: isMaster,
      isOnline: isOnline,
      isRouter: isNode,
      isWiredConnection: isWiredConnection,
      signalStrength: signalStrength,
      connectedDeviceCount: 0,
      icon: isNode
          ? routerIconTest(
              modelNumber: device.model.modelNumber ?? '',
              hardwareVersion: device.model.hardwareVersion)
          : iconTest(device.toJson()),
      children: [], // Will get this later
    );
  }

  TopologyNode _visitTheChain(
    TopologyNode? child,
    String selectedDeviceId,
    List<RouterDevice> devices,
    Map<String, Map<String, dynamic>> wirelessSignalMap,
  ) {
    final device = devices
        .firstWhereOrNull((device) => device.deviceID == selectedDeviceId);
    if (device == null) {
      throw Exception('No found selected device!');
    }
    bool isMaster = device.isAuthority || device.nodeType == 'Master';
    final masterDeviceID = devices.firstWhereOrNull((device) {
          return device.isAuthority || device.nodeType == 'Master';
        })?.deviceID ??
        '';
    final deviceConnection = device.connections.first;
    final macAddress = deviceConnection.macAddress;
    final parentDeviceID =
        deviceConnection.parentDeviceID ?? (isMaster ? '' : masterDeviceID);
    logger.d(
        '<${Utils.getDeviceLocation(device)}> parent device id: $parentDeviceID');
    final node = _createTopologyNode(
      device,
      wirelessSignalMap[macAddress] ?? {},
    );
    if (child != null) {
      node.children.add(child);
    }
    if (parentDeviceID.isNotEmpty) {
      return _visitTheChain(node, parentDeviceID, devices, wirelessSignalMap);
    } else {
      return node;
    }
  }

  TopologyNode _buildDeviceChain(
    String selectedDeviceId,
    List<RouterDevice> devices,
    Map<String, Map<String, dynamic>> wirelessSignalMap,
  ) {
    return _visitTheChain(
      null,
      selectedDeviceId,
      devices,
      wirelessSignalMap,
    );
  }
}
