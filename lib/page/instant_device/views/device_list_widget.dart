import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/instant_device/extensions/icon_device_category_ext.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: widget.devices.length,
      itemBuilder: widget.itemBuilder ??
          (context, index) => _buildCell(index, widget.devices),
      separatorBuilder: (BuildContext context, int index) {
        if (index != widget.devices.length - 1) {
          return AppGap.sm();
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildCell(int index, List<DeviceListItem> deviceList) {
    return _buildDeviceCell(deviceList[index]);
  }

  /// Composed DeviceListCard replacing AppDeviceListCard
  Widget _buildDeviceCell(DeviceListItem item) {
    final isSelected = widget.isItemSelected?.call(item) ?? false;

    return AppCard(
      onTap: () => widget.onItemClick?.call(item),
      child: Row(
        children: [
          if (widget.isEdit)
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.lg),
              child: Checkbox(
                value: isSelected,
                onChanged: (value) {
                  widget.onItemSelected?.call(value ?? false, item);
                },
              ),
            ),
          AppIcon.font(
            IconDeviceCategoryExt.resolveByName(item.icon),
            size: 24,
          ),
          AppGap.lg(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(item.name),
                AppGap.xs(),
                item.isOnline
                    ? AppText.bodyMedium(item.ipv4Address.isNotEmpty
                        ? item.ipv4Address
                        : item.ipv6Address)
                    : AppText.bodyMedium(loc(context).offline),
              ],
            ),
          ),
          _connectionInfo(item),
          AppGap.lg(),
          _trailing(item),
        ],
      ),
    );
  }

  Widget _connectionInfo(DeviceListItem device) {
    return device.isOnline
        ? AppResponsiveLayout(
            desktop: (ctx) => AppText.bodyMedium(device.isWired
                ? loc(context).ethernet
                : '${device.ssid}  •  ${device.band}'),
            mobile: (ctx) => device.isWired
                ? AppText.bodyMedium(loc(context).ethernet)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText.bodyMedium(device.ssid),
                      AppGap.xs(),
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
        if (widget.enableDeauth &&
            !device.isWired &&
            serviceHelper.isSupportClientDeauth()) ...[
          AppGap.lg(),
          AppIconButton(
            icon: AppIcon.font(
              AppFontIcons.bidirectional,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {
              widget.onItemDeauth?.call(device);
            },
          ),
        ],
        if (widget.enableDelete) ...[
          AppGap.lg(),
          AppIconButton(
            icon: AppIcon.font(
              AppFontIcons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: () {
              widget.onItemDelete?.call(device);
            },
          ),
        ],
      ],
    );
  }
}
