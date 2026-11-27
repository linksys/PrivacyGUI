import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/nav_tap_guard.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_provider.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_state.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_band_summary.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_content.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The dashboard's Channel Finder card (#1778): how busy the channel each
/// radio is on was at the last scan, and a button to scan.
///
/// The scan is the session's ([channelFinderProvider]), so the card, the page
/// and the diagnostics link show the same one, and a scan started here keeps
/// running when the user leaves. The card never scans on its own: building it
/// reads nothing from the router, and only the button starts a scan.
///
/// One tile per band; the footer holds the scan button and, like the other
/// cards, "View details", which opens the page listing every channel.
class ChannelFinderCard extends ConsumerWidget {
  const ChannelFinderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(channelFinderProvider);

    return DashboardCardTemplate(
      title: loc(context).channelFinder,
      popupValue: _busiest(context, state.lastResult),
      content: _Summary(state: state),
      footer: _ScanFooter(
        state: state,
        onScan: () => ref.read(channelFinderProvider.notifier).scan(),
      ),
    );
  }

  /// The popup form's value: how busy the busiest in-use channel was, which is
  /// the one number that says whether the Wi-Fi is on a crowded channel. Null
  /// before the first scan, so the tile shows the card's name instead.
  static String? _busiest(
      BuildContext context, ChannelFinderResultUIModel? result) {
    if (result == null) return null;
    int? busiest;
    for (final band in result.bands) {
      final percent = band.inUse?.utilizationPercent;
      if (percent != null && (busiest == null || percent > busiest)) {
        busiest = percent;
      }
    }
    return busiest == null
        ? loc(context).channelFinderBusyUnknown
        : loc(context).channelFinderBusy(busiest);
  }
}

/// The card's body: what the scan is doing, why it failed, and one tile per
/// band of the last result. A failed or re-running scan keeps the last
/// result's tiles, as the page does. The tiles only show; the footer's
/// "View details" opens the page, as on the other cards.
class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final ChannelFinderState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final result = state.lastResult;
    final error = state.phase == ChannelFinderPhase.failed ? state.error : null;

    final children = <Widget>[
      if (state.isScanning)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(variant: LoaderVariant.linear),
            AppGap.xs(),
            AppText.bodySmall(channelFinderStageText(context, state),
                color: colors.onSurfaceVariant),
          ],
        ),
      if (error != null)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon.font(Icons.error_outline,
                size: BlockConstants.iconSm, color: colors.error),
            AppGap.sm(),
            Expanded(
              child: AppText.bodySmall(localizeServiceError(context, error),
                  color: colors.error),
            ),
          ],
        ),
      if (result == null && !state.isScanning && error == null)
        AppText.bodyMedium(loc(context).channelFinderNoScan),
      if (result != null)
        for (final band in result.bands)
          LayoutBlock(child: ChannelFinderBandSummary(band: band)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) AppGap.sm(),
          children[i],
        ],
      ],
    );
  }
}

/// The scan button and when the last scan finished, then "View details",
/// which opens the page.
///
/// The button is in the footer, apart from the link, so pressing it scans
/// and does not navigate. A `Wrap` with `spaceBetween`: the link stays at the
/// end of the line, and moves to a line of its own where the two do not fit.
class _ScanFooter extends StatelessWidget {
  const _ScanFooter({required this.state, required this.onScan});

  final ChannelFinderState state;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scannedAt = state.lastResult?.scannedAt;
    final label = loc(context).viewDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDivider(),
        AppGap.md(),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            // The page's scan row: the button, then when the last scan
            // finished, which moves under the button when the two do not fit.
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppButton.small(
                  identifier: 'channel-finder-card-scan',
                  label: scannedAt == null
                      ? loc(context).channelFinderScan
                      : loc(context).channelFinderScanAgain,
                  isLoading: state.isScanning,
                  onTap: state.isScanning ? null : onScan,
                ),
                if (scannedAt != null)
                  AppText.bodySmall(
                    loc(context).channelFinderLastScan(
                        MaterialLocalizations.of(context).formatTimeOfDay(
                            TimeOfDay.fromDateTime(scannedAt))),
                    color: colors.onSurfaceVariant,
                  ),
              ],
            ),
            // The template's detail link, built the way the hand-rolled
            // footers build it: through [cardDetailLink] for the boundary and
            // the E2E handle (#1301, #1450), [NavTapGuard] so a double-tap
            // pushes once (#1445), and [navigateFromCard] so a presented copy
            // closes first (#1453).
            cardDetailLink(
              context,
              label: label,
              child: NavTapGuard(
                onTap: () => navigateFromCard(
                  context,
                  (router) => router.pushNamed(RouteNamed.uspChannelFinder),
                ),
                builder: (context, guardedTap) => InkWell(
                  onTap: guardedTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText.labelMedium(label,
                          color: colors.primary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      AppGap.xs(),
                      Icon(Icons.arrow_forward,
                          size: 14, color: colors.primary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
