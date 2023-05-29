import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class FirmwareUpdateView extends ArgumentsConsumerStatefulView {
  const FirmwareUpdateView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  ConsumerState<FirmwareUpdateView> createState() => _FirmwareUpdateViewState();
}

class _FirmwareUpdateViewState extends ConsumerState<FirmwareUpdateView> {
  bool autoUpdate = false;

  @override
  void initState() {
    super.initState();

    // TODO: Get from cubit
    autoUpdate = false;
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: getAppLocalizations(context).firmware_update,
      actions: [
        AppTertiaryButton(
          getAppLocalizations(context).save,
          onTap: () {},
        ),
      ],
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.semiBig(),
            AppPanelWithSwitch(
              value: autoUpdate,
              title: getAppLocalizations(context).automatic_firmware_update,
            ),
            const AppGap.regular(),
            SizedBox(
              width: Utils.getScreenWidth(context) * 0.7,
              child: AppText.descriptionSub(
                getAppLocalizations(context).auto_update_firmware_description,
                color: AppTheme.of(context).colors.ctaPrimaryDisable,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
