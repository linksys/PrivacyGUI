import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/page/dashboard/view/topology/topology_model.dart';
import 'package:linksys_app/provider/devices/topology_state.dart';
import 'package:linksys_widgets/widgets/topology/tree_node.dart';

final topologyProvider = NotifierProvider<TopologyNotifier, TopologyState>(
  () => TopologyNotifier(),
);

class TopologyNotifier extends Notifier<TopologyState> {
  @override
  TopologyState build() {
    final deviceManagerState = ref.watch(deviceManagerProvider);
    return TopologyState(
        onlineRoot: _buildRootNode(deviceManagerState),
        offlineRoot: _buildOfflineRootNode(deviceManagerState));
  }

  void setSelectedDeviceId(String deviceId) {
    state = state.copyWith(
      selectedDeviceId: deviceId,
    );
  }

  RouterTreeNode _buildRootNode(DeviceManagerState deviceManagerState) {
    // if (ref.read(deviceManagerProvider.notifier).isEmptyState()) {
    //   return TopologyNode();
    // }
    // final deviceId = null; //state.selectedDeviceId;
    // return deviceId != null
    //     ? _buildDeviceChain(deviceId, deviceManagerState)
    //     : _buildRouterTopology(deviceManagerState);
    return RouterTreeNode(
        type: AppTreeNodeType.internet,
        data: const TopologyModel(isOnline: true, location: 'Internet'),
        children: [_buildRouterTopology(deviceManagerState)]);
  }

  RouterTreeNode _buildOfflineRootNode(DeviceManagerState deviceManagerState) {
    // if (ref.read(deviceManagerProvider.notifier).isEmptyState()) {
    //   return TopologyNode();
    // }
    // final deviceId = null; //state.selectedDeviceId;
    // return deviceId != null
    //     ? _buildDeviceChain(deviceId, deviceManagerState)
    //     : _buildRouterTopology(deviceManagerState);
    return RouterTreeNode(
        type: AppTreeNodeType.offline,
        data: const TopologyModel(isOnline: true, location: 'Offline'),
        children: [..._buildOfflineRouterTopology(deviceManagerState)]);
  }
  // TopologyNode _buildDeviceChain(
  //   String selectedDeviceId,
  //   DeviceManagerState deviceManagerState,
  // ) {
  //   return _visitChain(null, selectedDeviceId, deviceManagerState);
  // }

  // TopologyNode _visitChain(
  //   TopologyNode? child,
  //   String selectedDeviceId,
  //   DeviceManagerState deviceManagerState,
  // ) {
  //   final deviceList = deviceManagerState.deviceList;
  //   final locationMap = deviceManagerState.locationMap;

  //   final target = deviceList.firstWhereOrNull((device) {
  //     return device.deviceID == selectedDeviceId;
  //   });
  //   if (target == null) {
  //     throw Exception('No found selected device!');
  //   }
  //   // Create a topology node for the target device
  //   final targetNode = _createTopologyNode(target, locationMap);
  //   if (child != null) {
  //     // Add the given child into the children list
  //     targetNode.children.add(child);
  //   }
  //   // Master node is always at the first
  //   final masterId = deviceList.first.deviceID;
  //   final parentId = target.connections.firstOrNull?.parentDeviceID ??
  //       (targetNode.isMaster ? '' : masterId);
  //   if (parentId.isNotEmpty) {
  //     // Parent exists
  //     return _visitChain(targetNode, parentId, deviceManagerState);
  //   } else {
  //     // It's master
  //     return targetNode;
  //   }
  // }

  List<RouterTreeNode> _buildOfflineRouterTopology(
      DeviceManagerState deviceManagerState) {
    return [
      ...deviceManagerState.nodeDevices
          .where((device) => device.connections.isEmpty)
          .map(
            (device) => _createTopologyNode(device),
          )
          .toList(),
    ];
  }

  RouterTreeNode _buildRouterTopology(DeviceManagerState deviceManagerState) {
    // {DeviceId : NodeObject}
    final nodeMap = Map.fromEntries(
      deviceManagerState.nodeDevices
          .where((device) => device.connections.isNotEmpty)
          .map(
            (device) => MapEntry(device.deviceID, _createTopologyNode(device)),
          ),
    );
    final deviceList = deviceManagerState.deviceList;
    // Master node is always at the first
    final masterNode = nodeMap[deviceList.first.deviceID]!;

    for (final device in deviceList) {
      // Master node will not be a child of any others
      if (device.deviceID != masterNode.data.deviceId) {
        // Check if this item is a router device or an external device
        final router = nodeMap[device.deviceID];
        if (router != null) {
          // A child device
          // Check if there is a parent
          final parentId = ref
              .read(deviceManagerProvider.notifier)
              .findParent(device.deviceID)
              ?.deviceID;
          if (parentId != null) {
            // Parent exists
            final parentNode = nodeMap[parentId];
            if (parentNode != null) {
              // Add this item into parent's children list
              parentNode.children.add(router..parent = parentNode);
            } else {
              // Error! parentDeviceID should always be valid if it exists
              masterNode.children.add(router..parent = parentNode);
            }
          } else {
            // No parent
            // Add this item into master's children list
            masterNode.children.add(router..parent = masterNode);
          }
        } else {
          // An external device
        }
      }
    }
    return masterNode;
  }

  RouterTreeNode _createTopologyNode(
    LinksysDevice device,
  ) {
    String deviceId = device.deviceID;
    String location = device.getDeviceLocation();
    bool isMaster = device.isAuthority || device.nodeType == 'Master';
    bool isOnline = device.connections.isNotEmpty;
    bool isRouter = device.isAuthority || device.nodeType != null;
    bool isWiredConnection =
        ref.read(deviceManagerProvider.notifier).checkIsWiredConnection(device);
    int signalStrength =
        ref.read(deviceManagerProvider.notifier).getWirelessSignal(device);
    final data = TopologyModel(
      deviceId: deviceId,
      location: location,
      isMaster: isMaster,
      isOnline: isOnline,
      isWiredConnection: isWiredConnection,
      signalStrength: signalStrength,
      isRouter: isRouter,
      icon: iconTest(device.toMap()),
      connectedDeviceCount: device.connectedDevices.length,
    );
    return RouterTreeNode(data: data, children: []);
  }
}
