import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

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
  bool hasConnectionError = false;
  bool isIpInvalid = false;

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
              offstage: !hasConnectionError,
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
            ),
            const SizedBox(
              height: 30,
            ),
            InputField(
              titleText: 'Default gateway',
              controller: gatewayController,
              hintText: 'e.g. 192.168.0.1',
            ),
            const SizedBox(
              height: 30,
            ),
            InputField(
              titleText: 'DNS1',
              controller: gatewayController,
              hintText: 'e.g. 192.168.0.1',
            ),
            const SizedBox(
              height: 30,
            ),
            InputField(
              titleText: 'DNS2',
              controller: gatewayController,
              hintText: 'e.g. 192.168.0.1',
            ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
        footer: PrimaryButton(
          text: getAppLocalizations(context).next,
          onPress: () {
            //TODO: Go to next page
          },
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}