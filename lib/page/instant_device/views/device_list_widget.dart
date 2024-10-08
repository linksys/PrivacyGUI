import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/instant_device/extensions/icon_device_category_ext.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/card/device_list_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

class DeviceListWidget extends ConsumerStatefulWidget {
  final List<DeviceListItem> devices;
  final bool isEdit;
  final bool enableDeauth;
  final bool enableDelete;
  final bool Function(DeviceListItem)? isItemSelected;
  final void Function(DeviceListItem)? onItemClick;
  final void Function(bool, DeviceListItem)? onItemSelected;
  final void Function(DeviceListItem)? onItemDeauth;
  final void Function(DeviceListItem)? onItemDelete;
  final Widget? Function(BuildContext, int)? itemBuilder;
  final ScrollPhysics? physics;

  const DeviceListWidget({
    super.key,
    this.devices = const [],
    this.isEdit = false,
    this.enableDeauth = false,
    this.enableDelete = false,
    this.isItemSelected,
    this.onItemClick,
    this.onItemSelected,
    this.onItemDeauth,
    this.onItemDelete,
    this.itemBuilder,
    this.physics,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DeviceListWidgetState();
}

class _DeviceListWidgetState extends ConsumerState<DeviceListWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: widget.physics,
      padding: EdgeInsets.zero,
      itemCount: widget.devices.length,
      itemBuilder: widget.itemBuilder ??
          (context, index) => _buildCell(index, widget.devices),
      separatorBuilder: (BuildContext context, int index) {
        if (index != widget.devices.length - 1) {
          return const AppGap.small2();
        } else {
          return const Center();
        }
      },
    );
  }

  Widget _buildCell(int index, List<DeviceListItem> deviceList) {
    return _buildDeviceCell(deviceList[index]);
  }

  Widget _buildDeviceCell(DeviceListItem item) {
    return AppDeviceListCard(
      color: (widget.isItemSelected?.call(item) ?? false)
          ? Theme.of(context).colorScheme.primaryContainer
          : item.isOnline
              ? null
              : Theme.of(context).colorScheme.surfaceVariant,
      borderColor: (widget.isItemSelected?.call(item) ?? false)
          ? Theme.of(context).colorScheme.primary
          : item.isOnline
              ? null
              : Theme.of(context).colorScheme.outlineVariant,
      isSelected: widget.isItemSelected?.call(item) ?? false,
      title: item.name,
      description: item.isOnline
          ? AppText.bodyMedium(item.ipv4Address)
          : AppText.bodyMedium(loc(context).offline),
      band: _connectionInfo(item),
      leading: IconDeviceCategoryExt.resolveByName(item.icon),
      trailing: _trailing(item),
      onSelected: widget.isEdit
          ? (value) {
              widget.onItemSelected?.call(value, item);
            }
          : null,
      onTap: () {
        widget.onItemClick?.call(item);
      },
    );
  }

  Widget _connectionInfo(DeviceListItem device) {
    return device.isOnline
        ? ResponsiveLayout(
            desktop: AppText.bodyMedium(device.isWired
                ? loc(context).ethernet
                : '${device.ssid}  •  ${device.band}'),
            mobile: device.isWired
                ? AppText.bodyMedium(loc(context).ethernet)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText.bodyMedium(device.ssid),
                      const AppGap.small1(),
                      AppText.bodyMedium(device.band),
                    ],
                  ),
          )
        : Container();
  }

  Widget _trailing(DeviceListItem device) {
    return Row(
      children: [
        SharedWidgets.resolveSignalStrengthIcon(
          context,
          device.signalStrength,
          isOnline: device.isOnline,
          isWired: device.isWired,
        ),
        if (widget.enableDeauth  && serviceHelper.isSupportClientDeauth()) ...[
          const AppGap.medium(),
          AppIconButton.noPadding(
            icon: LinksysIcons.bidirectional,
            semanticLabel: 'deauth',
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              widget.onItemDeauth?.call(device);
            },
          ),
        ],
        if (widget.enableDelete) ...[
          const AppGap.medium(),
          AppIconButton.noPadding(
            icon: LinksysIcons.delete,
            semanticLabel: 'delete',
            color: Theme.of(context).colorScheme.error,
            onTap: () {
              widget.onItemDelete?.call(device);
            },
          ),
        ],
      ],
    );
  }
}
