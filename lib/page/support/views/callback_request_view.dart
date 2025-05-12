import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:privacy_gui/core/cloud/model/region_code.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/support/providers/support_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

class CallbackRequestView extends ArgumentsConsumerStatefulView {
  final List<Widget>? actions;

  const CallbackRequestView({
    Key? key,
    this.actions,
  }) : super(key: key);

  @override
  ConsumerState<CallbackRequestView> createState() =>
      _CallbackRequestViewState();
}

class _CallbackRequestViewState extends ConsumerState<CallbackRequestView> {
  bool isLoading = false;
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController regionCodeController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  final EmailValidator emailValidator = EmailValidator();
  bool enableSend = false;
  bool isValidEmail = true;
  bool isValidPhone = true;
  String messageLengteh = '0';
  final int messageLengthLimit = 2000;
  Map _countryCodes = {};
  RegionCode currentRegion = RegionCode(
    countryCode: 'US',
    countryName: 'United States',
    countryCallingCode: 1,
  ); // Default
  String? phoneNumberHint = '';

  @override
  void initState() {
    super.initState();

    loadPhoneSamples().then((_) {
      updateRegion(currentRegion);
    });
  }

  @override
  void dispose() {
    super.dispose();

    phoneNumberController.dispose();
    regionCodeController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            actions: widget.actions,
            bottomBar: _bottomBar(),
            title: loc(context).support,
            child: (context, constraints) => Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField.outline(
                  headerText: loc(context).email,
                  controller: emailController,
                  errorText: isValidEmail
                      ? null
                      : loc(context).oopsPleaseSpecifyValidEmailAddress,
                  onChanged: (text) {
                    if (text.isNotEmpty) {
                      setState(() {
                        isValidEmail = true;
                      });
                    }
                  },
                  onFocusChanged: (hasFocus) {
                    setState(() {
                      isValidEmail =
                          emailValidator.validate(emailController.text);
                    });
                    _onInputChanged();
                  },
                ),
                const AppGap.medium(),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField.outline(
                        headerText: loc(context).firstName,
                        controller: firstNameController,
                        onChanged: (text) {
                          _onInputChanged();
                        },
                      ),
                    ),
                    const AppGap.medium(),
                    Expanded(
                      child: AppTextField.outline(
                        headerText: loc(context).lastName,
                        controller: lastNameController,
                        onChanged: (text) {
                          _onInputChanged();
                        },
                      ),
                    ),
                  ],
                ),
                const AppGap.medium(),
                Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: InkWell(
                        onTap: () async {
                          final selectedRegion =
                              await context.pushNamed<RegionCode?>(
                                  RouteNamed.phoneRegionCode);
                          if (selectedRegion != null &&
                              selectedRegion != currentRegion) {
                            updateRegion(selectedRegion);
                            phoneNumberController.text = '';
                            _phoneNumberValidate('', currentRegion);
                            _onInputChanged();
                          }
                        },
                        child: AbsorbPointer(
                          child: AppTextField.outline(
                            semanticLabel: 'phone region code',
                            controller: regionCodeController
                              ..text = '+${currentRegion.countryCallingCode}',
                            readOnly: true,
                            errorText: isValidPhone ? null : '',
                          ),
                        ),
                      ),
                    ),
                    const AppGap.small2(),
                    Expanded(
                      child: AppTextField.outline(
                        controller: phoneNumberController,
                        inputType: TextInputType.number,
                        hintText: phoneNumberHint,
                        errorText: isValidPhone
                            ? null
                            : loc(context).pleaseEnterValidPhoneNumber,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        onChanged: (text) {
                          _phoneNumberValidate(text, currentRegion);
                          _onInputChanged();
                        },
                      ),
                    ),
                  ],
                ),
                const AppGap.medium(),
                AppTextField.outline(
                  maxLines: 5,
                  controller: messageController,
                  hintText: loc(context).message,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(messageLengthLimit)
                  ],
                  descriptionText:
                      '$messageLengteh/${messageLengthLimit.toString()}',
                  onChanged: (text) {
                    _onInputChanged();
                    setState(() {
                      messageLengteh = text.length.toString();
                    });
                  },
                ),
              ],
            ),
          );
  }

  PageBottomBar _bottomBar() {
    return PageBottomBar(
      positiveLabel: loc(context).send,
      isPositiveEnabled: enableSend,
      onPositiveTap: () async {
        setState(() {
          isLoading = true;
        });
        await ref
            .read(supportProvider.notifier)
            .startCreateTicket(
                email: emailController.text,
                firstName: firstNameController.text,
                lastName: lastNameController.text,
                phoneRegionCode: regionCodeController.text,
                phoneNumber: phoneNumberController.text,
                subject: messageController.text)
            .then((_) async {
          await ref.read(supportProvider.notifier).fetchTickets();
        }).onError((error, stackTrace) {
          showSimpleAppDialog(
            context,
            title: loc(context).failedExclamation,
            content:
                AppText.bodyMedium(loc(context).requestCallbackFailDescription),
            actions: [
              AppTextButton(
                loc(context).download,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                onTap: () async {
                  setState(() {
                    isLoading = true;
                  });
                  await ref
                      .read(supportProvider.notifier)
                      .download(context)
                      .whenComplete(() {
                    setState(() {
                      isLoading = false;
                    });
                  });
                  context.pop();
                },
              ),
              AppTextButton(
                loc(context).cancel,
                onTap: () {
                  context.pop();
                },
              ),
            ],
          );
        }).whenComplete(() {
          setState(() {
            isLoading = false;
          });
        });
      },
    );
  }

  Future<void> loadPhoneSamples() async {
    final String jsonText = await rootBundle
        .loadString('assets/resources/phone_number_examples.json');
    _countryCodes = json.decode(jsonText);
  }

  void updateRegion(RegionCode region) {
    setState(() {
      currentRegion = region;
      // Get phone number hint
      final String? phoneSample = _countryCodes[currentRegion.countryCode];
      phoneNumberHint = phoneSample ?? loc(context).phoneNumber;
    });
  }

  void _phoneNumberValidate(String text, RegionCode region) {
    IsoCode? isoCode;
    try {
      isoCode = IsoCode.fromJson(region.countryCode);
    } catch (error) {
      logger.d(error);
    }
    PhoneNumber phoneNumber =
        PhoneNumber.parse('${region.countryCallingCode}$text');
    if (isoCode != null) {
      phoneNumber = PhoneNumber.parse(
        '${region.countryCallingCode}$text',
        callerCountry: isoCode,
      );
    }
    setState(() {
      isValidPhone = phoneNumber.isValid();
    });
  }

  void _onInputChanged() {
    setState(() {
      enableSend = isValidEmail &&
          isValidPhone &&
          firstNameController.text.isNotEmpty &&
          lastNameController.text.isNotEmpty &&
          messageController.text.isNotEmpty;
    });
  }
}
