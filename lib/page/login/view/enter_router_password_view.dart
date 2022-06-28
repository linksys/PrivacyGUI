import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/customs/network_check_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/route/route.dart';

class EnterRouterPasswordView extends StatefulWidget {
  const EnterRouterPasswordView({
    Key? key,
  }) : super(key: key);

  @override
  _EnterRouterPasswordState createState() => _EnterRouterPasswordState();
}

class _EnterRouterPasswordState extends State<EnterRouterPasswordView> {
  bool isConnectedToRouter = false;
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // TODO check is behind router
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: isConnectedToRouter
          ? _enterRouterPasswordView(context)
          : NetworkCheckView(
              description: 'Connect to your router’s WiFi network to log in',
              button: PrimaryButton(
                text: 'Continue',
                onPress: checkWifi,
              )),
    );
  }

  void checkWifi() {
    // TODO: check if connect to router
    setState(() {
      isConnectedToRouter = true;
    });
  }

  Widget _enterRouterPasswordView(BuildContext context) {
    return BasicLayout(
      alignment: CrossAxisAlignment.start,
      header: const BasicHeader(
        title: 'Enter your router password',
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 44,
          ),
          InputField(
              titleText: 'Router password',
              hintText: 'Router password',
              controller: passwordController),
          const SizedBox(
            height: 26,
          ),
          const ShowHintSection(),
          SimpleTextButton(
              text: 'Forgot router password',
              onPressed: () {
                // TODO TBD
              }),
          const SizedBox(
            height: 37,
          ),
          PrimaryButton(
            text: 'Continue',
            onPress: () {
              NavigationCubit.of(context).push(NoRouterPath());
            },
          ),
        ],
      ),
    );
  }
}

class ShowHintSection extends StatefulWidget {
  const ShowHintSection({Key? key}) : super(key: key);

  @override
  _ShowHintSectionState createState() => _ShowHintSectionState();
}

class _ShowHintSectionState extends State<ShowHintSection> {
  bool isShowingHint = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SimpleTextButton(
            text: isShowingHint ? 'Hide hint' : 'Show hint',
            onPressed: () {
              setState(() {
                isShowingHint = !isShowingHint;
              });
            }),
        Visibility(
          visible: isShowingHint,
          child: Text('favorite camping place',
              style: Theme.of(context)
                  .textTheme
                  .headline3
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
        ),
        SizedBox(
          height: isShowingHint ? 54 : 18,
        ),
      ],
    );
  }
}
