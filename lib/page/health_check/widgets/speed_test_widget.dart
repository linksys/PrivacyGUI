import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_digital_text.dart';
import 'package:privacy_gui/page/health_check/models/health_check_enum.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/animation/breath_dot.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/animated_meter.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

/// Defines the layout orientation for the widget.
enum SpeedTestLayout {
  vertical,
  horizontal,
}

/// A highly configurable widget that displays the entire speed test UI.
///
/// This widget manages the UI for all phases of the speed test:
/// - **Idle**: Shows a "Go" button to start the test. Can also show the latest result.
/// - **Running**: Displays an animated meter, live speed, and ping.
/// - **Complete**: Shows the final results and a "Test Again" button.
/// - **Error**: Displays an error message.
class SpeedTestWidget extends ConsumerWidget {
  /// If true, shows detailed information like server ID and latency.
  final bool showDetails;

  /// The layout orientation of the widget.
  final SpeedTestLayout layout;

  /// If true, shows the panel with download/upload results.
  final bool showInfoPanel;

  /// If true, shows descriptions for each step (e.g., "Testing download speed").
  final bool showStepDescriptions;

  /// If true, shows the latest polled speed test result when the status is idle.
  final bool showLatestOnIdle;

  /// The size of the animated meter.
  final double? meterSize;

  const SpeedTestWidget({
    super.key,
    this.showDetails = true,
    this.layout = SpeedTestLayout.vertical,
    this.showInfoPanel = true,
    this.showStepDescriptions = true,
    this.showLatestOnIdle = true,
    this.meterSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthCheckState = ref.watch(healthCheckProvider);
    final latestPolledResult = healthCheckState.latestSpeedTest;

    // Determine the main content based on the current health check status.
    final mainContent = switch (healthCheckState.status) {
      HealthCheckStatus.idle => (showLatestOnIdle && latestPolledResult != null)
          ? Column(
              children: [
                _startButton(context, ref),
                infoView(context, healthCheckState, latestPolledResult),
              ],
            )
          : _startButton(context, ref),
      HealthCheckStatus.running =>
        _runningContent(context, healthCheckState, ref),
      HealthCheckStatus.complete =>
        _completeContent(context, healthCheckState, ref),
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mainContent,
        // Display the "Powered by Ookla" image if applicable.
        if (healthCheckState.isOoklaSpeedTestModule) ...[
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: Spacing.medium),
              child: Image(
                image: CustomTheme.of(context).images.speedtestPowered,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the content to display while the test is running.
  Widget _runningContent(
      BuildContext context, HealthCheckState state, WidgetRef ref) {
    final meter = meterView(context, state, ref);
    final info =
        infoView(context, state, state.result ?? SpeedTestUIModel.empty());

    if (layout == SpeedTestLayout.horizontal) {
      return Row(
        children: [
          meter,
          if (showInfoPanel) ...[const AppGap.large1(), Expanded(child: info)]
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        meter,
        if (showStepDescriptions) ...[
          const AppGap.medium(),
          _descriptionCard(context, state.step),
        ],
        if (showInfoPanel) ...[const AppGap.large1(), info]
      ],
    );
  }

  /// Builds the content to display when the test is complete (either success or error).
  Widget _completeContent(
      BuildContext context, HealthCheckState state, WidgetRef ref) {
    final meter = meterView(context, state, ref);
    final info =
        infoView(context, state, state.result ?? SpeedTestUIModel.empty());

    final isError =
        state.status == HealthCheckStatus.complete && state.errorCode != null;

    if (layout == SpeedTestLayout.horizontal) {
      return Row(
        children: [
          meter,
          Column(
            children: [
              if (showStepDescriptions) ...[
                const AppGap.large5(),
                _descriptionCard(context, state.step),
              ],
              if (isError) ...[
                const AppGap.large1(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.medium),
                  child: errorView(context, state.errorCode),
                ),
              ] else if (showInfoPanel) ...[
                showStepDescriptions
                    ? const AppGap.large1()
                    : const AppGap.large5(),
                Expanded(child: info)
              ]
            ],
          )
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        meter,
        if (isError) ...[
          const AppGap.large1(),
          errorView(context, state.errorCode),
        ] else if (showInfoPanel) ...[
          const AppGap.large1(),
          info
        ]
      ],
    );
  }

  /// Builds the central animated meter gauge.
  Widget meterView(
      BuildContext context, HealthCheckState state, WidgetRef ref) {
    final result = state.result ?? SpeedTestUIModel.empty();

    // Format the live meter value for display.
    final formattedLiveValue = NetworkUtils.formatBitsWithUnit(
        (state.meterValue * 1024).toInt(),
        decimals: 1);

    final bandwidthValue = formattedLiveValue.value;
    final bandwidthUnit = formattedLiveValue.unit;

    final meterValueMbps = (state.meterValue / 1024);

    return Center(
      child: AnimatedMeter(
        size: meterSize ?? 3.col,
        value: meterValueMbps, // Value must be in Mbps for the meter scale
        markers: const <double>[
          0,
          1,
          5,
          10,
          20,
          30,
          50,
          75,
          100
        ], // Markers are in Mbps
        centerBuilder: (context, value) {
          // The content inside the meter (e.g., live speed).
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.titleSmall(switch (state.step) {
                HealthCheckStep.downloadBandwidth => loc(context).download,
                HealthCheckStep.uploadBandwidth => loc(context).upload,
                _ => '',
              }),
              AppText.displayLarge(
                  state.step == HealthCheckStep.latency ? '—' : bandwidthValue),
              if (state.step != HealthCheckStep.latency)
                AppText.bodyMedium('${bandwidthUnit}ps'),
            ],
          );
        },
        bottomBuilder: (context, value) {
          // The content below the meter (e.g., ping or "Test Again" button).
          return state.status == HealthCheckStatus.complete
              ? AppTextButton(
                  key: const Key('speedTestTestAgain'),
                  loc(context).testAgain,
                  onTap: () => ref
                      .read(healthCheckProvider.notifier)
                      .runHealthCheck(Module.speedtest),
                )
              : pingView(context, state.step, result.latency);
        },
      ),
    );
  }

  /// Builds the ping/latency display shown below the meter during the test.
  Widget pingView(BuildContext context, HealthCheckStep step, String latency) {
    final isLatencyStep = step == HealthCheckStep.latency;
    return Column(
      mainAxisAlignment: step != HealthCheckStep.success
          ? MainAxisAlignment.end
          : MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 9),
              child: BreathDot(
                breathSpeed: const Duration(seconds: 1),
                lightColor: Theme.of(context).colorScheme.primary,
                borderColor: Theme.of(context).colorScheme.primary,
                size: 12,
                dotSize: 6,
                animated: isLatencyStep, // Animate only during the latency step
              ),
            ),
            AppText.titleSmall('Ping: ',
                color: Theme.of(context).colorScheme.primary),
            if (isLatencyStep)
              // Show an animated number while testing latency.
              AnimatedDigitalText(
                  fontSize: 12,
                  fontColor: Theme.of(context).colorScheme.primary)
            else ...[
              // Show the final latency value.
              AppText.bodyMedium(latency,
                  color: Theme.of(context).colorScheme.primary),
            ],
            AppText.bodyMedium('ms',
                color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ],
    );
  }

  /// Builds the error message display.
  Widget errorView(BuildContext context, SpeedTestError? errorCode) {
    final errorMessage = switch (errorCode) {
      SpeedTestError.configuration => loc(context).speedTestConfigurationError,
      SpeedTestError.license => loc(context).speedTestLicenseError,
      SpeedTestError.execution => loc(context).speedTestExecutionError,
      SpeedTestError.aborted => loc(context).speedTestAbortedByUser,
      SpeedTestError.dbError => loc(context).speedTestDbError,
      SpeedTestError.timeout => loc(context).generalError,
      _ => loc(context).generalError,
    };
    return Center(
      child: AppText.labelLarge(
        errorMessage,
        color: Theme.of(context).colorScheme.error,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Builds the information panel that shows results and details.
  Widget infoView(BuildContext context, HealthCheckState state,
      SpeedTestUIModel resultToDisplay) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!showDetails) ...[
          const Divider(thickness: 1, height: Spacing.large5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.medium),
            child: Wrap(
              direction: Axis.vertical,
              children: [
                AppText.bodySmall(loc(context).dateAndTime),
                AppText.labelMedium(
                    key: const ValueKey('speedTestDateTime'),
                    resultToDisplay.timestamp),
              ],
            ),
          ),
          const AppGap.large2(),
        ],
        // Show the main result card (Download/Upload) if not in the initial latency step.
        if (showLatestOnIdle || state.step != HealthCheckStep.latency)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.medium),
            child: _resultCard(context, resultToDisplay),
          ),
        if (showDetails) ...[
          const Divider(thickness: 1, height: Spacing.large5),
          _detailsList(context, resultToDisplay),
        ],
      ],
    );
  }

  /// Builds the descriptive card shown during each step of the test.
  Widget _descriptionCard(BuildContext context, HealthCheckStep step) {
    List<Widget> children = [];
    final setpTitle = switch (step) {
      HealthCheckStep.latency => loc(context).testingPing,
      HealthCheckStep.downloadBandwidth => loc(context).testingDownloadSpeed,
      HealthCheckStep.uploadBandwidth => loc(context).testingUploadSpeed,
      _ => '',
    };
    final setpDesc = switch (step) {
      HealthCheckStep.latency => null,
      HealthCheckStep.downloadBandwidth =>
        loc(context).testingDownloadSpeedDescription,
      HealthCheckStep.uploadBandwidth =>
        loc(context).testingUploadSpeedDescription,
      _ => null,
    };
    children.add(AppText.titleSmall(
      setpTitle,
      textAlign: TextAlign.center,
    ));
    if (setpDesc != null) {
      children.add(const AppGap.small2());
      children.add(AppText.bodyMedium(
        setpDesc,
        textAlign: TextAlign.center,
      ));
    }
    return setpTitle.isEmpty
        ? const SizedBox.shrink()
        : SizedBox(
            width: double.infinity,
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          );
  }

  /// Builds the list of detailed results (timestamp, server ID, latency).
  Widget _detailsList(BuildContext context, SpeedTestUIModel result) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          direction: Axis.vertical,
          children: [
            AppText.bodySmall(loc(context).dateAndTime),
            AppText.labelMedium(
                key: const ValueKey('speedTestDateTime'), result.timestamp),
          ],
        ),
        const AppGap.large2(),
        Wrap(
          direction: Axis.vertical,
          children: [
            AppText.bodySmall(loc(context).serverId),
            AppText.labelMedium(result.serverId),
          ],
        ),
        const AppGap.large2(),
        Wrap(
          direction: Axis.vertical,
          children: [
            AppText.bodySmall(loc(context).latency),
            AppText.labelMedium('${result.latency} ms'),
          ],
        ),
      ],
    );
  }

  /// Builds the initial "Go" button to start the test.
  Widget _startButton(BuildContext context, WidgetRef ref) {
    return Container(
      alignment: Alignment.center,
      child: AnimatedMeter.withDefaultMarks(
        size: meterSize ?? 220,
        displayIndicatorValues: false,
        indicatorPathStrokeWidth: 8,
        markerRadius: 2,
        centerBuilder: (context, value) {
          return SizedBox(
            width: 102,
            height: 102,
            child: InkWell(
              key: const Key('goBtn'),
              borderRadius:
                  CustomTheme.of(context).radius.asBorderRadius().extraLarge,
              onTap: () {
                final isSpeedCheckSupported = ref.watch(healthCheckProvider
                    .select((s) => s.isSpeedTestModuleSupported));
                if (isSpeedCheckSupported) {
                  ref
                      .read(healthCheckProvider.notifier)
                      .runHealthCheck(Module.speedtest);
                } else {
                  // If not supported, navigate to the external test page.
                  context.pushNamed(RouteNamed.speedTestExternal);
                }
              },
              child: Ink(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary),
                child: Center(
                  child: AppText.bodyLarge(loc(context).go,
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
          );
        },
        value: 0,
      ),
    );
  }

  /// Builds the card that displays the final download and upload speeds.
  Widget _resultCard(BuildContext context, SpeedTestUIModel result) {
    final downloadBandWidthView = FittedBox(
      fit: BoxFit.scaleDown,
      child: AppText.displaySmall(
          key: const ValueKey('downloadBandWidth'), result.downloadSpeed),
    );
    final uploadBandWidthView = FittedBox(
      fit: BoxFit.scaleDown,
      child: AppText.displaySmall(
          key: const ValueKey('uploadBandWidth'), result.uploadSpeed),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.bodyExtraSmall(loc(context).download),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Spacing.small2),
                    child: Icon(LinksysIcons.arrowDownward,
                        semanticLabel: 'download icon',
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  Expanded(child: downloadBandWidthView),
                ],
              ),
              AppText.bodyExtraSmall('${result.downloadUnit}ps'),
            ],
          ),
        ),
        const AppGap.large2(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.bodyExtraSmall(loc(context).upload),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Spacing.small2),
                    child: Icon(LinksysIcons.arrowUpward,
                        semanticLabel: 'upload icon',
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  Expanded(child: uploadBandWidthView),
                ],
              ),
              AppText.bodyExtraSmall('${result.uploadUnit}ps'),
            ],
          ),
        ),
      ],
    );
  }
}
