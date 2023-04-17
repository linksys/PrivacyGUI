import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
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

import '../../../../constants/pref_key.dart';

class ChangeAuthModePasswordView extends ArgumentsConsumerStatefulView {
  const ChangeAuthModePasswordView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  _ChangeAuthModePasswordViewState createState() =>
      _ChangeAuthModePasswordViewState();
}

class _ChangeAuthModePasswordViewState
    extends ConsumerState<ChangeAuthModePasswordView> {
  final TextEditingController passwordController = TextEditingController();
  String _errorMessage = '';
  String mode = '';

  @override
  void initState() {
    super.initState();
    if (widget.args['changeModeTo'] == 'PASSWORDLESS') {
      changeAuthModeToPasswordless(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.args['changeModeTo'] == 'PASSWORDLESS'
        ? Container()
        : _contentView();
  }

  Widget _contentView() {
    return BasePageView.onDashboardSecondary(
      scrollable: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Create a password',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          // ref.read(navigationsProvider.notifier).pop();
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
            text: 'Save',
            onPress: _applyPassword,
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  _applyPassword() async {
    String token = widget.args['token'] ?? '';
    const storage = FlutterSecureStorage();
    String accountId = context.read<AccountCubit>().state.id;
    await storage.write(
        key: linksysPrefCloudAccountPasswordKey,
        value: passwordController.text);
    context
        .read<AuthBloc>()
        .changeAuthMode(accountId, token, passwordController.text)
        .then((value) async {
      await context.read<AccountCubit>().fetchAccount();
      ref.read(navigationsProvider.notifier).push(LoginMethodOptionsPath());
    }).onError((error, stackTrace) => _handleError(error));
  }

  _handleError(Object? error) {
    logger.d('Password validation error:', error);
    setState(() {
      if (error is ErrorResponse) {
        _errorMessage = generalErrorCodeHandler(context, error.code);
      }
    });
  }

  Future<void> changeAuthModeToPasswordless(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: linksysPrefCloudAccountPasswordKey);
    String accountId = context.read<AccountCubit>().state.id;
    context
        .read<AuthBloc>()
        .changeAuthMode(accountId, widget.args['token'], null)
        .then((value) async {
      await context.read<AccountCubit>().fetchAccount();
      ref.read(navigationsProvider.notifier).push(LoginMethodOptionsPath());
    });
  }
}
