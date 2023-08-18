import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/provider/account/account_provider.dart';
import 'package:linksys_app/provider/account/account_state.dart';
import 'package:linksys_app/provider/auth/_auth.dart';
import 'package:linksys_app/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:styled_text/styled_text.dart';

class AccountView extends ConsumerStatefulWidget {
  const AccountView({super.key});

  @override
  ConsumerState<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends ConsumerState<AccountView> {
  late final TextEditingController _passwordController;
  final String _displayPhoneNumber = '';
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
  Widget build(BuildContext context) {
    final state = ref.watch(accountProvider);
    final loginType =
        ref.watch(authProvider.select((value) => value.value?.loginType));
    return StyledAppPageView(
      scrollable: true,
      title: 'Account',
      child: loginType == LoginType.remote ? _remote(state) : _local(state),
    );
  }

  Widget _local(AccountState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.regular(),
        _localLoginInformationSection(context),
        const AppPadding(
          padding: AppEdgeInsets.symmetric(vertical: AppGapSize.regular),
          child: Divider(
            color: ConstantColors.primaryLinksysBlack,
          ),
        ),
        // _biometricsTile(state),
        const Spacer(),
      ],
    );
  }

  Widget _remote(AccountState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _informationSection(state),
        const AppPadding(
          padding: AppEdgeInsets.symmetric(vertical: AppGapSize.regular),
          child: Divider(
            color: ConstantColors.primaryLinksysBlack,
          ),
        ),
        _securitySection(state),
        const Spacer(),
      ],
    );
  }

  Widget _informationSection(AccountState state) {
    return SectionTile(
      header: const AppText.tags(
        'YOUR INFORMATION',
      ),
      child: Column(
        children: [
          ..._createInfoTile(
            state.username,
            state.password,
            state.mobile?.fullFormat,
          ),
        ],
      ),
    );
  }

  Widget _securitySection(AccountState state) {
    return SectionTile(
      header: const AppText.tags(
        'Security',
      ),
      child: Column(
        children: [
          AppPanelWithInfo(
              title: '2-Step Verification',
              infoText: state.mfaEnabled ? 'On' : 'Off'),
        ],
      ),
    );
  }

  List<Widget> _createInfoTile(
      String username, String password, String? phoneNumber) {
    return [
      AppSimplePanel(
        title: 'Email',
        description: username,
      ),
      AppPasswordField(
        headerText: 'Password',
        controller: _passwordController,
      ),
      if (phoneNumber != null)
        AppSimplePanel(
          title: 'Phone Number',
          description: phoneNumber,
        ),
    ];
  }

  Widget _localLoginInformationSection(BuildContext context) {
    return SectionTile(
      header: const AppText.tags(
        'No Linksys account',
      ),
      child: Column(
        children: [
          StyledText(
            text:
                'Unlock app features with a Linksys account  <link href="https://flutter.dev">Learn more</link>',
            style: AppTheme.of(context)
                .typography
                .textLinkSmall
                .copyWith(color: AppTheme.of(context).colors.ctaSecondary),
            tags: {
              'link': StyledTextActionTag(
                  (String? text, Map<String?, String?> attrs) {
                String? link = attrs['href'];
                print('The "$link" link is tapped.');
              }, style: const TextStyle(color: Colors.blue)),
            },
          ),
          const AppGap.regular(),
          const Row(children: [
            AppGap.small(),
            AppText.descriptionMain('\u2022'),
            AppGap.small(),
            AppText.descriptionMain('Benefit 1'),
          ]),
          const Row(children: [
            AppGap.small(),
            AppText.descriptionMain('\u2022'),
            AppGap.small(),
            AppText.descriptionMain('Benefit 2'),
          ]),
          const Row(children: [
            AppGap.small(),
            AppText.descriptionMain('\u2022'),
            AppGap.small(),
            AppText.descriptionMain('Benefit X'),
          ]),
          const AppGap.semiBig(),
          AppPrimaryButton(
            'Create an account',
            onTap: () {
              // ref.read(navigationsProvider.notifier).push(
              //     CreateCloudAccountPath()
              //       ..args = {'config': 'LOCALAUTHCREATEACCOUNT'});
            },
          ),
          const AppGap.extraBig(),
        ],
      ),
    );
  }
}
