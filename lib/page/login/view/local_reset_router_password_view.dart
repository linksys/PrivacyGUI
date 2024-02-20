import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/layouts/basic_header.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/router_password/_router_password.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/validator_rules/rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/input_field/validator_widget.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class LocalResetRouterPasswordView extends ArgumentsConsumerStatefulView {
  const LocalResetRouterPasswordView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<LocalResetRouterPasswordView> createState() =>
      _LocalResetRouterPasswordViewState();
}

class _LocalResetRouterPasswordViewState
    extends ConsumerState<LocalResetRouterPasswordView> {
  final _newPasswordController = TextEditingController();
  final _hintController = TextEditingController();
  final validations = [
    Validation(
        description: 'At least 10 characters',
        validator: ((text) => LengthRule().validate(text))),
    Validation(
        description: 'Upper and lowercase letters',
        validator: ((text) => HybridCaseRule().validate(text))),
    Validation(
        description: '1 number',
        validator: ((text) => DigitalCheckRule().validate(text))),
    Validation(
        description: '1 special character',
        validator: ((text) => SpecialCharCheckRule().validate(text))),
  ];

  @override
  void dispose() {
    super.dispose();

    _newPasswordController.dispose();
    _hintController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routerPasswordProvider);
    return StyledAppPageView(
      child: AppBasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).reset_router_password,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.regular(),
            AppPasswordField(
              withValidator: state.hasEdited,
              validations: validations,
              headerText: getAppLocalizations(context).router_password,
              hintText: 'New router password',
              controller: _newPasswordController,
              onFocusChanged: (hasFocus) {
                ref.read(routerPasswordProvider.notifier).setEdited(hasFocus);
              },
              onValidationChanged: (isValid) {
                ref.read(routerPasswordProvider.notifier).setValidate(isValid);
              },
            ),
            const AppGap.big(),
            AppTextField(
              headerText: getAppLocalizations(context).password_hint,
              hintText: 'Password hint',
              controller: _hintController,
            ),
          ],
        ),
        footer: AppFilledButton.fillWidth(
          getAppLocalizations(context).save,
          onTap: state.isValid ? _save : null,
        ),
      ),
    );
  }

  void _save() {
    final code = widget.args['code'] ?? '';
    ref
        .read(routerPasswordProvider.notifier)
        .setAdminPasswordWithResetCode(
          _newPasswordController.text,
          _hintController.text,
          code,
        )
        .then<void>((_) {
      context.goNamed(RouteNamed.localLoginPassword);
    });
  }
}
