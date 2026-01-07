import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_layout.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';
import 'package:privacy_gui/page/dashboard/views/components/port_status_widget.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:privacy_gui/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/url_helper/url_helper_web.dart';
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
          mainAxisSize: MainAxisSize.min,
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
          : _SpeedCheckResultWidget(state: state);
    }

    return Tooltip(
      message: loc(context).featureUnavailableInRemoteMode,
      child: Opacity(
        opacity: isRemote ? 0.5 : 1,
        child: AbsorbPointer(
          absorbing: isRemote,
          child: _ExternalSpeedTestWidget(state: state),
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

  const _LayoutConfig({
    required this.minHeight,
    this.portsHeight,
    this.speedTestHeight,
    required this.portsPadding,
    this.mainAxisAlignment = MainAxisAlignment.start,
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
        );
    }
  }
}

/// Widget showing speed check results (internal speed test).
class _SpeedCheckResultWidget extends ConsumerWidget {
  final DashboardHomeState state;

  const _SpeedCheckResultWidget({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speedTest = ref.watch(healthCheckProvider);
    final horizontalLayout = state.isHorizontalLayout;
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;

    final dateTime = speedTest.latestSpeedTest?.timestampEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            speedTest.latestSpeedTest!.timestampEpoch!);
    final isLegacy =
        dateTime == null || DateTime.now().difference(dateTime).inDays > 1;
    final dateTimeStr =
        dateTime == null ? '' : loc(context).formalDateTime(dateTime, dateTime);

    final downloadResult = _SpeedResultWidget(
      value: speedTest.latestSpeedTest?.downloadSpeed ?? '--',
      unit: speedTest.latestSpeedTest?.downloadUnit,
      isLegacy: isLegacy,
      isDownload: true,
    );

    final uploadResult = _SpeedResultWidget(
      value: speedTest.latestSpeedTest?.uploadSpeed ?? '--',
      unit: speedTest.latestSpeedTest?.uploadUnit,
      isLegacy: isLegacy,
      isDownload: false,
    );

    final speedTestButton = SizedBox(
      height: 40,
      child: AppButton(
        label: loc(context).speedTextTileStart,
        onTap: () => context.pushNamed(RouteNamed.dashboardSpeedTest),
      ),
    );

    return Container(
      key: const ValueKey('speedCheck'),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: _buildSpeedLayout(
          context,
          dateTimeStr,
          downloadResult,
          uploadResult,
          speedTestButton,
          horizontalLayout,
          hasLanPort,
        ),
      ),
    );
  }

  Widget _buildSpeedLayout(
    BuildContext context,
    String dateTimeStr,
    Widget downloadResult,
    Widget uploadResult,
    Widget speedTestButton,
    bool horizontalLayout,
    bool hasLanPort,
  ) {
    // No LAN ports layout
    if (!hasLanPort) {
      return Column(
        children: [
          if (dateTimeStr.isNotEmpty) ...[
            AppText.bodySmall(dateTimeStr),
            AppGap.sm(),
          ],
          Row(
            spacing: AppSpacing.lg,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [downloadResult, uploadResult],
          ),
          AppGap.lg(),
          speedTestButton,
        ],
      );
    }

    // Mobile or horizontal layout
    if (context.isMobileLayout || horizontalLayout) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateTimeStr.isNotEmpty) ...[
                  AppText.bodySmall(dateTimeStr),
                  AppGap.sm(),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: downloadResult),
                    Expanded(child: uploadResult),
                  ],
                ),
              ],
            ),
          ),
          speedTestButton,
        ],
      );
    }

    // Vertical layout
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (dateTimeStr.isNotEmpty) ...[
          AppText.bodySmall(dateTimeStr),
          AppGap.sm(),
        ],
        downloadResult,
        AppGap.xxl(),
        uploadResult,
        AppGap.lg(),
        speedTestButton,
      ],
    );
  }
}

/// Widget showing a single speed result (download or upload).
class _SpeedResultWidget extends StatelessWidget {
  final String value;
  final String? unit;
  final bool isLegacy;
  final bool isDownload;

  const _SpeedResultWidget({
    required this.value,
    required this.unit,
    required this.isLegacy,
    required this.isDownload,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLegacy
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.primary;
    final textColor = isLegacy
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.onSurface;

    return Opacity(
      opacity: isLegacy ? 0.6 : 1,
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          AppIcon.font(
            isDownload ? AppFontIcons.arrowDownward : AppFontIcons.arrowUpward,
            color: color,
          ),
          AppText.titleLarge(value, color: textColor),
          if (unit != null && unit!.isNotEmpty) ...[
            AppGap.xs(),
            AppText.bodySmall('${unit}ps', color: textColor),
          ],
        ],
      ),
    );
  }
}

/// Widget for external speed test links.
class _ExternalSpeedTestWidget extends StatelessWidget {
  final DashboardHomeState state;

  const _ExternalSpeedTestWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    final horizontalLayout = state.isHorizontalLayout;
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isVerticalDesktop =
        hasLanPort && !horizontalLayout && !context.isMobileLayout;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(12).copyWith(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, horizontalLayout, hasLanPort),
          AppGap.sm(),
          Flexible(
            child: isVerticalDesktop
                ? _buildVerticalButtons(context)
                : _buildHorizontalButtons(context),
          ),
          AppGap.sm(),
          AppText.bodyExtraSmall(loc(context).speedTestExternalOthers),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, bool horizontalLayout, bool hasLanPort) {
    final speedTitle = AppText.titleMedium(loc(context).speedTextTileStart);
    final infoIcon = InkWell(
      child: AppIcon.font(
        AppFontIcons.infoCircle,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => openUrl('https://support.linksys.com/kb/article/79-en/'),
    );
    final speedDesc =
        AppText.labelSmall(loc(context).speedTestExternalTileLabel);

    final showRowHeader =
        context.isMobileLayout || (hasLanPort && horizontalLayout);

    if (showRowHeader) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: speedTitle),
          infoIcon,
          speedDesc,
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: speedTitle),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            infoIcon,
            AppGap.sm(),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: speedDesc,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalButtons(BuildContext context) {
    return SizedBox(
      width: 144,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          AppButton(
            label: loc(context).speedTestExternalTileCloudFlare,
            onTap: () => openUrl('https://speed.cloudflare.com/'),
          ),
          AppButton(
            label: loc(context).speedTestExternalTileFast,
            onTap: () => openUrl('https://www.fast.com'),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: AppSpacing.lg,
      children: [
        Expanded(
          child: AppButton(
            label: loc(context).speedTestExternalTileCloudFlare,
            onTap: () => openUrl('https://speed.cloudflare.com/'),
          ),
        ),
        Expanded(
          child: AppButton(
            label: loc(context).speedTestExternalTileFast,
            onTap: () => openUrl('https://www.fast.com'),
          ),
        ),
      ],
    );
  }
}
