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

class WebUiAccessView extends ArgumentsConsumerStatefulView {
  const WebUiAccessView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<WebUiAccessView> createState() => _WebUiAccessViewState();
}

class _WebUiAccessViewState extends ConsumerState<WebUiAccessView> {
  bool webUiAccess = false;

  @override
  void initState() {
    super.initState();

    // TODO: Get from cubit
    webUiAccess = false;
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: getAppLocalizations(context).web_ui_access,
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
              value: webUiAccess,
              title: getAppLocalizations(context).automatic_firmware_update,
              onChangedEvent: (value) {
                // TODO: Update status
                setState(() {
                  webUiAccess = value;
                });
              },
            ),
            const AppGap.regular(),
            SizedBox(
              width: Utils.getScreenWidth(context) * 0.7,
              child: AppText.descriptionSub(
                webUiAccess
                    ? getAppLocalizations(context).web_ui_access_on_description
                    : getAppLocalizations(context)
                        .web_ui_access_off_description,
                color: AppTheme.of(context).colors.ctaPrimaryDisable,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
