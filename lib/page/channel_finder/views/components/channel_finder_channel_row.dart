import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_colors.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// One channel of a band: its busyness bar, how many networks are on it and
/// the strongest one. Tapping it lists those networks.
class ChannelFinderChannelRow extends StatelessWidget {
  final ChannelBandScanUIModel band;
  final ChannelScanUIModel channel;

  const ChannelFinderChannelRow({
    super.key,
    required this.band,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final utilization = channel.utilization;
    final percent = channel.utilizationPercent;
    final strongest = channel.strongestSignalDbm;

    return LayoutBlock(
      identifier:
          'channel-finder-channel-${band.channelIdentifierKey(channel)}',
      onTap: () => showChannelNetworksDialog(context, channel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppText.labelLarge(
                        loc(context).channelFinderChannel(channel.channel)),
                    if (channel.isInUse)
                      AppBadge(
                        label: loc(context).channelFinderInUse,
                        color: colors.primary,
                      ),
                  ],
                ),
              ),
              AppGap.sm(),
              AppText.bodySmall(percent == null
                  ? loc(context).channelFinderBusyUnknown
                  : loc(context).channelFinderBusy(percent)),
              AppGap.xs(),
              AppIcon.font(AppFontIcons.chevronRight, size: 20),
            ],
          ),
          AppGap.xs(),
          AppLoader(
            variant: LoaderVariant.linear,
            value: (utilization ?? 0) / 255,
            color: channelBusynessColor(context,
                utilization: utilization, isInUse: channel.isInUse),
          ),
          AppGap.xs(),
          AppText.bodySmall(
            [
              loc(context).channelFinderNetworks(channel.neighbors.length),
              if (strongest != null)
                loc(context).channelFinderStrongest(strongest),
            ].join(' · '),
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Lists the networks the neighbour scan heard on [channel], strongest first.
Future<void> showChannelNetworksDialog(
    BuildContext context, ChannelScanUIModel channel) {
  return showSimpleAppDialog(
    context,
    title: loc(context).channelFinderNetworksOnChannel(channel.channel),
    content: channel.neighbors.isEmpty
        ? AppText.bodyMedium(loc(context).channelFinderNoNetworksOnChannel)
        : ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final network in channel.neighbors)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText.bodyMedium(
                              network.ssid.isEmpty
                                  ? loc(context).channelFinderHiddenNetwork
                                  : network.ssid,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppGap.md(),
                          AppText.bodySmall(loc(context)
                              .signalStrengthDbm('${network.signalDbm}')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
    actions: [
      AppButton.text(
        identifier: 'channel-finder-networks-close',
        label: loc(context).close,
        onTap: () => context.pop(),
      ),
    ],
  );
}
