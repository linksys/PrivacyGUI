import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/picker/device_picker.dart';
import 'package:privacy_gui/page/devices/_devices.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/input_field/ipv6_form_field.dart';

class AppIpv6FieldWithDevicePicker extends StatelessWidget {
  final TextEditingController controller;
  final bool octet1ReadOnly;
  final bool octet2ReadOnly;
  final bool octet3ReadOnly;
  final bool octet4ReadOnly;
  final bool octet5ReadOnly;
  final bool octet6ReadOnly;
  final bool octet7ReadOnly;
  final bool octet8ReadOnly;
  final List<DeviceListItem> deviceList;
  final String Function(DeviceListItem)? selectedResult;

  const AppIpv6FieldWithDevicePicker({
    super.key,
    required this.controller,
    this.octet1ReadOnly = false,
    this.octet2ReadOnly = false,
    this.octet3ReadOnly = false,
    this.octet4ReadOnly = false,
    this.octet5ReadOnly = false,
    this.octet6ReadOnly = false,
    this.octet7ReadOnly = false,
    this.octet8ReadOnly = false,
    required this.deviceList,
    this.selectedResult,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppIPv6FormField(
            controller: controller,
            octet1ReadOnly: octet1ReadOnly,
            octet2ReadOnly: octet2ReadOnly,
            octet3ReadOnly: octet3ReadOnly,
            octet4ReadOnly: octet4ReadOnly,
            octet5ReadOnly: octet5ReadOnly,
            octet6ReadOnly: octet6ReadOnly,
            octet7ReadOnly: octet7ReadOnly,
            octet8ReadOnly: octet8ReadOnly,
          ),
        ),
        AppIconButton(
          icon: LinksysIcons.devices,
          onTap: deviceList.isEmpty
              ? null
              : () async {
                  final items =
                      await showModalBottomSheet<List<DeviceListItem>>(
                          context: context,
                          useRootNavigator: true,
                          useSafeArea: true,
                          isDismissible: false,
                          enableDrag: false,
                          builder: (context) {
                            return SingleChildScrollView(
                              child: DevicePicker(
                                type: DevicePickerType.grid,
                                isEnabledMultipleChoice: false,
                                devices: deviceList,
                                onSubmit: (items) {
                                  GoRouter.of(context).pop(items);
                                },
                              ),
                            );
                          });
                  if (items?.first != null) {
                    controller.text = selectedResult?.call(items!.first) ?? '';
                  }
                },
        ),
      ],
    );
  }
}
