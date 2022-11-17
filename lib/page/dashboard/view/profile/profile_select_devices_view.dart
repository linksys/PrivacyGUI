import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/device/_device.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/profile_group_path.dart';
import '../../../../design/colors.dart';
import '../../../../localization/localization_hook.dart';
import '../../../../route/model/base_path.dart';
import '../../../../route/navigation_cubit.dart';
import '../../../components/views/arguments_view.dart';

class ProfileSelectDevicesView extends ArgumentsStatefulView {
  const ProfileSelectDevicesView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<ProfileSelectDevicesView> createState() =>
      _CreateProfileDevicesSelectedViewState();
}

class _CreateProfileDevicesSelectedViewState
    extends State<ProfileSelectDevicesView> {
  List<DevicePickerItem> _devices = [];

  @override
  void initState() {
    super.initState();
    context
        .read<DeviceCubit>()
        .updateSelectedInterval(DeviceListInfoScope.profile);
    context.read<DeviceCubit>().fetchDeviceList().then((_) {
      _devices = context
          .read<DeviceCubit>()
          .getDisplayedDeviceList()
          .map((e) => DevicePickerItem(device: e, isSelected: false))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.bottomSheetModal(
      bottomSheet: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BaseAppBar(
          title: Text(
            getAppLocalizations(context).add_profile,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => NavigationCubit.of(context).pop(),
            ),
          ],
          action: [
            TextButton(
              onPressed: () {
                bool willReturnBack = widget.args['return'] ?? false;
                final selectedDevices = _devices
                    .where((element) => element.isSelected)
                    .map((e) => e.device)
                    .toList();
                if (selectedDevices.isNotEmpty) {
                  if (willReturnBack) {
                    NavigationCubit.of(context).popWithResult(selectedDevices);
                  } else {
                    context.read<ProfilesCubit>().createProfile(
                        devices:
                            List.from(selectedDevices.map((e) => ProfileDevice(
                                  deviceId: e.deviceID,
                                  name: e.name,
                                  macAddress: e.macAddress,
                                ))));
                    final next = widget.next ?? UnknownPath();
                    NavigationCubit.of(context)
                        .push(CreateProfileAvatarPath()..next = next);
                  }
                } else {
                  showOkAlertDialog(
                      context: context,
                      title: 'At least 1 device is required for a profile.');
                }
              },
              child: Text(
                getAppLocalizations(context).next,
                style:
                    const TextStyle(fontSize: 13, color: MoabColor.primaryBlue),
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 38),
              Text(
                getAppLocalizations(context).select_devices,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 13),
              Text(getAppLocalizations(context).select_devices_description),
              const SizedBox(height: 18),
              SimpleTextButton.noPadding(
                text: getAppLocalizations(context).i_dont_see_my_device,
                onPressed: () {},
              ),
              Flexible(
                child: BlocBuilder<DeviceCubit, DeviceState>(
                  builder: (context, state) => ListView.builder(
                    shrinkWrap: true,
                    itemCount: _devices.length,
                    itemBuilder: (context, index) => InkWell(
                      child: CheckboxSelectableItem(
                        title: _devices[index].device.name,
                        isSelected: _devices[index].isSelected,
                        height: 65,
                      ),
                      onTap: () {
                        setState(() {
                          _devices[index].isSelected =
                              !_devices[index].isSelected;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DevicePickerItem {
  DeviceDetailInfo device;
  bool isSelected;

  DevicePickerItem({required this.device, required this.isSelected});
}
