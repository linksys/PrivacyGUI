import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/util/extensions.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:ui_kit_library/ui_kit.dart';

class DevicesFilterWidget extends ConsumerStatefulWidget {
  final List<String>? preselectedNodeId;
  final bool onlineOnly;
  final bool scrollable;

  const DevicesFilterWidget({
    super.key,
    this.preselectedNodeId,
    this.onlineOnly = false,
    this.scrollable = true,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DevicesFilterWidgetState();
}

class _DevicesFilterWidgetState extends ConsumerState<DevicesFilterWidget> {
  late DeviceFilterConfigNotifier notifier;

  @override
  void initState() {
    super.initState();

    notifier = ref.read(deviceFilterConfigProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(deviceManagerProvider).nodeDevices;
    List<(String, String)> connectedList =
        nodes.map((e) => (e.deviceID, e.getDeviceLocation())).toList();
    final deviceUUID = widget.preselectedNodeId?.length == 1
        ? widget.preselectedNodeId?.first
        : null;
    final target =
        nodes.firstWhereOrNull((device) => device.deviceID == deviceUUID);
    final additionalRadios = (target == null
            ? ref.watch(deviceManagerProvider).externalDevices
            : target.connectedDevices)
        .fold(<String>{}, (radios, device) {
      final radio =
          ref.read(deviceManagerProvider.notifier).getBandConnectedBy(device);
      if (radio.isNotEmpty) {
        radios.add(radio);
      }
      return radios;
    });
    final wifiState = ref.watch(wifiBundleProvider);
    final wifiNames = [
      ...wifiState.settings.current.wifiList.mainWiFi
          .map((e) => e.ssid)
          .toList()
          .unique(),
      wifiState.settings.current.wifiList.guestWiFi.ssid,
    ];
    final radios = (ref
            .watch(dashboardManagerProvider.select((value) => value.mainRadios))
            .unique((x) => x.band)
            .map((e) => e.band)
            .toList()
          ..addAll(additionalRadios)
          ..add('Ethernet'))
        .unique((x) => x);
    final filterConfig = ref.watch(deviceFilterConfigProvider);
    final selectedNodeId = filterConfig.nodeFilter;
    final selectedWifi = filterConfig.wifiFilter;
    final selectedBand = filterConfig.bandFilter;
    final selectConnection = filterConfig.connectionFilter;
    final showOrphan = filterConfig.showOrphanNodes;

    if (showOrphan) {
      connectedList.add(('', 'unknown'));
    }
    return widget.scrollable
        ? SingleChildScrollView(
            physics: ScrollPhysics(),
            child: _FiltersWidget(
              widget: widget,
              selectConnection: selectConnection,
              notifier: notifier,
              connectedList: connectedList,
              selectedNodeId: selectedNodeId,
              wifiNames: wifiNames,
              selectedWifi: selectedWifi,
              radios: radios,
              selectedBand: selectedBand,
            ),
          )
        : Expanded(
            child: _FiltersWidget(
              widget: widget,
              selectConnection: selectConnection,
              notifier: notifier,
              connectedList: connectedList,
              selectedNodeId: selectedNodeId,
              wifiNames: wifiNames,
              selectedWifi: selectedWifi,
              radios: radios,
              selectedBand: selectedBand,
            ),
          );
  }
}

class _FiltersWidget extends StatelessWidget {
  const _FiltersWidget({
    required this.widget,
    required this.selectConnection,
    required this.notifier,
    required this.connectedList,
    required this.selectedNodeId,
    required this.wifiNames,
    required this.selectedWifi,
    required this.radios,
    required this.selectedBand,
  });

  final DevicesFilterWidget widget;
  final bool selectConnection;
  final DeviceFilterConfigNotifier notifier;
  final List<(String, String)> connectedList;
  final List<String> selectedNodeId;
  final List<String> wifiNames;
  final List<String> selectedWifi;
  final List<String> radios;
  final List<String> selectedBand;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppGap.sm(),
            AppText.titleSmall(loc(context).filters),
            AppGap.lg(),
            FilteredChipsWidget<(String, bool)>(
                title: loc(context).connectionStatus,
                dataList: [
                  (loc(context).online, true),
                  if (!widget.onlineOnly) (loc(context).offline, false)
                ],
                chipName: (data) => data?.$1 ?? '',
                checkIsSelected: (data) => selectConnection == (data?.$2),
                onSelected: (data, value) {
                  if (data == null) {
                    return;
                  }
                  if (value) {
                    notifier.updateConnectionFilter(data.$2);
                  }
                }),
            FilteredChipsWidget<(String, String)>(
                title: loc(context).connectedVia,
                dataList: connectedList,
                chipName: (data) => data?.$2 == 'unknown'
                    ? loc(context).unknown
                    : data?.$2 ?? '',
                checkIsSelected: (data) => selectConnection
                    ? selectedNodeId.contains(data?.$1)
                    : false,
                onSelected: selectConnection
                    ? (data, value) {
                        final deviceId = data?.$1;
                        if (deviceId == null) {
                          return;
                        }
                        if (value) {
                          notifier.updateNodeFilter(
                              List.from(selectedNodeId..add(deviceId)));
                        } else {
                          notifier.updateNodeFilter(
                              List.from(selectedNodeId..remove(deviceId)));
                        }
                      }
                    : null),
            FilteredChipsWidget<String>(
                title: loc(context).byWifi,
                dataList: wifiNames,
                chipName: (data) => data ?? '',
                checkIsSelected: (data) =>
                    selectConnection ? selectedWifi.contains(data) : false,
                onSelected: selectConnection
                    ? (data, value) {
                        if (data == null) {
                          return;
                        }
                        if (value) {
                          notifier.updateWifiFilter(
                              List.from(selectedWifi..add(data)));
                        } else {
                          notifier.updateWifiFilter(
                              List.from(selectedWifi..remove(data)));
                        }
                      }
                    : null),
            FilteredChipsWidget<String>(
                title: loc(context).byConnection.capitalizeWords(),
                dataList: radios,
                chipName: (data) =>
                    data == 'Ethernet' ? loc(context).ethernet : (data ?? ''),
                checkIsSelected: (data) =>
                    selectConnection ? selectedBand.contains(data) : false,
                onSelected: selectConnection
                    ? (data, value) {
                        final band = data;
                        if (band == null) {
                          return;
                        }
                        if (value) {
                          notifier.updateBandFilter(
                              List.from(selectedBand..add(band)));
                        } else {
                          notifier.updateBandFilter(
                              List.from(selectedBand..remove(band)));
                        }
                      }
                    : null),
            AppGap.lg(),
            AppButton.text(
              label: loc(context).resetFilters,
              icon: AppIcon.font(AppFontIcons.restartAlt),
              onTap: () {
                notifier.initFilter(
                    preselectedNodeId: widget.preselectedNodeId);
              },
            )
          ],
        ),
      ),
    );
  }
}

class FilteredChipsWidget<T> extends ConsumerStatefulWidget {
  final String title;
  final List<T> dataList;
  final String Function(T? data) chipName;
  final bool Function(T? data) checkIsSelected;
  final void Function(T? data, bool isSelected)? onSelected;

  const FilteredChipsWidget({
    super.key,
    required this.title,
    required this.dataList,
    required this.chipName,
    required this.checkIsSelected,
    this.onSelected,
  });

  @override
  ConsumerState<FilteredChipsWidget<T>> createState() =>
      _FilteredChipsWidgetState();
}

class _FilteredChipsWidgetState<T>
    extends ConsumerState<FilteredChipsWidget<T>> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall(widget.title),
        AppGap.sm(),
        AppChipGroup(
          chips: widget.dataList
              .map((e) => ChipItem(
                    label: widget.chipName(e),
                    enabled: true,
                  ))
              .toList(),
          selectedIndices: widget.dataList
              .asMap()
              .entries
              .where((entry) => widget.checkIsSelected(entry.value))
              .map((entry) => entry.key)
              .toSet(),
          selectionMode: ChipSelectionMode.multiple,
          onSelectionChanged: (selectedIndices) {
            final allItems = widget.dataList.asMap();
            for (var entry in allItems.entries) {
              final isSelected = selectedIndices.contains(entry.key);
              // FilteredChipsWidget 的 onSelected 是 (item, isSelected)
              // 這裡需要模擬原本的行為：如果狀態改變了才觸發
              if (widget.checkIsSelected(entry.value) != isSelected) {
                widget.onSelected?.call(entry.value, isSelected);
              }
            }
          },
        ),
        AppGap.md(),
      ],
    );
  }
}
