import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PnpIspSettingsAuthView extends ConsumerStatefulWidget {
  const PnpIspSettingsAuthView({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<PnpIspSettingsAuthView> createState() => _PnpIspSettingsAuthViewState();
}

class _PnpIspSettingsAuthViewState extends ConsumerState<PnpIspSettingsAuthView> {
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: 'Enter your router’s ',//'Enter your router’s password to proceed',
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField.outline(
              headerText: loc(context).password,
              controller: _passwordController,
            ),
            const AppGap.extraBig(),
            AppTextButton.noPadding(
              'Where is it?',
              onTap: () {
                //TODO: Where is it?
              },
            ),
          ],
        ),
        footer: AppFilledButton.fillWidth(
          loc(context).next,
          onTap: () {
            // TODO: Verify router password
          },
        ),
      ),
    );
  }
}
