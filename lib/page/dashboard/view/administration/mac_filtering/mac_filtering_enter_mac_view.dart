import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/mac_input_field.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

class MacFilteringEnterDeviceView extends ArgumentsStatefulView {
  const MacFilteringEnterDeviceView({super.key, super.next, super.args});

  @override
  State<MacFilteringEnterDeviceView> createState() =>
      _MacFilteringEnterDeviceViewState();
}

class _MacFilteringEnterDeviceViewState
    extends State<MacFilteringEnterDeviceView> {
  final InputValidator _macValidator = InputValidator([MACAddressRule()]);
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
    return BasePageView.withCloseButton(
      context,
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Column(
          children: [
            box24(),
            MACInputField(
              titleText: getAppLocalizations(context).enter_mac_address,
              onChanged: (value) {
                setState(() {
                  _isValid = _macValidator.validate(value);
                  // TODO is exist
                });
              },
            ),
            box48(),
            PrimaryButton(
              text: getAppLocalizations(context).save,
              onPress: _isValid ? () {} : null,
            ),
          ],
        ),
      ),
    );
  }
}
