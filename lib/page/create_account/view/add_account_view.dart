import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/page/create_account/view/view.dart';
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
      NavigationCubit.of(context).push(ChooseLoginMethodPath());
    } else {
      setState(() {});
    }
  }

  Widget _buildAccountTipsWidget() {
    List<String> tips = [
      AppLocalizations.of(context)!.add_cloud_account_bullet_1,
      AppLocalizations.of(context)!.add_cloud_account_bullet_2,
      AppLocalizations.of(context)!.add_cloud_account_bullet_3,
      AppLocalizations.of(context)!.add_cloud_account_bullet_4,
      AppLocalizations.of(context)!.add_cloud_account_bullet_5,
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
          title: AppLocalizations.of(context)!.add_cloud_account_header_title,
        ),
        content: Column(
          children: [
            InputField(
              titleText: AppLocalizations.of(context)!.add_cloud_account_input_title,
              controller: _emailController,
              isError: isEmailInvalid,
              onChanged: (value) {
                setState(() {
                  isEmailInvalid = false;
                });
              },
            ),
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
                text: AppLocalizations.of(context)!.add_cloud_account_skip_use_router_password,
                onPressed: () {
                  NavigationCubit.of(context).push(NoUseCloudAccountPath());
                })
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        footer: Visibility(
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          visible: _emailController.text.isNotEmpty,
          child: PrimaryButton(
            text: AppLocalizations.of(context)!.next,
            onPress: _onNextAction,
          ),
        ),
      ),
    );
  }
}
