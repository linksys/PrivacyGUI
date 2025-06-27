import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

final topologySelectedIdProvider = StateProvider((ref) => '');
final instantTopologyProvider =
    NotifierProvider<InstantTopologyNotifier, InstantTopologyState>(
  () => InstantTopologyNotifier(),
);

class InstantTopologyNotifier extends Notifier<InstantTopologyState> {
  @override
  InstantTopologyState build() {
    final deviceManagerState = ref.watch(deviceManagerProvider);
    final topologySelectId = ref.watch(topologySelectedIdProvider);
    final count = deviceManagerState.nodeDevices.length;

    final onlineRoot = _buildRootNode(deviceManagerState, topologySelectId);
    final offlineRoot = _buildOfflineRootNode(deviceManagerState);
    // final onlineRoot = testTopologyStateOffline4.onlineRoot;
    // final offlineRoot = testTopologyStateOffline4.offlineRoot;
    // final treeRoot;
    if (onlineRoot.children.isNotEmpty) {
      onlineRoot.children.first.children.addAll(offlineRoot.children);
    }
    final state = InstantTopologyState(
      root: onlineRoot,
    );
    logger.d(
        'topology flat list: ${state.root.toFlatList().map((e) => e.data.toJson())}');
    return state;
  }

  RouterTreeNode _buildRootNode(
      DeviceManagerState deviceManagerState, String selectId) {
    return OnlineTopologyNode(
        data: const TopologyModel(isOnline: true, location: 'Internet'),
        children: deviceManagerState.deviceList.isEmpty
            ? []
            : [_buildRouterTopology(deviceManagerState, selectId)]);
  }

  RouterTreeNode _buildOfflineRootNode(DeviceManagerState deviceManagerState) {
    return OfflineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: [..._buildOfflineRouterTopology(deviceManagerState)],
    );
  }

  List<RouterTreeNode> _buildOfflineRouterTopology(
      DeviceManagerState deviceManagerState) {
    return [
      ...deviceManagerState.nodeDevices
          .where((device) => !device.isOnline())
          .map(
            (device) => _createRouterTopologyNode(device)..tag = 'offline',
          )
          .toList(),
    ];
  }

  RouterTreeNode _buildRouterTopology(
      DeviceManagerState deviceManagerState, String selectId) {
    // {DeviceId : NodeObject}
    final nodeMap = Map.fromEntries(
      deviceManagerState.nodeDevices.where((device) => device.isOnline()).map(
            (device) =>
                MapEntry(device.deviceID, _createRouterTopologyNode(device)),
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
          final parentId = device.upstream?.deviceID;
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
            final deviceNode = _createDeviceTopologyNode(device);
            // Check if there is a parent
            final parentId = device.upstream?.deviceID;
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

  RouterTreeNode _createRouterTopologyNode(
    LinksysDevice device,
  ) {
    String deviceId = device.deviceID;
    String location = device.getDeviceLocation();
    bool isMaster = device.isAuthority || device.nodeType == 'Master';
    bool isOnline = device.isOnline();
    bool isRouter = device.isAuthority || device.nodeType != null;
    bool isWiredConnection =
        device.getConnectionType() == DeviceConnectionType.wired;
    String model = device.modelNumber ?? '';
    String serialNumber = device.unit.serialNumber ?? '';
    String fwVersion = device.unit.firmwareVersion ?? '';
    String ipAddress = device.connections.firstOrNull?.ipAddress ?? '';
    String hardwareVersion = device.model.hardwareVersion ?? '1';
    int? signalStrength = device.signalDecibels;
    String macAddress = device.getMacAddress();

    final updateInfo = (ref.read(firmwareUpdateProvider).nodesStatus?.length ??
                0) >
            1
        ? ref.watch(firmwareUpdateProvider.select((value) => value.nodesStatus
            ?.firstWhereOrNull((element) => element is NodesFirmwareUpdateStatus
                ? element.deviceUUID == deviceId
                : false)))
        : ref.watch(firmwareUpdateProvider
            .select((value) => value.nodesStatus?.firstOrNull));
    final isFwUpToDate = updateInfo?.availableUpdate == null;

    final data = TopologyModel(
      deviceId: deviceId,
      location: location,
      isMaster: isMaster,
      isOnline: isOnline,
      isWiredConnection: isWiredConnection,
      signalStrength: signalStrength ?? -1,
      isRouter: isRouter,
      icon: isRouter
          ? routerIconTest(device.toMap())
          : deviceIconTest(device.toMap()),
      connectedDeviceCount: device.connectedDevices.length,
      model: model,
      serialNumber: serialNumber,
      fwVersion: fwVersion,
      ipAddress: ipAddress,
      hardwareVersion: hardwareVersion,
      fwUpToDate: isFwUpToDate,
      macAddress: macAddress,
    );
    return RouterTopologyNode(
      data: data,
      children: [],
    );
  }

  RouterTreeNode _createDeviceTopologyNode(LinksysDevice device) {
    String deviceId = device.deviceID;
    String location = device.getDeviceLocation();
    bool isMaster = device.isAuthority || device.nodeType == 'Master';
    bool isOnline = device.isOnline();
    bool isRouter = device.isAuthority || device.nodeType != null;
    bool isWiredConnection =
        device.getConnectionType() == DeviceConnectionType.wired;
    int? signalStrength = device.signalDecibels;
    final data = TopologyModel(
      deviceId: deviceId,
      location: location,
      isMaster: isMaster,
      isOnline: isOnline,
      isWiredConnection: isWiredConnection,
      signalStrength: signalStrength ?? -1,
      isRouter: isRouter,
      icon: isRouter
          ? routerIconTest(device.toMap())
          : deviceIconTest(device.toMap()),
      connectedDeviceCount: device.connectedDevices.length,
    );
    return DeviceTopologyNode(data: data, children: []);
  }

  Future reboot([List<String> deviceUUIDs = const []]) {
    final routerRepository = ref.read(routerRepositoryProvider);
    final builder = JNAPTransactionBuilder(
        commands: deviceUUIDs.reversed
            .map((uuid) => MapEntry(JNAPAction.reboot2, {'deviceUUID': uuid}))
            .toList(),
        auth: true);
    if (deviceUUIDs.isEmpty) {
      return routerRepository.send(
        JNAPAction.reboot,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        auth: true,
      );
    } else {
      return routerRepository
          .transaction(
            builder,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )
          .then((_) => _waitForNodesOffline(deviceUUIDs));
    }
  }

  Future startBlinkNodeLED(String deviceId) async {
    final repository = ref.read(routerRepositoryProvider);
    return repository.send(
      JNAPAction.startBlinkNodeLed,
      data: {'deviceID': deviceId},
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      auth: true,
    );
  }

  Future stopBlinkNodeLED() async {
    final repository = ref.read(routerRepositoryProvider);
    return repository.send(
      JNAPAction.stopBlinkNodeLed,
      auth: true,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    );
  }

  Future<void> toggleBlinkNode(String deviceId, [bool stopOnly = false]) async {
    final prefs = await SharedPreferences.getInstance();
    final blinkDevice = prefs.get(pBlinkingNodeId);
    if (blinkDevice != null && deviceId != blinkDevice) {
      stopBlinkNodeLED();
    }
    startBlinkNodeLED(deviceId).then((_) {
      prefs.setString(pBlinkingNodeId, deviceId);
    });
  }

  Future<dynamic> factoryReset(List<String> deviceUUIDs) {
    final routerRepository = ref.read(routerRepositoryProvider);
    final builder = JNAPTransactionBuilder(
      // Start doing factory reset from the nodes of the bottom level
      commands: deviceUUIDs.reversed
          .map((uuid) =>
              MapEntry(JNAPAction.factoryReset2, {'deviceUUID': uuid}))
          .toList(),
      auth: true,
    );
    // If the target node is the master, the Id list will be empty
    if (deviceUUIDs.isEmpty) {
      return routerRepository.send(
        JNAPAction.factoryReset,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        auth: true,
      );
    } else {
      return routerRepository
          .transaction(
            builder,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )
          // After factory resetting a child node, we need to wait for them
          // being offline for subsequent Delete actions
          .then(
            (_) => _waitForNodesOffline(deviceUUIDs),
          );
    }
  }

  Future<void> _waitForNodesOffline(List<String> deviceUUIDs) async {
    final waitingStream = ref.read(routerRepositoryProvider).scheduledCommand(
          action: JNAPAction.getDevices,
          retryDelayInMilliSec: 3000,
          maxRetry: 20,
          condition: (result) {
            if (result is JNAPSuccess) {
              final deviceList = List.from(
                result.output['devices'],
              )
                  .map((e) => LinksysDevice.fromMap(e))
                  .where((device) => deviceUUIDs.contains(device.deviceID))
                  .toList();
              return !deviceList.any((device) => device.isOnline());
            }
            return false;
          },
          auth: true,
        );
    await for (final result in waitingStream) {
      logger.d('[Reboot/FactoryReset]: Waiting for all nodes offline');
      if (result is JNAPSuccess) {
        final deviceList = List.from(
          result.output['devices'],
        )
            .map((e) => LinksysDevice.fromMap(e))
            .where((device) => deviceUUIDs.contains(device.deviceID))
            .toList();
        for (final device in deviceList) {
          logger.d(
              '[Reboot/FactoryReset]: Waiting for - isDevice<${device.getDeviceLocation()}> Online - ${device.isOnline()}');
        }
      }
    }
  }
}
