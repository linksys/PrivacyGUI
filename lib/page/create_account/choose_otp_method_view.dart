import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:phone_number/phone_number.dart';

import '../../route/moab_router.dart';
import '../../route/path_model.dart';
import '../components/base_components/input_fields/primary_text_field.dart';
import '../components/base_components/selectable_item.dart';
import '../setup2/region_picker_view.dart';

class ChooseOTPMethodView extends StatefulWidget {
  final String email;
  final void Function() onNext;

  const ChooseOTPMethodView(
      {Key? key, required this.email, required this.onNext})
      : super(key: key);

  @override
  _ChooseOTPMethodState createState() => _ChooseOTPMethodState();
}

class _ChooseOTPMethodState extends State<ChooseOTPMethodView> {
  final List<String> _methods = [];
  late String selectedMethod;

  @override
  void initState() {
    super.initState();

    _methods.add('Text');
    _methods.add(widget.email);
    selectedMethod = _methods.first;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      // scrollable: true,
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Where should we send your code?',
        ),
        content: Column(
          children: [
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _methods.length,
                itemBuilder: (context, index) => GestureDetector(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: SelectableItem(
                          text: _methods[index],
                          isSelected: selectedMethod == _methods[index],
                          height: 66,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedMethod = _methods[index];
                        });
                      },
                    )),
            Visibility(
              visible: selectedMethod == widget.email,
              child: Column(
                children: [
                  const SizedBox(
                    height: 61,
                  ),
                  PrimaryButton(
                    text: 'Send',
                    onPress: widget.onNext,
                  ),
                ],
              ),
            ),
            Visibility(
              visible: selectedMethod == 'Text',
              child: PhoneNumberView(
                onNext: widget.onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneNumberView extends StatefulWidget {
  const PhoneNumberView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  @override
  _PhoneNumberViewState createState() => _PhoneNumberViewState();
}

class _PhoneNumberViewState extends State<PhoneNumberView> {
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
      phoneHint =
          await phoneNumberUtil.format(phoneSample, currentRegion.countryCode);
    } else {
      phoneHint = 'Phone';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 48, bottom: 7),
          child: Text('Phone'),
        ),
        IntrinsicHeight(
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final selectedRegion = await showPopup(
                      context: context, path: SelectPhoneRegionCodePath());
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
        const SizedBox(
          height: 12,
        ),
        Text(
          'Standard message and data rates apply.',
          style: Theme.of(context)
              .textTheme
              .headline4
              ?.copyWith(color: Theme.of(context).colorScheme.surface),
        ),
        Visibility(
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          visible: hasInput,
          child: PrimaryButton(
            text: 'Send',
            onPress: widget.onNext,
          ),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

enum OTPType {
  text,
  email,
}