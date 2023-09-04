import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/page/dashboard/view/topology/topology_model.dart';
import 'package:linksys_app/provider/devices/topology_state.dart';

final topologyProvider = NotifierProvider<TopologyNotifier, TopologyState>(
  () => TopologyNotifier(),
);

class TopologyNotifier extends Notifier<TopologyState> {
  @override
  TopologyState build() {
    final deviceManagerState = ref.watch(deviceManagerProvider);
    return TopologyState(root: _buildRootNode(deviceManagerState));
  }

  void setSelectedDeviceId(String deviceId) {
    state = state.copyWith(
      selectedDeviceId: deviceId,
    );
  }

  RouterTreeNode _buildRootNode(DeviceManagerState deviceManagerState) {
    // if (deviceManagerState.isEmptyState()) {
    //   return TopologyNode();
    // }
    // final deviceId = null; //state.selectedDeviceId; //TODO: XXXXXX Check this
    // return deviceId != null
    //     ? _buildDeviceChain(deviceId, deviceManagerState)
    //     : _buildRouterTopology(deviceManagerState);
    return RouterTreeNode(
        data: TopologyModel(),
        children: [_buildRouterTopology(deviceManagerState)]);
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

  RouterTreeNode _buildRouterTopology(DeviceManagerState deviceManagerState) {
    final deviceList = deviceManagerState.deviceList;
    final locationMap = deviceManagerState.locationMap;

    final routerDevices = deviceList.where((device) {
      return device.isAuthority || device.nodeType != null;
    });
    final routerMap = <String, RouterTreeNode>{}; // {DeviceId : NodeObject}
    for (final device in routerDevices) {
      routerMap[device.deviceID] = _createTopologyNode(device, locationMap);
    }

    // Master node is always at the first
    final masterNode = routerMap[deviceList.first.deviceID]!;
    for (final device in deviceList) {
      // Master node will not be a child of any others
      if (device.deviceID != masterNode.data.deviceId) {
        // Check if this item is a router device or an external device
        final router = routerMap[device.deviceID];
        if (router != null) {
          // A child device
          // Check if there is a parent
          final parentId = device.connections.firstOrNull?.parentDeviceID;
          if (parentId != null) {
            // Parent exists
            final parentNode = routerMap[parentId];
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
          // Ensure it is online now
          if (device.connections.isNotEmpty) {
            // Check if there is a parent
            final parentId = device.connections.firstOrNull?.parentDeviceID;
            if (parentId != null) {
              // Parent exists
              final parentNode = routerMap[parentId];
              if (parentNode != null) {
                // Increase its parent's connected device count
                parentNode.data.connectedDeviceCount++;
              } else {
                // Error! parentDeviceID should always be valid if it exists
                masterNode.data.connectedDeviceCount++;
              }
            } else {
              // No parent
              // Count this device under the master's connected device
              masterNode.data.connectedDeviceCount++;
            }
          }
        }
      }
    }
    return masterNode;
  }

  RouterTreeNode _createTopologyNode(
    RouterDevice device,
    Map<String, String> locationMap,
  ) {
    String deviceId = device.deviceID;
    String location = locationMap[deviceId] ?? '';
    bool isMaster = device.isAuthority || device.nodeType == 'Master';
    bool isOnline = device.connections.isNotEmpty;
    bool isRouter = device.isAuthority || device.nodeType != null;
    bool isWiredConnection =
        ref.read(deviceManagerProvider.notifier).checkWiredConnection(device);
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
      icon: iconTest(device.toJson()),
      // The following will be derived later
      connectedDeviceCount: 0,
    );
    return RouterTreeNode(data: data, children: []);
  }
}
