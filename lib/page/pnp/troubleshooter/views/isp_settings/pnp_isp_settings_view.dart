import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PnpIspSettingsView extends ArgumentsConsumerStatefulView {
  const PnpIspSettingsView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<PnpIspSettingsView> createState() => _PnpIspSettingsViewState();
}

class _PnpIspSettingsViewState extends ConsumerState<PnpIspSettingsView> {
  final _accountNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vlanController = TextEditingController();
  late bool hasVlanID;

  @override
  void initState() {
    hasVlanID = widget.args['needVlanId'] ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: 'Enter ISP settings',
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.bodyLarge(
              'Your PPPoE account name and password are provided by your Internet Service Provider (ISP). If you aren’t sure about yours, we recommend contacting your ISP.',
            ),
            const AppGap.extraBig(),
            AppTextField.outline(
              headerText: loc(context).accountName,
              controller: _accountNameController,
            ),
            const AppGap.semiBig(),
            AppTextField.outline(
              headerText: loc(context).password,
              controller: _passwordController,
            ),
            Visibility(
              visible: hasVlanID,
              replacement: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppGap.extraBig(),
                  AppTextButton.noPadding(
                    '+ Add VLAN ID',
                    onTap: () {
                      setState(() {
                        hasVlanID = true;
                      });
                    },
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppGap.semiBig(),
                  AppTextField.outline(
                    headerText: 'VLAN ID',
                    controller: _vlanController,
                  ),
                  const AppGap.extraBig(),
                  AppTextButton.noPadding(
                    '- Remove VLAN ID',
                    onTap: () {
                      setState(() {
                        hasVlanID = false;
                      });
                    },
                  ),
                ],
              ),
            )
          ],
        ),
        footer: AppFilledButton.fillWidth(
          loc(context).next,
          onTap: () {
            //
          },
        ),
      ),
    );
  }
}
