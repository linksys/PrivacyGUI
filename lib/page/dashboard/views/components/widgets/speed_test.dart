import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/external_speed_test_links.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/internal_speed_test_result.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying speed test results.
///
/// Extracted from [DashboardHomePortAndSpeed] for Bento Grid atomic usage.
class DashboardSpeedTest extends ConsumerWidget {
  const DashboardSpeedTest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLoadingWrapper(
      loadingHeight: 150,
      builder: (context, ref) => _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isRemote = BuildConfig.isRemote();
    final isHealthCheckSupported =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;

    if (isHealthCheckSupported) {
      return hasLanPort
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: SpeedTestWidget(
                showDetails: false,
                showInfoPanel: true,
                showStepDescriptions: false,
                showLatestOnIdle: true,
                layout: SpeedTestLayout.vertical,
              ),
            )
          : InternalSpeedTestResult(state: state);
    }

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
