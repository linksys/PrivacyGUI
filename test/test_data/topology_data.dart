import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';

class TopologyTestData {
static const topologyModelJsonTemplate = {
  "deviceId": "6c73112b-b6d1-4bfd-9a8c-80691abb46cc",
  "location": "Linksys03041",
  "isMaster": true,
  "isOnline": true,
  "isWiredConnection": true,
  "signalStrength": -1,
  "isRouter": true,
  "icon": "routerLn12",
  "connectedDeviceCount": 1,
  "model": "LN16",
  "serialNumber": "65G10M27E03041",
  "meshHealth": "",
  "fwVersion": "1.0.4.216421",
  "fwUpToDate": true,
  "ipAddress": "10.138.1.1",
  "hardwareVersion": "1"
};

final _onlineRoot =  OnlineTopologyNode(
  data: const TopologyModel(isOnline: true, location: 'Internet'),
  children: [],
);

final _masterNode = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-MASTER-DEVICEID-000001',
    location: 'Living room',
    isMaster: true,
    isOnline: true,
    isWiredConnection: true,
    signalStrength: 0,
    isRouter: true,
    connectedDeviceCount: 30,
  ),
  children: [],
);
final _masterNode2 = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-MASTER-DEVICEID-000001',
    location: 'Living room 1',
    isMaster: true,
    isOnline: true,
    isWiredConnection: true,
    signalStrength: 0,
    isRouter: true,
    connectedDeviceCount: 30,
    fwUpToDate: false
  ),
  children: [],
);
final _masterPinnacleNode = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    model: 'SPNM60',
    deviceId: 'ROUTER-MASTER-DEVICEID-000001',
    location: 'Living room',
    isMaster: true,
    isOnline: true,
    isWiredConnection: true,
    signalStrength: 0,
    isRouter: true,
    connectedDeviceCount: 30,
  ),
  children: [],
);
final _slaveNode1 = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000001',
    location: 'Kitchen',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -44,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 20,
  ),
  children: [],
);

final _slaveNode2 = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000002',
    location: 'Basement',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -66,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 17,
  ),
  children: [],
);

final _slaveNode3 = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000003',
    location: 'Bed room 1',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -58,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 7,
  ),
  children: [],
);

final _slaveNode4 = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000004',
    location: 'Bed room 2',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -55,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 1,
  ),
  children: [],
);

final _slaveNode5 = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000005',
    location: 'A super long long long long long long cool name',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -70,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 999,
  ),
  children: [],
);

final _slaveOfflineNode1 = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000001',
    location: 'Kitchen',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -49,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 20,
  ),
  children: [],
);

final _slaveOfflineNode2 = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000002',
    location: 'Basement',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -78,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 17,
  ),
  children: [],
);

final _slaveOfflineNode3 = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000003',
    location: 'Bed room 1',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -55,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 7,
  ),
  children: [],
);

final _slaveOfflineNode4 = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000004',
    location: 'Bed room 2',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -58,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 1,
  ),
  children: [],
);

final _slaveOfflineNode5 = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000005',
    location: 'A super long long long long long long cool name',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -70,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 999,
  ),
  children: [],
);

final _slaveGoodNode = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000001',
    location: 'First floor',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -68,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 20,
  ),
  children: [],
);

final _slaveFairNode = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000001',
    location: 'Second floor',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -75,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 20,
  ),
  children: [],
);
final _slavePoorNode = RouterTopologyNode(
  data: TopologyModel.fromMap(topologyModelJsonTemplate).copyWith(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000001',
    location: 'Third floor',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -90,
    isRouter: true,
    icon: 'routerLn12',
    connectedDeviceCount: 20,
  ),
  children: [],
);
/// State
get testTopologyMasterOnlyState => InstantTopologyState(
  root: _onlineRoot
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot,
    ),
);

get testTopologySingalsSlaveState => InstantTopologyState(
  root: _onlineRoot
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(_slaveGoodNode..parent = _masterNode)
        ..children.add(_slavePoorNode..parent = _masterNode)
        ..children.add(_slaveFairNode..parent = _masterNode),
    ),
);

get testTopologyGoodSlaveState => InstantTopologyState(
  root: _onlineRoot
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(_slaveGoodNode..parent = _masterNode),
    ),
);

get testTopologyFairSlaveState => InstantTopologyState(
  root: _onlineRoot
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(_slaveFairNode..parent = _masterNode),
    ),
);

get testTopologyPoorSlaveState => InstantTopologyState(
  root: _onlineRoot
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(_slavePoorNode..parent = _masterNode),
    ),
);

get testTopology1SlaveState => InstantTopologyState(
  root: _onlineRoot
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(_slaveNode1..parent = _masterNode),
    ),
);

get testTopology2SlavesStarState => InstantTopologyState(
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

get testTopology2SlavesDaisyState => InstantTopologyState(
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

get testTopology2SlavesDaisyAndFwUpdateState => InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode2
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode2
          ..children.addAll([
            _slaveNode2
              ..children.clear()
              ..parent = _slaveNode1
          ]),
      ])),
);

get testTopology5SlavesStarState => InstantTopologyState(
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

get testTopology5SlavesDaisyState => InstantTopologyState(
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

get testTopology5SlavesMixedState => InstantTopologyState(
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

get testTopology1OfflineState => InstantTopologyState(
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

get testTopology2OfflineState => InstantTopologyState(
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

get testTopology3OfflineState => InstantTopologyState(
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

get testTopology4OfflineState => InstantTopologyState(
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

get testTopology5OfflineState => InstantTopologyState(
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

get testTopologyPinnacleSlavesDaisyState => InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterPinnacleNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterPinnacleNode
          ..children.addAll([
            _slaveNode2
              ..children.clear()
              ..parent = _slaveNode1
          ]),
      ])),
);

void cleanup() {
  _onlineRoot.children.clear();
  _slaveOfflineNode1.children.clear();
  _slaveOfflineNode2.children.clear();
  _slaveOfflineNode3.children.clear();
  _slaveOfflineNode4.children.clear();
  _slaveOfflineNode5.children.clear();
  _masterNode.children.clear();
  _masterNode2.children.clear();
  _slaveNode1.children.clear();
  _slaveNode2.children.clear();
  _slaveNode3.children.clear();
  _slaveNode4.children.clear();
  _slaveNode5.children.clear();
  _slaveGoodNode.children.clear();
  _slaveFairNode.children.clear();
}
}