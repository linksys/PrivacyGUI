import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/bloc/account/state.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/shortcuts/dialogs.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:styled_text/styled_text.dart';

import '../../../../bloc/internet_check/cubit.dart';
import '../../../../route/model/create_account_path.dart';

class AccountView extends ConsumerStatefulWidget {
  const AccountView({super.key});

  @override
  ConsumerState<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends ConsumerState<AccountView> {
  late final TextEditingController _passwordController;
  String _displayPhoneNumber = '';
  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();

    if (context.read<AuthBloc>().isCloudLogin()) {
      final accountCubit = context.read<AccountCubit>();
      accountCubit.fetchAccount().then((_) {
        _passwordController.text = accountCubit.state.password;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(builder: (context, state) {
      return StyledLinksysPageView(
        scrollable: true,
        title: 'Account',
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
        const LinksysGap.regular(),
        _localLoginInformationSection(context),
        dividerWithPadding(),
        // _biometricsTile(state),
        const Spacer(),
      ],
    );
  }

  Widget _remote(AccountState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _informationSection(state),
        dividerWithPadding(),
        _securitySection(state),
        const Spacer(),
      ],
    );
  }

  Widget _informationSection(AccountState state) {
    return SectionTile(
      header: const LinksysText.tags(
        'YOUR INFORMATION',
      ),
      child: Column(
        children: [
          ..._createInfoTile(
            state.username,
            state.password,
            state.mobile?.fullFormat,
          ),
        ],
      ),
    );
  }

  Widget _securitySection(AccountState state) {
    return SectionTile(
      header: const LinksysText.tags(
        'Security',
      ),
      child: Column(
        children: [
          AppPanelWithInfo(
              title: '2-Step Verification',
              infoText: state.mfaEnabled ? 'On' : 'Off'),
        ],
      ),
    );
  }

  List<Widget> _createInfoTile(
      String username, String password, String? phoneNumber) {
    return [
      AppSimplePanel(
        title: 'Email',
        description: username,
      ),
      AppPasswordField(
        headerText: 'Password',
        controller: _passwordController,
      ),
      if (phoneNumber != null)
        AppSimplePanel(
          title: 'Phone Number',
          description: phoneNumber,
        ),
    ];
  }

  Widget _createCommunicationTile(CommunicationMethod method, bool showDelete) {
    return Row(
      children: [
        Expanded(
          child: SettingTile(
            axis: SettingTileAxis.vertical,
            title: Text(method.method == 'EMAIL' ? 'Email' : 'Phone number'),
            value: Text(
              method.target,
              style: Theme.of(context).textTheme.headline4,
            ),
            icon: Icon(Icons.delete),
            onPress: showDelete
                ? () {
                    _showDeleteCommunicationMethodDialog(
                        method.method, method.target);
                  }
                : null,
          ),
        ),
      ],
    );
  }

  // Widget _passwordLessTile(AccountState state) {
  //   return SettingTile(
  //     title: const Text('Log in method'),
  //     value: Text(
  //         state.authMode.toLowerCase() == AuthenticationType.passwordless.name
  //             ? "One-time passcode"
  //             : "Password",
  //         style: TextStyle(color: Colors.black.withOpacity(0.5))),
  //     onPress: () {
  //       ref.read(navigationsProvider.notifier).push(LoginMethodOptionsPath());
  //     },
  //   );
  // }

  // Widget _biometricsTile(AccountState state) {
  //   return SettingTile(
  //     title: Text('Biometric login'),
  //     description:
  //         'At vero eos et accusamus et iusto odio dignissimos. At vero eos et accusamus et iusto odio dignissimos.',
  //     value: Switch.adaptive(
  //       value: state.isBiometricEnabled,
  //       onChanged: (value) async {
  //         // if (!value) {
  //         //   _showConfirmBiometricDialog(value);
  //         // } else {
  //         //   final isValidate = await Utils.doLocalAuthenticate();
  //         //   if (isValidate) {
  //         //     final authBloc = context.read<AuthBloc>();
  //         //     await authBloc.extendCertification();
  //         //     await authBloc.requestSession();
  //         //     await context.read<AccountCubit>().toggleBiometrics(value);
  //         //   }
  //         // }
  //       },
  //     ),
  //   );
  // }

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
              ref.read(navigationsProvider.notifier).push(CreateCloudAccountPath()
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
                // await context.read<AccountCubit>().toggleBiometrics(value);
                // context.read<AuthBloc>().add(Logout());
                // Navigator.pop(context);
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
              // final _cubit = context.read<AccountCubit>();
              // _cubit
              //     .deleteCommunicationMethod(method, value)
              //     .then((value) => _cubit.fetchAccount())
              //     .then((value) => Navigator.pop(context));
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
