import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/wifi_channel.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_colors.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_channel_row.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// How busy every channel of one band was, as bars (#1778).
///
/// Three stacked series carry one channel each, so each bar takes the colour
/// of what it is: a channel at or above [busyChannelUtilization], the channel
/// the radio is on, or any other. Busy wins over in use, as on the rows and the
/// card, so a busy channel the radio is on reads as busy here too; its row's
/// "In use" badge says which it is. A channel with no reading has no bar.
/// Tapping a bar lists that channel's networks, as tapping its row does.
class ChannelFinderChart extends StatelessWidget {
  const ChannelFinderChart({super.key, required this.band, this.height = 180});

  final ChannelBandScanUIModel band;

  /// Height of the bars' area; the legend sits under it.
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final channels = band.channels;

    final bars = splitChannelBars(band);
    final series = [
      AppChartSeries(
        label: loc(context).channelFinderInUse,
        data: bars.inUse,
        color: colors.primary,
      ),
      AppChartSeries(
        label: loc(context).channelFinderLegendBusy,
        data: bars.busy,
        color: channelBusyColor(context),
      ),
      AppChartSeries(
        label: loc(context).channelFinderLegendOther,
        data: bars.other,
        color: colors.outline,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: AppBarChart(
            series: series,
            stacked: true,
            xLabels: [for (final c in channels) '${c.channel}'],
            yAxis: const AppChartAxis(min: 0, max: 100, interval: 50),
            yLabelFormatter: (v) => '${v.toInt()}%',
            showTooltip: false,
            onTouch: (event) {
              if (event.type != AppChartTouchType.tapUp) return;
              final touched = event.touchedPoints;
              if (touched.isEmpty) return;
              final index = touched.first.dataIndex;
              if (index < 0 || index >= channels.length) return;
              showChannelNetworksDialog(context, channels[index]);
            },
          ),
        ),
        AppGap.sm(),
        AppChartLegend.bar(series: series),
      ],
    );
  }
}

/// Each channel's busy percentage in exactly one of three series, the others
/// holding 0 for it, so a stacked chart draws one bar per channel in that
/// series' colour: [busy] for a channel at or above [busyChannelUtilization],
/// then [inUse] for the channel the radio is on, then [other]. A channel with
/// no reading is 0 in all three.
({List<double> inUse, List<double> busy, List<double> other}) splitChannelBars(
    ChannelBandScanUIModel band) {
  final inUse = <double>[];
  final busy = <double>[];
  final other = <double>[];
  for (final channel in band.channels) {
    final value = (channel.utilizationPercent ?? 0).toDouble();
    final isBusy = isBusyUtilization(channel.utilization);
    busy.add(isBusy ? value : 0);
    inUse.add(!isBusy && channel.isInUse ? value : 0);
    other.add(!isBusy && !channel.isInUse ? value : 0);
  }
  return (inUse: inUse, busy: busy, other: other);
}
