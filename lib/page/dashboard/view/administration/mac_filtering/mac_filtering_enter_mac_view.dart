import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/mac_input_field.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class MacFilteringEnterDeviceView extends ArgumentsStatefulView {
  const MacFilteringEnterDeviceView({super.key, super.next, super.args});

  @override
  State<MacFilteringEnterDeviceView> createState() =>
      _MacFilteringEnterDeviceViewState();
}

class _MacFilteringEnterDeviceViewState
    extends State<MacFilteringEnterDeviceView> {
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
    return StyledLinksysPageView(
      isCloseStyle: true,
      child: LinksysBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Column(
          children: [
            const LinksysGap.semiBig(),
            AppMacField(
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
            const LinksysGap.extraBig(),
            LinksysPrimaryButton(
              getAppLocalizations(context).save,
              onTap: _isValid ? () {} : null,
            ),
          ],
        ),
      ),
    );
  }
}
