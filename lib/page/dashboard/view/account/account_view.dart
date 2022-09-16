import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/bloc/account/state.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/constants/constants.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/shortcuts/dialogs.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/route/model/dashboard_path.dart';
import 'package:linksys_moab/route/model/otp_path.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/util/validator.dart';
import 'package:linksys_moab/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  @override
  void initState() {
    context.read<AccountCubit>().fetchAccount();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 33),
              ..._createCommunicationTiles(
                  state.username, state.communicationMethods),
              SettingTileTwoLine(
                title: Text('Account Password'),
                value: state.authMode == LoginType.passwordless.name
                    ? Text(
                        'none',
                        style: Theme.of(context).textTheme.headline4,
                      )
                    : Text(
                        '**********',
                        style: Theme.of(context).textTheme.headline4,
                      ),
                onPress: state.authMode == LoginType.password.name.toUpperCase()
                    ? () {
                        NavigationCubit.of(context)
                            .push(CloudPasswordValidationPath());
                      }
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(
                  height: 2,
                ),
              ),
              SettingTileWithDescription(
                  title: Text('Biometric login'),
                  description: Text(
                      'At vero eos et accusamus et iusto odio dignissimos. At vero eos et accusamus et iusto odio dignissimos.'),
                  value: Switch.adaptive(
                      value: state.isBiometricEnabled,
                      onChanged: (value) async {
                        if (!value) {
                          showAdaptiveDialog(
                              context: context,
                              title: Text('Warning'),
                              content: Text(
                                  'You\'ll need to login again after turning off biometric login'),
                              actions: [
                                SimpleTextButton(
                                    text: 'Turn off',
                                    onPressed: () async {
                                      await context
                                          .read<AccountCubit>()
                                          .toggleBiometrics(value);
                                      context.read<AuthBloc>().add(Logout());
                                      Navigator.pop(context);
                                    }),
                                SimpleTextButton(
                                    text: 'Cancel',
                                    onPressed: () => Navigator.pop(context))
                              ]);
                        } else {
                          final isValidate = await Utils.doLocalAuthenticate();
                          if (isValidate) {
                            final authBloc = context.read<AuthBloc>();
                            await authBloc.extendCertification();
                            await authBloc.requestSession();
                            await context
                                .read<AccountCubit>()
                                .toggleBiometrics(value);
                          }
                        }
                      })),
              box16(),
              SettingTileWithDescription(
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
              box16(),
              SettingTileWithDescription(
                  title: Text('Receive newsletter'),
                  description: Text(
                      'At vero eos et accusamus et iusto odio dignissimos. At vero eos et accusamus et iusto odio dignissimos.'),
                  value: Switch.adaptive(
                      value: state.pref.marketingOptIn, onChanged: (value) {})),
              Spacer(),
            ],
          ));
    });
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
                final otpInfo = OtpInfo(
                  method: OtpMethod.email,
                  data: username,
                );
                context.read<OtpCubit>().updateToken(token);
                context.read<OtpCubit>().selectOtpMethod(otpInfo);
                context.read<AuthBloc>().authChallenge(otpInfo, token: token);
                NavigationCubit.of(context).push(OtpInputCodePath()
                  ..next = AccountPath()
                  ..args = {'function': OtpFunction.add});
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
            ..next = AccountPath()
            ..args = {'function': OtpFunction.add});
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
                    showDeleteCommunicationMethodDialog(
                        method.method, method.targetValue);
                  }
                : null,
          ),
        ),
      ],
    );
  }

  showDeleteCommunicationMethodDialog(String method, String value) {
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
