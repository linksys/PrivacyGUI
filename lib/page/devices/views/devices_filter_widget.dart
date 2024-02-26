import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/page/devices/providers/device_list_provider.dart';
import 'package:linksys_app/util/extensions.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';

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

    Future.doWhile(() => !mounted).then((value) => initFilter());
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(deviceManagerProvider).nodeDevices;
    final radios =
        ref.watch(dashboardManagerProvider).mainRadios.unique((x) => x.band);

    final selectedNodeId = ref.watch(nodeIdFilterProvider);
    final selectedBand = ref.watch(bandFilterProvider);
    final selectConnection = ref.watch(connectionFilterProvider);
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
            children: [
              FilteredChipsWidget<String>(
                  title: 'by Connection',
                  dataList: const ['Online', 'Offline'],
                  chipName: (data) => data ?? '',
                  checkIsSelected: (data) => selectConnection.contains(data),
                  onSelected: (data, value) {
                    if (data == null) {
                      return;
                    }
                    final filter = ref.read(connectionFilterProvider.notifier);
                    if (value) {
                      filter.state = List.from(filter.state..add(data));
                    } else {
                      filter.state = List.from(filter.state..remove(data));
                    }
                  }),
              FilteredChipsWidget<LinksysDevice>(
                  title: 'By node',
                  dataList: nodes,
                  chipName: (data) => data?.getDeviceLocation() ?? '',
                  checkIsSelected: (data) =>
                      selectedNodeId.contains(data?.deviceID),
                  onSelected: (data, value) {
                    final deviceId = data?.deviceID;
                    if (deviceId == null) {
                      return;
                    }
                    final filter = ref.read(nodeIdFilterProvider.notifier);
                    if (value) {
                      filter.state = List.from(filter.state..add(deviceId));
                    } else {
                      filter.state = List.from(filter.state..remove(deviceId));
                    }
                  }),
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
                  title: 'by Radio',
                  dataList: radios,
                  chipName: (data) => data?.band ?? '',
                  checkIsSelected: (data) => selectedBand.contains(data?.band),
                  onSelected: (data, value) {
                    final band = data?.band;
                    if (band == null) {
                      return;
                    }
                    final filter = ref.read(bandFilterProvider.notifier);
                    if (value) {
                      filter.state = List.from(filter.state..add(band));
                    } else {
                      filter.state = List.from(filter.state..remove(band));
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }

  void initFilter() {
    final nodes = ref.read(deviceManagerProvider).nodeDevices;
    ref.read(nodeIdFilterProvider.notifier).state =
        nodes.map((e) => e.deviceID).toList();
    ref.read(bandFilterProvider.notifier).state = ref
        .read(dashboardManagerProvider)
        .mainRadios
        .unique((x) => x.band)
        .map((e) => e.band)
        .toList();
    ref.read(connectionFilterProvider.notifier).state = ['Online', 'Offline'];
    // ref.read(ssidFilterProvider.notifier).state = null;
  }
}

class FilteredChipsWidget<T> extends ConsumerStatefulWidget {
  final String title;
  final List<T> dataList;
  final String Function(T? data) chipName;
  final bool Function(T? data) checkIsSelected;
  final void Function(T? data, bool isSelected) onSelected;

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
          alignment: WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.dataList.map((e) => FilterChip(
                  label: AppText.bodySmall(widget.chipName(e)),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40))),
                  showCheckmark: false,
                  onSelected: (value) {
                    widget.onSelected(e, value);
                  },
                  selected: widget.checkIsSelected(e),
                ))
          ],
        ));
  }
}
