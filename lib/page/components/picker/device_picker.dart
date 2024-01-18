import 'package:flutter/material.dart';
import 'package:linksys_app/provider/devices/device_list_state.dart';
import 'package:linksys_app/util/extensions.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/theme/custom_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/panel/custom_animated_box.dart';
import 'package:linksys_widgets/widgets/panel/general_card.dart';
import 'package:linksys_widgets/widgets/panel/panel_bases.dart';

enum DevicePickerType {
  grid,
  list,
  ;
}

class DevicePicker extends StatefulWidget {
  final DevicePickerType type;
  final bool isEnabledMultipleChoice;
  final List<DeviceListItem> devices;
  final void Function(List<DeviceListItem>)? onSubmit;

  const DevicePicker({
    super.key,
    this.type = DevicePickerType.grid,
    this.isEnabledMultipleChoice = false,
    required this.devices,
    this.onSubmit,
  });

  @override
  State<DevicePicker> createState() => _DevicePickerState();
}

class _DevicePickerState extends State<DevicePicker> {
  late final List<String> _selectedList;

  @override
  void initState() {
    super.initState();
    _selectedList = [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isEnabledMultipleChoice)
          Align(
            alignment: Alignment.centerRight,
            child: AppFilledButton(
              'Done',
              onTap: () {
                widget.onSubmit?.call(_selectedList
                    .map((e) => widget.devices
                        .firstWhere((element) => element.deviceId == e))
                    .toList());
              },
            ),
          ),
        const AppGap.semiBig(),
        Container(
          padding: const EdgeInsets.all(
            Spacing.regular,
          ),
          height: 600,
          child: widget.type == DevicePickerType.grid
              ? _buildDeviceGridView(widget.devices)
              : _buildDeviceListView(widget.devices),
        ),
      ],
    );
  }

  Widget _buildDeviceGridView(List<DeviceListItem> deviceList) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: (3 / 2),
      ),
      itemCount: deviceList.length,
      itemBuilder: (context, index) {
        return CustomAnimatedBox(
            value: _selectedList.contains(deviceList[index].deviceId),
            selectable: widget.isEnabledMultipleChoice,
            onChanged: (value) {
              if (widget.isEnabledMultipleChoice) {
                _checkedItem(deviceList[index].deviceId, value);
              }
            },
            child: _buildDeviceGridCell(deviceList[index]));
      },
    );
  }

  Widget _buildDeviceGridCell(DeviceListItem item) {
    return GestureDetector(
      onTap: widget.isEnabledMultipleChoice
          ? null
          : () {
              widget.onSubmit?.call([item]);
            },
      child: AppCard(
        image: CustomTheme.of(context).images.devices.getByName(item.icon),
        title: item.name,
      ),
    );
  }

  Widget _buildDeviceListView(List<DeviceListItem> deviceList) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: deviceList.length,
      itemBuilder: (context, index) {
        return _buildDeviceListCell(deviceList[index]);
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider(
          height: 8,
        );
      },
    );
  }

  Widget _buildDeviceListCell(DeviceListItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.regular),
      child: AppDevicePanel.offline(
        headerChecked: _selectedList.contains(item.deviceId),
        onHeaderChecked: widget.isEnabledMultipleChoice
            ? (value) {
                _checkedItem(item.deviceId, value);
              }
            : null,
        title: item.name,
        deviceImage:
            CustomTheme.of(context).images.devices.getByName(item.icon),
        onTap: widget.isEnabledMultipleChoice
            ? null
            : () {
                widget.onSubmit?.call([item]);
              },
      ),
    );
  }

  void _checkedItem(String deviceId, bool? value) {
    setState(() {
      if (value == true) {
        _selectedList
          ..add(deviceId)
          ..unique((x) => x);
      } else {
        _selectedList.remove(deviceId);
      }
    });
  }
}
