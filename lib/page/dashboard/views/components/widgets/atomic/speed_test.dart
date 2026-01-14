import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/external_speed_test_links.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/internal_speed_test_result.dart';
import 'package:privacy_gui/page/health_check/models/health_check_enum.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying speed test results.
///
/// For custom layout (Bento Grid) only.
class CustomSpeedTest extends DisplayModeConsumerWidget {
  const CustomSpeedTest({
    super.key,
    super.displayMode,
  });

  @override
  double getLoadingHeight(DisplayMode mode) => switch (mode) {
        DisplayMode.compact => 80,
        DisplayMode.normal => 200,
        DisplayMode.expanded => 300,
      };

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    // Compact: Minimal view with just download/upload stats + controls
    final healthCheckState = ref.watch(healthCheckProvider);
    final result = healthCheckState.latestSpeedTest ??
        healthCheckState.result ??
        SpeedTestUIModel.empty();
    final isRunning = healthCheckState.status == HealthCheckStatus.running;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        2, // Very tight vertical padding for 1-row
        AppSpacing.md,
        2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCompactStat(
                      context,
                      icon: Icons.arrow_downward,
                      value: result.downloadSpeed,
                      unit: result.downloadUnit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Container(
                      width: 1,
                      height: 20, // Reduced height
                      color: Theme.of(context).dividerColor,
                    ),
                    _buildCompactStat(
                      context,
                      icon: Icons.arrow_upward,
                      value: result.uploadSpeed,
                      unit: result.uploadUnit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              AppGap.xs(), // Reduced gap
              SizedBox(
                width: 28, // Reduced button size
                height: 28,
                child: isRunning
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : IconButton(
                        onPressed: () {
                          ref
                              .read(healthCheckProvider.notifier)
                              .runHealthCheck(Module.speedtest);
                        },
                        icon: const Icon(Icons.play_arrow, size: 20),
                        padding: EdgeInsets.zero,
                        color: Theme.of(context).colorScheme.primary,
                        tooltip: 'Start Speed Test',
                      ),
              ),
            ],
          ),
          // Removed gap for tighter layout
          if (healthCheckState.status != HealthCheckStatus.idle)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _getStatusText(context, healthCheckState),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(BuildContext context, HealthCheckState state) {
    if (state.status == HealthCheckStatus.running) {
      if (state.step == HealthCheckStep.latency) {
        return 'Measuring Latency...';
      }
      if (state.step == HealthCheckStep.downloadBandwidth) {
        return 'Downloading...';
      }
      if (state.step == HealthCheckStep.uploadBandwidth) {
        return 'Uploading...';
      }
      return 'Running...';
    }
    if (state.status == HealthCheckStatus.complete) {
      return 'Completed';
    }
    if (state.status == HealthCheckStatus.idle) {
      if (state.latestSpeedTest != null) {
        return 'Last run: ${state.latestSpeedTest!.timestamp}';
      }
      return 'Ready';
    }
    return '';
  }

  Widget _buildCompactStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
        AppGap.sm(),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(value),
            AppText.labelSmall(
              unit,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    return _buildContent(context, ref, isCompact: false);
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    return _buildContent(context, ref, isCompact: false, isExpanded: true);
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref, {
    bool isCompact = false,
    bool isExpanded = false,
  }) {
    final state = ref.watch(dashboardHomeProvider);
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isRemote = BuildConfig.isRemote();
    final isHealthCheckSupported =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;

    if (isHealthCheckSupported) {
      // Internal Speed Test
      if (hasLanPort) {
        return Padding(
          padding: EdgeInsets.all(isExpanded ? AppSpacing.lg : AppSpacing.sm),
          child: SpeedTestWidget(
            showDetails: isExpanded,
            showInfoPanel:
                isExpanded, // Hide info panel in Normal mode for cleaner look
            showStepDescriptions: false,
            // Show latest results in both Normal and Expanded modes
            showLatestOnIdle: true,
            layout: SpeedTestLayout.vertical,
            // Dynamic meter size: 240 for Normal (Vertical layout in 250px height), 220 for Expanded
            meterSize: isExpanded ? 220 : 240,
          ),
        );
      } else {
        return InternalSpeedTestResult(state: state);
      }
    }

    // External Links (Legacy/Remote)
    return Tooltip(
      message: loc(context).featureUnavailableInRemoteMode,
      child: Opacity(
        opacity: isRemote ? 0.5 : 1,
        child: AbsorbPointer(
          absorbing: isRemote,
          child: ExternalSpeedTestLinks(state: state),
        ),
      ),
    );
  }
}
