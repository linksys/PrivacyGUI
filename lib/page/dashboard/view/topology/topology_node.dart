import 'package:graphview/GraphView.dart';
import 'package:linksys_moab/bloc/node/state.dart';

class TopologyNode extends Node {
  final String deviceID;
  final String location;
  final bool isMaster;
  final bool isOnline;
  final bool isWiredConnection;
  final int signalStrength;
  int connectedDeviceCount;
  final List<TopologyNode> children;
  //TODO: Duplicate check logic from NodeState!!
  NodeSignalLevel get signalLevel {
    if (isWiredConnection) {
      return NodeSignalLevel.wired;
    } else if (signalStrength <= -70) {
      return NodeSignalLevel.weak;
    } else if (signalStrength > -70 && signalStrength <= -60) {
      return NodeSignalLevel.fair;
    } else if (signalStrength > -60 && signalStrength <= -50) {
      return NodeSignalLevel.good;
    } else if (signalStrength > -50 && signalStrength <= 0) {
      return NodeSignalLevel.excellent;
    } else {
      return NodeSignalLevel.none;
    }
  }

  TopologyNode({
    this.deviceID = '',
    this.location = '',
    this.isMaster = false,
    this.isOnline = false,
    this.isWiredConnection = false,
    this.signalStrength = 0,
    this.connectedDeviceCount = 0,
    this.children = const [],
  }) : super.Id(deviceID);
}

/*
enum WiFiSignal { none, weak, good, fair, excellent }
enum DeviceRole { router, addon }

// class Topology Node extends Node {
//   TopologyNode({
//     required this.role,
//     required this.serialNumber,
//     required this.modelNumber,
//     required this.firmwareVersion,
//     required this.isLatest,
//     required this.friendlyName,
//     required this.connectedDevice,
//     required this.signal,
//     this.isOnline = true,
//     this.lanIp = '',
//     this.wanIp = '',
//     this.connectTo = '',
//   }) : super.Id(serialNumber);
//
//   factory TopologyNode.fromNode(DataNode node) {
//     return TopologyNode(
//       role: node.role,
//       serialNumber: node.serialNumber,
//       modelNumber: node.modelNumber,
//       firmwareVersion: node.firmwareVersion,
//       isLatest: node.isLatest,
//       friendlyName: node.friendlyName,
//       connectedDevice: node.connectedDevice,
//       signal: node.signal,
//       isOnline: node.isOnline,
//       wanIp: node.wanIp,
//       lanIp: node.lanIp,
//       connectTo: node.parentName,
//     );
//   }
//
//   final DeviceRole role;
//   final String serialNumber;
//   final String modelNumber;
//   final String firmwareVersion;
//   final bool isLatest;
//   final String friendlyName;
//   final int connectedDevice;
//   final WiFiSignal signal;
//   final bool isOnline;
//   final String wanIp;
//   final String lanIp;
//   final String connectTo;
// }


class DataNode {

  DataNode({
    required this.role,
    required this.serialNumber,
    required this.modelNumber,
    required this.firmwareVersion,
    required this.isLatest,
    required this.friendlyName,
    required this.connectedDevice,
    required this.signal,
    this.wanIp = '',
    this.lanIp = '',
    this.isOnline = true,
    this.parentIp = '',
    this.parentName = '',
    this.children = const [],
  });

  factory DataNode.fromNetwork(MoabNetwork network) {
    final device = network.devices!.firstWhere((element) =>
    element.unit.serialNumber == network.deviceInfo.serialNumber);
    return DataNode(
        role: device.isAuthority ? DeviceRole.router : DeviceRole.addon,
        serialNumber: device.unit.serialNumber ?? '',
        modelNumber: device.model.modelNumber ?? '',
        firmwareVersion: device.unit.firmwareVersion ?? '',
        isLatest: true,
        friendlyName: device.friendlyName ?? '',
        connectedDevice: 0,
        signal: WiFiSignal.none);
  }

  final DeviceRole role;
  final String serialNumber;
  final String modelNumber;
  final String firmwareVersion;
  final bool isLatest;
  final String friendlyName;
  final int connectedDevice;
  final WiFiSignal signal;
  final bool isOnline;
  final String wanIp;
  final String lanIp;
  final String parentIp;
  final String parentName;
  final List<DataNode> children;
}

DataNode _createFakeDataNodes() {
  //
  final router = DataNode(
      role: DeviceRole.router,
      serialNumber: 'ROUTER0001SN',
      modelNumber: 'WHW03v1',
      firmwareVersion: '1.1.19.209880',
      isLatest: true,
      friendlyName: 'Router',
      connectedDevice: 16,
      signal: WiFiSignal.good,
      lanIp: '10.189.1.94',
      wanIp: '192.168.1.100',
      isOnline: true,
      children: [
        DataNode(
            role: DeviceRole.addon,
            serialNumber: 'ADDON0001SN',
            modelNumber: 'WHW03v1',
            firmwareVersion: '1.1.19.209880',
            isLatest: true,
            friendlyName: 'Office',
            connectedDevice: 6,
            signal: WiFiSignal.good,
            wanIp: '192.168.1.101',
            isOnline: true,
            parentIp: '192.168.1.100',
            parentName: 'Router',
            children: [
            ]
        ),
        DataNode(
            role: DeviceRole.addon,
            serialNumber: 'ADDON0002SN',
            modelNumber: 'WHW03v1',
            firmwareVersion: '1.1.19.209880',
            isLatest: true,
            friendlyName: 'Gameroom',
            connectedDevice: 6,
            signal: WiFiSignal.good,
            wanIp: '192.168.1.102',
            isOnline: true,
            parentIp: '192.168.1.100',
            parentName: 'Router',
            children: [
            ]
        ),
        DataNode(
            role: DeviceRole.addon,
            serialNumber: 'ADDON0003SN',
            modelNumber: 'WHW03v1',
            firmwareVersion: '1.1.19.209880',
            isLatest: true,
            friendlyName: 'Guest bedroom',
            connectedDevice: 6,
            signal: WiFiSignal.good,
            wanIp: '192.168.1.103',
            isOnline: true,
            parentIp: '192.168.1.100',
            parentName: 'Router',
            children: [
            ]
        ),
        DataNode(
            role: DeviceRole.addon,
            serialNumber: 'ADDON0004SN',
            modelNumber: 'WHW03v1',
            firmwareVersion: '1.1.19.209880',
            isLatest: true,
            friendlyName: 'Kitchen',
            connectedDevice: 10,
            signal: WiFiSignal.good,
            wanIp: '192.168.1.104',
            isOnline: true,
            parentIp: '192.168.1.100',
            parentName: 'Router',
            children: [
            ]
        ),
      ]
  );
  return router;
}
 */