import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/provider/otp/otp.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/core/cloud/model/cloud_communication_method.dart';
import 'package:linksys_app/core/cloud/model/cloud_phone.dart';
import 'package:linksys_app/core/cloud/model/region_code.dart';
import 'package:linksys_app/page/components/layouts/basic_header.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/error_code_handler.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'dart:convert';
import 'package:phone_number/phone_number.dart';

class OtpAddPhoneView extends ArgumentsConsumerStatefulView {
  const OtpAddPhoneView({
    Key? key,
    super.args,
  }) : super(key: key);

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

      ref.read(otpProvider.notifier).onInputOtp(method: phoneMethod);
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
      context.pushNamed(RouteNamed.otpInputCode, queryParameters: widget.args);
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
    ref.read(otpProvider.notifier).setLoading(isLoading);
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
    final state = ref.watch(otpProvider);
    return StyledAppPageView(
      scrollable: true,
      child: AppBasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).otp_add_phone_number,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPadding(
              padding: const AppEdgeInsets.only(
                top: AppGapSize.extraBig,
                bottom: AppGapSize.semiSmall,
              ),
              child: AppText.bodyLarge(getAppLocalizations(context).phone),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final selectedRegion = await context
                          .pushNamed<RegionCode?>(RouteNamed.phoneRegionCode);
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
                      child: AppText.bodyLarge(
                        '+${currentRegion.countryCallingCode}',
                        color: isInputInvalid
                            ? ConstantColors.tertiaryRed
                            : ConstantColors.tertiaryRed,
                      ),
                    ),
                  ),
                  const AppGap.small(),
                  Expanded(
                    child: FutureBuilder<String>(
                        future: _getPhoneHint(currentRegion.countryCode),
                        initialData: getAppLocalizations(context).phone,
                        builder: (context, data) {
                          return AppTextField(
                            controller: phoneController,
                            hintText:
                                data.data ?? getAppLocalizations(context).phone,
                            onChanged: _onInputChanged,
                            inputType: TextInputType.number,
                          );
                        }),
                  ),
                ],
              ),
            ),
            const AppGap.semiSmall(),
            Offstage(
              offstage: !isInputInvalid,
              child: AppText.bodyLarge(
                generalErrorCodeHandler(context, errorInvalidPhone),
                color: ConstantColors.tertiaryRed,
              ),
            ),
          ],
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Visibility(
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              visible: hasInput,
              child: AppPrimaryButton(
                getAppLocalizations(context).otp_send_code,
                onTap: _checkPhoneNumber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
