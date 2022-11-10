import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphview/GraphView.dart';
import 'package:linksys_moab/bloc/add_nodes/state.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/dashboard/view/topology/bloc/cubit.dart';
import 'package:linksys_moab/page/dashboard/view/topology/bloc/state.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_node.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/utils.dart';
import 'custom_buchheim_walker_algorithm.dart';
import 'custom_tree_edge_renderer.dart';

class TopologyView extends StatelessWidget {
  const TopologyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TopologyCubit(context.read<RouterRepository>()),
      child: const TopologyContentView(),
    );
  }
}

class TopologyContentView extends StatefulWidget {
  const TopologyContentView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TopologyContentView();
}

class _TopologyContentView extends State<TopologyContentView> {
  @override
  void initState() {
    super.initState();
    context.read<TopologyCubit>().fetchTopologyData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TopologyCubit, TopologyState>(builder: (context, state) {
      return BasePageView(
        padding: EdgeInsets.zero,
        child: BasicLayout(
          content: Visibility(
            visible: state.rootNode.deviceID.isNotEmpty,
            child: Column(
              children: [
                state.rootNode.isOnline
                    ? _addNodeWidget()
                    : _noInternetConnectionWidget(),
                Expanded(
                  child: TreeViewPage(root: state.rootNode),
                ),
              ],
            ),
            replacement: const FullScreenSpinner(),
          ),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SimpleTextButton(
                  text: 'Restart mesh system',
                  onPressed: () {
                    NavigationCubit.of(context).push(NodeRestartPath());
                  })
            ],
          ),
        ),
      );
    });
  }

  Widget _addNodeWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SimpleTextButton(
          text: '+ Add Node',
          onPressed: () {
            NavigationCubit.of(context).push(SetupNthChildPlacePath()
              ..next = NavigationCubit.of(context).currentPath()
              ..args = {
                'isAddonsNode': true,
                'init': true,
                'mode': AddNodesMode.addNodeOnly,
              });
          },
        )
      ],
    );
  }

  Widget _noInternetConnectionWidget() {
    return Container(
        decoration: const BoxDecoration(color: MoabColor.topologyNoInternet),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                const SizedBox(
                  width: 8,
                ),
                Text(
                  'No internet connection',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      ?.copyWith(color: Colors.red),
                )
              ],
            ),
            SimpleTextButton(
              text: 'See what I can do',
              onPressed: () {},
              padding: const EdgeInsets.all(4),
            ),
          ],
        ));
  }
}

class TreeViewPage extends StatefulWidget {
  final TopologyNode root;

  const TreeViewPage({Key? key, required this.root}) : super(key: key);

  @override
  _TreeViewPageState createState() => _TreeViewPageState();
}

class _TreeViewPageState extends State<TreeViewPage> {
  final Graph graph = Graph()..isTree = true;
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

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(0),
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

  _traverseNodes(TopologyNode? parentNode, TopologyNode node) {
    if (node.isMaster && node.isOnline) {
      final internetSourceNode = Node.Id('0');
      graph.addNode(internetSourceNode);
      graph.addEdge(internetSourceNode, node);
    } else {
      graph.addNode(node);
      if (parentNode != null) {
        graph.addEdge(parentNode, node);
      }
    }
    for (var child in node.children) {
      _traverseNodes(node, child);
    }
  }

  Widget rectangleWidget(Node node) {
    return InkWell(
        onTap: node.key!.value == '0'
            ? null
            : () {
                final nodeDevice = node as TopologyNode;
                if (nodeDevice.isOnline) {
                  // Update the current target Id for node state
                  context
                      .read<NodeCubit>()
                      .setDetailNodeID(nodeDevice.deviceID);
                  NavigationCubit.of(context).push(NodeDetailPath());
                } else {
                  NavigationCubit.of(context).push(NodeOfflineCheckPath());
                }
              },
        child: node.key!.value == '0'
            ? Image.asset(
                'assets/images/icon_topology_internet.png',
                width: 56,
                height: 56,
              )
            : createNodeWidget(node));
  }

  Widget createNodeWidget(Node node) {
    final _node = node as TopologyNode;
    return Column(
      children: [
        Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            Image.asset(
              _node.isOnline
                  ? 'assets/images/img_topology_node.png'
                  : 'assets/images/img_topology_node_offline.png',
              width: 74,
              height: 74,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      _node.isOnline ? MoabColor.placeholderGrey : Colors.red,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(25),
                color: _node.isOnline ? MoabColor.placeholderGrey : Colors.red,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  _node.isOnline ? '${_node.connectedDeviceCount}' : '0',
                  style: Theme.of(context)
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
          _node.location,
          style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
        ),
        node.isOnline
            ? _getConnectionImage(_node)
            : Text(
                getAppLocalizations(context).offline,
                style: Theme.of(context).textTheme.headline4,
              )
      ],
    );
  }

  Widget _getConnectionImage(TopologyNode node) {
    return Wrap(
      children: [
        Image.asset(
          node.isWiredConnection ? 'assets/images/icon_signal_wired.png' : Utils.getWifiSignalImage(node.signalStrength),
          width: 14,
          height: 14,
        ),
        Offstage(
          offstage: node.isWiredConnection,
          child: Wrap(
            children: [
              const SizedBox(
                width: 4,
              ),
              Text(
                Utils.getWifiSignalLevel(node.signalStrength).displayTitle,
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
