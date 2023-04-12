import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/util/error_code_handler.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:linksys_moab/route/model/_model.dart';

class CloudLoginPasswordView extends ArgumentsStatefulView {
  const CloudLoginPasswordView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<CloudLoginPasswordView> createState() =>
      _LoginTraditionalPasswordViewState();
}

class _LoginTraditionalPasswordViewState extends State<CloudLoginPasswordView> {
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorCode = '';
  String _username = '';

  late AuthBloc _authBloc;
  late OtpCubit _optCubit;

  @override
  initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _optCubit = context.read<OtpCubit>();
  }

  @override
  dispose() {
    super.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          if (current is AuthCloudLoginState) {
            return true;
          }
          return false;
        },
        listener: (context, state) {
          if (state is AuthCloudLoginState) {
            // NavigationCubit.of(context).push(PrepareDashboardPath());
          } else {
            logger.d('ERROR: Wrong state type on LoginTraditionalPasswordView');
          }
        },
        builder: (context, state) => _isLoading
            ? LinksysFullScreenSpinner(
                text: getAppLocalizations(context).processing)
            : _contentView(state));
  }

  Widget _contentView(AuthState state) {
    // TODO HERE
    _username =
        state is AuthOnCloudLoginState ? state.accountInfo.username : '';
    return StyledLinksysPageView(
      scrollable: true,
      child: LinksysBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: LinksysText.screenName(
          getAppLocalizations(context).enter_password,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LinksysGap.big(),
            LinksysText.descriptionMain(_username),
            AppPasswordField(
              key: const Key('login_password_view_input_field_password'),
              // headerText: getAppLocalizations(context).password,
              hintText: getAppLocalizations(context).password,
              // isError: _errorCode.isNotEmpty,
              errorText: generalErrorCodeHandler(context, _errorCode),
              controller: passwordController,
              autofillHint: const [AutofillHints.password],
              onChanged: (value) {
                setState(() {
                  _errorCode = '';
                });
              },
            ),
            const LinksysGap.small(),
            LinksysTertiaryButton.noPadding(
              getAppLocalizations(context).forgot_password,
              key: const Key('login_password_view_button_forgot_password'),
              onTap: () {
                NavigationCubit.of(context).push(AuthCloudForgotPasswordPath());
              },
            ),
            const Spacer(),
            LinksysPrimaryButton(
              getAppLocalizations(context).text_continue,
              key: const Key('login_password_view_button_continue'),
              onTap: passwordController.text.isEmpty
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      await context
                          .read<AuthBloc>()
                          .loginPassword(password: passwordController.text)
                          .onError((error, stackTrace) =>
                              _handleError(error, stackTrace));
                      setState(() {
                        _isLoading = false;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  _handleError(Object? e, StackTrace trace) {
    final error = e as ErrorResponse?;
    if (error == null) {
      // Unknown error or error parsing
      logger.d('Unknown error: $error');
      return;
    }

    if (error.code == errorMfaRequired) {
      final mfaError = ErrorMfaRequired.fromResponse(error);
      NavigationCubit.of(context).pushAndWait(OTPViewPath()
        ..args = {
          'username': _username,
          'token': mfaError.verificationToken,
          'password': passwordController.text,
        }
        ..next = PrepareDashboardPath());
    } else {
      setState(() {
        _errorCode = error.code;
      });
    }
  }
}
