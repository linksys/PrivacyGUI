import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/constants/constants.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/network/http/model/cloud_phone.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/customs/customs.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_cubit.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_state.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/error_code_handler.dart';
import 'package:moab_poc/util/logger.dart';
import 'dart:convert';
import 'package:phone_number/phone_number.dart';

class OtpAddPhoneView extends ArgumentsStatefulView {
  const OtpAddPhoneView({Key? key, super.args}) : super(key: key);

  @override
  _OtpAddPhoneViewState createState() => _OtpAddPhoneViewState();
}

class _OtpAddPhoneViewState extends State<OtpAddPhoneView> {
  final PhoneNumberUtil phoneNumberUtil = PhoneNumberUtil();
  TextEditingController phoneController = TextEditingController();

  bool hasInput = false;
  bool isInputInvalid = false;
  Map _countryCodes = {};
  PhoneRegion currentRegion = PhoneRegion('United States', 'US', 1); // Default

  @override
  void initState() {
    super.initState();
    loadPhoneSamples().then((_) => updateRegion(currentRegion));
  }

  Future<void> loadPhoneSamples() async {
    final String jsonText = await rootBundle
        .loadString('assets/resources/phone_number_examples.json');
    _countryCodes = json.decode(jsonText);
  }

  void _onInputChanged(text) {
    setState(() {
      hasInput = text.isNotEmpty;
      isInputInvalid = false;
    });
  }

  void _checkPhoneNumber() async {
    final userInputPhoneNumber = phoneController.text;
    _setLoading(true);
    try {
      final phoneNumber = await phoneNumberUtil.parse(userInputPhoneNumber,
          regionCode: currentRegion.countryCode);
      context.read<OtpCubit>().onInputOtp(
              info: OtpInfo(
            method: OtpMethod.sms,
            data: phoneNumber.e164,
            phoneNumber: CloudPhoneModel(
              country: currentRegion.countryCode,
              countryCallingCode: '+${currentRegion.callingCode}',
              phoneNumber: phoneNumber.nationalNumber,
            ),
          ));
    } catch (e) {
      logger.e(
          'AddPhone: Special error: [$userInputPhoneNumber] is valid but cannot be parsed');
      setState(() {
        isInputInvalid = true;
      });
    } finally {
      _setLoading(false);
    }
  }

  _setLoading(bool isLoading) {
    context.read<OtpCubit>().setLoading(isLoading);
  }

  Future<void> updateRegion(PhoneRegion region) async {
    setState(() {
      currentRegion = region;
    });
    phoneController = PhoneNumberEditingController.fromValue(
      phoneNumberUtil,
      phoneController.value,
      regionCode: currentRegion.countryCode,
      behavior: PhoneInputBehavior.strict,
    );
  }

  Future<String> _getPhoneHint(String countryCode) async {
    final String? phoneSample = _countryCodes[countryCode];
    if (phoneSample != null) {
      return await phoneNumberUtil.format(
          phoneSample, currentRegion.countryCode);
    } else {
      return getAppLocalizations(context).phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpCubit, OtpState>(
      builder: (context, state) => BasePageView(
        scrollable: true,
        child: BasicLayout(
          header: BasicHeader(
            title: getAppLocalizations(context).otp_add_phone_number,
          ),
          content: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 63, bottom: 7),
                child: Text(getAppLocalizations(context).phone),
              ),
              IntrinsicHeight(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final selectedRegion = await showPopup(
                            context: context,
                            config: SelectPhoneRegionCodePath());
                        if (selectedRegion != null) {
                          updateRegion(selectedRegion);
                        }
                      },
                      child: Container(
                        width: 60,
                        decoration: BoxDecoration(
                            border: Border.all(
                          color: isInputInvalid
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                          width: 1,
                        )),
                        child: Text(
                          '+${currentRegion.callingCode}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(
                                  color: isInputInvalid
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.primary),
                        ),
                        alignment: Alignment.center,
                      ),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: FutureBuilder<String>(
                          future: _getPhoneHint(currentRegion.countryCode),
                          initialData: getAppLocalizations(context).phone,
                          builder: (context, data) {
                            return PrimaryTextField(
                              controller: phoneController,
                              hintText: data.data ??
                                  getAppLocalizations(context).phone,
                              onChanged: _onInputChanged,
                              inputType: TextInputType.number,
                              errorColor: Colors.red,
                              isError: isInputInvalid,
                            );
                          }),
                    ),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Offstage(
                offstage: !isInputInvalid,
                child: Text(
                  generalErrorCodeHandler(context, errorInvalidPhone),
                  style: Theme.of(context)
                      .textTheme
                      .headline3
                      ?.copyWith(color: Colors.red),
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
                  text: getAppLocalizations(context).otp_send_code,
                  onPress: _checkPhoneNumber,
                ),
              ),
            ],
          ),
          alignment: CrossAxisAlignment.start,
        ),
      ),
    );
  }
}
