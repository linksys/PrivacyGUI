import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';

import '../../components/base_components/button/primary_button.dart';

class AddAccountView extends ArgumentsStatefulView {
  const AddAccountView(
      {Key? key, super.args})
      : super(key: key);

  @override
  _AddAccountState createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccountView> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Add a Linksys account',
        ),
        content: InputField(
          titleText: 'Email',
          hintText: 'Email',
          controller: _emailController,
          onChanged: (value) {
            setState(() {});
          },
        ),
        footer: Column(
          children: [
            Visibility(
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              visible: _emailController.text != '',
              child: PrimaryButton(
                text: 'Continue',
                onPress: () {
                  NavigationCubit.of(context).push(ChooseLoginMethodPath());
                },
              ),
            ),
            const SizedBox(
              height: 26,
            ),
            SimpleTextButton(
                text: 'Skip and use router password',
                onPressed: () {
                  NavigationCubit.of(context).push(CreateAdminPasswordPath());
                })
          ],
        ),
      ),
    );
  }
}