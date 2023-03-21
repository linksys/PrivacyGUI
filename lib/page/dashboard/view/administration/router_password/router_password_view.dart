import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/router_password/bloc/cubit.dart';
import 'package:linksys_moab/page/dashboard/view/administration/router_password/bloc/state.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/buttons/button.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

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

  @override
  void initState() {
    _cubit = context.read<RouterPasswordCubit>();
    _cubit.fetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RouterPasswordCubit, RouterPasswordState>(
        builder: (context, state) {
      return StyledLinksysPageView(
        scrollable: true,
        title: !state.isSetByUser
            ? ''
            : getAppLocalizations(context).router_password,
        actions: [
          LinksysTertiaryButton(
            getAppLocalizations(context).save,
            onTap: (state.hasEdited && state.isValid) ? _save : null,
          ),
        ],
        child: !state.isSetByUser
            ? _createRouterPasswordView(state)
            : _editRouterPasswordView(state),
      );
    });
  }

  _editRouterPasswordView(RouterPasswordState state) {
    return LinksysBasicLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinksysGap.regular(),
          PasswordInputField(
            withValidator: state.hasEdited,
            titleText: getAppLocalizations(context).router_password,
            controller: _passwordController,
            color: Colors.black,
            suffixIcon: state.hasEdited ? null : box4(),
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
          box36(),
          InputField(
            titleText: getAppLocalizations(context).password_hint,
            hintText: '',
            controller: _hintController,
            readOnly: !state.hasEdited,
            customPrimaryColor: state.hasEdited
                ? Colors.black
                : const Color.fromRGBO(153, 153, 153, 1.0),
          ),
          box12(),
          if (!state.hasEdited)
            Text(
              getAppLocalizations(context)
                  .enter_router_password_to_change_password_hint,
              style: const TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }

  _createRouterPasswordView(RouterPasswordState state) {
    return BasicLayout(
      crossAxisAlignment: CrossAxisAlignment.start,
      header: Text(
        getAppLocalizations(context).set_a_router_password,
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        children: [
          box24(),
          Text(getAppLocalizations(context).create_router_password_description),
          box36(),
          PasswordInputField.withValidator(
            titleText: getAppLocalizations(context).router_password,
            controller: _passwordController,
            color: Colors.black,
            suffixIcon: state.hasEdited ? null : box4(),
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
          box36(),
          InputField(
            titleText: getAppLocalizations(context).password_hint,
            hintText: '',
            controller: _hintController,
            readOnly: !state.hasEdited,
            customPrimaryColor: state.hasEdited
                ? Colors.black
                : const Color.fromRGBO(153, 153, 153, 1.0),
          ),
          box36(),
          Row(
            children: [
              Expanded(
                  child: SimpleTextButton(
                text: getAppLocalizations(context)
                    .create_router_password_how_to_access,
                onPressed: () {},
              ))
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
