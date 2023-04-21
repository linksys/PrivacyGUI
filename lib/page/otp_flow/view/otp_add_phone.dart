import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/network/http/model/cloud_phone.dart';
import 'package:linksys_moab/network/http/model/region_code.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

import 'package:linksys_moab/util/error_code_handler.dart';
import 'package:linksys_moab/util/logger.dart';
import 'dart:convert';
import 'package:phone_number/phone_number.dart';

class OtpAddPhoneView extends ArgumentsConsumerStatefulView {
  const OtpAddPhoneView({Key? key, super.args, super.next}) : super(key: key);

  @override
  _OtpAddPhoneViewState createState() => _OtpAddPhoneViewState();
}

class _OtpAddPhoneViewState extends ConsumerState<OtpAddPhoneView> {
  final PhoneNumberUtil phoneNumberUtil = PhoneNumberUtil();
  TextEditingController phoneController = TextEditingController();

  bool hasInput = false;
  bool isInputInvalid = false;
  Map _countryCodes = {};
  RegionCode currentRegion = RegionCode(
    countryCode: 'US',
    countryName: 'United States',
    countryCallingCode: 1,
  ); // Default

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
      final phoneMethod = CommunicationMethod(
          method: CommunicationMethodType.sms.name.toUpperCase(),
          target: phoneNumber.e164,
          phone: CloudPhoneModel(
            country: currentRegion.countryCode,
            countryCallingCode: '+${currentRegion.countryCallingCode}',
            phoneNumber: phoneNumber.nationalNumber,
          ));

      context.read<OtpCubit>().onInputOtp(method: phoneMethod);
      final OtpFunction function = widget.args['function'] ?? OtpFunction.send;
      if (function == OtpFunction.add) {
        // String token = await context
        //     .read<AccountCubit>()
        //     .startAddCommunicationMethod(
        //       CommunicationMethod(
        //         method: CommunicationMethodType.sms.name.toUpperCase(),
        //         target: phoneNumber.e164,
        //         phone: CloudPhoneModel(
        //           country: currentRegion.countryCode,
        //           countryCallingCode: '+${currentRegion.countryCallingCode}',
        //           phoneNumber: phoneNumber.nationalNumber,
        //         ),
        //       ),
        //     );
        // context.read<OtpCubit>().updateToken(token);
        // context
        //     .read<OtpCubit>()
        //     .authChallenge(method: phoneMethod, token: token);
      }
      ref.read(navigationsProvider.notifier).push(OtpInputCodePath()
        ..next = widget.next
        ..args.addAll(widget.args));
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

  Future<void> updateRegion(RegionCode region) async {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 63, bottom: 7),
                child: Text(getAppLocalizations(context).phone),
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final selectedRegion = await showPopup(
                            ref: ref,
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
                        alignment: Alignment.center,
                        child: Text(
                          '+${currentRegion.countryCallingCode}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(
                                  color: isInputInvalid
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.primary),
                        ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ),
    );
  }
}
