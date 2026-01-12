import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/external_speed_test_links.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/internal_speed_test_result.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
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
        DisplayMode.normal => 150,
        DisplayMode.expanded => 200,
      };

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    // Compact: Minimal view, perhaps just results without heavy UI
    // For now, reuse vertical layout but stripped down if possible,
    // or rely on responsive behavior of SpeedTestWidget if it exists.
    return _buildContent(context, ref, isCompact: true);
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
        if (isCompact) {
          // Compact view: simplified widget configuration
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SpeedTestWidget(
              showDetails: false,
              showInfoPanel: false, // Hide info panel in compact
              showStepDescriptions: false,
              showLatestOnIdle: true,
              layout: SpeedTestLayout.vertical,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SpeedTestWidget(
            showDetails: isExpanded, // Show details in expanded mode
            showInfoPanel: true,
            showStepDescriptions: false,
            showLatestOnIdle: true,
            layout: SpeedTestLayout.vertical,
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

// Keep old name as alias for backward compatibility
@Deprecated('Use CustomSpeedTest instead')
typedef DashboardSpeedTest = CustomSpeedTest;
