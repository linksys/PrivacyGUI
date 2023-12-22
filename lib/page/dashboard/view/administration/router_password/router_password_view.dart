import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/provider/router_password/_router_password.dart';
import 'package:linksys_app/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class RouterPasswordView extends ArgumentsConsumerStatelessView {
  const RouterPasswordView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RouterPasswordContentView(
      args: super.args,
    );
  }
}

class RouterPasswordContentView extends ArgumentsConsumerStatefulView {
  const RouterPasswordContentView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<RouterPasswordContentView> createState() =>
      _RouterPasswordContentViewState();
}

class _RouterPasswordContentViewState
    extends ConsumerState<RouterPasswordContentView> {
  late final RouterPasswordNotifier _notifier;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();
  late List<Validation> validations;

  @override
  void initState() {
    super.initState();
    // localize here
    validations = [
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
    _notifier = ref.read(routerPasswordProvider.notifier);
    _notifier.fetch();
    final provider = ref.read(routerPasswordProvider);
    _passwordController.text = provider.adminPassword;
    _hintController.text = provider.hint;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routerPasswordProvider);
    return state.isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            title: state.isSetByUser
                ? getAppLocalizations(context).router_password
                : ' ',
            actions: [
              AppTextButton(
                getAppLocalizations(context).save,
                onTap: (state.hasEdited && state.isValid) ? _save : null,
              ),
            ],
            child: state.isSetByUser
                ? _editRouterPasswordView(state)
                : _createRouterPasswordView(state),
          );
  }

  _editRouterPasswordView(RouterPasswordState state) {
    return AppBasicLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGap.regular(),
          AppPasswordField(
            withValidator: state.hasEdited,
            validations: validations,
            headerText: getAppLocalizations(context).router_password,
            hintText: 'Router password',
            controller: _passwordController,
            onFocusChanged: (hasFocus) {
              if (hasFocus && _passwordController.text == state.adminPassword) {
                setState(() {
                  _passwordController.text = '';
                });
                _notifier.setEdited(true);
                _notifier.setValidate(false);
              }
            },
            onValidationChanged: (isValid) {
              // check validate
              _notifier.setValidate(isValid);
            },
          ),
          const AppGap.big(),
          AppTextField(
            headerText: getAppLocalizations(context).password_hint,
            hintText: 'Password hint',
            controller: _hintController,
            readOnly: !state.hasEdited,
          ),
          const AppGap.semiSmall(),
          if (!state.hasEdited)
            AppText.bodyMedium(getAppLocalizations(context)
                .enter_router_password_to_change_password_hint),
        ],
      ),
    );
  }

  _createRouterPasswordView(RouterPasswordState state) {
    return AppBasicLayout(
      crossAxisAlignment: CrossAxisAlignment.start,
      header: AppText.titleLarge(
        getAppLocalizations(context).set_a_router_password,
      ),
      content: Column(
        children: [
          const AppGap.semiBig(),
          AppText.bodyLarge(
              getAppLocalizations(context).create_router_password_description),
          const AppGap.big(),
          AppPasswordField.withValidator(
            validations: validations,
            headerText: getAppLocalizations(context).router_password,
            hintText: 'Router password',
            controller: _passwordController,
            onFocusChanged: (hasFocus) {
              if (hasFocus && _passwordController.text == state.adminPassword) {
                setState(() {
                  _passwordController.text = '';
                });
                _notifier.setEdited(true);
                _notifier.setValidate(false);
              }
            },
            onValidationChanged: (isValid) {
              _notifier.setValidate(isValid);
            },
          ),
          const AppGap.big(),
          AppTextField(
            headerText: getAppLocalizations(context).password_hint,
            hintText: 'Password hint',
            controller: _hintController,
            readOnly: !state.hasEdited,
          ),
          const AppGap.big(),
          Row(
            children: [
              Expanded(
                child: AppTextButton(
                  getAppLocalizations(context)
                      .create_router_password_how_to_access,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    _notifier
        .save(_passwordController.text, _hintController.text)
        .then<void>((_) {
      _success();
    });
  }

  void _success() {
    logger.d('success save');
    _notifier.setEdited(false);
    showSuccessSnackBar(context, getAppLocalizations(context).password_updated);
  }
}
