import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/auth/auth_provider.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import '../../components/base_components/progress_bars/full_screen_spinner.dart';

class CloudForgotPasswordView extends ArgumentsConsumerStatefulView {
  const CloudForgotPasswordView({
    Key? key,
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
        error: (_, __) => const Center(child: AppText.descriptionMain('Something wrong here'),),
        loading: () =>
            FullScreenSpinner(text: getAppLocalizations(context).processing));
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
    return BasePageView.withCloseButton(
      context,
      ref,
      child: BasicLayout(
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
            SizedBox(
              height: _hasPhoneNumber ? 32 : 71,
            ),
            PrimaryButton(
              text: getAppLocalizations(context).send_link,
              onPress: () async {
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
        const SizedBox(
          height: 35,
        ),
        GestureDetector(
          child: SelectableItem(
            text: getAppLocalizations(context).sms,
            height: 66,
            isSelected: !_sendLinkViaEmail,
          ),
          onTap: () {
            setState(() {
              _sendLinkViaEmail = false;
            });
          },
        ),
        const SizedBox(
          height: 13,
        ),
        GestureDetector(
          child: SelectableItem(
            text: state.username ?? '',
            height: 66,
            isSelected: _sendLinkViaEmail,
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
    return BasePageView.noNavigationBar(
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).link_sent,
          description: _sendLinkViaEmail
              ? ''
              : getAppLocalizations(context)
                  .cloud_forgot_password_not_receive_email,
        ),
        content: Column(
          children: [
            SizedBox(
              height: _sendLinkViaEmail ? 123 : 71,
            ),
            PrimaryButton(
              text: getAppLocalizations(context).back_to_login,
              onPress: () {
                // TODO: need universal link after sending link, keep go on next page for now
                ref
                    .read(navigationsProvider.notifier)
                    .push(AuthCloudResetPasswordPath());
              },
            ),
          ],
        ),
      ),
    );
  }
}
