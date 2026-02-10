import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/health_check/models/health_check_server.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/shared_widgets/speed_test_widget.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The main view for the Speed Test feature.
///
/// This view combines the interactive [SpeedTestWidget] with a panel
/// that displays the historical results of previous speed tests.
/// It adapts its layout for mobile and desktop screen sizes.
class SpeedTestView extends ConsumerWidget {
  const SpeedTestView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historicalTests =
        ref.watch(healthCheckProvider.select((s) => s.historicalSpeedTests));
    final healthCheckState = ref.watch(healthCheckProvider);
    final servers = healthCheckState.servers;
    final selectedServer = healthCheckState.selectedServer;
    final mainWidget = SpeedTestWidget(
      showDetails: true,
      showInfoPanel: true,
      showStepDescriptions: true,
      showLatestOnIdle: false, // History is shown separately in this view
      showServerSelectionDialog: false, // SpeedTestView uses its own dropdown
      meterSize: context.isMobileLayout
          ? context.colWidth(3)
          : context.colWidth(5), // Make it larger on desktop
    );

    final latestSpeedTest = healthCheckState.result;
    final (resultTitle, resultDesc) =
        _getTestResultDesc(context, latestSpeedTest);
    final performanceDescriptionCard = latestSpeedTest != null
        ? _performanceDescriptionCard(
            context, resultTitle, resultDesc, latestSpeedTest.timestamp)
        : SizedBox.shrink();

    final historyWidget = _buildHistoryPanel(context, historicalTests);

    final serverSelection = servers.isNotEmpty
        ? Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SizedBox(
                width: 250,
                child: AppDropdown<HealthCheckServer>(
                  items: servers,
                  value: selectedServer,
                  itemAsString: (s) => s.toString(),
                  hint: loc(context).selectServer,
                  onChanged: (server) {
                    if (server != null) {
                      ref
                          .read(healthCheckProvider.notifier)
                          .setSelectedServer(server);
                    }
                  },
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).speedTest,
      child: (context, constraints) => AppResponsiveLayout(
        mobile: (ctx) => Column(
          children: [
            serverSelection,
            mainWidget,
            AppGap.xxl(),
            performanceDescriptionCard,
            AppGap.xxl(),
            historyWidget,
          ],
        ),
        desktop: (ctx) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  serverSelection,
                  mainWidget,
                ],
              ),
            ),
            AppGap.gutter(),
            Expanded(
                flex: 6,
                child: Column(
                  children: [
                    performanceDescriptionCard,
                    AppGap.xxl(),
                    historyWidget,
                  ],
                )),
          ],
        ),
      ),
    );
  }

  /// Builds the panel that displays a list of historical speed test results.
  Widget _buildHistoryPanel(
      BuildContext context, List<SpeedTestUIModel> history) {
    return SizedBox(
      width: context.isMobileLayout ? double.infinity : context.colWidth(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(loc(context).speedTestHistory),
          AppGap.md(),
          history.isEmpty
              ? AppCard(
                  child: Center(
                    child: AppText.bodyMedium(
                        loc(context).speedTestNoRecordsFound),
                  ),
                )
              : Column(
                  children: history
                      .map((result) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: AppCard(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText.bodyMedium(result.timestamp),
                                    AppGap.sm(),
                                    Row(
                                      children: [
                                        Icon(Icons.download_rounded, size: 20),
                                        AppText.labelLarge(
                                            '${result.downloadSpeed} ${result.downloadUnit}ps'),
                                        AppGap.sm(),
                                        Icon(Icons.upload_rounded, size: 20),
                                        AppText.labelLarge(
                                            '${result.uploadSpeed} ${result.uploadUnit}ps'),
                                      ],
                                    ),
                                    AppGap.sm(),
                                    Wrap(
                                      children: [
                                        AppText.bodySmall(
                                            '${loc(context).ping}:'),
                                        AppText.labelMedium(
                                            '${result.latency} ms'),
                                      ],
                                    ),
                                    AppGap.xs(),
                                    Wrap(
                                      children: [
                                        AppText.bodySmall(
                                            '${loc(context).serverId}:'),
                                        AppText.labelMedium(result.serverId),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _performanceDescriptionCard(BuildContext context, String resultTitle,
      String resultDesc, String date) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.font(AppFontIcons.bolt),
          AppGap.md(),
          AppText.titleSmall(resultTitle),
          AppGap.sm(),
          AppText.bodyMedium(resultDesc),
          AppGap.sm(),
          AppText.bodySmall(date),
        ],
      ),
    );
  }

  (String, String) _getTestResultDesc(
      BuildContext context, SpeedTestUIModel? result) {
    var downloadBandWidth = double.tryParse(result?.downloadSpeed ?? '0') ?? 0;
    var resultTitle = switch (downloadBandWidth) {
      < 50 => loc(context).speedOkay,
      < 100 => loc(context).speedGood,
      < 150 => loc(context).speedOptimal,
      _ => loc(context).speedUltra,
    };
    var resultDesc = switch (downloadBandWidth) {
      < 50 => loc(context).speedOkayDescription,
      < 100 => loc(context).speedGoodDescription,
      < 150 => loc(context).speedOptimalDescription,
      _ => loc(context).speedUltraDescription,
    };
    return (resultTitle, resultDesc);
  }
}
