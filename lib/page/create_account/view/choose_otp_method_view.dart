import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/customs/customs.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';
import 'package:phone_number/phone_number.dart';

class ChooseOTPMethodView extends ArgumentsStatefulView {
  const ChooseOTPMethodView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _ChooseOTPMethodState createState() => _ChooseOTPMethodState();
}

class _ChooseOTPMethodState extends State<ChooseOTPMethodView> {
  late List<OtpInfo> _methods = [];
  late OtpInfo selectedMethod;

  @override
  void initState() {
    super.initState();
    _methods = widget.args!['optMethods'] as List<OtpInfo>;

    selectedMethod = _methods.first;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Where should we send your code?',
        ),
        content: Column(
          children: [
            SizedBox(
              height: 80.0 * _methods.length,
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _methods.length,
                  itemBuilder: (context, index) => GestureDetector(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: SelectableItem(
                            text: _methods[index].method.name,
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
            ),
            Visibility(
              visible: selectedMethod.method == OtpMethod.email,
              child: Column(
                children: [
                  const SizedBox(
                    height: 61,
                  ),
                  PrimaryButton(
                    text: 'Send',
                    onPress: () {
                      NavigationCubit.of(context).push(EnterOtpPath());
                    },
                  ),
                ],
              ),
            ),
            Visibility(
              visible: selectedMethod.method == OtpMethod.sms,
              child: PhoneNumberView(
                onNext: () {
                  NavigationCubit.of(context).push(EnterOtpPath());
                },
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
                      context: context, config: SelectPhoneRegionCodePath());
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
          child: Column(
            children: [
              const SizedBox(
                height: 23,
              ),
              PrimaryButton(
                text: 'Send',
                onPress: widget.onNext,
              )
            ],
          ),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}