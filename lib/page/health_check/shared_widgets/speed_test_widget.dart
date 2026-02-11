import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_digital_text.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/health_check/models/health_check_enum.dart';
import 'package:privacy_gui/page/health_check/models/health_check_server.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

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

  /// If true, shows the result summary (download/upload) below the meter when complete.
  final bool showResultSummary;

  /// If true, shows a server selection dialog when the user taps the Go button
  /// without a server selected. If false, the button is disabled when no server
  /// is selected.
  final bool showServerSelectionDialog;

  const SpeedTestWidget({
    super.key,
    this.showDetails = true,
    this.layout = SpeedTestLayout.vertical,
    this.showInfoPanel = true,
    this.showStepDescriptions = true,
    this.showLatestOnIdle = true,
    this.meterSize,
    this.showResultSummary = true,
    this.showServerSelectionDialog = true,
  });

  /// Calculates the maximum speed (in Mbps) from historical speed test results.
  /// Returns the default value (100.0) if no valid history exists.
  double _calculateMaxHistoricalSpeed(HealthCheckState state) {
    final allTests = <SpeedTestUIModel>[];

    // Include historical tests
    if (state.historicalSpeedTests.isNotEmpty) {
      allTests.addAll(state.historicalSpeedTests);
    }

    // Include latest test if it's not already in historical
    if (state.latestSpeedTest != null &&
        !state.historicalSpeedTests.contains(state.latestSpeedTest)) {
      allTests.add(state.latestSpeedTest!);
    }

    if (allTests.isEmpty) {
      return 100.0; // Default to 100 Mbps if no history
    }

    double maxSpeed = 0.0;

    for (final test in allTests) {
      // Download speed (convert Kbps to Mbps)
      if (test.downloadBandwidthKbps != null &&
          test.downloadBandwidthKbps! > 0) {
        final downloadMbps = test.downloadBandwidthKbps! / 1024.0;
        if (downloadMbps > maxSpeed) {
          maxSpeed = downloadMbps;
        }
      }

      // Upload speed (convert Kbps to Mbps)
      if (test.uploadBandwidthKbps != null && test.uploadBandwidthKbps! > 0) {
        final uploadMbps = test.uploadBandwidthKbps! / 1024.0;
        if (uploadMbps > maxSpeed) {
          maxSpeed = uploadMbps;
        }
      }
    }

    // If all values were null or zero, return default
    return maxSpeed > 0 ? maxSpeed : 100.0;
  }

  /// Rounds up a speed value to the nearest hundred (ceiling).
  /// Examples:
  /// - 89 -> 100
  /// - 345 -> 400
  /// - 1234 -> 1300
  /// - 56 -> 100 (minimum is 100)
  double _roundUpToHundred(double speed) {
    // Ensure minimum is 100
    if (speed < 100) {
      return 100.0;
    }

    // Round up to nearest hundred
    return (speed / 100).ceil() * 100.0;
  }

  /// Calculates the dynamic upper bound for the speed test gauge based on historical data.
  /// Returns at least 100 Mbps, rounded up to the nearest hundred.
  double _calculateGaugeUpperBound(HealthCheckState state) {
    final maxHistorical = _calculateMaxHistoricalSpeed(state);
    return _roundUpToHundred(maxHistorical);
  }

  /// Generates appropriate marker values for the speed gauge based on the upper bound.
  ///
  /// The markers are distributed to provide meaningful reference points:
  /// - For 100 Mbps: [0, 1, 5, 10, 20, 30, 50, 75, 100]
  /// - For 100-200 Mbps: [0, 10, 20, 30, 50, 75, 100, 150, upperBound]
  /// - For 200-500 Mbps: [0, 50, 100, 150, 200, 250, 300, 400, upperBound]
  /// - For 500-1000 Mbps: [0, 100, 200, 300, 400, 500, 750, upperBound]
  /// - For 1000+ Mbps: [0, 200, 400, 600, 800, 1000, 1200, ...]
  ///
  /// Small gauges (< 130px) use simplified markers: [0, upperBound]
  List<double> _generateMarkers(double upperBound,
      {bool isSmallGauge = false}) {
    if (isSmallGauge) {
      return [0, upperBound];
    }

    if (upperBound <= 100) {
      // Default case: 0-100 Mbps
      return const [0, 1, 5, 10, 20, 30, 50, 75, 100];
    } else if (upperBound <= 200) {
      // 100-200 Mbps range
      return [0, 10, 20, 30, 50, 75, 100, 150, upperBound];
    } else if (upperBound <= 500) {
      // 200-500 Mbps range
      // Generate markers at 50 Mbps intervals up to 300, then 100 Mbps intervals
      final markers = <double>[0];
      for (double i = 50; i <= 300; i += 50) {
        markers.add(i);
      }
      for (double i = 400; i < upperBound; i += 100) {
        markers.add(i);
      }
      markers.add(upperBound);
      return markers;
    } else if (upperBound <= 1000) {
      // 500-1000 Mbps range
      // Generate markers at 100 Mbps intervals, with an extra marker at 750 if applicable
      final markers = <double>[0];
      for (double i = 100; i <= 500; i += 100) {
        markers.add(i);
      }
      // Only add 750 if upperBound is >= 750 to maintain sorted order
      if (upperBound >= 750) {
        markers.add(750);
      }
      if (upperBound != 1000) {
        markers.add(upperBound);
      } else {
        markers.add(1000);
      }
      return markers;
    } else {
      // 1000+ Mbps range
      // Generate markers at 200 Mbps intervals
      final markers = <double>[0];
      for (double i = 200; i < upperBound; i += 200) {
        markers.add(i);
      }
      markers.add(upperBound);
      return markers;
    }
  }

  /// Runs the speed test with optional server selection.
  ///
  /// If [showServerSelectionDialog] is true and servers are available,
  /// shows a dialog to select a server before running the test.
  Future<void> _runSpeedTestWithServerSelection(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final isSpeedCheckSupported = ref
        .read(healthCheckProvider.select((s) => s.isSpeedTestModuleSupported));

    if (!isSpeedCheckSupported) {
      // If not supported, navigate to the external test page.
      context.pushNamed(RouteNamed.speedTestExternal);
      return;
    }

    // Show server selection if enabled and servers are available
    if (showServerSelectionDialog) {
      final servers = ref.read(healthCheckProvider).servers;
      if (servers.isNotEmpty) {
        final selected = await _showServerSelectionDialog(context, servers);
        if (selected == null) return; // User cancelled

        ref.read(healthCheckProvider.notifier).setSelectedServer(selected);
      }
    }

    // Run the speed test
    ref.read(healthCheckProvider.notifier).runHealthCheck(Module.speedtest);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthCheckState = ref.watch(healthCheckProvider);
    final latestPolledResult = healthCheckState.latestSpeedTest;
    // Determine the main content based on the current health check status.
    final mainContent = switch (healthCheckState.status) {
      HealthCheckStatus.idle => (showLatestOnIdle && latestPolledResult != null)
          ? (showInfoPanel
              ? Column(
                  children: [
                    _startButton(context, ref),
                    infoView(context, healthCheckState, latestPolledResult),
                  ],
                )
              : _startButton(context, ref, lastResult: latestPolledResult))
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
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Assets.images.speedtestPowered.image(
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
          if (showInfoPanel) ...[AppGap.xl(), Expanded(child: info)]
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        meter,
        if (showStepDescriptions) ...[
          AppGap.lg(),
          _descriptionCard(context, state.step),
        ],
        if (showInfoPanel) ...[AppGap.xl(), info]
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
                SizedBox(height: 48.0),
                _descriptionCard(context, state.step),
              ],
              if (isError) ...[
                AppGap.xl(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: errorView(context, state.errorCode),
                ),
              ] else if (showInfoPanel) ...[
                showStepDescriptions ? AppGap.xl() : SizedBox(height: 48.0),
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
          AppGap.xl(),
          errorView(context, state.errorCode),
        ] else if (showInfoPanel) ...[
          AppGap.xl(),
          info
        ]
      ],
    );
  }

  /// Builds the central animated meter gauge.
  Widget meterView(
      BuildContext context, HealthCheckState state, WidgetRef ref) {
    final result = state.result ?? SpeedTestUIModel.empty();

    // Calculate dynamic upper bound and markers based on historical data
    final upperBound = _calculateGaugeUpperBound(state);
    final isSmallGauge = (meterSize ?? 220) < 130;
    final markers = _generateMarkers(upperBound, isSmallGauge: isSmallGauge);

    // Format the live meter value for display.
    final formattedLiveValue = NetworkUtils.formatBitsWithUnit(
        (state.meterValue * 1024).toInt(),
        decimals: 1);

    final bandwidthValue = formattedLiveValue.value;
    final bandwidthUnit = formattedLiveValue.unit;

    final meterValueMbps = (state.meterValue / 1024);

    return Center(
      child: AppGauge(
        size: meterSize ?? context.colWidth(3),
        value: meterValueMbps, // Value must be in Mbps for the meter scale
        markers: markers, // Dynamic markers based on historical data
        centerBuilder: (context, value) {
          // The content inside the meter (e.g., live speed).
          final isSmall = (meterSize ?? 220) < 130;
          final titleText = switch (state.step) {
            HealthCheckStep.downloadBandwidth => loc(context).download,
            HealthCheckStep.uploadBandwidth => loc(context).upload,
            _ => '',
          };

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isSmall
                  ? Text(
                      titleText,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontSize: 10),
                    )
                  : AppText.titleSmall(titleText),
              isSmall
                  ? Text(
                      state.step == HealthCheckStep.latency
                          ? '—'
                          : bandwidthValue,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 24, height: 1.0),
                    )
                  : AppText.headlineMedium(
                      state.step == HealthCheckStep.latency
                          ? '—'
                          : bandwidthValue,
                    ),
              if (state.step != HealthCheckStep.latency)
                isSmall
                    ? Text(
                        '${bandwidthUnit}ps',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 10),
                      )
                    : AppText.bodyMedium('${bandwidthUnit}ps'),
            ],
          );
        },
        bottomBuilder: (context, value) {
          // The content below the meter (e.g., ping or "Test Again" button).
          if (state.status == HealthCheckStatus.complete) {
            if (!showResultSummary) {
              return IconButton(
                onPressed: () => _runSpeedTestWithServerSelection(context, ref),
                icon: Icon(Icons.replay,
                    color: Theme.of(context).colorScheme.primary),
                tooltip: loc(context).testAgain,
              );
            }
            // Show single-line result with tap-to-retry
            return InkWell(
              onTap: () => _runSpeedTestWithServerSelection(context, ref),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_downward,
                        size: 14, color: Theme.of(context).colorScheme.primary),
                    AppGap.xs(),
                    Flexible(
                      child: AppText.titleSmall(
                        result.downloadSpeed,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    AppGap.md(),
                    Icon(Icons.arrow_upward,
                        size: 14, color: Theme.of(context).colorScheme.primary),
                    AppGap.xs(),
                    Flexible(
                      child: AppText.titleSmall(
                        result.uploadSpeed,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    AppGap.md(),
                    Container(
                      width: 1,
                      height: 12,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    AppGap.md(),
                    Icon(Icons.replay,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            );
          } else {
            return pingView(context, state.step, result.latency);
          }
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
              child: AppBreathDot(
                color: Theme.of(context).colorScheme.primary,
                size: 10,
                animation: isLatencyStep
                    ? BreathDotAnimation.pulse
                    : BreathDotAnimation.none,
                period: const Duration(seconds: 1),
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
              Text(
                '$latency ms',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12, color: Theme.of(context).colorScheme.primary),
              ),
            ],
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
          const Divider(thickness: 1, height: 48.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              direction: Axis.vertical,
              children: [
                AppText.bodySmall(loc(context).dateAndTime),
                AppText.labelMedium(resultToDisplay.timestamp),
              ],
            ),
          ),
          AppGap.xxl(),
        ],
        // Show the main result card (Download/Upload) if not in the initial latency step.
        if (showLatestOnIdle || state.step != HealthCheckStep.latency)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _resultCard(context, resultToDisplay),
          ),
        if (showDetails) ...[
          const Divider(thickness: 1, height: 48.0),
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
      children.add(AppGap.sm());
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
            AppText.labelMedium(result.timestamp),
          ],
        ),
        AppGap.xxl(),
        Wrap(
          direction: Axis.vertical,
          children: [
            AppText.bodySmall(loc(context).serverId),
            AppText.labelMedium(result.serverId),
          ],
        ),
        AppGap.xxl(),
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
  Widget _startButton(BuildContext context, WidgetRef ref,
      {SpeedTestUIModel? lastResult}) {
    // Calculate dynamic upper bound and markers for idle state
    final healthCheckState = ref.watch(healthCheckProvider);
    final upperBound = _calculateGaugeUpperBound(healthCheckState);
    final markers = _generateMarkers(upperBound, isSmallGauge: true);

    return Container(
      alignment: Alignment.center,
      child: AppGauge(
        size: meterSize ?? 220,
        markers: markers, // Dynamic markers based on historical data
        // displayIndicatorValues: false, // assuming unsupported or default
        // indicatorPathStrokeWidth: 8,
        // markerRadius: 2,
        centerBuilder: (context, value) {
          // Button is always enabled - the method handles server selection logic
          final buttonColor = Theme.of(context).colorScheme.primary;

          return SizedBox(
            width: meterSize == null ? 102 : meterSize! / 2.0,
            height: meterSize == null ? 102 : meterSize! / 2.0,
            child: Material(
              shape: const CircleBorder(),
              color: buttonColor,
              child: InkWell(
                key: const Key('goBtn'),
                customBorder: const CircleBorder(),
                onTap: () => _runSpeedTestWithServerSelection(context, ref),
                child: Center(
                  child: AppText.bodyLarge(loc(context).go,
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
          );
        },
        bottomBuilder: (lastResult != null && !showInfoPanel)
            ? (context, value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_downward,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary),
                      AppGap.xs(),
                      AppText.titleSmall(lastResult.downloadSpeed),
                      AppGap.md(),
                      Container(
                        width: 1,
                        height: 12,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      AppGap.md(),
                      Icon(Icons.arrow_upward,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary),
                      AppGap.xs(),
                      AppText.titleSmall(lastResult.uploadSpeed),
                    ],
                  ),
                );
              }
            : null,
        value: 0,
      ),
    );
  }

  /// Builds the card that displays the final download and upload speeds.
  Widget _resultCard(BuildContext context, SpeedTestUIModel result) {
    final downloadBandWidthView = FittedBox(
      fit: BoxFit.scaleDown,
      child: AppText.displaySmall(result.downloadSpeed),
    );
    final uploadBandWidthView = FittedBox(
      fit: BoxFit.scaleDown,
      child: AppText.displaySmall(result.uploadSpeed),
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
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: AppIcon.font(AppFontIcons.arrowDownward,
                        // semanticLabel: 'download icon', // unsupported
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  Expanded(child: downloadBandWidthView),
                ],
              ),
              AppText.bodyExtraSmall('${result.downloadUnit}ps'),
            ],
          ),
        ),
        AppGap.xxl(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.bodyExtraSmall(loc(context).upload),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: AppIcon.font(AppFontIcons.arrowUpward,
                        // semanticLabel: 'upload icon', // unsupported
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

  /// Shows a dialog for server selection.
  /// Returns the selected server, or null if canceled.
  Future<HealthCheckServer?> _showServerSelectionDialog(
    BuildContext context,
    List<HealthCheckServer> servers,
  ) async {
    return showSimpleAppDialog<HealthCheckServer>(
      context,
      title: loc(context).selectServer,
      content: Builder(
        builder: (dialogContext) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: servers.map((server) {
                  return AppListTile(
                    key: Key('server_${server.serverID}'),
                    title: AppText.bodyMedium(server.serverName.isNotEmpty
                        ? server.serverName
                        : server.serverHostname),
                    onTap: () =>
                        Navigator.of(dialogContext, rootNavigator: true)
                            .pop(server),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
