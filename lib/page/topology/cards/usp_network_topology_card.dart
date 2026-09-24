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
import 'package:privacy_gui/page/topology/helpers/topology_subtitle.dart';
import 'package:privacy_gui/page/topology/helpers/topology_node_content_builder.dart';
import 'package:privacy_gui/page/topology/helpers/topology_tree_labels.dart';
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
                leafVisibility:
                    useRing ? LeafVisibility.onHover : LeafVisibility.always,
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
                  subtitleBuilder: (node) =>
                      TopologySubtitle.build(context, node),
                  preferAnimationNode: true,
                  showStatusIndicator: true,
                  // Our words, localised. ui_kit 3.4.0 stopped shipping label
                  // text: a library knows which appearance a node wears, not
                  // what that is called in our domain — and its own enum names
                  // ("PRIMARY", "active") were reaching the user in English.
                  showType: true,
                  slotLabelBuilder: (node, slot) =>
                      TopologyTreeLabels.slot(context, node, slot),
                  showStatusText: true,
                  statusLabelBuilder: (node, state) =>
                      TopologyTreeLabels.status(context, state),
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
    GraphData topology,
    String nodeId,
  ) {
    final node = topology.nodes.firstWhereOrNull((n) => n.id == nodeId);
    // The external node has nothing to show; a leaf now does, on both
    // presentations.
    //
    // This used to refuse leaves as well, on the grounds that the wide card's
    // in-place panel refused them too, so the two answered the same taps. ui_kit
    // 3.4.0 removed that refusal — whether a node has a panel is decided by
    // whether one was configured, never by what kind of node it is — so keeping
    // the leaf arm here would make the narrow card the only presentation that
    // ignores a tap on a device. `NodeDetailPopup` drops its role-only rows for a
    // node with no role (#1614 D2), which is what makes a leaf's panel truthful.
    if (node == null || node.isExternal) return;

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

  /// Wraps [child] in a local Theme override that enables topology animation.
  ///
  /// **The dashboard's spacing multiplier is gone, and it was measured out rather
  /// than tidied away.** It doubled `nodeSpacing` and `orbitRadius` to stop nodes
  /// crowding at the width the grid gives this card (#1299) — a real fix while the
  /// layout divided whatever had to be placed into a fixed circle. ui_kit 3.4.0
  /// sizes every ring from the discs going on it, so the pitch is already
  /// guaranteed: measured 51.5px at 5, 12, 30 and 70 leaves, with x1.0, x2.0 and
  /// x2.2 all producing **the same 51.5**. The multiplier buys no separation.
  ///
  /// What it does buy is a bigger bounding box, and after fit-to-screen that is a
  /// *loss*. Measured on this card's 700x392 content box at 30 leaves: x1.0 fits
  /// at 0.564 and draws a 29.1px pitch, x2.0 hits the kit's 0.5 fit floor and
  /// draws 25.9px. The discs shrink with it, 36.1px to 32.2px. So the spread now
  /// makes the graph slightly *smaller* than leaving it alone — the opposite of
  /// what it was added to do, because the crowding it compensated for no longer
  /// exists.
  ///
  /// The animation flag is why this override still exists at all — and it was
  /// always enabled for both presentations, so with the spacing gone this method
  /// no longer distinguishes them and its `presented` parameter went with the
  /// multiplier. The two presentations still differ elsewhere in this widget
  /// (`interactive`, and which detail surface answers a tap).
  Widget _withTopologyAnimation(BuildContext context, Widget child) {
    final appTheme = Theme.of(context).extension<AppDesignTheme>();
    if (appTheme == null) return child;

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          appTheme.copyWith(
            visualEffects:
                appTheme.visualEffects | AppThemeConfig.effectTopologyAnimation,
          ),
        ],
      ),
      child: child,
    );
  }
}
