import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/bloc/account/state.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/shortcuts/dialogs.dart';
import 'package:linksys_moab/route/model/dashboard_path.dart';
import 'package:linksys_moab/route/model/otp_path.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/util/validator.dart';
import 'package:linksys_moab/utils.dart';

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
              accountExpansionTile(
                title: SettingTileTwoLine(
                  title: Text('Username'),
                  value: Text(state.username),
                  space: 0,
                ),
                children: [
                  SettingTile(title: Text('Status'), value: Text(state.status)),
                  SettingTile(title: Text('Type'), value: Text(state.type)),
                  SettingTile(
                    title: Text('Authentication Mode'),
                    value: Text(state.authMode),
                    onPress:
                        state.authMode == LoginType.password.name.toUpperCase()
                            ? () {
                                // _showChangePasswordDialog();
                                NavigationCubit.of(context)
                                    .push(CloudPasswordValidationPath());
                              }
                            : null,
                  ),
                  SettingTile(title: Text('Biometric login'), value: Switch.adaptive(value: state.isBiometricEnabled, onChanged: (value){})),
                  SettingTile(title: Text('Linksys secure'), value: Switch.adaptive(value: state.isBiometricEnabled, onChanged: (value){})),
                  SettingTile(title: Text('Receive newsletter'), value: Switch.adaptive(value: state.pref.marketingOptIn, onChanged: (value){})),

                ],
              ),
              accountExpansionTile(
                title: Text('Preferences'),
                children: [
                  SettingTile(
                      title: Text('Language'),
                      value: Text(state.pref.isoLanguageCode)),
                  SettingTile(
                      title: Text('Country'),
                      value: Text(state.pref.isoCountryCode)),
                  SettingTile(
                      title: Text('Time zone'),
                      value: Text(state.pref.timeZone)),
                ],
              ),
              accountExpansionTile(
                  title: SettingTile(
                    title: Text('Communication methods'),
                    value: Text(state.communicationMethods
                        .map((e) => e.method)
                        .join('/')),
                  ),
                  children: _createCommunicationTiles(
                      state.username, state.communicationMethods)),
              SettingTile(
                  title: Text('Biometric login'),
                  value: Switch.adaptive(
                      value: state.isBiometricEnabled,
                      onChanged: (value) async {
                        // TODO check with cloud team, is there any way to revoke extended cert?
                        // final isValidate = await Utils.doLocalAuthenticate();
                        // if (isValidate) {
                        //   final authBloc = context.read<AuthBloc>();
                        //   await authBloc.extendCertification();
                        //   await authBloc.requestSession();
                        //   context.read<AccountCubit>().toggleBiometrics(value);
                        // }
                      })),
              SettingTile(
                  title: Text('Linksys secure'),
                  value: Switch.adaptive(value: true, onChanged: (value) {})),
              SettingTile(
                  title: Text('Receive newsletter'),
                  value: Switch.adaptive(
                      value: state.pref.marketingOptIn, onChanged: (value) {})),
              Spacer(),
            ],
          ));
    });
  }

  _showChangePasswordDialog() {
    TextEditingController _controller = TextEditingController();
    showAdaptiveDialog(
        context: context,
        title: Text('Change Password'),
        content: PasswordInputField.withValidator(
          titleText: 'New password',
          controller: _controller,
          color: Colors.black,
          inputType: TextInputType.visiblePassword,
        ),
        actions: [
          SimpleTextButton(
              text: 'OK',
              onPressed: () {
                if (ComplexPasswordValidator().validate(_controller.text)) {
                  // context
                  //     .read<AccountCubit>()
                  //     .changePassword(_controller.text)
                  //     .then((value) => Navigator.pop(context));
                } else {}
              }),
          SimpleTextButton(
              text: 'Cancel',
              onPressed: () {
                Navigator.pop(context);
              }),
        ]);
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
              value: Text('Not verified'),
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
              space: 0,
            )),
      );
    }
    if (!methods.any((element) => element.method == 'SMS')) {
      list.add(SettingTile(
        title: Text('SMS'),
        value: Text('Add phone'),
        space: 0,
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
              title: Text(method.method), value: Text(method.targetValue)),
        ),
        Offstage(
          offstage: !showDelete,
          child: IconButton(
              onPressed: () {
                showDeleteCommunicationMethodDialog(
                    method.method, method.targetValue);
              },
              icon: Icon(Icons.delete)),
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

  Widget accountExpansionTile(
      {Widget? title, List<Widget> children = const []}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: title ?? const Center(),
        textColor: Colors.black,
        tilePadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        collapsedTextColor: Colors.black,
        iconColor: Colors.black,
        collapsedIconColor: Colors.black,
        children: children,
      ),
    );
  }
}
