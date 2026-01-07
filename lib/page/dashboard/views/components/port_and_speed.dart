import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/strategies/dashboard_layout_context.dart';
import 'package:privacy_gui/page/dashboard/views/components/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/dashboard/views/components/external_speed_test_links.dart';
import 'package:privacy_gui/page/dashboard/views/components/internal_speed_test_result.dart';
import 'package:privacy_gui/page/dashboard/views/components/port_status_widget.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Dashboard widget showing port connections and speed test results.
///
/// This component follows IoC (Inversion of Control) - configuration is
/// provided by the parent [DashboardLayoutStrategy] via [PortAndSpeedConfig],
/// rather than self-determining layout based on variant.
class DashboardHomePortAndSpeed extends ConsumerWidget {
  const DashboardHomePortAndSpeed({
    super.key,
    required this.config,
  });

  /// Configuration provided by the parent Strategy.
  final PortAndSpeedConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLoadingWrapper(
      loadingHeight: 250,
      builder: (context, ref) {
        final state = ref.watch(dashboardHomeProvider);
        return _buildLayout(context, ref, state);
      },
    );
  }

  Widget _buildLayout(
    BuildContext context,
    WidgetRef ref,
    DashboardHomeState state,
  ) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isVertical = config.direction == Axis.vertical;

    // Calculate minimum height based on config
    final minHeight = _calculateMinHeight(isVertical, hasLanPort);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize:
              config.portsHeight == null ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: isVertical
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.start,
          children: [
            SizedBox(
              height: config.portsHeight,
              child: Padding(
                padding: config.portsPadding,
                child: _buildPortsSection(context, state),
              ),
            ),
            if (config.showSpeedTest)
              SizedBox(
                width: double.infinity,
                height: config.speedTestHeight,
                child: _buildSpeedTestSection(context, ref, state, hasLanPort),
              ),
          ],
        ),
      ),
    );
  }

  double _calculateMinHeight(bool isVertical, bool hasLanPort) {
    if (isVertical) {
      return 360;
    }
    if (!hasLanPort) {
      return 256;
    }
    return 110;
  }

  Widget _buildPortsSection(
    BuildContext context,
    DashboardHomeState state,
  ) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isVertical = config.direction == Axis.vertical;

    // Build LAN port widgets
    final lanPorts = state.lanPortConnections.mapIndexed((index, e) {
      final port = PortStatusWidget(
        connection: e == 'None' ? null : e,
        label: loc(context).indexedPort(index + 1),
        isWan: false,
        hasLanPorts: hasLanPort,
      );
      return isVertical
          ? Padding(padding: const EdgeInsets.only(bottom: 36.0), child: port)
          : Expanded(child: port);
    }).toList();

    // Build WAN port widget
    final wanPort = PortStatusWidget(
      connection:
          state.wanPortConnection == 'None' ? null : state.wanPortConnection,
      label: loc(context).wan,
      isWan: true,
      hasLanPorts: hasLanPort,
    );

    // Arrange based on config direction
    if (isVertical) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...lanPorts,
          wanPort,
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...lanPorts,
          Expanded(child: wanPort),
        ],
      );
    }
  }

  Widget _buildSpeedTestSection(
    BuildContext context,
    WidgetRef ref,
    DashboardHomeState state,
    bool hasLanPort,
  ) {
    final isRemote = BuildConfig.isRemote();
    final isHealthCheckSupported =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;

    if (isHealthCheckSupported) {
      return hasLanPort
          ? Column(
              children: [
                const Divider(),
                const SpeedTestWidget(
                  showDetails: false,
                  showInfoPanel: true,
                  showStepDescriptions: false,
                  showLatestOnIdle: true,
                  layout: SpeedTestLayout.vertical,
                ),
                AppGap.xxl(),
              ],
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
