import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/customs/customs.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';
import 'dart:convert';

import 'package:phone_number/phone_number.dart';


class CreateAccountPhoneView extends ArgumentsStatefulView {
  const CreateAccountPhoneView({
    Key? key, super.args
  }) : super(key: key);

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
                      final selectedRegion = await showPopup(context: context, config: SelectPhoneRegionCodePath());
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
                onPress: () {
                  // TODO TBD
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SecondaryButton(
              text: 'No thanks',
              onPress: () {
                // TODO TBD
              },
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}