import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/in_app_browser.dart';

class CreateAdminPasswordView extends ArgumentsStatelessView {
  const CreateAdminPasswordView({
    Key? key, super.args
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: _PageContent(args: args,),
      scrollable: true,
    );
  }
}

class _PageContent extends ArgumentsStatefulView {
  const _PageContent({
    Key? key, super.args
  }) : super(key: key);

  @override
  _PageContentState createState() => _PageContentState();
}

class _PageContentState extends State<_PageContent> {
  bool isValidData = false;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController hintController = TextEditingController();

  void _checkInputData(_) {
    setState(() {
      isValidData =
          passwordController.text.isNotEmpty;
    });
  }


  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return BasicLayout(
      header: const BasicHeader(
        title: 'Okay, you’ll need an admin password',
        description:
            'An admin password will allow you to access your router settings',
      ),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 36, bottom: 37),
            child: InputField(
              titleText: 'Password',
              hintText: 'Enter Password',
              controller: passwordController,
              onChanged: _checkInputData,
            ),
          ),
          InputField(
            titleText: 'Password hint (optional)',
            hintText: 'Add a hint',
            controller: hintController,
            onChanged: _checkInputData,
          ),
          const SizedBox(
            height: 100,
          ),
          SimpleTextButton(
              text: 'How do I access my router?',
              onPressed: () {
                MoabInAppBrowser.withDefaultOption().openUrlRequest(urlRequest: URLRequest(url: Uri.parse('https://www.linksys.com/us/')));
              })
        ],
      ),
      footer: Visibility(
        visible: isValidData,
        child: PrimaryButton(
          text: 'Next',
          onPress: () { NavigationCubit.of(context).clearAndPush(DashboardMainPath());},
        ),
      ),
      alignment: CrossAxisAlignment.start,
    );
  }
}
