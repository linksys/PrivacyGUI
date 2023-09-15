import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/devices/device_detail_id_provider.dart';
import 'package:linksys_app/provider/devices/device_list_provider.dart';
import 'package:linksys_app/provider/devices/device_list_state.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/extensions.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';

class DashboardDevices extends ArgumentsConsumerStatefulView {
  const DashboardDevices({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<DashboardDevices> createState() => _DashboardDevicesState();
}

class _DashboardDevicesState extends ConsumerState<DashboardDevices> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDeviceList = ref.watch(filteredDeviceListProvider);
    final filteredChips =
        ref.watch(filteredDeviceListProvider.select((value) => value.$3));
    return StyledAppPageView(
      padding: const AppEdgeInsets.zero(),
      child: AppBasicLayout(
        header: AppPadding.regular(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.headlineMedium('Devices'),
                AppTertiaryButton.noPadding(
                  'Filters',
                  icon: getCharactersIcons(context).filterDefault,
                  onTap: () {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return _buildFilterBottomSheet();
                        });
                  },
                )
              ],
            ),
            const AppGap.regular(),
            Wrap(
              spacing: 16,
              children: filteredChips
                  .map((e) => FilterChip(
                        label: AppText.bodySmall(e ?? ''),
                        selected: true,
                        onSelected: (bool value) {},
                      ))
                  .toList(),
            ),
          ],
        )),
        content: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: filteredDeviceList.$2.length + 1,
          itemBuilder: (context, index) {
            return _buildCell(index, filteredDeviceList.$2);
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider(
              height: 8,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCell(int index, List<DeviceListItem> deviceList) {
    if (index == deviceList.length) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: AppSimplePanel(
          title: 'Offline (${ref.read(offlineDeviceListProvider).length})',
          onTap: () {
            context.pushNamed(RouteNamed.offlineDevices);
          },
        ),
      );
    } else {
      return _buildDeviceCell(deviceList[index]);
    }
  }

  Widget _buildDeviceCell(DeviceListItem item) {
    return AppPadding(
      padding: const AppEdgeInsets.symmetric(horizontal: AppGapSize.regular),
      child: Opacity(
        opacity: item.isOnline ? 1 : 0.3,
        child: AppDevicePanel.normal(
          title: item.name,
          place: item.upstreamDevice,
          band: item.band,
          deviceImage: AppTheme.of(context).images.devices.getByName(item.icon),
          rssiIcon: item.isOnline
              ? getWifiSignalIconData(
                  context, item.isWired ? null : item.signalStrength)
              : null,
          onTap: !item.isOnline
              ? null
              : () {
                  ref.read(deviceDetailIdProvider.notifier).state =
                      item.deviceId;
                  context.pushNamed(RouteNamed.deviceDetails);
                },
        ),
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Consumer(builder: (context, ref, child) {
      final nodes = ref.watch(deviceManagerProvider).nodeDevices;
      final radios =
          ref.watch(dashboardManagerProvider).mainRadios.unique((x) => x.band);

      final selectedNodeId = ref.watch(nodeIdFilterProvider);
      final selectedBand = ref.watch(bandFilterProvider);
      final selectConnection = ref.watch(connectionFilterProvider);
      final selectSSID = ref.watch(ssidFilterProvider);

      return DraggableScrollableSheet(
        initialChildSize: .8,
        maxChildSize: .8,
        minChildSize: .6,
        builder: (BuildContext context, ScrollController scrollController) =>
            SingleChildScrollView(
          controller: scrollController,
          child: Container(
            alignment: Alignment.bottomLeft,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: AppPadding.regular(
              child: Column(
                children: [
                  FilteredChipsWidget<LinksysDevice>(
                      title: 'Node',
                      dataList: nodes,
                      chipName: ({data}) => data?.getDeviceLocation() ?? '',
                      checkIsSelected: ({data}) =>
                          (data == null && selectedNodeId.isEmpty) ||
                          selectedNodeId == data?.deviceID,
                      onSelected: ({data}) {
                        ref.read(nodeIdFilterProvider.notifier).state =
                            data?.deviceID ?? '';
                      }),
                  FilteredChipsWidget<WifiConnectionType>(
                      title: 'SSID',
                      dataList: WifiConnectionType.values,
                      chipName: ({data}) => data?.value ?? '',
                      checkIsSelected: ({data}) =>
                          (data == null && selectSSID == null) ||
                          selectSSID == data,
                      onSelected: ({data}) {
                        ref.read(ssidFilterProvider.notifier).state = data;
                      }),
                  FilteredChipsWidget<String>(
                      title: 'Connection type',
                      dataList: const ['Wired', 'WiFi'],
                      chipName: ({data}) => data ?? '',
                      checkIsSelected: ({data}) =>
                          (data == null && selectConnection.isEmpty) ||
                          selectConnection == data,
                      onSelected: ({data}) {
                        ref.read(connectionFilterProvider.notifier).state =
                            data ?? '';
                      }),
                  FilteredChipsWidget<RouterRadioInfo>(
                      title: 'Band',
                      dataList: radios,
                      chipName: ({data}) => data?.band ?? '',
                      checkIsSelected: ({data}) =>
                          (data == null && selectedBand.isEmpty) ||
                          selectedBand == data?.band,
                      onSelected: ({data}) {
                        ref.read(bandFilterProvider.notifier).state =
                            data?.band ?? '';
                      }),
                  const AppGap.semiBig(),
                  const Divider(
                    height: 8,
                  ),
                  const AppGap.semiBig(),
                  AppPadding.regular(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppTertiaryButton(
                          'Clear all',
                          onTap: () {
                            initFilter();
                          },
                        ),
                        AppPrimaryButton(
                          'Show ${ref.read(filteredDeviceListProvider).$2.length} devices',
                          onTap: () {
                            context.pop();
                          },
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void initFilter() {
    ref.read(nodeIdFilterProvider.notifier).state = '';
    ref.read(bandFilterProvider.notifier).state = '';
    ref.read(connectionFilterProvider.notifier).state = '';
    ref.read(ssidFilterProvider.notifier).state = null;
  }
}

class FilteredChipsWidget<T> extends ConsumerStatefulWidget {
  final String title;
  final List<T> dataList;
  final String Function({T? data}) chipName;
  final bool Function({T? data}) checkIsSelected;
  final void Function({T? data}) onSelected;

  const FilteredChipsWidget({
    super.key,
    required this.title,
    required this.dataList,
    required this.chipName,
    required this.checkIsSelected,
    required this.onSelected,
  });

  @override
  ConsumerState<FilteredChipsWidget<T>> createState() =>
      _FilteredChipsWidgetState();
}

class _FilteredChipsWidgetState<T>
    extends ConsumerState<FilteredChipsWidget<T>> {
  @override
  Widget build(BuildContext context) {
    return AppSection.withLabel(
        title: widget.title,
        content: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 16,
          children: [
            FilterChip(
              label: AppText.bodySmall('All'),
              onSelected: (value) {
                widget.onSelected();
              },
              selected: widget.checkIsSelected(),
            ),
            ...widget.dataList.map((e) => FilterChip(
                  label: AppText.bodySmall(widget.chipName(data: e)),
                  onSelected: (value) {
                    widget.onSelected(data: e);
                  },
                  selected: widget.checkIsSelected(data: e),
                ))
          ],
        ));
  }
}
