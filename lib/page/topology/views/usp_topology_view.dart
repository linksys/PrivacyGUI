import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/topology/helpers/topology_nav_target.dart';
import 'package:privacy_gui/page/topology/helpers/topology_node_content_builder.dart';
import 'package:privacy_gui/page/topology/helpers/topology_tree_labels.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:privacy_gui/page/topology/views/components/node_detail_popup.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Full-page interactive topology view.
///
/// Displays the network topology using [AppTopology] in interactive mode.
/// Tapping a router/extender node navigates to Node Detail; tapping a client
/// navigates to Device Detail.
class UspTopologyView extends ConsumerStatefulWidget {
  const UspTopologyView({super.key});

  @override
  ConsumerState<UspTopologyView> createState() => _UspTopologyViewState();
}

class _UspTopologyViewState extends ConsumerState<UspTopologyView> {
  bool _showDevices = true;

  /// The handle the search field drives the graph through.
  ///
  /// The graph view held selection, expansion and the viewport privately until
  /// ui_kit 3.4.0, so "type a name, go to that device" — the one thing a mesh of
  /// any size asks for — had nowhere to be built. This page still passes
  /// `interactive: false`, because it sits in a scrollable and an
  /// `InteractiveViewer` there swallows the scroll; the controller is what makes
  /// focus reachable anyway, which pan and zoom never were.
  final TopologyController _controller = TopologyController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Highlight every node matching [query], and move the viewport to the first.
  ///
  /// Matching is this app's business, not the kit's: name, MAC and IP are the
  /// three things a viewer knows a device by, which is the same set the device
  /// list searches (`searchByNameMacIp`).
  void _search(GraphData topology, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      _controller.highlight(const {});
      _controller.fitAll();
      return;
    }

    final matches = topology.nodes
        .where((node) => _matches(node, needle))
        .map((node) => node.id)
        .toSet();

    _controller.highlight(matches);
    if (matches.isNotEmpty) {
      // `focusOn` also expands whatever aggregate holds the node, which is what
      // makes a match inside a collapsed cluster reachable at all.
      _controller.focusOn(matches.first, scale: 2);
    }
  }

  bool _matches(GraphNode node, String needle) {
    if (node.name.toLowerCase().contains(needle)) return true;
    // `extra` carries the IP on a leaf and the manufacturer on a node.
    if ((node.extra ?? '').toLowerCase().contains(needle)) return true;
    final metadata = node.metadata;
    if (metadata == null) return false;
    for (final key in const ['mac', 'deviceId']) {
      final value = metadata[key];
      if (value is String && value.toLowerCase().contains(needle)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final asyncDevices = ref.watch(devicesDataProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).networkTopology,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      onRefresh: () => ref.refresh(devicesDataProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncDevices.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => ServiceErrorView(
            error: error is ServiceError ? error : null,
            title: loc(context).unableToLoadTopology,
            onRetry: () => ref.invalidate(devicesDataProvider),
          ),
          data: (data) {
            final sysInfo = ref.read(systemInfoDataProvider).valueOrNull?.model;
            if (sysInfo == null) {
              return const SizedBox.shrink();
            }
            final topology = UspTopologyBuilder.buildFromMeshNetwork(
              meshNetwork: data.meshNetwork,
              info: sysInfo,
            );

            return _buildTopologyCard(context, topology);
          },
        );
      },
    );
  }

  Widget _buildTopologyCard(BuildContext context, GraphData topology) {
    final router = GoRouter.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: search, then the devices toggle
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                controller: _searchController,
                hintText: loc(context).searchByNameMacIp,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: loc(context).clear,
                        onPressed: () {
                          _searchController.clear();
                          _search(topology, '');
                          setState(() {});
                        },
                      ),
                onChanged: (value) {
                  _search(topology, value);
                  // Only to swap the clear button in and out; the graph is driven
                  // by the controller, not by this rebuild.
                  setState(() {});
                },
              ),
            ),
            AppGap.md(),
            AppText.labelMedium(
              loc(context).devices,
              color: colorScheme.onSurfaceVariant,
            ),
            AppGap.sm(),
            AppSwitch(
              value: _showDevices,
              onChanged: (value) => setState(() => _showDevices = value),
            ),
          ],
        ),
        AppGap.sm(),
        // Topology view
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          // The width decides which view `auto` resolves to, and that decides
          // which of the two tap reactions is live — so it has to be read from the
          // same box the kit measures, not from the screen.
          child: LayoutBuilder(builder: (context, constraints) {
            final isTree = constraints.maxWidth < AppTopology.defaultBreakpoint;
            return _withTopologyAnimation(
              context,
              AppTopology(
                topology: topology,
                viewMode: TopologyViewMode.auto,
                layoutMode: LayoutRecommendation.auto,
                leafVisibility: _showDevices
                    ? LeafVisibility.always
                    : LeafVisibility.onHover,
                nodeRendererRegistry: NodeRendererRegistry.unified,
                enableAnimation: true,
                interactive: false,
                controller: _controller,
                // One reaction per tap, and which reaction depends on which view is
                // on screen.
                //
                // ui_kit 3.4.0 reports every tap AND opens the panel when one is
                // configured; its old silence meant "tapped, and there was nothing
                // else to do with it", which is not what the callback is documented
                // to mean. So in the graph view, navigating from here as well would
                // push a route and then open a panel over the page being left.
                //
                // The tree view, though, does not read `nodeDetailConfig` at all —
                // it only calls `onNodeTap`. Passing null unconditionally would
                // therefore leave every tree row pressable and inert, which is the
                // narrow viewport this page resolves to. Hence the width test, using
                // the kit's own published breakpoint and the same `<` it applies.
                onNodeTap: isTree
                    ? (nodeId) => _navigateByNodeId(router, nodeId, topology)
                    : null,
                nodeContentBuilder: TopologyNodeContentBuilder.build,
                treeConfig: TopologyTreeConfiguration(
                  titleBuilder: (node) => node.name,
                  subtitleBuilder: (node) => node.extra ?? '',
                  preferAnimationNode: true,
                  showStatusIndicator: true,
                  // Our words, localised — see TopologyTreeLabels. The kit used to
                  // print its own enum names here, unconditionally in this variant.
                  showType: true,
                  slotLabelBuilder: (node, slot) =>
                      TopologyTreeLabels.slot(context, node, slot),
                  showStatusText: true,
                  statusLabelBuilder: (node, state) =>
                      TopologyTreeLabels.status(context, state),
                  expanded: true,
                ),
                nodeDetailConfig: NodeDetailConfig(
                  trigger: NodeDetailTrigger.tap,
                  mode: NodeDetailMode.floatingPanel,
                  detailBuilder: (ctx, node, metadata) =>
                      NodeDetailPopup.builder(ctx, node, metadata,
                          showDetailsButton: true),
                ),
                // The external node is the one node with nothing to show, and it
                // became tappable in 3.4.0.
                nodeTapFilter: (node) => !node.isExternal,
                onClusterToggled: (nodeId, expanded) => logger.d(
                    '[Topology]: viewer ${expanded ? 'opened' : 'closed'} $nodeId'),
                nodeComparator: _nodeComparator,
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Navigate by node id — used by the tree view's `onNodeTap`.
  void _navigateByNodeId(GoRouter router, String nodeId, GraphData topology) {
    final node = topology.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return;

    final target = topologyNavTargetFor(node);
    if (target == null) return;

    router.pushNamed(target.route, queryParameters: target.queryParameters);
  }

  /// Comparator for sorting nodes: online first, then nodes before devices, then
  /// alphabetical.
  static int _nodeComparator(GraphNode a, GraphNode b) {
    // 1. Active before inactive
    if (a.isInactive && !b.isInactive) return 1;
    if (!a.isInactive && b.isInactive) return -1;
    // 2. Role priority: master > slave > device > external
    final rolePriority = topologyRolePriority(a) - topologyRolePriority(b);
    if (rolePriority != 0) return rolePriority;
    // 3. Alphabetical by name
    return a.name.compareTo(b.name);
  }

  Widget _withTopologyAnimation(BuildContext context, Widget child) {
    final appTheme = Theme.of(context).extension<AppDesignTheme>();
    if (appTheme == null) return child;

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          appTheme.copyWith(
            visualEffects:
                appTheme.visualEffects | AppThemeConfig.effectTopologyAnimation,
            // The x2.2 spacing multiplier is gone. It was here to stop leaves
            // overlapping the gateway, which ui_kit 3.4.0 makes structurally
            // impossible: every ring is sized from the discs going on it, and the
            // pitch measured 51.5px at x1.0, x2.0 and x2.2 alike, at 5 through 70
            // leaves. Past the fit-to-screen step the multiplier is actively
            // worse — it grows the bounds into the 0.5 fit floor, so the drawn
            // pitch fell from 29.1px to 25.9px and the discs with it. See
            // `UspNetworkTopologyCard._withTopologyAnimation` for the numbers.
          ),
        ],
      ),
      child: child,
    );
  }
}
