import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class MacFilteringEnterDeviceView extends ArgumentsConsumerStatefulView {
  const MacFilteringEnterDeviceView({super.key, super.args});

  @override
  ConsumerState<MacFilteringEnterDeviceView> createState() =>
      _MacFilteringEnterDeviceViewState();
}

class _MacFilteringEnterDeviceViewState
    extends ConsumerState<MacFilteringEnterDeviceView> {
  final InputValidator _macValidator = InputValidator([MACAddressRule()]);
  final TextEditingController _macController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.close,
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Column(
          children: [
            const AppGap.semiBig(),
            AppTextField.macAddress(
              controller: _macController,
              headerText: getAppLocalizations(context).enter_mac_address,
              hintText: getAppLocalizations(context).mac_address,
              onChanged: (value) {
                setState(() {
                  _isValid = _macValidator.validate(value);
                  // TODO is exist
                });
              },
            ),
            const AppGap.extraBig(),
            AppFilledButton(
              getAppLocalizations(context).save,
              onTap: _isValid ? () {} : null,
            ),
          ],
        ),
      ),
    );
  }
}
