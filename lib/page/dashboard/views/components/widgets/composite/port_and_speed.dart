import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/strategies/dashboard_layout_context.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/external_speed_test_links.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/internal_speed_test_result.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/port_status_widget.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Dashboard widget showing port connections and speed test results.
///
/// This component follows IoC (Inversion of Control) - configuration is
/// provided by the parent [DashboardLayoutStrategy] via [PortAndSpeedConfig],
/// rather than self-determining layout based on variant.
///
/// Supports three display modes:
/// - [DisplayMode.compact]: Minimal port status only
/// - [DisplayMode.normal]: Ports with speed test
/// - [DisplayMode.expanded]: Detailed port and speed info
class DashboardHomePortAndSpeed extends ConsumerWidget {
  const DashboardHomePortAndSpeed({
    super.key,
    required this.config,
    this.displayMode = DisplayMode.normal,
    this.useAppCard = true,
  });

  /// Configuration provided by the parent Strategy.
  final PortAndSpeedConfig config;

  /// The display mode for this widget
  final DisplayMode displayMode;

  /// Whether to wrap the content in an AppCard (default true).
  final bool useAppCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLoadingWrapper(
      loadingHeight: _getLoadingHeight(),
      builder: (context, ref) {
        final state = ref.watch(dashboardHomeProvider);
        return _buildLayout(context, ref, state);
      },
    );
  }

  double _getLoadingHeight() {
    return switch (displayMode) {
      DisplayMode.compact => 150,
      DisplayMode.normal => 250,
      DisplayMode.expanded => 350,
    };
  }

  Widget _buildLayout(
    BuildContext context,
    WidgetRef ref,
    DashboardHomeState state,
  ) {
    if (displayMode == DisplayMode.compact) {
      return _buildCompactView(context, ref, state);
    }

    // Bypass LayoutBuilder if direction is explicit (fixes IntrinsicHeight errors in legacy layouts)
    if (config.direction != null) {
      return displayMode == DisplayMode.normal
          ? _buildNormalView(
              context, ref, state, config.direction!, const BoxConstraints())
          : _buildExpandedView(context, ref, state, config.direction!);
    }

    // For Normal and Expanded, we might need auto-direction logic
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine direction:
        // 1. Explicit config
        // 2. Auto-detect based on width (breakpoint at 6 columns)
        // Min columns updated to 4.
        // 4-5 cols -> Vertical.
        // 6+ cols -> Horizontal.
        final Axis direction = constraints.maxWidth < context.colWidth(6)
            ? Axis.vertical
            : Axis.horizontal;

        return displayMode == DisplayMode.normal
            ? _buildNormalView(context, ref, state, direction, constraints)
            : _buildExpandedView(context, ref, state, direction);
      },
    );
  }

  /// Compact view: Port status icons only, no speed test
  Widget _buildCompactView(
    BuildContext context,
    WidgetRef ref,
    DashboardHomeState state,
  ) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // LAN ports in compact mode
        ...state.lanPortConnections.mapIndexed((index, e) {
          final isConnected = e != 'None';
          return _compactPortIcon(
            context,
            label: 'LAN${index + 1}',
            isConnected: isConnected,
            isWan: false,
          );
        }),
        // WAN port
        _compactPortIcon(
          context,
          label: loc(context).wan,
          isConnected: state.wanPortConnection != 'None',
          isWan: true,
        ),
      ],
    );

    if (useAppCard) {
      return AppCard(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: content,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: content,
    );
  }

  Widget _compactPortIcon(
    BuildContext context, {
    required String label,
    required bool isConnected,
    required bool isWan,
  }) {
    return Tooltip(
      message: '$label: ${isConnected ? "Connected" : "Disconnected"}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWan ? Icons.public : Icons.lan,
            size: 20,
            color: isConnected
                ? Theme.of(context)
                        .extension<AppDesignTheme>()
                        ?.colorScheme
                        .semanticSuccess ??
                    Colors.green
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppGap.xs(),
          AppText.labelSmall(
            label,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  /// Normal view: Ports with speed test (existing implementation)
  Widget _buildNormalView(
    BuildContext context,
    WidgetRef ref,
    DashboardHomeState state,
    Axis direction,
    BoxConstraints constraints,
  ) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isVertical = direction == Axis.vertical;

    // Calculate minimum height based on config
    // If auto-layout, we rely on intrinsic sizing primarily, but can keep minHeight for consistency if needed.
    // final minHeight = _calculateMinHeight(isVertical, hasLanPort);

    final content = Container(
      width: double.infinity,
      // constraints: BoxConstraints(minHeight: minHeight),
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
              child: _buildPortsSection(context, state, direction),
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
    );

    if (useAppCard) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: content,
      );
    }
    return content;
  }

  /// Expanded view: Detailed port and speed info
  Widget _buildExpandedView(
    BuildContext context,
    WidgetRef ref,
    DashboardHomeState state,
    Axis direction,
  ) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;

    final content = Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expanded port section with more details
          Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleSmall(loc(context).ports),
                AppGap.lg(),
                _buildPortsSection(context, state, direction),
              ],
            ),
          ),
          if (config.showSpeedTest) ...[
            const Divider(),
            Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: _buildSpeedTestSection(context, ref, state, hasLanPort),
            ),
          ],
        ],
      ),
    );

    if (useAppCard) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: content,
      );
    }
    return content;
  }

  Widget _buildPortsSection(
    BuildContext context,
    DashboardHomeState state,
    Axis direction,
  ) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isVertical = direction == Axis.vertical;

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
