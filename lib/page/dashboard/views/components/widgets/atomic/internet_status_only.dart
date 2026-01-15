import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/data/providers/node_internet_status_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying internet connection status.
///
/// For custom layout (Bento Grid) only.
/// Shows: Online/Offline indicator, geolocation (normal/expanded).
/// Expanded mode features animated data flow visualization.
class CustomInternetStatus extends DisplayModeConsumerStatefulWidget {
  const CustomInternetStatus({
    super.key,
    super.displayMode,
  });

  @override
  ConsumerState<CustomInternetStatus> createState() =>
      _CustomInternetStatusState();
}

class _CustomInternetStatusState extends ConsumerState<CustomInternetStatus>
    with DisplayModeStateMixin<CustomInternetStatus>, TickerProviderStateMixin {
  late AnimationController _flowController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  double getLoadingHeight(DisplayMode mode) => switch (mode) {
        DisplayMode.compact => 80,
        DisplayMode.normal => 100,
        DisplayMode.expanded => 180,
      };

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    final isOnline = _isOnline(ref);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusIndicator(context, isOnline),
              AppGap.sm(),
              AppText.labelLarge(
                isOnline
                    ? loc(context).internetOnline
                    : loc(context).internetOffline,
              ),
            ],
          ),
          if (!Utils.isMobilePlatform()) _refreshButton(context, ref),
        ],
      ),
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    final isOnline = _isOnline(ref);
    final geolocationState = ref.watch(geolocationProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          _statusIndicator(context, isOnline),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.labelLarge(
                  isOnline
                      ? loc(context).internetOnline
                      : loc(context).internetOffline,
                ),
                if (geolocationState.value?.name.isNotEmpty == true) ...[
                  AppGap.xs(),
                  SharedWidgets.geolocationWidget(
                    context,
                    geolocationState.value?.name ?? '',
                    geolocationState.value?.displayLocationText ?? '',
                  ),
                ],
              ],
            ),
          ),
          if (!Utils.isMobilePlatform()) _refreshButton(context, ref),
        ],
      ),
    );
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    final isOnline = _isOnline(ref);
    final geolocationState = ref.watch(geolocationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Data Flow Visualization
          Expanded(
            child: Center(
              child: _DataFlowWidget(
                isOnline: isOnline,
                animation: _flowController,
                primaryColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                secondaryColor: colorScheme.tertiary,
                masterIcon: ref.watch(dashboardHomeProvider).masterIcon,
              ),
            ),
          ),
          AppGap.md(),
          // Status Text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusIndicator(context, isOnline),
              AppGap.sm(),
              AppText.titleMedium(
                isOnline
                    ? loc(context).internetOnline
                    : loc(context).internetOffline,
              ),
            ],
          ),
          // Geolocation
          if (geolocationState.value?.name.isNotEmpty == true) ...[
            AppGap.sm(),
            SharedWidgets.geolocationWidget(
              context,
              geolocationState.value?.name ?? '',
              geolocationState.value?.displayLocationText ?? '',
            ),
          ],
          AppGap.md(),
          // Refresh button centered
          if (!Utils.isMobilePlatform()) _refreshButton(context, ref),
        ],
      ),
    );
  }

  // Helper methods
  bool _isOnline(WidgetRef ref) =>
      ref.watch(internetStatusProvider) == InternetStatus.online;

  Widget _statusIndicator(BuildContext context, bool isOnline) => Icon(
        Icons.circle,
        color: isOnline
            ? Theme.of(context).extension<AppColorScheme>()!.semanticSuccess
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        size: 12.0,
      );

  Widget _refreshButton(BuildContext context, WidgetRef ref) =>
      AnimatedRefreshContainer(
        builder: (controller) => AppIconButton(
          icon: AppIcon.font(
            AppFontIcons.refresh,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          onTap: () {
            controller.repeat();
            ref.read(pollingProvider.notifier).forcePolling().then((_) {
              controller.stop();
            });
          },
        ),
      );
}

/// Clean data flow widget using Flutter Icons
class _DataFlowWidget extends StatelessWidget {
  final bool isOnline;
  final Animation<double> animation;
  final Color primaryColor;
  final Color secondaryColor;
  final Color inactiveColor;
  final String masterIcon;

  const _DataFlowWidget({
    required this.isOnline,
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.inactiveColor,
    required this.masterIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Router Image
        SharedWidgets.resolveRouterImage(
          context,
          masterIcon,
          size: 48,
        ),
        // Animated connection
        SizedBox(
          width: 120,
          child: isOnline ? _buildAnimatedDots() : _buildOfflineLine(),
        ),
        // Cloud Icon - with gradient and glow
        isOnline
            ? Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: secondaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.cloud,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              )
            : Icon(
                Icons.cloud_outlined,
                size: 48,
                color: inactiveColor,
              ),
      ],
    );
  }

  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            // Staggered animation for each dot
            final dotProgress = (animation.value + index * 0.33) % 1.0;
            final opacity = _calculateOpacity(dotProgress);
            final scale = 0.6 + (0.4 * _calculateScale(dotProgress));

            // Gradient color based on position (0=primary, 2=secondary)
            final gradientRatio = index / 2.0;
            final dotColor =
                Color.lerp(primaryColor, secondaryColor, gradientRatio)!;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      dotColor.withValues(alpha: opacity),
                      dotColor.withValues(alpha: opacity * 0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withValues(alpha: opacity * 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildOfflineLine() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dashed line
        Container(
          height: 2,
          color: inactiveColor,
        ),
        // X mark
        Icon(
          Icons.close,
          size: 24,
          color: inactiveColor,
        ),
      ],
    );
  }

  double _calculateOpacity(double progress) {
    // Wave-like opacity: peaks in the middle
    return 0.3 + 0.7 * (1 - (2 * progress - 1).abs());
  }

  double _calculateScale(double progress) {
    // Subtle pulse effect
    return 0.8 + 0.2 * (1 - (2 * progress - 1).abs());
  }
}
