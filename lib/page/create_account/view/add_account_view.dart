import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../components/base_components/button/primary_button.dart';

class AddAccountView extends StatefulWidget {
  final void Function() onNext;
  final void Function() onSkip;

  const AddAccountView({Key? key, required this.onNext, required this.onSkip})
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
        header: BasicHeader(
          title: AppLocalizations.of(context)!.add_cloud_account_header_title,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputField(
              titleText:
                  AppLocalizations.of(context)!.add_cloud_account_input_title,
              hintText:
                  AppLocalizations.of(context)!.add_cloud_account_input_title,
              controller: _emailController,
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(
              height: 39,
            ),
            BulletPoint(context,
                AppLocalizations.of(context)!.add_cloud_account_bullet_1),
            BulletPoint(context,
                AppLocalizations.of(context)!.add_cloud_account_bullet_2),
            BulletPoint(context,
                AppLocalizations.of(context)!.add_cloud_account_bullet_3),
            BulletPoint(context,
                AppLocalizations.of(context)!.add_cloud_account_bullet_4),
            BulletPoint(context,
                AppLocalizations.of(context)!.add_cloud_account_bullet_5),
            const SizedBox(
              height: 30,
            ),
            SimpleTextButton(
                text: AppLocalizations.of(context)!
                    .add_cloud_account_skip_use_router_password,
                onPressed: widget.onSkip)
          ],
        ),
        footer: Column(
          children: [
            Visibility(
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              visible: _emailController.text != '',
              child: PrimaryButton(
                text: AppLocalizations.of(context)!.next,
                onPress: widget.onNext,
              ),
            ),
            const SizedBox(
              height: 26,
            ),
          ],
        ),
      ),
    );
  }
}

Widget BulletPoint(BuildContext context, String title) => Row(
      children: [
        Image.asset('assets/images/icon_check_green.png'),
        const SizedBox(width: 12),
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    ?.copyWith(color: Colors.white)))
      ],
    );
