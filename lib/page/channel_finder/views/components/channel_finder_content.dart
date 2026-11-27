import 'package:flutter/material.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_state.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_band_summary.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_channel_row.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_chart.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// What a running scan is doing, in the words the page's scan card and the
/// dashboard card both use. A scan that has not reported a stage yet is
/// listening for neighbours, which is the part that runs first.
String channelFinderStageText(BuildContext context, ChannelFinderState state) =>
    state.stage == ChannelFinderScanStage.channels
        ? loc(context).channelFinderScanningChannels
        : loc(context).channelFinderScanningNeighbors;

/// The Channel Finder page's body (#1778), laid out per width:
/// - desktop: the scan card and one summary per band on the left (4 of 12
///   columns); the band picker, the chart and the channels in two columns on
///   the right (8 of 12);
/// - tablet: one column, the channels in two columns;
/// - mobile: one column, the channels in one.
///
/// Stateless about the scan itself, so a test can pump any
/// [ChannelFinderState]; the band picked is this widget's own state.
class ChannelFinderContent extends StatefulWidget {
  final ChannelFinderState state;
  final VoidCallback onScan;

  const ChannelFinderContent({
    super.key,
    required this.state,
    required this.onScan,
  });

  @override
  State<ChannelFinderContent> createState() => _ChannelFinderContentState();
}

class _ChannelFinderContentState extends State<ChannelFinderContent> {
  int _band = 0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bands = state.lastResult?.bands ?? const <ChannelBandScanUIModel>[];
    final band = bands.isEmpty ? null : bands[_band.clamp(0, bands.length - 1)];
    final scanCard = _ScanCard(state: state, onScan: widget.onScan);

    Widget channels(int columns) => _BandView(
          bands: bands,
          band: band,
          columns: columns,
          showNoScan: !state.isScanning,
          onBandChanged: (i) => setState(() => _band = i),
        );

    return AppResponsiveLayout(
      mobile: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [scanCard, AppGap.lg(), channels(1)],
      ),
      tablet: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [scanCard, AppGap.lg(), channels(2)],
      ),
      desktop: (ctx) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ctx.colWidth(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                scanCard,
                for (final b in bands) ...[
                  AppGap.md(),
                  LayoutBlock(child: ChannelFinderBandSummary(band: b)),
                ],
              ],
            ),
          ),
          AppGap.gutter(),
          SizedBox(width: ctx.colWidth(8), child: channels(2)),
        ],
      ),
    );
  }
}

/// The band picker, the chart and the channel rows of the band picked, or the
/// "no scan yet" line before the first result.
class _BandView extends StatelessWidget {
  const _BandView({
    required this.bands,
    required this.band,
    required this.columns,
    required this.showNoScan,
    required this.onBandChanged,
  });

  final List<ChannelBandScanUIModel> bands;
  final ChannelBandScanUIModel? band;
  final int columns;
  final bool showNoScan;
  final ValueChanged<int> onBandChanged;

  @override
  Widget build(BuildContext context) {
    final band = this.band;
    if (band == null) {
      return showNoScan
          ? AppText.bodyMedium(loc(context).channelFinderNoScan)
          : const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bands.length > 1) ...[
          AppTabs(
            tabs: [
              for (final b in bands)
                TabItem(
                  label: b.band,
                  identifier: 'channel-finder-band-${b.identifierKey}',
                ),
            ],
            initialIndex: bands.indexOf(band),
            displayMode: TabDisplayMode.segmented,
            showBorder: false,
            onTabChanged: onBandChanged,
          ),
          AppGap.md(),
        ],
        if (_measurementNote(context, band.measurement) case final note?) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon.font(Icons.info_outline,
                  size: 16, color: Theme.of(context).colorScheme.outline),
              AppGap.sm(),
              Expanded(
                child: AppText.bodySmall(note,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          AppGap.md(),
        ],
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ChannelFinderChart(band: band),
        ),
        AppGap.md(),
        LayoutBuilder(builder: (context, constraints) {
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                  columns;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final channel in band.channels)
                SizedBox(
                  width: width,
                  child: ChannelFinderChannelRow(band: band, channel: channel),
                ),
            ],
          );
        }),
      ],
    );
  }

  /// Why a band has no busyness, or null when it was measured. The rows
  /// already say "not measured"; this says whether scanning again can help.
  static String? _measurementNote(
          BuildContext context, ChannelBandMeasurement measurement) =>
      switch (measurement) {
        ChannelBandMeasurement.measured => null,
        ChannelBandMeasurement.refused => loc(context).channelFinderBandRefused,
        ChannelBandMeasurement.unanswered =>
          loc(context).channelFinderBandUnanswered,
      };
}

class _ScanCard extends StatelessWidget {
  final ChannelFinderState state;
  final VoidCallback onScan;

  const _ScanCard({required this.state, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scannedAt = state.lastResult?.scannedAt;
    final error = state.error;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(loc(context).channelFinderDescription,
              color: colors.onSurfaceVariant),
          AppGap.md(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon.font(Icons.info_outline, size: 16, color: colors.outline),
              AppGap.sm(),
              Expanded(
                child: AppText.bodySmall(loc(context).channelFinderScanNote,
                    color: colors.onSurfaceVariant),
              ),
            ],
          ),
          AppGap.lg(),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton.primary(
                identifier: 'channel-finder-scan',
                label: scannedAt == null
                    ? loc(context).channelFinderScan
                    : loc(context).channelFinderScanAgain,
                isLoading: state.isScanning,
                onTap: state.isScanning ? null : onScan,
              ),
              if (scannedAt != null)
                AppText.bodySmall(
                  loc(context).channelFinderLastScan(
                      MaterialLocalizations.of(context)
                          .formatTimeOfDay(TimeOfDay.fromDateTime(scannedAt))),
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
          if (state.isScanning) ...[
            AppGap.md(),
            const AppLoader(variant: LoaderVariant.linear),
            AppGap.xs(),
            AppText.bodySmall(channelFinderStageText(context, state)),
          ],
          if (state.phase == ChannelFinderPhase.failed && error != null) ...[
            AppGap.md(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon.font(Icons.error_outline,
                    size: 16, color: colors.error),
                AppGap.sm(),
                Expanded(
                  child: AppText.bodySmall(localizeServiceError(context, error),
                      color: colors.error),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
