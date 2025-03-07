import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class ChangeNodeNameView extends ArgumentsConsumerStatefulView {
  const ChangeNodeNameView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<ChangeNodeNameView> createState() =>
      __ChangeNodeNameViewState();
}

class __ChangeNodeNameViewState extends ConsumerState<ChangeNodeNameView> {
  final TextEditingController nameController = TextEditingController();
  bool isChanged = false;

  @override
  void initState() {
    super.initState();
    final nodeDetail = ref.read(nodeDetailProvider);
    nameController.text = nodeDetail.location;
  }

  @override
  void dispose() {
    super.dispose();

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: getAppLocalizations(context).deviceName,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: Spacing.medium),
          child: AppTextButton.noPadding(
            getAppLocalizations(context).save,
            onTap: isChanged ? _checkInputData : null,
          ),
        )
      ],
      child: (context, constraints, scrollController) =>AppBasicLayout(
        content: Column(children: [
          AppTextField(
            headerText: getAppLocalizations(context).deviceName,
            controller: nameController,
            onChanged: _onNameChanged,
          )
        ]),
      ),
    );
  }

  void _checkInputData() {
    if (nameController.text.isNotEmpty) {
      final targetId = ref.read(nodeDetailIdProvider);

      ref
          .read(deviceManagerProvider.notifier)
          .updateDeviceNameAndIcon(
            targetId: targetId,
            newName: nameController.text,
            isLocation: true,
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
