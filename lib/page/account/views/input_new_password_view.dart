import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/util/error_code_handler.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';

class InputNewPasswordView extends ArgumentsConsumerStatefulView {
  const InputNewPasswordView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _InputNewPasswordViewState createState() => _InputNewPasswordViewState();
}

class _InputNewPasswordViewState extends ConsumerState<InputNewPasswordView> {
  final TextEditingController passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _contentView();
  }

  Widget _contentView() {
    return StyledAppPageView(
      scrollable: true,
      title: 'Input new password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGap.regular(),
          AppPasswordField.withValidator(
            headerText: 'Password',
            controller: passwordController,
            errorText: _errorMessage,
            onChanged: (value) {
              setState(() {
                _errorMessage = '';
              });
            },
            validations: [
              Validation(
                description: 'At least 10 characters',
                validator: (text) => LengthRule().validate(text),
              ),
              Validation(
                description: 'Upper and lowercase letters',
                validator: (text) => HybridCaseRule().validate(text),
              ),
              Validation(
                description: '1 number',
                validator: (text) => DigitalCheckRule().validate(text),
              ),
              Validation(
                description: '1 special character',
                validator: (text) => SpecialCharCheckRule().validate(text),
              ),
            ],
          ),
          const AppGap.extraBig(),
          AppFilledButton(
            'Next',
            onTap: _applyPassword,
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
    logger.d('Password validation error:', error: error);
    setState(() {
      if (error is ErrorResponse) {
        _errorMessage = generalErrorCodeHandler(context, error.code);
      }
    });
  }
}
