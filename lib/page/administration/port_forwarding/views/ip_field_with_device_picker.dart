import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/picker/device_picker.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/buttons/button.dart';
import 'package:linksys_widgets/widgets/input_field/ip_form_field.dart';

class AppIpFieldWithDevicePicker extends StatelessWidget {
  final TextEditingController controller;
  final bool octet1ReadOnly;
  final bool octet2ReadOnly;
  final bool octet3ReadOnly;
  final bool octet4ReadOnly;
  final List<DeviceListItem> deviceList;
  final String Function(DeviceListItem)? selectedResult;

  const AppIpFieldWithDevicePicker({
    super.key,
    required this.controller,
    required this.octet1ReadOnly,
    required this.octet2ReadOnly,
    required this.octet3ReadOnly,
    required this.octet4ReadOnly,
    required this.deviceList,
    this.selectedResult,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppIPFormField(
            controller: controller,
            octet1ReadOnly: octet1ReadOnly,
            octet2ReadOnly: octet2ReadOnly,
            octet3ReadOnly: octet3ReadOnly,
            octet4ReadOnly: octet4ReadOnly,
          ),
        ),
        AppIconButton(
          icon: getCharactersIcons(context).devicesDefault,
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
