import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/account_path.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/util/error_code_handler.dart';
import 'package:linksys_moab/util/logger.dart';

class InputNewPasswordView extends ArgumentsStatefulView {
  const InputNewPasswordView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  _InputNewPasswordViewState createState() => _InputNewPasswordViewState();
}

class _InputNewPasswordViewState extends State<InputNewPasswordView> {
  final TextEditingController passwordController = TextEditingController();
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _contentView();
  }

  Widget _contentView() {
    return BasePageView.onDashboardSecondary(
      scrollable: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Input new password',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
        actions: [],
      ),
      child: Column(
        children: [
          box16(),
          PasswordInputField.withValidator(
            titleText: 'Password',
            controller: passwordController,
            isError: _errorMessage.isNotEmpty,
            color: Colors.black,
            onChanged: (value) {
              setState(() {
                _errorMessage = '';
              });
            },
          ),
          box(72),
          PrimaryButton(
            text: 'Next',
            onPress: _applyPassword,
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  _applyPassword() {
    // String token = widget.args['token'] ?? '';
    // context
    //     .read<AccountCubit>()
    //     .changePassword(passwordController.text, token)
    //     .then((value) {
    //   ScaffoldMessenger.of(context)
    //       .showSnackBar(SnackBar(content: Text('Change password success!!')),);
    //   NavigationCubit.of(context).popTo(AccountDetailPath());
    // }).onError((error, stackTrace) => _handleError(error));
  }

  _handleError(Object? error) {
    logger.d('Password validation error:', error);
    setState(() {
      if (error is ErrorResponse) {
        _errorMessage = generalErrorCodeHandler(context, error.code);
      }
    });
  }
}
