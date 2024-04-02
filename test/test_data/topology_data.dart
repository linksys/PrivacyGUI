import 'package:linksys_app/page/topology/_topology.dart';

final _onlineRoot = OnlineTopologyNode(
  data: const TopologyModel(isOnline: true, location: 'Internet'),
  children: [],
);

final _masterNode = RouterTopologyNode(
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

final _slaveNode1 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000001',
    location: 'Kitchen',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -44,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 20,
  ),
  children: [],
);

final _slaveNode2 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000002',
    location: 'Basement',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -66,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 17,
  ),
  children: [],
);

final _slaveNode3 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000003',
    location: 'Bed room 1',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -58,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 7,
  ),
  children: [],
);

final _slaveNode4 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000004',
    location: 'Bed room 2',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -55,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 1,
  ),
  children: [],
);

final _slaveNode5 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000005',
    location: 'A super long long long long long long cool name',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -70,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 999,
  ),
  children: [],
);

final _slaveOfflineNode1 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000001',
    location: 'Kitchen',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -49,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 20,
  ),
  children: [],
);

final _slaveOfflineNode2 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000002',
    location: 'Basement',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -78,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 17,
  ),
  children: [],
);

final _slaveOfflineNode3 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000003',
    location: 'Bed room 1',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -55,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 7,
  ),
  children: [],
);

final _slaveOfflineNode4 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000004',
    location: 'Bed room 2',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -58,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 1,
  ),
  children: [],
);

final _slaveOfflineNode5 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000005',
    location: 'A super long long long long long long cool name',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -70,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 999,
  ),
  children: [],
);

/// State

final testTopologyState1 = TopologyState(
  nodesCount: 1,
  onlineRoot: _onlineRoot
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(_slaveNode1..parent = _masterNode),
    ),
  offlineRoot: OfflineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: []),
);

final testTopologyState2 = TopologyState(
  nodesCount: 1,
  onlineRoot: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode2
          ..children.clear()
          ..parent = _masterNode
      ])),
  offlineRoot: OfflineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: []),
);

final testTopologyState3 = TopologyState(
  nodesCount: 1,
  onlineRoot: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode
          ..children.addAll([
            _slaveNode2
              ..children.clear()
              ..parent = _slaveNode1
          ]),
      ])),
  offlineRoot: OfflineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: []),
);

final testTopologyState4 = TopologyState(
  nodesCount: 1,
  onlineRoot: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode2
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode3
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode4
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode5
          ..children.clear()
          ..parent = _masterNode,
      ])),
  offlineRoot: OfflineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: []),
);

final testTopologyState5 = TopologyState(
  nodesCount: 1,
  onlineRoot: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode
          ..children.addAll([
            _slaveNode2
              ..children.clear()
              ..parent = _slaveNode1
              ..children.addAll([
                _slaveNode3
                  ..children.clear()
                  ..parent = _slaveNode2
                  ..children.addAll([
                    _slaveNode4
                      ..children.clear()
                      ..parent = _slaveNode3
                      ..children.addAll([
                        _slaveNode5
                          ..children.clear()
                          ..parent = _slaveNode4,
                      ]),
                  ]),
              ]),
          ]),
      ])),
  offlineRoot: OfflineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: []),
);

final testTopologyState6 = TopologyState(
  nodesCount: 1,
  onlineRoot: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode
          ..children.addAll([
            _slaveNode2
              ..children.clear()
              ..parent = _slaveNode1,
            _slaveNode3
              ..children.clear()
              ..parent = _slaveNode1
              ..children.addAll([
                _slaveNode4
                  ..children.clear()
                  ..parent = _slaveNode3,
                _slaveNode5
                  ..children.clear()
                  ..parent = _slaveNode3,
              ]),
          ]),
      ])),
  offlineRoot: OfflineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: []),
);

final testTopologyStateOffline1 = TopologyState(
  nodesCount: 1,
  onlineRoot: _onlineRoot
    ..children.clear()
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot,
    ),
  offlineRoot: OfflineTopologyNode(
      data: const TopologyModel(isOnline: false, location: 'Offline'),
      children: [_slaveOfflineNode1..children.clear()]),
);

final testTopologyStateOffline2 = TopologyState(
  nodesCount: 1,
  onlineRoot: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()),
  offlineRoot: OfflineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: [
        _slaveOfflineNode1..children.clear(),
        _slaveOfflineNode2..children.clear()
      ]),
);

final testTopologyStateOffline3 = TopologyState(
  nodesCount: 1,
  onlineRoot: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode2
          ..children.clear()
          ..parent = _masterNode,
      ])),
  offlineRoot: OfflineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: [
        _slaveOfflineNode3..children.clear(),
        _slaveOfflineNode4..children.clear(),
        _slaveOfflineNode5..children.clear(),
      ]),
);

final testTopologyStateOffline4 = TopologyState(
  nodesCount: 1,
  onlineRoot: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode,
      ])),
  offlineRoot: OfflineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: [
        _slaveOfflineNode2..children.clear(),
        _slaveOfflineNode3..children.clear(),
        _slaveOfflineNode4..children.clear(),
        _slaveOfflineNode5..children.clear(),
      ]),
);

final testTopologyStateOffline5 = TopologyState(
  nodesCount: 1,
  onlineRoot: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()),
  offlineRoot: OfflineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Offline'),
      children: [
        _slaveOfflineNode1..children.clear(),
        _slaveOfflineNode2..children.clear(),
        _slaveOfflineNode3..children.clear(),
        _slaveOfflineNode4..children.clear(),
        _slaveOfflineNode5..children.clear(),
      ]),
);
