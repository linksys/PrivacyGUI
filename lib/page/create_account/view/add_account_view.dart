import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/event.dart';
import 'package:moab_poc/bloc/setup/bloc.dart';
import 'package:moab_poc/bloc/setup/event.dart';
import 'package:moab_poc/bloc/setup/state.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_state.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/page/create_account/view/view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/route.dart';

import '../../components/base_components/button/primary_button.dart';

class AddAccountView extends ArgumentsStatefulView {
  const AddAccountView({Key? key, super.args}) : super(key: key);

  @override
  _AddAccountState createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccountView> {
  final TextEditingController _emailController = TextEditingController();
  var isEmailInvalid = false;

  void _onNextAction() {
    isEmailInvalid = !_emailController.text.isValidEmailFormat();
    if (!isEmailInvalid) {
      context.read<AuthBloc>().add(SetEmail(email: _emailController.text));
      NavigationCubit.of(context).push(CreateAccountOtpPath()..args = {'username': 'test@linksys.com', 'function': OtpFunction.setting,});
    } else {
      setState(() {});
    }
  }


  @override
  void initState() {
    super.initState();
    context.read<SetupBloc>().add(const ResumePointChanged(status: SetupResumePoint.CREATECLOUDACCOUNT));
  }

  Widget _buildAccountTipsWidget() {
    List<String> tips = [
      getAppLocalizations(context).add_cloud_account_bullet_1,
      getAppLocalizations(context).add_cloud_account_bullet_2,
      getAppLocalizations(context).add_cloud_account_bullet_3,
      getAppLocalizations(context).add_cloud_account_bullet_4,
      getAppLocalizations(context).add_cloud_account_bullet_5,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Column(
        children: List.generate(tips.length, (index) {
          return Row(
            children: [
              Image.asset('assets/images/icon_check_green.png'),
              const SizedBox(
                width: 8,
              ),
              Text(
                tips[index],
                style: Theme.of(context).textTheme.headline4?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).add_cloud_account_header_title,
        ),
        content: Column(
          children: [
            InputField(
              titleText: getAppLocalizations(context).add_cloud_account_input_title,
              controller: _emailController,
              isError: isEmailInvalid,
              onChanged: (value) {
                setState(() {
                  isEmailInvalid = false;
                });
              }
            ),
            const SizedBox(height: 31),
            DescriptionText(text: getAppLocalizations(context).add_cloud_account_input_description),
            const SizedBox(
              height: 8,
            ),
            Visibility(
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              visible: isEmailInvalid,
              child: Text(
                'Enter a valid email format',
                style: Theme.of(context).textTheme.headline4?.copyWith(
                      color: Colors.red,
                    ),
              ),
            ),
            _buildAccountTipsWidget(),
            SimpleTextButton(
                text: getAppLocalizations(context).already_have_an_account,
                onPressed: () {
                  NavigationCubit.of(context).push(NoUseCloudAccountPath());
                })
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        footer: Column(
          children: [
            PrimaryButton(
              text: getAppLocalizations(context).next,
              onPress: _onNextAction,
            ),
            const SizedBox(height: 8),
            SimpleTextButton(
              text: getAppLocalizations(context).do_this_later,
              onPressed: (){
                NavigationCubit.of(context).push(NoUseCloudAccountPath());
              },
            )
          ],
        )
      ),
    );
  }
}
