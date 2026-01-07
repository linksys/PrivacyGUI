import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_layout.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/views/components/external_speed_test_links.dart';
import 'package:privacy_gui/page/dashboard/views/components/internal_speed_test_result.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';
import 'package:privacy_gui/page/dashboard/views/components/port_status_widget.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Dashboard widget showing port connections and speed test results.
class DashboardHomePortAndSpeed extends ConsumerWidget {
  const DashboardHomePortAndSpeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final isLoading =
        (ref.watch(pollingProvider).value?.isReady ?? false) == false;
    final horizontalLayout = state.isHorizontalLayout;
    final hasLanPort = state.lanPortConnections.isNotEmpty;

    if (isLoading) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: double.infinity,
          height: 250,
          child: const LoadingTile(),
        ),
      );
    }

    // Determine layout variant
    final layoutVariant = context.isMobileLayout
        ? DashboardLayoutVariant.mobile
        : context.isTabletLayout
            ? DashboardLayoutVariant.tablet
            : !hasLanPort
                ? DashboardLayoutVariant.desktopNoLanPorts
                : horizontalLayout
                    ? DashboardLayoutVariant.desktopHorizontal
                    : DashboardLayoutVariant.desktopVertical;

    return _buildLayout(context, ref, state, layoutVariant);
  }

  Widget _buildLayout(
    BuildContext context,
    WidgetRef ref,
    DashboardHomeState state,
    DashboardLayoutVariant variant,
  ) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;

    // Configure layout parameters based on variant
    final config = _LayoutConfig.fromVariant(variant, hasLanPort);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: config.minHeight),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: config.mainAxisSize,
          mainAxisAlignment: config.mainAxisAlignment,
          children: [
            SizedBox(
              height: config.portsHeight,
              child: Padding(
                padding: config.portsPadding,
                child: _buildPortsSection(context, state, variant),
              ),
            ),
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

  Widget _buildPortsSection(
    BuildContext context,
    DashboardHomeState state,
    DashboardLayoutVariant variant,
  ) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isVertical = variant == DashboardLayoutVariant.desktopVertical;

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

    // Arrange based on layout variant
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

/// Configuration for different layout variants.
class _LayoutConfig {
  final double minHeight;
  final double? portsHeight;
  final double? speedTestHeight;
  final EdgeInsets portsPadding;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  const _LayoutConfig({
    required this.minHeight,
    this.portsHeight,
    this.speedTestHeight,
    required this.portsPadding,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  factory _LayoutConfig.fromVariant(
      DashboardLayoutVariant variant, bool hasLanPort) {
    switch (variant) {
      case DashboardLayoutVariant.mobile:
        return _LayoutConfig(
          minHeight: 0,
          portsHeight: null,
          speedTestHeight: null,
          portsPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxl,
          ),
          mainAxisSize: MainAxisSize.min,
        );
      case DashboardLayoutVariant.tablet:
        return _LayoutConfig(
          minHeight: 0,
          portsHeight: null, // Flexible
          speedTestHeight: null, // Flexible
          portsPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md, // Tighter than mobile?
          ),
          mainAxisSize: MainAxisSize.min,
        );
      case DashboardLayoutVariant.desktopHorizontal:
        return _LayoutConfig(
          minHeight: 110,
          portsHeight: 224,
          speedTestHeight: 112,
          portsPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxxl,
          ),
        );
      case DashboardLayoutVariant.desktopVertical:
        return _LayoutConfig(
          minHeight: 360,
          portsHeight: 752,
          speedTestHeight: null,
          portsPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxl,
          ),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        );
      case DashboardLayoutVariant.desktopNoLanPorts:
        return _LayoutConfig(
          minHeight: 256,
          portsHeight: 120,
          speedTestHeight: 132,
          portsPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          mainAxisSize: MainAxisSize.min,
        );
    }
  }
}
