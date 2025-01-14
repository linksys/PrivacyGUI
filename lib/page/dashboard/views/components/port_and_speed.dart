import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
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
    final wanStatus = ref.watch(nodeWanStatusProvider);
    final isOnline = wanStatus == NodeWANStatus.online;
    final hasLanPort = state.lanPortConnections.isNotEmpty;

    return ResponsiveLayout(
        desktop: !hasLanPort
            ? _desktopNoLanPorts(context, ref, state, isOnline, isLoading)
            : horizontalLayout
                ? _desktopHorizontal(context, ref, state, isOnline, isLoading)
                : _desktopVertical(context, ref, state, isOnline, isLoading),
        mobile: _mobile(context, ref, state, isOnline, isLoading));
  }

  Widget _mobile(BuildContext context, WidgetRef ref, DashboardHomeState state,
      bool isOnline, bool isLoading) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    return Container(
      width: double.infinity,
      constraints:
          BoxConstraints(minHeight: !state.isHealthCheckSupported ? 240 : 400),
      child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.medium,
                  vertical: Spacing.large3,
                ),
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
                                  false,
                                  hasLanPort),
                            ))
                        .toList(),
                    Expanded(
                      child: _portWidget(
                          context,
                          state.wanPortConnection == 'None'
                              ? null
                              : state.wanPortConnection,
                          loc(context).wan,
                          true,
                          hasLanPort),
                    )
                  ],
                ),
              ),
              // const AppGap.large2(),
              _speedCheckWidget(context, ref, state),
            ],
          )),
    );
  }

  Widget _desktopVertical(BuildContext context, WidgetRef ref,
      DashboardHomeState state, bool isOnline, bool isLoading) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
          minWidth: 150, minHeight: !state.isHealthCheckSupported ? 360 : 520),
      child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: !state.isHealthCheckSupported
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 752,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.small2,
                    vertical: Spacing.large2,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...state.lanPortConnections
                          .mapIndexed((index, e) => Padding(
                                padding: const EdgeInsets.only(bottom: 36.0),
                                child: _portWidget(
                                    context,
                                    e == 'None' ? null : e,
                                    loc(context).indexedPort(index + 1),
                                    false,
                                    hasLanPort),
                              ))
                          .toList(),
                      _portWidget(
                          context,
                          state.wanPortConnection == 'None'
                              ? null
                              : state.wanPortConnection,
                          loc(context).wan,
                          true,
                          hasLanPort),
                    ],
                  ),
                ),
              ),
              SizedBox(
                  width: double.infinity,
                  height: 304,
                  child: _speedCheckWidget(context, ref, state)),
            ],
          )),
    );
  }

  Widget _desktopHorizontal(BuildContext context, WidgetRef ref,
      DashboardHomeState state, bool isOnline, bool isLoading) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 110),
      child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 224,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.small2,
                    vertical: Spacing.large3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...state.lanPortConnections
                          .mapIndexed((index, e) => Expanded(
                                child: _portWidget(
                                    context,
                                    e == 'None' ? null : e,
                                    loc(context).indexedPort(index + 1),
                                    false,
                                    hasLanPort),
                              ))
                          .toList(),
                      Expanded(
                        child: _portWidget(
                            context,
                            state.wanPortConnection == 'None'
                                ? null
                                : state.wanPortConnection,
                            loc(context).wan,
                            true,
                            hasLanPort),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                  height: 112, child: _speedCheckWidget(context, ref, state)),
            ],
          )),
    );
  }

  Widget _desktopNoLanPorts(BuildContext context, WidgetRef ref,
      DashboardHomeState state, bool isOnline, bool isLoading) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 256),
      child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 124,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.small2,
                    vertical: Spacing.large1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...state.lanPortConnections
                          .mapIndexed((index, e) => Expanded(
                                child: _portWidget(
                                    context,
                                    e == 'None' ? null : e,
                                    loc(context).indexedPort(index + 1),
                                    false,
                                    hasLanPort),
                              ))
                          .toList(),
                      Expanded(
                        child: _portWidget(
                            context,
                            state.wanPortConnection == 'None'
                                ? null
                                : state.wanPortConnection,
                            loc(context).wan,
                            true,
                            hasLanPort),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                  height: 132, child: _speedCheckWidget(context, ref, state)),
            ],
          )),
    );
  }

  Widget _speedCheckWidget(
      BuildContext context, WidgetRef ref, DashboardHomeState state) {
    final horizontalLayout = state.isHorizontalLayout;
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;
    final dateTime = state.speedCheckTimestamp == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(state.speedCheckTimestamp!);
    final isLegacy = dateTime == null
        ? true
        : DateTime.now().difference(dateTime).inDays > 1;
    final dateTimeStr =
        dateTime == null ? '' : loc(context).formalDateTime(dateTime, dateTime);
    return Container(
      key: const ValueKey('speedCheck'),
      color: Theme.of(context).colorSchemeExt.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.large4),
      child: Column(
        crossAxisAlignment: horizontalLayout
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          ResponsiveLayout(
            desktop: !hasLanPort
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: Spacing.large1),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (dateTimeStr.isNotEmpty) ...[
                                AppText.bodySmall(dateTimeStr),
                                const AppGap.small2(),
                              ],
                              Opacity(
                                opacity: isLegacy ? 0.6 : 1,
                                child: _downloadSpeedResult(
                                    context,
                                    state.downloadResult?.value ?? '--',
                                    state.downloadResult?.unit,
                                    isLegacy),
                              ),
                              Opacity(
                                opacity: isLegacy ? 0.6 : 1,
                                child: _uploadSpeedResult(
                                    context,
                                    state.uploadResult?.value ?? '--',
                                    state.uploadResult?.unit,
                                    isLegacy),
                              )
                            ],
                          ),
                        ),
                        _speedTestButton(context, state)
                      ],
                    ),
                  )
                : horizontalLayout
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: Spacing.large2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (dateTimeStr.isNotEmpty) ...[
                                    AppText.bodySmall(dateTimeStr),
                                    const AppGap.small2(),
                                  ],
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Opacity(
                                          opacity: isLegacy ? 0.6 : 1,
                                          child: _downloadSpeedResult(
                                              context,
                                              state.downloadResult?.value ??
                                                  '--',
                                              state.downloadResult?.unit,
                                              isLegacy),
                                        ),
                                      ),
                                      Expanded(
                                        child: Opacity(
                                          opacity: isLegacy ? 0.6 : 1,
                                          child: _uploadSpeedResult(
                                              context,
                                              state.uploadResult?.value ?? '--',
                                              state.uploadResult?.unit,
                                              isLegacy),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            _speedTestButton(context, state)
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: Spacing.large2),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (dateTimeStr.isNotEmpty) ...[
                                AppText.bodySmall(dateTimeStr),
                                const AppGap.small2(),
                              ],
                              _downloadSpeedResult(
                                  context,
                                  state.downloadResult?.value ?? '--',
                                  state.downloadResult?.unit,
                                  isLegacy),
                              const AppGap.large2(),
                              _uploadSpeedResult(
                                  context,
                                  state.uploadResult?.value ?? '--',
                                  state.uploadResult?.unit,
                                  isLegacy),
                              const AppGap.large2(),
                              _speedTestButton(context, state),
                            ]),
                      ),
            mobile: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.large2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bodySmall(dateTimeStr),
                        const AppGap.small2(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Opacity(
                                opacity: isLegacy ? 0.6 : 1,
                                child: _downloadSpeedResult(
                                    context,
                                    state.downloadResult?.value ?? '--',
                                    state.downloadResult?.unit,
                                    isLegacy),
                              ),
                            ),
                            Expanded(
                              child: Opacity(
                                opacity: isLegacy ? 0.6 : 1,
                                child: _uploadSpeedResult(
                                    context,
                                    state.uploadResult?.value ?? '--',
                                    state.uploadResult?.unit,
                                    isLegacy),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  _speedTestButton(context, state)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _speedTestButton(BuildContext context, DashboardHomeState state) {
    return InkResponse(
      onTap: () {
        if (state.isHealthCheckSupported) {
          context.pushNamed(RouteNamed.dashboardSpeedTest);
        } else {
          context.pushNamed(RouteNamed.speedTestExternal);
        }
      },
      child: SvgPicture(
        CustomTheme.of(context).images.btnCheckSpeeds,
        width: 64,
        height: 64,
      ),
    );
  }

  Widget _downloadSpeedResult(
      BuildContext context, String value, String? unit, bool isLegacy,
      [WrapAlignment alignment = WrapAlignment.start]) {
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Icon(
          LinksysIcons.arrowDownward,
          semanticLabel: 'arrow Downward',
          color: isLegacy
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.primary,
        ),
        AppText.titleLarge(
          value,
          color: isLegacy
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.onSurface,
        ),
        if (unit != null && unit.isNotEmpty) ...[
          const AppGap.small1(),
          AppText.bodySmall(
            '${unit}ps',
            color: isLegacy
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).colorScheme.onSurface,
          )
        ]
      ],
    );
  }

  Widget _uploadSpeedResult(
      BuildContext context, String value, String? unit, bool isLegacy,
      [WrapAlignment alignment = WrapAlignment.start]) {
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Icon(
          LinksysIcons.arrowUpward,
          semanticLabel: 'arrow upward',
          color: isLegacy
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.primary,
        ),
        AppText.titleLarge(
          value,
          color: isLegacy
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.onSurface,
        ),
        if (unit != null && unit.isNotEmpty) ...[
          const AppGap.small1(),
          AppText.bodySmall(
            '${unit}ps',
            color: isLegacy
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).colorScheme.onSurface,
          )
        ]
      ],
    );
  }

  Widget _portWidget(BuildContext context, String? connection, String label,
      bool isWan, bool hasLanPorts) {
    final isMobile = ResponsiveLayout.isMobileLayout(context);
    final portLabel = [
      Icon(
        connection == null
            ? LinksysIcons.circle
            : LinksysIcons.checkCircleFilled,
        color: connection == null
            ? Theme.of(context).colorScheme.surfaceVariant
            : Theme.of(context).colorSchemeExt.green,
        semanticLabel: 'port icon',
      ),
      if (hasLanPorts) ...[
        const AppGap.small2(),
        AppText.labelMedium(label),
      ],
    ];

    return hasLanPorts
        ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                // mainAxisSize: MainAxisSize.min,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  isMobile
                      ? Column(
                          children: portLabel,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: portLabel,
                        )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.small2),
                child: SvgPicture(
                  connection == null
                      ? CustomTheme.of(context).images.imgPortOff
                      : CustomTheme.of(context).images.imgPortOn,
                  semanticsLabel: 'port status image',
                  width: 40,
                  height: 40,
                ),
              ),
              if (connection != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LinksysIcons.bidirectional,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        AppText.bodySmall(connection),
                      ],
                    ),
                    SizedBox(
                      width: 70,
                      child: AppText.bodySmall(
                        loc(context).connectedSpeed,
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              if (isWan) AppText.labelMedium(loc(context).internet),
              Container(
                constraints: const BoxConstraints(maxWidth: 60),
                width: 60,
                child: isWan
                    ? Container(
                        height: 2,
                        color: connection == null
                            ? Theme.of(context).colorScheme.outlineVariant
                            : Color(orangeTonal.get(80)))
                    : null,
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Wrap(
                    // mainAxisSize: MainAxisSize.min,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      isMobile
                          ? Column(
                              children: portLabel,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: portLabel,
                            )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Spacing.small2),
                    child: SvgPicture(
                      connection == null
                          ? CustomTheme.of(context).images.imgPortOff
                          : CustomTheme.of(context).images.imgPortOn,
                      semanticsLabel: 'port status image',
                      width: 40,
                      height: 40,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (connection != null)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LinksysIcons.bidirectional,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            AppText.bodyMedium(connection),
                          ],
                        ),
                        AppText.bodySmall(
                          loc(context).connectedSpeed,
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  if (isWan) AppText.labelMedium(loc(context).internet),
                ],
              ),
            ],
          );
  }
}
