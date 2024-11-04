import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';

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
final testTopologyMasterOnlyState = InstantTopologyState(
  root: _onlineRoot
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot,
    ),
);

final testTopology1SlaveState = InstantTopologyState(
  root: _onlineRoot
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(_slaveNode1..parent = _masterNode),
    ),
);

final testTopology2SlavesStarState = InstantTopologyState(
  root: _onlineRoot
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
);

final testTopology2SlavesDaisyState = InstantTopologyState(
  root: _onlineRoot
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
);

final testTopology5SlavesStarState = InstantTopologyState(
  root: _onlineRoot
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
);

final testTopology5SlavesDaisyState = InstantTopologyState(
  root: _onlineRoot
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
);

final testTopology5SlavesMixedState = InstantTopologyState(
  root: _onlineRoot
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
);

final testTopology1OfflineState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(
          _slaveOfflineNode1
            ..children.clear()
            ..parent = _masterNode,
        ),
    ),
);

final testTopology2OfflineState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(_slaveOfflineNode1
          ..children.clear()
          ..parent = _masterNode)
        ..children.add(_slaveOfflineNode2
          ..children.clear()
          ..parent = _masterNode),
    ),
);

final testTopology3OfflineState = InstantTopologyState(
  root: _onlineRoot
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
        _slaveOfflineNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode2
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode3
          ..children.clear()
          ..parent = _masterNode,
      ])),
);

final testTopology4OfflineState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode2
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode3
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode4
          ..children.clear()
          ..parent = _masterNode,
      ])),
);

final testTopology5OfflineState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveOfflineNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode2
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode3
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode4
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode5
          ..children.clear()
          ..parent = _masterNode,
      ])),
);
