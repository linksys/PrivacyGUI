import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';


class CloudResetPasswordView extends ArgumentsConsumerStatefulView {
  const CloudResetPasswordView({Key? key}) : super(key: key);

  @override
  _CloudForgotPasswordViewState createState() =>
      _CloudForgotPasswordViewState();
}

class _CloudForgotPasswordViewState
    extends ConsumerState<CloudResetPasswordView> {
  final TextEditingController _passwordController = TextEditingController();
  String _errorReason = '';
  final bool _isLoading = false;
  bool _isNewPasswordSet = false;
  final bool _isLinkExpired = false;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppText.descriptionMain('TBD'),
    );
  }

  Widget _setNewPasswordView() {
    return BasePageView.withCloseButton(
      context,
      ref,
      scrollable: true,
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).enter_your_new_password,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 37,
            ),
            AppPasswordField.withValidator(
              headerText: getAppLocalizations(context).enter_password,
              controller: _passwordController,
              errorText: _checkErrorReason(),
              onChanged: (value) {
                setState(() {
                  _errorReason = '';
                });
              },
            ),
            const SizedBox(
              height: 23,
            ),
            PrimaryButton(
              text: getAppLocalizations(context).text_continue,
              onPress: _localValidatePassword(_passwordController.text)
                  ? () async {
                      // setState(() {
                      //   _isLoading = true;
                      // });
                      // await context
                      //     .read<AuthBloc>()
                      //     .resetPassword(_passwordController.text)
                      //     .then((value) => _handleResult())
                      //     .onError((error, stackTrace) =>
                      //         _handleError(error, stackTrace));
                      // setState(() {
                      //   _isLoading = false;
                      // });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _newPasswordSetView() {
    return BasePageView.noNavigationBar(
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).new_password_set,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(
                Icons.check,
                color: Colors.white,
              ),
              onPressed: () {
                ref.read(navigationsProvider.notifier).clearAndPush(HomePath());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkExpiredView() {
    return BasePageView.withCloseButton(
      context,
      ref,
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).error_reset_password_link_expired,
        ),
        content: Column(
          children: [
            const SizedBox(
              height: 67,
            ),
            PrimaryButton(
              text: getAppLocalizations(context).back_to_login,
              onPress: () {
                ref.read(navigationsProvider.notifier).clearAndPush(HomePath());
              },
            )
          ],
        ),
      ),
    );
  }

  String _checkErrorReason() {
    if (_errorReason == 'OLD_PASSWORD') {
      return getAppLocalizations(context).error_reset_password_use_old_password;
    } else {
      return getAppLocalizations(context).unknown_error;
    }
  }

  bool _localValidatePassword(String password) {
    return ComplexPasswordValidator().validate(password);
  }

  _handleResult() async {
    setState(() {
      _isNewPasswordSet = true;
    });
  }

  _handleError(Object? e, StackTrace trace) {
    if (e is ErrorResponse) {
      setState(() {
        _errorReason = e.code;
      });
    } else {
      // Unknown error or error parsing
      logger.d('Unknown error: $e');
    }
  }
}
