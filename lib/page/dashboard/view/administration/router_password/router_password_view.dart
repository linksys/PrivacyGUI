import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/router_password/bloc/cubit.dart';
import 'package:linksys_moab/page/dashboard/view/administration/router_password/bloc/state.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class RouterPasswordView extends ArgumentsStatelessView {
  const RouterPasswordView({
    Key? key,
    super.next,
    super.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RouterPasswordCubit(context.read<RouterRepository>()),
      child: RouterPasswordContentView(
        args: super.args,
        next: super.next,
      ),
    );
  }
}

class RouterPasswordContentView extends ArgumentsStatefulView {
  const RouterPasswordContentView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<RouterPasswordContentView> createState() =>
      _RouterPasswordContentViewState();
}

class _RouterPasswordContentViewState extends State<RouterPasswordContentView> {
  late final RouterPasswordCubit _cubit;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();
  late List<Validation> validations;

  @override
  void initState() {
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
    _cubit = context.read<RouterPasswordCubit>();
    _cubit.fetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RouterPasswordCubit, RouterPasswordState>(
        builder: (context, state) {
      return state.isLoading
          ? const LinksysFullScreenSpinner()
          : StyledLinksysPageView(
              scrollable: true,
              title: state.isSetByUser
                  ? getAppLocalizations(context).router_password
                  : ' ',
              actions: [
                LinksysTertiaryButton(
                  getAppLocalizations(context).save,
                  onTap: (state.hasEdited && state.isValid) ? _save : null,
                ),
              ],
              child: state.isSetByUser
                  ? _editRouterPasswordView(state)
                  : _createRouterPasswordView(state),
            );
    });
  }

  _editRouterPasswordView(RouterPasswordState state) {
    return LinksysBasicLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinksysGap.regular(),
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
                _cubit.setEdited(true);
                _cubit.setValidate(false);
              }
            },
            onValidationChanged: (isValid) {
              // check validate
              _cubit.setValidate(isValid);
            },
          ),
          const LinksysGap.big(),
          AppTextField(
            headerText: getAppLocalizations(context).password_hint,
            hintText: 'Password hint',
            controller: _hintController,
            readOnly: !state.hasEdited,
          ),
          const LinksysGap.semiSmall(),
          if (!state.hasEdited)
            LinksysText.descriptionSub(getAppLocalizations(context)
                .enter_router_password_to_change_password_hint),
        ],
      ),
    );
  }

  _createRouterPasswordView(RouterPasswordState state) {
    return LinksysBasicLayout(
      crossAxisAlignment: CrossAxisAlignment.start,
      header: LinksysText.screenName(
        getAppLocalizations(context).set_a_router_password,
      ),
      content: Column(
        children: [
          const LinksysGap.semiBig(),
          LinksysText.descriptionMain(
              getAppLocalizations(context).create_router_password_description),
          const LinksysGap.big(),
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
                _cubit.setEdited(true);
                _cubit.setValidate(false);
              }
            },
            onValidationChanged: (isValid) {
              _cubit.setValidate(isValid);
            },
          ),
          const LinksysGap.big(),
          AppTextField(
            headerText: getAppLocalizations(context).password_hint,
            hintText: 'Password hint',
            controller: _hintController,
            readOnly: !state.hasEdited,
          ),
          const LinksysGap.big(),
          Row(
            children: [
              Expanded(
                child: LinksysTertiaryButton(
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
    _cubit.save(_passwordController.text, _hintController.text).then<void>((_) {
      _success();
    });
  }

  void _success() {
    logger.d('success save');
    _cubit.setEdited(false);
    showSuccessSnackBar(context, getAppLocalizations(context).password_updated);
  }
}
