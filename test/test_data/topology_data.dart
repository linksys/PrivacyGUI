import 'package:linksys_app/page/dashboard/view/topology/topology_model.dart';
import 'package:linksys_app/provider/devices/topology_state.dart';
import 'package:linksys_widgets/widgets/topology/tree_node.dart';

final _onlineRoot = RouterTreeNode(
  type: AppTreeNodeType.internet,
  data: const TopologyModel(isOnline: true, location: 'Internet'),
  children: [],
);

final _masterNode = RouterTreeNode(
  type: AppTreeNodeType.node,
  data: const TopologyModel(
    deviceId: 'ROUTER-MASTER-DEVICEID-000001',
    location: 'Living room',
    isMaster: true,
    isOnline: true,
    isWiredConnection: true,
    signalStrength: 0,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 30,
  ),
  children: [],
);

final _slaveNode1 = RouterTreeNode(
  type: AppTreeNodeType.node,
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000001',
    location: 'Kitchen',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: 0,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 20,
  ),
  children: [],
);

final _slaveNode2 = RouterTreeNode(
  type: AppTreeNodeType.node,
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000002',
    location: 'Basement',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: 0,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 17,
  ),
  children: [],
);

final _slaveNode3 = RouterTreeNode(
  type: AppTreeNodeType.node,
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000003',
    location: 'Bed room 1',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: 0,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 7,
  ),
  children: [],
);

final _slaveNode4 = RouterTreeNode(
  type: AppTreeNodeType.node,
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000004',
    location: 'Bed room 2',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: 0,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 1,
  ),
  children: [],
);

final _slaveNode5 = RouterTreeNode(
  type: AppTreeNodeType.node,
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000005',
    location: 'Bed room 3',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: 0,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 11,
  ),
  children: [],
);

/// State

final testTopologyState1 = TopologyState(
  onlineRoot: _onlineRoot
    ..children.add(
      _masterNode
        ..parent = _onlineRoot
        ..children.add(_slaveNode1..parent = _masterNode),
    ),
  offlineRoot: RouterTreeNode(
      type: AppTreeNodeType.offline,
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: []),
);

final testTopologyState2 = TopologyState(
  onlineRoot: _onlineRoot
    ..children.add(
      _masterNode
        ..parent = _onlineRoot
        ..children.add(_slaveNode1..parent = _masterNode)
        ..children.add(_slaveNode2..parent = _masterNode),
    ),
  offlineRoot: RouterTreeNode(
      type: AppTreeNodeType.offline,
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: []),
);
