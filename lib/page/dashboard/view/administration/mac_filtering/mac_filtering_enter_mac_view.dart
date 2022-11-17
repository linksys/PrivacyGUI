import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/custom_title_input_field.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

import '../common_widget.dart';
import 'bloc/cubit.dart';

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
        administrationTwoLineTile(
          tileHeight: null,
          title: title(getAppLocalizations(context).enter_mac_address),
          value: TextFormField(
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-f]')),
              // allow only  digits
              MacAddressFormatter(),
              // custom class to format entered data from textField
              LengthLimitingTextInputFormatter(17)
              // restrict user to enter max 16 characters
            ],
            onChanged: (value) {
              setState(() {
                _isValid = _macValidator.validate(value);
                // TODO is exist
              });
            },
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                hintText: "00:00:00:00:00:00",
                filled: true,
                fillColor: Colors.grey[350]),
          ),
        ),
        box48(),
        PrimaryButton(text: getAppLocalizations(context).save,
          onPress: _isValid ? () {} : null,),
        ],
      ),
    ),);
  }
}

// this class will be called, when their is change in textField
class MacAddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,
      TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String enteredData = newValue.text; // get data enter by used in textField
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < enteredData.length; i++) {
      // add each character into String buffer
      buffer.write(enteredData[i]);
      int index = i + 1;
      if (index % 2 == 0 && enteredData.length != index) {
        buffer.write(":");
      }
    }

    return TextEditingValue(
        text: buffer.toString(), // final generated credit card number
        selection: TextSelection.collapsed(
            offset: buffer
                .toString()
                .length) // keep the cursor at end
    );
  }
}
