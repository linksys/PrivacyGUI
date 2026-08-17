import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
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
/// overflow. It is a local degradation, not a form selection — Track B (#1240)
/// may later replace it with a declared `normalAbove` threshold.
const double _kSideBySideMinWidth = 352;

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

    return DashboardCardTemplate(
      title: loc(context).ethernetPorts,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          // Port icons
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.lg,
            children: ports.map((p) => _PortItem(port: p)).toList(),
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

class _PortItem extends StatelessWidget {
  final EthernetPortUIModel port;

  const _PortItem({required this.port});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successColor =
        theme.extension<AppColorScheme>()?.semanticSuccess ?? Colors.green;
    final inactiveColor = theme.colorScheme.surfaceContainerHighest;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);

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
              colorFilter: ColorFilter.mode(
                port.isUp ? successColor : inactiveColor,
                BlendMode.srcIn,
              ),
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
