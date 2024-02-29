import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/util/extensions.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';
import 'package:material_symbols_icons/symbols.dart';

class DevicesFilterWidget extends ConsumerStatefulWidget {
  const DevicesFilterWidget({super.key});

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
    final radios = ref
        .watch(dashboardManagerProvider.select((value) => value.mainRadios))
        .unique((x) => x.band);
    final filterConfig = ref.watch(deviceFilterConfigProvider);
    final selectedNodeId = filterConfig.nodeFilter;
    final selectedBand = filterConfig.bandFilter;
    final selectConnection = filterConfig.connectionFilter;
    // final selectSSID = ref.watch(ssidFilterProvider);
    return SingleChildScrollView(
      physics: const ScrollPhysics(),
      child: Container(
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.regular),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.semiSmall(),
              const AppText.titleSmall('Filters'),
              const AppGap.regular(),
              FilteredChipsWidget<String>(
                  title: 'By Connection',
                  dataList: const ['Online', 'Offline'],
                  chipName: (data) => data ?? '',
                  checkIsSelected: (data) =>
                      selectConnection == (data == 'Online'),
                  onSelected: (data, value) {
                    if (data == null) {
                      return;
                    }
                    if (value) {
                      ref
                          .read(deviceFilterConfigProvider.notifier)
                          .updateConnectionFilter(data == 'Online');
                    }
                  }),
              FilteredChipsWidget<LinksysDevice>(
                  title: 'By node',
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
              FilteredChipsWidget<RouterRadio>(
                  title: 'By Radio',
                  dataList: radios,
                  chipName: (data) => data?.band ?? '',
                  checkIsSelected: (data) => selectConnection
                      ? selectedBand.contains(data?.band)
                      : false,
                  onSelected: selectConnection
                      ? (data, value) {
                          final band = data?.band;
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
              const AppGap.regular(),
              AppTextButton.noPadding(
                'Reset Filters',
                icon: Symbols.restart_alt,
                onTap: () {
                  ref.read(deviceFilterConfigProvider.notifier).initFilter();
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
                  label: AppText.bodySmall(widget.chipName(e)),
                  // shape: const RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.all(Radius.circular(40))),
                  // showCheckmark: false,
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
