import 'dart:async';

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
import 'package:privacy_gui/page/topology/helpers/topology_subtitle.dart';
import 'package:privacy_gui/page/topology/helpers/node_identifier.dart';
import 'package:privacy_gui/page/topology/helpers/topology_nav_target.dart';
import 'package:privacy_gui/page/topology/helpers/topology_node_order.dart';
import 'package:privacy_gui/page/topology/helpers/topology_search.dart';
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
  /// any size asks for — had nowhere to be built.
  ///
  /// The page now also passes `interactive: true`, so pan and zoom reach the same
  /// viewport by hand. The controller is still what a *search* needs: a query has
  /// no gesture, and `focusOn` opens whatever aggregate was holding the match.
  final TopologyController _controller = TopologyController();
  final TextEditingController _searchController = TextEditingController();

  /// Coalesces keystrokes before the graph is searched.
  ///
  /// A search is a full node scan plus `highlight`, plus a camera animation to the
  /// match. At `mesh-at-scale` sizes — 55 nodes — running that per keystroke means
  /// the viewport chases each letter while the viewer is still typing the word.
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // The build reads `_searchController.text` to decide whether the clear button
    // exists, so it has to listen: the two empty `setState(() {})` calls this
    // replaces were hand-invalidating a Listenable the build depended on, which is
    // the shape that leaves a stale read the moment a path forgets one.
    _searchController.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    // Only the clear button's presence depends on this rebuild; the graph is driven
    // by the controller.
    setState(() {});
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Highlight every node matching [query], and move the viewport to the first.
  ///
  /// Matching is this app's business, not the kit's: name, MAC and IP are the
  /// three things a viewer knows a device by, which is the same set the device
  /// list searches (`searchByNameMacIp`).
  /// Search after a short quiet period, so a word costs one scan rather than one
  /// per letter.
  ///
  /// 250ms: long enough to swallow ordinary typing, short enough that the graph
  /// still feels like it is answering. An empty query skips the wait — clearing the
  /// field is a request to see everything again, and making that lag reads as the
  /// clear having not worked.
  void _searchDebounced(GraphData topology, String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      _search(topology, query);
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 250),
      () => _search(topology, query),
    );
  }

  void _search(GraphData topology, String query) {
    // The query goes in raw: `TopologySearch` owns trimming and case-folding, and
    // normalising here as well would be the same work done twice in two places
    // that then have to agree.
    final matches = TopologySearch.match(topology, query);
    _controller.highlight(matches);

    if (matches.isEmpty) {
      _controller.fitAll();
      return;
    }

    // Which match to move to is `focusTarget`'s decision — nearest the anchor,
    // ties by name — not `.first` off a Set, which would be insertion order
    // dressed up as a choice.
    final target = TopologySearch.focusTarget(topology, query);
    if (target != null) {
      // `focusOn` also expands whatever aggregate holds the node, which is what
      // makes a match inside a collapsed cluster reachable at all.
      _controller.focusOn(target, scale: 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDevices = ref.watch(devicesDataProvider);

    return UiKitPageView.withSliver(
      // Stays scrollable. Turning it off does not give the graph an unbounded
      // parent to fill — `withSliver` puts the body in a `SliverToBoxAdapter`
      // either way, so the incoming height is infinite and an `Expanded` there
      // throws on every frame. The graph therefore keeps an explicit height, and
      // the page keeps its scroll.
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
            // Watched, not read. `ref.read` took a one-time snapshot, so a
            // system-info fetch that landed after the devices one left this page
            // on whatever it saw first — and with the branch below that meant a
            // blank page that never recovered.
            final sysInfo =
                ref.watch(systemInfoDataProvider).valueOrNull?.model;
            if (sysInfo == null) {
              // Still arriving, or failed. Either way the graph cannot be built
              // without the gateway's own identity, and an empty box says nothing
              // and offers nothing — the state a viewer reads as a broken page.
              return const Center(child: AppLoader());
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
                identifier: kTopologySearchFieldIdentifier,
                hintText: loc(context).searchByNameMacIp,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : AppIconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        identifier: kTopologySearchClearIdentifier,
                        tooltip: loc(context).clear,
                        styleVariant: ButtonStyleVariant.text,
                        size: AppButtonSize.small,
                        onTap: () {
                          // Clearing notifies the listener, which rebuilds.
                          _searchController.clear();
                          _search(topology, '');
                        },
                      ),
                onChanged: (value) => _searchDebounced(topology, value),
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
        // An explicit height, because the sliver body above it is unbounded.
        //
        // 0.78 rather than 0.7: the graph now pans, so it is worth more of the
        // viewport — but it cannot have all of it. The page scrolls, and a graph
        // that filled the viewport exactly would leave a vertical drag ambiguous
        // between panning the mesh and scrolling the page. Leaving a margin keeps
        // the page's own scroll reachable beside the graph rather than only
        // through it.
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
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
                // Adaptive, not `always`: a leaf is drawn while its disc is at
                // least 44px across and held behind an aggregate below that, so a
                // crowded parent folds instead of stacking devices nobody can hit.
                //
                // ui_kit measured what the alternatives cost. `always` keeps every
                // device on screen at any density — 9% of taps opened the wrong
                // device at ten leaves per parent, 61% at twelve. `clustered` asks a
                // *count* to answer a question about room and fires at thirteen,
                // which is past both. Adaptive asks about the room directly.
                //
                // Its escape hatch is zoom, and this page has two: a pinch
                // (`interactive: true` below) and the search field, which reaches
                // the same viewport through `TopologyController.focusOn`. Either
                // reopens an aggregate the rule had closed.
                //
                // Off means `collapsed`, not `onHover`. `onHover` reveals a
                // parent's leaves whenever the pointer crosses it, so on a desktop
                // the devices the viewer just asked to hide come back under the
                // cursor and cannot be got rid of. `collapsed` is the mode that
                // means what the switch says — and it is also the one that leaves
                // the count on each node, because `LeafOrbitRing` draws its number
                // whenever the leaves are not expanded.
                leafVisibility: _showDevices
                    ? LeafVisibility.adaptive
                    : LeafVisibility.collapsed,
                nodeRendererRegistry: NodeRendererRegistry.unified,
                enableAnimation: true,
                // Pan and zoom. The page above does not scroll, so the gesture
                // arena has one claimant.
                //
                // This is also what `LeafVisibility.adaptive` needs to be usable
                // rather than merely correct: it aggregates a parent's leaves when
                // their drawn size falls under 44px and reopens them when the
                // viewer zooms in, the way zooming a map opens its pins. Without a
                // pinch the only route back into a cluster was the search field.
                interactive: true,
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
                  subtitleBuilder: (node) =>
                      TopologySubtitle.build(context, node),
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
                nodeComparator: TopologyNodeOrder.compare,
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
