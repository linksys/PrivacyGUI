import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/route/model/internet_check_path.dart';
import 'package:moab_poc/route/navigation_cubit.dart';
import 'package:moab_poc/util/validator.dart';

class EnterStaticIpView extends StatefulWidget {
  const EnterStaticIpView({Key? key}): super(key: key);

  @override
  State<EnterStaticIpView> createState() => _EnterStaticIpViewState();
}

class _EnterStaticIpViewState extends State<EnterStaticIpView> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController subnetController = TextEditingController();
  final TextEditingController gatewayController = TextEditingController();
  final TextEditingController dns1Controller = TextEditingController();
  final TextEditingController dns2Controller = TextEditingController();
  final IpAddressRule ipValidator = IpAddressRule();
  bool hasOtherErrors = false;
  bool isIpInvalid = false;
  bool isSubnetInvalid = false;
  bool isGatewayInvalid = false;
  bool isDns1Invalid = false;
  bool isDns2Invalid = false;

  void _validateInputData() {
    if (!ipValidator.validate(ipController.text)) {
      setState(() {
        isIpInvalid = true;
      });
    }

    if (!ipValidator.validate(subnetController.text)) {
      setState(() {
        isSubnetInvalid = true;
      });
    }

    if (!ipValidator.validate(gatewayController.text)) {
      setState(() {
        isGatewayInvalid = true;
      });
    }

    if (!ipValidator.validate(dns1Controller.text)) {
      setState(() {
        isDns1Invalid = true;
      });
    }

    if (!ipValidator.validate(dns2Controller.text)) {
      setState(() {
        isDns2Invalid = true;
      });
    }

    if (!isIpInvalid && !isSubnetInvalid && !isGatewayInvalid && !isDns1Invalid && !isDns2Invalid) {
      //TODO: Do real configuration check process
      NavigationCubit.of(context).push(InternetConnectedPath());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Static IP Address',
        ),
        content: Column(
          children: [
            Offstage(
              offstage: !hasOtherErrors,
              child: Column(
                children: [
                  Text(
                    'Couldn’t establish a connection. Please check your info and try again.',
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        color: Colors.red
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
            InputField(
              titleText: 'IP Address',
              controller: ipController,
              hintText: 'e.g. 192.168.1.1',
              errorText: 'Invalid IP Address',
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
              titleText: 'Subnet mask',
              controller: subnetController,
              hintText: 'e.g. 255.255.255.1',
              errorText: 'Invalid IP Address',
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
              titleText: 'Default gateway',
              controller: gatewayController,
              hintText: 'e.g. 192.168.0.1',
              errorText: 'Invalid IP Address',
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
              titleText: 'DNS1',
              controller: dns1Controller,
              hintText: 'e.g. 192.168.0.1',
              errorText: 'Invalid IP Address',
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
              titleText: 'DNS2',
              controller: dns2Controller,
              hintText: 'e.g. 192.168.0.1',
              errorText: 'Invalid IP Address',
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
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}