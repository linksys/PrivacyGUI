import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/route.dart';

import '../../components/base_components/progress_bars/full_screen_spinner.dart';

class CloudForgotPasswordView extends ArgumentsStatefulView {
  const CloudForgotPasswordView({
    Key? key,
  }) : super(key: key);

  @override
  _CloudForgotPasswordViewState createState() => _CloudForgotPasswordViewState();
}

class _CloudForgotPasswordViewState extends State<CloudForgotPasswordView> {
  bool _isLoading = false;
  bool _isLinkSent = false;

  // TODO: need modify
  bool _hasPhoneNumber = false;
  bool _sendLinkViaEmail = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => _isLoading
          ? const FullScreenSpinner(text: 'processing...')
          : _contentView(state),
    );
  }

  Widget _contentView(AuthState state) {
    // TODO: need modify
    _hasPhoneNumber = state.accountInfo.otpInfo.length > 1;
    return _isLinkSent ? _linkSentView(state) : _sendLinkView(state);
  }

  Widget _sendLinkView(AuthState state) {
    return BasePageView.withCloseButton(
      context,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'We’ll send you a link to reset your password.',
          description: 'This link will expire in 15 minutes.',
          spacing: 12,
        ),
        content: Column(
          children: [
            if (_hasPhoneNumber) _chooseMethodView(state),
            SizedBox(
              height: _hasPhoneNumber ? 32 : 71,
            ),
            PrimaryButton(
              text: 'Send link',
              onPress: () async {
                setState(() {
                  _isLoading = true;
                });
                await context
                    .read<AuthBloc>()
                    .forgotPassword()
                    .then((value) => {
                          setState(() {
                            _isLinkSent = true;
                          })
                        });
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
            text: 'SMS',
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
            text: state.accountInfo.username,
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
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: 'Link sent!',
          description: _sendLinkViaEmail
              ? ''
              : 'If you didn’t receive an email, remember to check your spam folder.',
        ),
        content: Column(
          children: [
            SizedBox(
              height: _sendLinkViaEmail ? 123 : 71,
            ),
            PrimaryButton(
              text: 'Back to login',
              onPress: () {
                // TODO: need universal link after sending link, keep go on next page for now
                NavigationCubit.of(context).push(AuthCloudResetPasswordPath());
              },
            ),
          ],
        ),
      ),
    );
  }
}
