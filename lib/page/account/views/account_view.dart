import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/cloud/model/cloud_account.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/account/providers/account_provider.dart';
import 'package:linksys_app/page/account/providers/account_state.dart';
import 'package:linksys_app/providers/auth/_auth.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';

class AccountView extends ConsumerStatefulWidget {
  const AccountView({super.key});

  @override
  ConsumerState<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends ConsumerState<AccountView> {
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();

    if (ref.read(authProvider.notifier).isCloudLogin()) {
      ref.read(accountProvider.notifier).fetchAccount().then((_) {
        _passwordController.text = ref.read(accountProvider).password;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountProvider);
    final loginType =
        ref.watch(authProvider.select((value) => value.value?.loginType));
    return StyledAppPageView(
      scrollable: true,
      title: 'Account',
      child: loginType == LoginType.remote ? _remote(state) : const Center(),
    );
  }

  Widget _remote(AccountState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _informationSection(state),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: Spacing.regular),
          child: Divider(),
        ),
        _securitySection(state),
        _marketingSection(state),
        const Spacer(),
      ],
    );
  }

  Widget _informationSection(AccountState state) {
    return AppSection(
      header: const AppText.titleLarge(
        'YOUR INFORMATION',
      ),
      child: Column(
        children: [
          ..._createInfoTile(
            state.username,
            state.password,
            state.mobile,
          ),
        ],
      ),
    );
  }

  Widget _securitySection(AccountState state) {

    return AppSection(
      header: const AppText.titleLarge(
        'Security',
      ),
      child: Column(
        children: [
          AppPanelWithInfo(
            title: '2-Step Verification',
            infoText: state.mfaEnabled ? 'On' : 'Off',
            onTap: () {
              context.pushNamed(RouteNamed.twoStepVerification);
            },
          ),
        ],
      ),
    );
  }

  Widget _marketingSection(AccountState state) {
    return AppSection(
      header: const AppText.titleLarge(
        'Marketing',
      ),
      child: Column(
        children: [
          AppPanelWithSwitch(
            title: 'Newsletter',
            value: state.newsletterOptIn,
            description: 'Be the first to know about exclusive deals & news',
            onChangedEvent: (value) {
              ref.read(accountProvider.notifier).setNewsletterOptIn(value);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _createInfoTile(
      String username, String password, CAMobile? mobile) {
    return [
      AppSimplePanel(
        title: 'Email',
        description: username,
      ),
      if (mobile != null)
        AppSimplePanel(
          title: 'Phone Number',
          description: mobile.fullFormat,
          onTap: () {
            context.pushNamed(RouteNamed.otpAddPhone, extra: {'phone': mobile});
          },
        ),
      AppTextField(
        headerText: 'Password',
        controller: _passwordController,
        secured: true,
      ),
    ];
  }
}