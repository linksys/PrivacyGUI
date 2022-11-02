import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/bloc/setup/bloc.dart';
import 'package:linksys_moab/bloc/setup/event.dart';
import 'package:linksys_moab/bloc/setup/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/simple_text_button.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/input_field.dart';
import 'package:linksys_moab/page/components/base_components/text/description_text.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/util/error_code_handler.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/util/validator.dart';
import 'package:linksys_moab/utils.dart';

import '../../components/base_components/button/primary_button.dart';
import '../../components/base_components/progress_bars/full_screen_spinner.dart';

class AddAccountView extends ArgumentsStatefulView {
  const AddAccountView({Key? key, super.args}) : super(key: key);

  @override
  _AddAccountState createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccountView> {
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  var isEmailInvalid = false;
  var _errorCode = '';
  bool _enableBiometrics = false;

  void _onNextAction() async {
    isEmailInvalid = !EmailValidator().validate(_emailController.text);
    if (!isEmailInvalid) {
      setState(() {
        _isLoading = true;
      });
      await context
          .read<AuthBloc>()
          .createAccountPreparation(_emailController.text)
          .onError((error, stackTrace) => _handleError(error, stackTrace));
      context
          .read<AuthBloc>()
          .add(SetEnableBiometrics(enableBiometrics: _enableBiometrics));
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<SetupBloc>().add(
        const ResumePointChanged(status: SetupResumePoint.createCloudAccount));
  }

  Widget _buildAccountTipsWidget() {
    List<String> tips = [
      getAppLocalizations(context).add_cloud_account_bullet_1,
      getAppLocalizations(context).add_cloud_account_bullet_2,
      getAppLocalizations(context).add_cloud_account_bullet_3,
      getAppLocalizations(context).add_cloud_account_bullet_4,
      getAppLocalizations(context).add_cloud_account_bullet_5,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Column(
        children: List.generate(tips.length, (index) {
          return Row(
            children: [
              Image.asset('assets/images/icon_check_green.png'),
              const SizedBox(
                width: 8,
              ),
              Text(
                tips[index],
                style: Theme.of(context).textTheme.headline4?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          if (previous is AuthOnCreateAccountState &&
              current is AuthOnCreateAccountState) {
            return previous.vToken != current.vToken;
          }
          return false;
        },
        listener: (context, state) {
          if (state is AuthOnCreateAccountState) {
            if (state.vToken.isNotEmpty) {
              context.read<AuthBloc>().add(SetCloudPassword(password: ''));
              context.read<AuthBloc>().add(
                  SetLoginType(loginType: AuthenticationType.passwordless));
              NavigationCubit.of(context).push(CreateAccountOtpPath()
                ..args = {
                  'username': _emailController.text,
                  'function': OtpFunction.setting,
                  'commMethods': state.accountInfo.communicationMethods,
                  'token': state.vToken,
                  ...widget.args
                });
            }
          }
        },
        builder: (context, state) => _isLoading
            ? FullScreenSpinner(text: getAppLocalizations(context).processing)
            : _contentView());
  }

  Widget _contentView() {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
          alignment: CrossAxisAlignment.start,
          header: BasicHeader(
            title: getAppLocalizations(context).add_cloud_account_header_title,
          ),
          content: Column(
            children: [
              InputField(
                titleText:
                    getAppLocalizations(context).add_cloud_account_input_title,
                controller: _emailController,
                isError: isEmailInvalid,
                errorText: 'Enter a valid email format',
                inputType: TextInputType.emailAddress,
                onChanged: (value) {
                  setState(() {
                    isEmailInvalid = false;
                  });
                },
              ),
              Offstage(
                offstage: _errorCode.isEmpty,
                child: Wrap(
                  children: [
                    Text(
                      generalErrorCodeHandler(context, _errorCode),
                      style: Theme.of(context)
                          .textTheme
                          .headline3
                          ?.copyWith(color: Colors.red),
                    ),
                    SimpleTextButton.onPaddingWithStyle(
                        text: getAppLocalizations(context).login_to_continue,
                        onPressed: _goLogin,
                        textStyle: const TextStyle(color: Colors.blue))
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<bool>(
                future: Utils.canUseBiometrics(),
                initialData: false,
                builder: (context, canUseBiometrics) {
                  return Offstage(
                    offstage: !(canUseBiometrics.data ?? false),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _enableBiometrics = !_enableBiometrics;
                        });
                      },
                      child: CheckboxSelectableItem(
                        title: getAppLocalizations(context).enable_biometrics,
                        isSelected: _enableBiometrics,
                      ),
                    ),
                  );
                },
              ),
              SimpleTextButton(
                  text: getAppLocalizations(context).already_have_an_account,
                  onPressed: _goLogin),
              const SizedBox(height: 32),
              DescriptionText(
                  text: getAppLocalizations(context)
                      .add_cloud_account_input_description),
              const SizedBox(
                height: 8,
              ),
              _buildAccountTipsWidget(),
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
          footer: Column(
            children: [
              PrimaryButton(
                text: getAppLocalizations(context).next,
                onPress: _onNextAction,
              ),
              const SizedBox(height: 8),
              widget.args['config'] != null &&
                      widget.args['config'] == 'LOCALAUTHCREATEACCOUNT'
                  ? Container()
                  : SimpleTextButton(
                      text: getAppLocalizations(context).use_router_password,
                      onPressed: () {
                        NavigationCubit.of(context)
                            .push(NoUseCloudAccountPath());
                      },
                    )
            ],
          )),
    );
  }

  _handleError(Object? e, StackTrace trace) {
    if (e is ErrorResponse) {
      setState(() {
        _errorCode = e.code;
      });
    } else {
      // Unknown error or error parsing
      logger.d('Unknown error: $e');
    }
  }

  _goLogin() {
    NavigationCubit.of(context).push(AuthSetupLoginPath());
  }
}
