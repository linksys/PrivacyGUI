import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/views/components/shimmer.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/theme/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class DashboardHomePortAndSpeed extends ConsumerWidget {
  const DashboardHomePortAndSpeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final isLoading = ref
        .watch(deviceManagerProvider.select((value) => value.deviceList))
        .isEmpty;
    final horizontalLayout = state.isHorizontalLayout;
    final isSpeedCheckSupported = state.isHealthCheckSupported;
    return ResponsiveLayout(
        desktop: horizontalLayout
            ? _desktopHorizontal(context, ref, state, isLoading)
            : _desktopVertical(context, ref, state, isLoading),
        mobile: _mobile(context, ref, state, isLoading));
  }

  Widget _mobile(BuildContext context, WidgetRef ref, DashboardHomeState state,
      bool isLoading) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 150),
      child: ShimmerContainer(
        isLoading: isLoading,
        child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.big),
                  child: Row(
                    // mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...state.lanPortConnections
                          .mapIndexed((index, e) => Expanded(
                                child: _portWidget(
                                    context,
                                    e == 'None' ? null : e,
                                    loc(context).indexedPort(index + 1),
                                    false),
                              ))
                          .toList(),
                      Expanded(
                        child: _portWidget(context, state.wanPortConnection,
                            loc(context).wan, true),
                      )
                    ],
                  ),
                ),
                const AppGap.semiBig(),
                _speedCheckWidget(context, ref, state),
              ],
            )),
      ),
    );
  }

  Widget _desktopVertical(BuildContext context, WidgetRef ref,
      DashboardHomeState state, bool isLoading) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      child: ShimmerContainer(
        isLoading: isLoading,
        child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.big),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...state.lanPortConnections
                          .mapIndexed((index, e) => Padding(
                                padding: const EdgeInsets.only(bottom: 60.0),
                                child: _portWidget(
                                    context,
                                    e == 'None' ? null : e,
                                    loc(context).indexedPort(index + 1),
                                    false),
                              ))
                          .toList(),
                      _portWidget(context, state.wanPortConnection,
                          loc(context).wan, true)
                    ],
                  ),
                ),
                _speedCheckWidget(context, ref, state),
              ],
            )),
      ),
    );
  }

  Widget _desktopHorizontal(BuildContext context, WidgetRef ref,
      DashboardHomeState state, bool isLoading) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 110),
      child: ShimmerContainer(
        isLoading: isLoading,
        child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.big),
                  child: Row(
                    // mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...state.lanPortConnections
                          .mapIndexed((index, e) => Expanded(
                                child: _portWidget(
                                    context,
                                    e == 'None' ? null : e,
                                    loc(context).indexedPort(index + 1),
                                    false),
                              ))
                          .toList(),
                      Expanded(
                        child: _portWidget(context, state.wanPortConnection,
                            loc(context).wan, true),
                      )
                    ],
                  ),
                ),
                _speedCheckWidget(context, ref, state),
              ],
            )),
      ),
    );
  }

  Widget _speedCheckWidget(
      BuildContext context, WidgetRef ref, DashboardHomeState state) {
    final horizontalLayout = state.isHorizontalLayout;

    final dateTime = state.speedCheckTimestamp == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(state.speedCheckTimestamp!);
    final dateTimeStr = loc(context).speedCheckLatestTime(dateTime, dateTime);
    return state.isHealthCheckSupported
        ? Container(
            color: Theme.of(context).colorSchemeExt.surfaceContainerLow,
            padding: const EdgeInsets.all(48.0),
            child: Column(
              children: [
                AppText.bodySmall(dateTimeStr),
                const AppGap.semiBig(),
                ResponsiveLayout(
                    desktop: horizontalLayout
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _downloadSpeedResult(
                                    context,
                                    state.downloadResult?.value ?? '--',
                                    state.downloadResult?.unit),
                              ),
                              Expanded(
                                child: _uploadSpeedResult(
                                    context,
                                    state.uploadResult?.value ?? '--',
                                    state.uploadResult?.unit),
                              ),
                              Expanded(
                                child: _speedTestButton(context),
                              )
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                                _downloadSpeedResult(
                                    context,
                                    state.downloadResult?.value ?? '--',
                                    state.downloadResult?.unit),
                                const AppGap.semiBig(),
                                _uploadSpeedResult(
                                    context,
                                    state.uploadResult?.value ?? '--',
                                    state.uploadResult?.unit),
                                const AppGap.semiBig(),
                                _speedTestButton(context),
                              ]),
                    mobile: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _downloadSpeedResult(
                                    context,
                                    state.downloadResult?.value ?? '--',
                                    state.downloadResult?.unit,
                                    MainAxisAlignment.center),
                              ),
                              const AppGap.semiBig(),
                              Expanded(
                                child: _uploadSpeedResult(
                                    context,
                                    state.uploadResult?.value ?? '--',
                                    state.uploadResult?.unit,
                                    MainAxisAlignment.center),
                              ),
                            ],
                          ),
                          const AppGap.semiBig(),
                          _speedTestButton(context),
                        ]))
              ],
            ),
          )
        : const Center();
  }

  Widget _speedTestButton(BuildContext context) {
    return AppTextButton.noPadding(
      loc(context).speedTest,
      icon: LinksysIcons.networkCheck,
      onTap: () {
        context.pushNamed(RouteNamed.dashboardSpeedTest);
      },
    );
  }

  Widget _downloadSpeedResult(BuildContext context, String value, String? unit,
      [MainAxisAlignment alignment = MainAxisAlignment.start]) {
    return Row(
      mainAxisAlignment: alignment,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(
          LinksysIcons.arrowDownward,
          color: Theme.of(context).colorScheme.primary,
        ),
        AppText.titleLarge(value),
        if (unit != null) AppText.bodySmall('${unit}ps')
      ],
    );
  }

  Widget _uploadSpeedResult(BuildContext context, String value, String? unit,
      [MainAxisAlignment alignment = MainAxisAlignment.start]) {
    return Row(
      mainAxisAlignment: alignment,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(
          LinksysIcons.arrowUpward,
          color: Theme.of(context).colorScheme.primary,
        ),
        AppText.titleLarge(value),
        if (unit != null) AppText.bodySmall('${unit}ps')
      ],
    );
  }

  Widget _portWidget(
      BuildContext context, String? connection, String label, bool isWan) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              connection == null
                  ? LinksysIcons.circle
                  : LinksysIcons.checkCircleFilled,
              color: connection == null
                  ? Theme.of(context).colorScheme.surfaceVariant
                  : Theme.of(context).colorSchemeExt.green,
            ),
            const AppGap.semiSmall(),
            AppText.labelMedium(label),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture(
            connection == null
                ? CustomTheme.of(context).images.imgPortOff
                : CustomTheme.of(context).images.imgPortOn,
            width: 40,
            height: 40,
          ),
        ),
        if (connection != null) AppText.bodySmall(connection),
        if (isWan) AppText.labelMedium(loc(context).internet),
        Container(
          constraints: const BoxConstraints(maxWidth: 120),
          child: isWan
              ? Divider(
                  height: 8,
                  indent: 24,
                  endIndent: 24,
                  color: Theme.of(context).colorSchemeExt.orange)
              : null,
        ),
      ],
    );
  }
}
