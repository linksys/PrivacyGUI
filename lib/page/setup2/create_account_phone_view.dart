import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:moab_poc/page/setup2/region_picker_view.dart';
import 'package:phone_number/phone_number.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/primary_text_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

import '../../route/route.dart';

class CreateAccountPhoneView extends StatefulWidget {
  const CreateAccountPhoneView({
    Key? key,
    required this.onSave,
    required this.onSkip,
  }) : super(key: key);

  final void Function() onSave;
  final void Function() onSkip;

  @override
  _CreateAccountPhoneViewState createState() => _CreateAccountPhoneViewState();
}

class _CreateAccountPhoneViewState extends State<CreateAccountPhoneView> {
  final PhoneNumberUtil phoneNumberUtil = PhoneNumberUtil();
  TextEditingController phoneController = TextEditingController();

  bool hasInput = false;
  Map _countryCodes = {};
  PhoneRegion currentRegion = PhoneRegion('United States', 'US', 1); // Default
  String phoneHint = 'Phone';

  @override
  void initState() {
    loadPhoneSamples();
    updateRegion(currentRegion);

    super.initState();
  }

  Future<void> loadPhoneSamples() async {
    final String jsonText = await rootBundle
        .loadString('assets/resources/phone_number_examples.json');
    _countryCodes = json.decode(jsonText);
  }

  void _checkPhoneNumber(_) {
    setState(() {
      hasInput = phoneController.text.isNotEmpty;
    });
  }

  Future<void> updateRegion(PhoneRegion region) async {
    currentRegion = region;
    phoneController = PhoneNumberEditingController.fromValue(
      phoneNumberUtil,
      phoneController.value,
      regionCode: currentRegion.countryCode,
      behavior: PhoneInputBehavior.strict,
    );

    final String? phoneSample = _countryCodes[currentRegion.countryCode];
    if (phoneSample != null) {
      phoneHint = await phoneNumberUtil.format(phoneSample, currentRegion.countryCode);
    } else {
      phoneHint = 'Phone';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Send a code to your phone next time?',
        ),
        content: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 63, bottom: 7),
              child: Text('Phone'),
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final selectedRegion = await showPopup(context: context, path: SelectPhoneRegionCodePath());
                      if (selectedRegion != null) {
                        updateRegion(selectedRegion);
                      }
                      print('region picker result: $selectedRegion');
                    },
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                          border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      )),
                      child: Text(
                        '+${currentRegion.callingCode}',
                        style: Theme.of(context).textTheme.bodyText1?.copyWith(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      alignment: Alignment.center,
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(
                    child: PrimaryTextField(
                      controller: phoneController,
                      hintText: phoneHint,
                      onChanged: _checkPhoneNumber,
                      inputType: TextInputType.number,
                    ),
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.stretch,
              ),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        footer: Column(
          children: [
            Visibility(
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              visible: hasInput,
              child: PrimaryButton(
                text: 'Save',
                onPress: widget.onSave,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SecondaryButton(
              text: 'No thanks',
              onPress: widget.onSkip,
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
