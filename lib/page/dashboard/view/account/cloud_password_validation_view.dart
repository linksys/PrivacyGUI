import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/account_path.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

import 'package:linksys_moab/util/error_code_handler.dart';
import 'package:linksys_moab/util/logger.dart';

class CloudPasswordValidationView extends ArgumentsConsumerStatefulView {
  const CloudPasswordValidationView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  _CloudPasswordValidationViewState createState() =>
      _CloudPasswordValidationViewState();
}

class _CloudPasswordValidationViewState
    extends ConsumerState<CloudPasswordValidationView> {
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Verify your password',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          ref.read(navigationsProvider.notifier).pop();
        }),
        actions: [],
      ),
      scrollable: true,
      child: Column(
        children: [
          box36(),
          PasswordInputField(
            titleText: 'Password',
            controller: passwordController,
            isError: _errorMessage.isNotEmpty,
            errorText: _errorMessage,
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
            onPress: _verifyPassword,
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
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
    logger.d('Password validation error:', error);
    setState(() {
      if (error is ErrorResponse) {
        _errorMessage = generalErrorCodeHandler(context, error.code);
      }
    });
  }
}
