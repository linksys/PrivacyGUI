import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';

import '../../../../design/colors.dart';
import '../../../../localization/localization_hook.dart';
import '../../../../route/model/base_path.dart';
import '../../../../route/model/dashboard_path.dart';
import '../../../../route/navigation_cubit.dart';
import '../../../components/views/arguments_view.dart';

class CreateProfileDevicesSelectedView extends ArgumentsStatefulView {
  const CreateProfileDevicesSelectedView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<CreateProfileDevicesSelectedView> createState() =>
      _CreateProfileDevicesSelectedViewState();
}

class _CreateProfileDevicesSelectedViewState
    extends State<CreateProfileDevicesSelectedView> {
  final TextEditingController _textController = TextEditingController();

  final _devices = [
    DeviceInfo(name: 'Device 1', isSelected: false),
    DeviceInfo(name: 'Device 2', isSelected: false),
    DeviceInfo(name: 'Device 3', isSelected: false),
    DeviceInfo(name: 'Device 4', isSelected: false),
    DeviceInfo(name: 'Device 5', isSelected: false),
    DeviceInfo(name: 'Device 6', isSelected: false),
    DeviceInfo(name: 'Device 7', isSelected: false),
    DeviceInfo(name: 'Device 8', isSelected: false),
    DeviceInfo(name: 'Device 9', isSelected: false),
  ];

  @override
  Widget build(BuildContext context) {
    return BasePageView.bottomSheetModal(
      bottomSheet: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BaseAppBar(
          title: Text(
            getAppLocalizations(context).add_profile,
            style: TextStyle(
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
                final next = widget.next ?? UnknownPath();
                NavigationCubit.of(context).push(CreateProfileAvatarPath()
                  ..next = next);
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
                style: TextStyle(
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
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  itemBuilder: (context, index) => InkWell(
                    child: CheckboxSelectableItem(
                      title: _devices[index].name,
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
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceInfo {
  String name;
  bool isSelected;

  DeviceInfo({required this.name, required this.isSelected});
}
