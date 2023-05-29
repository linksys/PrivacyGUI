import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';

import 'package:linksys_moab/util/error_code_handler.dart';
import 'package:linksys_moab/util/logger.dart';

import '../../../../route/navigations_notifier.dart';

class InputNewPasswordView extends ArgumentsConsumerStatefulView {
  const InputNewPasswordView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  _InputNewPasswordViewState createState() => _InputNewPasswordViewState();
}

class _InputNewPasswordViewState extends ConsumerState<InputNewPasswordView> {
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
        title: const Text('Input new password',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          ref.read(navigationsProvider.notifier).pop();
        }),
        actions: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    //   ref.read(navigationsProvider.notifier).popTo(AccountDetailPath());
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
