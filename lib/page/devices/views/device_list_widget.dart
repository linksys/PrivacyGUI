import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/devices/extensions/icon_device_category_ext.dart';
import 'package:privacy_gui/page/devices/providers/device_list_state.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/card/device_list_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class DeviceListWidget extends ConsumerStatefulWidget {
  final List<DeviceListItem> devices;
  final bool isEdit;
  final bool Function(DeviceListItem)? isItemSelected;
  final void Function(DeviceListItem)? onItemClick;
  final void Function(bool, DeviceListItem)? onItemSelected;
  final Widget? Function(BuildContext, int)? itemBuilder;

  const DeviceListWidget({
    super.key,
    this.devices = const [],
    this.isEdit = false,
    this.isItemSelected,
    this.onItemClick,
    this.onItemSelected,
    this.itemBuilder,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DeviceListWidgetState();
}

class _DeviceListWidgetState extends ConsumerState<DeviceListWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: widget.devices.length,
      itemBuilder: widget.itemBuilder ??
          (context, index) => _buildCell(index, widget.devices),
    );
  }

  Widget _buildCell(int index, List<DeviceListItem> deviceList) {
    return _buildDeviceCell(deviceList[index]);
  }

  Widget _buildDeviceCell(DeviceListItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.zero),
      child: AppDeviceListCard(
        isSelected: widget.isItemSelected?.call(item) ?? false,
        title: item.name,
        description: ResponsiveLayout.isMobile(context) || !item.isOnline
            ? null
            : item.upstreamDevice,
        band: ResponsiveLayout.isMobile(context)
            ? null
            : !item.isOnline
                ? null
                : item.isWired
                    ? null
                    : item.band,
        leading: IconDeviceCategoryExt.resolveByName(item.icon),
        trailing: item.isOnline
            ? getWifiSignalIconData(
                context, item.isWired ? null : item.signalStrength)
            : null,
        onSelected: widget.isEdit
            ? (value) {
                widget.onItemSelected?.call(value, item);
              }
            : null,
        onTap: () {
          if (widget.isEdit) {
            return;
          } else {
            widget.onItemClick?.call(item);
          }
        },
      ),
    );
  }
}
