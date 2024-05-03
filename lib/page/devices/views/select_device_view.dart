import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/list_card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/providers/device_list_provider.dart';
import 'package:linksys_widgets/widgets/page/layout/group_list_layout.dart';

import '../providers/device_list_state.dart';

enum DisplaySubType {
  none,
  mac,
  ipv4,
  ipv6,
  ;

  static DisplaySubType resolve(String value) => switch (value) {
        'mac' => DisplaySubType.mac,
        'ipv4' => DisplaySubType.ipv4,
        'ipv6' => DisplaySubType.ipv6,
        _ => DisplaySubType.none,
      };
}

class SelectDeviceView extends ArgumentsConsumerStatefulView {
  const SelectDeviceView({super.key, super.args});

  @override
  ConsumerState<SelectDeviceView> createState() => _SelectDeviceViewState();
}

class _SelectDeviceViewState extends ConsumerState<SelectDeviceView> {
  late final DisplaySubType _subType;
  final List<DeviceListItem> selected = [];

  @override
  void initState() {
    super.initState();
    _subType = DisplaySubType.resolve(widget.args['type']);
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
      saveAction: SaveAction(
          enabled: selected.isNotEmpty,
          label: loc(context).nAdd(selected.length),
          onSave: () {
            context.pop(selected);
          }),
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
              final selectable = value?.isNotEmpty ?? false;
              return AppListCard(
                title: AppText.labelMedium(item.name),
                leading: Opacity(
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
                ),
                description:
                    selectable ? AppText.bodyMedium(value ?? '') : null,
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
      };
}
