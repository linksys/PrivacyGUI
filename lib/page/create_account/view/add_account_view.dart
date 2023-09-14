import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/core/cloud/model/error_response.dart';
import 'package:linksys_app/page/components/layouts/basic_header.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/util/error_code_handler.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_app/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class AddAccountView extends ArgumentsConsumerStatefulView {
  const AddAccountView({Key? key, super.args}) : super(key: key);

  @override
  _AddAccountState createState() => _AddAccountState();
}

class _AddAccountState extends ConsumerState<AddAccountView> {
  // final bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  var isEmailInvalid = false;
  var _errorCode = '';
  bool _enableBiometrics = false;

  void _onNextAction() async {
    isEmailInvalid = !EmailValidator().validate(_emailController.text);
    if (!isEmailInvalid) {
      // setState(() {
      //   _isLoading = true;
      // });
      // await context
      //     .read<AuthBloc>()
      //     .createAccountPreparation(_emailController.text)
      //     .onError((error, stackTrace) => _handleError(error, stackTrace));
      // context
      //     .read<AuthBloc>()
      //     .add(SetEnableBiometrics(enableBiometrics: _enableBiometrics));
      // setState(() {
      //   _isLoading = false;
      // });
    } else {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Widget _buildAccountTipsWidget() {
    List<String> tips = [
      getAppLocalizations(context).add_cloud_account_bullet_1,
      getAppLocalizations(context).add_cloud_account_bullet_2,
      getAppLocalizations(context).add_cloud_account_bullet_3,
      getAppLocalizations(context).add_cloud_account_bullet_4,
      getAppLocalizations(context).add_cloud_account_bullet_5,
    ];

    return AppPadding(
      padding: const AppEdgeInsets.symmetric(vertical: AppGapSize.semiBig),
      child: Column(
        children: List.generate(tips.length, (index) {
          return Row(
            children: [
              AppIcon.regular(
                  icon: AppTheme.of(context).icons.characters.checkDefault),
              const AppGap.semiSmall(),
              AppText.bodyLarge(
                tips[index],
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    return state.when(
        data: (state) => _contentView(),
        error: (_, __) => const Center(
              child: AppText.bodyLarge('Something happen here'),
            ),
        loading: () => AppFullScreenSpinner(
            text: getAppLocalizations(context).processing));
    // return BlocConsumer<AuthBloc, AuthState>(
    //     listenWhen: (previous, current) {
    //       if (previous is AuthOnCreateAccountState &&
    //           current is AuthOnCreateAccountState) {
    //         return previous.vToken != current.vToken;
    //       }
    //       return false;
    //     },
    //     listener: (context, state) {
    //       if (state is AuthOnCreateAccountState) {
    //         if (state.vToken.isNotEmpty) {
    //           context.read<AuthBloc>().add(SetCloudPassword(password: ''));
    //           context.read<AuthBloc>().add(
    //               SetLoginType(loginType: AuthenticationType.passwordless));
    //           ref.read(navigationsProvider.notifier).push(CreateAccountOtpPath()
    //             ..args = {
    //               'username': _emailController.text,
    //               'function': OtpFunction.setting,
    //               'commMethods': state.accountInfo.communicationMethods,
    //               'token': state.vToken,
    //               ...widget.args
    //             });
    //         }
    //       }
    //     },
    //     builder: (context, state) => _isLoading
    //         ? FullScreenSpinner(text: getAppLocalizations(context).processing)
    //         : _contentView());
  }

  Widget _contentView() {
    return StyledAppPageView(
      scrollable: true,
      child: AppBasicLayout(
          header: BasicHeader(
            title: getAppLocalizations(context).add_cloud_account_header_title,
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                headerText:
                    getAppLocalizations(context).add_cloud_account_input_title,
                controller: _emailController,
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
                    AppText.bodyMedium(
                      generalErrorCodeHandler(context, _errorCode),
                    ),
                    AppTertiaryButton(
                      getAppLocalizations(context).login_to_continue,
                      onTap: _goLogin,
                    ),
                  ],
                ),
              ),
              const AppGap.semiSmall(),
              // FutureBuilder<bool>(
              //   future: Utils.canUseBiometrics(),
              //   initialData: false,
              //   builder: (context, canUseBiometrics) {
              //     return Offstage(
              //       offstage: !(canUseBiometrics.data ?? false),
              //       child: InkWell(
              //         onTap: () {
              //           setState(() {
              //             _enableBiometrics = !_enableBiometrics;
              //           });
              //         },
              //         child: AppPanelWithValueCheck(
              //           title: getAppLocalizations(context).enable_biometrics,
              //           valueText: '',
              //           isChecked: _enableBiometrics,
              //         ),
              //       ),
              //     );
              //   },
              // ),
              AppTertiaryButton(
                  getAppLocalizations(context).already_have_an_account,
                  onTap: _goLogin),
              const AppGap.big(),
              AppText.bodyLarge(getAppLocalizations(context)
                  .add_cloud_account_input_description),
              const AppGap.semiSmall(),
              _buildAccountTipsWidget(),
            ],
          ),
          footer: Column(
            children: [
              AppPrimaryButton(
                getAppLocalizations(context).next,
                onTap: _onNextAction,
              ),
              const AppGap.semiSmall(),
              widget.args['config'] != null &&
                      widget.args['config'] == 'LOCALAUTHCREATEACCOUNT'
                  ? Container()
                  : AppTertiaryButton(
                      getAppLocalizations(context).use_router_password,
                      onTap: () {},
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
    // Go Router
  }
}
