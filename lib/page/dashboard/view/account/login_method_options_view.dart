import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_moab/bloc/account/_account.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

import '../../../../constants/pref_key.dart';
import '../../../../route/model/account_path.dart';
import '../../../components/base_components/base_page_view.dart';

enum LoginMethod { otp, password }

class LoginMethodOptionsView extends ArgumentsConsumerStatefulView {
  const LoginMethodOptionsView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  _LoginMethodOptionsViewState createState() => _LoginMethodOptionsViewState();
}

class _LoginMethodOptionsViewState
    extends ConsumerState<LoginMethodOptionsView> {
  LoginMethod? _choose = LoginMethod.otp;
  String? password;
  bool isShowPainText = false;

  @override
  void initState() {
    super.initState();
    // _choose = context.read<AccountCubit>().state.authMode.toLowerCase() ==
    //         AuthenticationType.passwordless.name
    //     ? LoginMethod.otp
    //     : LoginMethod.password;
    initPassword();
  }

  @override
  Widget build(BuildContext context) {
    return _content(context);
  }

  Widget _content(BuildContext context) {
    final state = ref.read(accountProvider);
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
          if (ref.read(navigationsProvider).contains(AccountDetailPath())) {
            ref.read(navigationsProvider.notifier).popTo(AccountDetailPath());
          } else {
            ref
                .read(navigationsProvider.notifier)
                .clearAndPush(AccountDetailPath());
          }
        }),
        actions: const [],
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  // if (state.authMode.toUpperCase() == 'PASSWORD') {
                  //   changeAuthModePrepare(context, state);
                  // }
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
                    changeAuthModePrepare(context, state);
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
      ),
    );
  }

  Future<void> changeAuthModePrepare(
      BuildContext context, AccountState state) async {
    // String mode = state.authMode.toUpperCase() == 'PASSWORD'
    //     ? AuthenticationType.passwordless.name.toUpperCase()
    //     : AuthenticationType.password.name.toUpperCase();
    // String? password;
    // if(state.authMode.toUpperCase() == 'PASSWORD') {
    //   const storage = FlutterSecureStorage();
    //   final pwd = await storage.read(key: linksysPrefCloudAccountPasswordKey);
    //   if(pwd != null) {
    //     password = pwd;
    //   }
    // }
    // ChangeAuthenticationModeChallenge challenge = await context
    //     .read<AuthBloc>()
    //     .changeAuthModePrepare(state.id, password, mode);
    // ref.read(navigationsProvider.notifier).push(OTPViewPath()
    //   ..next = ChangeAuthModePasswordPath()
    //   ..args = {
    //     'commMethods': context.read<AccountCubit>().state.communicationMethods,
    //     'token': challenge.token,
    //     'changeModeTo' : mode
    //   });
  }

  Future<void> initPassword() async {
    const storage = FlutterSecureStorage();
    final accountPassword =
        await storage.read(key: linksysPrefCloudAccountPasswordKey);
    if (accountPassword != null) {
      setState(() {
        password = accountPassword;
      });
    }
  }
}
