import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/devices/providers/device_list_provider.dart';
import 'package:privacygui_widgets/widgets/page/layout/group_list_layout.dart';

import '../providers/device_list_state.dart';

enum DisplaySubType {
  none,
  mac,
  ipv4,
  ipv6,
  ipv4AndMac,
  ;

  static DisplaySubType resolve(String? value) => switch (value) {
        'mac' => DisplaySubType.mac,
        'ipv4' => DisplaySubType.ipv4,
        'ipv6' => DisplaySubType.ipv6,
        'ipv4AndMac' => DisplaySubType.ipv4AndMac,
        _ => DisplaySubType.none,
      };
}

enum SelectMode {
  single,
  multiple,
  ;

  static SelectMode resolve(String? value) => switch (value) {
        'single' => SelectMode.single,
        _ => SelectMode.multiple,
      };
}

class SelectDeviceView extends ArgumentsConsumerStatefulView {
  const SelectDeviceView({super.key, super.args});

  @override
  ConsumerState<SelectDeviceView> createState() => _SelectDeviceViewState();
}

class _SelectDeviceViewState extends ConsumerState<SelectDeviceView> {
  late final DisplaySubType _subType;
  late final SelectMode _selectMode;

  final List<DeviceListItem> selected = [];
  @override
  void initState() {
    super.initState();
    _subType = DisplaySubType.resolve(widget.args['type']);
    _selectMode = SelectMode.resolve(widget.args['selectMode']);
    final selectedValues = widget.args['selected'] as List<String>? ?? [];
    final devices = ref.read(deviceListProvider).devices;
    final selectedItems = selectedValues
        .map((value) {
          return devices
              .firstWhereOrNull((device) => _subMessage(device) == value);
        })
        .whereType<DeviceListItem>()
        .toList();
    selected.addAll(selectedItems);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceListProvider);
    final onlineDevices =
        state.devices.where((device) => device.isOnline).toList();
    final offlineDevices =
        state.devices.where((device) => !device.isOnline).toList();
    return StyledAppPageView(
      title: loc(context).selectDevices,
      bottomBar: _selectMode == SelectMode.multiple
          ? PageBottomBar(
              isPositiveEnabled: selected.isNotEmpty,
              positiveLabel: loc(context).nAdd(selected.length),
              onPositiveTap: () {
                context.pop(selected);
              })
          : null,
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: GroupList<DeviceListItem>(
            groups: [
              GroupItem(
                key: const ObjectKey('online'),
                label: loc(context).onlineDevices,
                items: onlineDevices,
              ),
              GroupItem(
                key: const ObjectKey('offline'),
                label: loc(context).offlineDevices,
                items: offlineDevices,
              ),
            ],
            itemBuilder: (item) {
              final value = _subMessage(item);
              final selectable = _selectable(item);
              return Opacity(
                opacity: _selectMode == SelectMode.multiple
                    ? 1
                    : selectable
                        ? 1
                        : 0.3,
                child: AppListCard(
                  color: selected.any((element) => element == item)
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  borderColor: selected.any((element) => element == item)
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  title: AppText.labelMedium(item.name),
                  leading: _selectMode == SelectMode.multiple
                      ? Opacity(
                          opacity: selectable ? 1 : 0.3,
                          child: AbsorbPointer(
                            absorbing: !selectable,
                            child: AppCheckbox(
                              value: selected.any((element) => element == item),
                              onChanged: (value) {
                                onChecked(item);
                              },
                            ),
                          ),
                        )
                      : null,
                  description:
                      selectable ? AppText.bodyMedium(value ?? '') : null,
                  onTap: _selectMode == SelectMode.multiple
                      ? selectable
                          ? () {
                              onChecked(item);
                            }
                          : null
                      : selectable
                          ? () {
                              context.pop([item]);
                            }
                          : null,
                ),
              );
            }),
      ),
    );
  }

  void onChecked(DeviceListItem item) {
    setState(() {
      if (selected.contains(item)) {
        selected.remove(item);
      } else {
        selected.add(item);
      }
    });
  }

  String? _subMessage(DeviceListItem item) => switch (_subType) {
        DisplaySubType.none => null,
        DisplaySubType.mac => item.macAddress,
        DisplaySubType.ipv4 => item.ipv4Address,
        DisplaySubType.ipv6 => item.ipv6Address,
        DisplaySubType.ipv4AndMac =>
          'IP: ${item.ipv4Address}\nMAC: ${item.macAddress}',
      };

  bool _selectable(DeviceListItem item) => switch (_subType) {
        DisplaySubType.none => false,
        DisplaySubType.mac => item.macAddress.isNotEmpty,
        DisplaySubType.ipv4 => item.ipv4Address.isNotEmpty,
        DisplaySubType.ipv6 => item.ipv6Address.isNotEmpty,
        DisplaySubType.ipv4AndMac =>
          item.ipv4Address.isNotEmpty && item.macAddress.isNotEmpty,
      };
}
