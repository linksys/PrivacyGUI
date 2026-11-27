import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_colors.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// One band of the last scan: the channel its radio is on, how busy that
/// channel was and how many networks the router heard on it (#1778).
///
/// Shared by the dashboard card's band tiles and the page's band summaries,
/// so the two agree on what "busy" looks like.
class ChannelFinderBandSummary extends StatelessWidget {
  const ChannelFinderBandSummary({super.key, required this.band});

  final ChannelBandScanUIModel band;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final inUse = band.inUse;
    final utilization = inUse?.utilization;
    final percent = inUse?.utilizationPercent;
    final channel = inUse?.channel ?? band.channelInUse;
    final details = [
      if (channel != null) loc(context).channelFinderChannel(channel),
      if (inUse != null)
        loc(context).channelFinderNetworks(inUse.neighbors.length),
    ].join(' · ');

    return Column(
      // `stretch`, so the `Wrap` below has a tight width and `spaceBetween`
      // puts the busyness at the row's right edge rather than one gap after
      // the band.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A `Wrap`, not a `Row`: neither side may be cut, so a long busyness
        // string moves to a line of its own instead of overflowing.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xxs,
          children: [
            AppText.labelLarge(band.band),
            AppText.bodySmall(percent == null
                ? loc(context).channelFinderBusyUnknown
                : loc(context).channelFinderBusy(percent)),
          ],
        ),
        AppGap.xs(),
        AppLoader(
          variant: LoaderVariant.linear,
          value: (utilization ?? 0) / 255,
          // The in-use channel: the primary colour, or the warning colour when
          // it is busy (channelBusynessColor).
          color: channelBusynessColor(context,
              utilization: utilization, isInUse: inUse != null),
        ),
        if (details.isNotEmpty) ...[
          AppGap.xs(),
          AppText.bodySmall(details, color: colors.onSurfaceVariant),
        ],
      ],
    );
  }
}
