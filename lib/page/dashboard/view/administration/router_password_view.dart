import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';

class RouterPasswordView extends ArgumentsStatefulView {
  const RouterPasswordView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<RouterPasswordView> createState() => _RouterPasswordViewState();
}

class _RouterPasswordViewState extends State<RouterPasswordView> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();
  bool editing = false;
  bool isValid = false;
  String currentPassword = '';
  String currentHint = '';

  @override
  void initState() {
    super.initState();

    // TODO: Fetch current password and hint
    currentPassword = 'passwordFromCubit';
    currentHint = 'hintFromCubit';
    _passwordController.text = currentPassword;
    _hintController.text = currentHint;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // iconTheme:
        // IconThemeData(color: Theme.of(context).colorScheme.primary),
        elevation: 0,
        title: Text(
          getAppLocalizations(context).router_password,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          SimpleTextButton(
            text: getAppLocalizations(context).save,
            onPressed: (editing && isValid) ? _save : null,
          ),
        ],
      ),
      child: BasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box24(),
            PasswordInputField(
              withValidator: editing,
              titleText: getAppLocalizations(context).router_password,
              controller: _passwordController,
              color: Colors.black,
              suffixIcon: editing ? null : box4(),
              onFocusChanged: (hasFocus) {
                if (hasFocus && _passwordController.text == currentPassword) {
                  setState(() {
                    _passwordController.text = '';
                    editing = true;
                    isValid = false;
                  });
                }
              },
              onValidationChanged: (isValid) {
                setState(() {
                  this.isValid = isValid;
                });
              },
            ),
            box36(),
            InputField(
              titleText: getAppLocalizations(context).password_hint,
              hintText: '',
              controller: _hintController,
              readOnly: !editing,
              customPrimaryColor: editing
                  ? Colors.black
                  : const Color.fromRGBO(153, 153, 153, 1.0),
            ),
            box12(),
            if (!editing)
              Text(
                getAppLocalizations(context)
                    .enter_router_password_to_change_password_hint,
                style: const TextStyle(fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  void _save() {
    // TODO: Update router password and hint
    setState(() {
      editing = false;
      currentPassword = _passwordController.text;
      currentHint = _hintController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Image.asset('assets/images/icon_check_green.png'),
            box16(),
            Text(getAppLocalizations(context).password_updated),
          ],
        ),
      ),
    );
  }
}
