import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/devices/extensions/icon_device_category_ext.dart';
import 'package:privacygui_widgets/theme/const/spacing.dart';
import 'package:privacygui_widgets/widgets/card/device_list_card.dart';

class ConnectedDeviceListWidget extends ConsumerStatefulWidget {
  final List<LinksysDevice> devices;
  final bool isEdit;
  final bool Function(LinksysDevice)? isItemSelected;
  final void Function(LinksysDevice)? onItemClick;
  final void Function(bool, LinksysDevice)? onItemSelected;
  final Widget? Function(BuildContext, int)? itemBuilder;
  final ScrollPhysics? physics;

  const ConnectedDeviceListWidget({
    super.key,
    this.devices = const [],
    this.isEdit = false,
    this.isItemSelected,
    this.onItemClick,
    this.onItemSelected,
    this.itemBuilder,
    this.physics,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DeviceListWidgetState();
}

class _DeviceListWidgetState extends ConsumerState<ConnectedDeviceListWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: widget.physics,
      padding: EdgeInsets.zero,
      itemCount: widget.devices.length,
      itemBuilder: widget.itemBuilder ??
          (context, index) => _buildCell(index, widget.devices),
    );
  }

  Widget _buildCell(int index, List<LinksysDevice> deviceList) {
    return _buildDeviceCell(deviceList[index]);
  }

  Widget _buildDeviceCell(LinksysDevice item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.zero),
      child: AppDeviceListCard(
        isSelected: widget.isItemSelected?.call(item) ?? false,
        title: item.getDeviceLocation(),
        leading:
            IconDeviceCategoryExt.resolveByName(deviceIconTest(item.toMap())),
        onTap: () {
          if (widget.isEdit) {
            return;
          } else {
            widget.onItemClick?.call(item);
          }
        },
        trailing: getWifiSignalIconData(
            context, item.isWiredConnection() ? null : item.signalDecibels),
      ),
    );
  }
}
