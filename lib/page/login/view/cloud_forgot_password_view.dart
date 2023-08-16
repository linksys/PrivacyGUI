import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/provider/auth/auth_provider.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class CloudForgotPasswordView extends ArgumentsConsumerStatefulView {
  const CloudForgotPasswordView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _CloudForgotPasswordViewState createState() =>
      _CloudForgotPasswordViewState();
}

class _CloudForgotPasswordViewState
    extends ConsumerState<CloudForgotPasswordView> {
  bool _isLoading = false;
  final bool _isLinkSent = false;

  // TODO: need modify
  final bool _hasPhoneNumber = false;
  bool _sendLinkViaEmail = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(authProvider);
    return data.when(
        data: _contentView,
        error: (_, __) => const Center(
              child: AppText.descriptionMain('Something wrong here'),
            ),
        loading: () => AppFullScreenSpinner(
            text: getAppLocalizations(context).processing));
  }

  Widget _contentView(AuthState state) {
    // TODO: need modify
    // _hasPhoneNumber = (state as AuthOnCloudLoginState)
    //         .accountInfo
    //         .communicationMethods
    //         .length >
    //     1;
    return _isLinkSent ? _linkSentView(state) : _sendLinkView(state);
  }

  Widget _sendLinkView(AuthState state) {
    return StyledAppPageView(
      isCloseStyle: true,
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).cloud_forgot_password_title,
          description:
              getAppLocalizations(context).cloud_forgot_password_description,
          spacing: 12,
        ),
        content: Column(
          children: [
            if (_hasPhoneNumber) _chooseMethodView(state),
            _hasPhoneNumber ? const AppGap.semiBig() : const AppGap.extraBig(),
            AppPrimaryButton(
              getAppLocalizations(context).send_link,
              onTap: () async {
                setState(() {
                  _isLoading = true;
                });
                // await context
                //     .read<AuthBloc>()
                //     .forgotPassword()
                //     .then((value) => {
                //           setState(() {
                //             _isLinkSent = true;
                //           })
                //         });
                setState(() {
                  _isLoading = false;
                });
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _chooseMethodView(AuthState state) {
    return Column(
      children: [
        const AppGap.big(),
        InkWell(
          child: AppPanelWithValueCheck(
            title: getAppLocalizations(context).sms,
            valueText: ' ',
            isChecked: !_sendLinkViaEmail,
          ),
          onTap: () {
            setState(() {
              _sendLinkViaEmail = false;
            });
          },
        ),
        const AppGap.regular(),
        InkWell(
          child: AppPanelWithValueCheck(
            title: state.username ?? '',
            valueText: ' ',
            isChecked: _sendLinkViaEmail,
          ),
          onTap: () {
            setState(() {
              _sendLinkViaEmail = true;
            });
          },
        )
      ],
    );
  }

  Widget _linkSentView(AuthState state) {
    return AppPageView(
      child: AppBasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).link_sent,
          description: _sendLinkViaEmail
              ? ''
              : getAppLocalizations(context)
                  .cloud_forgot_password_not_receive_email,
        ),
        content: Column(
          children: [
            _sendLinkViaEmail ? const AppGap.extraBig() : const AppGap.big(),
            AppPrimaryButton(
              getAppLocalizations(context).back_to_login,
              onTap: () {
                // Go Router
              },
            ),
          ],
        ),
      ),
    );
  }
}
