import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/wan_external_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/shimmer.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/page/instant_verify/views/components/ping_network_modal.dart';
import 'package:privacy_gui/page/instant_verify/views/components/speed_test_widget.dart';
import 'package:privacy_gui/page/instant_verify/views/components/traceroute_modal.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacy_gui/page/instant_topology/views/model/tree_view_node.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class InstantVerifyView extends ArgumentsConsumerStatefulView {
  const InstantVerifyView({super.key, super.args});

  @override
  ConsumerState<InstantVerifyView> createState() => _InstantVerifyViewState();
}

class _InstantVerifyViewState extends ConsumerState<InstantVerifyView> {
  @override
  void initState() {
    super.initState();
    ref.read(wanExternalProvider.notifier).fetch();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [loc(context).instantInfo, loc(context).instantTopology];
    final tabContents = [
      _instantInfo(context, ref),
      _instantTopology(),
    ];
    return StyledAppTabPageView(
      title: loc(context).instantVerify,
      actions: [
        AppTextButton(
          loc(context).print,
          icon: LinksysIcons.print,
          onTap: () {
            doSomethingWithSpinner(context, _printPdf(context, ref));
          },
        )
      ],
      tabs: tabs.map((e) => Tab(text: e)).toList(),
      tabContentViews: tabContents,
      expandedHeight: 120,
    );
  }

  Widget _instantInfo(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: ResponsiveLayout.isMobileLayout(context)
          ? Column(
              children: [
                _deviceInfoCard(context, ref),
                const AppGap.medium(),
                _connectivityContentWidget(context, ref),
                const AppGap.medium(),
                _speedTestContent(context),
                const AppGap.medium(),
                _portsCard(context, ref),
              ],
            )
          : Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 4.col,
                        child: _deviceInfoCard(context, ref),
                      ),
                      const AppGap.gutter(),
                      SizedBox(
                        width: 4.col,
                        child: _connectivityContentWidget(context, ref),
                      ),
                      const AppGap.gutter(),
                      SizedBox(
                        width: 4.col,
                        child: _speedTestContent(context),
                      ),
                    ],
                  ),
                ),
                const AppGap.medium(),
                _portsCard(context, ref),
              ],
            ),
    );
  }

  Widget _instantTopology() {
    return InstantTopologyView.widget();
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
        padding: const EdgeInsets.symmetric(vertical: Spacing.large2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.large2),
              child: _headerWidget(loc(context).deviceInfo),
            ),
            const AppGap.medium(),
            _appNoBoarderCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        LinksysIcons.calendar,
                        semanticLabel: 'calendar',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.small2),
                        child: AppText.bodySmall(
                            '${loc(context).systemTestDateFormat(localTime)} | ${loc(context).systemTestDateTime(localTime)}'),
                      ),
                    ],
                  ),
                  const AppGap.medium(),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        LinksysIcons.uptime,
                        semanticLabel: 'uptime',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.small2),
                        child: AppText.bodySmall(
                            '${loc(context).uptime}: $uptime'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(
              height: Spacing.large4,
              thickness: 1,
              indent: Spacing.large2,
              endIndent: Spacing.large2,
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
                  AppText.bodySmall(loc(context).deviceModel),
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
                  AppText.bodySmall(loc(context).mac),
                  AppText.labelMedium(master.getMacAddress()),
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
                      AppText.labelMedium(master.unit.firmwareVersion ?? '--'),
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
                        '${(double.tryParse(cpuLoad) ?? 0) * 100}%'),
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
                        '${(double.tryParse(memoryLoad) ?? 0) * 100}%'),
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
    final isLoading = ref
        .watch(deviceManagerProvider.select((value) => value.deviceList))
        .isEmpty;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 110),
      child: ShimmerContainer(
        isLoading: isLoading,
        child: AppCard(
            key: const ValueKey('portCard'),
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
        semanticLabel: connection == null ? 'circle' : 'checked circle',
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
            semanticsLabel:
                connection == null ? 'port off image' : 'port on image',
            width: 40,
            height: 40,
          ),
        ),
        if (connection != null)
          Column(
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
    final systemConnectivityState = ref.watch(instantVerifyProvider);
    final dnsCount = systemConnectivityState.wanConnection?.dnsServer3 != null
        ? 3
        : systemConnectivityState.wanConnection?.dnsServer2 != null
            ? 2
            : 1;
    final guestWiFi = systemConnectivityState.guestRadioSettings.radios.first;
    return AppCard(
      key: const ValueKey('connectivityCard'),
      padding: const EdgeInsets.all(Spacing.large2),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerWidget(
              loc(context).connectivity,
              AnimatedRefreshContainer(
                builder: (controller) => AppIconButton(
                  icon: LinksysIcons.refresh,
                  semanticLabel: 'refresh',
                  color: Theme.of(context).colorScheme.primary,
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
              ),
            ),
            const AppGap.large2(),
            Row(
              children: [
                // Expanded(
                //   child: AppCard(
                //       child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       AppText.labelMedium(loc(context).selfTest),
                //       _greenCircle(context),
                //     ],
                //   )),
                // ),
                // const AppGap.small2(),
                Expanded(
                  child: AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.large2, vertical: Spacing.medium),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.labelMedium(loc(context).internet),
                          _greenCircle(context,
                              systemConnectivityState.wanConnection != null)
                        ],
                      )),
                ),
              ],
            ),
            const AppGap.small2(),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _appNoBoarderCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.large2, vertical: Spacing.medium),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppText.labelMedium(loc(context).wifi),
                        _greenCircle(
                            context,
                            !_isAllWiFiOff(
                                systemConnectivityState.radioInfo.radios,
                                systemConnectivityState.guestRadioSettings))
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
                              '${e.band} | ${e.settings.ssid}',
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
                        _greenCircle(
                            context,
                            systemConnectivityState
                                .guestRadioSettings.isGuestNetworkEnabled),
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
                  AppText.bodySmall(loc(context).wan),
                  AppText.labelMedium(
                      systemConnectivityState.wanExternal?.publicWanIPv4 ??
                          systemConnectivityState.wanConnection?.ipAddress ??
                          '--'),
                ],
              ),
            ),
            _appNoBoarderCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.zero, vertical: Spacing.medium),
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).gateway),
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
                  AppText.bodySmall(loc(context).connectionType),
                  AppText.labelMedium(
                      systemConnectivityState.wanConnection?.wanType ?? '--'),
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
            AppCard(
              key: const ValueKey('ping'),
              child: Row(
                children: [
                  Expanded(child: AppText.labelMedium(loc(context).ping)),
                  const Icon(
                    LinksysIcons.ping,
                    semanticLabel: 'ping',
                  ),
                ],
              ),
              onTap: () {
                _showPingNetworkModal(context, ref);
              },
            ),
            const AppGap.small2(),
            AppCard(
              key: const ValueKey('traceroute'),
              child: Row(
                children: [
                  Expanded(child: AppText.labelMedium(loc(context).traceroute)),
                  const Icon(
                    LinksysIcons.traceroute,
                    semanticLabel: 'Traceroute',
                  ),
                ],
              ),
              onTap: () {
                _showTracerouteModal(context, ref);
              },
            ),
          ]),
    );
  }

  Widget _speedTestContent(BuildContext context) {
    final isSupportedHealthCheck = serviceHelper.isSupportHealthCheck();
    return AppCard(
      key: const ValueKey('speedTestCard'),
      padding: const EdgeInsets.all(Spacing.large2),
      child: Opacity(
        opacity: isSupportedHealthCheck ? 1 : .3,
        child: Column(
          children: [
            _headerWidget(loc(context).speedTest),
            const AppGap.large2(),
            AbsorbPointer(
                absorbing: isSupportedHealthCheck ? false : true,
                child: const SpeedTestWidget())
          ],
        ),
      ),
    );
  }

  Widget _greenCircle(BuildContext context, [bool isActive = true]) {
    return Icon(
      LinksysIcons.circle,
      semanticLabel: 'color circle',
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
                horizontal: Spacing.large2, vertical: Spacing.medium),
        child: child,
      );

  bool _isAllWiFiOff(List<RouterRadio> radios, GuestRadioSettings guestRadio) {
    final enabledList = [
      ...radios.map((e) => e.settings.isEnabled),
      guestRadio.isGuestNetworkEnabled
    ];
    return !enabledList.any((e) => e);
  }

  _showPingNetworkModal(BuildContext context, WidgetRef ref) {
    showSimpleAppDialog(
      context,
      dismissible: false,
      title: 'Ping Network',
      content: const PingNetworkModal(),
    );
  }

  _showTracerouteModal(BuildContext context, WidgetRef ref) {
    showSimpleAppDialog(
      context,
      dismissible: false,
      title: 'Traceroute',
      content: const TracerouteModal(),
    );
  }

  Future<void> _printPdf(BuildContext context, WidgetRef ref) async {
    final topologyState = ref.read(instantTopologyProvider);
    final nodeList = [
      ...topologyState.root.toFlatList(),
      // ...topologyState.offlineRoot.toFlatList()
    ]..removeWhere((element) =>
        element is OnlineTopologyNode || element is OfflineTopologyNode);
    final nodeMap = nodeList.foldIndexed(
        <int, List<AppTreeNode<TopologyModel>>>{}, (index, previous, element) {
      final id = (index ~/ 5) + 1;
      final list = previous[id] ?? [];
      list.add(element);
      previous[id] = list;
      return previous;
    });

    try {
      final doc = pw.Document();

      // Create Info Page
      doc.addPage(_createPage(_buildInfo(context, ref)));
      // Create Node Pages
      for (int i = 0; i < nodeMap.entries.length; i++) {
        final list = nodeMap.entries.toList()[i];
        doc.addPage(
          _createPage(_buildNodes(context, list.key, list.value)),
        );
      }
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => doc.save(),
      );
    } catch (e) {
      logger.e('Print page error', error: e);
    }
  }

  pw.Widget _buildInfo(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.read(dashboardManagerProvider);
    final deviceManagerState = ref.read(deviceManagerProvider);
    final devicesState = ref.read(deviceManagerProvider);
    final healthCheckState = ref.read(healthCheckProvider);
    final systemConnectivityState = ref.read(instantVerifyProvider);

    final uptime = DateFormatUtils.formatDuration(
        Duration(seconds: dashboardState.uptimes), context);
    final master = devicesState.masterDevice;
    final guestWiFi = systemConnectivityState.guestRadioSettings.radios.first;
    final isSupportHealthCheck = serviceHelper.isSupportHealthCheck();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        //
        pw.Text(loc(context).deviceInfo),
        pw.Text(
            '${loc(context).systemTestDateFormat(DateTime.now())} ${loc(context).systemTestDateTime(DateTime.now())}'),
        pw.Text('${loc(context).uptime}: $uptime'),
        pw.Text('${loc(context).model}: ${master.modelNumber ?? '--'}'),
        pw.Text(
            '${loc(context).sku}: ${dashboardState.skuModelNumber ?? '--'}'),
        pw.Text(
            '${loc(context).serialNumber}: ${master.unit.serialNumber ?? '--'}'),
        pw.Text('${loc(context).macAddress}: ${master.getMacAddress()}'),
        pw.Text(
            '${loc(context).firmwareVersion}: ${master.unit.firmwareVersion ?? '--'}'),
        // pw.Text('CPU Utilization: ####'),
        // pw.Text('Memory Utilization: ####'),
        pw.Divider(height: Spacing.medium),
        //
        pw.Text(loc(context).connectivity),
        pw.Text('${loc(context).selfTest}... Passed'),
        pw.Text(
            '${loc(context).internet}... ${systemConnectivityState.wanConnection != null ? 'Passed' : 'Failed'}'),
        ...systemConnectivityState.radioInfo.radios.map(
          (e) => pw.Text(
              '${e.band} | ${e.settings.ssid}... ${e.settings.isEnabled ? 'Enabled' : 'Disabled'}'),
        ),
        pw.Text(
            'Guest | ${guestWiFi.guestSSID}... ${systemConnectivityState.guestRadioSettings.isGuestNetworkEnabled ? 'Enabled' : 'Disabled'}'),
        pw.Text(
            '${loc(context).wanIPAddress}: ${systemConnectivityState.wanConnection?.ipAddress ?? '--'}'),
        pw.Text(
            '${loc(context).gateway}: ${systemConnectivityState.wanConnection?.gateway ?? '--'}'),
        pw.Text(
            '${loc(context).connectionType}: ${systemConnectivityState.wanConnection?.wanType ?? '--'}'),
        pw.Text(
            '${loc(context).dns} 1: ${systemConnectivityState.wanConnection?.dnsServer1 ?? '--'}'),
        pw.Text(
            '${loc(context).dns} 2: ${systemConnectivityState.wanConnection?.dnsServer2 ?? '--'}'),
        pw.Text(
            '${loc(context).dns} 3: ${systemConnectivityState.wanConnection?.dnsServer3 ?? '--'}'),
        pw.Divider(height: Spacing.medium),
        if (isSupportHealthCheck) ...[
          pw.Text(loc(context).speedTest),
          pw.Text(healthCheckState.result.firstOrNull?.toString() ?? ''),
          pw.Divider(height: Spacing.medium),
        ],
        pw.Text('Backhaul info'),

        pw.Text(deviceManagerState.backhaulInfoData
            .map((e) => e.toJson())
            .toList()
            .join('\n')),
        pw.Divider(height: Spacing.medium),
        if (deviceManagerState.wanStatus != null) ...[
          pw.Text('WAN status'),
          pw.Text(deviceManagerState.wanStatus?.toJson() ?? '--'),
        ],
        pw.Divider(height: Spacing.medium),
      ],
    );
  }

  pw.Widget _buildNodes(BuildContext context, int index,
      List<AppTreeNode<TopologyModel>> nodeList) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('${loc(context).instantTopology}... $index'),
        ...nodeList.map((node) {
          return pw.Row(children: [
            pw.SizedBox(width: 16.0 * node.level()),
            pw.Container(
              constraints: const pw.BoxConstraints(
                minWidth: 180,
                maxWidth: 400,
                // minHeight: 264,
              ),
              decoration: pw.BoxDecoration(
                // color: PdfColor.fromInt(Colors.amber.value),
                border: pw.Border.all(),
              ),
              child: pw.Column(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(Spacing.medium),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                node.data.location,
                                maxLines: 1,
                              ),
                              // const AppGap.medium(),
                              pw.SizedBox(height: Spacing.small2),
                              pw.Column(
                                mainAxisSize: pw.MainAxisSize.min,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildNodeContent(
                                    context,
                                    node,
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]);
        }),
      ],
    );
  }

  pw.Widget _buildNodeContent(
    BuildContext context,
    AppTreeNode<TopologyModel> node,
  ) {
    final signalLevel = getWifiSignalLevel(node.data.signalStrength);
    return pw.Table(
      border: const pw.TableBorder(),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(children: [
          pw.Text('${loc(context).model}:'),
          pw.Text(node.data.model),
        ]),
        pw.TableRow(children: [
          pw.Text('${loc(context).serialNo}:'),
          pw.Text(node.data.serialNumber),
        ]),
        pw.TableRow(children: [
          pw.Text('${loc(context).fwVersion}:'),
          pw.Wrap(
            crossAxisAlignment: pw.WrapCrossAlignment.center,
            children: [
              pw.Text(node.data.fwVersion),
            ],
          ),
        ]),
        pw.TableRow(children: [
          pw.Text('${loc(context).connection}:'),
          pw.Text(!node.data.isOnline
              ? '--'
              : node.data.isWiredConnection
                  ? loc(context).wired
                  : loc(context).wireless),
        ]),
        pw.TableRow(children: [
          pw.Text('${loc(context).meshHealth}:'),
          pw.Text(
            node.data.isOnline
                ? '${signalLevel.resolveLabel(context)}(${node.data.signalStrength})'
                : loc(context).offline,
          ),
        ]),
        pw.TableRow(children: [
          pw.Text('${loc(context).ipAddress}:'),
          pw.Text(node.data.isOnline ? node.data.ipAddress : '--'),
        ]),
        pw.TableRow(children: [
          pw.Text('${loc(context).upstream}:'),
          pw.Text(node.parent?.data.location ?? '--'),
        ]),
      ],
    );
  }

  pw.Page _createPage(pw.Widget child) {
    return pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        build: (pw.Context pwContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(loc(context).appTitle,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textScaleFactor: 2.0),
              pw.SizedBox(height: 8.0),
              child
            ],
          );
        });
  }
}
