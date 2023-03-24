import 'package:graphview/GraphView.dart';

class TopologyNode extends Node {
  final String deviceID;
  final String location;
  final bool isMaster;
  final bool isOnline;
  final bool isWiredConnection;
  final int signalStrength;
  int connectedDeviceCount;
  String icon;
  final isRouter;
  final List<TopologyNode> children;

  TopologyNode({
    this.deviceID = '',
    this.location = '',
    this.isMaster = false,
    this.isOnline = false,
    this.isWiredConnection = false,
    this.signalStrength = 0,
    this.connectedDeviceCount = 0,
    this.icon = 'genericDevice',
    this.isRouter = false,
    this.children = const [],
  }) : super.Id(deviceID);
}
