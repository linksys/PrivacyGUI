import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/internet_check/cubit.dart';
import 'package:linksys_moab/bloc/internet_check/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/internet_check_path.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';
import 'package:linksys_moab/util/logger.dart';

class EnterIspSettingsView extends StatefulWidget {
  const EnterIspSettingsView({Key? key}) : super(key: key);

  @override
  State<EnterIspSettingsView> createState() => _EnterIspSettingsViewState();
}

class _EnterIspSettingsViewState extends State<EnterIspSettingsView> {
  final TextEditingController accountController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController vLanIdController = TextEditingController();

  late final InternetCheckCubit _internetCheckCubit;

  bool _hasError = false;
  bool _isLoading = false;

  @override
  void initState() {
    _internetCheckCubit = context.read<InternetCheckCubit>();
    super.initState();
  }

  void _checkCredentials() {
    setState(() {
      _isLoading = true;
    });
    final vlanId = vLanIdController.text;
    if (vlanId.isNotEmpty) {
      // check internet connection
    }

    _internetCheckCubit
        .setPPPoESettings(
      accountController.text,
      passwordController.text,
      vlanId,
    )
        .then((_) {

    }).onError((error, stackTrace) {
      // show something error here
      logger.e('set PPPoE settings', error, stackTrace);
    }).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InternetCheckCubit, InternetCheckState>(
      listener: (context, state) {
        if (state.status == InternetCheckStatus.detectWANStatus) {
          setState(() {
            _isLoading = true;
          });
          _internetCheckCubit.detectWANStatusUntilConnected();
        } else if (state.status == InternetCheckStatus.checkWiring) {
          // not connected
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      },
      child: _isLoading ? FullScreenSpinner() : BasePageView(
        scrollable: true,
        child: BasicLayout(
          header: BasicHeader(
            title: getAppLocalizations(context).enter_isp_settings_title,
          ),
          content: Column(
            children: [
              Offstage(
                offstage: !_hasError,
                child: Column(
                  children: [
                    Text(
                      getAppLocalizations(context).enter_isp_settings_error,
                      style: Theme.of(context)
                          .textTheme
                          .headline4
                          ?.copyWith(color: Colors.red),
                    ),
                    const SizedBox(
                      height: 30,
                    )
                  ],
                ),
              ),
              InputField(
                titleText: getAppLocalizations(context).account_name,
                controller: accountController,
                isError: _hasError,
                onChanged: (text) {
                  setState(() {
                    _hasError = false;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: PasswordInputField(
                  titleText: getAppLocalizations(context).password,
                  controller: passwordController,
                  isError: _hasError,
                  onChanged: (text) {
                    setState(() {
                      _hasError = false;
                    });
                  },
                ),
              ),
              InputField(
                titleText: getAppLocalizations(context).vlan_id,
                controller: vLanIdController,
              ),
            ],
          ),
          footer: PrimaryButton(
            text: getAppLocalizations(context).next,
            onPress: accountController.text.isEmpty || passwordController.text.isEmpty ? null : _checkCredentials,
          ),
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ),
    );
  }
}
