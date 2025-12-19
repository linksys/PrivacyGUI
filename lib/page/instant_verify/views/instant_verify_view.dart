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
      onRefresh: () {
        return ref.read(pollingProvider.notifier).forcePolling();
      },
      title: loc(context).instantVerify,
      tabs: tabs.map((e) => Tab(text: e)).toList(),
      tabContentViews: tabContents,
      tabController: _tabController,
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
    );
  }

  Widget _instantInfo(BuildContext context, WidgetRef ref) {
    final isHealthCheckSupported =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;
    final desktopCol = context.colWidth(4);
    return SingleChildScrollView(
      child: AppResponsiveLayout(
        mobile: (ctx) => _mobileLayout(context, ref),
        desktop: (ctx) =>
            _desktopLayout(context, ref, isHealthCheckSupported, desktopCol),
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
                    Expanded(
                      child: _deviceInfoCard(context, ref),
                    ),
                    AppGap.gutter(),
                    Expanded(
                      child: _connectivityContentWidget(context, ref),
                    ),
                    AppGap.gutter(),
                    Expanded(
                      child: _speedTestContent(context),
                    ),
                  ],
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _deviceInfoCard(context, ref),
                          ),
                          AppGap.gutter(),
                          Expanded(
                            child: _connectivityContentWidget(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppGap.gutter(),
                  Expanded(
                    flex: 1,
                    child: _speedTestContent(context),
                  ),
                ],
              ),
        AppGap.lg(),
        _portsCard(context, ref),
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
              child: Column(
                children: [
                  _linkStatusWidget(context, ref),
                  AppGap.lg(),
                  _wifiStatusWidget(context, ref),
                  AppGap.xxl(),
                  _wanStatusWidget(context, ref),
                ],
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
              child: _pingTracerouteWidget(context, ref),
            ),
          ],
        ));
  }

  Widget _linkStatusWidget(BuildContext context, WidgetRef ref) {
    final systemConnectivityState = ref.watch(instantVerifyProvider);
    final isOnline = systemConnectivityState.wanConnection != null;
    final theme = Theme.of(context).extension<AppDesignTheme>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            loc(context).internet,
            variant: AppTextVariant.titleSmall,
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline
                  ? theme?.colorScheme.semanticSuccess
                  : theme?.colorScheme.semanticDanger,
            ),
          )
        ],
      ),
    );
  }

  Widget _wanStatusWidget(BuildContext context, WidgetRef ref) {
    final systemConnectivityState = ref.watch(instantVerifyProvider);
    final wan = systemConnectivityState.wanConnection;
    final ipv4 = wan?.ipAddress ?? '';
    final dns2 = wan?.dnsServer2;

    Widget item(String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium(label),
          AppText(
            value,
            variant: AppTextVariant.titleSmall,
            fontWeight: FontWeight.bold,
          ),
          AppGap.md(),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item(loc(context).wanIPAddress, ipv4.isNotEmpty ? ipv4 : '--'),
          item(loc(context).gateway, wan?.gateway ?? '--'),
          item(loc(context).connectionType, wan?.wanType ?? '--'),
          item('${loc(context).dns} 1', wan?.dnsServer1 ?? '--'),
          if (dns2 != null && dns2.isNotEmpty)
            item('${loc(context).dns} 2', dns2),
        ],
      ),
    );
  }

  Widget _wifiStatusWidget(BuildContext context, WidgetRef ref) {
    final systemConnectivityState = ref.watch(instantVerifyProvider);
    final radios = systemConnectivityState.radioInfo.radios;
    final guestSettings = systemConnectivityState.guestRadioSettings;
    final guestWiFi = guestSettings.radios.firstOrNull;
    final theme = Theme.of(context).extension<AppDesignTheme>();

    Widget dot(bool enabled) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? theme?.colorScheme.semanticSuccess
              : theme?.colorScheme.outline,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                loc(context).wifi,
                variant: AppTextVariant.titleSmall,
                fontWeight: FontWeight.bold,
              ),
              dot(true),
            ],
          ),
          Divider(height: AppSpacing.xxl),
          for (final e in radios) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child:
                        AppText.labelMedium('${e.band} | ${e.settings.ssid}')),
                dot(e.settings.isEnabled),
              ],
            ),
            AppGap.lg(),
          ],
          if (guestWiFi != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppText.labelMedium(
                      '${loc(context).guest} | ${guestWiFi.guestSSID}'),
                ),
                dot(guestSettings.isGuestNetworkEnabled),
              ],
            ),
        ],
      ),
    );
  }

  Widget _pingTracerouteWidget(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _toolCard(
          context,
          title: loc(context).ping,
          icon: Icons.radio_button_checked,
          onTap: () {
            doSomethingWithSpinner(
                context, _showPingNetworkModal(context, ref));
          },
        ),
        AppGap.lg(),
        _toolCard(
          context,
          title: loc(context).traceroute,
          icon: Icons.route,
          onTap: () {
            doSomethingWithSpinner(context, _showTracerouteModal(context, ref));
          },
        ),
      ],
    );
  }

  Widget _toolCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: Row(
          children: [
            AppText(
              title,
              variant: AppTextVariant.titleSmall,
              fontWeight: FontWeight.bold,
            ),
            const Spacer(),
            Icon(icon, color: Theme.of(context).iconTheme.color),
          ],
        ),
      ),
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
      Padding(
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
