import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/topology/helpers/topology_node_content_builder.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:privacy_gui/page/topology/views/components/node_detail_popup.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Width the graph view's in-place node-detail panel needs before it has a valid
/// position at all: 320 of panel plus 32 of margin on either side, which are the
/// figures `TopologyGraphView` computes its `Positioned.left` from.
///
/// Below this the card presents the detail itself ([_showNodeDetail]) rather than
/// letting the kit try. On ui_kit v2.38.0 the attempt throws — the two `clamp`
/// limits invert and Dart reports `Invalid argument: 32`, raised inside layout
/// and repeated on every frame until the panel is dismissed — and a kit that
/// guards the clamp can only answer by shrinking the panel to the room left,
/// which at this card's narrowest grid width (261px, four columns on a 601px
/// screen) is a 197px panel inside the `ClipRect` above.
const double _kInPlaceDetailMinWidth = 384.0;

/// Height twin of [_kInPlaceDetailMinWidth]: the same function places the panel
/// with `(nodeY - 50).clamp(60.0, stackHeight - 200)`, so it wants 60 of margin
/// above a panel taken as 200 tall. This card's declared floor of three rows
/// gives its content exactly 260, so one row less inverts the vertical limits the
/// way a narrow card inverts the horizontal ones.
const double _kInPlaceDetailMinHeight = 260.0;

/// Displays a network topology visualization of the router and connected devices.
///
/// Uses [AppTopology] to render a gateway node (the router) with client nodes
/// (connected devices) linked via WiFi or Ethernet connections.
/// When mesh topology data is available, extender nodes are shown between
/// gateway and their connected clients.
class UspNetworkTopologyCard extends ConsumerWidget {
  final SystemInfoUIModel? info;
  final MeshNetwork? meshNetwork;

  const UspNetworkTopologyCard({
    super.key,
    this.info,
    this.meshNetwork,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final info =
        this.info ?? ref.watch(systemInfoDataProvider).valueOrNull?.model;
    final meshNetwork = this.meshNetwork ?? devicesData?.meshNetwork;
    if (info == null || meshNetwork == null)
      return const CardSkeleton.topology();

    final topology = UspTopologyBuilder.buildFromMeshNetwork(
      meshNetwork: meshNetwork,
      info: info,
    );
    final onlineCount = meshNetwork.onlineClientCount;
    final totalCount = meshNetwork.totalClientCount;
    final useRing = totalCount >= 8;
    // Whether this is the card the popup tile opens rather than the one the grid
    // lays out. Both of the decisions below differ between the two, and neither
    // can be read off the box: a presented card is 400px wide, which is also a
    // width the grid can hand it.
    final presented = CardDensityScope.isPresented(context);

    return DashboardCardTemplate(
      title: loc(context).networkTopology,
      titleBadge: AppBadge(
          label: loc(context)
              .nOnlineOfTotal(onlineCount.toString(), totalCount.toString())),
      // Online over total, the same fact the badge states — the graph itself is
      // unreadable at two columns, so the count is all the tile can honestly
      // carry. `nOnlineOfTotal` spells it out in words and does not fit.
      popupValue: '$onlineCount/$totalCount',
      detailRoute: RouteNamed.uspTopology,
      scrollable: false,
      content: ClipRect(
        child: _withTopologyAnimation(
          context,
          presented: presented,
          // The panel the graph view opens in place is sized in absolute pixels,
          // so whether it fits is a question about this card's box — hence a
          // `LayoutBuilder` here, reading the very constraints the graph view
          // measures its panel against ([AppTopology] passes the content box
          // straight through to `TopologyGraphView`).
          //
          // The builder's own context is discarded on purpose: the dialog below
          // is opened against the card's context, which sits outside the topology
          // theme override, so it inherits the app's theme rather than a doubled
          // node spacing it has no use for.
          LayoutBuilder(
            builder: (_, constraints) {
              final hasRoomForPanel =
                  constraints.maxWidth >= _kInPlaceDetailMinWidth &&
                      constraints.maxHeight >= _kInPlaceDetailMinHeight;

              return AppTopology(
                topology: topology,
                viewMode: TopologyViewMode.graph,
                layoutMode: LayoutRecommendation.auto,
                clientVisibility: useRing
                    ? ClientVisibility.onHover
                    : ClientVisibility.always,
                nodeRendererRegistry: NodeRendererRegistry.unified,
                enableAnimation: true,
                // Pan and zoom, but only in the presentation. On the dashboard
                // the graph sits inside a drag-to-resize grid, and an
                // `InteractiveViewer` there swallows the gestures the grid needs;
                // in the presentation there is no grid to protect and panning is
                // the only way to reach a node the fixed-width box cannot fit.
                interactive: presented,
                nodeContentBuilder: TopologyNodeContentBuilder.build,
                treeConfig: TopologyTreeConfiguration(
                  titleBuilder: (node) => node.name,
                  subtitleBuilder: (node) => node.extra ?? '',
                  preferAnimationNode: true,
                  showStatusIndicator: true,
                  showStatusText: true,
                  expanded: false,
                ),
                // Exactly one of the two is ever live. With a `nodeDetailConfig`
                // the graph view opens the panel itself and never calls
                // `onNodeTap` for a node that has one; without it, every tap that
                // would have opened a panel arrives here instead.
                nodeDetailConfig: hasRoomForPanel
                    ? NodeDetailConfig(
                        trigger: NodeDetailTrigger.tap,
                        detailBuilder: (ctx, node, metadata) =>
                            NodeDetailPopup.builder(ctx, node, metadata),
                      )
                    : null,
                onNodeTap: hasRoomForPanel
                    ? null
                    : (nodeId) => _showNodeDetail(context, topology, nodeId),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Presents the tapped node's detail as a dialog, for a card with no room for
  /// the graph view's in-place panel.
  ///
  /// The width is [AppDialog]'s own 400px cap rather than a `SizedBox` here: a
  /// fixed width would exceed the viewport on the 320px screen this branch exists
  /// to serve, and the cap already collapses to the screen when there is less
  /// room than that. [NodeDetailPopup] is a bare `Column`, so the dialog is the
  /// only frame around it — the same content the wide card shows in the panel,
  /// not a card drawn inside a card.
  void _showNodeDetail(
    BuildContext context,
    MeshTopology topology,
    String nodeId,
  ) {
    final node = topology.nodes.firstWhereOrNull((n) => n.id == nodeId);
    // Clients and the internet node get no detail on a wide card either — the
    // graph view fires `onNodeTap` for them and skips the panel — so both
    // presentations answer exactly the same taps.
    if (node == null || node.isClient || node.isInternet) return;

    showAppDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: AppText.titleMedium(node.name),
        content: NodeDetailPopup.builder(ctx, node, node.metadata),
        actions: [
          AppButton.text(
            label: loc(ctx).close,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  /// Wraps [child] in a local Theme override that enables topology animation
  /// and — on the dashboard only — spreads the client nodes out.
  ///
  /// The spread is sized for the box the grid gives this card, whose preferred
  /// realization is 700px+ of width. A [presented] card is a fixed
  /// `kCardPresentationWidth`, so the same doubling spends the box on gaps and
  /// pushes the outer nodes under the `ClipRect` above — which is half of what
  /// "topology 也是太小" was (#1299). The animation is enabled in both, so the
  /// override is still built either way.
  Widget _withTopologyAnimation(
    BuildContext context,
    Widget child, {
    required bool presented,
  }) {
    final appTheme = Theme.of(context).extension<AppDesignTheme>();
    if (appTheme == null) return child;

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          appTheme.copyWith(
            visualEffects:
                appTheme.visualEffects | AppThemeConfig.effectTopologyAnimation,
            topologySpec: presented
                ? appTheme.topologySpec
                : appTheme.topologySpec.copyWith(
                    nodeSpacing: appTheme.topologySpec.nodeSpacing * 2.0,
                    orbitRadius: appTheme.topologySpec.orbitRadius * 2.0,
                  ),
          ),
        ],
      ),
      child: child,
    );
  }
}
