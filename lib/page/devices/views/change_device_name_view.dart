import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class ChangeDeviceNameView extends ArgumentsConsumerStatefulView {
  const ChangeDeviceNameView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<ChangeDeviceNameView> createState() =>
      __ChangeDeviceNameViewState();
}

class __ChangeDeviceNameViewState extends ConsumerState<ChangeDeviceNameView> {
  final TextEditingController nameController = TextEditingController();
  bool isChanged = false;

  @override
  void initState() {
    super.initState();
    final deviceDetail = ref.read(externalDeviceDetailProvider);
    nameController.text = deviceDetail.item.name;
  }

  @override
  void dispose() {
    super.dispose();

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: getAppLocalizations(context).device_name,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: Spacing.regular),
          child: AppTextButton.noPadding(
            getAppLocalizations(context).save,
            onTap: isChanged ? _checkInputData : null,
          ),
        )
      ],
      child: AppBasicLayout(
        content: Column(children: [
          AppTextField(
            headerText: getAppLocalizations(context).device_name,
            controller: nameController,
            onChanged: _onNameChanged,
          )
        ]),
      ),
    );
  }

  void _checkInputData() {
    if (nameController.text.isNotEmpty) {
      final targetId = ref.read(deviceDetailIdProvider);

      ref
          .read(deviceManagerProvider.notifier)
          .updateDeviceNameAndIcon(
            targetId: targetId,
            newName: nameController.text,
            isLocation: false,
          )
          .then((value) {
        context.pop();
      });
    }
  }

  void _onNameChanged(String text) {
    setState(() {
      isChanged = true;
      // nameController.text = text;
    });
  }
}