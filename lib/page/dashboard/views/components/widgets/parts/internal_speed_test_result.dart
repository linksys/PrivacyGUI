import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Widget showing speed check results (internal speed test).
class InternalSpeedTestResult extends ConsumerWidget {
  final DashboardHomeState state;

  const InternalSpeedTestResult({super.key, required this.state});

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
