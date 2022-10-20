import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphview/GraphView.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/router/network.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/dashboard_path.dart';
import 'package:linksys_moab/route/model/nodes_path.dart';
import 'package:linksys_moab/route/_route.dart';


import 'custom_buchheim_walker_algorithm.dart';
import 'custom_tree_edge_renderer.dart';

class TopologyView extends ArgumentsStatefulView {
  const TopologyView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TopologyViewState();
}

class _TopologyViewState extends State<TopologyView> {

  late DataNode _root;

  @override
  void initState() {
    super.initState();
    _root = _createFakeDataNodes();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
        builder: (context, state) {
          return BasePageView(
            padding: EdgeInsets.zero,
            child: BasicLayout(
              header: _checkInternetConnection() ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SimpleTextButton(
                    text: '+ Add Node',
                    onPressed: () {},
                  )
                ],
              ) : _noInternetConnectionWidget(),
              content: TreeViewPage(root: _transferData(state.selected),),
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SimpleTextButton(
                      text: 'Restart mesh system', onPressed: () {})
                ],
              ),
            ),
          );
        }
    );
  }


  Widget _noInternetConnectionWidget() {
    return Container(
        decoration: BoxDecoration(color: MoabColor.topologyNoInternet),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/icon_close_red.png',
                  width: 12,
                  height: 12,
                ),
                SizedBox(width: 8,),
                Text(
                  'No internet connection',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyText2
                      ?.copyWith(color: Colors.red),
                )
              ],
            ),
            SimpleTextButton(text: 'See what I can do',
              onPressed: () {},
              padding: EdgeInsets.all(4),),
          ],
        ));
  }

  bool _checkInternetConnection() {
    return _root.isOnline;
  }


  DataNode _transferData(MoabNetwork? network) {
    return DataNode.fromNetwork(network!);
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
}

class TreeViewPage extends StatefulWidget {
  final DataNode root;

  const TreeViewPage({Key? key, required this.root}) : super(key: key);

  @override
  _TreeViewPageState createState() => _TreeViewPageState();
}

class _TreeViewPageState extends State<TreeViewPage> {

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
        constrained: false,
        boundaryMargin: EdgeInsets.all(0),
        // minScale: 1,
        // maxScale: 5.6,
        // scaleFactor: 4,
        scaleEnabled: false,
        child: GraphView(
          graph: graph,
          algorithm: CustomBuchheimWalkerAlgorithm(
              builder, CustomEdgeRenderer(builder)),
          paint: Paint()
            ..color = Colors.black
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
          builder: (Node node) {
            return rectangleWidget(node);
          },
        ));
  }

  Random r = Random();

  Widget rectangleWidget(Node node) {
    return InkWell(
        onTap: node.key!.value == '0'
            ? null
            : () {
          print('clicked');
          NavigationCubit.of(context).push(
              ((node as TopologyNode).isOnline
                  ? NodeDetailPath()
                  : NodeOfflineCheckPath())
                ..args = {'node': node});
        },
        child: node.key!.value == '0'
            ? createInternetWidget()
            : createNodeWidget(node));
  }

  final Graph graph = Graph()
    ..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  void initState() {
    super.initState();
    _traverseNodes(null, widget.root);
    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (50)
      ..subtreeSeparation = (100);
  }

  _traverseNodes(DataNode? parent, DataNode node) {
    if (node.role == DeviceRole.router && node.isOnline) {
      final internetNode = Node.Id('0');
      graph.addNode(Node.Id('0'));
      graph.addEdge(internetNode, TopologyNode.fromNode(node));
    } else {
      graph.addNode(TopologyNode.fromNode(node));
      if (parent != null) {
        final parentNode = TopologyNode.fromNode(parent);
        graph.addEdge(parentNode, TopologyNode.fromNode(node));
      }
    }
    for (var child in node.children) {
      _traverseNodes(node, child);
    }
  }

  Widget createInternetWidget() {
    return Image.asset(
      'assets/images/icon_topology_internet.png',
      width: 56,
      height: 56,
    );
  }

  Widget createNodeWidget(Node node) {
    final _node = node as TopologyNode;
    return Column(
      children: [
        Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            Image.asset(
              node.isOnline
                  ? 'assets/images/img_topology_node.png'
                  : 'assets/images/img_topology_node_offline.png',
              width: 74,
              height: 74,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: node.isOnline ? MoabColor.placeholderGrey : Colors.red,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(25),
                color: node.isOnline ? MoabColor.placeholderGrey : Colors.red,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  node.isOnline ? '${_node.connectedDevice}' : '0',
                  style: Theme
                      .of(context)
                      .textTheme
                      .headline4
                      ?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ],
        ),
        Text(
          _node.friendlyName,
          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
        ),
        node.isOnline
            ? _createSignal(_node.signal) ?? const Center()
            : Text(
          getAppLocalizations(context).offline,
          style: Theme
              .of(context)
              .textTheme
              .headline4,
        )
      ],
    );
  }

  Widget? _createSignal(WiFiSignal signal) {
    var imagePath = 'assets/images/icon_wifi_signal_good.png';
    var signalStr = getAppLocalizations(context).wifi_signal_good;
    switch (signal) {
      case WiFiSignal.good:
        break;
      case WiFiSignal.weak:
        signalStr = getAppLocalizations(context).wifi_signal_weak;
        break;
      case WiFiSignal.excellent:
        imagePath = 'assets/images/icon_wifi_signal_excellent.png';
        signalStr = getAppLocalizations(context).wifi_signal_excellent;
        break;
      default:
        return null;
    }
    return Wrap(
      children: [
        Image.asset(
          imagePath,
          height: 14,
        ),
        SizedBox(
          width: 4,
        ),
        Text(
          signalStr,
          style: Theme
              .of(context)
              .textTheme
              .headline4,
        )
      ],
    );
  }
}

enum WiFiSignal { none, weak, good, fair, excellent }
enum DeviceRole { router, addon }

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
    element.unit.serialNumber == network.deviceInfo?.serialNumber);
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

class TopologyNode extends Node {
  TopologyNode({
    required this.role,
    required this.serialNumber,
    required this.modelNumber,
    required this.firmwareVersion,
    required this.isLatest,
    required this.friendlyName,
    required this.connectedDevice,
    required this.signal,
    this.isOnline = true,
    this.lanIp = '',
    this.wanIp = '',
    this.connectTo = '',
  }) : super.Id(serialNumber);

  factory TopologyNode.fromNode(DataNode node) {
    return TopologyNode(
      role: node.role,
      serialNumber: node.serialNumber,
      modelNumber: node.modelNumber,
      firmwareVersion: node.firmwareVersion,
      isLatest: node.isLatest,
      friendlyName: node.friendlyName,
      connectedDevice: node.connectedDevice,
      signal: node.signal,
      isOnline: node.isOnline,
      wanIp: node.wanIp,
      lanIp: node.lanIp,
      connectTo: node.parentName,
    );
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
  final String connectTo;
}
