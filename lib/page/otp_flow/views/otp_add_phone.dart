import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/constants/default_country_codes.dart';
import 'package:privacy_gui/core/cloud/model/cloud_account.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/cloud/model/cloud_communication_method.dart';
import 'package:privacy_gui/core/cloud/model/cloud_phone.dart';
import 'package:privacy_gui/core/cloud/model/region_code.dart';
import 'package:privacy_gui/page/components/layouts/basic_header.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'dart:convert';

class OtpAddPhoneView extends ArgumentsConsumerStatefulView {
  const OtpAddPhoneView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _OtpAddPhoneViewState createState() => _OtpAddPhoneViewState();
}

class _OtpAddPhoneViewState extends ConsumerState<OtpAddPhoneView> {
  // final PhoneNumberUtil phoneNumberUtil = PhoneNumberUtil();
  TextEditingController phoneController = TextEditingController();

  CAMobile? editPhone;
  bool hasInput = false;
  bool isInputInvalid = false;
  Map _countryCodes = {};
  RegionCode currentRegion = RegionCode(
    countryCode: 'US',
    countryName: 'United States',
    countryCallingCode: 1,
  ); // Default

  /* =============


    TODO: Refactor this page if needed in the future because replace the 
    old phone number lib with other libs.


  ============= */

  @override
  void initState() {
    super.initState();
    editPhone = widget.args['phone'];
    loadPhoneSamples().then((_) {
      final data = List.from(defaultCountryCodes['countryCodes'])
          .firstWhereOrNull((element) =>
              '+${element['countryCode']}' == editPhone?.countryCode);

      return data != null ? RegionCode.fromJson(data) : currentRegion;
    }).then((region) => updateRegion(region));
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> loadPhoneSamples() async {
    final String jsonText = await rootBundle
        .loadString('assets/resources/phone_number_examples.json');
    _countryCodes = json.decode(jsonText);
  }

  void _onInputChanged(String text) {
    setState(() {
      hasInput = text.isNotEmpty;
      isInputInvalid = false;
    });
  }

  void _checkPhoneNumber() async {
    final router = GoRouter.of(context);
    final userInputPhoneNumber = phoneController.text;
    _setLoading(true);
    try {
      // final phoneNumber = await phoneNumberUtil.parse(userInputPhoneNumber,
      //     regionCode: currentRegion.countryCode);
      // final phoneMethod = CommunicationMethod(
      //     method: 'SMS',
      //     target: phoneNumber.e164,
      //     phone: CloudPhoneModel(
      //       country: currentRegion.countryCode,
      //       countryCallingCode: '+${currentRegion.countryCallingCode}',
      //       phoneNumber: phoneNumber.nationalNumber,
      //     ));
      // router.pop(phoneMethod);
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

  _setLoading(bool isLoading) {}

  Future<void> updateRegion(RegionCode region) async {
    setState(() {
      currentRegion = region;
    });
    // phoneController = PhoneNumberEditingController.fromValue(
    //   phoneNumberUtil,
    //   phoneController.value,
    //   regionCode: currentRegion.countryCode,
    //   behavior: PhoneInputBehavior.strict,
    // );
    phoneController.addListener(() {
      logger.d('phone number changed');
      _onInputChanged(phoneController.value.text);
    });
  }

  // Future<String> _getPhoneHint(String countryCode) async {
  //   final String? phoneSample = _countryCodes[countryCode];
  //   if (phoneSample != null) {
  //     return await phoneNumberUtil.format(
  //         phoneSample, currentRegion.countryCode);
  //   } else {
  //     return getAppLocalizations(context).phone;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      scrollable: true,
      child:(context, constraints, scrollController) => AppBasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).otpAddPhoneNumber,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: Spacing.large5,
                bottom: Spacing.small2,
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
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        width: 1,
                      )),
                      alignment: Alignment.center,
                      child: AppText.bodyLarge(
                        '+${currentRegion.countryCallingCode}',
                        color: isInputInvalid
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const AppGap.small3(),
                  // Expanded(
                  //   child: FutureBuilder<String>(
                  //       future: _getPhoneHint(currentRegion.countryCode),
                  //       initialData: getAppLocalizations(context).phone,
                  //       builder: (context, data) {
                  //         return AppTextField(
                  //           controller: phoneController
                  //             ..text = editPhone?.phoneNumber ?? '',
                  //           hintText:
                  //               data.data ?? getAppLocalizations(context).phone,
                  //           inputType: TextInputType.number,
                  //           onChanged: _onInputChanged,
                  //         );
                  //       }),
                  // ),
                ],
              ),
            ),
            const AppGap.small2(),
            Offstage(
              offstage: !isInputInvalid,
              child: AppText.bodyLarge(
                errorCodeHelper(context, errorInvalidPhone) ?? '',
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFilledButton.fillWidth(
              getAppLocalizations(context).sendCode,
              onTap: hasInput ? _checkPhoneNumber : null,
            ),
          ],
        ),
      ),
    );
  }
}
