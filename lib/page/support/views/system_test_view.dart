import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/shimmer.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/page/support/providers/system_connectivity_provider.dart';
import 'package:privacy_gui/page/topology/_topology.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class SystemTestView extends ArgumentsConsumerStatelessView {
  const SystemTestView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ResponsiveLayout.isMobileLayout(context)
        ? ['Device Info', 'Connectivitity', 'Speed Test', 'Topology']
        : ['Device Info & Connectivity', 'Topology'];
    final tabContents = ResponsiveLayout.isMobileLayout(context)
        ? [
            SingleChildScrollView(child: _deviceInfoCard(context, ref)),
            SingleChildScrollView(
                child: _connectivityContentWidget(context, ref)),
            _speedTestContent(context),
            _topologyView(),
          ]
        : [
            _deviceInfoAndConnectivityView(context, ref),
            _topologyView(),
          ];
    return StyledAppTabPageView(
      backState: StyledBackState.none,
      title: 'System Test',
      tabs: tabs.map((e) => AppTab(title: e)).toList(),
      tabContentViews: tabContents,
      expandedHeight: 120,
    );
  }

  Widget _deviceInfoAndConnectivityView(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 4.col,
            child: _deviceInfoCard(context, ref),
          ),
          const AppGap.gutter(),
          SizedBox(
            width: 8.col,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 4.col,
                      child: AppCard(
                        child: _connectivityContentWidget(context, ref),
                      ),
                    ),
                    const AppGap.gutter(),
                    SizedBox(
                      width: 4.col,
                      child: AppCard(
                        child: _speedTestContent(context),
                      ),
                    ),
                  ],
                ),
                const AppGap.medium(),
                _portsCard(context, ref),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _topologyView() {
    return TopologyView();
  }

  Widget _deviceInfoCard(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardManagerProvider);
    final devicesState = ref.watch(deviceManagerProvider);
    final uptime = DateFormatUtils.formatDuration(
        Duration(seconds: dashboardState.uptimes), context);
    final master = devicesState.masterDevice;
    return AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _appNoBoarderCard(
                child: AppText.titleSmall(loc(context).deviceInfo)),
            _appNoBoarderCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(LinksysIcons.calendar),
                      AppText.bodySmall(
                          '${loc(context).systemTestDateFormat(DateTime.now())}|${loc(context).systemTestDateTime(DateTime.now())}'),
                    ],
                  ),
                  const AppGap.medium(),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(LinksysIcons.uptime),
                      AppText.bodySmall('${loc(context).uptime}: $uptime'),
                    ],
                  ),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).deviceName),
                  AppText.labelMedium(master.getDeviceLocation()),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).model),
                  AppText.labelMedium(master.modelNumber ?? '--'),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).sku),
                  AppText.labelMedium(dashboardState.skuModelNumber ?? '--'),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).serialNumber),
                  AppText.labelMedium(master.unit.serialNumber ?? '--'),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).macAddress),
                  AppText.labelMedium(master.getMacAddress()),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).firmwareVersion),
                  AppText.labelMedium(master.unit.firmwareVersion ?? '--'),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall('CPU Utilization'),
                  AppText.labelMedium('####'),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall('Memory Utilization'),
                  AppText.labelMedium('####'),
                ],
              ),
            ),
            const AppGap.large1(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: Spacing.medium),
              width: double.infinity,
              child: AppCard(
                child: Column(
                  children: [
                    Icon(LinksysIcons.restartAlt),
                    AppText.labelMedium('Reset Router')
                  ],
                ),
              ),
            ),
            const AppGap.small2(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: Spacing.medium),
              width: double.infinity,
              child: AppCard(
                child: Column(
                  children: [
                    Icon(LinksysIcons.restartAlt),
                    AppText.labelMedium('Factory Reset')
                  ],
                ),
              ),
            ),
            const AppGap.medium(),
          ],
        ));
  }

  Widget _portsCard(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final isLoading = ref
        .watch(deviceManagerProvider.select((value) => value.deviceList))
        .isEmpty;
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.small2,
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
      ),
    );
  }

  Widget _portWidget(
      BuildContext context, String? connection, String label, bool isWan) {
    final isMobile = ResponsiveLayout.isMobileLayout(context);
    final portLabel = [
      Icon(
        connection == null
            ? LinksysIcons.circle
            : LinksysIcons.checkCircleFilled,
        color: connection == null
            ? Theme.of(context).colorScheme.surfaceVariant
            : Theme.of(context).colorSchemeExt.green,
      ),
      const AppGap.small2(),
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
          padding: const EdgeInsets.all(Spacing.small2),
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
          width: 120,
          child: isWan
              ? Divider(
                  height: 8, color: Theme.of(context).colorSchemeExt.orange)
              : null,
        ),
      ],
    );
  }

  Widget _headerWidget(String title, [Widget? action]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall(title),
        if (action != null) action,
      ],
    );
  }

  Widget _connectivityContentWidget(BuildContext context, WidgetRef ref) {
    final systemConnectivityState = ref.watch(systemConnectivityProvider);
    final dnsCount = systemConnectivityState.wanConnection?.dnsServer3 != null
        ? 3
        : systemConnectivityState.wanConnection?.dnsServer2 != null
            ? 2
            : 1;
    final guestWiFi = systemConnectivityState.guestRadioSettings.radios.first;
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerWidget(
            'Connectivity',
            AppIconButton.noPadding(
              icon: LinksysIcons.refresh,
              onTap: () {},
            ),
          ),
          const AppGap.large2(),
          AppCard(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelMedium('Self Test'),
              _greenCircle(context),
            ],
          )),
          const AppGap.small2(),
          AppCard(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelMedium('Internet'),
              _greenCircle(
                  context, systemConnectivityState.wanConnection != null)
            ],
          )),
          const AppGap.small2(),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _appNoBoarderCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.labelMedium('WiFi'),
                      _greenCircle(context)
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                ),
                ...systemConnectivityState.radioInfo.radios.map(
                  (e) => _appNoBoarderCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppText.labelMedium(
                            '${e.band}|${e.settings.ssid}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        _greenCircle(context, e.settings.isEnabled),
                      ],
                    ),
                  ),
                ),
                _appNoBoarderCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AppText.labelMedium(
                          '${loc(context).guest}|${guestWiFi.guestSSID}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      _greenCircle(context, guestWiFi.isEnabled),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const AppGap.large2(),
          _appNoBoarderCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.zero, vertical: Spacing.medium),
            child: Wrap(
              direction: Axis.vertical,
              children: [
                AppText.bodySmall('WAN'),
                AppText.labelMedium(systemConnectivityState
                            .wanConnection?.wanType ==
                        null
                    ? '--'
                    : '${systemConnectivityState.wanConnection?.wanType}|${systemConnectivityState.wanConnection?.ipAddress}'),
              ],
            ),
          ),
          _appNoBoarderCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.zero, vertical: Spacing.medium),
            child: Wrap(
              direction: Axis.vertical,
              children: [
                AppText.bodySmall('Gateway'),
                AppText.labelMedium(
                    systemConnectivityState.wanConnection?.gateway ?? '--'),
              ],
            ),
          ),
          _appNoBoarderCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.zero, vertical: Spacing.medium),
            child: Wrap(
              direction: Axis.vertical,
              children: [
                AppText.bodySmall(loc(context).nDNS(dnsCount)),
                AppText.labelMedium(dnsCount == 3
                    ? '${systemConnectivityState.wanConnection?.dnsServer1}|${systemConnectivityState.wanConnection?.dnsServer2}|${systemConnectivityState.wanConnection?.dnsServer3}'
                    : dnsCount == 2
                        ? '${systemConnectivityState.wanConnection?.dnsServer1}|${systemConnectivityState.wanConnection?.dnsServer2}'
                        : systemConnectivityState.wanConnection?.dnsServer1 ??
                            '--'),
              ],
            ),
          ),
          const AppGap.large2(),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    children: [
                      Icon(
                        LinksysIcons.checkCircleFilled,
                      ),
                      AppText.labelMedium('Ping')
                    ],
                  ),
                ),
              ),
              const AppGap.small2(),
              Expanded(
                child: AppCard(
                  child: Column(
                    children: [
                      Icon(
                        LinksysIcons.checkCircleFilled,
                      ),
                      AppText.labelMedium('Traceroute')
                    ],
                  ),
                ),
              ),
            ],
          ),
        ]);
  }

  Widget _speedTestContent(BuildContext context) {
    return Column(
      children: [
        _headerWidget('Speed Test'),
        const AppGap.large2(),
        SizedBox(width: 326, height: 326, child: SpeedTestView()),
      ],
    );
  }

  Widget _greenCircle(BuildContext context, [bool isActive = true]) {
    return Icon(
      LinksysIcons.circle,
      color: isActive
          ? Theme.of(context).colorSchemeExt.green
          : Theme.of(context).colorScheme.surfaceVariant,
      size: 16,
    );
  }

  Widget _appNoBoarderCard({required Widget child, EdgeInsets? padding}) =>
      AppCard(
        showBorder: false,
        padding: padding ??
            const EdgeInsets.symmetric(
                horizontal: Spacing.medium, vertical: Spacing.medium),
        child: child,
      );
}

class AppExpansionCard extends StatefulWidget {
  final Widget collapsedChild;
  final Widget expandedChild;

  const AppExpansionCard({
    super.key,
    required this.collapsedChild,
    required this.expandedChild,
  });

  @override
  State<AppExpansionCard> createState() => _AppExpansionCardState();
}

class _AppExpansionCardState extends State<AppExpansionCard> {
  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    return AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.large2),
                  child: _isExpanded
                      ? widget.expandedChild
                      : widget.collapsedChild,
                )),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: CustomTheme.of(context)
                      .radius
                      .asBorderRadius()
                      .medium
                      .copyWith(topLeft: Radius.zero, topRight: Radius.zero)),
              child: InkWell(
                borderRadius: CustomTheme.of(context)
                    .radius
                    .asBorderRadius()
                    .medium
                    .copyWith(topLeft: Radius.zero, topRight: Radius.zero),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.medium),
                    child:
                        AppText.labelLarge(_isExpanded ? 'Collaspe' : 'Expand'),
                  ),
                ),
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ),
          ],
        ));
  }
}
