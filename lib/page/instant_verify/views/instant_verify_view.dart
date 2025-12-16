import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/wan_external_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/page/instant_verify/views/components/ping_network_modal.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_external_widget.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:privacy_gui/page/instant_verify/views/components/traceroute_modal.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/route/constants.dart';

import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/page/instant_verify/services/instant_verify_pdf_service.dart';

class InstantVerifyView extends ArgumentsConsumerStatefulView {
  const InstantVerifyView({super.key, super.args});

  @override
  ConsumerState<InstantVerifyView> createState() => _InstantVerifyViewState();
}

class _InstantVerifyViewState extends ConsumerState<InstantVerifyView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Widget _instantTopologyWidget;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _instantTopologyWidget = InstantTopologyView.widget();

    ref.read(wanExternalProvider.notifier).fetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context);
    final tabs = [loc(context).instantInfo, loc(context).instantTopology];
    final tabContents = [
      _instantInfo(context, ref),
      _instantTopologyWidget,
    ];
    return UiKitPageView.withSliver(
      useMainPadding: false,
      onRefresh: () {
        return ref.read(pollingProvider.notifier).forcePolling();
      },
      title: loc(context).instantVerify,
      actions: [
        AppIconButton(
          icon: AppIcon.font(AppFontIcons.print),
          onTap: () {
            doSomethingWithSpinner(
                context, InstantVerifyPdfService.generatePdf(context, ref));
          },
        ),
        if (!Utils.isMobilePlatform())
          AnimatedRefreshContainer(
            builder: (controller) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: AppIconButton(
                  icon: AppIcon.font(AppFontIcons.refresh),
                  onTap: () {
                    controller.repeat();
                    ref
                        .read(pollingProvider.notifier)
                        .forcePolling()
                        .then((value) {
                      controller.stop();
                    });
                  },
                ),
              );
            },
          ),
      ],
      child: (context, constraints) => Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabContents,
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: tabs.map((e) => Tab(text: e)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _instantInfo(BuildContext context, WidgetRef ref) {
    final isHealthCheckSupported =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;
    final desktopCol = context.colWidth(4);
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal:
                context.isMobileLayout ? AppSpacing.lg : AppSpacing.xxl),
        child: AppResponsiveLayout(
          mobile: _mobileLayout(context, ref),
          desktop:
              _desktopLayout(context, ref, isHealthCheckSupported, desktopCol),
        ),
      ),
    );
  }

  Widget _mobileLayout(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _deviceInfoCard(context, ref),
        AppGap.lg(),
        _connectivityContentWidget(context, ref),
        AppGap.lg(),
        _speedTestContent(context),
        AppGap.lg(),
        _portsCard(context, ref),
        AppGap.lg(),
        _dnsDetailWidget(context, ref),
      ],
    );
  }

  Widget _desktopLayout(BuildContext context, WidgetRef ref,
      bool isHealthCheckSupported, double desktopCol) {
    return Column(
      children: [
        isHealthCheckSupported
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: desktopCol,
                      child: _deviceInfoCard(context, ref),
                    ),
                    AppGap.xxl(),
                    SizedBox(
                      width: desktopCol,
                      child: _connectivityContentWidget(context, ref),
                    ),
                    AppGap.xxl(),
                    SizedBox(
                      width: desktopCol,
                      child: _speedTestContent(context),
                    ),
                  ],
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: desktopCol,
                          child: _deviceInfoCard(context, ref),
                        ),
                        AppGap.xxl(),
                        SizedBox(
                          width: desktopCol,
                          child: _connectivityContentWidget(context, ref),
                        ),
                      ],
                    ),
                  ),
                  AppGap.xxl(),
                  SizedBox(
                    width: desktopCol,
                    child: _speedTestContent(context),
                  ),
                ],
              ),
        AppGap.lg(),
        _portsCard(context, ref),
        AppGap.lg(),
        _dnsDetailWidget(context, ref),
      ],
    );
  }

  Widget _dnsDetailWidget(BuildContext context, WidgetRef ref) {
    final systemConnectivityState = ref.watch(instantVerifyProvider);
    final wan = systemConnectivityState.wanConnection;
    final dnsList = [wan?.dnsServer1, wan?.dnsServer2, wan?.dnsServer3]
        .where((e) => e != null && e.isNotEmpty)
        .toList();
    final dnsContent = dnsList.join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _headerWidget(loc(context).dns)),
            if (!Utils.isMobilePlatform())
              // TODO: check if we need to migrate PingNetworkModal/TracerouteModal calls or button styles
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton.text(
                    label: loc(context).ping,
                    onTap: () {
                      doSomethingWithSpinner(
                          context, _showPingNetworkModal(context, ref));
                    },
                  ),
                  AppGap.lg(),
                  AppIconButton(
                    icon: AppIcon.font(
                      AppFontIcons.router,
                    ),
                    onTap: () {
                      doSomethingWithSpinner(
                          context, _showTracerouteModal(context, ref));
                    },
                  ),
                ],
              )
          ],
        ),
        AppGap.lg(),
        context.isMobileLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dnsItem(loc(context).dns, dnsContent),
                  AppGap.lg(),
                  if (Utils.isMobilePlatform()) ...[
                    AppButton.text(
                      label: loc(context).ping,
                      onTap: () {
                        doSomethingWithSpinner(
                            context, _showPingNetworkModal(context, ref));
                      },
                    ),
                    AppButton.text(
                      label: loc(context).traceroute,
                      onTap: () {
                        doSomethingWithSpinner(
                            context, _showTracerouteModal(context, ref));
                      },
                    ),
                  ]
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _dnsItem(loc(context).dns, dnsContent),
                  ),
                ],
              )
      ],
    );
  }

  Widget _deviceInfoCard(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardManagerProvider);
    final devicesState = ref.watch(deviceManagerProvider);
    final uptime = DateFormatUtils.formatDuration(
        Duration(seconds: dashboardState.uptimes), context, true);
    final localTime =
        DateTime.fromMillisecondsSinceEpoch(dashboardState.localTime);
    final master = devicesState.masterDevice;
    final cpuLoad = dashboardState.cpuLoad;
    final memoryLoad = dashboardState.memoryLoad;

    return AppCard(
        key: const ValueKey('deviceInfoCard'),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: _headerWidget(loc(context).deviceInfo),
            ),
            AppGap.lg(),
            _appNoBoarderCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppIcon.font(
                        AppFontIcons.calendar,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        child: AppText.bodySmall(
                            '${loc(context).systemTestDateFormat(localTime)} | ${loc(context).systemTestDateTime(localTime)}'),
                      ),
                    ],
                  ),
                  AppGap.lg(),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppIcon.font(
                        AppFontIcons.networkCheck,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        child: AppText.bodySmall(
                            '${loc(context).uptime}: $uptime'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(
              height: AppSpacing.xxxl,
              thickness: 1,
              indent: AppSpacing.xxl,
              endIndent: AppSpacing.xxl,
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).deviceName),
                  AppText.labelMedium(
                    master.getDeviceLocation(),
                    selectable: true,
                  ),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).deviceModel),
                  AppText.labelMedium(
                    master.modelNumber ?? '--',
                    selectable: true,
                  ),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).sku),
                  AppText.labelMedium(
                    dashboardState.skuModelNumber ?? '--',
                    selectable: true,
                  ),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).serialNumber),
                  AppText.labelMedium(
                    master.unit.serialNumber ?? '--',
                    selectable: true,
                  ),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).mac),
                  AppText.labelMedium(
                    master.getMacAddress(),
                    selectable: true,
                  ),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodySmall(
                        loc(context).firmwareVersion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppText.labelMedium(
                        master.unit.firmwareVersion ?? '--',
                        selectable: true,
                      ),
                    ],
                  )),
                  SharedWidgets.nodeFirmwareStatusWidget(
                      context, hasNewFirmware(ref), () {
                    context.pushNamed(RouteNamed.firmwareUpdateDetail);
                  }),
                ],
              ),
            ),
            if (cpuLoad != null)
              _appNoBoarderCard(
                child: Wrap(
                  direction: Axis.vertical,
                  children: [
                    AppText.bodySmall(loc(context).cpuUtilization),
                    AppText.labelMedium(
                        '${((double.tryParse(cpuLoad.padLeft(2, '0')) ?? 0) * 100).toStringAsFixed(2)}%'),
                  ],
                ),
              ),
            if (memoryLoad != null)
              _appNoBoarderCard(
                child: Wrap(
                  direction: Axis.vertical,
                  children: [
                    AppText.bodySmall(loc(context).memoryUtilization),
                    AppText.labelMedium(
                        '${((double.tryParse(memoryLoad.padRight(2, '0')) ?? 0) * 100).toStringAsFixed(2)}%'),
                  ],
                ),
              ),
          ],
        ));
  }

  bool hasNewFirmware(WidgetRef ref) {
    final nodesStatus =
        ref.watch(firmwareUpdateProvider.select((value) => value.nodesStatus));
    return nodesStatus?.any((element) => element.availableUpdate != null) ??
        false;
  }

  Widget _portsCard(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    return SizedBox(
      height: context.isMobileLayout ? 224 : 208,
      width: double.infinity,
      child: AppCard(
          key: const ValueKey('portCard'),
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
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
                                  false),
                            ))
                        .toList(),
                    Expanded(
                      child: _portWidget(
                          context,
                          state.wanPortConnection == 'None'
                              ? null
                              : state.wanPortConnection,
                          loc(context).wan,
                          true),
                    )
                  ],
                ),
              ),
            ],
          )),
    );
  }

  Widget _portWidget(
      BuildContext context, String? connection, String label, bool isWan) {
    final isMobile = context.isMobileLayout;
    final portLabel = [
      AppIcon.font(
        connection == null
            ? AppFontIcons.circle
            : AppFontIcons.checkCircleFilled,
        color: connection == null
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).extension<AppColorScheme>()?.semanticSuccess,
      ),
      AppGap.sm(),
      AppText.labelMedium(label),
    ];
    return Column(
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
          child: SizedBox(
            width: 40,
            height: 40,
            child: connection == null
                ? Assets.images.imgPortOff.svg()
                : Assets.images.imgPortOn.svg(),
          ),
        ),
        if (connection != null)
          Column(
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
              SizedBox(
                width: 70,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AppText.bodySmall(
                    loc(context).connectedSpeed,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              )
            ],
          ),
        if (isWan) AppText.labelMedium(loc(context).internet),
      ],
    );
  }

  Widget _headerWidget(String title, [Widget? action]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: AppText.titleSmall(title)),
        if (action != null) action,
      ],
    );
  }

  Widget _connectivityContentWidget(BuildContext context, WidgetRef ref) {
    return AppCard(
        key: const ValueKey('connectivityCard'),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: _headerWidget(loc(context).connectivity),
            ),
            AppGap.lg(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _linkStatusWidget(context, ref)),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                    ),
                    Expanded(child: _wanStatusWidget(context, ref)),
                  ],
                ),
              ),
            ),
            AppGap.lg(),
            Divider(
              height: AppSpacing.xxxl,
              thickness: 1,
              indent: AppSpacing.xxl,
              endIndent: AppSpacing.xxl,
            ),
            AppGap.lg(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: _dnsDetailWidget(context, ref),
            ),
          ],
        ));
  }

  Widget _linkStatusWidget(BuildContext context, WidgetRef ref) {
    final systemConnectivityState = ref.watch(instantVerifyProvider);
    final isOnline = systemConnectivityState.wanConnection != null;
    return Column(
      children: [
        AppGap.lg(),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isOnline
                ? Theme.of(context).extension<AppColorScheme>()?.semanticSuccess
                : Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(AppSpacing.xxl),
          ),
          child: AppText.labelMedium(
            isOnline ? loc(context).online : loc(context).offline,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        AppGap.sm(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppText.labelMedium(
            isOnline ? loc(context).online : loc(context).offline,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _wanStatusWidget(BuildContext context, WidgetRef ref) {
    final systemConnectivityState = ref.watch(instantVerifyProvider);
    final wan = systemConnectivityState.wanConnection;
    final ipv4 = wan?.ipAddress ?? '';
    const ipv6 = ''; // WAN IPv6 not in simple wanConnection model
    return Column(
      children: [
        AppGap.lg(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppText.labelMedium(
            loc(context).ipv4,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppText.bodySmall(
            ipv4.isNotEmpty ? ipv4 : '--',
            textAlign: TextAlign.center,
          ),
        ),
        AppGap.lg(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppText.labelMedium(
            loc(context).ipv6,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppText.bodySmall(
            ipv6.isNotEmpty ? ipv6 : '--',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _dnsItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelMedium(title),
        AppText.bodySmall(content),
      ],
    );
  }

  Widget _speedTestContent(BuildContext context) {
    final isHealthCheckSupported =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;
    return AppCard(
      key: const ValueKey('speedTestCard'),
      padding: EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          _headerWidget(loc(context).speedTest),
          AppGap.xxl(),
          isHealthCheckSupported
              ? SpeedTestWidget()
              : AppCard(
                  child: Tooltip(
                    message: loc(context).featureUnavailableInRemoteMode,
                    child: Opacity(
                      opacity: BuildConfig.isRemote() ? 0.5 : 1,
                      child: AbsorbPointer(
                        absorbing: BuildConfig.isRemote(),
                        child: const SpeedTestExternalWidget(),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _appNoBoarderCard({required Widget child, EdgeInsets? padding}) =>
      AppCard(
        // showBorder: false, // ui_kit AppCard might not support this, check properties.
        // Assuming default AppCard is acceptable, or use decoration to hide border if needed.
        // For now, removing showBorder as it flags an error.
        padding: padding ??
            const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
        child: child,
      );

  Future<void> _showPingNetworkModal(
      BuildContext context, WidgetRef ref) async {
    await showSimpleAppDialog(
      context,
      dismissible: false,
      title: loc(context).pingNetwork,
      content: const PingNetworkModal(),
    );
  }

  Future<void> _showTracerouteModal(BuildContext context, WidgetRef ref) async {
    await showSimpleAppDialog(
      context,
      dismissible: false,
      title: loc(context).traceroute,
      content: const TracerouteModal(),
    );
  }
}
