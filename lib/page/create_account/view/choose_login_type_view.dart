import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/selectable_item.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/route.dart';

// TODO: nobody use this
class ChooseLoginTypeView extends ArgumentsStatefulView {
  const ChooseLoginTypeView({Key? key, super.args}) : super(key: key);

  @override
  _ChooseLoginTypeState createState() => _ChooseLoginTypeState();
}

class _ChooseLoginTypeState extends State<ChooseLoginTypeView> {
  final TextEditingController textController = TextEditingController();
  final List<LoginMethod> _methods = [
    LoginMethod('Send me a code', '(Recommended)'),
    LoginMethod('Password', null),
  ];
  late String selectedMethod;

  @override
  void initState() {
    super.initState();
    selectedMethod = _methods.first.name;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).create_account_choose_login_type,
        ),
        content: Column(
          children: [
            SizedBox(
              height: 93.0 * _methods.length,
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _methods.length,
                  itemBuilder: (context, index) => GestureDetector(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: SelectableItem(
                            text: _methods[index].name,
                            description: _methods[index].description,
                            isSelected: selectedMethod == _methods[index].name,
                            height: 79,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedMethod = _methods[index].name;
                          });
                        },
                      )),
            ),
            SizedBox(
              height: selectedMethod == 'Password' ? 27 : 35,
            ),
            Visibility(
              visible: selectedMethod == 'Password',
              child: PasswordInputField.withValidator(
                  titleText: 'Password', controller: textController),
            ),
            PrimaryButton(
              text: 'Next',
              onPress: selectedMethod == 'Password'
                  ? () {
                      NavigationCubit.of(context).push(EnableTwoSVPath());
                    }
                  : () {
                      final username =
                          context.read<AuthBloc>().state.accountInfo.username;

                      NavigationCubit.of(context).push(CreateAccountOtpPath()
                        ..args = {'username': username});
                    },
            )
          ],
        ),
      ),
    );
  }
}

class LoginMethod {
  final String name;
  final String? description;

  LoginMethod(this.name, this.description);
}
