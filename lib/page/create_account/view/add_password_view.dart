import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

// TODO: nobody use this
class AddPasswordView extends StatefulWidget {
  const AddPasswordView({Key? key}) : super(key: key);

  @override
  _AddPasswordViewState createState() => _AddPasswordViewState();
}

class _AddPasswordViewState extends State<AddPasswordView> {
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordInvalid = false;

  void _onContinueAction() {
    isPasswordInvalid = passwordController.text.isEmpty;
    if (isPasswordInvalid) {
      setState(() {});
    } else {
      //TODO: Go to next page
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Enter password',
        ),
        content: Column(
          children: [
            const SizedBox(
              height: 15,
            ),
            InputField(
              titleText: 'Password',
              controller: passwordController,
              isError: isPasswordInvalid,
              onChanged: (value) {
                setState(() {
                  isPasswordInvalid = false;
                });
              },
            ),
            SimpleTextButton(text: 'Forgot password', onPressed: () {}),
            const SizedBox(
              height: 30,
            ),
            PrimaryButton(
              text: 'Continue',
              onPress: _onContinueAction,
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
