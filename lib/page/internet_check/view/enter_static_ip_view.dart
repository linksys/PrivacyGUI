import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/internet_check/cubit.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

class EnterStaticIpView extends ConsumerStatefulWidget {
  const EnterStaticIpView({Key? key}) : super(key: key);

  @override
  ConsumerState<EnterStaticIpView> createState() => _EnterStaticIpViewState();
}

class _EnterStaticIpViewState extends ConsumerState<EnterStaticIpView> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController subnetController = TextEditingController();
  final TextEditingController gatewayController = TextEditingController();
  final TextEditingController dns1Controller = TextEditingController();
  final TextEditingController dns2Controller = TextEditingController();
  final IpAddressRequiredValidator ipAddressValidator =
      IpAddressRequiredValidator();
  final SubnetValidator subnetValidator = SubnetValidator();
  final IpAddressRequiredValidator gatewayValidator =
      IpAddressRequiredValidator();
  final IpAddressRequiredValidator dns1Validator = IpAddressRequiredValidator();
  final IpAddressValidator dns2Validator = IpAddressValidator();

  bool hasOtherErrors = false;
  bool isIpInvalid = false;
  bool isSubnetInvalid = false;
  bool isGatewayInvalid = false;
  bool isDns1Invalid = false;
  bool isDns2Invalid = false;

  void _validateInputData() async {
    if (!ipAddressValidator.validate(ipController.text)) {
      setState(() {
        isIpInvalid = true;
      });
    }

    if (!subnetValidator.validate(subnetController.text)) {
      setState(() {
        isSubnetInvalid = true;
      });
    }

    if (!gatewayValidator.validate(gatewayController.text)) {
      setState(() {
        isGatewayInvalid = true;
      });
    }

    if (!dns1Validator.validate(dns1Controller.text)) {
      setState(() {
        isDns1Invalid = true;
      });
    }

    // DNS2 is optional
    if (!dns2Validator.validate(dns2Controller.text)) {
      setState(() {
        isDns2Invalid = true;
      });
    }

    if (!isIpInvalid &&
        !isSubnetInvalid &&
        !isGatewayInvalid &&
        !isDns1Invalid &&
        !isDns2Invalid) {
      bool connectedWAN = await context
          .read<InternetCheckCubit>()
          .checkInternetConnectionStatus()
          .onError((error, stackTrace) {
        logger.e('connected WAN error', error, stackTrace);
        return false;
      });
      if (connectedWAN) {
        context.read<InternetCheckCubit>().setStaticSettings(
              ipAddress: ipController.text,
              subnetMask: subnetController.text,
              gateway: gatewayController.text,
              dns1: dns1Controller.text,
              dns2: dns2Controller.text,
            );
      } else {
        // Show something wrong
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).static_ip_address,
        ),
        content: Column(
          children: [
            Offstage(
              offstage: !hasOtherErrors,
              child: Column(
                children: [
                  Text(
                    getAppLocalizations(context).enter_static_ip_error,
                    style: Theme.of(context)
                        .textTheme
                        .headline4
                        ?.copyWith(color: Colors.red),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
            InputField(
              titleText: getAppLocalizations(context).ip_address,
              controller: ipController,
              hintText: getAppLocalizations(context).general_ip_hint,
              errorText: getAppLocalizations(context).invalid_ip_address,
              isError: isIpInvalid,
              onChanged: (text) {
                setState(() {
                  isIpInvalid = false;
                });
              },
            ),
            const SizedBox(
              height: 30,
            ),
            InputField(
              titleText: getAppLocalizations(context).subnet_mask,
              controller: subnetController,
              hintText: getAppLocalizations(context).mask_ip_hint,
              errorText: getAppLocalizations(context).invalid_ip_address,
              isError: isSubnetInvalid,
              onChanged: (text) {
                setState(() {
                  isSubnetInvalid = false;
                });
              },
            ),
            const SizedBox(
              height: 30,
            ),
            InputField(
              titleText: getAppLocalizations(context).default_gateway,
              controller: gatewayController,
              hintText: getAppLocalizations(context).gateway_ip_hint,
              errorText: getAppLocalizations(context).invalid_ip_address,
              isError: isGatewayInvalid,
              onChanged: (text) {
                setState(() {
                  isGatewayInvalid = false;
                });
              },
            ),
            const SizedBox(
              height: 30,
            ),
            InputField(
              titleText: getAppLocalizations(context).first_dns,
              controller: dns1Controller,
              hintText: getAppLocalizations(context).general_ip_hint,
              errorText: getAppLocalizations(context).invalid_ip_address,
              isError: isDns1Invalid,
              onChanged: (text) {
                setState(() {
                  isDns1Invalid = false;
                });
              },
            ),
            const SizedBox(
              height: 30,
            ),
            InputField(
              titleText: getAppLocalizations(context).second_dns,
              controller: dns2Controller,
              hintText: getAppLocalizations(context).general_ip_hint,
              errorText: getAppLocalizations(context).invalid_ip_address,
              isError: isDns2Invalid,
              onChanged: (text) {
                setState(() {
                  isDns2Invalid = false;
                });
              },
            ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
        footer: PrimaryButton(
          text: getAppLocalizations(context).next,
          onPress: _validateInputData,
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}
