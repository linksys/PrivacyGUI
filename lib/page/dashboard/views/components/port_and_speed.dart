import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/instant_verify/views/components/speed_test_widget.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:privacy_gui/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/url_helper/url_helper_web.dart';

class DashboardHomePortAndSpeed extends ConsumerWidget {
  const DashboardHomePortAndSpeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final isLoading =
        (ref.watch(pollingProvider).value?.isReady ?? false) == false;
    final horizontalLayout = state.isHorizontalLayout;
    final wanStatus = ref.watch(internetStatusProvider);
    final isOnline = wanStatus == InternetStatus.online;
    final hasLanPort = state.lanPortConnections.isNotEmpty;

    return isLoading
        ? AppCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
                width: double.infinity,
                height: 250,
                child: const LoadingTile()))
        : ResponsiveLayout(
            desktop: !hasLanPort
                ? _desktopNoLanPorts(context, ref, state, isOnline, isLoading)
                : horizontalLayout
                    ? _desktopHorizontal(
                        context, ref, state, isOnline, isLoading)
                    : _desktopVertical(
                        context, ref, state, isOnline, isLoading),
            mobile: _mobile(context, ref, state, isOnline, isLoading));
  }

  Widget _mobile(BuildContext context, WidgetRef ref, DashboardHomeState state,
      bool isOnline, bool isLoading) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    return Container(
      width: double.infinity,
      // constraints:
      //     BoxConstraints(minHeight: !state.isHealthCheckSupported ? 240 : 420),
      child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.medium,
                  vertical: Spacing.large2,
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
              _createSpeedTestTile(context, ref, state, hasLanPort, true),
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
                  // height: state.isHealthCheckSupported ? 304 : 154,
                  child: _createSpeedTestTile(context, ref, state, hasLanPort)),
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
                  height: 112,
                  child: _createSpeedTestTile(context, ref, state, hasLanPort)),
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
                height: 120,
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
                  height: 136,
                  child: _createSpeedTestTile(context, ref, state, false)),
            ],
          )),
    );
  }

  Widget _createSpeedTestTile(BuildContext context, WidgetRef ref,
      DashboardHomeState state, bool hasLanPort,
      [bool mobile = false]) {
    return state.isHealthCheckSupported
        ? hasLanPort
            ? Column(
                children: [
                  Divider(),
                  SpeedTestWidget(
                      showDetails: false,
                      layout: mobile
                          ? SpeedTestLayout.horizontal
                          : SpeedTestLayout.vertical),
                  AppGap.large2(),
                ],
              )
            : _speedCheckWidget(context, ref, state)
        : _externalSpeedTest(context, state);
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
                        const EdgeInsets.symmetric(vertical: Spacing.small3),
                    child: Column(
                      children: [
                        if (dateTimeStr.isNotEmpty) ...[
                          AppText.bodySmall(dateTimeStr),
                          const AppGap.small2(),
                        ],
                        Row(
                          spacing: Spacing.medium,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                        AppGap.medium(),
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
                              const AppGap.medium(),
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

  Widget _externalSpeedTest(BuildContext context, DashboardHomeState state) {
    final horizontalLayout = state.isHorizontalLayout;
    final hasLanPort = state.lanPortConnections.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorSchemeExt.surfaceContainerLow,
        border: Border.all(color: Colors.transparent),
        borderRadius:
            CustomTheme.of(context).radius.asBorderRadius().medium.copyWith(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.large1, vertical: Spacing.small2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _speedTestHeader(context, state),
          AppGap.small2(),
          Flexible(
            child: hasLanPort &&
                    !horizontalLayout &&
                    !ResponsiveLayout.isMobileLayout(context)
                ? SizedBox(
                    width: 144,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: Spacing.small2,
                        children: [
                          AppFilledButton.fillWidth(
                            loc(context).speedTestExternalTileCloudFlare,
                            fitText: true,
                            onTap: () {
                              openUrl('https://speed.cloudflare.com/');
                            },
                          ),
                          AppFilledButton.fillWidth(
                            fitText: true,
                            loc(context).speedTestExternalTileFast,
                            onTap: () {
                              openUrl('https://www.fast.com');
                            },
                          ),
                        ]),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: Spacing.medium,
                    children: [
                        Expanded(
                          child: AppFilledButton(
                            loc(context).speedTestExternalTileCloudFlare,
                            fitText: true,
                            onTap: () {
                              openUrl('https://speed.cloudflare.com/');
                            },
                          ),
                        ),
                        Expanded(
                          child: AppFilledButton(
                            loc(context).speedTestExternalTileFast,
                            fitText: true,
                            onTap: () {
                              openUrl('https://www.fast.com');
                            },
                          ),
                        ),
                      ]),
          ),
          AppGap.small2(),
          AppText.bodyExtraSmall(loc(context).speedTestExternalOthers),
        ],
      ),
    );
  }

  Widget _speedTestHeader(BuildContext context, DashboardHomeState state) {
    final horizontalLayout = state.isHorizontalLayout;
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final speedTitle = AppText.titleMedium(loc(context).speedTextTileStart);
    final infoIcon = InkWell(
      child: Icon(
        LinksysIcons.infoCircle,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () {
        openUrl('https://support.linksys.com/kb/article/79-en/');
      },
    );
    final speedDesc =
        AppText.labelSmall(loc(context).speedTestExternalTileLabel);
    final rowHeader = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: speedTitle),
        infoIcon,
        speedDesc,
      ],
    );
    final columnHeader = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: speedTitle),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            infoIcon,
            AppGap.small2(),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: speedDesc,
              ),
            )
          ],
        )
      ],
    );
    return ResponsiveLayout(
        desktop: hasLanPort && horizontalLayout ? rowHeader : columnHeader,
        mobile: rowHeader);
  }

  Widget _speedTestButton(BuildContext context, DashboardHomeState state) {
    return SizedBox(
      height: 40,
      child: AppFilledButton(
        fitText: true,
        loc(context).speedTextTileStart,
        radius: BorderRadius.circular(40),
        onTap: () {
          context.pushNamed(RouteNamed.dashboardSpeedTest);
        },
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
                    AppText.bodySmall(
                      loc(context).connectedSpeed,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              if (isWan) AppText.labelMedium(loc(context).internet),
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
