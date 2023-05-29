import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/device/_device.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class EditDeviceNameView extends ArgumentsConsumerStatefulView {
  const EditDeviceNameView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  ConsumerState<EditDeviceNameView> createState() => _EditDeviceNameViewState();
}

class _EditDeviceNameViewState extends ConsumerState<EditDeviceNameView> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _textController.text =
        context.read<DeviceCubit>().state.selectedDeviceInfo?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: getAppLocalizations(context).device_name,
      actions: [
        AppTertiaryButton(
          getAppLocalizations(context).save,
          onTap: () {
            context
                .read<DeviceCubit>()
                .updateDeviceInfoName(
                    context.read<DeviceCubit>().state.selectedDeviceInfo!,
                    _textController.text)
                .then((value) => ref.read(navigationsProvider.notifier).pop());
          },
        ),
      ],
      child: AppBasicLayout(
        content: Column(
          children: [
            Row(
              children: [
                AppText.descriptionMain(
                  getAppLocalizations(context).device_name,
                ),
                const AppGap.regular(),
                Expanded(
                  child: AppTextField(
                    controller: _textController,
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
