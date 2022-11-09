import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/bloc/account/state.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/shortcuts/dialogs.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/route/model/account_path.dart';
import 'package:linksys_moab/route/model/dashboard_path.dart';
import 'package:linksys_moab/route/model/otp_path.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/utils.dart';
import 'package:styled_text/styled_text.dart';

import '../../../../bloc/internet_check/cubit.dart';
import '../../../../route/model/create_account_path.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  @override
  void initState() {
    if (context.read<AuthBloc>().isCloudLogin()) {
      context.read<AccountCubit>().fetchAccount();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(builder: (context, state) {
      return BasePageView.onDashboardSecondary(
        scrollable: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(getAppLocalizations(context).account,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading: BackButton(onPressed: () {
            NavigationCubit.of(context).pop();
          }),
          actions: [],
        ),
        child: context.read<AuthBloc>().isCloudLogin()
            ? _remote(state)
            : _local(state),
      );
    });
  }

  Widget _local(AccountState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 33),
        box16(),
        _localLoginInformationSection(context),
        dividerWithPadding(),
        _biometricsTile(state),
        const Spacer(),
      ],
    );
  }

  Widget _remote(AccountState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 33),
        Center(
          child: CircleAvatar(
            child: Image.asset(
              'assets/images/icon_default_avatar.png',
              width: 52,
              height: 52,
            ),
            radius: 45,
            backgroundColor: MoabColor.avatarBackground,
          ),
        ),
        box16(),
        _informationSection(state),
        dividerWithPadding(),
        _subscriptionSection(state),
        dividerWithPadding(),
        _preferencesSection(state),
        const Spacer(),
      ],
    );
  }

  Widget _informationSection(AccountState state) {
    return SectionTile(
      header: Text(
        'YOUR INFORMATION',
        style: Theme.of(context).textTheme.headline4,
      ),
      child: Column(
        children: [
          ..._createCommunicationTiles(
              state.username, state.communicationMethods),
        ],
      ),
    );
  }

  Widget _subscriptionSection(AccountState state) {
    return SectionTile(
      header: Text(
        'SUBSCRIPTION',
        style: Theme.of(context).textTheme.headline4,
      ),
      child: SettingTileWithDescription(
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Linksys secure'),
              box8(),
              Text(
                'Active',
                style: Theme.of(context).textTheme.headline4,
              )
            ],
          ),
          description: Text('Next charge is on April, 23, 2024'),
          value: Switch.adaptive(value: true, onChanged: (value) {})),
    );
  }

  Widget _preferencesSection(AccountState state) {
    return SectionTile(
      header: Text(
        'PREFERENCES',
        style: Theme.of(context).textTheme.headline4,
      ),
      child: Column(
        children: [
          _passwordLessTile(state),
          box16(),
          _biometricsTile(state),
          box16(),
          SettingTileWithDescription(
              title: Text('Receive newsletter'),
              description: Text(
                  'At vero eos et accusamus et iusto odio dignissimos. At vero eos et accusamus et iusto odio dignissimos.'),
              value: Switch.adaptive(
                  value: state.pref.marketingOptIn, onChanged: (value) {})),
        ],
      ),
    );
  }

  List<Widget> _createCommunicationTiles(
      String username, List<CommunicationMethod> methods) {
    List<Widget> list = [];
    if (!methods.any((element) => element.method == 'EMAIL')) {
      list.add(
        SectionTile(
            header: Text('Email'),
            child: SettingTile(
              title: Text(username),
              value: Text(
                'Not verified',
                style: Theme.of(context).textTheme.headline4?.copyWith(
                      color: MoabColor.primaryBlue,
                    ),
              ),
              onPress: () async {
                String token = await context
                    .read<AccountCubit>()
                    .startAddCommunicationMethod(
                      CommunicationMethod(
                        method: 'EMAIL',
                        targetValue: username,
                      ),
                    );
                final selectedMethod = CommunicationMethod(
                  method: CommunicationMethodType.email.name.toUpperCase(),
                  targetValue: username,
                );
                // context.read<OtpCubit>().updateToken(token);
                // context.read<OtpCubit>().selectOtpMethod(otpInfo);
                // context
                //     .read<AuthBloc>()
                //     .authChallenge(method: otpInfo, token: token);
                NavigationCubit.of(context).push(OtpPreparePath()
                  ..next = AccountDetailPath()
                  ..args = {
                    'function': OtpFunction.add,
                    'username': username,
                    'commMethods': methods,
                    'token': token,
                    'selected': selectedMethod,
                  });
              },
            )),
      );
    }
    if (!methods.any((element) => element.method == 'SMS')) {
      list.add(SettingTileTwoLine(
        title: Text('Phone number'),
        value: Text(
          '+Add',
          style: Theme.of(context).textTheme.headline4?.copyWith(
                color: MoabColor.primaryBlue,
              ),
        ),
        onPress: () {
          NavigationCubit.of(context).push(OtpAddPhonePath()
            ..next = AccountDetailPath()
            ..args = {
              'function': OtpFunction.add,
            });
        },
      ));
    }
    if (list.length < 2) {
      list.addAll(
          methods.map((e) => _createCommunicationTile(e, methods.length == 2)));
    }
    return list;
  }

  Widget _createCommunicationTile(CommunicationMethod method, bool showDelete) {
    return Row(
      children: [
        Expanded(
          child: SettingTileTwoLine(
            title: Text(method.method == 'EMAIL' ? 'Email' : 'Phone number'),
            value: Text(
              method.targetValue,
              style: Theme.of(context).textTheme.headline4,
            ),
            icon: Icon(Icons.delete),
            onPress: showDelete
                ? () {
                    _showDeleteCommunicationMethodDialog(
                        method.method, method.targetValue);
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _passwordLessTile(AccountState state) {
    return SettingTile(
      title: const Text('Log in method'),
      value: Text(
          state.authMode.toLowerCase() == AuthenticationType.passwordless.name
              ? "One-time passcode"
              : "Password",
          style: TextStyle(color: Colors.black.withOpacity(0.5))),
      onPress: () {
        NavigationCubit.of(context).push(LoginMethodOptionsPath());
      },
    );
  }

  Widget _biometricsTile(AccountState state) {
    return SettingTileWithDescription(
      title: Text('Biometric login'),
      description: Text(
          'At vero eos et accusamus et iusto odio dignissimos. At vero eos et accusamus et iusto odio dignissimos.'),
      value: Switch.adaptive(
        value: state.isBiometricEnabled,
        onChanged: (value) async {
          if (!value) {
            _showConfirmBiometricDialog(value);
          } else {
            final isValidate = await Utils.doLocalAuthenticate();
            if (isValidate) {
              final authBloc = context.read<AuthBloc>();
              await authBloc.extendCertification();
              await authBloc.requestSession();
              await context.read<AccountCubit>().toggleBiometrics(value);
            }
          }
        },
      ),
    );
  }

  Widget _localLoginInformationSection(BuildContext context) {
    return SectionTile(
      header: Text(
        'No Linksys account',
        style: Theme.of(context).textTheme.headline4,
      ),
      child: Column(
        children: [
          StyledText(
              text:
                  'Unlock app features with a Linksys account  <link href="https://flutter.dev">Learn more</link>',
              style: Theme.of(context)
                  .textTheme
                  .headline2
                  ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
              tags: {
                'link': StyledTextActionTag(
                    (String? text, Map<String?, String?> attrs) {
                  String? link = attrs['href'];
                  print('The "$link" link is tapped.');
                }, style: const TextStyle(color: Colors.blue)),
              }),
          box16(),
          Row(children: [
            box4(),
            Text('\u2022'),
            box4(),
            Text(
              'Benefit 1',
              style: Theme.of(context).textTheme.headline4,
            ),
          ]),
          Row(children: [
            box4(),
            Text('\u2022'),
            box4(),
            Text(
              'Benefit 2',
              style: Theme.of(context).textTheme.headline4,
            ),
          ]),
          Row(children: [
            box4(),
            Text('\u2022'),
            box4(),
            Text(
              'Benefit X',
              style: Theme.of(context).textTheme.headline4,
            ),
          ]),
          const SizedBox(
            height: 28,
          ),
          PrimaryButton(
            text: 'Create an account',
            onPress: () {
              context.read<InternetCheckCubit>().getInternetConnectionStatus();
              context.read<NavigationCubit>().push(CreateCloudAccountPath()
                ..args = {'config': 'LOCALAUTHCREATEACCOUNT'});
            },
          ),
          const SizedBox(
            height: 46,
          ),
        ],
      ),
    );
  }

  _showConfirmBiometricDialog(bool value) {
    showAdaptiveDialog(
        context: context,
        title: Text('Warning'),
        content: Text(
            'You\'ll need to login again after turning off biometric login'),
        actions: [
          SimpleTextButton(
              text: 'Turn off',
              onPressed: () async {
                await context.read<AccountCubit>().toggleBiometrics(value);
                context.read<AuthBloc>().add(Logout());
                Navigator.pop(context);
              }),
          SimpleTextButton(
              text: 'Cancel', onPressed: () => Navigator.pop(context))
        ]);
  }

  _showDeleteCommunicationMethodDialog(String method, String value) {
    showAdaptiveDialog(
      context: context,
      title: Text('Warning'),
      content: Text('Do you want to delete $method: $value'),
      actions: [
        SimpleTextButton(
            text: 'Yes',
            onPressed: () {
              final _cubit = context.read<AccountCubit>();
              _cubit
                  .deleteCommunicationMethod(method, value)
                  .then((value) => _cubit.fetchAccount())
                  .then((value) => Navigator.pop(context));
            }),
        SimpleTextButton(
            text: 'No',
            onPressed: () {
              Navigator.pop(context);
            }),
      ],
    );
  }
}
