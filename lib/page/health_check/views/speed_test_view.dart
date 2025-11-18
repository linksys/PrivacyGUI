import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

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
    final mainWidget = SpeedTestWidget(
      showDetails: true,
      showInfoPanel: true,
      showStepDescriptions: true,
      showLatestOnIdle: false, // History is shown separately in this view
      meterSize: ResponsiveLayout.isMobileLayout(context)
          ? 3.col
          : 5.col, // Make it larger on desktop
    );

    final latestSpeedTest = healthCheckState.result;
    final (resultTitle, resultDesc) =
        _getTestResultDesc(context, latestSpeedTest);
    final performanceDescriptionCard = latestSpeedTest != null
        ? _performanceDescriptionCard(
            context, resultTitle, resultDesc, latestSpeedTest.timestamp)
        : SizedBox.shrink();

    final historyWidget = _buildHistoryPanel(context, historicalTests);

    return StyledAppPageView.withSliver(
      scrollable: true,
      title: loc(context).speedTest,
      child: (context, constraints) => ResponsiveLayout(
        mobile: Column(
          children: [
            mainWidget,
            const AppGap.large5(),
            performanceDescriptionCard,
            const AppGap.large5(),
            historyWidget,
          ],
        ),
        desktop: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: mainWidget),
            const AppGap.gutter(),
            Expanded(
                flex: 6,
                child: Column(
                  children: [
                    performanceDescriptionCard,
                    const AppGap.large5(),
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
      width: ResponsiveLayout.isMobileLayout(context) ? double.infinity : 5.col,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(loc(context).speedTestHistory),
          const AppGap.medium(),
          history.isEmpty
              ? AppCard(
                  child: Center(
                    child: AppText.bodyMedium(
                        loc(context).speedTestNoRecordsFound),
                  ),
                )
              : Column(
                  children: history
                      .map((result) => AppCard(
                            margin:
                                const EdgeInsets.only(bottom: Spacing.small3),
                            child: Padding(
                              padding: const EdgeInsets.all(Spacing.medium),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText.bodyMedium(result.timestamp),
                                  const AppGap.small2(),
                                  Row(
                                    children: [
                                      const Icon(Icons.download_rounded,
                                          size: 20),
                                      AppText.labelLarge(
                                          '${result.downloadSpeed} ${result.downloadUnit}ps'),
                                      const AppGap.small3(),
                                      const Icon(Icons.upload_rounded,
                                          size: 20),
                                      AppText.labelLarge(
                                          '${result.uploadSpeed} ${result.uploadUnit}ps'),
                                    ],
                                  ),
                                  const AppGap.small2(),
                                  Wrap(
                                    children: [
                                      AppText.bodySmall(
                                          '${loc(context).ping}:'),
                                      AppText.labelMedium(
                                          '${result.latency} ms'),
                                    ],
                                  ),
                                  const AppGap.small1(),
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
      color: ResponsiveLayout.isMobileLayout(context)
          ? Theme.of(context).colorScheme.surface
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LinksysIcons.bolt),
          const AppGap.medium(),
          AppText.titleSmall(resultTitle),
          const AppGap.small2(),
          AppText.bodyMedium(resultDesc),
          const AppGap.small2(),
          AppText.bodySmall(date),
        ],
      ),
    );
  }

  (String, String) _getTestResultDesc(
      BuildContext context, SpeedTestUIModel? result) {
    var downloadBandWidth = double.parse(result?.downloadSpeed ?? '0');
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
