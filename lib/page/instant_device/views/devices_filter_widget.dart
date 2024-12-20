import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/util/extensions.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacygui_widgets/widgets/panel/general_section.dart';

class DevicesFilterWidget extends ConsumerStatefulWidget {
  final List<String>? preselectedNodeId;

  const DevicesFilterWidget({
    super.key,
    this.preselectedNodeId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DevicesFilterWidgetState();
}

class _DevicesFilterWidgetState extends ConsumerState<DevicesFilterWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(deviceManagerProvider).nodeDevices;
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
    final selectedBand = filterConfig.bandFilter;
    final selectConnection = filterConfig.connectionFilter;
    // final selectSSID = ref.watch(ssidFilterProvider);
    return SingleChildScrollView(
      physics: const ScrollPhysics(),
      child: Container(
        alignment: Alignment.bottomLeft,
        // decoration: BoxDecoration(
        //   color: Theme.of(context).colorScheme.background,
        //   borderRadius: const BorderRadius.only(
        //     topLeft: Radius.circular(30),
        //     topRight: Radius.circular(30),
        //   ),
        // ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.small2(),
              AppText.titleSmall(loc(context).filters),
              const AppGap.medium(),
              FilteredChipsWidget<(String, bool)>(
                  title: loc(context).byConnection,
                  dataList: [
                    (loc(context).online, true),
                    (loc(context).offline, false)
                  ],
                  chipName: (data) => data?.$1 ?? '',
                  checkIsSelected: (data) => selectConnection == (data?.$2),
                  onSelected: (data, value) {
                    if (data == null) {
                      return;
                    }
                    if (value) {
                      ref
                          .read(deviceFilterConfigProvider.notifier)
                          .updateConnectionFilter(data.$2);
                    }
                  }),
              FilteredChipsWidget<LinksysDevice>(
                  title: loc(context).byNode,
                  dataList: nodes,
                  chipName: (data) => data?.getDeviceLocation() ?? '',
                  checkIsSelected: (data) => selectConnection
                      ? selectedNodeId.contains(data?.deviceID)
                      : false,
                  onSelected: selectConnection
                      ? (data, value) {
                          final deviceId = data?.deviceID;
                          if (deviceId == null) {
                            return;
                          }
                          final filter =
                              ref.read(deviceFilterConfigProvider.notifier);
                          if (value) {
                            filter.updateNodeFilter(
                                List.from(selectedNodeId..add(deviceId)));
                          } else {
                            filter.updateNodeFilter(
                                List.from(selectedNodeId..remove(deviceId)));
                          }
                        }
                      : null),
              // FilteredChipsWidget<WifiConnectionType>(
              //     title: 'SSID',
              //     dataList: WifiConnectionType.values,
              //     chipName: (data) => data?.value ?? '',
              //     checkIsSelected: (data) =>
              //         (data == null && selectSSID == null) ||
              //         selectSSID == data,
              //     onSelected: (data, value) {
              //       ref.read(ssidFilterProvider.notifier).state = data;
              //     }),
              FilteredChipsWidget<String>(
                  title: loc(context).byRadio,
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
                          final filter =
                              ref.read(deviceFilterConfigProvider.notifier);
                          if (value) {
                            filter.updateBandFilter(
                                List.from(selectedBand..add(band)));
                          } else {
                            filter.updateBandFilter(
                                List.from(selectedBand..remove(band)));
                          }
                        }
                      : null),
              const AppGap.medium(),
              AppTextButton.noPadding(
                loc(context).resetFilters,
                icon: LinksysIcons.restartAlt,
                onTap: () {
                  ref
                      .read(deviceFilterConfigProvider.notifier)
                      .initFilter(preselectedNodeId: widget.preselectedNodeId);
                },
              )
            ],
          ),
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
    return AppSection.withLabel(
        title: widget.title,
        content: Wrap(
          alignment: WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.dataList.map((e) => FilterChip(
                  label: AppText.bodySmall(
                    widget.chipName(e),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onSelected: widget.onSelected != null
                      ? (value) {
                          widget.onSelected?.call(e, value);
                        }
                      : null,
                  selected: widget.checkIsSelected(e),
                ))
          ],
        ));
  }
}
