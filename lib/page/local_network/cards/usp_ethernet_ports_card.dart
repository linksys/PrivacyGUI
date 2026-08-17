import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/ethernet_port_detail_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Content width below which the two summary tiles stack instead of sitting side
/// by side.
///
/// Derived, not chosen. Each tile spends a fixed 76px on chrome — 24px of
/// [LayoutBlock] padding, the 40px status disc, and the 12px gap after it — and
/// the source-locale labels need 96px (`Disconnected` measures 95.4px at
/// `titleSmall`, `LAN connected` 89.4px). Two of those plus the 8px between them
/// is 352px.
///
/// Below that, side by side is measurably worse than stacked rather than merely
/// tighter. At the narrowest width the grid ever yields — a 191px card, 157px of
/// content — each tile's row has **50.7px** for a disc and gap that cost 52px, so
/// the text column is squeezed to zero and the row *still* overflows by 1.3px.
/// That is under the gate's 2px tolerance, so constraining the text alone would
/// have passed the gate while rendering no label at all (#1228). Stacked, the
/// same card gives each label 81px, and 288px gives it 178px.
///
/// This threshold only decides *readability*: [SummaryTile] is overflow-safe at
/// any width on its own, so getting it wrong costs an ellipsis, never an
/// overflow. It is a local degradation, not a form selection.
///
/// ## Its relationship to the declared `normalAbove: 386` (#1290 AC 6)
///
/// The two coexist and neither subsumes the other, because they are thresholds
/// on **different boxes**:
///
/// * `normalAbove` is read against the width the *grid* gives the card, and
///   selects which form renders.
/// * This one is read against the width the *content column* gets — measured at
///   `cardWidth − 34` — and arranges the tiles inside whichever box the normal
///   form ended up in.
///
/// From the dashboard grid they now never disagree: 386 is the card width at
/// which the content column first reaches 352 (1px sweep: stacked at 385, side by
/// side at 386), so every grid width that selects the normal form also seats the
/// tiles side by side, and the stacked branch is unreachable *from the grid*.
///
/// It is emphatically reachable from the **presentation**. `showCardNormalForm`
/// renders this same normal form in a dialog, or in a full-bleed sheet on a
/// screen too narrow for one, at up to `normalAbove` — so a 320px phone tapping
/// the popup form gets the normal form with ~284px of content, which is this
/// threshold's stacked band. Deleting it would put that phone back on the 191px
/// arrangement #1228 measured as overflowing by 1.3px with no label rendered at
/// all. `ethernet_ports_summary_readability_test.dart` is what holds it, and
/// since #1290 it pins `CardDensity.normal` so its narrow cases keep describing
/// the presented form rather than a grid width that no longer selects it.
const double _kSideBySideMinWidth = 352;

/// Width cap on a compact port chip's text column.
///
/// The chip is `20px` of glyph + `AppSpacing.xs` + this, so the whole chip is
/// bounded at 96px however long a port label the router sends. Port labels are
/// device data (`LAN 1`, and nothing stops a future model from sending more),
/// which is the same reason the normal item is a fixed 88px box: an unbounded
/// string inside a [Wrap] is an overflow the gate would catch on someone else's
/// hardware and not in CI.
const double _kCompactChipTextWidth = 72;

class UspEthernetPortsCard extends ConsumerWidget {
  final List<EthernetPortUIModel>? ports;

  const UspEthernetPortsCard({super.key, this.ports});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ports = this.ports ??
        ref.watch(ethernetDataProvider).valueOrNull?.ethernetPortModels;
    if (ports == null) return const CardSkeleton.info(rows: 3);
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();

    final lanPorts = ports.where((p) => !p.isWan).toList();
    final wanPorts = ports.where((p) => p.isWan).toList();
    final lanConnected = lanPorts.where((p) => p.isUp).length;
    final wanConnected = wanPorts.where((p) => p.isUp).length;

    // Compact drops the summary tiles and shrinks every port to a chip. Both
    // halves are needed together and neither is a nicety: the tiles are what
    // pushed the port grid out of the 121px viewport (#1290), and full-size items
    // would not fit the space they vacate — five 88px items need 536px of content
    // in one run, where five chips need three runs of the 166px the narrowest
    // compact width grants, and fit.
    final compact = CardDensityScope.of(context) == CardDensity.compact;

    return DashboardCardTemplate(
      title: loc(context).ethernetPorts,
      // How many ports are up, over how many there are. The popup form has one
      // line for the fact worth a glance, and for this card that is neither the
      // WAN state alone (a router with no LAN link still reads "Connected") nor
      // a port list, which is what the tap is for.
      popupValue: '${ports.where((p) => p.isUp).length}/${ports.length}',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            // Summary tiles - WAN first
            _SummaryTiles(
              wan: _TileSpec(
                icon: Icons.public,
                accent: colorScheme.primary,
                title: wanConnected > 0
                    ? loc(context).connected
                    : loc(context).disconnected,
                subtitle: 'WAN',
              ),
              lan: _TileSpec(
                icon: Icons.lan,
                accent: appColors?.semanticSuccess ?? Colors.green,
                title: '$lanConnected',
                subtitle: loc(context).lanConnected,
              ),
            ),
            AppGap.lg(),
          ],
          // Port icons
          Wrap(
            spacing: compact ? AppSpacing.lg : AppSpacing.xl,
            runSpacing: compact ? AppSpacing.sm : AppSpacing.lg,
            children:
                ports.map((p) => _PortItem(port: p, compact: compact)).toList(),
          ),
        ],
      ),
    );
  }
}

/// What one summary tile shows. The four values travel together everywhere, so
/// they are one type rather than four parameters repeated per tile.
class _TileSpec {
  const _TileSpec({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
}

/// Lays the WAN and LAN summary tiles out side by side, or stacks them once the
/// card is narrower than [_kSideBySideMinWidth].
///
/// The two tiles are a matched pair — same chrome, same treatment — so they are
/// one widget rendered twice from [_TileSpec] rather than two copies of the same
/// markup, and no change can reach one without the other (#1228).
///
/// Since #1275 the tile itself is `layout_blocks`' [SummaryTile]; only the
/// arrangement and the 40px disc are still this card's. The arrangement stays
/// here deliberately — its threshold is measured from this card's own longest
/// locale and only one other card has one (see §2.10e of the density design).
class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles({required this.wan, required this.lan});

  final _TileSpec wan;
  final _TileSpec lan;

  /// One tile from [spec].
  ///
  /// A method rather than four `SummaryTile.stacked(...)` calls below: the pair
  /// is matched, so no change may reach one tile without the other (#1228).
  Widget _tile(_TileSpec spec, {bool compact = false}) => SummaryTile.stacked(
        leading: _disc(spec),
        value: spec.title,
        label: spec.subtitle,
        compact: compact,
      );

  /// The tinted 40px status disc.
  ///
  /// This card's own chrome, not the shared tile's: the disc's colour and glyph
  /// are the only things identifying which port group a tile describes, which is
  /// why it keeps its design size while the text is what yields (#1228).
  ///
  /// [_TileSpec.accent] travels in the spec because it differs per tile (one is
  /// `colorScheme.primary`, the other `semanticSuccess` from an extension); the
  /// caption colour is the same for both, so [SummaryTile] resolves it and it
  /// stays out of the spec.
  Widget _disc(_TileSpec spec) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: spec.accent
              .withValues(alpha: BlockConstants.badgeBackgroundAlpha),
          shape: BoxShape.circle,
        ),
        child: AppIcon.font(spec.icon, color: spec.accent, size: 20),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kSideBySideMinWidth) {
          return Row(
            children: [
              Expanded(child: _tile(wan)),
              AppGap.sm(),
              Expanded(child: _tile(lan)),
            ],
          );
        }
        // Stacked, the pair has to fit the height the card gives its content —
        // measured at **121px** for this card's 3 rows, at both narrow
        // realizations. Two tiles at the standard 12px padding are 136px and cut
        // the second one off, so stacking tightens the padding to 8px: 2 × 56 +
        // 8 = 120px, and both tiles stay whole. Stretch keeps each one
        // full-width; the height beyond the viewport scrolls rather than clips,
        // so this cannot trade right-overflows for bottom ones (#1228).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tile(wan, compact: true),
            AppGap.sm(),
            _tile(lan, compact: true),
          ],
        );
      },
    );
  }
}

/// One port, in either form.
///
/// ## What compact keeps, and why exactly that
///
/// Both forms show the same three facts — the glyph (whose colour *is* the
/// up/down state), the label, and the speed. Compact lays them on a row with a
/// half-size glyph instead of a column with a full one, and drops only the
/// connected-device line.
///
/// Nothing is invented for the narrow band: the state signal is the same glyph
/// tint the normal item uses, and the speed stays because it is the *textual*
/// half of the state — [EthernetPortUIModel.speedLabel] reads `—` for a port
/// that is down — so a colour-blind reader loses nothing that the wide form
/// gave them. The device names go because they are unbounded router data with a
/// tap that shows them in full, which is the one thing on this card that can be
/// dropped without dropping a fact.
///
/// ## The arithmetic that fixes the shape
///
/// The compact chip measures 61.8–79.0 × **32** with this fixture (the 79 is
/// `100 Mbps`, the widest speed string) and is bounded at 96 wide by
/// [_kCompactChipTextWidth], so five of them take three runs of the 166px content
/// column a 200px card gives — 3 × 32 + 2 × 8 = **112px against a 121px
/// viewport** — and two runs (**72px**) from 269px up, where 235px of content
/// first seats three chips in a row. A full-size item cannot reach that anywhere
/// in the compact band: five 88px items are 536px of content in one run, and
/// stacked they are five runs of 82px.
///
/// Chip height is locale-invariant, which is measured rather than hoped for: a
/// port label and a speed are ASCII device data (`LAN 1`, `1 Gbps`), so no
/// locale's fallback font is reached and every one of the 26 measures the same
/// 32px. The one dimension that is *not* fixed is the port count — five (a WAN
/// plus four LAN) is every model in the fixture, and an eight-port device would
/// take four runs at the bottom of the band and scroll. Scroll, not clip: the
/// template's viewport scrolls, so a wider port count costs reach, never pixels.
class _PortItem extends StatelessWidget {
  final EthernetPortUIModel port;
  final bool compact;

  const _PortItem({required this.port, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successColor =
        theme.extension<AppColorScheme>()?.semanticSuccess ?? Colors.green;
    final inactiveColor = theme.colorScheme.surfaceContainerHighest;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final stateColor = port.isUp ? successColor : inactiveColor;

    if (compact) {
      return GestureDetector(
        onTap: () => showEthernetPortDetailDialog(context, port),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Assets.images.imgPortOn.svg(
              width: 20,
              height: 19,
              colorFilter: ColorFilter.mode(stateColor, BlendMode.srcIn),
            ),
            AppGap.xs(),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _kCompactChipTextWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelMedium(
                    port.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppText.bodySmall(
                    port.speedLabel,
                    color: secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => showEthernetPortDetailDialog(context, port),
      child: SizedBox(
        width: 88,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Assets.images.imgPortOn.svg(
              width: 40,
              height: 38,
              colorFilter: ColorFilter.mode(stateColor, BlendMode.srcIn),
            ),
            AppGap.sm(),
            AppText.labelMedium(port.label),
            AppGap.xs(),
            AppText.bodySmall(
              port.speedLabel,
              color: secondaryTextColor,
            ),
            if (port.connectedDevices.isNotEmpty) ...[
              AppGap.xs(),
              AppText.bodySmall(
                port.connectedDevices.length == 1
                    ? port.connectedDevices.first.displayName
                    : '${port.connectedDevices.first.displayName} +${port.connectedDevices.length - 1}',
                color: secondaryTextColor,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
