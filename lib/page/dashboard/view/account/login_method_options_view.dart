import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_moab/bloc/account/_account.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/account_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';

import '../../../../constants/pref_key.dart';

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
  bool isShowPlainText = false;

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
    return AppPageView(
      appBar: LinksysAppBar.withBack(
        context: context,
        title: const AppText.screenName('Log in method'),
        onBackTap: () {
          if (ref.read(navigationsProvider).contains(AccountDetailPath())) {
            ref.read(navigationsProvider.notifier).popTo(AccountDetailPath());
          } else {
            ref
                .read(navigationsProvider.notifier)
                .clearAndPush(AccountDetailPath());
          }
        },
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: const AppText.descriptionMain(
              'One-time passcode (OTP)',
            ),
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
            subtitle: const AppText.descriptionSub(
              'A one-time passcode verification is required to log in',
            ),
          ),
          const AppGap.semiBig(),
          ListTile(
            title: password == null
                ? const AppText.descriptionMain(
                    'Password',
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: AppText.descriptionMain(
                              'Password',
                            ),
                          ),
                          AppTertiaryButton(
                            'Edit',
                            onTap: () {},
                          )
                        ],
                      ),
                      Row(
                        children: [
                          isShowPlainText
                              ? AppText.descriptionMain(
                                  password!,
                                )
                              : const AppText.descriptionSub(
                                  '\u25cf\u25cf\u25cf\u25cf\u25cf\u25cf\u25cf',
                                ),
                          const AppGap.semiSmall(),
                          GestureDetector(
                            child: Image.asset(
                              'assets/images/eye_closed.png',
                              width: 26,
                              height: 26,
                            ),
                            onTap: () {
                              setState(() {
                                isShowPlainText = !isShowPlainText;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
            leading: Radio<LoginMethod>(
              value: LoginMethod.password,
              groupValue: _choose,
              onChanged: (LoginMethod? value) {
                setState(() {
                  _choose = value;
                  if (password == null) {
                    // changeAuthModePrepare(context, state);
                  }
                });
              },
              activeColor: Colors.black,
            ),
            subtitle: const AppText.descriptionSub(
              'A traditional password and a one-time passcode verification are required to log in',
            ),
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
