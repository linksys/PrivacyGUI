import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/data/providers/node_internet_status_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';

import 'package:ui_kit_library/ui_kit.dart';
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
        : AppResponsiveLayout(
            desktop: (ctx) => !hasLanPort
                ? _desktopNoLanPorts(context, ref, state, isOnline, isLoading)
                : horizontalLayout
                    ? _desktopHorizontal(
                        context, ref, state, isOnline, isLoading)
                    : _desktopVertical(
                        context, ref, state, isOnline, isLoading),
            mobile: (ctx) => _mobile(context, ref, state, isOnline, isLoading));
  }

  Widget _mobile(BuildContext context, WidgetRef ref, DashboardHomeState state,
      bool isOnline, bool isLoading) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      // constraints:
      //     BoxConstraints(minHeight: !state.isHealthCheckSupported ? 240 : 420),
      child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xxl,
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
              // AppGap.xxl(),
              _createSpeedTestTile(context, ref, state, hasLanPort, true),
            ],
          )),
    );
  }

  Widget _desktopVertical(BuildContext context, WidgetRef ref,
      DashboardHomeState state, bool isOnline, bool isLoading) {
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isHealthCheckSupported =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;
    return Container(
      constraints: BoxConstraints(
          minWidth: 150, minHeight: !isHealthCheckSupported ? 360 : 520),
      child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: !isHealthCheckSupported
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 752,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxl,
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
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxxl,
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
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.md, // Reduced from xl to fix overflow
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
                  height: 132,
                  child: _createSpeedTestTile(context, ref, state, false)),
            ],
          )),
    );
  }

  Widget _createSpeedTestTile(BuildContext context, WidgetRef ref,
      DashboardHomeState state, bool hasLanPort,
      [bool mobile = false]) {
    final isRemote = BuildConfig.isRemote();
    final isHealthCheckSupported =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;
    return isHealthCheckSupported
        ? hasLanPort
            ? Column(
                children: [
                  const Divider(),
                  const SpeedTestWidget(
                      showDetails: false,
                      showInfoPanel: true,
                      showStepDescriptions: false,
                      showLatestOnIdle: true,
                      layout: SpeedTestLayout.vertical),
                  AppGap.xxl(),
                ],
              )
            : _speedCheckWidget(context, ref, state)
        : Tooltip(
            message: loc(context).featureUnavailableInRemoteMode,
            child: Opacity(
              opacity: isRemote ? 0.5 : 1,
              child: AbsorbPointer(
                absorbing: isRemote,
                child: _externalSpeedTest(context, state),
              ),
            ),
          );
  }

  Widget _speedCheckWidget(
      BuildContext context, WidgetRef ref, DashboardHomeState state) {
    final speedTest = ref.watch(healthCheckProvider);
    final horizontalLayout = state.isHorizontalLayout;
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;
    final dateTime = speedTest.latestSpeedTest?.timestampEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            speedTest.latestSpeedTest!.timestampEpoch!);
    final isLegacy = dateTime == null
        ? true
        : DateTime.now().difference(dateTime).inDays > 1;
    final dateTimeStr =
        dateTime == null ? '' : loc(context).formalDateTime(dateTime, dateTime);
    return Container(
      key: const ValueKey('speedCheck'),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: horizontalLayout
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          AppResponsiveLayout(
            desktop: (ctx) => !hasLanPort
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Column(
                      children: [
                        if (dateTimeStr.isNotEmpty) ...[
                          AppText.bodySmall(dateTimeStr),
                          AppGap.sm(),
                        ],
                        Row(
                          spacing: AppSpacing.lg,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: isLegacy ? 0.6 : 1,
                              child: _downloadSpeedResult(
                                  context,
                                  speedTest.latestSpeedTest?.downloadSpeed ??
                                      '--',
                                  speedTest.latestSpeedTest?.downloadUnit,
                                  isLegacy),
                            ),
                            Opacity(
                              opacity: isLegacy ? 0.6 : 1,
                              child: _uploadSpeedResult(
                                  context,
                                  speedTest.latestSpeedTest?.uploadSpeed ??
                                      '--',
                                  speedTest.latestSpeedTest?.uploadUnit,
                                  isLegacy),
                            )
                          ],
                        ),
                        AppGap.lg(),
                        _speedTestButton(context, state)
                      ],
                    ),
                  )
                : horizontalLayout
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xxl),
                        child: Row(
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Opacity(
                                          opacity: isLegacy ? 0.6 : 1,
                                          child: _downloadSpeedResult(
                                              context,
                                              speedTest.latestSpeedTest
                                                      ?.downloadSpeed ??
                                                  '--',
                                              speedTest.latestSpeedTest
                                                  ?.downloadUnit,
                                              isLegacy),
                                        ),
                                      ),
                                      Expanded(
                                        child: Opacity(
                                          opacity: isLegacy ? 0.6 : 1,
                                          child: _uploadSpeedResult(
                                              context,
                                              speedTest.latestSpeedTest
                                                      ?.uploadSpeed ??
                                                  '--',
                                              speedTest
                                                  .latestSpeedTest?.uploadUnit,
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
                            vertical: AppSpacing.xxl),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (dateTimeStr.isNotEmpty) ...[
                                AppText.bodySmall(dateTimeStr),
                                AppGap.sm(),
                              ],
                              _downloadSpeedResult(
                                  context,
                                  speedTest.latestSpeedTest?.downloadSpeed ??
                                      '--',
                                  speedTest.latestSpeedTest?.downloadUnit,
                                  isLegacy),
                              AppGap.xxl(),
                              _uploadSpeedResult(
                                  context,
                                  speedTest.latestSpeedTest?.uploadSpeed ??
                                      '--',
                                  speedTest.latestSpeedTest?.uploadUnit,
                                  isLegacy),
                              AppGap.lg(),
                              _speedTestButton(context, state),
                            ]),
                      ),
            mobile: (ctx) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bodySmall(dateTimeStr),
                        AppGap.sm(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Opacity(
                                opacity: isLegacy ? 0.6 : 1,
                                child: _downloadSpeedResult(
                                    context,
                                    speedTest.latestSpeedTest?.downloadSpeed ??
                                        '--',
                                    speedTest.latestSpeedTest?.downloadUnit,
                                    isLegacy),
                              ),
                            ),
                            Expanded(
                              child: Opacity(
                                opacity: isLegacy ? 0.6 : 1,
                                child: _uploadSpeedResult(
                                    context,
                                    speedTest.latestSpeedTest?.uploadSpeed ??
                                        '--',
                                    speedTest.latestSpeedTest?.uploadUnit,
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(12).copyWith(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _speedTestHeader(context, state),
          AppGap.sm(),
          Flexible(
            child: hasLanPort && !horizontalLayout && !context.isMobileLayout
                ? SizedBox(
                    width: 144,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: AppSpacing.sm,
                        children: [
                          AppButton(
                            label: loc(context).speedTestExternalTileCloudFlare,
                            onTap: () {
                              openUrl('https://speed.cloudflare.com/');
                            },
                          ),
                          AppButton(
                            label: loc(context).speedTestExternalTileFast,
                            onTap: () {
                              openUrl('https://www.fast.com');
                            },
                          ),
                        ]),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: AppSpacing.lg,
                    children: [
                        Expanded(
                          child: AppButton(
                            label: loc(context).speedTestExternalTileCloudFlare,
                            onTap: () {
                              openUrl('https://speed.cloudflare.com/');
                            },
                          ),
                        ),
                        Expanded(
                          child: AppButton(
                            label: loc(context).speedTestExternalTileFast,
                            onTap: () {
                              openUrl('https://www.fast.com');
                            },
                          ),
                        ),
                      ]),
          ),
          AppGap.sm(),
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
      child: AppIcon.font(
        AppFontIcons.infoCircle,
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
            AppGap.sm(),
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
    return AppResponsiveLayout(
        desktop: (ctx) =>
            hasLanPort && horizontalLayout ? rowHeader : columnHeader,
        mobile: (ctx) => rowHeader);
  }

  Widget _speedTestButton(BuildContext context, DashboardHomeState state) {
    return SizedBox(
      height: 40,
      child: AppButton(
        label: loc(context).speedTextTileStart,
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
        AppIcon.font(
          AppFontIcons.arrowDownward,
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
          AppGap.xs(),
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
        AppIcon.font(
          AppFontIcons.arrowUpward,
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
          AppGap.xs(),
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
    final isMobile = context.isMobileLayout;
    final portLabel = [
      AppIcon.font(
        connection == null
            ? AppFontIcons.circle
            : AppFontIcons.checkCircleFilled,
        color: connection == null
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.green,
      ),
      if (hasLanPorts) ...[
        AppGap.sm(),
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
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: connection == null
                    ? Assets.images.imgPortOff.svg(
                        width: 40,
                        height: 40,
                        semanticsLabel: 'port status image',
                      )
                    : Assets.images.imgPortOn.svg(
                        width: 40,
                        height: 40,
                        semanticsLabel: 'port status image',
                      ),
              ),
              if (connection != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon.font(
                          AppFontIcons.bidirectional,
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
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: connection == null
                        ? Assets.images.imgPortOff.svg(
                            width: 40,
                            height: 40,
                            semanticsLabel: 'port status image',
                          )
                        : Assets.images.imgPortOn.svg(
                            width: 40,
                            height: 40,
                            semanticsLabel: 'port status image',
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
                            AppIcon.font(
                              AppFontIcons.bidirectional,
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
