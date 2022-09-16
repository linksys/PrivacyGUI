import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/device/device.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/route.dart';

class EditDeviceNameView extends ArgumentsStatefulView {
  const EditDeviceNameView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<EditDeviceNameView> createState() => _EditDeviceNameViewState();
}

class _EditDeviceNameViewState extends State<EditDeviceNameView> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _textController.text =
        context.read<DeviceCubit>().state.selectedDeviceInfo?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // iconTheme:
        // IconThemeData(color: Theme.of(context).colorScheme.primary),
        elevation: 0,
        title: Text(
          getAppLocalizations(context).device_name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          SimpleTextButton(
            text: getAppLocalizations(context).save,
            onPressed: () {
              context
                  .read<DeviceCubit>()
                  .updateDeviceInfoName(null, _textController.text);
              NavigationCubit.of(context).pop();
            },
          ),
        ],
      ),
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        content: Column(
          children: [
            Row(
              children: [
                Text(
                  getAppLocalizations(context).device_name,
                  style: const TextStyle(fontSize: 14),
                ),
                box16(),
                Expanded(
                  child: TextField(
                    cursorColor: Colors.black,
                    controller: _textController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
