import 'package:graphview/GraphView.dart';

class TopologyNode extends Node {
  final String deviceId;
  final String location;
  final bool isMaster;
  final bool isOnline;
  final bool isWiredConnection;
  final int signalStrength;
  final bool isRouter;
  String icon;  
  int connectedDeviceCount;
  final List<TopologyNode> children;

  TopologyNode({
    this.deviceId = '',
    this.location = '',
    this.isMaster = false,
    this.isOnline = false,
    this.isWiredConnection = false,
    this.signalStrength = 0,
    this.isRouter = false,
    this.icon = 'genericDevice',
    this.connectedDeviceCount = 0,
    this.children = const [],
  }) : super.Id(deviceId);
}
