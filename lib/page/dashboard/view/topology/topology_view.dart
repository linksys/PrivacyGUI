import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/dashboard/view/topology/topology_node.dart';
import 'package:linksys_app/provider/devices/device_detail_id_provider.dart';
import 'package:linksys_app/provider/devices/topology_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/data/colors.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/animation/blink.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import '../../../../core/utils/logger.dart';
import 'custom_buchheim_walker_algorithm.dart';
import 'custom_tree_edge_renderer.dart';

class TopologyView extends ArgumentsConsumerStatelessView {
  const TopologyView({Key? key, super.args}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topologyState = ref.watch(topologyProvider);
    final isShowingDeviceChain = topologyState.selectedDeviceId != null;
    return StyledAppPageView(
      scrollable: true,
      child: AppBasicLayout(
        content: Column(
          children: [
            !isShowingDeviceChain
                ? (topologyState.root.isOnline
                    ? _connectionStatus(context)
                    : _noInternetConnectionWidget())
                : Container(),
            Expanded(
              child: TreeViewPage(
                root: topologyState.root,
                isChainMode: isShowingDeviceChain,
              ),
            ),
          ],
        ),
        // footer: Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     AppTertiaryButton('Restart mesh system', onTap: () {
        //       ref.read(navigationsProvider.notifier).push(NodeRestartPath());
        //     })
        //   ],
        // ),
      ),
    );
  }

  Widget _connectionStatus(BuildContext context) {
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
                child: AppIcon(
                  icon: getCharactersIcons(context).statusOn,
                  color: ConstantColors.tertiaryGreen,
                ),
              ),
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
        decoration: const BoxDecoration(color: ConstantColors.baseTextBoxWhite),
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
                const AppGap.semiSmall(),
                const AppText.descriptionMain(
                  'No internet connection',
                  color: ConstantColors.tertiaryRed,
                )
              ],
            ),
            AppTertiaryButton(
              'See what I can do',
              onTap: () {},
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
            ref.read(deviceDetailIdProvider.notifier).state =
                nodeDevice.deviceId;
            context.pushNamed(RouteNamed.nodeDetails);
          } else {
            context.pushNamed(RouteNamed.nodeOffline);
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
}
