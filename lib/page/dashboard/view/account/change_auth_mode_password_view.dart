import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/cloud/model/error_response.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/util/error_code_handler.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class ChangeAuthModePasswordView extends ArgumentsConsumerStatefulView {
  const ChangeAuthModePasswordView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<ChangeAuthModePasswordView> createState() =>
      _ChangeAuthModePasswordViewState();
}

class _ChangeAuthModePasswordViewState
    extends ConsumerState<ChangeAuthModePasswordView> {
  final TextEditingController passwordController = TextEditingController();
  String? _errorMessage;
  String mode = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.args['changeModeTo'] == 'PASSWORDLESS'
        ? Container()
        : _contentView();
  }

  Widget _contentView() {
    return StyledAppPageView(
      scrollable: true,
      title: 'Create a password',
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
            'Save',
            onTap: _applyPassword,
          ),
        ],
      ),
    );
  }

  _applyPassword() async {
    // String token = widget.args['token'] ?? '';
    // const storage = FlutterSecureStorage();
    // String accountId = context.read<AccountCubit>().state.id;
    // await storage.write(
    //     key: linksysPrefCloudAccountPasswordKey,
    //     value: passwordController.text);
    // context
    //     .read<AuthBloc>()
    //     .changeAuthMode(accountId, token, passwordController.text)
    //     .then((value) async {
    //   await context.read<AccountCubit>().fetchAccount();
    //   ref.read(navigationsProvider.notifier).push(LoginMethodOptionsPath());
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
