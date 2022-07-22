import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/customs/customs.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_cubit.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_state.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/logger.dart';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
      phoneHint = getAppLocalizations(context).phone;
    }
    setState(() {});
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
                          color: Theme.of(context).colorScheme.primary,
                          width: 1,
                        )),
                        child: Text(
                          '+${currentRegion.callingCode}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(
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
                  text: getAppLocalizations(context).otp_send_code,
                  onPress: () {
                    _onSend(OtpInfo(
                        method: OtpMethod.sms,
                        data:
                            '+${currentRegion.callingCode}${phoneController.text}'));
                  },
                ),
              ),
            ],
          ),
          alignment: CrossAxisAlignment.start,
        ),
      ),
    );
  }

  _onSend(OtpInfo method) async {
    logger.d('Phone number: ${phoneController.text}');
    _setLoading(true);
    await context
        .read<AuthBloc>()
        .authChallenge(method, context.read<AuthBloc>().state.vToken)
        .then((value) => context.read<OtpCubit>().onInputOtp(info: method));
    _setLoading(false);
  }

  _setLoading(bool isLoading) {
    context.read<OtpCubit>().setLoading(isLoading);
  }
}
