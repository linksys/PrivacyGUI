import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/topology/bloc/cubit.dart';
import 'package:linksys_moab/page/dashboard/view/topology/bloc/state.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_node.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/data/colors.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/animation/blink.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import '../../../../util/logger.dart';
import 'custom_buchheim_walker_algorithm.dart';
import 'custom_tree_edge_renderer.dart';

class TopologyView extends ArgumentsConsumerStatelessView {
  const TopologyView({
    Key? key,
    super.next,
    super.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = args['selectedDeviceId'];
    return BlocProvider(
      create: (context) => TopologyCubit(context.read<RouterRepository>()),
      child: TopologyContentView(
        selectedDeviceId: selectedId,
      ),
    );
  }
}

class TopologyContentView extends ConsumerStatefulWidget {
  final String? selectedDeviceId;
  const TopologyContentView({Key? key, this.selectedDeviceId})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopologyContentView();
}

class _TopologyContentView extends ConsumerState<TopologyContentView> {
  @override
  void initState() {
    super.initState();
    context.read<TopologyCubit>().fetchTopologyData(
          selectedId: widget.selectedDeviceId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TopologyCubit, TopologyState>(builder: (context, state) {
      return StyledAppPageView(
        padding: const AppEdgeInsets.only(),
        scrollable: true,
        // padding: const AppEdgeInsets.regular(),
        child: AppBasicLayout(
          content: Visibility(
            visible: state.rootNode.deviceID.isNotEmpty,
            replacement: const AppFullScreenSpinner(),
            child: Column(
              children: [
                widget.selectedDeviceId == null
                    ? (state.rootNode.isOnline
                        ? _connectionStatus()
                        : _noInternetConnectionWidget())
                    : Container(),
                Expanded(
                  child: TreeViewPage(
                    root: state.rootNode,
                    isChainMode: widget.selectedDeviceId != null,
                  ),
                ),
              ],
            ),
          ),
          // footer: Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     SimpleTextButton(
          //         text: 'Restart mesh system',
          //         onPressed: () {
          //           ref.read(navigationsProvider.notifier).push(NodeRestartPath());
          //         })
          //   ],
          // ),
        ),
      );
    });
  }

  Widget _connectionStatus() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: ConstantColors.primaryLinksysBlue.withOpacity(0.07),
        ),
        child: AppPadding(
          padding: const AppEdgeInsets.symmetric(
              vertical: AppGapSize.semiSmall, horizontal: AppGapSize.regular),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Blink(
                  child: Icon(
                getCharactersIcons(context).statusOn,
                color: ConstantColors.tertiaryGreen,
              )),
              const AppGap.regular(),
              const AppText.descriptionSub(
                'Connected to Internet',
              )
            ],
          ),
        ),
      ),
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
                      .bodyMedium
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

class TreeViewPage extends ConsumerStatefulWidget {
  final TopologyNode root;
  final bool isChainMode;

  const TreeViewPage({
    Key? key,
    required this.root,
    this.isChainMode = false,
  }) : super(key: key);

  @override
  ConsumerState<TreeViewPage> createState() => _TreeViewPageState();
}

class _TreeViewPageState extends ConsumerState<TreeViewPage> {
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
    logger.d('Interactive viewer width: ${MediaQuery.of(context).size.width}');
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(0),
      scaleEnabled: false,
      child: GraphView(
        graph: graph,
        algorithm: CustomBuchheimWalkerAlgorithm(
          builder,
          CustomEdgeRenderer(builder),
          viewWidth: MediaQuery.of(context).size.width,
        ),
        paint: Paint()
          ..color = AppTheme.of(context).colors.tertiaryText
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          return rectangleWidget(node);
        },
      ),
    );
  }

  _traverseNodes(TopologyNode? parentNode, TopologyNode node) {
    graph.addNode(node);
    if (parentNode != null) {
      graph.addEdge(parentNode, node);
    }
    for (var child in node.children) {
      _traverseNodes(node, child);
    }
  }

  Widget rectangleWidget(Node node) {
    return InkWell(
      onTap: () {
        final nodeDevice = node as TopologyNode;
        if (nodeDevice.isRouter) {
          if (nodeDevice.isOnline) {
            // Update the current target Id for node state
            context.read<NodeCubit>().setDetailNodeID(nodeDevice.deviceID);
            ref.read(navigationsProvider.notifier).push(NodeDetailPath());
          } else {
            ref.read(navigationsProvider.notifier).push(NodeOfflineCheckPath());
          }
        } else {}
      },
      child: createNodeWidget(node),
    );
  }

  Widget createNodeWidget(Node node) {
    final node0 = node as TopologyNode;
    return Column(
      children: [
        Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ConstantColors.primaryLinksysBlue.withOpacity(0.26),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(100),
                  color: ConstantColors.primaryLinksysBlue.withOpacity(0.07),
                ),
                width: node0.isMaster
                    ? AppTheme.of(context).avatar.extraLarge
                    : AppTheme.of(context).avatar.large,
                height: node0.isMaster
                    ? AppTheme.of(context).avatar.extraLarge
                    : AppTheme.of(context).avatar.large,
                margin: EdgeInsets.all(AppTheme.of(context).spacing.semiSmall),
                child: AppPadding(
                  padding: const AppEdgeInsets.regular(),
                  child: Image(
                    image: AppTheme.of(context)
                        .images
                        .devices
                        .getByName(node0.icon),
                  ),
                )),
            if (!widget.isChainMode)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: node0.isOnline
                      ? ConstantColors.primaryLinksysBlack
                      : Colors.red,
                ),
                width: AppTheme.of(context).avatar.normal,
                height: AppTheme.of(context).avatar.normal,
                child: AppPadding(
                  padding: const AppEdgeInsets.small(),
                  child: Center(
                    child: AppText.descriptionSub(
                      node0.isOnline ? '${node0.connectedDeviceCount}' : '0',
                      color: ConstantColors.primaryLinksysWhite,
                    ),
                  ),
                ),
              )
          ],
        ),
        const AppGap.regular(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            node.isMaster
                ? Icon(getCharactersIcons(context).ethernetDefault)
                : Icon(getCharactersIcons(context).wifiDefault),
            const AppGap.regular(),
            AppText.descriptionSub(
              node0.location,
            ),
          ],
        ),
      ],
    );
  }

  Widget _getConnectionImage(TopologyNode node) {
    return Wrap(
      children: [
        AppIcon.small(
          icon: node.isWiredConnection
              ? AppTheme.of(context).icons.characters.ethernetDefault
              : Utils.getWifiSignalIconData(context, node.signalStrength),
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
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
