import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/page/dashboard/view/topology/topology_model.dart';
import 'package:linksys_app/provider/devices/topology_state.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_widgets/widgets/topology/tree_node.dart';

final topologySelectedIdProvider = StateProvider((ref) => '');
final topologyProvider = NotifierProvider<TopologyNotifier, TopologyState>(
  () => TopologyNotifier(),
);

class TopologyNotifier extends Notifier<TopologyState> {
  @override
  TopologyState build() {
    final deviceManagerState = ref.watch(deviceManagerProvider);
    final topologySelectId = ref.watch(topologySelectedIdProvider);
    return TopologyState(
        onlineRoot: _buildRootNode(deviceManagerState, topologySelectId),
        offlineRoot: _buildOfflineRootNode(deviceManagerState));
  }

  void setSelectedDeviceId(String deviceId) {
    state = state.copyWith(
      selectedDeviceId: deviceId,
    );
  }

  RouterTreeNode _buildRootNode(
      DeviceManagerState deviceManagerState, String selectId) {
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
        children: [_buildRouterTopology(deviceManagerState, selectId)]);
  }

  RouterTreeNode _buildOfflineRootNode(DeviceManagerState deviceManagerState) {
    return RouterTreeNode(
        type: AppTreeNodeType.offline,
        data: const TopologyModel(isOnline: true, location: 'Offline'),
        children: [..._buildOfflineRouterTopology(deviceManagerState)]);
  }

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

  RouterTreeNode _buildRouterTopology(
      DeviceManagerState deviceManagerState, String selectId) {
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
          if (device.deviceID == selectId) {
            final deviceNode =
                _createTopologyNode(device, type: AppTreeNodeType.device);
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
                parentNode.children.add(deviceNode..parent = parentNode);
              } else {
                // Error! parentDeviceID should always be valid if it exists
                masterNode.children.add(deviceNode..parent = parentNode);
              }
            } else {
              // No parent
              // Add this item into master's children list
              masterNode.children.add(deviceNode..parent = masterNode);
            }
          }
        }
      }
    }
    return masterNode;
  }

  RouterTreeNode _createTopologyNode(
    LinksysDevice device, {
    AppTreeNodeType type = AppTreeNodeType.node,
  }) {
    String deviceId = device.deviceID;
    String location = device.getDeviceLocation();
    bool isMaster = device.isAuthority || device.nodeType == 'Master';
    bool isOnline = device.connections.isNotEmpty;
    bool isRouter = device.isAuthority || device.nodeType != null;
    bool isWiredConnection = device.isWiredConnection();
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
    return RouterTreeNode(data: data, children: [], type: type);
  }

  Future reboot() {
    final routerRepository = ref.read(routerRepositoryProvider);
    return routerRepository.send(
      JNAPAction.reboot,
      cacheLevel: CacheLevel.noCache,
    );
  }
}
