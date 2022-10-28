import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/account/_account.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';

import '../../../../bloc/auth/bloc.dart';
import '../../../../bloc/auth/state.dart';
import '../../../../network/http/model/cloud_auth_clallenge_method.dart';
import '../../../../route/model/account_path.dart';
import '../../../../route/navigation_cubit.dart';
import '../../../components/base_components/base_page_view.dart';

enum LoginMethod { otp, password }

class LoginMethodOptionsView extends ArgumentsStatefulView {
  const LoginMethodOptionsView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  _LoginMethodOptionsViewState createState() => _LoginMethodOptionsViewState();
}

class _LoginMethodOptionsViewState extends State<LoginMethodOptionsView> {
  LoginMethod? _choose = LoginMethod.otp;
  String? password;
  bool isShowPainText = false;

  @override
  void initState() {
    super.initState();
    _choose = context.read<AccountCubit>().state.authMode.toLowerCase() ==
            AuthenticationType.passwordless.name
        ? LoginMethod.otp
        : LoginMethod.password;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(builder: (context, state) {
      return _content(state);
    });
  }

  Widget _content(AccountState state) {
    return BasePageView.onDashboardSecondary(
      padding: const EdgeInsets.all(0),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        title: const Text('Log in method',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
        actions: [],
      ),
      scrollable: true,
      child: Column(
        children: [
          ListTile(
            title: const Text('One-time passcode (OTP)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
            leading: Radio<LoginMethod>(
              value: LoginMethod.otp,
              groupValue: _choose,
              onChanged: (LoginMethod? value) {
                setState(() {
                  _choose = value;
                });
              },
              activeColor: Colors.black,
            ),
            subtitle: const Text(
                'A one-time passcode verification is required to log in',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
          ),
          box24(),
          ListTile(
            title: password == null
                ? const Text('Password',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400))
                : Column(
                    children: [
                      Row(children: [
                        const Text('Password',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w400)),
                        const Expanded(child: Center()),
                        TextButton(
                            onPressed: () {},
                            child: const Text('Edit',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: MoabColor.primaryBlue)))
                      ]),
                      Row(
                        children: [
                          isShowPainText
                              ? Text(password!,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400))
                              : const Text(
                                  '\u25cf\u25cf\u25cf\u25cf\u25cf\u25cf\u25cf',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400)),
                          box8(),
                          GestureDetector(
                              child: Image.asset(
                                'assets/images/eye_closed.png',
                                width: 26,
                                height: 26,
                              ),
                              onTap: () {
                                setState(() {
                                  isShowPainText = !isShowPainText;
                                });
                              })
                        ],
                      )
                    ],
                  ),
            leading: Radio<LoginMethod>(
              value: LoginMethod.password,
              groupValue: _choose,
              onChanged: (LoginMethod? value) {
                setState(() {
                  _choose = value;
                  if (password == null) {
                    changeAuthModeToPassword(context, state);
                  }
                });
              },
              activeColor: Colors.black,
            ),
            subtitle: const Text(
                'A traditional password and a one-time passcode verification are required to log in',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
          )
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  Future<void> changeAuthModeToPassword(BuildContext context, AccountState state) async {
    ChangeAuthenticationModeChallenge challenge = await context.read<AuthBloc>().changeAuthModePrepare(state.id, null, AuthenticationType.password.name.toUpperCase());
    NavigationCubit.of(context).push(
        OTPViewPath()..next = state.authMode.toUpperCase() == 'PASSWORDLESS'? ChangeAuthModePasswordPath() : LoginMethodOptionsPath()
          ..args = {
          'commMethods' : context.read<AccountCubit>().state.communicationMethods,
          'token': challenge.token
        }
    );
  }
}
