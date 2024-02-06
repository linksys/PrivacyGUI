import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/cloud/model/error_response.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/util/error_code_handler.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class CloudPasswordValidationView extends ArgumentsConsumerStatefulView {
  const CloudPasswordValidationView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _CloudPasswordValidationViewState createState() =>
      _CloudPasswordValidationViewState();
}

class _CloudPasswordValidationViewState
    extends ConsumerState<CloudPasswordValidationView> {
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
      title: 'Verify your password',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGap.big(),
          AppPasswordField(
            headerText: 'Password',
            controller: passwordController,
            errorText: _errorMessage,
            onChanged: (value) {
              setState(() {
                _errorMessage = '';
              });
            },
          ),
          const AppGap.extraBig(),
          AppFilledButton(
            'Next',
            onTap: _verifyPassword,
          ),
        ],
      ),
    );
  }

  _verifyPassword() {
    // context
    //     .read<AccountCubit>()
    //     .verifyPassword(passwordController.text)
    //     .then((value) => ref.read(navigationsProvider.notifier)
    //         .push(InputNewPasswordPath()..args = {'token': value}))
    //     .onError((error, stackTrace) => _handleError(error));
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
